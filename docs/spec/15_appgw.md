# 15_appgw

## スコープ
Application Gateway (AppGw) のトラフィック制御・ルーティング層を定義する。ネットワーク基盤（[10_network.md](./10_network.md)）と認証層（[20_auth.md](./20_auth.md)）の間に位置し、クライアント入口から ACA 内部サービスへのパス制御を担う。

## 責務分離
本スペック（AppGw層）、[10_network.md](./10_network.md)（ネットワーク基盤）、[20_auth.md](./20_auth.md)（認証検証）、[30_api.md](./30_api.md)（API 層）の責務は以下のとおり：

| 層 | ドメイン | 責務 |
|---|---|---|
| **ネットワーク基盤** | [10_network.md](./10_network.md) | VNet、Subnet、NSG による物理・ネットワークレベルの境界制御 |
| **トラフィック制御** | **15_appgw.md (本スペック)** | パス・プロトコル・ポート基準のルーティング、SSL/TLS ターミネーション |
| **認証検証** | [20_auth.md](./20_auth.md) | OAuth2 Proxy による Entra OIDC 認証、HTTP ヘッダ伝播 |
| **API 管理・認証** | [30_api.md](./30_api.md) | APIM による API エンドポイント管理、Bearer Token 検証（将来） |

## 設計原則

### 公開入口の一本化
- **唯一の外部入口**: インターネット → **Application Gateway** のみ
- **ターゲット**: ACA 内の `nginx` Container App サイドカー（ポート 4180、OAuth2 Proxy）
- **その他すべて**: Private Endpoint、サービスエンドポイント、VNet 統合により非公開化

### パス別ルーティング設計
Application Gateway は URL パス基準で以下のように振り分ける：

| パス | バックエンド | 役割 | 認証 |
|---|---|---|---|
| `/*` (デフォルト) | Nginx UI パイプ | Web UI (`web:3000`) 提供 | OAuth2 Proxy (Entra OIDC) |
| `/v1/*` | Nginx API パイプ | API エンドポイント | 現状: OAuth2 Proxy、将来: APIM Bearer Token |
| `/console/api/*` | Nginx API パイプ | Console API エンドポイント | 同上 |
| `/api/*` | Nginx API パイプ | 互換性 API | 同上 |
| `/files/*` | Nginx API パイプ | ファイルサーブング | 同上 |

### トラフィック流
```
┌─────────────┐
│   Internet  │
│  (HTTP/443) │
└──────┬──────┘
       │
       ▼
┌────────────────────────────────────────────────────┐
│  Application Gateway (appgw.bicep)                │
│  - Frontend IP: Public Static IP                   │
│  - Listeners: HTTP (80), HTTPS (443)               │
│  - Redirect: HTTP → HTTPS (if cert provided)       │
│  - Backend Pools:                                  │
│    - backendPool-ui  (path: /*)                    │
│    - backendPool-api (path: /v1/*, /api/*, etc.)   │
└────────────────────┬─────────────────────────────┘
                     │
       ┌─────────────┴─────────────┐
       │                           │
       ▼                           ▼
    UI Backend              API Backend
  (port 4180)               (port 4180)
    (nginx +                (nginx +
   OAuth2P)                OAuth2P)
```

## SSL/TLS 証明書管理

### 証明書の役割
- **TLS ターミネーション**: Application Gateway でクライアント通信を TLS/SSL 保護
- **バックエンド通信**: nginx へは HTTP ローカル通信（ポート 4180）、非暗号化

### 証明書提供パターン

#### パターン A: 証明書あり（`isProvidedCert = true`）
```bicep
isProvidedCert: true
appGwCertBase64Value: '...(PFX Base64)...'
appGwCertPassword: '...(secure)'
```
**動作**:
- Frontend: HTTPS（443）リスナー + HTTP（80）→ HTTPS リダイレクト
- SSL 証明書: PFX 形式で `appgw.bicep` に登録
- リダイレクト: HTTP トラフィックを HTTPS へ恒久的リダイレクト（HTTP 301）

#### パターン B: 証明書なし（`isProvidedCert = false`、開発環境想定）
```bicep
isProvidedCert: false
```
**動作**:
- Frontend: HTTP（80）リスナーのみ
- SSL 証明書: なし
- リダイレクト: なし

### 証明書形式と管理方法
- **PFX 形式**: PKCS#12、秘密鍵と証明書を含む
- **Base64 エンコード**: `appGwCertBase64Value` パラメータで渡す
- **パスワード保護**: `@secure()` で保護、`appGwCertPassword` パラメータで渡す
- **Key Vault 連携**: 本スペックでは PFX ファイルのアップロード方式を想定。将来的には Key Vault 参照に切り替え可能

## バックエンド構成

### バックエンド HTTP 設定
```bicep
backendHttpSettings:
  port: 4180
  protocol: 'Http'
  cookieBasedAffinity: 'Disabled'
  pickHostNameFromBackendAddress: true
```
**特性**:
- **ポート 4180**: OAuth2 Proxy のリッスンポート（[20_auth.md](./20_auth.md) 参照）
- **HTTP のみ**: バックエンド内通信はプライベート（VNet 内）のため HTTP で十分
- **ホスト名自動取得**: バックエンドプール内の FQDN からホスト名を動的抽出（nginx ACA の `<app-name>.<default-domain>` に対応）

### バックエンドプール構成

#### backendPool-ui
- **ターゲット**: `nginx.<default-domain>` (ACA default domain)
- **用途**: Web UI、Web Console 提供
- **通信先**: nginx → `web:3000`（OAuth2 Proxy で認証済み）

#### backendPool-api
- **ターゲット**: 同一 `nginx.<default-domain>` (共通)
- **用途**: API エンドポイント（`/v1/*`, `/api/*` など）
- **通信先**: nginx → `api:5001`（OAuth2 Proxy で認証済み）
- **将来**: APIM 経由に変更される予定（[30_api.md](./30_api.md) 参照）

## ルーティングルール

### URL パス マッピング
```bicep
urlPathMap: {
  defaultBackendAddressPool: backendPool-ui
  defaultBackendHttpSettings: backendHttpSettings
  pathRules: [
    {
      paths: ['/v1/*', '/console/api/*', '/api/*', '/files/*']
      backendAddressPool: backendPool-api
      backendHttpSettings: backendHttpSettings
    }
  ]
}
```

### リクエストルーティング優先度（Priority）
- **Priority 100** (HTTPS リスナー): 通常リクエスト → URL パス マッピング処理
- **Priority 200** (HTTP リスナー): HTTP → HTTPS リダイレクト（証明書あり時のみ）

**優先度の意義**: 複数ルールが存在する場合、優先度の低い番号から評価される。HTTPS ルールを先に処理することで、セキュアなルーティングを保証。

## Bicep 実装との整合性

### パラメータ入力
`appgw.bicep` への入力仕様（[main.bicep](../../infra/main.bicep) から渡される）:

| パラメータ | 型 | 説明 | 例 |
|---|---|---|---|
| `location` | string | デプロイ先 Azure リージョン | `japaneast`, `westus2` |
| `appGwName` | string | AppGw リソース名 | `dify-appgw` |
| `appGwSubnetId` | string | AppGw 専用サブネット ID（[10_network.md](./10_network.md) の `AppGwSubnet` 指定） | `/subscriptions/.../AppGwSubnet` |
| `publicIpName` | string | Public IP 名 | `dify-appgw-pip` |
| `acaNginxFqdn` | string | ACA nginx Container App FQDN | `nginx.agreeablesky-abc123.japaneast.azurecontainerapps.io` |
| `isProvidedCert` | bool | SSL 証明書提供フラグ | `true` / `false` |
| `appGwCertBase64Value` | string (secure) | PFX 証明書 Base64 値（提供時のみ） | `MIIJrQIBAzCC...` |
| `appGwCertPassword` | string (secure) | PFX 証明書パスワード（提供時のみ） | `(sensitive)` |

### リソース命名規則
- **Application Gateway**: `${appGwName}` (通常 `dify-appgw`)
- **Public IP**: `${publicIpName}` (通常 `dify-appgw-pip`)
- **Frontend IP Configuration**: `appGwFrontendIP` (固定)
- **SSL 証明書**: `appgw-cert` (固定)

## 認証層との相互作用（[20_auth.md](./20_auth.md) との接点）

### トラフィックハンドオフ
1. AppGw がリクエストを受信し、URL パスに応じて `backendPool-ui` または `backendPool-api` を選択
2. **バックエンド**: ポート 4180（OAuth2 Proxy）へ転送
3. **OAuth2 Proxy の責務**: 
   - Entra OIDC 認証検証（Issuer, audience,署名確認）
   - 認証済みマーク付きヘッダ伝播（`X-Auth-Request-Email` など）
   - 認証失敗時はエラー応答

### カスタムヘッダ伝播
OAuth2 Proxy から nginx への HTTP ヘッダ:
```http
X-Auth-Request-Email: user@example.com
X-Auth-Request-User: user
X-Auth-Request-Groups: group1,group2
```
Dify アプリケーション層は上記ヘッダからユーザー情報を取得。

## API 層との分離（[30_api.md](./30_api.md) との将来計画）

### 現状（As-Is）
- API (`/v1/*`) も同一 OAuth2 Proxy / セッションクッキー認証フローを通過
- 実装の簡潔さのため統一ルーティング

### 将来（To-Be）
```
Client -> APIM (Bearer Token 検証)
       -> api Container App (ポート 5001)
```
- **AppGw の変更**: `/v1/*` ルールを APIM バックエンド URL へ指し替え
- **AppGw の責務**: APIM への L7 パス ルーティングのみ（認証は APIM で処理）
- **認証分離**: UI セッション認証と API Bearer Token 認証を明確に分離

## デプロイ・テスト検証

### 確認項目
1. **外部接続性**: パブリック IP から AppGw への HTTP(S) 到達確認
2. **ホスト名解決**: AppGw の FQDN 解決確認（DNS レコード登録状況確認）
3. **パス ルーティング**:
   - `/` → UI バックエンド
   - `/v1/models` → API バックエンド
4. **SSL/TLS 動作**:
   - HTTP → HTTPS リダイレクト（証明書あり時）
   - HTTPS ハンドシェイク成功
5. **バックエンド疎通**:
   - AppGw → nginx コンテナ (port 4180) の通信成功
   - oauth2proxy のログ確認

### トラブルシューティング
- **502 Bad Gateway**: バックエンドプール（nginx:4180）到達不可 → NSG ルール、ACA ネットワーク設定確認
- **証明書エラー**: 自署証明書対応が必要な場合、バックエンド HTTP 設定の `backendHttpSettings.probes` カスタマイズ検討

## 参考
- [10_network.md](./10_network.md) - ネットワーク基盤設計
- [20_auth.md](./20_auth.md) - OAuth2 Proxy 認証検証
- [30_api.md](./30_api.md) - APIM (将来 API 層)
- [appgw.bicep](../../infra/modules/appgw.bicep) - Application Gateway 実装
- [spec.md](./spec.md) - 全体構成と modules 対応表
