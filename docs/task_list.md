# task_list

このドキュメントは、以下の仕様書をもとに、現状のリポジトリで不足している実装をタスク化したものです。

- `docs/agent-ci.md`
- `docs/aoai-entra-auth-spec.md`
- `docs/current-architecture-spec.yaml`

## 1. 現在の問題点（要約）

1. **CI/CD が未実装**
   - GitHub Actions の IaC 検証・デプロイ Workflow が存在しない。
   - PR での `what-if` 自動実行や `main` 反映時デプロイが未整備。

2. **AOAI + Entra ID（Managed Identity）対応が未実装**
   - AOAI リソース作成モジュール、UAMI + RBAC モジュールが未追加。
   - ACA (`api` / `worker`) への UAMI 割り当てと AOAI 関連環境変数注入が未対応。

3. **パラメータ/運用設計が仕様と未整合**
   - `parameters/` の環境別ファイル運用（`dev/stg/prod`）が未導入。
   - `deploy.ps1` に RBAC 伝播待ち・検証ロジックがない。

4. **ドキュメント整備不足**
   - README とパラメータ例が AOAI + Entra ID 拡張仕様を十分にカバーできていない。

---

## 2. 優先度付きタスク一覧

### P0: 先に着手（基盤）

- [ ] **T1. CI 用 Workflow（PR 検証）を追加**
  - 追加先: `.github/workflows/iac-pr.yml`
  - 実装内容:
    - Bicep Lint/Build
    - `az deployment sub what-if`
    - What-If 結果を PR コメント/Artifact 化

- [ ] **T2. CI 用 Workflow（main デプロイ）を追加**
  - 追加先: `.github/workflows/iac-deploy.yml`
  - 実装内容:
    - precheck（Build + What-If）
    - deploy（`az deployment sub create`）
    - post-verify（主要リソース確認）

- [ ] **T3. OIDC 認証方式へ統一**
  - 実装内容:
    - Azure 側 Federated Credential 構成
    - GitHub Secrets/Variables の最小セット化
    - Client Secret 依存の排除

### P1: AOAI + Entra ID 対応

- [ ] **T4. AOAI モジュール追加**
  - 追加先: `modules/aoai.bicep`
  - 実装内容:
    - AOAI アカウント作成
    - モデルデプロイ（chat/embedding）
    - endpoint/resourceId/output の定義

- [ ] **T5. UAMI + RBAC モジュール追加**
  - 追加先: `modules/identity-rbac.bicep`
  - 実装内容:
    - UAMI 作成
    - AOAI スコープに `Cognitive Services OpenAI User` 付与

- [ ] **T6. `main.bicep` 拡張**
  - 実装内容:
    - AOAI/UAMI 用パラメータ追加
    - 依存順序（AOAI -> identity/rbac -> aca）でモジュール接続
    - `useEntraIdForAoai` フラグ導入

- [ ] **T7. `modules/aca-env.bicep` 拡張**
  - 実装内容:
    - `api` / `worker` へ UAMI 割り当て
    - AOAI Endpoint / API Version / Deployment 名など環境変数追加
    - API キー認証との切替制御（`useEntraIdForAoai`）

### P2: 運用強化・整合性

- [ ] **T8. `deploy.ps1` の検証処理強化**
  - 実装内容:
    - デプロイ出力から AOAI/UAMI 情報取得
    - RBAC 付与確認
    - 伝播遅延に対する待機リトライ

- [ ] **T9. パラメータファイル運用を環境分離**
  - 追加先: `parameters/dev.json`, `parameters/stg.json`, `parameters/prod.json`
  - 実装内容:
    - 既存 `parameters.json` 依存から段階移行
    - CI で環境別パラメータを使用

- [ ] **T10. ドキュメント更新**
  - 対象: `README.md`, `parameters.example.json`, `docs/*`
  - 実装内容:
    - AOAI + Entra ID の前提と設定手順
    - CI/CD の運用フロー
    - ロールバック手順

---

## 3. 実装順序（推奨）

1. T1, T2, T3（CI 基盤と認証）
2. T4, T5, T6, T7（AOAI + Entra ID 実装本体）
3. T8（デプロイ後検証）
4. T9, T10（運用定着とドキュメント整備）

---

## 4. 完了条件（Definition of Done）

- [ ] PR 作成時に Bicep Build と What-If が自動実行される。
- [ ] `main` 反映時に承認付きデプロイ（prod）が実行可能。
- [ ] OIDC 認証で Azure 接続でき、長期シークレット依存がない。
- [ ] AOAI/UAMI/RBAC が Bicep で一貫デプロイされる。
- [ ] `api` / `worker` が UAMI で AOAI にアクセス可能。
- [ ] `deploy.ps1` が RBAC 伝播遅延を考慮した検証を行う。
- [ ] README/パラメータ例/運用資料が最新構成に追従している。

---

## 5. メモ（リスク管理）

- RBAC 反映遅延は初回デプロイ直後に顕在化しやすいため、**自動リトライ**を標準化する。
- AOAI のモデル名・バージョンは変更頻度が高いため、**ハードコード禁止**・完全パラメータ化する。
- Dify の環境変数仕様はバージョン依存があるため、実装時に対象バージョンの仕様確認を必須とする。
