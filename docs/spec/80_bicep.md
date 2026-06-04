# 80_bicep

## スコープ
- Bicep モジュールの境界定義
- 各モジュール間の依存関係
- [main.bicep](file:///home/sept/dify-azure-bicep-insidecorp/infra/main.bicep) におけるデプロイ順序

## モジュール対応表 (実装状況)

| 役割名 | 物理 Bicep テンプレートファイル | 概要 |
|---|---|---|
| `nsgs` | [nsg.bicep](file:///home/sept/dify-azure-bicep-insidecorp/infra/modules/nsg.bicep) | ネットワークセキュリティグループの作成 (AppGw, ACA, PrivateLink, Postgres) |
| `network` | [network.bicep](file:///home/sept/dify-azure-bicep-insidecorp/infra/modules/network.bicep) | 仮想ネットワーク (VNet) および各サブネット (委譲設定・NSGバインド含む) の作成 |
| `keyvault` | [keyvault.bicep](file:///home/sept/dify-azure-bicep-insidecorp/infra/modules/keyvault.bicep) | Key Vault、Private Endpoint およびプライベート DNS 設定の作成 |
| `storage` | [storage.bicep](file:///home/sept/dify-azure-bicep-insidecorp/infra/modules/storage.bicep) | Storage Account、Blob/File の PE、および File Shares の一括作成 |
| `postgresql` | [postgresql.bicep](file:///home/sept/dify-azure-bicep-insidecorp/infra/modules/postgresql.bicep) | PostgreSQL Flexible Server、データベース (`dify`/`vector`)、拡張機能の有効化 |
| `redis` | [redis-cache.bicep](file:///home/sept/dify-azure-bicep-insidecorp/infra/modules/redis-cache.bicep) | Azure Cache for Redis および Private Endpoint の作成 |
| `aca-env` | [aca-env.bicep](file:///home/sept/dify-azure-bicep-insidecorp/infra/modules/aca-env.bicep) | ACA Environment と各サービス (`nginx`, `ssrfproxy`, `web`, `api`, `worker` 等) のオーケストレーション |
| `appgw` | [appgw.bicep](file:///home/sept/dify-azure-bicep-insidecorp/infra/modules/appgw.bicep) | Application Gateway およびルーティング・SSL証明書・プローブの構成 |
| `apim` | [apim.bicep](file:///home/sept/dify-azure-bicep-insidecorp/infra/modules/apim.bicep) | APIM プレースホルダーモジュール（現在 [main.bicep](file:///home/sept/dify-azure-bicep-insidecorp/infra/main.bicep) からは未統合） |

## 依存関係およびデプロイ順序 (main.bicep準拠)
[main.bicep](file:///home/sept/dify-azure-bicep-insidecorp/infra/main.bicep) におけるモジュールの作成順序（依存性）は以下の順で行われる：

1. **`nsgs`**: 各サブネット用の NSG を先行して定義する。
2. **`networkModule`**: `nsgs` の Resource ID 出力を受け取り、各サブネットへ NSG をバインドして VNet をデプロイする。
3. **`keyVaultModule` / `storageModule` / `postgresqlModule` / `redisModule`**: `networkModule` よりサブネット ID を受け取り、Private Endpoint または委譲されたネットワーク空間に各インフラリソースを並列デプロイする。
4. **`acaModule`**:
   - `networkModule` から ACA 委譲サブネット ID を取得する。
   - `storageModule`、`postgresqlModule`、`redisModule` のホスト名や接続文字列などの出力を受け取り、ACA 環境および Dify のコンポーネント群をデプロイする。
   - 内部デプロイ順序: Platform (`platform.bicep`) → Edge Runtime (`edge-runtime.bicep`) → Application (`application.bicep`)
5. **`appGwModule`**: `networkModule` の Gateway サブネット ID、および `acaModule` から出力された Nginx Ingress の内部 FQDN を受け取り、リバースプロキシおよび証明書検証経路をデプロイする。

## 将来的な拡張・検討事項
- **`apim` の統合**: [apim.bicep](file:///home/sept/dify-azure-bicep-insidecorp/infra/modules/apim.bicep) を [main.bicep](file:///home/sept/dify-azure-bicep-insidecorp/infra/main.bicep) の依存関係（4 と 5 の間など）に組み込む。
- **`aoai` モジュールの追加**: Azure OpenAI Service リソースを作成する `aoai.bicep` を新規追加し、3 のタイミングで並行デプロイする設計を追加する。
