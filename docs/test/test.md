# test

本ファイルはテスト仕様の親ドキュメントです。
詳細は `docs/test/10_network_test.md` 〜 `docs/test/99_e2e_test.md` を参照します。

## テスト方針
- 仕様（`docs/spec/*`）に対してドメイン単位で検証する。
- 段階は単体（ドメイン）→統合（E2E）で実施する。
- シークレット値はテストログへ出力しない。

## 参照順序
1. 10_network_test
2. 20_auth_test
3. 30_api_test
4. 40_aoai_test
5. 50_aca-env_test
6. 99_e2e_test
