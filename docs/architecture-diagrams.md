# Architecture Diagrams

このページは、Action の構成と主要フローを図としてまとめた資料です。
細かい仕様説明は省き、構成と流れを短く参照できることを優先しています。

## 1. System Overview

```mermaid
flowchart LR
    User["User"]
    Frontend["Frontend<br/>Next.js SPA"]
    ActAPI["act-api<br/>session / RPC gateway"]
    Worker["act-adk-worker<br/>LLM runtime"]
    Ingest["ActionIngest<br/>large import"]
    Upload["Add Source<br/>single file upload"]
    Organize["ActionOrganize<br/>knowledge pipeline"]
    Discord["discord-bot<br/>guild listener"]
    Store["Firestore / GCS"]
    Redis["Redis"]
    PubSub["Pub/Sub"]

    User --> Frontend
    Frontend --> ActAPI
    ActAPI --> Worker
    Worker --> Store
    ActAPI --> Redis
    Ingest --> PubSub
    Upload --> PubSub
    Discord --> PubSub
    Discord --> Store
    PubSub --> Organize
    Organize --> Store
    Organize --> Redis
```

Notes:

- 最初の全体説明
- 「何のサービスがあるのか」を短く示したいとき

## 2. Large Import Flow

```mermaid
flowchart LR
    File["Chat export / log file"]
    Normalize["ActionIngest<br/>normalize / dedupe / chunk"]
    Topic["Pub/Sub<br/>organize.ingest.received"]
    Receive["Organize bridge"]
    Atomize["A1 Atomize"]
    Resolve["A2 Topic Resolve"]
    Draft["Draft / Bundle / Outline"]
    Node["Node update"]
    Data["Firestore / GCS"]

    File --> Normalize --> Topic --> Receive --> Atomize --> Resolve --> Draft --> Node --> Data
```

Notes:

- `ActionIngest` の役割説明
- 大きい入力をどう扱うかの説明

## 3. Add Source Flow

```mermaid
flowchart LR
    User["User"]
    Frontend["Frontend"]
    API["act-api<br/>upload API"]
    Media["Pub/Sub<br/>media.received"]
    A0["A0 Media Extraction"]
    Input["Pub/Sub<br/>input.received"]
    A1["A1 Atomize"]
    Resolve["A2 Topic Resolve"]
    Draft["Draft / Bundle / Outline"]
    Data["Firestore / GCS"]

    User --> Frontend --> API --> Media --> A0 --> Input --> A1 --> Resolve --> Draft --> Data
```

Notes:

- UI からの file 追加がどう知識化されるか
- `ActionIngest` とは別入口であることの説明

## 4. Act Runtime Flow

```mermaid
sequenceDiagram
    participant U as User
    participant F as Frontend
    participant A as act-api
    participant W as act-adk-worker
    participant S as Firestore / GCS
    participant D as Discord logs

    U->>F: ask / select / upload
    F->>A: auth bootstrap or RunAct
    A->>W: execute request
    W->>S: read context bundle
    W->>D: optional read/search
    W-->>A: streamed response
    A-->>F: response stream
    F-->>U: progressive UI update
```

Notes:

- UI, API, worker の責務分離説明
- streaming response の説明

## 5. Discord Integration Flow

```mermaid
sequenceDiagram
    participant Owner as Workspace owner
    participant Frontend as Frontend
    participant API as act-api
    participant Discord as Discord
    participant Bot as discord-bot
    participant Store as Firestore

    Owner->>Frontend: Open Invite
    Frontend->>API: create install session
    API-->>Frontend: invite URL
    Owner->>Discord: invite bot to guild
    Discord->>Bot: guild join
    Bot->>Store: attach candidate to session
    Frontend->>API: poll session status
    API-->>Frontend: candidate list
    Owner->>Frontend: Confirm
    Frontend->>API: confirm binding
```

Notes:

- Discord connect が半自動 confirm であることの説明
- 安全性と UX のバランス説明

## 6. Discord Message Ingestion

```mermaid
sequenceDiagram
    participant D as Discord
    participant B as discord-bot
    participant S as Firestore / GCS
    participant P as Pub/Sub
    participant O as ActionOrganize

    D->>B: guild message
    B->>S: save raw message JSON
    B->>S: update channel / thread index
    B->>P: discord.message.received
    P->>O: push event
    O->>S: update topic / evidence / node
```

Notes:

- Discord が単なる bot demo ではなく knowledge pipeline に入ることの説明

## 7. Security Boundary

```mermaid
flowchart LR
    User["Browser user"]
    Discord["Discord"]
    Frontend["frontend"]
    ActAPI["act-api"]
    Worker["act-adk-worker"]
    Organize["organize"]
    Bot["discord-bot"]
    Internal["Redis / PubSub / Firestore / GCS"]

    User --> Frontend --> ActAPI
    Discord --> Bot
    ActAPI --> Worker
    ActAPI --> Internal
    Worker --> Internal
    Organize --> Internal
    Bot --> Internal
```

Notes:

- public / internal boundary の説明
- secret や internal service をどう閉じているかの説明

## 8. Diagram Set

このページにある図は、それぞれ独立して参照できます。
全体構成を先に見る場合は `System Overview`、実行系を見る場合は `Act Runtime Flow`、入力経路を見る場合は `Large Import Flow` と `Add Source Flow`、外部連携を見る場合は `Discord Integration Flow` と `Discord Message Ingestion` を参照してください。
