# 10_network

## スコープ
- VNet / Subnet 設計
- NSG (Network Security Group) 設計
- Private Endpoint / Private DNS

※ Application Gateway のトラフィック制御・ルーティング設計は [15_appgw.md](./15_appgw.md) にて分離管理。

## 方針
- 公開入口は Application Gateway ([appgw.bicep](../../infra/modules/appgw.bicep)) のみに限定する。詳細ルーティング設計は [15_appgw.md](./15_appgw.md) を参照。
- ACA 環境 ([aca-env.bicep](../../infra/modules/aca-env.bicep)) は internal 運用とし、インターネットへ直接露出させない。
- 各サブネット境界は NSG ([nsg.bicep](../../infra/modules/nsg.bicep)) を用いて最小権限で制御する。

## サブネット設計仕様
VNet 名は `vnet-${location}` とし、以下のサブネットおよび NSG を構成する（詳細は [network.bicep]参照）：

| サブネット名 | アドレス帯 (CIDR) | 関連付け NSG | 役割と特徴 |
|---|---|---|---|
| `PrivateLinkSubnet` | `ipPrefix.0.0/24` | `nsg-privatelink` | Key Vault、Redis、Storage などの Private Endpoint を配置する。 |
| `ACASubnet` | `ipPrefix.2.0/23` | `nsg-aca` | ACA 環境に委譲（delegation）され、Dify コンポーネントをホストする。 |
| `PostgresSubnet` | `ipPrefix.4.0/24` | `nsg-postgres` | PostgreSQL Flexible Server に委譲される。`Microsoft.Storage` サービスエンドポイントを有効化する。 |
| `AppGwSubnet` | `ipPrefix.5.0/24` | `nsg-appgw` | Application Gateway 専用のサブネット。委譲なし。 |

## 主なトラフィック制御ルール（NSG 仕様）
- **`nsg-appgw`**: インターネットまたは指定された `allow_ip` からの HTTP/HTTPS (80/443) トラフィック、および `GatewayManager` からの管理トラフィックのみを許可。
- **`nsg-aca`**: `AppGwSubnet` からの OAuth2 Proxy ポート (4180) へのインバウンド接続、および ACA サブネット内部の通信のみを許可。
- **`nsg-privatelink`**: ACA サブネット (`ACASubnet`) からの HTTPS (443) および Redis (6379) トラフィックのみを許可。
- **`nsg-postgres`**: ACA サブネット (`ACASubnet`) からの PostgreSQL (5432) トラフィックのみを許可。

## Bicep実装との整合性
- **`vnet-${location}` の固定命名**: [network.bicep] 内で定義されており、パラメータで変更せずリソースグループの場所に基づいて自動決定される。
- **PostgreSQL サブネットのサービスエンドポイント**: Azure File Share または Blob 接続等のため、PostgreSQL の委譲サブネットに `Microsoft.Storage` サービスエンドポイントが構成されている。
- **Application Gateway のバックエンドターゲット**: ACA にデプロイされた Nginx Container App の内部 FQDN (`nginx.<default-domain>`) を直接バックエンドプールに指定している。


