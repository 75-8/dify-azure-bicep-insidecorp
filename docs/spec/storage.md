# storage ドメイン仕様

対象モジュール: `modules/storage.bicep`

- Storage Account と必要な Blob/File Share を作成する。
- Private Endpoint + Private DNS による閉域接続を提供する。
- Public Network Access は無効を基本とする。
