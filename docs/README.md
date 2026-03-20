# Action Docs

この `docs/` は、Action を外部の人に説明するときの入口です。
まずは全体像を把握し、その後にフローやセキュリティを個別に読める構成にしています。

## 読み順

1. [Overview](./overview.md)
2. [Hackathon Narrative](./hackathon.md)
3. [Robustness Design](./robustness.md)
4. [Google Stack](./google-stack.md)
5. [Glossary](./glossary.md)
6. [Ingest / Organize Flow](./flows/ingest-organize.md)
7. [Act Runtime Flow](./flows/act-runtime.md)
8. [Discord Integration](./integrations/discord.md)
9. [Security Overview](./security.md)

## この docs が対象にしていること

- Action が何をするシステムか
- ハッカソン審査でどう見せるか
- 堅牢性をどう設計し、どう実装したか
- Google 技術をどこでどう使っているか
- 用語の意味
- どのコンポーネントがどう連携するか
- ingest / organize の処理がどう進むか
- frontend / act-api / act-adk-worker の役割分担
- Add Source と Discord integration のような主要な対話導線
- 対外説明で必要なセキュリティの考え方

## 深掘り用の関連資料

- ルートセットアップ: [README.md](/home/unix/Action/README.md)
- デプロイ手順: [DEPLOYMENT.md](/home/unix/Action/DEPLOYMENT.md)
- Frontend 仕様: [frontend-spec.md](/home/unix/Action/ActionAct/frontend/frontend-spec.md)
- Organize 詳細設計: [organize-ingest-llm-architecture.md](/home/unix/Action/ActionOrganize/docs/organize-ingest-llm-architecture.md)
- Ingest 詳細フロー: [ingest-organize-flow.md](/home/unix/Action/ActionOrganize/docs/ingest-organize-flow.md)
