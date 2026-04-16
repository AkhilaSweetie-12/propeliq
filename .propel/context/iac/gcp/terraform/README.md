# GCP Terraform Baseline

This folder contains a baseline Terraform structure generated from the "infra setup" DevOps orchestration.

## Structure
- modules/networking
- modules/security
- modules/compute
- modules/storage
- modules/database
- modules/monitoring
- environments/dev
- environments/qa
- environments/staging
- environments/prod

## Baseline Notes
- This scaffold is intentionally conservative and environment-driven.
- Replace placeholder variables in tfvars files before apply.
- Configure remote state bucket and IAM before first deployment.
