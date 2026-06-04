# 30_api

## スコープ
- Dify API 経路 (`/v1/*`) の保護設計
- API Management (APIM) による認証制御方針
- 将来的なエンドポイント分離

## 現状の暫定経路 (As-Is)
現在、APIM 経由の経路はインフラに組み込まれておらず、Dify UI と同様に以下の経路でルーティングされ保護されている：
```text
Client -> Application Gateway (ポート 80/443)
       -> nginx Container App / OAuth2 Proxy (ポート 4180、Entra OIDC 認証強制)
       -> nginx (ポート 80)
       -> api Container App (ポート 5001)
```

## 将来的な目標構成 (To-Be)
UI 画面と API エンドポイントの認証ライフサイクルを分離するため、将来的に API 経路を APIM 経由に切り替える：
```text
[Dify UI 経路]
Client -> Application Gateway -> OAuth2 Proxy -> nginx -> web Container App (ポート 3000)

[Dify API 経路]
Client -> APIM (OAuth 2.0 Bearer トークン検証) -> api Container App (ポート 5001)
```

## Bicep モジュールステータス ([apim.bicep](file:///home/sept/dify-azure-bicep-insidecorp/infra/modules/apim.bicep))
- **現実装**: `infra/modules/apim.bicep` にて APIM リソース（Consumption/Developer SKU）が定義されている。
- **ID 構成**: APIM には `SystemAssigned` Managed Identity が有効化されている。
- **公開アクセス**: 現在 `publicNetworkAccess` は `'Enabled'` に設定されている。
- **制限**: 現行モジュールは APIM インスタンスの作成のみを行う最小限の定義であり、[main.bicep](file:///home/sept/dify-azure-bicep-insidecorp/infra/main.bicep) からはまだ呼び出されていない。また、OpenAPI 定義のインポート設定や、OAuth2 のトークン検証ポリシー定義は含まれていない。

## 将来の課題（APIM 統合時のロードマップ）
- **[main.bicep](file:///home/sept/dify-azure-bicep-insidecorp/infra/main.bicep) への組み込み**: APIM モジュール呼び出しの有効化。
- **ポリシーの実装**: JWT/OAuth2 トークン検証用のインバウンドポリシーの定義。
- **APIスキーマの取り込み**: Dify API の OpenAPI 仕様書インポートの自動化。
- **マネージド ID による保護**: APIM からバックエンド（`api` Container App）への接続時に Managed Identity による認証/アクセス制御を検討。


