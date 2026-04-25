# Dify から Azure OpenAI を Entra ID 認証で利用するための拡張仕様書（実装計画）

## 1. 背景と目的

本仕様は、既存の Bicep 構成に **Azure OpenAI (AOAI)** と **Entra ID (Managed Identity) 認証**を組み込み、Dify が API キーではなくトークンベースで AOAI に接続できるようにするための実装計画を定義する。

### 目的
- Dify（主に `api` / `worker`）から AOAI への通信を Entra ID 認証へ切替する。
- 追加リソースを Bicep モジュール化し、`main.bicep` から一貫してデプロイできるようにする。
- `deploy.ps1` に、AOAI 追加に伴う事後設定（必要に応じた RBAC 伝播待ち・疎通確認）を実装する。

## 2. スコープ

### 対象
- `modules/` 配下への新規モジュール追加（AOAI / Managed Identity / RBAC）。
- `main.bicep` へのパラメータ追加と新規モジュール呼び出し追加。
- `modules/aca-env.bicep` への入力追加（Dify コンテナの AOAI 関連環境変数、Managed Identity 割当）。
- `deploy.ps1` への AOAI 関連の補助処理追加。
- `parameters.example.json` と `README.md` の追補（任意だが推奨）。

### 非対象
- Dify アプリ本体コードの改修。
- 既存 DB/Redis/Storage のアーキテクチャ変更。

## 3. 目標アーキテクチャ

1. Azure OpenAI アカウント（Cognitive Services kind: `OpenAI`）を新規作成。
2. AOAI 内にモデルデプロイ（例: `gpt-4o-mini` / `text-embedding-3-large`）を作成。
3. Dify 用の User Assigned Managed Identity (UAMI) を作成。
4. `api` / `worker` Container App に UAMI を割り当て。
5. UAMI に AOAI スコープで `Cognitive Services OpenAI User` ロールを付与。
6. Dify の環境変数を Azure OpenAI + Entra ID 方式に合わせて設定（API キー未使用）。

## 4. 変更方針（ファイル別）

## 4.1 新規: `modules/aoai.bicep`

### 役割
- AOAI アカウント作成。
- 必要なモデルデプロイ作成（複数対応）。

### 主なパラメータ案
- `location` (string)
- `aoaiAccountName` (string)
- `aoaiSkuName` (string, default: `S0`)
- `aoaiPublicNetworkAccess` (string: `Enabled` / `Disabled`)
- `aoaiDeployments` (array)
  - 要素例:
    - `name`: Dify から参照するデプロイ名
    - `modelName`: 例 `gpt-4o-mini`
    - `modelVersion`: 例 `2024-07-18`（将来差し替え前提）
    - `capacity`: 例 `10`

### 主な出力案
- `aoaiResourceId`
- `aoaiEndpoint` (`https://<account>.openai.azure.com/`)
- `chatDeploymentName`
- `embeddingDeploymentName`

> 補足: モデルバージョンは更新頻度が高いため、パラメータ化を必須とし、固定値ハードコードを避ける。

## 4.2 新規: `modules/identity-rbac.bicep`

### 役割
- UAMI 作成。
- AOAI スコープに対する RBAC 付与。

### 主なパラメータ案
- `location` (string)
- `uamiName` (string)
- `aoaiResourceId` (string)
- `roleDefinitionIdOrName` (string, default: `Cognitive Services OpenAI User`)

### 主な出力案
- `uamiResourceId`
- `uamiClientId`
- `uamiPrincipalId`

### RBAC 設計
- 最小権限の原則で `Cognitive Services OpenAI User` を採用。
- スコープは AOAI アカウント単位。
- 必要がない限りサブスクリプション/リソースグループスコープ付与はしない。

## 4.3 変更: `modules/aca-env.bicep`

### 追加パラメータ案
- `difyIdentityResourceId` (string)
- `difyIdentityClientId` (string)
- `aoaiEndpoint` (string)
- `aoaiApiVersion` (string)
- `aoaiChatDeployment` (string)
- `aoaiEmbeddingDeployment` (string)
- `useEntraIdForAoai` (bool, default: `true`)

### 変更内容
1. `apiApp` と `workerApp` の `identity` に UAMI を設定。
2. Dify コンテナ環境変数に AOAI + Entra ID 用の値を追加。
   - 例（最終的なキー名は Dify バージョンに合わせて確認）:
     - `AZURE_OPENAI_ENDPOINT`
     - `AZURE_OPENAI_API_VERSION`
     - `AZURE_OPENAI_CHAT_DEPLOYMENT_NAME`
     - `AZURE_OPENAI_EMBEDDING_DEPLOYMENT_NAME`
     - `AZURE_CLIENT_ID`（UAMI の clientId）
3. API キー変数（`AZURE_OPENAI_API_KEY` 相当）を未設定/空にして、トークン認証ルートを優先。
4. 将来の後方互換のため `useEntraIdForAoai=false` 時は従来方式を維持できる分岐を設計。

## 4.4 変更: `main.bicep`

### 追加パラメータ案
- `aoaiAccountBase` (string)
- `aoaiSkuName` (string)
- `aoaiPublicNetworkAccess` (string)
- `aoaiApiVersion` (string)
- `aoaiChatDeploymentName` (string)
- `aoaiEmbeddingDeploymentName` (string)
- `aoaiChatModelName` / `aoaiEmbeddingModelName` (string)
- `difyUamiName` (string)
- `useEntraIdForAoai` (bool)

### 依存関係
- `aoaiModule` -> `identityRbacModule` -> `acaModule` の順で依存。
- `acaModule` へ `uamiResourceId/clientId` と AOAI endpoint/deployment を引き渡す。

### 命名
- 既存の `uniqueString(subscription().id, rg.name)` を流用し、グローバル一意性を担保。

## 4.5 変更: `deploy.ps1`

### 目的
- Bicep デプロイ後に RBAC 伝播遅延を考慮した検証を追加。

### 追加処理案
1. `az deployment sub create` 後、出力から `aoaiEndpoint` / `uamiClientId` を取得。
2. `az role assignment list` で UAMI の AOAI ロール付与を確認。
3. 必要に応じて待機リトライ（例: 30秒 x 最大10回）。
4. 任意の疎通確認コマンド（管理プレーン確認）を追加。
   - 実データプレーン呼び出しはテスト段階では任意。

### 注意点
- `deploy.ps1` は現在ファイルアップロード処理を含むため、AOAI 関連チェックを追加する位置を明確化（Bicep 成功直後を推奨）。
- エラー時は既存と同様に `Write-Error` + `exit 1`。

## 5. パラメータ設計（`parameters.example.json` 追補案）

- `useEntraIdForAoai`: `true`
- `aoaiAccountBase`: `aoaidify`
- `aoaiSkuName`: `S0`
- `aoaiPublicNetworkAccess`: `Enabled`（将来的に Private Endpoint 化を検討）
- `aoaiApiVersion`: `2024-10-21`（利用可能バージョンに合わせて更新）
- `aoaiChatDeploymentName`: `chat`
- `aoaiChatModelName`: `gpt-4o-mini`
- `aoaiEmbeddingDeploymentName`: `embedding`
- `aoaiEmbeddingModelName`: `text-embedding-3-large`
- `difyUamiName`: `dify-uami`

## 6. 実装ステップ

1. `modules/aoai.bicep` を作成し、AOAI アカウント+デプロイを定義。
2. `modules/identity-rbac.bicep` を作成し、UAMI + RBAC を定義。
3. `main.bicep` に新規パラメータとモジュール連携を追加。
4. `modules/aca-env.bicep` に UAMI 割当と AOAI 関連 env を追加。
5. `deploy.ps1` に RBAC 伝播確認ロジックを追加。
6. `parameters.example.json` と README を更新。
7. What-If/本番デプロイで検証。

## 7. テスト計画

### IaC 構文
- `az bicep build --file main.bicep`
- `az deployment sub what-if --location <region> --template-file main.bicep --parameters parameters.json`

### 権限
- UAMI に `Cognitive Services OpenAI User` が付与されていること。

### アプリ設定
- `api` / `worker` に UAMI が割り当て済みであること。
- AOAI 関連 env が設定され、API キー依存が無効化されていること。

### 動作
- Dify で Azure OpenAI モデル接続テストが成功すること。
- 埋め込みモデル呼び出しが成功すること。

## 8. ロールバック方針

- `useEntraIdForAoai=false` で従来認証方式へ戻せる設計にする。
- 新規追加モジュールは main 側の条件分岐で切り離し可能にする。

## 9. リスクと対策

1. **RBAC 伝播遅延**
   - 対策: `deploy.ps1` でリトライ待機を実装。
2. **Dify の環境変数仕様差分（バージョン依存）**
   - 対策: 実装時に対象 Dify バージョンの公式仕様と突合。
3. **AOAI モデル/バージョン変更**
   - 対策: モデル名・バージョンの完全パラメータ化。
4. **ネットワーク制限時の到達性不足**
   - 対策: 初期は Public access で動作確認し、その後 Private Endpoint を段階導入。

## 10. 受け入れ基準

- Bicep デプロイで AOAI/UAMI/RBAC が一貫して作成される。
- `api` と `worker` が UAMI を利用し、AOAI に Entra ID でアクセスできる。
- `deploy.ps1` が AOAI 関連チェックを実行し、異常時に明確に失敗する。
- 既存リソース（PostgreSQL/Storage/Redis/ACA）の動作を阻害しない。

