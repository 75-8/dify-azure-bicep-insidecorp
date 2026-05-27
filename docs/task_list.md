# task_list

このドキュメントは、**App Gateway + Private ACA（Azure Container Apps）** を前提とし、
各ネットワークを **NSG で保護**するために、現行リポジトリの実装差分を計画として整理したものです。

参照仕様:
- `docs/spec/spec.md`
- `docs/spec/*.md`
- `docs/current-architecture-spec.yaml`
- `docs/security_guardrails.md`

---

## 1. 目標アーキテクチャ（To-Be）

1. **入口は Application Gateway（WAFなし）に統一**
   - インターネット公開は App Gateway のみ。
   - 既存の ACA 公開 Ingress（`nginx` など）は廃止または内部化。

2. **ACA は Private（Internal）運用**
   - ACA Environment は Internal。
   - `web` / `api` / `worker` / `sandbox` / `plugin` / `ssrfproxy` は VNet 内通信のみ。

3. **サブネット単位で NSG 適用**
   - `AppGatewaySubnet` / `ACASubnet` / `PostgresSubnet` / `PrivateLinkSubnet` すべてに NSG を割当。
   - 必要最小限の Inbound/Outbound のみ許可（deny by default）。

4. **PaaS は private endpoint + private DNS で閉域接続**
   - Storage / Redis / PostgreSQL /（必要に応じて AOAI）を private 化。

---

## 2. 現在の主要ギャップ

1. **App Gateway の IaC 未実装**
   - 専用サブネット、Public IP、Backend/Probe/Listener、Entra 認証連携設定が未定義。

2. **ACA 公開経路が残存**
   - `nginx` の external ingress を前提とした構成が残っている。

3. **NSG 設計・実装が未完**
   - サブネット別 NSG の作成、関連付け、ルール最小化が不足。

4. **接続テスト/運用 Runbook 不足**
   - App Gateway → ACA 内部 FQDN の疎通確認手順、NSG 変更時の検証項目が不足。

---

## 3. 優先度付きタスク

### P0: ネットワーク境界の確立（最優先）

- [ ] **N1. VNet サブネット再設計（App Gateway 追加）**
  - 対象: `modules/vnet.bicep`, `main.bicep`
  - 実装内容:
    - `AppGatewaySubnet`（専用）追加
    - 既存サブネット CIDR の競合確認
    - パラメータに CIDR を外だし（環境別変更可能にする）

- [ ] **N2. NSG モジュール追加とサブネット関連付け**
  - 追加先: `modules/network-nsg.bicep`（新規）
  - 実装内容:
    - `nsg-appgw` / `nsg-aca` / `nsg-postgres` / `nsg-privatelink` を作成
    - 各サブネットへ NSG を関連付け
    - 既定 deny と必要通信のみ許可

- [ ] **N3. Application Gateway（WAFなし）モジュール追加 + Entra侵入制限**
  - 追加先: `modules/app-gateway.bicep`（新規）
  - 実装内容:
    - Public IP / App Gateway（Standard_v2想定）
    - HTTPS Listener + 証明書参照（Key Vault 連携は将来拡張可）
    - Entra ID を用いた侵入制限（認証必須化）を設計・実装
    - Backend Pool を ACA 内部エンドポイントに向ける
    - Health Probe と HTTP Settings を定義

- [ ] **N4. ACA の完全内部化**
  - 対象: `modules/aca-env.bicep`
  - 実装内容:
    - `nginx` の external ingress 廃止（または app 自体削除）
    - App Gateway 経由のみを前提に ingress 設定を見直し

### P1: Private PaaS 完成度向上

- [ ] **N5. Private Endpoint / DNS の整合性強化**
  - 対象: `modules/storage.bicep`, `modules/postgresql.bicep`, `modules/redis-cache.bicep`, （必要に応じて AOAI モジュール）
  - 実装内容:
    - Private DNS Zone Link の依存関係を明確化
    - ACA からの名前解決確認用 output 追加

- [ ] **N6. NSG ルールの具体化（通信マトリクス化）**
  - 対象: `docs/security_guardrails.md`（および必要なら `docs/current-architecture-spec.yaml`）
  - 実装内容:
    - `from/to/port/protocol/reason` を一覧化
    - App Gateway → ACA（80/443 or targetPort）
    - ACA → PostgreSQL(5432), Redis(6380), Storage(PE経由) の明示

### P2: CI/CD・運用整備

- [ ] **N7. CI にネットワーク検証を追加**
  - 対象: `.github/workflows/iac-pr.yml`, `.github/workflows/iac-deploy.yml`（新規）
  - 実装内容:
    - Bicep build/lint
    - what-if で NSG/App Gateway/ACA 変更差分を可視化

- [ ] **N8. 運用 Runbook 更新**
  - 対象: `README.md`, `docs/*`
  - 実装内容:
    - 切替手順（既存公開経路 → App Gateway 経路）
    - 障害時切戻し手順
    - NSG/Entra 設定変更時の疎通確認コマンド集

---

## 4. 実装順序（推奨）

1. N1（サブネット）
2. N2（NSG）
3. N3（App Gateway）
4. N4（ACA 内部化）
5. N5, N6（private 接続とルール明確化）
6. N7, N8（CI/CD と運用）

---

## 5. Definition of Done

- [ ] インターネットからの入口が App Gateway のみに限定されている（WAFは未使用）。
- [ ] ACA アプリはすべて internal ingress で、直接公開されていない。
- [ ] すべての関連サブネットに NSG が適用されている。
- [ ] NSG ルールが通信要件と 1:1 で対応し、不要許可がない。
- [ ] App Gateway で Entra 認証による侵入制限が有効化されている。
- [ ] Private Endpoint + Private DNS で PaaS 接続が成立している。
- [ ] what-if でネットワーク変更のレビューが可能である。

---

## 6. リスクと注意点

- App Gateway の Backend を ACA に向ける際、FQDN 解決（Private DNS）と Probe パス不整合で 502 が起こりやすい。
- NSG の Outbound を絞りすぎると、ACA のイメージ取得・依存サービス接続が失敗するため段階的に tighten する。
- 切替期間中は旧経路と新経路の二重運用を避け、短期間で一本化する。

---

## 7. 実装未定項目の計画（Decision Backlog）

以下は、現時点で実装方式が未確定のため、**先に意思決定タスクを実施**する項目です。

### D1. App Gateway での Entra 認証方式の確定
- 検討軸:
  - App Service / Front Door と異なり、App Gateway 単体でどこまでネイティブに実現するか
  - 認証処理を別コンポーネント（例: 認証プロキシ）で補うか
- 決定成果物:
  - 採用方式の ADR（Architecture Decision Record）
  - Bicep 実装方針（モジュール境界、必要リソース）
- 期限目安: N3 実装着手前

### D2. AOAI API Key 手動投入の運用手順確定
- 検討軸:
  - 誰が、どのタイミングで、どこへ投入するか
  - ローテーション時の切替/検証/監査方法
- 決定成果物:
  - Runbook（投入手順、ローテーション手順、障害時復旧手順）
  - 監査チェックリスト（投入漏れ/誤投入防止）
- 期限目安: N8 完了まで

### D3. ACA へのバックエンド接続方式の確定
- 検討軸:
  - App Gateway から ACA への名前解決方式（Private DNS）
  - Probe パス、Host ヘッダ、TLS 終端位置
- 決定成果物:
  - 接続設計書（疎通条件、失敗時切り分け観点）
  - 検証結果（502/403/タイムアウトの再現と対処）
- 期限目安: N3〜N4 の間

### D4. NSG ルール最小化の最終承認
- 検討軸:
  - 運用開始時の暫定許可範囲と、段階的 tighten 計画
  - 監視アラート（拒否ログ増加時の判断基準）
- 決定成果物:
  - 本番適用版の通信マトリクス
  - 例外ルール申請フロー
- 期限目安: N6 完了時

### D5. CI での検証深度の確定
- 検討軸:
  - what-if の差分検出のみか、ポリシーチェックまで自動化するか
  - セキュリティ観点（公開設定/認証設定）の Fail 条件
- 決定成果物:
  - CI 検証仕様（Fail 条件一覧）
  - 運用ガイド（誤検知時の対応）
- 期限目安: N7 実装前
