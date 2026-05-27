# app-gateway ドメイン仕様

対象モジュール: `modules/app-gateway.bicep`（新規）

- Public IP + Application Gateway（WAFなし）を構成する。
- HTTPS listener / probe / backend settings を管理する。
- 侵入制限は Entra 認証で行う。
- Backend は ACA internal endpoint を参照する。
