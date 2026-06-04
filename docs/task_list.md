# task_list

このドキュメントは、**App Gateway + Private ACA（Azure Container Apps）** を前提とし、
各ネットワークを **NSG で保護**するために、現行リポジトリの実装差分を計画として整理したものです。

参照仕様:
- `docs/spec/spec.md`
- `docs/spec/10_network.md`
- `docs/spec/20_auth.md`
- `docs/spec/30_api.md`
- `docs/spec/40_aoai.md`
- `docs/spec/50_aca.md`
- `docs/spec/60_db.md`
- `docs/spec/80_bicep.md`
- `docs/spec/70_secret.md`
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
  - 対象: `infra/modules/vnet.bicep`, `infra/main.bicep`
  - 実装内容:
    - `AppGatewaySubnet`（専用）追加
    - 既存サブネット CIDR の競合確認
    - パラメータに CIDR を外だし（環境別変更可能にする）

- [ ] **N2. NSG モジュール追加とサブネット関連付け**
  - 追加先: `infra/modules/network-nsg.bicep`（新規）
  - 実装内容:
    - `nsg-appgw` / `nsg-aca` / `nsg-postgres` / `nsg-privatelink` を作成
    - 各サブネットへ NSG を関連付け
    - 既定 deny と必要通信のみ許可

- [ ] **N3. Application Gateway（WAFなし）モジュール追加 + Entra侵入制限**
  - 追加先: `infra/modules/app-gateway.bicep`（新規）
  - 実装内容:
    - Public IP / App Gateway（Standard_v2想定）
    - HTTPS Listener + 証明書参照（Key Vault 連携は将来拡張可）
    - Entra ID を用いた侵入制限（認証必須化）を設計・実装
    - Backend Pool を ACA 内部エンドポイントに向ける
    - Health Probe と HTTP Settings を定義

- [ ] **N4. ACA の完全内部化**
  - 対象: `infra/modules/aca-env.bicep`
  - 実装内容:
    - `nginx` の external ingress 廃止（または app 自体削除）
    - App Gateway 経由のみを前提に ingress 設定を見直し

### P1: Private PaaS 完成度向上

- [ ] **N5. Private Endpoint / DNS の整合性強化**
  - 対象: `infra/modules/storage.bicep`, `infra/modules/postgresql.bicep`, `infra/modules/redis-cache.bicep`, （必要に応じて AOAI モジュール）
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

## 7. 実装完了状況（2026/6/5 時点）

### ✅ 完了済み

- [x] **N1. VNet サブネット再設計** - network.bicep でサブネット設計完了（PrivateLink, ACA, Postgres, AppGw）
- [x] **N2. NSG モジュール追加とサブネット関連付け** - nsg.bicep で全 NSG 定義完了
- [x] **N3. Application Gateway モジュール追加** - appgw.bicep で完全実装（URL パス分離、HTTP/HTTPS管理、probe 設定）
- [x] **N4. ACA の完全内部化** - edge-runtime.bicep で nginx `external: false` 確認、ipSecurityRestrictions で CIDR 制限
- [x] **N5. Private Endpoint/DNS 整合性** - 全 PaaS リソースで Private Endpoint 設定完了

### ⏳ 実装継続中

- [ ] **N6. NSG ルール通信マトリクス明確化** - 現在の NSG ルール設定は機能的だが、文書化が不足
- [ ] **N7. CI/CD ネットワーク検証** - GitHub Actions 未実装
- [ ] **N8. 運用 Runbook 更新** - README に簡易手順あり、詳細化が必要

---

## 8. 新規確認事項・不明点（2026/6/5 追加）

### S1. セキュリティ: 環境変数への機微情報直接記載
- **状況**: ACA Container Apps の環境変数に SECRET_KEY、API KEY などが平文設定
  - 例：`SECRET_KEY: 'dify-9f73s3ljTXVcMT3...'`（application.bicep L:184）
  - 例：`DB_PASSWORD: postgresAdminPassword`（application.bicep L:219）
- **仕様との齟齬**: [70_secret.md](./spec/70_secret.md) では「平文環境変数表示を回避」を要件としているが、現実装では Key Vault 参照が未実装
- **推奨改善**:
  - Container Apps シークレットオブジェクトを利用し、Key Vault 参照を定義
  - Managed Identity を各 Container App に付与し、Key Vault への読み取りアクセスを許可
  - Environment variable から秘密値の参照に変更
- **優先度**: **P0 セキュリティ対応**

### S2. OAuth2 Proxy: リダイレクト URL とカスタムドメイン連携
- **状況**: 
  - edge-runtime.bicep で OAUTH2_PROXY_REDIRECT_URL は `https://${acaDifyCustomerDomain}/oauth2/callback` を設定（L:104）
  - `acaDifyCustomerDomain` パラメータは `dify.example.com` のテンプレート値
- **不明点**:
  - カスタムドメインの DNS 解決、SSL 証明書の手動設定が必要か
  - Entra App Registration での Redirect URI の登録が必要か（手動手順かスクリプト化するか）
  - 証明書が提供されない場合（開発環境）の動作確認は?
- **推奨改善**:
  - `acaDifyCustomerDomain` の有効性検証ルール（DNS resolve チェック）
  - Entra App Registration 設定ガイドの詳細化（README または Runbook）
  - 開発環境用の `localhost` / 自己署名証明書ハンドリングの確認
- **優先度**: **P1 運用ガイド補強**

### S3. Application Gateway: oauth2-proxy health probe パス
- **状況**: appgw.bicep で health probe は `path: '/oauth2/ping'` に設定（L:276）
- **不明点**:
  - `/oauth2/ping` エンドポイントが oauth2-proxy に実装されているか
  - 認証後のバックエンド (nginx:80) が健全か判定できるか、プローブはレイヤーがどこまで見ているか
  - 502/503 エラーの切り分け観点は?
- **推奨改善**:
  - Probe パスの動作確認・テスト実施
  - Probe 失敗時のデバッグ手順（ログ取得、サービス再起動）をドキュメント化
  - 監視アラート設定（503 Gateway Service Unavailable 時の通知）
- **優先度**: **P1 運用安定性**

### S4. APIM 統合: 現状プレースホルダー
- **状況**: 
  - [apim.bicep](./modules/apim.bicep) は定義されているが、main.bicep から呼び出されていない（コメントアウト未確認）
  - [30_api.md](./spec/30_api.md) では「将来的に API 経路を APIM 経由に切り替え」と記載
- **現行実装**:
  - Dify API は nginx を経由し、OAuth2 Proxy で Entra 認証→API へ
- **不明点**:
  - APIM 統合のスコープ（いつ実施するか）と優先度は?
  - OAuth2 Proxy（セッションクッキー）と APIM（Bearer Token）の認証分離方針は?
- **推奨改善**:
  - APIM 統合を P0/P1 の誰かのタスクに明示的に割り当てるか、バックログに移すか決定
  - 決定次第、[apim.bicep](./modules/apim.bicep) の呼び出し有効化 OR 削除
- **優先度**: **P2 戦略決定**

### S5. AOAI 統合: 手動投入ポリシー
- **状況**: 
  - [40_aoai.md](./spec/40_aoai.md) では「Bicep テンプレートに AOAI 作成モジュール未含」、管理者が Dify Web から手動設定
- **現行実装**:
  - `aoai.bicep` 未作成、main.bicep に呼び出しなし
  - Container Apps 環境変数に AOAI endpoint/key の投入方法が未定
- **不明点**:
  - AOAI API Key をどこに保管するか（Key Vault への自動登録？手動？）
  - Container Apps からの Key Vault 参照方法（参照: S1 セキュリティ改善と連動）
  - 複数 AOAI デプロイの管理方法（開発/本番環境別）
- **推奨改善**:
  - AOAI 統合の実装時期を決定（P0/P1/P2 または外部タスク）
  - 決定に応じて aoai.bicep スケルトンを作成 OR バックログに記載
- **優先度**: **P1 IaC 完成度向上**

### S6. deploy.ps1: 複雑性と保守性
- **状況**:
  - deploy.ps1 は Bicep デプロイ後のファイルアップロード処理を担当（L:100-300）
  - azcopy / az CLI の自動フォールバック、SAS トークン / ストレージキー切り替え
- **リスク**:
  - ファイルアップロード失敗時の前進/後退戻しが複雑
  - Windows/Mac/Linux での互換性確認が不十分の可能性
  - スクリプト長で保守が困難
- **推奨改善**:
  - Bicep 内で Azure Files の初期化を進める（storage.bicep または aca-env.bicep で）
  - deploy.ps1 を段階的に簡素化（Bicep の役割拡大）
  - 単体テスト / CI 統合による動作検証
- **優先度**: **P2 長期保守性**

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
