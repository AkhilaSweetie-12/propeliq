# Secret Rotation

Scheduled workflow for auditing and rotating secrets across GCP Service Account keys and GCP Secret Manager.

## Structure

```
secret-rotation/
├── secret-rotation.yml   ← Main rotation/audit workflow
└── README.md
```

## Usage

### Scheduled audit (recommended)

```yaml
name: Weekly Secret Rotation Audit

on:
  schedule:
    - cron: '0 8 * * 1'   # Every Monday at 8 AM UTC
  workflow_dispatch:

jobs:
  rotation-audit:
    uses: ./.github/workflows/shared-services/security/secret-rotation/secret-rotation.yml
    with:
      gcp_project_id: ${{ vars.GCP_PROJECT_ID }}
      rotation_targets: 'sa-keys,secrets'
      sa_key_max_age_days: 90
      dry_run: true
      notify_channel: slack
      slack_webhook_url: ${{ secrets.SLACK_WEBHOOK_URL }}
    secrets: inherit
```

### Active rotation (auto-rotate expired keys)

```yaml
jobs:
  rotate:
    uses: ./.github/workflows/shared-services/security/secret-rotation/secret-rotation.yml
    with:
      gcp_project_id: ${{ vars.GCP_PROJECT_ID }}
      rotation_targets: 'sa-keys'
      sa_key_max_age_days: 90
      dry_run: false          # Actually rotate
    secrets: inherit
```

## Jobs

| Job | Description |
|-----|-------------|
| **audit-sa-keys** | Lists all user-managed SA keys, flags expired ones, optionally rotates |
| **audit-secrets** | Audits Secret Manager entries for version count, rotation policy |
| **notify** | Sends summary via Slack/Teams using the foundation notify action |

## Inputs

| Input | Default | Description |
|-------|---------|-------------|
| `rotation_targets` | `sa-keys,secrets` | Comma-separated: `sa-keys`, `secrets` |
| `sa_key_max_age_days` | `90` | Days before a SA key is flagged as expired |
| `dry_run` | `true` | Audit only; set `false` to rotate expired keys |
| `notify_channel` | `none` | `slack`, `teams`, or `none` |

## Required Secrets

| Secret | Description |
|--------|-------------|
| `GCP_WORKLOAD_IDENTITY_PROVIDER` | GCP Workload Identity provider |
| `GCP_SERVICE_ACCOUNT` | GCP service account email |
| `SLACK_WEBHOOK_URL` | Slack webhook (if notify_channel=slack) |
| `TEAMS_WEBHOOK_URL` | Teams webhook (if notify_channel=teams) |
