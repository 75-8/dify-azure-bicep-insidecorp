# 40_aoai

## スコープ
- Azure OpenAI Service (AOAI) の作成方針
- Dify アプリケーションとの連携方式

## 現状の実装・運用仕様 (As-Is)
- **非管理リソース**: 現時点の Bicep テンプレートには、Azure OpenAI サービス自体をデプロイするモジュール（例: `aoai.bicep`）は含まれていない。また、[main.bicep] および Container Apps 側のパラメータにも AOAI 接続設定は定義されていない。
- **運用回避**: Dify アプリケーション立ち上げ後、管理者が Dify Web コンソール画面から直接 Azure OpenAI のエンドポイント情報、モデルデプロイ情報、および API Key を手動で入力して連携を有効化する。

## 将来的な設計方針 (To-Be)
自動プロビジョニングを拡張する場合、以下の方針を適用する：
- **IaC 化**: `infra/modules/aoai.bicep` を新規追加し、Cognitive Services アカウントおよび指定されたモデル（例: GPT-4o, text-embedding-ada-002）のデプロイを定義する。
- **キー管理**: 生成された API Key を Bicep 内から直接 Key Vault に登録する。
- **環境変数渡し**: `api` および `worker` Container App のシークレット参照を定義し、Key Vault から自動でキーを取得できるように連携する。


