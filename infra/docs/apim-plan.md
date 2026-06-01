# APIM Plan (Draft)

目的: 将来の API 管理導入に向けたインフラとポリシーの設計を記録する。実装は保留する。

## 概要
- APIM 実装はコストと運用負荷を鑑みて保留
- 今回はプレースホルダモジュールと計画ドキュメントを用意する

## 想定 API インターフェース（例）
- /api/v1/auth/* - 認証連携（JWT/OIDC 検証）
- /api/v1/users/* - ユーザー管理（レート制限）
- /api/v1/models/* - モデル呼び出し系（厳格なスロットリング）

## 必要ポリシー
- 認証: JWT/OIDC 検証（Issuer, audience チェック）
- レート制限: エンドポイントごとのレートとバースト制御
- CORS 設定: Web UI ドメイン限定
- ログ: App Insights 連携またはログ送信先の指定

## ネットワーク配置
- APIM は開発段階では `Developer` SKU のみ検討
- 将来 VNet 統合が必要な場合は、APIM を VNet 内に配置し、バックエンド（ACA、Postgres）とプライベート接続を構成

## シークレットと認証連携
- Key Vault に OIDC クライアントシークレットを格納
- APIM ポリシーで Key Vault 参照を使う手順をドキュメント化

## デプロイプレースホルダ
- `infra/modules/apim-placeholder.bicep` を用意。パラメータ `deployApim` を `false` にしておき、明示的に切り替えない限り展開されない。

## 次のアクション（将来）
1. 実運用時に APIM を有効化する場合、`deployApim=true` でデプロイ。必要に応じて VNet 統合とプライベートエンドポイントを検討。
2. APIM のスケールと環境別設定を `infra/parameters` に追加。
3. APIM ポリシーのテンプレートを `infra/docs/apim-policies/` に追加。
