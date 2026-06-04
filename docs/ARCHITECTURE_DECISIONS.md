# Architecture Decision Records (ADR)

このドキュメントは、Dify Azure 環境の設計・実装における重要な意思決定を記録します。

参照: [docs/task_list.md](./task_list.md#d1-app-gateway-での-entra-認証方式の確定)

---

## ADR-001: API 認証経路の段階化 (APIM 統合)

**Status**: 📋 DECISION PENDING

**Context**:
- 現状: すべての API（UI 画面も含む）が Application Gateway → OAuth2 Proxy → nginx → API サービスの単一経路を使用
- 問題: API エンドポイント（`/v1`, `/api`, `/console/api`）とセッション基盤の UI 画面が同じ認証フローを共有
- 要件: 将来的に API と UI の認証ライフサイクルを分離し、外部 API クライアント向け OAuth 2.0 Bearer Token 検証を実現

**Design Options**:

### Option A: APIM による完全分離（推奨）
```
UI Path:       Client → App Gateway → OAuth2 Proxy → nginx → web (session cookie)
API Path:      Client → APIM → API (Bearer token validation)
Integration:   APIM backend policy で Bearer token → API Key に変換
```
- **Pros**: 
  - API 認証が独立、外部クライアント対応可
  - APIM で rate limiting, throttling 制御が可能
  - UI セッション管理と API キー管理が分離
- **Cons**:
  - APIM の追加管理オーバーヘッド
  - 設定複雑度が増加（inbound/outbound policy 定義）
  - コスト増加（APIM SKU による）

### Option B: 単一経路（現状維持）
```
Both UI & API: Client → App Gateway → OAuth2 Proxy → nginx → web/api (all via session)
```
- **Pros**:
  - 実装・管理が単純
  - 現状実装で動作確認済み
- **Cons**:
  - 外部 API クライアント対応困難（session cookie ベース）
  - 将来的な API ゲートウェイ機能（rate limiting等）が制限される

### Option C: APIM + Conditional Routing（段階的統合）
```
Phase 1: APIM デプロイするが、traffic は App Gateway 経由のまま（オフ状態）
Phase 2: 一部 API `/v1/internal/*` を APIM 経由に段階移行
Phase 3: 全 API を APIM 経由に完全移行（UI 経路は App Gateway のまま）
```
- **Pros**:
  - 段階的なリスク低減
  - 既存 UI 経路への影響が少ない
  - ロールバック容易
- **Cons**:
  - 複数経路の併行管理期間が長い
  - テスト・検証コストが高い

**Decision Required**:
- [ ] Option A 採用（APIM 完全分離、今後実装予定）
- [ ] Option B 採用（現状維持、APIM 削除検討）
- [ ] Option C 採用（段階的統合、フェーズ計画作成）

**Implementation Plan** (Option A 前提):
1. **Phase 1**: APIM モジュール統合と基本構成（Q3 2026）
2. **Phase 2**: Inbound policy（Bearer token 検証）実装（Q4 2026）
3. **Phase 3**: Client → APIM ルーティング有効化（Q1 2027）
4. **Phase 4**: UI 経路最適化と API 経路完全移行（Q2 2027）

**Related**:
- [docs/spec/30_api.md](./spec/30_api.md)
- [apim.bicep](../infra/modules/apim.bicep) (placeholder)

---

## ADR-002: Azure OpenAI (AOAI) 統合スコープ

**Status**: 📋 DECISION PENDING

**Context**:
- 現状: AOAI リソース作成・連携は IaC に含まれていない（手動投入）
- 要件: Dify が複数の LLM モデル（GPT-4, text-embedding）を使用
- 問題: AOAI API Key のライフサイクル管理、環境別設定管理が未定

**Design Options**:

### Option A: 完全な IaC 自動化（推奨・将来）
```bicep
// aoai.bicep で以下を管理
- Cognitive Services Account 作成
- Model deployments (GPT-4, embedding-ada-002, etc.)
- API Keys 自動生成 → Key Vault 登録
- Container App secrets reference 設定
```
- **Pros**:
  - 完全な IaC・再現可能性
  - Key Vault との統合でシークレット管理を一元化
  - 環境別自動設定
- **Cons**:
  - AOAI リソース作成権限が必要（Azure AOAI Deployment 制限あり）
  - API Key ローテーションの自動化が必要
  - デプロイ時間が増加

### Option B: Bicep で作成、Key を手動投入（現行推奨）
```
Bicep:   AOAI リソース + モデル deployment 作成
Manual:  API Key を Key Vault に手動登録（運用手順書に記載）
Apps:    Key Vault reference で自動参照（セキュリティ改善）
```
- **Pros**:
  - 実装が比較的簡単
  - AOAI デプロイ権限の制限に対応可能
  - 現状の手動手順を最小化
- **Cons**:
  - 管理が 2 段階（IaC + 手動）
  - Key ローテーション時にドキュメント必須

### Option C: 完全手動（現状維持）
```
Manual:  AOAI リソース作成、モデル deployment、API Key 取得
Manual:  Dify Web UI から直接設定、または環境変数に投入
```
- **Pros**:
  - Bicep 側の変更なし（最小労力）
  - AOAI 設定の柔軟性最大
- **Cons**:
  - 再現性がない（手動オペレーション）
  - 監査・追跡が困難
  - ヒューマンエラーのリスク

**Decision Required**:
- [ ] Option A 採用（完全自動化、将来実装予定）
- [ ] Option B 採用（Bicep 作成 + 手動 Key 投入、推奨）
- [ ] Option C 採用（現状維持）

**Implementation Plan** (Option B 前提):
1. **aoai.bicep 作成**: Cognitive Services Account + model deployments（Q3 2026）
2. **운用 Runbook 作成**: AOAI Key 登録・ローテーション手順（Q3 2026）
3. **Key Vault 統合**: Container App secret reference 実装（参考: ADR-003）
4. **監査ログ設定**: AOAI API usage tracking（Q4 2026）

**Related**:
- [docs/spec/40_aoai.md](./spec/40_aoai.md)
- [security-implementation-guide.md](./security-implementation-guide.md) (Key Vault reference)
- ADR-003 (Secret management)

---

## ADR-003: シークレット管理アーキテクチャ

**Status**: 🔄 IN PROGRESS (task_list.md S1)

**Context**:
- 現状: Database password, OAuth2 secret 等が Container App 環境変数に平文記載
- 要件: 機微情報を安全に管理し、ログからの露出を防止

**Design Options**:

### Option A: Key Vault + Managed Identity（推奨・実装中）
```bicep
// Container App: SystemAssigned Managed Identity
identity: { type: 'SystemAssigned' }

// Key Vault に事前登録されたシークレットを参照
secrets: [
  {
    name: 'db-password'
    keyVaultUrl: '${keyVaultUri}secrets/db-password/'
  }
]

env: [
  {
    name: 'DB_PASSWORD'
    secretRef: 'db-password'  // 秘密値は環境変数に展開されない
  }
]
```
- **Pros**:
  - 秘密値がログに出現しない
  - RBAC で権限管理可能
  - ローテーション時は Key Vault のみ更新
- **Cons**:
  - Bicep 実装変更が必要（既存環境への適用に手作業）
  - Managed Identity 権限管理が複雑

### Option B: Azure Configuration Service（軽量版）
```
Configuration Service に平文以外の設定を保存
Container App では startup でダウンロード（environment variable ではなく ファイルシステムに配置）
```
- **Pros**:
  - Key Vault より軽量
  - 設定更新時にポッド再起動不要
- **Cons**:
  - 別途サービス管理が必要
  - ファイルシステム権限管理が必要

### Option C: 環境変数のままセキュアハッシング（緩和版）
```
秘密値を環境変数ではなく、コンテナイメージに build-time に埋め込み
または initContainer で vault から取得して tmpfs にマウント
```
- **Pros**:
  - 既存実装への変更が最小
  - 多くの Dify deployment で採用されている
- **Cons**:
  - ログからの露出リスクは残存
  - ローテーション手順が複雑

**Decision Made**: Option A（Key Vault + Managed Identity）
- **Status**: 実装ガイド完成、Bicep 実装予定
- **Timeline**: 
  - Phase 1: ガイドドキュメント完成 ✅（[security-implementation-guide.md](./security-implementation-guide.md)）
  - Phase 2: Bicep 실装（keyvault.bicep + aca-env.bicep 修正）- Q3 2026
  - Phase 3: 既存環境への適用（migration script）- Q4 2026

**Implementation Steps**:
1. keyvault.bicep: シークレット作成ロジック追加
2. application.bicep, edge-runtime.bicep: secret reference + secretRef 導入
3. main.bicep: keyVault 출력を aca-env 모듈에 전달
4. access policy: 各 Container App Managed Identity に Secret Get 権限付与

**Related**:
- [docs/security-implementation-guide.md](./security-implementation-guide.md)
- [docs/task_list.md#s1-セキュリティ-環境変数への機微情報直接記載](./task_list.md#s1-セキュリティ-環境変数への機微情報直接記載)
- [docs/spec/70_secret.md](./spec/70_secret.md)

---

## ADR-004: Application Gateway の Entra 認証

**Status**: 🟢 CONFIRMED

**Context**:
- 要件: App Gateway 層でネットワークレベルの侵入制限
- 現実装: OAuth2 Proxy により Entra 認証を実行（nginx container 内）

**Decision Made**: OAuth2 Proxy（Application Gateway ではなく ACA 層での認証）
- **Rationale**: App Gateway 単体では Entra ネイティブ認証が複雑（別途 auth provider パターン必要）
- **Implementation**: edge-runtime.bicep の oauth2-proxy sidecar で実現
- **Trade-off**: ネットワーク層での early rejection はできないが、アプリケーション層での uniform 認証が実現

**Related**:
- [docs/spec/15_appgw.md](./spec/15_appgw.md)
- [docs/spec/20_auth.md](./spec/20_auth.md)

---

## ADR-005: NSG ルール段階的 Tightening

**Status**: 🟡 PLANNED

**Context**:
- 要件: 最小権限の原則に基づいた NSG ルール
- 課題: デプロイ初期段階では可用性を優先、本番移行前に段階的にセキュリティを強化

**Decision Framework**:

### Phase 1: Development (Current)
- NSG: 必要最小限のみ許可（通常運用で十分なルール）
- Monitoring: ドロップされたパケット監視（不要なルール特定用）

### Phase 2: Staging
- NSG: Phase 1 + 追加の explicit deny ルール
- Testing: 負荷テスト、長期運用監視
- Logging: Application Gateway / Container Apps ログ精査

### Phase 3: Production
- NSG: explicit white-list のみ、他は implicit deny
- Monitoring: DDoS protection, WAF（将来検討）
- Audit: 定期的なルール見直し（四半期）

**Implementation Status**:
- Phase 1 ルール設定: 🟢 実装完了（nsg.bicep）
- Phase 2 → Phase 3 移行: 🔴 未実装（本番前に実施）

**Related**:
- [docs/spec/10_network.md](./spec/10_network.md)
- [docs/task_list.md#n6-nsg-ルールの具体化通信マトリクス化](./task_list.md#n6-nsg-ルールの具体化通信マトリクス化)

---

## Summary Table

| ADR | Title | Status | Priority | Target |
|-----|-------|--------|----------|--------|
| ADR-001 | APIM 統合（API 経路分離） | 📋 Decision Pending | P2 | Q3 2026 |
| ADR-002 | AOAI 統合スコープ | 📋 Decision Pending | P1 | Q3 2026 |
| ADR-003 | Secret 管理（Key Vault + MI） | 🔄 In Progress | P0 | Q3-Q4 2026 |
| ADR-004 | App Gateway Entra 認証 | 🟢 Confirmed | ✅ Done | N/A |
| ADR-005 | NSG ルール段階化 | 🟡 Planned | P1 | Q4 2026 |

---

**Document Version**: 1.0  
**Last Updated**: June 5, 2026  
**Maintainers**: Architecture Team
