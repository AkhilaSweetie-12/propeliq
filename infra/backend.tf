# -----------------------------------------------------------------------------
# Remote State Backend — GCS
# -----------------------------------------------------------------------------
# Before first use, create the bucket:
#   gsutil mb -p <PROJECT_ID> -l <REGION> gs://<PROJECT_ID>-tfstate
#   gsutil versioning set on gs://<PROJECT_ID>-tfstate

terraform {
  backend "gcs" {
    bucket = ""
    prefix = "infra/state"
  }
}
