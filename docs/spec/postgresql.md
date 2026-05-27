# postgresql ドメイン仕様

対象モジュール: `modules/postgresql.bicep`

- PostgreSQL Flexible Server を private 接続で構成する。
- Delegated subnet / private DNS を前提にする。
- ACA からの接続要件（5432）を満たす。
