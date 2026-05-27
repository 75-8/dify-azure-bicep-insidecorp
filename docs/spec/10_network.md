# 10_network

## スコープ
- VNet / Subnet 設計
- NSG 設計
- Application Gateway（WAFなし）
- Private Endpoint / Private DNS

## 方針
- 公開入口は Application Gateway のみに限定する。
- ACA は internal 運用とし、外部公開しない。
- サブネット境界は NSG で最小権限制御する。

## 主要要件
- `AppGatewaySubnet` / `ACASubnet` / `PostgresSubnet` / `PrivateLinkSubnet` を定義する。
- 各サブネットへ NSG を関連付ける。
- App Gateway backend は ACA internal endpoint を参照する。
