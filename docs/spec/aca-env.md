# aca-env ドメイン仕様

対象モジュール: `modules/aca-env.bicep`

- ACA Environment を internal で構成する。
- `web/api/worker/sandbox/plugin/ssrfproxy` を VNet 内運用する。
- AOAI 設定は endpoint/version/deployment のみを受け取る。
- AOAI API Key は IaC で注入しない（手動投入）。
