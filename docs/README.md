# Action Docs

この `docs/` は、Action の全体構成、主要フロー、integration、設計上の考え方をまとめた入口です。
全体像を把握したあと、必要に応じて flow、architecture、security、robustness を個別に読める構成にしています。

## Documents

### Overview

- [Overview](./overview.md)
- [Glossary](./glossary.md)

### Flows

- [Ingest / Organize Flow](./flows/ingest-organize.md)
- [Act Runtime Flow](./flows/act-runtime.md)

### Integrations

- [Discord Integration](./integrations/discord.md)

### Architecture

- [Robustness Design](./robustness.md)
- [Google Stack](./google-stack.md)
- [Architecture Diagrams](./architecture-diagrams.md)
- [Limitations and Roadmap](./limitations-and-roadmap.md)

### Security

- [Security Overview](./security.md)

## Scope

- Action が何をするシステムか
- 堅牢性をどう設計し、どう実装したか
- Google 技術をどこでどう使っているか
- 用語の意味
- 今の制約と今後の拡張余地
- スライドにそのまま使える図
- どのコンポーネントがどう連携するか
- ingest / organize の処理がどう進むか
- frontend / act-api / act-adk-worker の役割分担
- Add Source と Discord integration のような主要な対話導線
- セキュリティ境界と運用上の前提

## Related

- ルートセットアップ: [README.md](../README.md)
- 開発向け資料: [developer.md](./developer.md)
- デプロイ手順: [DEPLOYMENT.md](../DEPLOYMENT.md)
- Frontend 仕様: [frontend-spec.md](../ActionAct/frontend/frontend-spec.md)
- Organize 詳細設計: [organize-ingest-llm-architecture.md](../ActionOrganize/docs/organize-ingest-llm-architecture.md)
- Ingest 詳細フロー: [ingest-organize-flow.md](../ActionOrganize/docs/ingest-organize-flow.md)
