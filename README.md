# Actions

## Docker Compose

ローカル起動用の compose は [compose.yaml](/home/unix/Action/compose.yaml) にあります。

この repo の現状では、compose でそのまま参照できる実装ディレクトリは次の 4 つです。

* `frontend`: `./ActionAct/frontend`
* `act-api`: `./ActionAct/act-api`
* `act-adk-worker`: `./ActionAct/act-adk-worker`
* `organize`: `./ActionOrganize`

### Profiles

* `ui`
  * `frontend`, `act-api`, `act-adk-worker`, `redis` を起動します
  * Frontend から Act 実行系の疎通確認を行うための最小構成です
* `full`
  * `ui` に加えて `organize`, `firebase-emulator`, `gcs-emulator`, `pubsub-emulator`, `pubsub-bootstrap` を起動します
  * Organize と emulator 群を含めた全経路確認用です

### 起動例

```bash
docker compose --profile ui up
docker compose --profile full up
```

バックグラウンド実行:

```bash
docker compose --profile ui up -d
docker compose --profile full up -d
```

停止:

```bash
docker compose down
```

### 実コードの配置

compose の既定 bind mount は次のとおりです。

* `FRONTEND_DIR=./ActionAct/frontend`
* `ACT_API_DIR=./ActionAct/act-api`
* `ACT_ADK_WORKER_DIR=./ActionAct/act-adk-worker`
* `ORGANIZE_DIR=./ActionOrganize`

この repo では、上記 4 つの既定値がそのまま使えます。

別の checkout や外部ディレクトリを bind mount したい場合だけ、対応する `*_DIR` を上書きしてください。

例:

```bash
FRONTEND_DIR=./ActionAct/frontend \
ACT_API_DIR=/path/to/act-api \
ACT_ADK_WORKER_DIR=/path/to/act-adk-worker \
ORGANIZE_DIR=./ActionOrganize \
docker compose --profile full up
```

### 主な環境変数

* `NEXT_PUBLIC_USE_MOCKS`
  * `ui` では既定値 `true`
  * モックなしで繋ぐ場合は `false`
* `VERTEX_USE_REAL_API`
  * 既定値 `false`
  * 実 Vertex API を使う場合は `true`
* `GOOGLE_CLOUD_PROJECT`
  * 既定値 `local-dev`

例:

```bash
NEXT_PUBLIC_USE_MOCKS=false \
VERTEX_USE_REAL_API=false \
GOOGLE_CLOUD_PROJECT=local-dev \
STATE_BACKEND=memory \
docker compose --profile full up
```

### 補足

* `frontend` の `NEXT_PUBLIC_*` はブラウザから参照するため、既定では `localhost` 向けにしています
* `full` profile では [docker/pubsub/init.sh](/home/unix/Action/docker/pubsub/init.sh) が `mind-events` と各 subscription を bootstrap します
* Firebase の最小設定は [docker/firebase/firebase.json](/home/unix/Action/docker/firebase/firebase.json) にあります
* `full` profile の emulator image には Java を同梱しているため、追加の Java セットアップなしで起動できます
* `organize` 単体開発で emulator を使わない場合は、`STATE_BACKEND=memory` でも起動できます
