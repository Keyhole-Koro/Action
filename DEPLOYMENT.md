# Deployment Guide

Production 限定のデプロイメント手順です。GitHub Actions がメインですが、ローカルからもデプロイ可能です。

## 前提

- GCP インスタンス（Asia-Northeast1）
- GitHub リポジトリ上の Secrets 設定
- ローカルデプロイ用：`gcloud` CLI + Terraform 1.7+

---

## 1. GitHub Actions デプロイ（推奨）

### 1.1 GitHub Secrets の設定

リポジトリ Settings → Secrets and variables → Actions から以下を追加：

| Secret Name | 説明 | 例 |
|------------|------|-----|
| `GCP_PROJECT_ID` | Google Cloud Project ID | `action-490203` |
| `WIF_PROVIDER` | Workload Identity Federation Provider リソース名 | `projects/PROJECT_NUM/locations/global/workloadIdentityPools/github-actions-pool/providers/github-provider` |
| `GCP_DEPLOYER_SA` | デプロイ用 Service Account メアド | `github-deployer-sa@action-490203.iam.gserviceaccount.com` |
| `GITHUB_REPO` | GitHub リポジトリ (owner/repo 形式) | `your-org/Action` |

### 1.2 初回セットアップ

#### A. Terraform State バケット作成

GCP コンソールで以下を実行：

```bash
# GCS バケットを作成（tfstate 管理用）
gsutil mb -p action-490203 -l asia-northeast1 \
  gs://action-490203-tfstate

# バージョニング有効化
gsutil versioning set on gs://action-490203-tfstate
```

#### B. 既存リソースの場合

GCP プロジェクトに既に以下リソースが存在する場合、Terraform にインポートして管理下に置く必要があります。

```bash
cd terraform

# リソース確認（GCP コンソール または gcloud で事前確認）
gcloud redis instances list --region asia-northeast1
gcloud storage buckets list
gcloud pubsub topics list
gcloud run services list --region asia-northeast1

# ---- Import 実行例 ----
# ※ リソース名・ID は環境に合わせて修正

# 1. Redis インスタンス
terraform import google_redis_instance.main \
  projects/action-490203/locations/asia-northeast1/instances/main

# 2. GCS バケット（uploads）
terraform import google_storage_bucket.uploads \
  action-490203-uploads

# 3. Pub/Sub トピック
terraform import google_pubsub_topic.mind_events \
  projects/action-490203/topics/mind-events

# 4. VPC Access Connector
terraform import google_vpc_access_connector.redis_connector \
  projects/action-490203/locations/asia-northeast1/connectors/redis-connector

# 5. Cloud Run サービス（既存がある場合）
terraform import google_cloud_run_service.frontend \
  projects/action-490203/locations/asia-northeast1/services/frontend

# ... 以下、act-api, act-adk-worker, organize も同様

# 短い方法（Makefile を使用）
make terraform-import-all
```

**注意**：Import 後は `terraform state show <resource>` で状態が正しく反映されていることを確認してください。

#### C. 新規プロジェクトの場合

既存リソースが一切ない場合、`terraform apply` で全リソースが自動作成されます。

```bash
cd terraform
terraform init
terraform apply
```

### 1.3 デプロイ

**自動（push to main）**
```
main ブランチに push → CI/CD が自動でビルド・デプロイ
```

**手動トリガー（workflow_dispatch）**
```
GitHub UI → Actions → "Deploy to Cloud Run" → "Run workflow"
  - image_tag: 未入力なら最新コミット SHA を使用
```

---

## 2. ローカルデプロイ

ローカル環境から `gcloud` と `terraform` で本番環境にデプロイします。

### 2.1 前提条件

```bash
# gcloud CLI がインストール済みか確認
gcloud --version

# Terraform インストール確認
terraform -v  # 1.7 以上

# Authenticate to GCP
gcloud auth login
gcloud config set project action-490203
```

### 2.2 環境変数ファイル作成

`terraform/terraform.tfvars` を作成：

```hcl
project_id   = "action-490203"
region       = "asia-northeast1"
image_tag    = "v1.0.0"  # または git SHA など
github_repo  = "your-org/Action"
```

### 2.3 Terraform 実行

```bash
cd terraform

# 初期化（初回のみ）
terraform init

# 変更内容の確認
terraform plan

# インフラストラクチャと Cloud Run サービスを適用
terraform apply
```

### 2.4 コンテナイメージのビルド・プッシュ（別途）

Terraform は イメージタグに基づいて Cloud Run を更新するため、事前にイメージを Artifact Registry にプッシュする必要があります。

```bash
# 変数設定
export PROJECT_ID="action-490203"
export REGION="asia-northeast1"
export IMAGE_TAG="v1.0.0"  # git SHA でも可

# Docker 認証
gcloud auth configure-docker ${REGION}-docker.pkg.dev

# frontend をビルド・プッシュ
docker build \
  --build-arg NEXT_PUBLIC_USE_MOCKS=false \
  --build-arg NEXT_PUBLIC_FIREBASE_API_KEY="${FIREBASE_API_KEY}" \
  --build-arg NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN="${FIREBASE_AUTH_DOMAIN}" \
  --build-arg NEXT_PUBLIC_FIREBASE_APP_ID="${FIREBASE_APP_ID}" \
  --build-arg NEXT_PUBLIC_GCLOUD_PROJECT="${PROJECT_ID}" \
  -t ${REGION}-docker.pkg.dev/${PROJECT_ID}/action/frontend:${IMAGE_TAG} \
  -t ${REGION}-docker.pkg.dev/${PROJECT_ID}/action/frontend:latest \
  ActionAct/frontend
docker push ${REGION}-docker.pkg.dev/${PROJECT_ID}/action/frontend:${IMAGE_TAG}
docker push ${REGION}-docker.pkg.dev/${PROJECT_ID}/action/frontend:latest

# act-api をビルド・プッシュ
docker build \
  -t ${REGION}-docker.pkg.dev/${PROJECT_ID}/action/act-api:${IMAGE_TAG} \
  -t ${REGION}-docker.pkg.dev/${PROJECT_ID}/action/act-api:latest \
  ActionAct/act-api
docker push ${REGION}-docker.pkg.dev/${PROJECT_ID}/action/act-api:${IMAGE_TAG}
docker push ${REGION}-docker.pkg.dev/${PROJECT_ID}/action/act-api:latest

# act-adk-worker をビルド・プッシュ
docker build \
  -t ${REGION}-docker.pkg.dev/${PROJECT_ID}/action/act-adk-worker:${IMAGE_TAG} \
  -t ${REGION}-docker.pkg.dev/${PROJECT_ID}/action/act-adk-worker:latest \
  ActionAct/act-adk-worker
docker push ${REGION}-docker.pkg.dev/${PROJECT_ID}/action/act-adk-worker:${IMAGE_TAG}
docker push ${REGION}-docker.pkg.dev/${PROJECT_ID}/action/act-adk-worker:latest

# organize をビルド・プッシュ
docker build \
  -t ${REGION}-docker.pkg.dev/${PROJECT_ID}/action/organize:${IMAGE_TAG} \
  -t ${REGION}-docker.pkg.dev/${PROJECT_ID}/action/organize:latest \
  ActionOrganize
docker push ${REGION}-docker.pkg.dev/${PROJECT_ID}/action/organize:${IMAGE_TAG}
docker push ${REGION}-docker.pkg.dev/${PROJECT_ID}/action/organize:latest
```

または **Makefile** を使って一括ビルド・プッシュ：

```bash
make docker-build IMAGE_TAG=v1.0.0
make docker-push IMAGE_TAG=v1.0.0
make terraform-apply IMAGE_TAG=v1.0.0
```

---

## 3. デプロイ状態の確認

```bash
# Cloud Run サービス一覧
gcloud run services list --region asia-northeast1 --format="table(name,status.url)"

# 特定サービスの詳細
gcloud run services describe frontend --region asia-northeast1

# ログ確認（最新 50 行）
gcloud run services logs read frontend --region asia-northeast1 --limit=50
```

---

## 4. ロールバック

イメージを巻き戻す場合：

```bash
# 以前のイメージタグでサービスを更新
cd terraform
terraform apply -var="image_tag=v1.0.0-previous" -auto-approve
```

---

## 5. シークレット管理

Google Secret Manager に保存されたシークレットは、Cloud Run のサービスアカウント経由でアクセスされます。

### シークレット追加例

```bash
# Google API Key をシークレットに追加
gcloud secrets versions add google-api-key --data-file=- <<< "YOUR_API_KEY"

# 確認
gcloud secrets versions list google-api-key
```

Cloud Run 上で環境変数 `GOOGLE_API_KEY_SECRET_ID` が設定されているため、アプリから読み取り可能です。

---

## 6. セキュリティ運用

本リポジトリの本番デプロイでは、認証情報の置き場所と公開境界を曖昧にしないことを優先します。

### 6.1 認証とデプロイ権限

- GitHub Actions から GCP へ接続するときは、長期鍵ではなく Workload Identity Federation を使います。
- `GCP_DEPLOYER_SA` には必要最小限の権限だけを付与し、Editor のような広すぎるロールは避けてください。
- 個人の `gcloud auth login` は初期構築や緊急対応に限定し、通常運用は GitHub Actions 経由に寄せます。

### 6.2 シークレットの扱い

- `google_api_key` のような秘密値は Secret Manager で管理し、`terraform.tfvars` の平文配布や commit は行わないでください。
- frontend 用の Firebase 設定値は公開前提の構成値ですが、サーバー側シークレットと同じ場所に混在させないでください。
- ローカル開発用の `.env` や `terraform.tfvars` は Git 管理外に置き、共有時は安全な経路を使ってください。

### 6.3 ネットワーク境界

- `act_api_cors_allowed_origins` には実際に許可する origin だけを明示し、ワイルドカード運用は避けてください。
- Cloud Run の公開設定はサービスごとに見直し、外部公開が不要なものは unauthenticated access を許可しないでください。
- Redis や内部 API は、Cloud Run のサービスアカウントと VPC 接続を前提に閉じた経路で扱ってください。

### 6.4 監査とローテーション

- API key や deploy 権限を持つサービスアカウントは、定期的に棚卸ししてください。
- インシデント時に追跡できるよう、Cloud Run revision、Terraform apply、Secret の更新履歴を運用ログとして残してください。
- 漏えいの疑いがある場合は、Secret の新バージョン発行と再デプロイを同じ変更手順に含めてください。

### 6.5 このリポジトリでの実務ルール

- 必須環境変数に fallback を入れず、missing 時は起動または初期化で明示的に失敗させます。
- 秘密値を frontend bundle に入れないでください。公開してよい値は frontend JSON config に限定します。
- 認証やセッションの境界を変更する場合は、frontend と act-api の両方の仕様と実装を同時に確認してください。

---

## 7. トラブルシューティング

### Terraform state がロック状態

```bash
# ロック削除（注意：実行中の apply が存在しないことを確認）
terraform force-unlock <LOCK_ID>
```

### イメージプッシュで auth エラー

```bash
gcloud auth configure-docker asia-northeast1-docker.pkg.dev
```

### デプロイ後に Cloud Run が古いイメージを使用

Terraform のリビジョンが新しいものに更新されていないことがあります：

```bash
gcloud run deploy <SERVICE_NAME> \
  --image <NEW_IMAGE_URL> \
  --region asia-northeast1 \
  --no-traffic-tags
```
