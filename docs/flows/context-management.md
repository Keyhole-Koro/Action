# Context Management Flow

Action における「コンテクスト（Context）」は、知識グラフ上のノード、ユーザーのセッション情報、およびパーソナライズ情報を LLM が理解可能な形に統合する仕組みです。

---

## 1. Context ライフサイクル概要

コンテクストは、「生成」「選択」「組み立て」の 3 つのフェーズを経て LLM に渡されます。

```mermaid
graph TD
    subgraph "1. Generation (ActionOrganize)"
        Input[Raw Data / Atoms] --> A3[A3: Bundle/Outline]
        A3 --> A4[A4: Node Rollup]
        A4 --> GeminiGen[Gemini: Generate Summary]
        GeminiGen --> NodeStore[(Firestore: Node.contextSummary)]
    end

    subgraph "2. Selection (Frontend)"
        User((User)) --> Graph[Graph UI]
        Graph --> Selection[Select Nodes]
        Selection --> Req[RunActRequest: SelectedNodeContext]
    end

    subgraph "3. Assembly (act-adk-worker)"
        Req --> Assembly[Context Assembly]
        NodeStore --> Assembly
        Overlay[(Personalization Overlay)] --> Assembly
        Assembly --> Prompt[Final LLM Prompt]
        Prompt --> GeminiAct[Gemini: Act Execution]
    end
```

---

## 2. 各フェーズの詳細

### 2-A. Generation (ActionOrganize)
知識化パイプラインの最終段階で、各ノードの「要約」が生成されます。

- **処理主体**: `NodeRollupHandler` / `PipelineWriteService`
- **内容**: 
    - 子ノードの `contextSummary` を集約し、Gemini (Quality) を用約。
    - `contextSummary`: プロンプト埋め込み用の 1-2 文のプレーンテキスト。
    - `detailHtml`: UI 表示および詳細参照用の HTML。
- **保存先**: Firestore `nodes` コレクション의 `contextSummary` フィールド。

### 2-B. Selection (Frontend)
ユーザーの操作や実行時の必要性に応じて、どの知識を LLM に渡すべきかが決定されます。

- **処理主体**: Frontend (`GraphNodeCard`, `act-runner`)
- **内容**: 
    - ユーザーがグラフ上で選択したノード。
    - 実行中のコンテクストに基づき自動選択された関連ノード。
    - `SelectedNodeContext` 型として `act-api` へ送信。

### 2-C. Assembly (act-adk-worker)
実行エンジンが、バラバラの情報を 1 つの「プロンプト」として統合します。

- **処理主体**: `act-adk-worker` (`FirestoreAssembly`)
- **内容**: 
    1. **Node Content Load**: `node_ids` に基づき、Firestore/GCS から正本データを読み込み。
    2. **Overlay Application**: ユーザーごとの `personalization/overlay` を適用（トピックの解釈変更など）。
    3. **Prompt Rendering**: Markdown 形式などで LLM 用の指示と知識を連結。
- **最終出力**: LLM (Gemini) への Input Message。

---

## 3. コンテクスト組み立てのシーケンス

```mermaid
sequenceDiagram
    participant FE as Frontend
    participant API as act-api
    participant WR as act-adk-worker
    participant FS as Firestore / GCS
    participant LLM as Gemini

    Note over FE, FS: 1. Selection
    FE->>API: RunAct(SelectedNodeContexts)
    API->>WR: ExecuteRequest

    Note over WR, FS: 2. Assembly (Context Assembly)
    WR->>FS: Get Node Summaries & Full Content
    FS-->>WR: contextSummary, detailHtml, etc.
    WR->>FS: Load Personalization Overlay
    FS-->>WR: User specific rules / preferences

    Note over WR, LLM: 3. Execution
    WR->>WR: Build Final Prompt
    WR->>LLM: Streamed Inference
    LLM-->>WR: Token Streams
    WR-->>API: Streamed Response
    API-->>FE: Streamed UI Update
```

---

## 4. 関連リソース

- **Schema**: `contracts/act/v1/act.proto` (`SelectedNodeContext`)
- **Logic (Gen)**: `ActionOrganize/src/services/pipeline-write-service.ts`
- **Logic (Assembly)**: `ActionAct/act-adk-worker/app/adapter/firestore_assembly.py`
- **Personalization**: `docs/concepts/personalization-overlay.md` (TBD)
