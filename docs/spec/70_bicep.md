# 70_bicep

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
