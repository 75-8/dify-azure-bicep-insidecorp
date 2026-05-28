# 40_aoai

## スコープ
- Azure OpenAI リソース
- Dify 連携方式

## 方針
- 認証方式は Key 認証を採用する。
- API Key は IaC に含めず、Key Vault で管理する。
- IaC で扱うのは endpoint / apiVersion / deployment 情報のみ。

## 要件
- AOAI アカウントおよびモデルデプロイを作成可能にする。
- モデル名/バージョンはパラメータ化する。


## シークレット管理
- AOAI API Key は Key Vault に登録し、実行系から参照する。
- 平文の手動配布は行わない。

## 未確認事項（spec未記載・コード記載）
- `modules` 配下に AOAI リソース作成モジュール（例: `aoai.bicep`）は現時点で未確認。
- `infra/modules/aca-env.bicep` には AOAI 接続情報パラメータ（endpoint/apiVersion/deployment）が未定義。

