# Actions

## Docker Compose

ローカル起動用の compose は [compose.yaml](/home/unix/Action/compose.yaml) にあります。

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

compose の既定値は次のディレクトリを bind mount します。

* `./frontend`
* `./act/act-api`
* `./act/act-adk-worker`
* `./ActionOrganize`

この repo の現状では、実在する既定値は次の 2 つです。

* `FRONTEND_DIR=./ActionAct/frontend`
* `ORGANIZE_DIR=./ActionOrganize`

実際の配置が異なる場合は、起動時に環境変数で上書きしてください。

```bash
FRONTEND_DIR=./apps/frontend \
ACT_API_DIR=./apps/act-api \
ACT_ADK_WORKER_DIR=./apps/act-adk-worker \
ORGANIZE_DIR=./apps/organize \
docker compose --profile full up
```

ソースが未配置のサービスは、コンテナ内で待機メッセージを出して停止せず待つようにしています。

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
docker compose --profile full up
```

### 補足

* `frontend` の `NEXT_PUBLIC_*` はブラウザから参照するため、既定では `localhost` 向けにしています
* `full` profile では [docker/pubsub/init.sh](/home/unix/Action/docker/pubsub/init.sh) が `mind-events` と各 subscription を bootstrap します
* Firebase の最小設定は [docker/firebase/firebase.json](/home/unix/Action/docker/firebase/firebase.json) にあります
