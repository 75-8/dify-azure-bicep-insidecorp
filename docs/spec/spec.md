# spec

本ファイルは全体境界と統合ルールを定義する。
詳細は `docs/spec/10_network.md` 〜 `docs/spec/70_bicep.md` を参照する。

## 全体方針
- 公開入口は Gateway に限定する。
- 侵入制限は Entra 認証を基本とする。
- ネットワーク境界は NSG で制御する。
- AOAI は Key 認証、API Key は IaC 管理しない。

## 参照順序
1. 10_network
2. 20_auth
3. 30_api
4. 40_aoai
5. 50_aca
6. 60_db
7. 70_bicep
