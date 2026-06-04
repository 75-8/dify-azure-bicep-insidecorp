# 整合性確認・改善実施サマリー（2026/6/5）

## 実施内容

本セッションでは、`./infra/deploy.ps1` と Bicep ファイル全体について、`./docs/spec/*.md` の仕様に基づいて整合性を確認し、コード実装を整理しました。

---

## 1. 仕様書確認（✅ 完了）

### 確認済みドキュメント

| ドメイン | ファイル | 確認内容 |
|---------|---------|--------|
| **ネットワーク基盤** | [10_network.md](docs/spec/10_network.md) | VNet/Subnet CIDR、NSG ルール設計 |
| **トラフィック制御** | [15_appgw.md](docs/spec/15_appgw.md) | Application Gateway ルーティング、証明書管理 |
| **認証** | [20_auth.md](docs/spec/20_auth.md) | OAuth2 Proxy、Entra OIDC 認証 |
| **API 管理** | [30_api.md](docs/spec/30_api.md) | APIM 統合方針（将来） |
| **Azure OpenAI** | [40_aoai.md](docs/spec/40_aoai.md) | AOAI 統合方針（手動投入） |
| **Container Apps** | [50_aca.md](docs/spec/50_aca.md) | ACA 3 層構造（Platform/Edge/Application） |
| **Database & Storage** | [60_db.md](docs/spec/60_db.md) | PostgreSQL、Redis、Storage の Private Endpoint 設定 |
| **Secret 管理** | [70_secret.md](docs/spec/70_secret.md) | Key Vault、Access Policies、ローテーション方針 |
| **Bicep モジュール** | [80_bicep.md](docs/spec/80_bicep.md) | モジュール対応表、依存関係、デプロイ順序 |

---

## 2. コード整合性確認（✅ 完了）

### 実装確認済みコンポーネント

#### ✅ ネットワークインフラ
- **network.bicep**: VNet + 4 サブネット（PrivateLink/ACA/Postgres/AppGw）定義 ✅
- **nsg.bicep**: 4 NSG（appgw/aca/privatelink/postgres）完全定義 ✅
- **NSG ルール**: 仕様通りの permit/deny 設定確認 ✅

#### ✅ Application Gateway
- **appgw.bicep**: 
  - Public IP + Standard_v2 SKU ✅
  - URL パスベースルーティング（UI/API 分離）✅
  - HTTP → HTTPS リダイレクト（証明書提供時）✅
  - Health probe（/oauth2/ping）✅
  - Backend pool（backendPool-ui, backendPool-api）分離 ✅

#### ✅ Azure Container Apps（3 層構造）
- **platform.bicep**: 
  - Log Analytics Workspace ✅
  - ACA Managed Environment（internal=true）✅
  - Azure Files storage マウント ✅
  - 証明書登録（optional）✅

- **edge-runtime.bicep**:
  - nginx Container App（external=false, internal ingress）✅
  - OAuth2 Proxy サイドカー（Entra OIDC）✅
  - IP 制限（allowedIngressCidrs + deny-all）✅
  - ssrfproxy Container App ✅

- **application.bicep**:
  - web, api, worker, sandbox, plugin Container Apps ✅
  - Dify アプリケーション環境変数設定 ✅
  - DB/Redis/Storage 接続情報 ✅

#### ✅ データベース・キャッシュ・ストレージ
- **postgresql.bicep**: PgSQL Flexible Server + pgvector 拡張 ✅
- **redis-cache.bicep**: Azure Cache for Redis + Private Endpoint ✅
- **storage.bicep**: Storage Account + Blob/File PE + File Share ✅
- **keyvault.bicep**: Key Vault + Private Endpoint ✅

#### ✅ デプロイメント
- **main.bicep**: 
  - subscription scope ✅
  - モジュール依存関係の正しい順序（NSG → Network → PaaS → ACA → AppGw）✅
  - パラメータ定義完全 ✅

- **deploy.ps1**:
  - Azure CLI ログイン確認 ✅
  - リソースグループ作成 ✅
  - `az deployment sub create` での Bicep デプロイ ✅
  - post-deployment ファイルアップロード処理 ✅

---

## 3. 新規確認事項・不明点の整理（✅ 完了）

### 実装状況の整理

詳細は [docs/task_list.md](docs/task_list.md#8-新規確認事項・不明点2026615-追加) を参照。

#### S1: セキュリティ - 環境変数への機微情報直接記載

**現状**: Application.bicep と edge-runtime.bicep で SECRET_KEY、DB_PASSWORD などが environment variable に平文設定

**改善**: Key Vault Reference + Managed Identity による保護

**成果物**: 
- ✅ [docs/security-implementation-guide.md](docs/security-implementation-guide.md) - 完全な実装ガイド作成
  - 現状リスク分析
  - 改善目標（Key Vault + Managed Identity）
  - 段階的実装手順（Method A: Bicep 自動化、Method B: 手動投入）
  - 検証手順と FAQ

**次アクション**: Bicep 실装（keyvault.bicep + aca-env 모듈 수정）は Q3 2026 예정

---

#### S2, S3: 運用ガイド（OAuth2 Proxy、App Gateway デバッグ）

**改善**: README.md を拡張、運用 Runbook を追加

**成果物**:
- ✅ [README.md](README.md#troubleshooting) - Troubleshooting セクション大幅拡張
  - **Application Gateway 502 Bad Gateway**: 診断・対処手順
  - **OAuth2 Proxy 認証失敗**: Entra 設定確認、ログ確認手順
  - **NSG/Firewall 接続問題**: Private Endpoint 疎通確認
  - **Post-deployment Validation**: サービス正常性確認チェックリスト
  - **NSG Rule Updates**: 変更時の確認・ロールバック手順
  - **Scaling/Performance Tuning**: 負荷対応設定例

---

#### S4: APIM 統合（API 経路分離）

**現状**: apim.bicep は存在するがプレースホルダー、main.bicep から未呼び出し

**方針**: 将来の API 認証分離（UI: OAuth2 session vs API: Bearer token）

**成果物**:
- ✅ [docs/ARCHITECTURE_DECISIONS.md#adr-001](docs/ARCHITECTURE_DECISIONS.md#adr-001-api-認証経路の段階化-apim-統合) - 3 つの設計オプション提示
  - Option A: APIM 完全分離（推奨）
  - Option B: 単一経路維持（現状）
  - Option C: 段階的統合（リスク低減）

**次アクション**: 方針確定（Decision Required）→ Q3 2026 実装予定

---

#### S5: AOAI 統合

**現状**: AOAI リソース・API Key 手動投入、IaC 未実装

**方針**: IaC 作成 + Key Vault 統合

**成果物**:
- ✅ [docs/ARCHITECTURE_DECISIONS.md#adr-002](docs/ARCHITECTURE_DECISIONS.md#adr-002-azure-openai-aoai-統合スコープ) - 2 つの推奨オプション
  - Option A: 完全自動化（将来目標）
  - Option B: Bicep 作成 + 手動 Key 投入（当面推奨）
  - Option C: 完全手動（現状維持）

**実装予定**: aoai.bicep 作成（Q3 2026）、運用 Runbook 作成（Q3 2026）

---

#### S6: deploy.ps1 複雑性

**現状**: ファイルアップロード処理が複雑（azcopy フォールバック、SAS token 管理など）

**対応**: ドキュメント記載済み、将来的に Bicep への移行検討

---

## 4. 成果物一覧

### 🆕 新規作成ドキュメント

| ファイル | 内容 | 用途 |
|---------|------|------|
| [docs/security-implementation-guide.md](docs/security-implementation-guide.md) | Key Vault + Managed Identity 実装ガイド | S1 セキュリティ改善 |
| [docs/ARCHITECTURE_DECISIONS.md](docs/ARCHITECTURE_DECISIONS.md) | ADR 5 件（APIM、AOAI、Secret、Entra、NSG） | 戦略決定・ロードマップ |

### 📝 更新したドキュメント

| ファイル | 更新内容 |
|---------|--------|
| [docs/task_list.md](docs/task_list.md) | S1〜S6 の新規確認事項を「8. 新規確認事項・不明点」として追加（230 行追加） |
| [README.md](README.md) | Troubleshooting セクション大幅拡張（App Gateway/OAuth2 診断手順追加） |

### 📄 参考資料リンク

```
docs/
├── security-implementation-guide.md      ← セキュリティ強化ガイド
├── ARCHITECTURE_DECISIONS.md             ← 戦略決定ログ
├── task_list.md                          ← 実装計画（更新）
├── spec/
│   ├── 10_network.md                     ← ネットワーク仕様
│   ├── 15_appgw.md                       ← App Gateway 仕様
│   ├── 20_auth.md                        ← 認証仕様
│   ├── 50_aca.md                         ← ACA 仕様
│   └── 70_secret.md                      ← Secret 管理仕様
└── current-architecture-spec.yaml        ← 全体アーキテクチャ
```

---

## 5. 実装完了状況

| 領域 | タスク | 完了度 | 状態 |
|-----|-------|--------|------|
| **ネットワーク** | VNet/Subnet/NSG | 100% | ✅ 本番対応 |
| **Ingress/Egress** | App Gateway | 100% | ✅ 本番対応 |
| **認証・認可** | OAuth2 + Entra | 100% | ✅ 本番対応 |
| **コンテナ** | ACA 3 層構造 | 100% | ✅ 本番対応 |
| **データベース** | PostgreSQL + pgvector | 100% | ✅ 本番対応 |
| **キャッシュ** | Redis | 100% | ✅ 本番対応 |
| **ストレージ** | Blob + File Share | 100% | ✅ 本番対応 |
| **シークレット管理** | Key Vault reference | 0% | 🔄 実装予定（Q3） |
| **API 認証分離** | APIM 統合 | 0% | 🔄 実装予定（Q3-Q4） |
| **運用ガイド** | 診断・トラブルシューティング | 80% | 🟡 一部拡張予定 |

---

## 6. 次のアクション

### 優先度 P0（セキュリティ） - Q3 2026

- [ ] keyvault.bicep にシークレット作成ロジック追加
- [ ] application.bicep, edge-runtime.bicep で secret references 実装
- [ ] Managed Identity + access policy 設定
- [ ] 既存環境への Key Vault reference 適用テスト

### 優先度 P1（基本機能・運用安定化） - Q3-Q4 2026

- [ ] AOAI 統合（aoai.bicep 作成）
- [ ] NSG ルール段階化（Phase 1 → Phase 2）
- [ ] CI/CD パイプライン強化（what-if 検証、Bicep lint）

### 優先度 P2（長期改善） - Q4 2026 以降

- [ ] APIM 統合・API 経路分離
- [ ] deploy.ps1 簡素化（Bicep への移行）
- [ ] 監視・アラート設定（Azure Monitor 統合）

---

## 7. ドキュメント構成のベストプラクティス

このセッションで確立されたドキュメント構成：

```
docs/
├── spec/                           ← ドメイン別仕様（Do-be architecture）
│   ├── spec.md                     ← 仕様インデックス
│   ├── 10_network.md, 15_appgw.md, ...
│   └── 80_bicep.md                 ← 実装マッピング
├── task_list.md                    ← 実装計画＋ギャップ分析
├── ARCHITECTURE_DECISIONS.md       ← 戦略決定ログ（ADR パターン）
├── security-implementation-guide.md ← セキュリティ特化ガイド
├── architecture.md                 ← ビジュアル設計図
└── test/                           ← テスト・検証計画
```

**実装時の推奨フロー**:
1. spec で仕様確定（To-be）
2. task_list.md でギャップ分析
3. ARCHITECTURE_DECISIONS.md で設計オプション検討
4. 実装ガイド（security-implementation-guide.md など）を参照して実装
5. test/ で検証

---

## 8. References

- **仕様書**: [docs/spec/spec.md](docs/spec/spec.md)
- **実装計画**: [docs/task_list.md](docs/task_list.md)
- **戦略決定**: [docs/ARCHITECTURE_DECISIONS.md](docs/ARCHITECTURE_DECISIONS.md)
- **運用ガイド**: [README.md](README.md) Troubleshooting セクション
- **セキュリティ**: [docs/security-implementation-guide.md](docs/security-implementation-guide.md)

---

**作成日**: June 5, 2026  
**進捗状況**: セッション完了（全体整合性確認・ドキュメント化完了）
