# Google Stack

このページは、Action が Google 技術をどこでどう使っているかを説明する資料です。
ハッカソン審査で「Google の技術をうまく活用できているか」に答えるため、機能ごとではなくシステム全体の役割分担として整理しています。

## 一覧

| 技術 | Action での役割 | 具体的に使っている場所 | なぜこの技術か |
| --- | --- | --- | --- |
| Gemini | 知識化と Act 実行の中心となる AI | Organize の知識更新、Act の推論 | 単発回答ではなく、知識更新と行動支援の両方を同じ AI で回せる |
| Cloud Run | HTTP サービスの実行基盤 | `frontend`, `act-api`, `act-adk-worker`, `organize` | サービスごとに責務を分けて独立デプロイしやすい |
| Firestore | 正本データストア | graph, drafts, workspace state, integration state | 低レイテンシで状態を持てて、UI と backend の同期もしやすい |
| Cloud Storage | raw data の保管 | upload file, raw media, Discord raw log | 大きいファイルや再処理対象の raw data を安全に保持しやすい |
| Pub/Sub | 非同期イベント基盤 | `media.received`, `input.received`, `discord.message.received` など | UI と重い知識化処理を疎結合にできる |
| Redis | request 制御と session 周辺 | session, CSRF 周辺, request gate | 低レイテンシで一時制御情報を持ちやすい |
| Secret Manager | secret 管理 | bot token や deploy 時の secret 注入 | frontend や repo に秘密を置かずに済む |
| Artifact Registry | container image 配布 | 各サービス image | 複数サービスの build / deploy を一貫して扱いやすい |
| Compute Engine | 常駐 bot 実行基盤 | `discord-bot` | Discord WebSocket 常駐のような長時間接続に向いている |

## 1. Gemini をどう使っているか

Action における Gemini は、単なる chat completion API ではありません。
役割は大きく 2 つあります。

### Organize 側

- 入力された text を atom 化する
- topic を解決する
- draft / outline / node を更新する

つまり、情報を「読んで答える」のではなく、「知識構造へ変換する」ために使っています。

### Act 側

- graph context を読んで回答する
- follow-up の流れを進める
- 必要に応じて保存済み Discord ログや web grounding を使う

つまり、知識化された情報を「使って次の行動を支援する」ために使っています。

### 審査での言い方

> Gemini を chat bot としてだけ使うのではなく、知識化パイプラインと Act 実行の両方に組み込み、AI をプロダクトの中心的な runtime にしています。

## 2. Cloud Run をどう使っているか

Action の HTTP サービスは Cloud Run を前提に分離しています。

- `frontend`
  - 公開 UI
- `act-api`
  - 認証付き API 境界
- `act-adk-worker`
  - 推論 runtime
- `organize`
  - 知識化 pipeline の HTTP 入口

### なぜ分けるのか

- UI と知識化の負荷特性が違う
- 認証境界を `act-api` に寄せたい
- worker や organize を public にしたくない
- サービスごとに独立して改善・デプロイしたい

### 審査での言い方

> Cloud Run を 1 サービスの hosting に使ったのではなく、UI、認証境界、推論 runtime、知識化 pipeline を分離する実行基盤として使っています。

## 3. Firestore をどう使っているか

Firestore は Action の正本ストアです。

主に持っているもの:

- topic / node などの graph 状態
- draft や integration の状態
- workspace 状態
- Discord binding や install session の状態

### なぜ Firestore か

- UI から見たい状態と backend が持つ状態を近く保てる
- 小さな document 単位で更新しやすい
- graph や integration 状態の正本として扱いやすい

### 審査での言い方

> Firestore を単なる保存先ではなく、graph と workspace state の source of truth として使っています。

## 4. Cloud Storage をどう使っているか

GCS は raw data の保存に使っています。

保存しているもの:

- upload された file
- media extraction 前の raw input
- Discord の raw message JSON

### なぜ GCS か

- raw input を正本 graph と分けて持てる
- あとから再処理しやすい
- 大きい file を Firestore に持ち込まずに済む

### 審査での言い方

> Firestore に全部を入れず、raw data は GCS に分離することで、再処理しやすい構成にしています。

## 5. Pub/Sub をどう使っているか

Pub/Sub は Action の内部イベント基盤です。

代表的な event:

- `organize.ingest.received`
- `media.received`
- `input.received`
- `discord.message.received`

### 役割

- UI や upload API と重い知識化処理を分離する
- 複数入口を Organize に疎結合でつなぐ
- retry や再処理の単位を持ちやすくする

### なぜ重要か

Action の堅牢性は、この非同期境界にかなり依存しています。
同期 API で全部を処理しないからこそ、応答性と拡張性を両立できます。

### 審査での言い方

> Pub/Sub を通知用途ではなく、知識化 pipeline を成り立たせる内部 event bus として使っています。

## 6. Redis をどう使っているか

Redis は正本保存ではなく、一時的な request 制御に使っています。

主な用途:

- session 周辺
- request の重複制御
- lock / gate のような短命制御

### なぜ Firestore ではなく Redis か

- 低レイテンシで扱いたい
- 正本データではなく ephemeral state だから

### 審査での言い方

> Redis は graph の正本ではなく、session や request gate のような短命制御に限定しています。

## 7. Secret Manager / Artifact Registry / Compute Engine

### Secret Manager

- bot token などの secret を runtime に注入する
- repo や frontend bundle に秘密を残さない

### Artifact Registry

- 各サービス image を build / push / deploy する
- 複数サービス構成でも配布経路をそろえる

### Compute Engine

- `discord-bot` を常駐で動かす
- Discord WebSocket のような長時間接続を安定して扱う

### 審査での言い方

> Google 技術を AI API だけで終わらせず、実運用に必要な secret, image distribution, long-running worker まで含めて組んでいます。

## 8. なぜ Google 技術の使い方として強いのか

Action のポイントは、Google 技術を単発 feature のために使っていないことです。
それぞれの技術が architecture の役割を持っています。

- Gemini
  - 知識化と Act 実行の頭脳
- Cloud Run
  - サービス分離の実行基盤
- Firestore
  - state の正本
- GCS
  - raw data の保管
- Pub/Sub
  - pipeline の内部 event bus
- Redis
  - session / gate 制御

つまり、「Google の技術をいろいろ使いました」ではなく、
「Google の技術でシステムの責務分離そのものを作った」と説明できます。

## 9. 審査で使える短い説明文

> Action では、Google 技術を feature 単位ではなく architecture 単位で使っています。  
> Gemini は知識化と Act 実行の中心、Cloud Run は UI / API / worker / pipeline の分離基盤、Firestore は state の正本、GCS は raw data の保管、Pub/Sub は内部 event bus、Redis は request 制御です。  
> それぞれを役割で分けることで、完成度と拡張性の両方を確保しています。
