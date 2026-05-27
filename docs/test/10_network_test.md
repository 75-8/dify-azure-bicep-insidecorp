# 10_network_test

## 対象
- VNet/Subnet
- NSG
- App Gateway
- Private Endpoint / DNS

## テスト項目
- サブネットが設計どおり作成されること。
- 全対象サブネットに NSG が関連付け済みであること。
- App Gateway backend が ACA internal endpoint を参照すること。
- Private DNS 解決が成立すること。

## 検証例
- `az network vnet subnet show`
- `az network nsg show`
- `az network application-gateway show`
- `nslookup <private-fqdn>`
