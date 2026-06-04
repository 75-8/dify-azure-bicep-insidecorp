# 20_auth

## スコープ
- 侵入制限・認証方式の定義
- OAuth2 Proxy を利用した認証構成
- 将来的な認証境界の分離

## 方針
- インターネット（または許可された IP）からの流入に対して、Microsoft Entra ID (OIDC) による認証制限を適用する。
- 認証未済みのリクエストは OAuth2 Proxy によって遮断し、サインインページ（Entra ID）へリダイレクトする。
- 認証後は、カスタム HTTP ヘッダ（`X-Auth-Request-Email` 等）を介してログインユーザー情報を後続のアプリケーション層に伝える。

## 実装構成 (Bicep実装仕様)
OAuth2 Proxy は ACA 環境上の `nginx` Container App 内にサイドカーコンテナとして稼働し、以下のフローで動作する（詳細は [edge-runtime.bicep](file:///home/sept/dify-azure-bicep-insidecorp/infra/modules/aca-env/edge-runtime.bicep) 参照）：

1. **ルーティング**: Application Gateway ([appgw.bicep](file:///home/sept/dify-azure-bicep-insidecorp/infra/modules/appgw.bicep)) は、バックエンドポート `4180` (OAuth2 Proxy のリッスンポート) にトラフィックを送る。
2. **認証検証**: OAuth2 Proxy コンテナは、Entra OIDC プロバイダー (`https://login.microsoftonline.com/${tenantId}/v2.0`) と通信し認証検証を行う。
3. **ローカルプロキシ**: 認証済みトラフィックのみを、同一 Container App 内のローカル `nginx` コンテナ（ポート `80`）へ中継（Upstream）する。
4. **コンポーネント転送**: `nginx` はリクエストのパスに応じて、同じ ACA 環境内の internal サービス (`web:3000` または `api:5001`) にトラフィックを転送する。

## パラメータ設定 (Key Vault 連携想定)
OAuth2 Proxy の動作に必要な以下のパラメータは、[main.bicep](file:///home/sept/dify-azure-bicep-insidecorp/infra/main.bicep) で引数として定義される：
- `oauth2ProxyClientId`: Entra アプリ登録のクライアント ID
- `oauth2ProxyClientSecret`: クライアントシークレット（セキュリティ保護 `@secure()` 対象）
- `oauth2ProxyTenantId`: テナント ID
- `oauth2ProxyCookieSecret`: 暗号化用クッキーシークレット（セキュリティ保護 `@secure()` 対象）

## 将来の課題（API認証の分離）
- 現状、API (`/v1`) パスも同一の OAuth2 Proxy / UI 認証フローを通っている。
- 将来的には、API 経路は APIM ([apim.bicep](file:///home/sept/dify-azure-bicep-insidecorp/infra/modules/apim.bicep)) 経由とし、OAuth 2.0 (Bearer Token) 検証ポリシーを適用して UI のセッションクッキー認証と境界を分離する。


