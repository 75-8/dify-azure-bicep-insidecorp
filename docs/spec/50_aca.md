# 50_aca

## スコープ
- ACA Environment / Container Apps

## 方針
- ACA Environment は internal。
- `web/api/worker/sandbox/plugin/ssrfproxy` は VNet 内通信のみ。
- external ingress は廃止し、公開は Gateway 経由に限定する。

## 連携
- AOAI: endpoint/version/deployment を受け取る。
- DB/Redis/Storage: private 接続情報で疎通する。


## シークレット連携
- コンテナ実行時に必要な機微情報は Key Vault 参照で取得する。
- 環境変数へ平文を直書きしない。

## 未確認事項（spec未記載・コード記載）
- `modules/aca-env.bicep` の `nginx` Container App は `ingress.external: true` で公開設定。
- `modules/aca-env.bicep` は `allowedIngressCidrs` によるIP許可 + `deny-all` で制御。
- `modules/aca-env.bicep` では Storage/Redis/PostgreSQL の接続秘密情報を `@secure` パラメータで受け取るが、Key Vault 参照定義は未確認。

