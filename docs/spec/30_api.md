# 30_api

## スコープ
- Dify API 経路の保護設計（実装保留）
- API インターフェース先行定義

## To-Be
`Client -> APIM -> (Private) ACA api`

## インターフェース方針
- OAuth 2.0（Bearer Token）必須。
- パスベース versioning（`/v1/...`）。
- エラー形式は `code` / `message` / `traceId` を共通化。

## 実装保留
- `modules/apim.bicep` の作成
- OAuth連携設定
- OpenAPI import
