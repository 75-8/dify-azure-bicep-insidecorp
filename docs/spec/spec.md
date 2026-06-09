# spec

本ファイルは全体境界と統合ルールを定義する。
詳細は各ドメイン仕様書を参照する。

## 全体方針
- 公開入口は Application Gateway ([appgw.bicep]) に限定する。
- 侵入制限は Entra 認証（OIDC）を基本とし、ACA 内の OAuth2 Proxy サイドカーにより未認証アクセスを遮断する。
- ネットワーク境界は NSG ([nsg.bicep]) および各サブネット設定で制御する。
- Azure OpenAI Service (AOAI) は Key 認証を利用し、API Key などの機微情報は Key Vault ([keyvault.bicep]) にて管理する想定とする。

## 参照順序
1. [10_network.md]
2. [15_appgw.md]
3. [20_auth.md]
4. [30_api.md]
5. [40_aoai.md]
6. [50_aca.md]
7. [60_db.md]
8. [70_secret.md]
9. [80_bicep.md]

## 経路アーキテクチャ（要点）
- **Dify UI 経路**: Client -> Application Gateway -> OAuth2 Proxy (Nginx Container App 内のサイドカー) -> Nginx -> Web UI (`web`)
- **Dify API 経路 (現状)**: Client -> Application Gateway -> OAuth2 Proxy -> Nginx -> API (`api`)
- **Dify API 経路 (将来/To-Be)**: Client -> APIM -> API (`api`) ※APIM ([apim.bicep]) 経由の経路は現状プレースホルダーであり、未統合。

