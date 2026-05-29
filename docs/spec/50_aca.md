# 50_aca

## スコープ
- Azure Container Apps (ACA) Managed Environment / Container Apps。
- 対象実装は `infra/modules/aca-env.bicep` と `infra/modules/aca-env/` 配下の分割モジュール。
- `infra/main.bicep` からは `infra/modules/aca-env.bicep` を ACA 全体のオーケストレーション層として呼び出す。

## 方針
- ACA Environment は VNet 統合された internal managed environment とし、インフラストラクチャサブネットへ閉域配置する。
- Container Apps は `nginx/web/api/worker/sandbox/plugin/ssrfproxy` を構成単位とする。
- `web/api/worker/sandbox/plugin/ssrfproxy` は ACA Environment 内の内部通信を前提とし、external ingress は持たない。
- 外部からの入口は `nginx` Container App に集約する。`nginx` は external ingress を持つが、`allowedIngressCidrs` による許可リストと `deny-all` の IP 制限で社内・許可済み CIDR からの到達に限定する。
- カスタム証明書が提供される場合は ACA Environment に証明書を登録し、`nginx` ingress の custom domain に関連付ける。

## 実行責務の3分割
ACA 定義は従来の単一 `aca-env.bicep` に全リソースを直接記述する構成ではなく、実行責務を以下の 3 つに分割する。

1. **Platform 層 (`infra/modules/aca-env/platform.bicep`)**
   - Log Analytics workspace を作成する。
   - ACA Managed Environment を作成し、`vnetConfiguration.internal: true` で internal 化する。
   - Azure Files を ACA Environment storage として登録する。
   - 任意の Dify カスタム証明書を ACA Environment certificate として登録する。
   - 後続層が利用する ACA Environment ID、証明書 ID、storage resource name を出力する。

2. **Edge Runtime 層 (`infra/modules/aca-env/edge-runtime.bicep`)**
   - `nginx` Container App を作成し、公開入口、カスタムドメイン、IP 制限を管理する。
   - `ssrfproxy` Container App を作成し、internal ingress の Squid proxy としてアプリケーション実行層から利用させる。
   - `nginx` の FQDN を ACA アプリケーション URL として出力する。

3. **Application 層 (`infra/modules/aca-env/application.bicep`)**
   - Dify 実行コンポーネントである `web`、`api`、`worker`、`sandbox`、`plugin` Container Apps を作成する。
   - API / Worker / Plugin から PostgreSQL、Redis、Azure Blob Storage、Sandbox、SSRF proxy へ接続するための環境変数を設定する。
   - `sandbox` と `plugin` には Platform 層で登録した ACA Environment storage をマウントする。
   - 各アプリケーション ingress は internal とし、`nginx` 経由で到達させる。

## オーケストレーション層
- `infra/modules/aca-env.bicep` は ACA 全体のオーケストレーション層として継続利用する。
- `infra/main.bicep` は従来どおり `acaModule` として `infra/modules/aca-env.bicep` を参照し、上位モジュールの呼び出しインターフェースを維持する。
- オーケストレーション層は入力パラメータを受け取り、Platform → Edge Runtime → Application の順に分割モジュールへ引き渡す。
- Application 層は Platform 層の出力を利用し、Edge Runtime 層に依存してからデプロイすることで、入口系リソースとアプリケーション実行リソースの作成順序を明示する。
- `difyAppUrl` は Edge Runtime 層の `nginx` FQDN 出力をそのまま上位へ伝播する。

## Container Apps 構成
| App | 実装層 | Ingress | 主な責務 |
| --- | --- | --- | --- |
| `nginx` | Edge Runtime | external true | 公開入口、IP 制限、カスタムドメイン、Nginx 設定ファイルの Azure Files マウント |
| `ssrfproxy` | Edge Runtime | internal | Squid proxy。Sandbox / API 系の外向き通信を中継 |
| `sandbox` | Application | internal TCP 8194 | コード実行環境。`/dependencies` に Azure Files をマウントし、HTTP(S)_PROXY で `ssrfproxy` を利用 |
| `worker` | Application | なし | Dify Worker。DB、Redis、Blob、pgvector、Sandbox、Plugin Daemon と連携 |
| `api` | Application | internal 5001 | Dify API。DB、Redis、Blob、pgvector、Sandbox、Plugin Daemon と連携 |
| `plugin` | Application | internal 5002 | Plugin Daemon。DB、Redis、Blob と連携し、Plugin storage をマウント |
| `web` | Application | internal 3000 | Dify Web UI。API へ内部接続 |

## 連携
- AOAI: endpoint/version/deployment をアプリケーション設定として受け取る方針とする。
- DB: PostgreSQL FQDN、管理ユーザー、パスワード、Dify DB 名、Vector DB 名を Application 層へ渡し、Dify API / Worker / Plugin が利用する。
- Redis: host / primary key を Application 層へ渡し、キャッシュおよび Celery broker として利用する。
- Storage: Blob endpoint、account name、account key、container name を Application 層へ渡し、Dify のファイル保存先として利用する。
- Azure Files: Platform 層で `nginx`、`ssrfproxy`、`sandbox`、`plugin` 用の share を ACA Environment storage として登録し、各 Container App へマウントする。

## シークレット連携
- Bicep パラメータでは Storage account key、Redis primary key、PostgreSQL administrator password、証明書値・パスワードを `@secure()` として扱う。
- 現行実装では Application 層の Container Apps 環境変数に `@secure()` パラメータ値を渡している。
- Key Vault 参照を利用する場合は、Container Apps の secret / Key Vault reference と managed identity の設計を追加し、環境変数へ平文値を直接展開しない構成へ移行する。

## 実装との差分・注意事項
- 現行実装の `nginx` は external ingress であり、Gateway 専用公開ではない。公開制御は `allowedIngressCidrs` と `deny-all` の `ipSecurityRestrictions` によって行う。
- `web/api/sandbox/plugin/ssrfproxy` は internal ingress、`worker` は ingress なしで構成する。
- `infra/modules/aca-env.bicep` が従来の ACA モジュール名・呼び出し口を維持し、`infra/modules/aca-env/` 配下の 3 分割モジュールを内部で呼び出す。
