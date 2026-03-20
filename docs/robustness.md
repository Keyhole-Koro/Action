# Robustness Design

このページは、Action がどのような設計判断で壊れにくい構成を作っているかを説明する資料です。
単に「堅牢である」と述べるのではなく、境界設計、イベント設計、責務分離を具体的に整理しています。

## 基本方針

Action では、堅牢性を次の 4 つで作っています。

- 入口を増やしても内部契約を増やしすぎない
- 重い処理を同期リクエストから切り離す
- 認証、推論、知識更新の責務を混ぜない
- 正本データと一時データを分離する

つまり、error handling を後から足して守るというより、最初から壊れにくい境界を作る方針です。

## 1. 入力経路を増やしても内部イベントはそろえる

Action には複数の入力経路があります。

- `ActionIngest`
  - chat export や large log の取り込み
- `Add Source`
  - frontend からの単発ファイル追加
- Discord integration
  - `discord-bot` が live message を取り込む

これらは入口としては別物ですが、Organize 内部ではなるべく共通の契約へ寄せています。

特に重要なのが `input.received` です。

- `ActionIngest` は `organize.ingest.received` から bridge して `input.received` に寄せる
- `Add Source` は `media.received` を A0 で text 抽出し、`input.received` に変換する
- A1 以降は `input.received` を前提に処理する

この設計の利点:

- 新しい入力チャネルを足しても A1 以降を壊しにくい
- 「どこから来た入力か」と「今どう知識化するか」を分離できる
- pipeline の再実行ポイントが分かりやすい

## 2. 重い処理を UI や API の同期処理に載せない

Action は、ユーザー操作のたびに重い知識化をその場で完了させる設計にしていません。

たとえば `Add Source` では、frontend が upload した時点で全文解析まで終わらせません。
流れは次です。

1. frontend が upload を開始する
2. `act-api` が upload 完了を記録する
3. `media.received` を Pub/Sub に publish する
4. A0 が非同期で media を読み、text を抽出する
5. `input.received` として Organize 本流へ流す

large import でも同様に、

1. `ActionIngest` が normalize / dedupe / chunk を行う
2. chunk job を Pub/Sub に流す
3. Organize が非同期で順次処理する

この設計の利点:

- UI の応答性を落としにくい
- 長い処理や失敗を API timeout に巻き込みにくい
- 再送や再実行の単位を持ちやすい

## 3. API 境界と推論境界を分ける

Action は、1 サービスに全部を押し込んでいません。

- `frontend`
  - UI とユーザー体験
- `act-api`
  - 認証済み API 境界
- `act-adk-worker`
  - LLM runtime
- `organize`
  - knowledge pipeline

これを分けている理由は、責務だけではありません。
障害の性質が違うからです。

- 認証の問題
  - `act-api` で見る
- stream や model 実行の問題
  - `act-adk-worker` で見る
- ingest や topic 更新の問題
  - `organize` で見る

この分離の利点:

- 障害切り分けしやすい
- サービスごとにスケールさせやすい
- public に出す面と internal に閉じる面を分けやすい

## 4. 正本データと raw data と一時状態を分離する

Action は、全部を同じ保存先に混ぜていません。

- Firestore
  - graph, workspace state, integration state などの正本
- GCS
  - upload 済み資料、raw media、Discord raw log
- Pub/Sub
  - 非同期イベントの輸送
- Redis
  - session や request 制御

たとえば Discord では、

- raw message JSON は GCS に保存する
- channel / thread index は Firestore に保存する
- `discord.message.received` は Pub/Sub に流す
- topic / evidence / node は Organize が Firestore に反映する

この分離の利点:

- raw input と knowledge graph の責務が混ざらない
- あとから再処理しやすい
- どこまでが source data で、どこからが derived data か説明しやすい

## 5. 認証とセキュリティ境界を構造で守る

Action は、セキュリティを「気をつける」ではなく、境界で守る方針です。

- `frontend` は公開 UI
- `act-api` は公開 API
- `act-adk-worker`, `organize`, `discord-bot` は internal

ユーザー向け API は `act-api` に集めています。
ここで次を受け持ちます。

- Firebase Auth
- session bootstrap
- CSRF 対策
- upload API
- workspace 操作
- Discord connect 操作

一方で worker や organize は public に出さず、内部経路からのみ使います。

この設計の利点:

- 認証境界が散らばらない
- internal service を直接叩かせない
- frontend bundle に秘密を載せずに済む

## 6. 完全自動にしない方が安全な箇所は確認を残す

Action では、自動化できるからといって全部を自動確定しません。

Discord integration はその例です。

接続時の流れ:

1. workspace owner が install session を作る
2. Discord で bot を guild に招待する
3. `discord-bot` が `guild join` を検知する
4. candidate を session にぶら下げる
5. owner が `Confirm` して binding を確定する

つまり、

- join event は自動で拾う
- しかし guild binding は自動確定しない

この判断の理由:

- 複数 workspace があると誤紐付けのリスクがある
- 自動化より整合性を優先したい
- 「最後に owner が 1 回確認する」方が運用上安全

## 7. なぜ拡張に強いのか

Action は、入力源が増えるほど複雑になる種類のシステムです。
それでも崩れにくくしているのは、「新機能を既存パイプラインに寄せる」方針だからです。

例:

- `Add Source`
  - 新しい知識化ロジックを別実装せず、A0 -> `input.received` に寄せる
- Discord
  - live input をそのまま UI に流さず、raw log 保存と internal event publish に寄せる
- Act
  - frontend から直接 storage や Pub/Sub を触らず、`act-api` 経由に寄せる

この方針の利点:

- 機能追加のたびに全体の契約を増やしすぎない
- 既存の観測点や運用フローを使い回せる
- システム説明が破綻しにくい

## 8. Summary

Action の堅牢性は、複数の入力経路を内部では canonical event に寄せ、重い処理を Pub/Sub 経由の非同期 pipeline に逃がし、`act-api`, `act-adk-worker`, `organize` を責務で分離している点にあります。

また、認証境界、推論境界、知識更新境界、正本データと raw data の保存先を分けることで、応答性、一貫性、拡張性を同時に確保しています。

## 関連資料

- 全体像: [overview.md](/home/unix/Action/docs/overview.md)
- Ingest / Organize: [ingest-organize.md](/home/unix/Action/docs/flows/ingest-organize.md)
- Act Runtime: [act-runtime.md](/home/unix/Action/docs/flows/act-runtime.md)
- Discord: [discord.md](/home/unix/Action/docs/integrations/discord.md)
- Security: [security.md](/home/unix/Action/docs/security.md)
