# spec

本ファイルは全体境界と統合ルールを定義する。
詳細は `docs/spec/10_network.md` 〜 `docs/spec/80_secret.md` を参照する。

## 全体方針
- 公開入口は Gateway に限定する。
- 侵入制限は Entra 認証を基本とし、必要に応じて OAuth2 Proxy を併用する。
- ネットワーク境界は NSG で制御する。
- AOAI は Key 認証を維持し、API Key を含む機微情報は Key Vault で管理する。

## 参照順序
1. 10_network
2. 20_auth
3. 30_api（OAuth2 Proxy 暫定案を含む）
4. 40_aoai
5. 50_aca
6. 60_db
7. 70_bicep
8. 80_secret
