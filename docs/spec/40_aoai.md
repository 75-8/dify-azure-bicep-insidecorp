# 40_aoai

## スコープ
- Azure OpenAI Service (AOAI) の作成方針
- Private Endpoint および Private DNS Zone による閉域接続設計
- SSRF Proxy を経由しない直接接続設計（バイパス）
- API Key およびモデル定義の運用仕様

## 設計および実装仕様

### 1. リソースプロビジョニング (IaC)
- [aoai.bicep](../../infra/modules/aoai.bicep) モジュールを新規導入し、[main.bicep](../../infra/main.bicep) の Step 3（データ層の並列デプロイ）として統合。
- **Cognitive Services アカウント**: `kind: 'OpenAI'` および `sku: { name: 'S0' }` で作成。
- **モデルデプロイ**: 以下のモデル定義をデフォルト値としてデプロイ。パラメータ化されており環境ごとにオーバーライド可能。
  - `gpt-5-4` (`gpt-5.4` バージョン `2026-04-01`)
  - `text-embedding-ada-003` (`text-embedding-ada-003` バージョン `2`)

### 2. 閉域接続設計 (Private Link)
- **パブリックアクセス遮断**: アカウントの `publicNetworkAccess` を `Disabled` に設定し、`networkAcls.defaultAction` を `Deny` とする。
- **Private Endpoint**: `PrivateLinkSubnet` に配置し、`pe-aoai` として構成（Target Sub-Resource: `account`）。
- **Private DNS Zone**: `privatelink.openai.azure.com` を作成し、仮想ネットワーク (`vnet-${location}`) にリンク。これによって、VNet 内のコンポーネントが AOAI エンドポイント FQDN を Private Endpoint のプライベート IP に自動的に解決する。

### 3. SSRF Proxy バイパス設計
- Dify の外部通信プロキシ（SSRF Proxy / Squid）経由でのアクセスで発生し得るボトルネックや誤ルーティングを避けるため、`.openai.azure.com` ドメインへの通信はプロキシを介さず、VNet 経由で直接通信（`always_direct`）するよう [squid.conf](../../infra/mountfiles/ssrfproxy/squid.conf) にバイパス ACL を実装。

### 4. 運用・セキュリティ仕様（API Key 手動管理）
- **Credential 非保持原則の例外**:
  通常は機微情報を Key Vault またはコンテナ環境変数で自動参照させますが、AOAI 連携においてはセキュリティの観点および Dify の仕様に準拠し、API Key を IaC やコンテナの環境変数に保持させません。
- **設定手順**:
  1. インフラデプロイ後、デプロイ出力から AOAI エンドポイント URL を取得する。
  2. 管理者が Dify Web UI（管理者コンソール）にアクセスする。
  3. Azure OpenAI の設定画面で、取得したエンドポイント URL と、Azure Portal 等から手動取得した API Key を入力してモデル連携を有効化する。



