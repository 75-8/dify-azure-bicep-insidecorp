# vnet ドメイン仕様

対象モジュール: `modules/vnet.bicep`

- VNet と主要サブネット（AppGateway/ACA/Postgres/PrivateLink）を提供する。
- CIDR は環境差分を考慮してパラメータ化する。
- サブネット名とアドレス帯は下流モジュール参照の基準値とする。
