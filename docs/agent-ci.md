# GitHub Actions を用いたデプロイ自動化パイプライン計画（agent-ci）

## 1. 目的

本ドキュメントは、このリポジトリの Bicep ベース Azure デプロイを GitHub Actions で自動化するための実装計画を定義する。
特に以下を満たすことを目的とする。

- Pull Request 時に IaC 品質ゲート（Lint / Build / What-If）を自動実行する。
- `main` マージ時に Azure への本番デプロイを自動実行できる構成を用意する。
- 将来的に AOAI + Entra ID（Managed Identity）対応を含む追加モジュールにも耐えるパイプライン設計にする。
- Secrets 最小化のため、可能な限り GitHub OIDC + Azure Federated Credential を採用する。

---

## 2. 方針（設計原則）

1. **環境分離**
   - `dev` / `stg` / `prod` を GitHub Environments で分離。
   - `prod` は Approver 必須。

2. **再現性**
   - ローカル `deploy.ps1` 依存を減らし、CI 用の明示的ジョブに処理を分解する。
   - Bicep コンパイル・What-If・Deploy をパイプラインで固定手順化。

3. **安全性**
   - `what-if` 結果を PR コメントとして可視化。
   - 破壊的変更（Delete/Replace）検出時は失敗または手動承認へ遷移。

4. **最小権限**
   - GitHub Actions の Azure ログインは OIDC を使用。
   - サービスプリンシパルに必要最小限の RBAC ロールを付与。

5. **拡張性**
   - AOAI/UAMI/RBAC モジュール追加後も同じワークフローで検証可能な構成にする。

---

## 3. 想定ブランチ戦略とトリガー

### 3.1 Pull Request
- トリガー: `pull_request`（`main` 向け）
- 実行内容:
  - Bicep Lint
  - Bicep Build
  - `az deployment sub what-if`
  - What-If 結果サマリを PR に投稿

### 3.2 Main マージ後
- トリガー: `push` on `main`
- 実行内容:
  - `what-if` 再実行
  - Deploy 実行（`az deployment sub create`）
  - デプロイ後検証（主に出力値・主要リソース存在確認）

### 3.3 手動実行
- トリガー: `workflow_dispatch`
- 用途:
  - 任意環境 (`dev/stg/prod`) への再デプロイ
  - ドリフト修正
  - 緊急リカバリ

---

## 4. 追加する GitHub Actions ファイル計画

## 4.1 `.github/workflows/iac-pr.yml`

### 目的
PR の品質ゲート。

### 主要ジョブ
1. `validate-bicep`
   - `az bicep install`（または事前インストール確認）
   - `az bicep build --file main.bicep`
2. `what-if`
   - Azure OIDC ログイン
   - `az deployment sub what-if --location <loc> --template-file main.bicep --parameters <env-params>`
   - 結果を markdown 化して PR コメント
3. `policy-check`（任意）
   - 禁止設定（例: public ingress, 広すぎる CIDR）をスクリプトで検出

### 成果物
- What-If 結果 artifact（テキスト/JSON）

## 4.2 `.github/workflows/iac-deploy.yml`

### 目的
main への反映を Azure へ自動デプロイ。

### 主要ジョブ
1. `precheck`
   - Bicep Build
   - What-If
2. `deploy`
   - GitHub Environment（例: `prod`）で保護
   - `az deployment sub create`
3. `post-verify`
   - デプロイ出力取得
   - 主要リソース存在確認（RG / ACA / PostgreSQL / Storage / AOAI など）
   - AOAI + UAMI 採用後は RBAC 反映確認を実施

### 補足
- `deploy.ps1` の機能（アップロードや事後確認）のうち CI 必須部分は script 化して再利用可能にする。

## 4.3 `.github/workflows/iac-manual.yml`（任意）

### 目的
手動リラン用。`environment`, `location`, `parameterFile` を入力で受ける。

---

## 5. リポジトリ構成の拡張計画

## 5.1 パラメータファイル整理
`parameters/` ディレクトリを新設し、環境ごとに分離。

- `parameters/dev.json`
- `parameters/stg.json`
- `parameters/prod.json`

> 現在の `parameters.json` はローカル実行向けとし、CI は環境別ファイルを参照する運用に移行する。

## 5.2 CI 共通スクリプト
`tools/ci/` ディレクトリを追加し、Action から呼び出す。

- `tools/ci/run-whatif.ps1`
- `tools/ci/run-deploy.ps1`
- `tools/ci/post-verify.ps1`

これにより Workflow YAML の肥大化を防ぎ、ローカル検証とも共通化できる。

---

## 6. 認証・シークレット設計

## 6.1 推奨: GitHub OIDC

### Azure 側
- Entra ID に CI 用アプリ登録（Service Principal）を作成。
- Federated Credential を設定（repo/branch/environment 制約付き）。
- 対象サブスクリプションまたは RG に必要ロール付与。

### GitHub 側 Secrets/Variables
- `AZURE_CLIENT_ID`
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`
- （必要時のみ）`DEPLOY_LOCATION` など

## 6.2 非推奨（暫定）
- Client Secret を長期保管する方式。

---

## 7. AOAI + Entra ID 対応を見据えた CI 追加チェック

AOAI/UAMI/RBAC 実装後、`post-verify` に以下を追加する。

1. AOAI リソース存在確認。
2. UAMI 存在確認。
3. `Cognitive Services OpenAI User` ロールが AOAI スコープに付与されていることを確認。
4. ACA `api` / `worker` が UAMI をアタッチしていることを確認。
5. 必要に応じて RBAC 伝播待機リトライ（最大回数・待機秒をパラメータ化）。

---

## 8. サンプル実行フロー（PR）

1. 開発者が `feature/*` から PR 作成
2. `iac-pr.yml` 起動
3. Lint/Build 成功
4. What-If 実行
5. 変更サマリが PR コメントに投稿
6. 破壊的変更がなければレビュー進行

---

## 9. サンプル実行フロー（本番）

1. PR マージで `main` 更新
2. `iac-deploy.yml` 起動
3. `prod` Environment 承認
4. Deploy 実行
5. Post Verify 実行
6. 成功時にデプロイ結果（出力値）をジョブサマリへ記録

---

## 10. 失敗時の運用設計

1. **What-If 失敗**
   - PR をブロックし、ログ確認を促す。
2. **Deploy 失敗**
   - `post-verify` はスキップ。
   - 失敗箇所を artifact と job summary に集約。
3. **RBAC 伝播遅延**
   - リトライ許容後も失敗する場合は Warning 扱いで手動確認タスク化（運用ルールで定義）。

---

## 11. 段階導入ロードマップ

### Phase 1（最短導入）
- `iac-pr.yml` を導入（Lint/Build/What-If）。
- OIDC ログイン確立。

### Phase 2（自動デプロイ）
- `iac-deploy.yml` を導入。
- `dev` 自動デプロイ、`prod` 手動承認付き。

### Phase 3（運用高度化）
- post-verify 強化（AOAI/UAMI/RBAC まで含む）。
- ドリフト検知ジョブ（定期 `schedule`）を追加。

---

## 12. 受け入れ基準

- PR 作成時に Bicep Build と What-If が自動実行される。
- main 反映時に承認付きデプロイが可能である。
- OIDC 認証で Azure に接続でき、長期シークレット依存を排除できる。
- AOAI + Entra ID 拡張後も同一パイプラインで検証・デプロイ・事後確認が実行できる。

