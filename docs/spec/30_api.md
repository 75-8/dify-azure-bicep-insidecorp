# 30_api

## スコープ
- Dify API 経路の保護設計（実装保留）
- API インターフェース先行定義

## To-Be
`Client -> APIM (/v1) -> (Private) ACA api`

## インターフェース方針
- OAuth 2.0（Bearer Token）必須。
- パスベース versioning（`/v1/...`）。
- エラー形式は `code` / `message` / `traceId` を共通化。

## 実装保留
- `modules/apim.bicep` の作成
- OAuth連携設定
- OpenAPI import


## OAuth2 Proxy 連携（UI 経路）
- OAuth2 Proxy は Dify `/ui` リクエスト経路の認証保護を担当する。
- OAuth2 Proxy は Entra ID(OIDC)で認証し、未認証アクセスを遮断する。
- `/v1` API 経路は APIM 側で保護し、OAuth2 Proxy 側と責務分離する。


## 経路分離方針
- **/ui 系リクエスト経路**: `Client -> App Gateway -> OAuth2 Proxy -> ACA(web/ui)`
- **/v1 API リクエスト経路**: `Client -> APIM -> ACA(api)`
- UI と API は経路・責務を分離し、ポリシーを独立管理する。
