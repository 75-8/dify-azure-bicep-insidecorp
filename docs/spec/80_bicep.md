# 80_bicep

## スコープ
- Bicep モジュール境界
- 依存関係
- デプロイ順序

## モジュール対応
- `vnet`
- `network-nsg`（新規）
- `app-gateway`（新規）
- `aoai`（新規）
- `aca-env`
- `storage` / `postgresql` / `redis-cache`
- `api`（将来 `apim`）

## 依存の基本形
1. vnet
2. network-nsg
3. app-gateway
4. aoai
5. storage/postgresql/redis
6. aca-env
7. api(apim) ※将来


## APIM 拡張時の前提
- `api(apim)` ドメイン実装時は APIM に Managed Identity を割り当てる。
- APIM の外部IdP連携（OAuth2.0）と内部バックエンド連携（MI）を分離設計する。

## 未確認事項（spec未記載・コード記載）
- 実在モジュールは `network/apim/keyvault/aca-env/postgresql/redis-cache/storage`。
- `80_bicep.md` 記載の `vnet`/`network-nsg`/`app-gateway`/`aoai` は `modules` 直下に同名モジュール未確認。
- `docs/directory.md` には `fileshare.bicep`/`vnet.bicep` の記載があるが、現行 `modules` には未確認。

