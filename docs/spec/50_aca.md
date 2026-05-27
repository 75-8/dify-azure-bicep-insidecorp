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
