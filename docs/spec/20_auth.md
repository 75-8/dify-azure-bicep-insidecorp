# 20_auth

## スコープ
- 侵入制限の認証方式
- 運用上の認可境界

## 方針
- インターネットからの侵入は Entra 認証で制限する。
- App Gateway（または将来の API Gateway）で認証必須を強制する。
- 未認証は 401、権限不足は 403 を返す。

## 保留事項
- App Gateway 単体での実現方式は要設計（必要に応じて補助コンポーネントを検討）。

## OAuth2 Proxy 方針
- App Gateway 単体で要件を満たせない場合、OAuth2 Proxy を認証補助コンポーネントとして利用する。
- OAuth2 Proxy は Entra ID（OIDC）と連携し、未認証リクエストを遮断する。
- 認証済みヘッダの受け渡し仕様（例: user/sub/tenant）を API 側と事前合意する。


## 経路分離（認証境界）
- `/ui` は OAuth2 Proxy で認証を強制する。
- `/v1` は APIM で OAuth 2.0 を強制する。
- 認証境界を分離し、設定変更影響を局所化する。

## 未確認事項（spec未記載・コード記載）
- `modules` 配下に Entra/OIDC 認証設定を直接実装する Bicep 定義は現時点で未確認。
- 認証強制の実体は `infra/modules/apim.bicep` の APIM 作成までで、ポリシー/IdP連携設定は未確認。

