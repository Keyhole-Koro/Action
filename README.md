# Action

Action は、情報探索と知識整理を分離しつつ、同じ knowledge graph に接続するシステムです。
会話、資料、Discord、ログのような複数の入力を取り込み、knowledge graph に整理し、その知識をもとに Act 実行を行います。

公開 frontend:

- https://frontend-wmd222x7za-an.a.run.app

## Repository Map

ルートディレクトリの役割は次のとおりです。

- [ActionAct](./ActionAct)
  - 実行層です
  - `frontend`, `act-api`, `act-adk-worker` を含みます
- [ActionOrganize](./ActionOrganize)
  - knowledge pipeline です
  - Organize 本体と `discord-bot` を含みます
- [ActionIngest](./ActionIngest)
  - large import 用の ingest 入口です
- [docs](./docs)
  - 全体構成、flow、integration、architecture、security の説明です
- [terraform](./terraform)
  - GCP 上の実行基盤と IAM の定義です
- [docker](./docker)
  - ローカル開発用の emulator と bootstrap です
- [contracts](./contracts)
  - 契約や共有インターフェースの配置先です
- [config](./config)
  - 実行環境ごとの設定を置くためのディレクトリです

## Runtime Routing

Action の主要 runtime は次のように分かれています。

- `frontend`
  - UI と graph 表示
- `act-api`
  - 認証済み API 境界
- `act-adk-worker`
  - LLM runtime
- `organize`
  - knowledge pipeline
- `action-ingest`
  - large import の前処理
- `discord-bot`
  - Discord guild message の取り込み

## Docs Routing

`docs/` の入口は [docs/README.md](./docs/README.md) です。

主な資料:

- [docs/overview.md](./docs/overview.md)
  - 全体像
- [docs/flows/ingest-organize.md](./docs/flows/ingest-organize.md)
  - ingest と Add Source の知識化フロー
- [docs/flows/act-runtime.md](./docs/flows/act-runtime.md)
  - Act 実行フロー
- [docs/integrations/discord.md](./docs/integrations/discord.md)
  - Discord integration
- [docs/robustness.md](./docs/robustness.md)
  - 堅牢性の設計
- [docs/google-stack.md](./docs/google-stack.md)
  - Google 技術の役割分担
- [docs/security.md](./docs/security.md)
  - セキュリティ境界
- [docs/glossary.md](./docs/glossary.md)
  - 用語集
- [docs/architecture-diagrams.md](./docs/architecture-diagrams.md)
  - 全体構成図と主要フロー図
- [docs/limitations-and-roadmap.md](./docs/limitations-and-roadmap.md)
  - 現在の制約と拡張方向

## Development

ローカル起動、Docker Compose、開発用設定は [docs/developer.md](./docs/developer.md) を参照してください。
