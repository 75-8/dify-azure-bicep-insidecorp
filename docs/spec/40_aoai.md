# 40_aoai (Azure AI Foundry)

## スコープ
- Azure AI Foundry (AI Services, AI Hub, AI Project) の作成方針
- Private Endpoint および Private DNS Zone による閉域接続設計
- SSRF Proxy を経由しない直接接続設計（バイパス）
- API Key およびモデル定義の運用仕様 (モデルデプロイのマニュアル化)

## 設計および実装仕様

### 1. リソースプロビジョニング (IaC)
- [aoai.bicep](../../infra/modules/aoai.bicep) モジュールを更新し、[main.bicep](../../infra/main.bicep) の Step 3（データ層の並列デプロイ）として統合。
- **Azure AI Services**: `kind: 'AIServices'` および `sku: { name: 'S0' }` で作成。
- **Azure AI Hub**: `kind: 'Hub'` で作成。Storage Account, Key Vault, Application Insights と連携。
- **Azure AI Project**: `kind: 'Project'` で作成し、AI Hub に関連付け。
- **モデルデプロイ（手動運用）**: アップデート頻度および運用の柔軟性を考慮し、LLMモデルのデプロイは Bicep からは行わず、Azure AI Studio ポータルまたは CLI による**マニュアル操作**とする。

### 2. リソース命名規則とパラメータ化
命名規則（「命名規則」）に基づき、各リソース名はパラメータからベース名を受け取り、リソースグループ固有のハッシュを付与してユニークに構成する。
- **Azure AI Services**: `${aiServicesNameBase}${rgNameHex}` (デフォルト: `difyais${rgNameHex}`)
- **Azure AI Hub**: `${aiHubNameBase}-${rgNameHex}` (デフォルト: `dify-aihub-${rgNameHex}`)
- **Azure AI Project**: `${aiProjectNameBase}-${rgNameHex}` (デフォルト: `dify-aiproject-${rgNameHex}`)

### 3. 閉域接続設計 (Private Link)
- **パブリックアクセス遮断**:
  - Azure AI Services: `publicNetworkAccess` を `Disabled` に設定し、`networkAcls.defaultAction` を `Deny` とする。
  - Azure AI Hub: `publicNetworkAccess` を `Disabled` に設定。
- **Private Endpoint**: `PrivateLinkSubnet` に配置。
  - **AI Services 用 PE (`pe-aiservices`)**: Target Sub-Resource: `account`。
  - **AI Hub 用 PE (`pe-aihub`)**: Target Sub-Resource: `amlworkspace`。
- **Private DNS Zone**:
  - AI Services 用: `privatelink.openai.azure.com` を作成し VNet にリンク（Dify が Azure OpenAI API エンドポイントとして直接接続するため）。
  - AI Hub 用: `privatelink.api.azureml.ms` を作成し VNet にリンク。

### 4. SSRF Proxy バイパス設計
- Dify の外部通信プロキシ（SSRF Proxy / Squid）経由でのアクセスで発生し得るボトルネックや誤ルーティングを避けるため、`.openai.azure.com` ドメインへの通信はプロキシを介さず、VNet 経由で直接通信（`always_direct`）するよう [squid.conf](../../infra/mountfiles/ssrfproxy/squid.conf) にバイパス ACL を実装。

### 5. 運用・セキュリティ仕様（API Key 手動管理）
- **Credential 非保持原則の例外**:
  通常は機微情報を Key Vault またはコンテナ環境変数で自動参照させますが、AI Services 連携においてはセキュリティの観点および Dify の仕様に準拠し、API Key を IaC やコンテナの環境変数に保持させません。
- **設定手順**:
  1. インフラデプロイ後、デプロイ出力から AI Services エンドポイント URL を取得する。
  2. 管理者が Dify Web UI（管理者コンソール）にアクセスする。
  3. Azure OpenAI の設定画面で、取得したエンドポイント URL と、Azure Portal 等から手動取得した API Key を入力してモデル連携を有効化する。
