# Act

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
make compose-check
make compose-preflight
make smoke-test
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

起動前に bind mount の解決先と compose 解釈を確認したい場合は次を使います。

```bash
make compose-check
```

`make compose-check` は bind mount の解決先を確認します。ディレクトリ不在は error にし、service 実装ファイル不足は compose と同様に wait mode へ入る想定として warning を出します。

`make compose-preflight` は `--profile full` の実効 compose 設定を検査し、`organize` が `VERTEX_USE_REAL_API=true` のときに `GEMINI_API_KEY` が空なら起動前に失敗させます。

起動後の最小疎通確認は次を使います。

```bash
make smoke-test
```

`make smoke-test` は起動中の `frontend`, `act-api`, `act-adk-worker` に対して `/`, `/healthz`, `/auth/session/bootstrap` を確認します。`organize` や `firebase-emulator` が起動中なら、それらの health も追加で確認します。

### 主な環境変数

`compose.yaml` では、ローカル起動用の値を各サービスに明示注入しています。
ここで挙げる値は host 環境変数の fallback ではなく、compose に固定しているローカル既定値です。

Frontend:

* 正本ファイル:
  * local: `ActionAct/frontend/src/config/local.json`
  * prod: `ActionAct/frontend/src/config/prod.json`
* `src/lib/config.ts` が `NODE_ENV` に応じて読み分けます
* frontend に秘密情報は置かず、必要なら server 側で環境変数を読む前提です

Act API:

* `GOOGLE_CLOUD_PROJECT`
  * compose 注入値 `local-dev`
* `SID_STRICT`
  * compose 注入値 `true`
* `SID_REQ_TTL_SECONDS`
  * compose 注入値 `900`
* `SID_LOCK_TTL_SECONDS`
  * compose 注入値 `10`

Organize / Act ADK Worker:

* `VERTEX_USE_REAL_API`
  * compose 注入値 `false`
  * 実 Vertex API を使う場合は `true`
* `GEMINI_MODEL`
  * `organize` のみ
  * compose 注入値 `gemini-3-flash`
* `GEMINI_API_KEY`
  * `organize` のみ
  * `VERTEX_USE_REAL_API=true` のとき必須
  * compose は host の `GEMINI_API_KEY` をそのまま渡す
* `STATE_BACKEND`
  * `organize` のみ
  * compose 注入値 `firestore`
* `PUBSUB_TOPIC_NAME`
  * `organize` のみ
  * compose 注入値 `mind-events`
* `PUBSUB_PUBLISH_ENABLED`
  * `organize` のみ
  * compose 注入値 `true`

これらの値を変える場合は、`compose.yaml` を直接編集するか、override 用 compose file を追加してください。
Frontend の公開設定を変える場合は、`ActionAct/frontend/src/config/local.json` または `ActionAct/frontend/src/config/prod.json` を編集してください。

Gemini 実 API を `organize` で使う最小例:

```bash
export GEMINI_API_KEY=your-api-key
docker compose --profile full up organize
```

`VERTEX_USE_REAL_API=true` に切り替える場合は `compose.yaml` か override で明示してください。

`compose.override.yaml` を使う場合は、次で `organize` を実 API モードで起動できます。

```bash
export GEMINI_API_KEY=your-api-key
docker compose --profile full up organize
```

既定の override では `VERTEX_USE_REAL_API=true` と `GEMINI_MODEL=gemini-3-flash` を注入します。

Optional override:

* `GCS_EMULATOR_IMAGE`
  * 既定値 `fsouza/fake-gcs-server:latest`
  * `gcs-emulator` service の image を差し替える場合だけ使います

### 補足

* `frontend` の公開設定は JSON 正本で管理しています
* `full` profile では [docker/pubsub/init.sh](/home/unix/Action/docker/pubsub/init.sh) が `mind-events` と各 subscription を bootstrap します
* Firebase の最小設定は [docker/firebase/firebase.json](/home/unix/Action/docker/firebase/firebase.json) にあります
* `full` profile の emulator image には Java を同梱しているため、追加の Java セットアップなしで起動できます
* `organize` 単体開発で emulator を使わない場合は、`STATE_BACKEND=memory` でも起動できます
