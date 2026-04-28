## dify-azure-bicep
Deploy [langgenius/dify](https://github.com/langgenius/dify), an LLM based chat bot app on Azure with Bicep.

> **Note**: This repository rewrites the contents of [dify-azure-terraform](https://github.com/nikawang/dify-azure-terraform) in Bicep and defaults to the current upstream Dify container image tags from `docker-compose-template.yaml`.

### Topology
Front-end access:
- nginx -> Azure Container Apps (Serverless)

Back-end components:
- web -> Azure Container Apps (Serverless)
- api -> Azure Container Apps (Serverless)
- worker -> Azure Container Apps (minimum of 1 instance)
- sandbox -> Azure Container Apps (Serverless)
- ssrf_proxy -> Azure Container Apps (Serverless)
- db -> Azure Database for PostgreSQL
- vectordb -> Azure Database for PostgreSQL
- redis -> Azure Cache for Redis

Before you provision Dify, please check and set the variables in parameters.json file.

### Bicep Variables Documentation

This document provides detailed descriptions of the variables used in the Bicep configuration for setting up the Dify environment.

### ⚠️ Security Notice

**IMPORTANT**: The `parameters.json` file contains sensitive information such as database passwords and certificate passwords. 

Before deploying:

1. **Copy the example file**: 
   ```bash
   cp parameters.example.json parameters.json
   ```

2. **Set secure passwords**: Edit `parameters.json` and replace the placeholder values with your own secure passwords:
   - `pgsqlPassword`: PostgreSQL database password (minimum 8 characters, must include uppercase, lowercase, and numbers)
   - `acaCertPassword`: Certificate password (only required if `isProvidedCert` is `true`)

3. **Do NOT commit** the `parameters.json` file to version control. It is already included in `.gitignore`.

**Password Requirements**:
- Use unique, strong passwords for each deployment
- Do not reuse passwords across environments
- Consider using a password manager to generate and store secure passwords

### Kick Start
```bash
az login
az account set --subscription <subscription-id>

# Copy and configure parameters file
cp parameters.example.json parameters.json
# Edit parameters.json with your secure passwords

./deploy.ps1
```

### Deployment Parameters

#### Region

- **Parameter Name**: `location`
- **Type**: `string`
- **Default Value**: `japaneast`

#### Resource Group Prefix

- **Parameter Name**: `resourceGroupPrefix`
- **Type**: `string`
- **Default Value**: `rg-dify`

### Network Parameters

#### VNET Address IP Prefix

- **Parameter Name**: `ipPrefix`
- **Type**: `string`
- **Default Value**: `10.99`

#### Storage Account

- **Parameter Name**: `storageAccountBase`
- **Type**: `string`
- **Default Value**: `acadifytest`

#### Storage Account Container

- **Parameter Name**: `storageAccountContainer`
- **Type**: `string`
- **Default Value**: `dfy`

### Redis

- **Parameter Name**: `redisNameBase`
- **Type**: `string`
- **Default Value**: `acadifyredis`

#### PostgreSQL Flexible Server

- **Parameter Name**: `psqlFlexibleBase`
- **Type**: `string`
- **Default Value**: `acadifypsql`

#### PostgreSQL User

- **Parameter Name**: `pgsqlUser`
- **Type**: `string`
- **Default Value**: `adminuser`

#### PostgreSQL Password

- **Parameter Name**: `pgsqlPassword`
- **Type**: `string`
- **Default Value**: `YOUR_SECURE_PASSWORD_HERE`
- **Note**: Specified as a secure parameter. **Must be changed before deployment.** Use a strong password with at least 8 characters including uppercase, lowercase, and numbers.

### ACA Environment Parameters

#### ACA Environment

- **Parameter Name**: `acaEnvName`
- **Type**: `string`
- **Default Value**: `dify-aca-env`

#### ACA Log Analytics Workspace

- **Parameter Name**: `acaLogaName`
- **Type**: `string`
- **Default Value**: `dify-loga`

#### IF BRING YOUR OWN CERTIFICATE

- **Parameter Name**: `isProvidedCert`
- **Type**: `bool`
- **Default Value**: `false`


##### ACA Certificate Path (if isProvidedCert is true)

- **Parameter Name**: `acaCertBase64Value`
- **Type**: `string`
- **Default Value**: ``
- **Note**: Specified as a secure parameter

##### ACA Certificate Password (if isProvidedCert is true)

- **Parameter Name**: `acaCertPassword`
- **Type**: `string`
- **Default Value**: `YOUR_CERT_PASSWORD_HERE`
- **Note**: Specified as a secure parameter. **Only required if you bring your own certificate** (`isProvidedCert` is `true`). Must be changed before deployment.

##### ACA Dify Customer Domain (if isProvidedCert is false)

- **Parameter Name**: `acaDifyCustomerDomain`
- **Type**: `string`
- **Default Value**: `dify.example.com`

#### ACA App Minimum Instance Count

- **Parameter Name**: `acaAppMinCount`
- **Type**: `int`
- **Default Value**: `1`

#### Container Images

##### Dify API Image

- **Parameter Name**: `difyApiImage`
- **Type**: `string`
- **Default Value**: `langgenius/dify-api:1.13.3`

#### Dify Sandbox Image

- **Parameter Name**: `difySandboxImage`
- **Type**: `string`
- **Default Value**: `langgenius/dify-sandbox:0.2.14`

##### Dify Web Image

- **Parameter Name**: `difyWebImage`
- **Type**: `string`
- **Default Value**: `langgenius/dify-web:1.13.3`

##### Dify Plugin Daemon Image

- **Parameter Name**: `difyPluginDaemonImage`
- **Type**: `string`
- **Default Value**: `langgenius/dify-plugin-daemon:0.5.3-local`

### Infrastructure Diagram (draw.io)

インフラ構成を draw.io で可視化したファイルを追加しました。

- `docs/dify-azure-infra.drawio`

使い方:
1. [diagrams.net](https://app.diagrams.net/) を開く
2. **File > Open From > Device** で `docs/dify-azure-infra.drawio` を選択
3. 必要に応じて環境名・CIDR・接続線を編集

### Current Architecture Spec (YAML)

Bicep の現在構成を仕様書として整理した YAML を追加しました。

- `docs/current-architecture-spec.yaml`

この YAML には、以下を含みます。
- パラメータ既定値と命名規則
- ネットワーク (VNet / サブネット)
- Storage / PostgreSQL / (任意) Redis
- ACA Environment と各 Container App の役割・依存関係
- 主な通信フローと出力

### Security Hardening (Corporate Network Only Access)

以下の設定で、外部からのアクセスを制限し、社内ネットワークからのみアクセスできる構成にしています。

- ACA Environment を Internal Load Balancer モード (`internal: true`) に設定
- `nginx` ingress に CIDR ベースの `ipSecurityRestrictions` を適用
- `allowedIngressCidrs` パラメータで許可ネットワークを定義 (既定: `10.0.0.0/8`)
- Storage Account の Public Network Access を `Disabled` に変更し、`networkAcls.defaultAction` を `Deny` に変更
- Redis の Non-SSL ポートを無効化 (`enableNonSslPort: false`)

> 運用時は `allowedIngressCidrs` に実際の社内ネットワーク CIDR (VPN / ExpressRoute で到達可能な送信元) を設定してください。

### Azure OpenAI + Entra ID (Managed Identity)

`main.bicep` で Azure OpenAI と UAMI (User Assigned Managed Identity) をオプション構成として追加しています。

主な追加パラメータ:
- `useEntraIdForAoai` (`true` 推奨)
- `aoaiAccountBase`
- `aoaiSkuName`
- `aoaiPublicNetworkAccess`
- `aoaiAllowedIpRanges` (公開アクセスを許可するIP/CIDR)
- `aoaiApiVersion`
- `aoaiChatDeploymentName` / `aoaiChatModelName` / `aoaiChatModelVersion`
- `aoaiEmbeddingDeploymentName` / `aoaiEmbeddingModelName` / `aoaiEmbeddingModelVersion`
- `difyUamiName`

有効時は `api` / `worker` の Container App に UAMI を割り当て、`AZURE_OPENAI_ENDPOINT` や `AZURE_CLIENT_ID` などの環境変数を自動設定します。

`deploy.ps1` は Bicep デプロイ後に AOAI の `Cognitive Services OpenAI User` ロール割当の伝播をリトライ確認します。
