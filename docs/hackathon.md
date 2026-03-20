# Hackathon Narrative

このページは、Action をハッカソン審査向けに説明するための要約です。
技術説明そのものではなく、「なぜこれを作ったのか」「何が新しいのか」「なぜ実運用に耐えるのか」を伝えるための資料です。

## 一言でいうと

Action は、会話、資料、Discord、ログのように散らばった情報を、あとから使える知識グラフへ変換し、その知識をもとに AI と次の作業まで進められるシステムです。

単に検索するだけではなく、

- 情報を取り込む
- 知識として整理する
- その知識をもとに次の行動を起こす

までを 1 つの体験にまとめています。

## テーマへの答え

テーマ `Brand New "Hello World."` に対して、Action の答えは次です。

> これからの `Hello World` は、1 回の prompt で終わる会話ではなく、散らばった現実の情報を継続的に知識化し、その知識と一緒に AI と仕事を進める入口である。

### なぜ `Brand New` なのか

- AI を単発チャットではなく、継続的に育つ knowledge graph と組み合わせている
- `ingest`, `organize`, `act` を分け、知識化と対話を同じ体験の中でつないでいる
- Discord のような外部会話も live に取り込み、あとから Act で再利用できる
- `Add Source` で単発資料を足し、`ActionIngest` で大きな履歴を入れ、どちらも同じ知識パイプラインへ寄せている

### ストーリー

多くの人にとって、情報は 1 箇所にありません。
会話は chat に散り、意思決定は Discord に流れ、資料は PDF や画像で溜まり、あとから何も見つからなくなります。

Action は、この「情報が散らばること」を前提にしています。
まず散らばった入力を受け止め、知識グラフとして整理し、その知識をもとに AI と次の問いを進められるようにします。

## 再現性

### デモで何を見せられるか

1. `Add Source` で資料を追加する
2. 追加された情報が Organize に入り、topic / node が増える
3. graph 上の Act node から follow-up を投げる
4. 保存済み知識や Discord ログを参照しながら回答が返る

つまり、入力から知識化、知識から次の行動までを一連でデモできます。

### 多くの人に届く形か

- frontend はブラウザベースの SPA です
- API 境界は `act-api` にまとめています
- Discord integration により、既存のコミュニケーション環境からもデータを取り込めます
- 単発資料と大量履歴の両方に入口があります

### 実運用に向けた考慮

- 重い処理は非同期の Organize パイプラインへ切り出しています
- `input.received` のような canonical event にそろえ、入口が増えても内部を安定させています
- `act-api`, `act-adk-worker`, `organize` を分離し、責務ごとにスケールしやすくしています
- 認証、CSRF、内部サービス分離、Secret Manager 前提の構成を取っています

### どうやって堅固に実装したか

Action の堅牢性は、「気をつけています」と言うより、壊れにくい境界を先に決めて実装している点にあります。

1. 入口が増えても内部イベントを増やしすぎない
   - `ActionIngest`, `Add Source`, Discord という 3 種類の入口があります
   - ただし Organize 内部では `input.received` を canonical event にしており、A1 以降の処理系は入口の違いを意識しません
   - これにより、新しい入力チャネルを足しても後段の知識化ロジックを壊しにくくしています

2. 重い処理を UI リクエストから切り離す
   - upload 完了や ingest 完了の時点では、すぐに全文処理しません
   - `media.received` や `organize.ingest.received` を Pub/Sub に流し、非同期の Organize 側で処理します
   - これにより、ユーザー体験と知識化パイプラインの負荷を分離しています

3. API 境界と推論境界を分ける
   - `frontend` は UI
   - `act-api` は認証済み API 境界
   - `act-adk-worker` は LLM runtime
   - `organize` は知識化パイプライン
   と分離しています
   - これにより、認証、推論、知識更新の責務が混ざらず、障害切り分けもしやすくしています

4. 正本データと一時状態を分ける
   - Firestore を graph や workspace state の正本に使います
   - GCS は upload 済み資料や raw Discord log の保存先です
   - UI の一時 stream や途中イベントを、いきなり正本にしない構成にしています

5. セキュリティ境界をコード上でも固定する
   - `act-api` で session bootstrap と CSRF を通します
   - internal service である `act-adk-worker`, `organize`, `discord-bot` は public API にしません
   - secret は frontend bundle に置かず、実行環境や Secret Manager に寄せています

6. 完全自動化しない方が安全な箇所は確認を残す
   - Discord integration は `guild join` を拾うだけで binding を自動確定しません
   - install session と candidate を出し、workspace owner の confirm を 1 回通します
   - これは UX より整合性を優先した設計です

### 審査でそのまま言える表現

> 堅牢性は、あとから error handling を足したのではなく、最初から境界を分けて壊れにくい形にした点にあります。  
> 具体的には、複数の入力経路を `input.received` に寄せ、重い処理を Pub/Sub 経由の非同期パイプラインへ逃がし、`act-api`, `act-adk-worker`, `organize` を責務で分離しました。  
> そのため、UI 応答性と知識化の一貫性を両立しながら、機能追加にも耐えやすい構成になっています。

## Google 技術の活用

Action は Google 技術を単発で使っているのではなく、プロダクト全体の骨格に組み込んでいます。

### 使っている主な技術

- Gemini
  - Organize の知識化と Act の推論の中心です
- Cloud Run
  - `frontend`, `act-api`, `act-adk-worker`, `organize` の実行基盤です
- Firestore
  - graph, drafts, workspace state, integration state の正本です
- GCS
  - upload 済み資料や Discord raw log を保存します
- Pub/Sub
  - `media.received`, `input.received`, `discord.message.received` などの内部イベントを運びます
- Redis
  - session や request 制御に使います

### Google AI をどう活かしているか

- Gemini を単なる chat completion ではなく、knowledge graph 更新と Act 実行の両方に使っている
- Discord logs や graph context を組み合わせ、AI が孤立した prompt ではなく蓄積知識を前提に動く
- Grounding や tool 呼び出しを通じて、外部情報や保存済み情報を実行時に参照できる

### 技術的難しさ

- UI 応答系と知識化パイプラインを分けつつ、1 つの体験としてつなぐ必要がある
- 単発 upload、大量 ingest、Discord live input という異なる入口を、内部では同じ Organize 系へ寄せている
- AI runtime と graph UI の両方を保ちながら、認証境界と内部イベント設計を壊さない必要がある

## 異端性

Action の異端性は、単に技術を多く使っていることではありません。
普通なら別物として作るものを、あえて 1 つの流れにしています。

- knowledge graph と AI chat を別画面にしない
- Discord bot と document ingest を別プロダクトにしない
- 単発の回答生成で終わらず、graph 上に問いの枝分かれを残す
- 対話 UI と非同期知識パイプラインを同じ体験にまとめる

発表では、「AI に聞く」のではなく「AI と一緒に知識を育てながら次の行動に進む」という見せ方にすると、印象が強くなります。

## 発表で強く出すべきポイント

1. Action は chat app ではなく、知識化と行動をつなぐ system であること
2. `Add Source`, Discord, large import という複数入口が、内部では 1 つの Organize に寄ること
3. graph 上で問いが枝分かれし、AI の作業履歴と知識の関係が見えること
4. Google 技術を feature 単位ではなく architecture 単位で使っていること

## デモのすすめ方

1. 問題提起
   - 情報は chat, Discord, PDF に散らばって消える
2. 取り込み
   - `Add Source` か Discord で情報を入れる
3. 知識化
   - graph に topic / node が出る
4. 実行
   - Act node から follow-up を投げる
5. 余韻
   - 「これは単発の回答ではなく、次回も使える知識になる」と締める
