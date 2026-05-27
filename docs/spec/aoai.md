# aoai ドメイン仕様

対象モジュール: `modules/aoai.bicep`（新規）

- AOAI アカウントとモデルデプロイを作成する。
- 出力は endpoint / deployment 名を中心にする。
- 認証方式は Key を採用する。
- API Key は IaC で保持せず、運用で手動投入する。
