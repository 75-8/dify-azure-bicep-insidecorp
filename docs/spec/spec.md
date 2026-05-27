# 全体仕様（Boundary / Cross-domain）

## 1. 目的

本仕様は、Dify on Azure の IaC を **モジュール単位のドメイン仕様**へ分割し、境界（責務）と統合ルールを明確化する。

- インターネット入口は Application Gateway（WAF なし）に限定する。
- ACA は Private（internal）運用とする。
- サブネット境界は NSG で保護する。
- AOAI は Key 認証を採用し、API Key は IaC に含めない（手動投入）。

## 2. ドメイン分割方針

ドメインは Bicep モジュールに対応させる。

- `vnet` (`modules/vnet.bicep`)
- `network-nsg` (`modules/network-nsg.bicep` 想定)
- `app-gateway` (`modules/app-gateway.bicep` 想定)
- `aca-env` (`modules/aca-env.bicep`)
- `storage` (`modules/storage.bicep`)
- `postgresql` (`modules/postgresql.bicep`)
- `redis-cache` (`modules/redis-cache.bicep`)
- `aoai` (`modules/aoai.bicep` 想定)

## 3. 境界定義（責務）

- 各ドメイン仕様は、**自ドメインの入力・出力・制約**のみを定義する。
- クロスドメイン依存（例: App Gateway -> ACA、ACA -> Storage/DB）は `spec.md` で統合管理する。
- セキュリティ方針（公開境界、認証境界、ネットワーク境界）は `spec.md` を正本とする。

## 4. クロスドメイン統合ルール

1. `vnet` がサブネットを提供し、`network-nsg` が関連付ける。
2. `app-gateway` は `aca-env` の内部エンドポイントへ転送する。
3. `aca-env` は `storage`/`postgresql`/`redis-cache`/`aoai` の接続先情報を受け取る。
4. `aoai` の API Key は IaC では扱わない。運用手順で手動投入する。

## 5. 受け入れ基準（全体）

- 公開入口が App Gateway のみに限定される。
- ACA が external ingress を持たない。
- すべての対象サブネットに NSG が適用される。
- App Gateway の侵入制限（Entra）と NSG 制御が両立している。
- AOAI API Key がテンプレート/パラメータ/CIログに含まれない。
