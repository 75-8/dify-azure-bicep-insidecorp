# 30_api

## スコープ
- Dify API 経路の保護設計（実装保留）
- API インターフェース先行定義

## To-Be
`Client -> APIM (or App Gateway + OAuth2 Proxy) -> (Private) ACA api`

## インターフェース方針
- OAuth 2.0（Bearer Token）必須。
- パスベース versioning（`/v1/...`）。
- エラー形式は `code` / `message` / `traceId` を共通化。

## 実装保留
- `modules/apim.bicep` の作成
- OAuth連携設定
- OpenAPI import


## OAuth2 Proxy 連携（APIM実装前の暫定案）
- APIM 実装までの暫定として `App Gateway -> OAuth2 Proxy -> ACA api` 経路を許容する。
- OAuth2 Proxy で OIDC 検証を実施し、API は信頼ヘッダを検証する。
- 暫定構成の終了条件（APIM移行完了）を Runbook に明記する。
