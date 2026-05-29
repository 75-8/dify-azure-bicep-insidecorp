# Agents Guide

このドキュメントは、リポジトリの構成とそれぞれのフォルダ・ファイルへのナビゲーションを提供します。

## リポジトリ構成

### 📋 ルートファイル

| ファイル | 説明 |
|---------|------|
| [`main.bicep`](./main.bicep) | メインのBicep構成ファイル。Azure リソースのプロビジョニング定義 |
| [`deploy.ps1`](./deploy.ps1) | PowerShellデプロイメントスクリプト。`az login` 後に実行 |
| [`parameters.example.json`](./parameters.example.json) | パラメータ設定のテンプレート。コピーして `parameters.json` を作成 |
| [`README.md`](./README.md) | プロジェクト全体の説明とデプロイ手順 |

### 📁 フォルダ構成

#### [`docs/`](./docs/)

ドキュメントとアーキテクチャ設計が格納されています。

**主なファイル:**
- `dify-azure-infra.drawio` - インフラ構成図（draw.io形式）
- `current-architecture-spec.yaml` - 現行アーキテクチャ仕様書
- `aoai-entra-auth-spec.md` - Azure OpenAI + Entra ID 認証設計ドキュメント
- `security_guardrails.md` - セキュリティ境界とNSG制御の提案

**参照:** 詳細は [`README.md` の Infrastructure Diagram セクション](./README.md#infrastructure-diagram-drawio) を確認してください。

#### [`modules/`](./modules/)

Bicep モジュール（再利用可能なコンポーネント）が格納されています。

**役割:**
- Azure リソース（Storage、PostgreSQL、Redis、ACA など）を モジュール化
- `main.bicep` から参照される個別リソース定義

**参照:** 各モジュールは `main.bicep` から以下のようにして利用されます：
```bicep
module storageModule './modules/storage.bicep' = {
  // ...
}
```

#### [`mountfiles/`](./mountfiles/)

コンテナへのマウント用設定ファイルが格納されています。

**役割:**
- アプリケーション設定ファイル
- コンテナ起動時に必要な初期化スクリプトやコンフィグ

**参照:** 詳細はスクリプトまたはドキュメントを確認してください。

#### [`terraform_old/`](./terraform_old/)

**⚠️ レガシー** - Terraform 実装（廃止）

現在のプロジェクトは **Bicep** で実装されています。本フォルダは過去の Terraform 構成の参考資料として保持されています。

**参照:** 新しいデプロイは [`main.bicep`](./main.bicep) と [`deploy.ps1`](./deploy.ps1) を使用してください。

詳細は [`terraform_old/README.md`](./terraform_old/README.md) を確認してください。

## クイックスタート

1. **リポジトリをクローン**
   ```bash
   git clone https://github.com/75-8/dify-azure-bicep-insidecorp.git
   cd dify-azure-bicep-insidecorp
   ```

2. **パラメータファイルを作成**
   ```bash
   cp parameters.example.json parameters.json
   # 必要な値を編集（パスワード、ドメインなど）
   ```

3. **Azure にログイン**
   ```bash
   az login
   az account set --subscription <subscription-id>
   ```

4. **デプロイ実行**
   ```bash
   ./deploy.ps1
   ```

詳細は [`README.md`](./README.md#kick-start) を参照してください。

## リソースマッピング

| Azure リソース | 役割 | 設定ファイル |
|---------------|------|----------|
| **Azure Container Apps** | Dify のマイクロサービス（nginx、web、api、worker、sandbox、ssrf_proxy） | `main.bicep` / `modules/` |
| **Azure Database for PostgreSQL** | DB・ベクトルDB | `main.bicep` / `modules/` |
| **Azure Cache for Redis** | キャッシュ・セッション | `main.bicep` / `modules/` |
| **Storage Account** | ファイルストレージ | `main.bicep` / `modules/` |
| **Virtual Network** | ネットワーク分離・セキュリティ | `main.bicep` |

## セキュリティに関する重要な注意

⚠️ **`parameters.json` には機密情報が含まれます**

- `.gitignore` で保護されています
- **決してコミット・プッシュしないでください**
- 本番環境では強力なパスワードを使用してください

詳細は [`README.md` の Security Notice セクション](./README.md#️-security-notice) を参照してください。

## トラブルシューティング

各フォルダの詳細については、以下を参照してください：

- **デプロイエラー** → [`README.md`](./README.md)
- **アーキテクチャ疑問** → [`docs/current-architecture-spec.yaml`](./docs/current-architecture-spec.yaml)
- **セキュリティ設定** → [`docs/security_guardrails.md`](./docs/security_guardrails.md)
- **旧Terraform参考** → [`terraform_old/README.md`](./terraform_old/README.md)
