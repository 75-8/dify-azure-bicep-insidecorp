# 40_aoai

## スコープ
- Azure OpenAI リソース
- Dify 連携方式

## 方針
- 認証方式は Key 認証を採用する。
- API Key は IaC に含めない（手動投入）。
- IaC で扱うのは endpoint / apiVersion / deployment 情報のみ。

## 要件
- AOAI アカウントおよびモデルデプロイを作成可能にする。
- モデル名/バージョンはパラメータ化する。
