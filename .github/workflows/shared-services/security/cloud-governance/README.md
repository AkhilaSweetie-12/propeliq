# Cloud Governance — GCP

Reusable GitHub Actions workflows for GCP cloud governance. Enforces security policies, IAM hygiene, cost management, and compliance standards across all projects.

## Structure

```
cloud-governance/
├── governance-pipeline.yml       ← Reusable: full governance pipeline
├── policies/                     ← OPA/Rego policy-as-code rules
│   ├── labels.rego               ← Resource labeling enforcement
│   ├── network.rego              ← Firewall / network security rules
│   ├── iam.rego                  ← IAM least-privilege enforcement
│   ├── storage.rego              ← Storage bucket security rules
│   └── compute.rego              ← Compute & SQL security rules
└── README.md
```

## Governance Checks

| Job | What It Does |
|-----|-------------|
| **policy-check** | Evaluates OPA/Rego policies against Terraform plan — blocks PRs on violations |
| **iam-audit** | Audits IAM bindings, flags overly permissive roles, checks for user-managed SA keys |
| **cost-check** | Scans for expensive/orphaned resources, checks billing, enforces labeling |
| **compliance-scan** | Audits firewall rules, bucket security, audit logging, enabled APIs |

## OPA Policies

| Policy | Rules |
|--------|-------|
| **labels.rego** | All resources must have `environment`, `team`, `cost-center` labels. Environment must be one of: dev, staging, production, review |
| **network.rego** | No firewall rules allowing SSH/RDP/all-ports from `0.0.0.0/0` |
| **iam.rego** | No `roles/owner`, `roles/editor`, or other overly permissive roles. No `allUsers` or `allAuthenticatedUsers` bindings |
| **storage.rego** | Buckets must have versioning, uniform bucket-level access, and no public IAM |
| **compute.rego** | No public IPs on VMs (use Cloud NAT/IAP), shielded VMs required, no public Cloud SQL |

## Usage

### From project-level pipeline

```yaml
name: Cloud Governance

on:
  schedule:
    - cron: '0 6 * * 1'    # Weekly Monday 6am UTC
  pull_request:
    paths: ['infra/**']
  workflow_dispatch:

jobs:
  governance:
    uses: ./.github/workflows/shared-services/security/cloud-governance/governance-pipeline.yml
    with:
      gcp_project_id: my-gcp-project-id
      infra_directory: infra
      enable_iam_audit: true
      enable_cost_check: true
      enable_compliance_scan: true
      enable_policy_check: true
      cost_threshold_monthly: '1000'
    secrets: inherit
```

### Policy-only (on every PR)

```yaml
jobs:
  policy:
    uses: ./.github/workflows/shared-services/security/cloud-governance/governance-pipeline.yml
    with:
      gcp_project_id: my-gcp-project-id
      enable_policy_check: true
      enable_iam_audit: false
      enable_cost_check: false
      enable_compliance_scan: false
    secrets: inherit
```

### Full audit (scheduled)

```yaml
jobs:
  audit:
    uses: ./.github/workflows/shared-services/security/cloud-governance/governance-pipeline.yml
    with:
      gcp_project_id: my-gcp-project-id
      enable_policy_check: true
      enable_iam_audit: true
      enable_cost_check: true
      enable_compliance_scan: true
    secrets: inherit
```

## Required GCP Permissions

The service account needs these roles for full governance scanning:

| Role | Purpose |
|------|---------|
| `roles/viewer` | Read project resources |
| `roles/iam.securityReviewer` | Audit IAM bindings |
| `roles/billing.viewer` | Check billing/budgets |
| `roles/logging.viewer` | Audit log configurations |
| `roles/compute.viewer` | Audit firewall rules, instances |
| `roles/storage.admin` | Audit bucket configurations |

## Required Secrets

| Variable | Description |
|----------|-------------|
| `GCP_WORKLOAD_IDENTITY_PROVIDER` | Workload identity provider |
| `GCP_SERVICE_ACCOUNT` | Service account email |

## Adding Custom Policies

Create a new `.rego` file in the `policies/` directory:

```rego
package governance

import future.keywords.contains
import future.keywords.if

deny contains msg if {
    resource := input.resource_changes[_]
    # your condition here
    msg := "Your violation message"
}
```

All `.rego` files in the `policies/` directory are automatically loaded and evaluated against the Terraform plan.
