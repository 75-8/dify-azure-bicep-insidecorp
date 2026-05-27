# Dify から Azure OpenAI を Key 認証で利用するための拡張仕様書（実装計画）

## 1. 背景と目的

本仕様は、既存の Bicep 構成に **Azure OpenAI (AOAI)** を組み込み、Dify が **Key 認証**で AOAI に接続できるようにするための実装計画を定義する。

> 方針変更: 当初想定していた Entra ID（Managed Identity）認証は、Dify の AOAI プラグイン不具合リスクを踏まえて採用しない。

また、外部アクセス制限は **App Gateway（WAFなし）+ Entra 認証による侵入制限** と **NSG（Network Security Group）によるネットワーク制御**を組み合わせる。

### 目的
- Dify（主に `api` / `worker`）から AOAI への通信を Key 認証で安定運用する。
- インターネット侵入は App Gateway + Entra 認証で制限し、WAF は利用しない。
- 追加リソースを Bicep モジュール化し、`main.bicep` から一貫してデプロイできるようにする。
- `deploy.ps1` に、AOAI 追加に伴う事後設定（必要に応じた NSG 適用確認・疎通確認）を実装する。

## 2. スコープ

### 対象
- `modules/` 配下への新規モジュール追加（AOAI / NSG）。
- `main.bicep` へのパラメータ追加と新規モジュール呼び出し追加。
- `modules/aca-env.bicep` への入力追加（Dify コンテナの AOAI 関連設定。ただし API Key は IaC で注入しない）。
- `deploy.ps1` への AOAI 関連の補助処理追加。
- `parameters.example.json` と `README.md` の追補（任意だが推奨）。

### 非対象
- Dify アプリ本体コードの改修。
- 既存 DB/Redis/Storage のアーキテクチャ変更。
- Entra ID / UAMI / AOAI 向け RBAC の導入。

## 3. 目標アーキテクチャ

1. Azure OpenAI アカウント（Cognitive Services kind: `OpenAI`）を新規作成。
2. AOAI 内にモデルデプロイ（例: `gpt-4o-mini` / `text-embedding-3-large`）を作成。
3. AOAI API Key を安全に受け渡し（将来は Key Vault 連携を推奨）。
4. `api` / `worker` Container App には AOAI Endpoint / API Version / Deployment 名のみを IaC 設定する。
5. 外部アクセス制限は App Gateway（WAFなし）で入口を一元化し、Entra 認証で侵入制限を実施。
6. 併せて NSG でサブネット境界を制御し、必要最小限の到達性に限定する。
7. Dify には Azure OpenAI Key 認証を手動設定し、IaC ではキー値を保持しない。

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

## 4.2 変更: `modules/aca-env.bicep`

### 追加パラメータ案
- `aoaiEndpoint` (string)
- `aoaiApiVersion` (string)
- `aoaiChatDeployment` (string)
- `aoaiEmbeddingDeployment` (string)

### 変更内容
1. Dify コンテナ設定には AOAI 接続先情報（Endpoint / API Version / Deployment）のみを追加。
2. Entra ID 前提の設定（`AZURE_CLIENT_ID` など）は本計画から除外。
3. AOAI API Key は **人手で持ち込み**、IaC のパラメータ/環境変数/Secret 注入対象にしない。

## 4.3 変更: `main.bicep`

### 追加パラメータ案
- `aoaiAccountBase` (string)
- `aoaiSkuName` (string)
- `aoaiPublicNetworkAccess` (string)
- `aoaiApiVersion` (string)
- `aoaiChatDeploymentName` (string)
- `aoaiEmbeddingDeploymentName` (string)
- `aoaiChatModelName` / `aoaiEmbeddingModelName` (string)

### 依存関係
- `aoaiModule` -> `acaModule` の順で依存。
- `acaModule` へ AOAI endpoint/deployment を引き渡す。

### 命名
- 既存の `uniqueString(subscription().id, rg.name)` を流用し、グローバル一意性を担保。

## 4.4 変更: `deploy.ps1`

### 目的
- Bicep デプロイ後に NSG 適用状態を確認し、外部アクセス制限が期待どおりであることを検証する。

### 追加処理案
1. `az deployment sub create` 後、出力から `aoaiEndpoint` / `nsgName`（または NSG resourceId）を取得。
2. `az network nsg rule list` で許可 CIDR / Deny ルールを確認。
3. App Gateway 側の Entra 認証設定（認証必須・未認証遮断）を確認。
4. 必要に応じて到達性確認（認証済みのみ接続可）を実施。
5. API Key は手動投入前提のため、IaC/CI ログにキー文字列を出さないことを確認。

### 注意点
- `deploy.ps1` は現在ファイルアップロード処理を含むため、AOAI 関連チェックを追加する位置を明確化（Bicep 成功直後を推奨）。
- エラー時は既存と同様に `Write-Error` + `exit 1`。

## 5. パラメータ設計（`parameters.example.json` 追補案）

- `aoaiAccountBase`: `aoaidify`
- `aoaiSkuName`: `S0`
- `aoaiPublicNetworkAccess`: `Enabled`（将来的に Private Endpoint 化を検討）
- `publicAllowedCidrs`: `["10.0.0.0/8"]`（公開経路で許可する送信元CIDR）
- `nsgName`: `dify-ingress-nsg`
- `aoaiApiVersion`: `2024-10-21`（利用可能バージョンに合わせて更新）
- `aoaiChatDeploymentName`: `chat`
- `aoaiChatModelName`: `gpt-4o-mini`
- `aoaiEmbeddingDeploymentName`: `embedding`
- `aoaiEmbeddingModelName`: `text-embedding-3-large`

## 6. 実装ステップ

1. `modules/aoai.bicep` を作成し、AOAI アカウント+デプロイを定義。
2. `main.bicep` に新規パラメータとモジュール連携を追加。
3. `modules/aca-env.bicep` に AOAI 接続先情報（endpoint/version/deployment）のみ追加。
4. `modules/vnet.bicep`（または NSG 専用モジュール）に NSG とルールを追加し、対象サブネットへ関連付け。
5. `deploy.ps1` に NSG ルール確認 + 機微情報非出力チェックを追加。
6. `parameters.example.json` と README を更新。
7. What-If/本番デプロイで検証。

## 7. テスト計画

### IaC 構文
- `az bicep build --file main.bicep`
- `az deployment sub what-if --location <region> --template-file main.bicep --parameters parameters.json`

### ネットワーク
- NSG が対象サブネットに関連付け済みであること。
- App Gateway で未認証アクセスが拒否されること（Entra 認証必須）。
- NSG ルールが意図どおり適用されること。

### アプリ設定
- `api` / `worker` に AOAI 接続先情報が設定されていること。
- API Key は IaC では設定されず、手動運用手順に従って投入すること。
- Entra ID 前提の環境変数に依存していないこと。

### 動作
- Dify で Azure OpenAI モデル接続テストが成功すること。
- 埋め込みモデル呼び出しが成功すること。

## 8. ロールバック方針

- AOAI 連携の有効/無効をフラグ化し、問題時は AOAI 連携を停止可能にする。
- API Key の手動投入・ローテーション手順を運用 Runbook に明記する。

## 9. リスクと対策

1. **NSG ルール設計ミス（過剰遮断/過剰許可）**
   - 対策: 許可CIDRをパラメータ化し、`what-if` と疎通試験で検証。
2. **Dify の環境変数仕様差分（バージョン依存）**
   - 対策: 実装時に対象 Dify バージョンの公式仕様と突合。
3. **AOAI モデル/バージョン変更**
   - 対策: モデル名・バージョンの完全パラメータ化。
4. **API Key の手動運用ミス（投入漏れ/誤設定）**
   - 対策: 手順書整備、ダブルチェック、定期ローテーションを必須化。
5. **Entra 認証設定ミスによる意図しない侵入許可**
   - 対策: App Gateway 側で認証必須ポリシーをテンプレート化し、デプロイ後に必ず検証。
6. **NSG 適用漏れによる意図しない公開**
   - 対策: NSG の関連付け状態を `deploy.ps1` と運用監査で継続確認。

## 10. 受け入れ基準

- Bicep デプロイで AOAI が一貫して作成される。
- `api` と `worker` が AOAI に Key 認証でアクセスできる。
- `deploy.ps1` が Entra 認証設定と NSG ルール/関連付けを確認し、異常時に明確に失敗する。
- API Key が IaC パラメータやコンテナ環境変数として管理されていない。
- 既存リソース（PostgreSQL/Storage/Redis/ACA）の動作を阻害しない。
