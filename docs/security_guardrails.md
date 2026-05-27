# Security Guardrails（セキュリティ境界の整理と修正提案）

## 1. 目的

本ドキュメントは、現在の `dify-azure-bicep-insidecorp` 構成におけるセキュリティ境界（Security Boundary）を整理し、
「**外部アクセス制限は RBAC ではなく NSG で担保する**」方針に沿った修正提案をまとめる。

---

## 2. 現状の整理（As-Is）

### 2.1 ネットワーク境界

- VNet は `PrivateLinkSubnet` / `ACASubnet` / `PostgresSubnet` の 3 サブネット構成。現時点で NSG リソース定義およびサブネット関連付けは未実装。  
- `ACA Environment` は `internal: true` で内部 LB 構成。  
- 一方で `nginx` Container App は `external: true` で公開され、`ipSecurityRestrictions` で CIDR 許可制御を実施。  
- つまり、現状の公開面制御は ACA のアプリ設定に依存しており、サブネット境界（NSG）での防御層がない。

### 2.2 データ境界（PaaS 到達性）

- Storage は `publicNetworkAccess: Disabled` + Private Endpoint（Blob/File）で閉域化。  
- PostgreSQL Flexible Server は delegated subnet + private DNS で閉域利用。  
- Redis は `publicNetworkAccess: Disabled` + Private Endpoint で閉域利用。

### 2.3 ID / 権限境界

- 現状コードには AOAI/UAMI 実装は未反映（リバート済み）。  
- 既存構成は主にネットワーク境界での分離を採用しているが、外部公開制御を NSG で一元化する設計には未到達。

### 2.4 運用検証境界

- `deploy.ps1` はデプロイ・ファイル共有アップロード中心で、NSG ルールの適用状態を検査する手順は未実装。

---

## 3. 課題

1. **外部公開制御がアプリ層寄り**  
   `ipSecurityRestrictions` は有効だが、ネットワーク境界（NSG）での明示的な deny/allow の多層防御が不足。

2. **セキュリティ境界の責務分離が曖昧**  
   RBAC（認可）と NSG（到達性）を分けて設計・検証する指針がドキュメント上で不十分だった。

3. **運用時の検証不足**  
   デプロイ後に「NSG が正しく関連付けされ、許可 CIDR のみ通す」ことを自動で検証できない。

---

## 4. 修正提案（To-Be）

## 4.1 境界の原則

- **RBAC は認可（Who can call）に限定**。  
- **NSG は到達性（Who can reach）に限定**。  
- 外部公開制御は NSG を主、ACA `ipSecurityRestrictions` を従（重ね掛け）とする。

## 4.2 Bicep 修正案

1. `modules/nsg.bicep`（新規）を追加し、以下を定義。
   - Inbound Allow: `publicAllowedCidrs` -> `80/443`（必要ポートのみ）
   - Inbound Deny: `*` -> `*`
   - 必要に応じて管理向け許可（踏み台/VPNセグメント）

2. `modules/vnet.bicep` または `main.bicep` 側で NSG をサブネットへ関連付け。
   - 優先対象: `ACASubnet`
   - 必要に応じて `PrivateLinkSubnet` / `PostgresSubnet` も個別 NSG で明示制御

3. パラメータ追加。
   - `publicAllowedCidrs`（許可送信元 CIDR 配列）
   - `nsgName`（またはサブネットごとの NSG 名）
   - `enableNsgEnforcement`（段階適用フラグ）

## 4.3 運用スクリプト修正案（deploy.ps1）

- デプロイ後に以下を検証。
  1. NSG が対象サブネットに関連付け済みであること。
  2. Allow ルールに `publicAllowedCidrs` が反映されていること。
  3. 最終 Deny ルールが存在すること。
- 失敗時は `Write-Error` + `exit 1`。

## 4.4 ドキュメント整備

- `docs/aoai-entra-auth-spec.md` と本ドキュメントで整合を維持し、
  **「外部アクセス制限は NSG、RBAC は認可」** を明文化する。

---

## 5. 受け入れ条件（Guardrail Definition）

1. 対象サブネットに NSG が関連付けられている。  
2. 許可 CIDR 以外からの到達が拒否される。  
3. 既存の Private Endpoint ベース閉域（Storage/Redis/PostgreSQL）を阻害しない。  
4. （AOAI 導入時）RBAC は AOAI 認可に限定し、外部到達制御の根拠にしない。

---

## 6. 段階導入プラン（推奨）

1. `what-if` で NSG 差分確認。  
2. ステージングで NSG 適用 + 疎通試験（許可元/非許可元）。  
3. 本番へ段階展開。  
4. 展開後は定期監査（NSG ルール逸脱・関連付け外れ）を運用タスク化。
