# 40_aoai_test

## 対象
- AOAI リソース
- Dify 連携設定
- Key Vault シークレット参照

## テスト項目
- AOAI アカウント/デプロイが作成されること。
- `endpoint/apiVersion/deployment` が実行系へ反映されること。
- AOAI API Key が IaC パラメータやログに出力されないこと。
- AOAI API Key が Key Vault 管理であること。
