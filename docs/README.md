# Action Docs

この `docs/` は、Action を外部の人に説明するときの入口です。
まずは全体像を把握し、その後にフローやセキュリティを個別に読める構成にしています。

## 読み順

1. [Overview](./overview.md)
2. [Ingest / Organize Flow](./flows/ingest-organize.md)
3. [Act Runtime Flow](./flows/act-runtime.md)
4. [Security Overview](./security.md)

## この docs が対象にしていること

- Action が何をするシステムか
- どのコンポーネントがどう連携するか
- ingest / organize の処理がどう進むか
- frontend / act-api / act-adk-worker の役割分担
- 対外説明で必要なセキュリティの考え方

## 深掘り用の関連資料

- ルートセットアップ: [README.md](/home/unix/Action/README.md)
- デプロイ手順: [DEPLOYMENT.md](/home/unix/Action/DEPLOYMENT.md)
- Frontend 仕様: [frontend-spec.md](/home/unix/Action/ActionAct/frontend/frontend-spec.md)
- Organize 詳細設計: [organize-ingest-llm-architecture.md](/home/unix/Action/ActionOrganize/docs/organize-ingest-llm-architecture.md)
- Ingest 詳細フロー: [ingest-organize-flow.md](/home/unix/Action/ActionOrganize/docs/ingest-organize-flow.md)
