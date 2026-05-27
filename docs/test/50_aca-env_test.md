# 50_aca-env_test

## 対象
- ACA Environment
- Container Apps（web/api/worker/sandbox/plugin/ssrfproxy）

## テスト項目
- ACA Environment が internal 設定であること。
- external ingress が無効（または Gateway 経由に限定）であること。
- DB/Redis/Storage/AOAI への接続情報が正しく設定されること。
- 機微情報が平文環境変数で設定されていないこと。
