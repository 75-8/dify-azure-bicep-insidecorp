# アーキテクチャ

Dify on Azure のシステムアーキテクチャと各コンポーネントの相互関係を図式化する。

## 1. 全体アーキテクチャ

```mermaid
graph TB
    subgraph Internet["🌐 Internet"]
        Client["クライアント<br/>(Browser/API Consumer)"]
    end

    subgraph Azure["☁️ Azure"]
        subgraph PublicLayer["🟦 Public Layer"]
            PIP["Public IP<br/>(dify-appgw-pip)"]
            AppGw["Application Gateway<br/>(appgw.bicep)"]
        end

        subgraph NetworkLayer["🟦 Network Layer"]
            VNet["VNet: vnet-${location}"]
            AppGwSubnet["AppGwSubnet<br/>(10.x.5.0/24)"]
            ACASubnet["ACASubnet<br/>(10.x.2.0/23)"]
            PostgresSubnet["PostgresSubnet<br/>(10.x.4.0/24)"]
            PrivateLinkSubnet["PrivateLinkSubnet<br/>(10.x.0.0/24)"]
            NSG["NSG (Network Security Groups)"]
        end

        subgraph ComputeLayer["🟩 Compute Layer (ACA Environment)"]
            ACAEnv["Azure Container Apps<br/>Environment (internal)"]
            
            subgraph EdgeRuntime["Edge Runtime"]
                Nginx["nginx<br/>(External Ingress)<br/>- Public Entry Point<br/>- OAuth2 Proxy Sidecar"]
                SSRF["ssrfproxy<br/>(Squid)"]
            end

            subgraph ApplicationRuntime["Application Runtime"]
                Web["web<br/>(Port 3000)"]
                API["api<br/>(Port 5001)"]
                Worker["worker<br/>(Async Tasks)"]
                Sandbox["sandbox<br/>(Port 8194)"]
                Plugin["plugin<br/>(Port 5002)"]
            end
        end

        subgraph DataLayer["🟨 Data Layer (VNet Private)"]
            subgraph PrivateEndpoints["Private Endpoints<br/>(PrivateLinkSubnet)"]
                PE_KV["pe-keyvault"]
                PE_Redis["pe-redis"]
                PE_Blob["pe-blob"]
                PE_File["pe-file"]
            end

            subgraph DataServices["Data Services"]
                KV["Key Vault<br/>(keyvault.bicep)"]
                Redis["Azure Cache<br/>for Redis<br/>(redis-cache.bicep)"]
                Blob["Storage Account<br/>Blob Storage<br/>(storage.bicep)"]
                FileShare["Azure Files<br/>(nginx, sandbox, etc.)"]
            end

            PostgreSQL["PostgreSQL<br/>Flexible Server<br/>(postgresql.bicep)<br/>- dify DB<br/>- vector DB (pgvector)"]
        end

        subgraph FutureLayer["🟦 Future Layer (To-Be)"]
            APIM["API Management<br/>(apim.bicep)<br/>[Future]"]
            AOAI["Azure OpenAI<br/>Service<br/>[Future]"]
        end
    end

    Client -->|HTTP/HTTPS| PIP
    PIP -->|Port 80/443| AppGw
    AppGw -->|Port 4180<br/>Path-Based Routing| Nginx
    
    AppGw -->|"/v1/* , /api/*"<br/>Future Route| APIM
    
    VNet -.-> AppGwSubnet
    VNet -.-> ACASubnet
    VNet -.-> PostgresSubnet
    VNet -.-> PrivateLinkSubnet

    AppGwSubnet -.-> AppGw
    ACASubnet -.-> ACAEnv

    Nginx -->|Port 4180<br/>OAuth2 Auth| Nginx
    Nginx -->|Port 80<br/>HTTP| Web
    Nginx -->|Port 80<br/>HTTP| API

    API -->|Port 5001| API
    Web -->|Port 3000| Web
    API -->|Internal| Worker
    API -->|HTTP Proxy| SSRF

    Sandbox -->|Mount| FileShare
    Plugin -->|Mount| FileShare
    Nginx -->|Mount| FileShare

    ACAEnv -->|Private<br/>Connection| PE_Redis
    ACAEnv -->|Private<br/>Connection| PE_KV
    ACAEnv -->|Private<br/>Connection| PE_Blob
    ACAEnv -->|Private<br/>Connection| PE_File

    PE_KV -.->|DNS| KV
    PE_Redis -.->|DNS| Redis
    PE_Blob -.->|DNS| Blob
    PE_File -.->|DNS| FileShare

    ACAEnv -->|FQDN<br/>postgres.database...| PostgreSQL

    KV -.->|Stores| Secrets["Secrets:<br/>- DB Password<br/>- Redis Key<br/>- OAuth2 Secret"]

    style Client fill:#fff,stroke:#666
    style Internet fill:#e1f5ff,stroke:#01579b
    style Azure fill:#f1f8e9,stroke:#33691e
    style PublicLayer fill:#bbdefb,stroke:#1565c0
    style NetworkLayer fill:#bbdefb,stroke:#1565c0
    style ComputeLayer fill:#c8e6c9,stroke:#2e7d32
    style DataLayer fill:#fff9c4,stroke:#f57f17
    style FutureLayer fill:#e0e0e0,stroke:#424242
    style EdgeRuntime fill:#a5d6a7,stroke:#1b5e20
    style ApplicationRuntime fill:#81c784,stroke:#1b5e20
    style Secrets fill:#ffe082,stroke:#f57f17
```

## 2. トラフィックフロー図

### UI アクセス経路
```mermaid
graph LR
    User["👤 User<br/>Browser"]
    
    User -->|1. HTTP/HTTPS| AppGw["Application Gateway"]
    AppGw -->|2. Path: /<br/>Port 4180| OAuth2["OAuth2 Proxy<br/>(nginx sidecar)"]
    OAuth2 -->|3a. Auth Check<br/>via Entra ID| Entra["🔐 Microsoft<br/>Entra ID"]
    OAuth2 -->|3b. If Auth OK<br/>Port 80| Nginx["nginx<br/>Container App"]
    Nginx -->|4. Upstream<br/>Port 3000| Web["web App<br/>(Dify UI)"]
    Web -->|5. API Calls| API["api App"]
    API -->|6. Queries| DB["PostgreSQL<br/>Redis<br/>Blob Storage"]
    
    style User fill:#fff,stroke:#666
    style AppGw fill:#bbdefb,stroke:#1565c0
    style OAuth2 fill:#fff9c4,stroke:#f57f17
    style Entra fill:#f8bbd0,stroke:#c2185b
    style Nginx fill:#c8e6c9,stroke:#2e7d32
    style Web fill:#a5d6a7,stroke:#1b5e20
    style API fill:#a5d6a7,stroke:#1b5e20
    style DB fill:#ffe082,stroke:#f57f17
```

### API アクセス経路（現状）
```mermaid
graph LR
    Consumer["👤 API Consumer"]
    
    Consumer -->|1. HTTP/HTTPS<br/>Path: /v1/* | AppGw["Application Gateway"]
    AppGw -->|2. Port 4180| OAuth2["OAuth2 Proxy<br/>(nginx sidecar)"]
    OAuth2 -->|3a. Auth Check<br/>Session Cookie| OAuth2
    OAuth2 -->|3b. If Auth OK<br/>Port 80| Nginx["nginx<br/>Container App"]
    Nginx -->|4. Upstream<br/>Port 5001| API["api App<br/>(Dify API)"]
    API -->|5. Queries| Resources["PostgreSQL<br/>Redis<br/>Blob Storage"]
    
    Note["⚠️ Note: API 認証は<br/>UI と同一の<br/>セッション方式"]
    
    style Consumer fill:#fff,stroke:#666
    style AppGw fill:#bbdefb,stroke:#1565c0
    style OAuth2 fill:#fff9c4,stroke:#f57f17
    style Nginx fill:#c8e6c9,stroke:#2e7d32
    style API fill:#a5d6a7,stroke:#1b5e20
    style Resources fill:#ffe082,stroke:#f57f17
    style Note fill:#ffcccc,stroke:#c62828
```

### API アクセス経路（将来予定）
```mermaid
graph LR
    Consumer["👤 API Consumer"]
    
    Consumer -->|1. HTTP/HTTPS<br/>Bearer Token<br/>Path: /v1/*| APIM["API Management<br/>(APIM)"]
    APIM -->|2. Token Validation<br/>Policy| APIM
    APIM -->|3. If Valid<br/>Port 5001| API["api App<br/>(Dify API)"]
    API -->|4. Queries| Resources["PostgreSQL<br/>Redis<br/>Blob Storage"]
    
    APIM -->|Key Vault<br/>Reference| KV["Key Vault"]
    
    Note["✅ Future: API 認証を<br/>Bearer Token に分離"]
    
    style Consumer fill:#fff,stroke:#666
    style APIM fill:#e0e0e0,stroke:#424242
    style API fill:#a5d6a7,stroke:#1b5e20
    style Resources fill:#ffe082,stroke:#f57f17
    style KV fill:#fff9c4,stroke:#f57f17
    style Note fill:#ccffcc,stroke:#2e7d32
```

## 3. ネットワークセキュリティ図

```mermaid
graph TB
    Internet["🌐 Internet"]
    AppGw["Application Gateway<br/>(Subnet: AppGwSubnet)"]
    
    subgraph VNet["Azure VNet: vnet-${location}"]
        subgraph AppGwSubnet_Detail["AppGwSubnet<br/>(10.x.5.0/24)"]
            AppGw
            NSG_AppGw["NSG: nsg-appgw<br/>✅ Allow: HTTP/HTTPS (80,443)<br/>✅ Allow: GatewayManager<br/>❌ Deny: Other"]
        end

        subgraph ACASubnet_Detail["ACASubnet<br/>(10.x.2.0/23)"]
            ACA["ACA Environment<br/>(nginx, web, api, worker...)"]
            NSG_ACA["NSG: nsg-aca<br/>✅ Allow: AppGwSubnet → port 4180<br/>✅ Allow: Internal traffic<br/>❌ Deny: Other"]
        end

        subgraph PostgresSubnet_Detail["PostgresSubnet<br/>(10.x.4.0/24)"]
            PostgreSQL["PostgreSQL<br/>(Delegated to Microsoft.DBforPostgreSQL)"]
            NSG_Postgres["NSG: nsg-postgres<br/>✅ Allow: ACASubnet → port 5432<br/>✅ Allow: Backup service<br/>❌ Deny: Other"]
        end

        subgraph PrivateLinkSubnet_Detail["PrivateLinkSubnet<br/>(10.x.0.0/24)"]
            PE["Private Endpoints<br/>(Key Vault, Redis, Storage)"]
            NSG_PL["NSG: nsg-privatelink<br/>✅ Allow: ACASubnet → port 443<br/>✅ Allow: ACASubnet → port 6379<br/>❌ Deny: Other"]
        end
    end

    Internet -->|⚠️ Port 80,443 ONLY| AppGw
    
    AppGw -->|Internal<br/>Port 4180| ACA
    ACA -->|Private Link| PE
    ACA -->|Private Link| PostgreSQL

    style Internet fill:#e1f5ff,stroke:#01579b
    style VNet fill:#f1f8e9,stroke:#33691e
    style AppGwSubnet_Detail fill:#bbdefb,stroke:#1565c0
    style ACASubnet_Detail fill:#c8e6c9,stroke:#2e7d32
    style PostgresSubnet_Detail fill:#fff9c4,stroke:#f57f17
    style PrivateLinkSubnet_Detail fill:#f8bbd0,stroke:#c2185b
    style NSG_AppGw fill:#ffcccc,stroke:#c62828
    style NSG_ACA fill:#ccffcc,stroke:#2e7d32
    style NSG_Postgres fill:#fff9cc,stroke:#f57f17
    style NSG_PL fill:#ffccff,stroke:#c2185b
```

## 4. コンテナアプリケーション層構成

```mermaid
graph TB
    subgraph ACAEnv["Azure Container Apps Environment<br/>(Internal, VNet integrated)"]
        
        subgraph EdgeLayer["Edge Runtime Layer"]
            Nginx["nginx Container App<br/>━━━━━━━━━━━━━━━<br/>Image: official nginx:latest<br/>Ingress: External (port 4180)<br/>Mount: Azure Files (nginx/)<br/>━━━━━━━━━━━━━━━<br/>Sidecar: oauth2-proxy<br/>- Entra OIDC auth<br/>- Custom header injection"]
            
            SSRF["ssrfproxy Container App<br/>━━━━━━━━━━━━━━━<br/>Image: Squid proxy<br/>Ingress: Internal (port 3128)<br/>Mount: Azure Files (ssrfproxy/)<br/>━━━━━━━━━━━━━━━<br/>Used by: API/Sandbox<br/>HTTPS_PROXY env"]
        end

        subgraph AppLayer["Application Layer"]
            Web["web Container App<br/>━━━━━━━━━━━━━━━<br/>Ingress: Internal (port 3000)<br/>Runtime: Node.js<br/>━━━━━━━━━━━━━━━<br/>Depends on:<br/>- api"]
            
            API["api Container App<br/>━━━━━━━━━━━━━━━<br/>Ingress: Internal (port 5001)<br/>Runtime: Python/FastAPI<br/>━━━━━━━━━━━━━━━<br/>Depends on:<br/>- PostgreSQL (dify DB)<br/>- Redis (cache/broker)<br/>- Blob (file storage)<br/>- Sandbox (code exec)<br/>- Plugin"]
            
            Worker["worker Container App<br/>━━━━━━━━━━━━━━━<br/>Ingress: None<br/>Runtime: Celery worker<br/>━━━━━━━━━━━━━━━<br/>Depends on:<br/>- PostgreSQL<br/>- Redis (broker)<br/>- Blob"]
            
            Sandbox["sandbox Container App<br/>━━━━━━━━━━━━━━━<br/>Ingress: Internal (port 8194)<br/>Runtime: Python sandbox<br/>Mount: Azure Files (sandbox/)<br/>━━━━━━━━━━━━━━━<br/>Security:<br/>- Restricted env<br/>- SSRF proxy"]
            
            Plugin["plugin Container App<br/>━━━━━━━━━━━━━━━<br/>Ingress: Internal (port 5002)<br/>Runtime: Plugin daemon<br/>Mount: Azure Files (plugin/)<br/>━━━━━━━━━━━━━━━<br/>Depends on:<br/>- PostgreSQL<br/>- Redis<br/>- Blob"]
        end
    end

    Nginx -.->|Sidecar| Nginx
    Nginx -->|Upstream<br/>port 3000| Web
    Nginx -->|Upstream<br/>port 5001| API

    Web -->|API<br/>port 5001| API
    API -->|Enqueue| Worker
    API -->|Exec<br/>port 8194| Sandbox
    API -->|Load<br/>port 5002| Plugin

    Sandbox -->|HTTPS_PROXY| SSRF
    API -->|HTTP_PROXY| SSRF

    style ACAEnv fill:#f1f8e9,stroke:#33691e,stroke-width:3px
    style EdgeLayer fill:#c8e6c9,stroke:#2e7d32
    style AppLayer fill:#a5d6a7,stroke:#1b5e20
    style Nginx fill:#81c784,stroke:#1b5e20,stroke-width:2px
    style SSRF fill:#81c784,stroke:#1b5e20
    style Web fill:#66bb6a,stroke:#1b5e20
    style API fill:#66bb6a,stroke:#1b5e20
    style Worker fill:#66bb6a,stroke:#1b5e20
    style Sandbox fill:#66bb6a,stroke:#1b5e20
    style Plugin fill:#66bb6a,stroke:#1b5e20
```

## 5. シークレット・認証フロー

```mermaid
graph TB
    subgraph Mgmt["🔐 Management"]
        Admin["Infrastructure<br/>Administrator"]
        ParamFile["parameters.json<br/>(@secure fields)"]
    end

    subgraph Bicep["🔨 Bicep Deployment"]
        MainBicep["main.bicep"]
        KeyVaultModule["keyvault.bicep"]
        ACAModule["aca-env.bicep"]
    end

    subgraph Runtime["⚙️ Runtime"]
        KV["Key Vault"]
        ContainerApps["Container Apps<br/>(web, api, worker...)"]
        EnvVars["Environment Variables<br/>(@secure)"]
    end

    subgraph Future["🟦 Future (To-Be)"]
        MI["Managed Identity<br/>(SystemAssigned)"]
        KVRef["Key Vault Reference<br/>@Microsoft.KeyVault(...)"]
        SecretObj["Secret Object<br/>(Not exposed)"]
    end

    Admin -->|Input| ParamFile
    ParamFile -->|Sensitive Data| MainBicep
    MainBicep -->|Deploy| KeyVaultModule
    KeyVaultModule -->|Create/Update| KV
    MainBicep -->|Deploy| ACAModule
    ACAModule -->|Environment| ContainerApps
    ACAModule -->|Pass| EnvVars

    ContainerApps -->|Read| EnvVars

    MI -.->|Future Auth| KV
    KV -.->|Future Reference| KVRef
    KVRef -.->|Future Value| SecretObj
    SecretObj -.->|Future Mount| ContainerApps

    style Mgmt fill:#f8bbd0,stroke:#c2185b
    style Bicep fill:#ffccbc,stroke:#d84315
    style Runtime fill:#fff9c4,stroke:#f57f17
    style Future fill:#e0e0e0,stroke:#424242
    style KV fill:#fff9c4,stroke:#f57f17
    style EnvVars fill:#ffcccc,stroke:#c62828
    style KVRef fill:#ccffcc,stroke:#2e7d32
```

## 6. 責務分離マトリクス

```mermaid
graph LR
    subgraph L1["Layer 1: Network"]
        N["🟦 network.bicep<br/>nsg.bicep<br/>━━━━━━━━━━<br/>VNet / Subnet / NSG<br/>Physical boundaries"]
    end

    subgraph L2["Layer 2: Traffic Control"]
        AGW["🟦 appgw.bicep<br/>━━━━━━━━━━<br/>Application Gateway<br/>Path-based routing<br/>SSL/TLS termination<br/>→ [15_appgw.md]"]
    end

    subgraph L3["Layer 3: Authentication"]
        AUTH["🟩 aca-env/edge-runtime.bicep<br/>━━━━━━━━━━<br/>OAuth2 Proxy sidecar<br/>Entra OIDC validation<br/>Header injection<br/>→ [20_auth.md]"]
    end

    subgraph L4["Layer 4: API Management"]
        API["🟦 apim.bicep (Future)<br/>━━━━━━━━━━<br/>API Management<br/>Bearer token validation<br/>Rate limiting<br/>→ [30_api.md]"]
    end

    subgraph L5["Layer 5: Compute"]
        ACA["🟩 aca-env.bicep<br/>aca-env/platform.bicep<br/>aca-env/application.bicep<br/>━━━━━━━━━━<br/>Container Apps<br/>Application execution<br/>→ [50_aca.md]"]
    end

    subgraph L6["Layer 6: Data & Secrets"]
        DATA["🟨 postgresql.bicep<br/>redis-cache.bicep<br/>storage.bicep<br/>keyvault.bicep<br/>━━━━━━━━━━<br/>Data persistence<br/>Secret management<br/>→ [60_db.md] [70_secret.md]"]
    end

    L1 --> L2 --> L3 --> L5 --> L6
    L2 -.-> L4
    L4 -.-> L5

    style L1 fill:#bbdefb,stroke:#1565c0
    style L2 fill:#bbdefb,stroke:#1565c0
    style L3 fill:#c8e6c9,stroke:#2e7d32
    style L4 fill:#e0e0e0,stroke:#424242
    style L5 fill:#c8e6c9,stroke:#2e7d32
    style L6 fill:#fff9c4,stroke:#f57f17
```

## 参考
- [spec.md](./spec/spec.md) - 全体構成と modules 対応表
- [10_network.md](./spec/10_network.md) - ネットワーク基盤
- [15_appgw.md](./spec/15_appgw.md) - Application Gateway
- [20_auth.md](./spec/20_auth.md) - 認証層
- [30_api.md](./spec/30_api.md) - API 管理層
- [50_aca.md](./spec/50_aca.md) - コンテナアプリケーション
- [60_db.md](./spec/60_db.md) - データ層
- [70_secret.md](./spec/70_secret.md) - シークレット管理
