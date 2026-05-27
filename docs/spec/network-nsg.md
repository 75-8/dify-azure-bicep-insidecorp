# network-nsg ドメイン仕様

対象モジュール: `modules/network-nsg.bicep`（新規）

- サブネット単位 NSG を作成し関連付ける。
- 許可通信は最小権限（deny by default）で定義する。
- ルールの根拠は通信マトリクス（security_guardrails）で管理する。
