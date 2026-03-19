# Terraform Refactoring: Directory Structure

Terraform を責務別 + モジュール化で整理しました。

## 構造概要

```
terraform/
├── provider.tf                          # Backend + provider definition
├── variables.tf                         # Root variables (passed to infrastructure)
├── main.tf                              # Root module: Orchestrate infrastructure
├── outputs.tf                           # Root outputs (pass-through)
├── terraform.tfvars.example
│
├── modules/                             # Reusable components
│   ├── gcp_api_enablement/              # Enable GCP APIs
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── iam_service_account/             # Service Account creation
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── cloud_run_service/               # Cloud Run service (generic)
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
│
└── infrastructure/                      # Project-specific infrastructure
    ├── variables.tf
    ├── core.tf                          # API enablement + Artifact Registry
    ├── iam.tf                           # IAM + Workload Identity Federation
    ├── network.tf                       # VPC Connector
    ├── data_stores.tf                   # Redis + GCS + Secret Manager
    ├── messaging.tf                     # Pub/Sub topics & subscriptions
    ├── services.tf                      # Cloud Run services (via modules)
    └── outputs.tf
```

## メリット

| 項目 | 効果 |
|------|------|
| **モジュール再利用** | `cloud_run_service` を新規サービス追加時に再利用 |
| **責務分離** | core, iam, network, data_stores, messaging, services で関心を分離 |
| **保守性向上** | ファイル数削減（21個 → 比較）+ ロジック集約 |
| **拡張性** | dev環境追加時に `infrastructure/` をコピーして root で呼び出し可能 |

## 削除したファイル

以下は `infrastructure/` と `modules/` に統合されたため削除されました：

```
terraform/
├── apis.tf                    → infrastructure/core.tf
├── iam.tf                     → infrastructure/iam.tf
├── network.tf                 → infrastructure/network.tf  
├── redis.tf                   → infrastructure/data_stores.tf
├── storage.tf                 → infrastructure/data_stores.tf
├── pubsub.tf                  → infrastructure/messaging.tf
├── secrets.tf                 → infrastructure/data_stores.tf
└── services/                  → infrastructure/services.tf (modules経由)
    ├── variables.tf
    ├── act_adk_worker.tf
    ├── act_api.tf
    ├── frontend.tf
    ├── organize.tf
    └── outputs.tf
```

## 動作確認

```bash
# 初期化 & 計画確認
cd terraform
terraform init
terraform plan \
  -var="project_id=action-490203" \
  -var="image_tag=v1.0.0" \
  -var="github_repo=your-org/Action"

# 本番環境にデプロイ (既存コマンド変わらず)
make terraform-apply IMAGE_TAG=v1.0.0
```

## 新規環境追加時の流れ

例：dev環境を追加する場合

```bash
# 1. infrastructure/ をコピー
cp -r infrastructure/ infrastructure_dev/

# 2. 環境別変数を指定して実行
terraform apply \
  -var-file="environments/dev.tfvars" \
  # ... infrastructure_dev 配下を参照
```
