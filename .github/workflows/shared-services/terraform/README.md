# Terraform Shared-Services Templates

Reusable GitHub Actions workflows for Terraform infrastructure lifecycle management. These templates provide standardized stages for lint, validate, IaC scanning, plan, apply, destroy, and release.

## Workflows

| Workflow | Purpose |
|----------|---------|
| `terraform-pipeline.yml` | Full pipeline — lint, validate, IaC scan, init, plan, approve, apply, destroy, summary |
| `terraform-review.yml` | PR-driven review environments — auto plan/apply on PR, auto destroy on merge/close |
| `terraform-deploy.yml` | Static environment deploy — plan, approval gate, apply, optional GitHub release |
| `terraform-unlock.yml` | Utility — force-unlock a stuck Terraform state lock |

## Composite Actions

| Action | Purpose |
|--------|---------|
| `actions/cloud-auth` | Multi-cloud authentication (Azure, GCP, AWS) |

## Pipeline Stages

```
lint → validate → iac-scan → init → plan → approve → apply → summary
                                                 ↘ destroy (if requested)
```

| Stage | Description |
|-------|-------------|
| **lint** | `terraform fmt -recursive -check` |
| **validate** | `terraform init -backend=false` + `terraform validate` |
| **iac-scan** | tfsec + checkov with SARIF upload |
| **init** | Backend init, workspace create/select, plugin cache |
| **plan** | `terraform plan -detailed-exitcode`, PR comment, artifact upload |
| **approve** | Manual approval via GitHub environment protection rules |
| **apply** | `terraform apply` from saved plan, output export |
| **destroy** | `terraform destroy` + workspace cleanup |
| **release** | Auto-increment semver tag + GitHub release |

## Usage

### Full pipeline (from project-level workflow)

```yaml
name: Infrastructure

on:
  push:
    branches: [main]
    paths: ['infra/**']
  pull_request:
    paths: ['infra/**']

jobs:
  terraform:
    uses: ./.github/workflows/shared-services/terraform/terraform-pipeline.yml
    with:
      infra_directory: infra
      environment: staging
      cloud_provider: gcp
      apply: true
      enable_iac_scan: true
    secrets: inherit
```

### Review environments (auto lifecycle on PR)

```yaml
name: Review Environment

on:
  pull_request:
    types: [opened, synchronize, reopened, closed]
    paths: ['infra/**']

jobs:
  review:
    uses: ./.github/workflows/shared-services/terraform/terraform-review.yml
    with:
      infra_directory: infra
      cloud_provider: gcp
      auto_destroy_on_merge: true
    secrets: inherit
```

### Production deploy (on merge to main)

```yaml
name: Production Deploy

on:
  push:
    branches: [main]
    paths: ['infra/**']

jobs:
  deploy:
    uses: ./.github/workflows/shared-services/terraform/terraform-deploy.yml
    with:
      infra_directory: infra
      environment: production
      cloud_provider: gcp
      create_release: true
    secrets: inherit
```

### Force unlock (manual trigger)

```yaml
name: Terraform Unlock

on:
  workflow_dispatch:
    inputs:
      lock_id:
        description: 'Lock ID to force-unlock'
        required: true

jobs:
  unlock:
    uses: ./.github/workflows/shared-services/terraform/terraform-unlock.yml
    with:
      lock_id: ${{ github.event.inputs.lock_id }}
      cloud_provider: gcp
    secrets: inherit
```

## Cloud Authentication

Set these secrets/variables based on your cloud provider:

### GCP (default)
| Variable | Description |
|----------|-------------|
| `GCP_WORKLOAD_IDENTITY_PROVIDER` | Workload identity provider |
| `GCP_SERVICE_ACCOUNT` | Service account email |

### Azure
| Variable | Description |
|----------|-------------|
| `ARM_CLIENT_ID` | Service principal client ID |
| `ARM_TENANT_ID` | Azure AD tenant ID |
| `ARM_SUBSCRIPTION_ID` | Target subscription |

### AWS
| Variable | Description |
|----------|-------------|
| `AWS_ROLE_ARN` | IAM role ARN for OIDC |
| `AWS_REGION` | Target AWS region |

## Mapping from GitLab Reference

| GitLab Stage | GitHub Equivalent |
|--------------|-------------------|
| `infra: lint` | `terraform-pipeline.yml` → `lint` job |
| `infra: validate` | `terraform-pipeline.yml` → `validate` job |
| `iac-sast` | `terraform-pipeline.yml` → `iac-scan` job |
| `infra: init` | `terraform-pipeline.yml` → `init` job |
| `infra: plan` | `terraform-pipeline.yml` → `plan` job |
| `infra: approvals` | `terraform-pipeline.yml` → `approve` job (GitHub environment protection) |
| `infra: review` | `terraform-review.yml` → `review-deploy` job |
| `infra: stop` | `terraform-review.yml` → `review-destroy` job |
| `infra: deploy` | `terraform-deploy.yml` → `apply` job |
| `infra: release` | `terraform-deploy.yml` → `release` job |
| `infra: unlock` | `terraform-unlock.yml` → `unlock` job |
