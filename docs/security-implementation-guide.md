# セキュリティ実装ガイド

このドキュメントは、Dify 環境のセキュリティ強化、特に機微情報（シークレット）の管理方法を記載します。

参照: [docs/spec/70_secret.md](./spec/70_secret.md), [docs/task_list.md](./task_list.md#s1-セキュリティ-環境変数への機微情報直接記載)

---

## 現状

### ❌ セキュリティリスク: 環境変数への平文記載

**現在の実装 (application.bicep / edge-runtime.bicep)**:
```bicep
env: [
  {
    name: 'DB_PASSWORD'
    value: postgresAdminPassword  // 平文で環境変数に展開
  }
  {
    name: 'OAUTH2_PROXY_CLIENT_SECRET'
    value: oauth2ProxyClientSecret  // 平文で環境変数に展開
  }
]
```

**問題点**:
- Container App のコンソール / ログから秘密値が見える
- `az containerapp show` で機微情報が出力される
- 監査ログに秘密値が含まれる

---

## 改善目標 (To-Be)

### ✅ Key Vault Reference による保護

**目標実装**:
```bicep
// Container App: Managed Identity を有効化
identity: {
  type: 'SystemAssigned'
}

// Secret reference を定義
secrets: [
  {
    name: 'db-password'
    keyVaultUrl: '${keyVaultUri}secrets/db-password/'
  }
  {
    name: 'oauth2-client-secret'
    keyVaultUrl: '${keyVaultUri}secrets/oauth2-client-secret/'
  }
]

// 環境変数: secretRef で参照
env: [
  {
    name: 'DB_PASSWORD'
    secretRef: 'db-password'  // 秘密値はログに出現しない
  }
  {
    name: 'OAUTH2_PROXY_CLIENT_SECRET'
    secretRef: 'oauth2-client-secret'
  }
]
```

**メリット**:
- 秘密値がコンソール / ログに出現しない
- Key Vault で統一的な監査ログが取得される
- ローテーション時は Key Vault 側のみ更新

---

## 実装手順

### 1. Key Vault シークレット登録

#### 方法 A: Bicep で自動化（推奨・実装予定）

**keyvault.bicep** に以下を追加:

```bicep
param postgresAdminPassword string
@secure()

param oauth2ProxyClientSecret string
@secure()

// ... (他のシークレット)

// PostgreSQL パスワード
resource postgresPasswordSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  name: '${keyVault.name}/db-password'
  properties: {
    value: postgresAdminPassword
  }
}

// OAuth2 Proxy クライアントシークレット
resource oauth2SecretSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  name: '${keyVault.name}/oauth2-client-secret'
  properties: {
    value: oauth2ProxyClientSecret
  }
}

// 出力: 登録済みシークレット名
output secretNames object = {
  dbPassword: postgresPasswordSecret.name
  oauth2Secret: oauth2SecretSecret.name
}
```

#### 方法 B: 手動登録（当面の暫定手順）

```bash
# Key Vault にシークレットを登録（Azure CLI）
az keyvault secret set \
  --vault-name dify-kv \
  --name db-password \
  --value 'YOUR_POSTGRES_PASSWORD'

az keyvault secret set \
  --vault-name dify-kv \
  --name oauth2-client-secret \
  --value 'YOUR_OAUTH2_SECRET'

# ほか必要なシークレット...
```

### 2. Container App に Managed Identity を付与

**application.bicep / edge-runtime.bicep**:

```bicep
// 各 Container App に以下を追加
identity: {
  type: 'SystemAssigned'  // システム割り当て Managed Identity
}
```

### 3. Key Vault アクセスポリシー設定

**Managed Identity に Key Vault 権限を付与**:

```bicep
// main.bicep の keyVaultAccessPolicies パラメータに以下を設定
// （パラメータファイルで指定するか、Bicep内で生成）

keyVaultAccessPolicies: [
  {
    tenantId: subscription().tenantId
    objectId: acaModule.outputs.webAppPrincipalId  // web Container App の Managed Identity ID
    permissions: {
      secrets: [
        'get'
        'list'
      ]
    }
  }
  {
    tenantId: subscription().tenantId
    objectId: acaModule.outputs.apiAppPrincipalId  // api Container App の Managed Identity ID
    permissions: {
      secrets: [
        'get'
        'list'
      ]
    }
  }
  // ... (各 Container App)
]
```

**或いは手動設定（Azure CLI）**:

```bash
# 各 Container App の Principal ID を取得して登録
# 例: web Container App
WEB_PRINCIPAL_ID=$(az containerapp show \
  --resource-group rg-dify-japaneast \
  --name web \
  --query identity.principalId -o tsv)

az keyvault set-policy \
  --vault-name dify-kv \
  --object-id $WEB_PRINCIPAL_ID \
  --secret-permissions get list
```

### 4. Container App 環境変数を Secret Reference に変更

**application.bicep**:

```bicep
// Before: 平文記載
env: [
  {
    name: 'DB_PASSWORD'
    value: postgresAdminPassword  // ❌ 平文
  }
]

// After: Key Vault reference
secrets: [
  {
    name: 'db-password'
    keyVaultUrl: '${keyVaultUri}secrets/db-password/'
  }
]

env: [
  {
    name: 'DB_PASSWORD'
    secretRef: 'db-password'  // ✅ 秘密値は参照
  }
]
```

### 5. 必須シークレット一覧

以下のシークレットは Key Vault で管理すべき：

| シークレット名 | 用途 | 管理元 |
|---|---|---|
| `db-password` | PostgreSQL admin password | `postgresAdminPassword` parameter |
| `db-vector-password` | PostgreSQL vector DB password | `postgresAdminPassword` parameter (同一) |
| `redis-password` | Redis primary key | `redisPrimaryKey` parameter |
| `oauth2-client-secret` | Entra App Registration client secret | `oauth2ProxyClientSecret` parameter |
| `oauth2-cookie-secret` | OAuth2 Proxy cookie encryption secret | `oauth2ProxyCookieSecret` parameter |
| `storage-account-key` | Storage account key | `storageAccountKey` parameter |
| `dify-secret-key` | Dify SECRET_KEY | Generate securely |
| `plugin-daemon-key` | Plugin daemon API key | Generate securely |
| `plugin-inner-api-key` | Plugin inner API key | Generate securely |

---

## 検証手順

### デプロイ後の確認

```bash
# 1. Container App が Managed Identity を持っているか確認
az containerapp show \
  --resource-group rg-dify-japaneast \
  --name web \
  --query identity

# 2. Key Vault にシークレットが登録されているか確認
az keyvault secret list \
  --vault-name dify-kv

# 3. Container App が Key Vault secret にアクセス可能か確認
# (Application内でシークレット値を使用した動作確認)
az containerapp exec \
  --resource-group rg-dify-japaneast \
  --name web \
  --command "echo \$DB_PASSWORD"
  # Output: (空か実際の値、ログに出現しない)
```

### ログ確認

```bash
# Azure Monitor ログで秘密値が記録されていないか確認
az monitor log-analytics query \
  --workspace rg-dify-japaneast \
  --analytics-query "ContainerAppConsoleLogs | where Log contains 'PASSWORD' or Log contains 'SECRET'"
```

---

## ロードマップ

| 優先度 | フェーズ | 内容 | 期限 |
|---|---|---|---|
| **P0** | Phase 1 | 方針確定、ドキュメント作成（本ガイド） | 完了 |
| **P0** | Phase 2 | keyvault.bicep に secret 作成ロジック追加 | Sprint A |
| **P1** | Phase 3 | application/edge-runtime.bicep に secret reference 実装 | Sprint B |
| **P1** | Phase 4 | 運用手順（Key Vault secret ローテーション、監査）作成 | Sprint C |

---

## FAQ

### Q1: 既存デプロイメントへの適用方法は?

**A**: 既存環境では以下の手順で段階的に移行:

1. Key Vault にシークレットを事前登録（手動または CLI スクリプト）
2. 各 Container App に access policy を設定
3. 環境変数を secret reference に変更（Container App の再デプロイ必要）
4. 動作確認後、旧平文環境変数を削除

### Q2: secret reference が解決できない場合のデバッグは?

**A**: 以下を確認:

- [ ] Container App に Managed Identity が有効か
- [ ] Key Vault access policy が設定されているか
- [ ] シークレット名は正確か (keyVaultUrl の形式確認)
- [ ] Key Vault への network access は許可されているか (firewall 設定)
- Container App ログで "Key Vault secret not found" エラーを確認

### Q3: 開発環境と本番環境でシークレットを分ける方法は?

**A**: Key Vault 名またはシークレット名でサフィックスを付与:

```bicep
param environment string  // 'dev', 'prod'

// Key Vault 名
param keyVaultName string = 'dify-kv-${environment}'

// または secret 名
var secretSuffix = environment == 'prod' ? '-prod' : '-dev'
keyVaultUrl: '${keyVaultUri}secrets/db-password${secretSuffix}/'
```

---

## 参考資料

- [Azure Key Vault reference in Azure Container Apps](https://learn.microsoft.com/en-us/azure/container-apps/manage-secrets)
- [Container Apps managed identity](https://learn.microsoft.com/en-us/azure/container-apps/managed-identity)
- [Key Vault access policies](https://learn.microsoft.com/en-us/azure/key-vault/general/assign-access-policy)
