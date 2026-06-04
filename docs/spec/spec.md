# spec

本ファイルは全体境界と統合ルールを定義する。
詳細は各ドメイン仕様書を参照する。

## 全体方針
- 公開入口は Application Gateway ([appgw.bicep](file:///home/sept/dify-azure-bicep-insidecorp/infra/modules/appgw.bicep)) に限定する。
- 侵入制限は Entra 認証（OIDC）を基本とし、ACA 内の OAuth2 Proxy サイドカーにより未認証アクセスを遮断する。
- ネットワーク境界は NSG ([nsg.bicep](file:///home/sept/dify-azure-bicep-insidecorp/infra/modules/nsg.bicep)) および各サブネット設定で制御する。
- Azure OpenAI Service (AOAI) は Key 認証を利用し、API Key などの機微情報は Key Vault ([keyvault.bicep](file:///home/sept/dify-azure-bicep-insidecorp/infra/modules/keyvault.bicep)) にて管理する想定とする。

## 参照順序
1. [10_network.md](file:///home/sept/dify-azure-bicep-insidecorp/docs/spec/10_network.md)
2. [20_auth.md](file:///home/sept/dify-azure-bicep-insidecorp/docs/spec/20_auth.md)
3. [30_api.md](file:///home/sept/dify-azure-bicep-insidecorp/docs/spec/30_api.md)
4. [40_aoai.md](file:///home/sept/dify-azure-bicep-insidecorp/docs/spec/40_aoai.md)
5. [50_aca.md](file:///home/sept/dify-azure-bicep-insidecorp/docs/spec/50_aca.md)
6. [60_db.md](file:///home/sept/dify-azure-bicep-insidecorp/docs/spec/60_db.md)
7. [70_secret.md](file:///home/sept/dify-azure-bicep-insidecorp/docs/spec/70_secret.md)
8. [80_bicep.md](file:///home/sept/dify-azure-bicep-insidecorp/docs/spec/80_bicep.md)

## 経路アーキテクチャ（要点）
- **Dify UI 経路**: Client -> Application Gateway -> OAuth2 Proxy (Nginx Container App 内のサイドカー) -> Nginx -> Web UI (`web`)
- **Dify API 経路 (現状)**: Client -> Application Gateway -> OAuth2 Proxy -> Nginx -> API (`api`)
- **Dify API 経路 (将来/To-Be)**: Client -> APIM -> API (`api`) ※APIM ([apim.bicep](file:///home/sept/dify-azure-bicep-insidecorp/infra/modules/apim.bicep)) 経由の経路は現状プレースホルダーであり、未統合。

## modules 対応表（[directory.md](file:///home/sept/dify-azure-bicep-insidecorp/docs/directory.md) 準拠）

| modules | ドメイン仕様書 | 備考 |
|---|---|---|
| [nsg.bicep](file:///home/sept/dify-azure-bicep-insidecorp/infra/modules/nsg.bicep) | [10_network.md](file:///home/sept/dify-azure-bicep-insidecorp/docs/spec/10_network.md) | Network Security Group (NSG) の定義 |
| [network.bicep](file:///home/sept/dify-azure-bicep-insidecorp/infra/modules/network.bicep) | [10_network.md](file:///home/sept/dify-azure-bicep-insidecorp/docs/spec/10_network.md) | VNet/Subnet の定義 |
| [appgw.bicep](file:///home/sept/dify-azure-bicep-insidecorp/infra/modules/appgw.bicep) | [10_network.md](file:///home/sept/dify-azure-bicep-insidecorp/docs/spec/10_network.md) / [20_auth.md](file:///home/sept/dify-azure-bicep-insidecorp/docs/spec/20_auth.md) | Application Gateway の定義 |
| [apim.bicep](file:///home/sept/dify-azure-bicep-insidecorp/infra/modules/apim.bicep) | [30_api.md](file:///home/sept/dify-azure-bicep-insidecorp/docs/spec/30_api.md) | APIM (将来的な /v1 API 経路の保護) |
| [keyvault.bicep](file:///home/sept/dify-azure-bicep-insidecorp/infra/modules/keyvault.bicep) | [70_secret.md](file:///home/sept/dify-azure-bicep-insidecorp/docs/spec/70_secret.md) | Key Vault 管理 |
| [aca-env.bicep](file:///home/sept/dify-azure-bicep-insidecorp/infra/modules/aca-env.bicep) | [50_aca.md](file:///home/sept/dify-azure-bicep-insidecorp/docs/spec/50_aca.md) | ACA Environment / Apps オーケストレーション |
| [postgresql.bicep](file:///home/sept/dify-azure-bicep-insidecorp/infra/modules/postgresql.bicep) | [60_db.md](file:///home/sept/dify-azure-bicep-insidecorp/docs/spec/60_db.md) | PostgreSQL (Flexible Server, pgvector) |
| [redis-cache.bicep](file:///home/sept/dify-azure-bicep-insidecorp/infra/modules/redis-cache.bicep) | [60_db.md](file:///home/sept/dify-azure-bicep-insidecorp/docs/spec/60_db.md) | Azure Cache for Redis |
| [storage.bicep](file:///home/sept/dify-azure-bicep-insidecorp/infra/modules/storage.bicep) | [60_db.md](file:///home/sept/dify-azure-bicep-insidecorp/docs/spec/60_db.md) | Storage Account (Blob / Azure Files) |

> 目次（構成一覧）は [directory.md](file:///home/sept/dify-azure-bicep-insidecorp/docs/directory.md) を正とし、本表は `docs/spec` からの参照用とする。
