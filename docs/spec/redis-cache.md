# redis-cache ドメイン仕様

対象モジュール: `modules/redis-cache.bicep`

- Redis を private endpoint 経由で提供する。
- 有効化条件は上位フラグ（例: isAcaEnabled）に従う。
- ACA からの接続要件（6380/TLS）を満たす。
