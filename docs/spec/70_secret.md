# 70_secret

## スコープ
- シークレット管理方針
- Key Vault 連携
- 運用（投入/ローテーション/監査）

## 共通セキュリティ方針
- アプリケーションで利用する機微情報（データベースパスワード、Redis 接続キー、OAuth2 クライアントシークレットなど）は一元的に保護し、テンプレートファイルや CI/CD ログに平文で記録しない。
- Key Vault は完全閉域化し、接続元を VNet 内部に限定する。

## Key Vault 実装仕様 (詳細は [keyvault.bicep](file:///home/sept/dify-azure-bicep-insidecorp/infra/modules/keyvault.bicep))
- **アクセス制御**: `enableRbacAuthorization: false` とし、従来の **Access Policies** (アクセスポリシー) による認証を採用する。許可するポリシーは [main.bicep](file:///home/sept/dify-azure-bicep-insidecorp/infra/main.bicep) の `keyVaultAccessPolicies` パラメータ経由で明示的に制御する。
- **ネットワーク**: `publicNetworkAccess` を `'Disabled'` に設定。`PrivateLinkSubnet` にプライベートエンドポイント (`pe-keyvault`) を配置し、プライベート DNS リンク (`privatelink.vaultcore.azure.net`) を構成する。

## 現状のシークレット連携ステータス (As-Is)
- **パラメータ保護**: パラメータファイルおよびテンプレート定義上、シークレット値は `@secure()` として定義されている。
- **直接渡し**: 現在、機微情報（データベース管理者パスワードや Redis プライマリエクスポートキーなど）は、Container App 側の環境変数へ直接平文で展開されている。Key Vault 内でのシークレット自動生成や、Container App から Managed Identity を使用した Key Vault 参照 (`@Microsoft.KeyVault(...)`) による動的参照設定は実装されていない。

## 将来的なシークレット連携強化 (To-Be)
- **シークレット IaC 登録**: デプロイ時に Bicep を通じてシークレット（例: DB 接続情報）を Key Vault に書き込み自動生成する。
- **Managed Identity 認証**: 各 Container App (`api`, `worker` 等) にシステム割り当て、またはユーザー割り当てのマネージド ID を付与し、Key Vault への読み取りアクセスポリシーをバインドする。
- **Container Apps 連携**: Container Apps の設定で、Key Vault 参照をシークレットオブジェクトとして定義し、環境変数からはキー値のみを参照するように変更（平文の環境変数表示を回避）。


