# Foundation Pipeline

Reusable GitHub Actions workflows and composite actions for pipeline authentication, credential management, semantic versioning, and code quality. This is the GitHub Actions equivalent of the GitLab `foundation-pipeline` template.

## Structure

```
foundation/
├── foundation-pipeline.yml                    ← Main orchestrator workflow
├── semantic-release.yml                       ← Semantic versioning workflow
├── code-quality.yml                           ← Shellcheck + BATS workflow
├── pr-automation.yml                          ← Auto-label, size label, conventional title, stale
├── actions/
│   ├── gcp-secret-manager/action.yml          ← Fetch secrets from GCP Secret Manager
│   ├── gcp-auth/action.yml                    ← GCP auth via Workload Identity
│   ├── artifactory-auth/action.yml            ← Artifactory auth (creds from GSM)
│   ├── consul-auth/action.yml                 ← Consul auth (token from GSM)
│   ├── git-credentials/action.yml             ← Git credential configuration
│   ├── cleanup/action.yml                     ← Credential cleanup
│   ├── common-functions/action.yml            ← Shared bash functions
│   ├── notify/action.yml                      ← Slack/Teams/Email notifications
│   └── cache-strategy/action.yml              ← Dependency caching (Terraform, npm, Docker, Go, pip)
└── README.md
```

## GitLab → GitHub Mapping

| GitLab `!reference` / `extends` | GitHub Composite Action / Workflow |
|----------------------------------|-------------------------------------|
| `.foundation-pipeline::vault-auth-pipeline` | `actions/gcp-secret-manager/` |
| `.foundation-pipeline::google-auth-credentials` | `actions/gcp-auth/` |
| `.foundation-pipeline::artifactory-auth-vault` | `actions/artifactory-auth/` |
| `.foundation-pipeline::consul-auth-vault` | `actions/consul-auth/` |
| `.foundation-pipeline::git-configure-credentials` | `actions/git-credentials/` |
| `.foundation-pipeline::vault-logout-pipeline` | `actions/cleanup/` |
| `.foundation-pipeline::common-functions` | `actions/common-functions/` |
| `.foundation-pipeline::hash-directory` | Included in `common-functions` |
| `.foundation-pipeline::semantic-release` | `semantic-release.yml` |
| `.foundation-pipeline::shellcheck` | `code-quality.yml` → `shellcheck` job |
| `.foundation-pipeline::bats` | `code-quality.yml` → `bats` job |
| `.foundation-pipeline::m365-email-notify` | `actions/notify/` (Slack + Teams + Email) |
| `.cloud-governance` | See `security/cloud-governance/` |
| _(new)_ PR labeling, size, conventional titles | `pr-automation.yml` |
| _(new)_ Dependency caching | `actions/cache-strategy/` |

## Authentication Chain

```
GCP Workload Identity Federation (GitHub OIDC → GCP)
   ├── GCP Secret Manager (fetch application secrets)
   ├── Consul Auth (token stored in GSM → exported as CONSUL_HTTP_TOKEN)
   ├── Artifactory Auth (creds stored in GSM → Helm repo setup)
   └── Credential Cleanup (revoke gcloud tokens, remove temp files)
```

## Usage

### Full foundation pipeline (all auth + quality + release)

```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [main]
  pull_request:

jobs:
  foundation:
    uses: ./.github/workflows/shared-services/foundation/foundation-pipeline.yml
    with:
      gcp_project_id: ${{ vars.GCP_PROJECT_ID }}
      enable_gcp_auth: true
      enable_artifactory_auth: true
      artifactory_url: https://artifactory.example.com
      enable_consul_auth: true
      consul_addr: https://consul.example.com
      secret_names: 'app-secret-key,db-password'
      enable_semantic_release: true
      enable_shellcheck: true
    secrets: inherit
```

### Auth-only (use outputs in downstream jobs)

```yaml
jobs:
  auth:
    uses: ./.github/workflows/shared-services/foundation/foundation-pipeline.yml
    with:
      gcp_project_id: ${{ vars.GCP_PROJECT_ID }}
      enable_semantic_release: false
    secrets: inherit

  deploy:
    needs: [auth]
    runs-on: ubuntu-latest
    steps:
      - run: echo "GCP auth available from auth job outputs"
```

### Individual actions (a la carte)

You can use any composite action independently in your own workflow steps:

```yaml
steps:
  - uses: actions/checkout@v4

  - name: Load common functions
    uses: ./.github/workflows/shared-services/foundation/actions/common-functions
    with:
      github_token: ${{ secrets.GITHUB_TOKEN }}

  - name: GCP auth via Workload Identity
    id: gcp
    uses: ./.github/workflows/shared-services/foundation/actions/gcp-auth
    with:
      workload_identity_provider: ${{ secrets.GCP_WORKLOAD_IDENTITY_PROVIDER }}
      service_account: ${{ secrets.GCP_SERVICE_ACCOUNT }}
      gcp_project_id: ${{ vars.GCP_PROJECT_ID }}

  - name: Fetch secrets from GCP Secret Manager
    uses: ./.github/workflows/shared-services/foundation/actions/gcp-secret-manager
    with:
      gcp_project_id: ${{ vars.GCP_PROJECT_ID }}
      secret_names: 'db-password,api-key'

  - name: Your pipeline steps here
    run: |
      source /tmp/foundation-scripts/common-functions.sh
      require-executables jq curl
      gcloud projects list

  - name: Cleanup
    if: always()
    uses: ./.github/workflows/shared-services/foundation/actions/cleanup
```

## Common Functions

After loading `common-functions`, these are available in any `run` step:

| Function | Description |
|----------|-------------|
| `require-executables <pkg...>` | Install missing packages via apk/apt |
| `sleep-random [min] [max]` | Sleep random seconds (default 5-30) |
| `retry-random <command>` | Retry command with random backoff (TRIES, MIN, MAX) |
| `hash_directory <dir...>` | Compute deterministic hash of directory contents |
| `gh-pr-comment <body>` | Post a comment on the current PR |

## Notifications

Send pipeline alerts via Slack, Teams, or Email:

```yaml
- name: Notify on failure
  if: failure()
  uses: ./.github/workflows/shared-services/foundation/actions/notify
  with:
    channel: slack                           # slack | teams | email | all
    status: failure
    title: 'Deploy Failed'
    slack_webhook_url: ${{ secrets.SLACK_WEBHOOK_URL }}
    mention_on_failure: 'U12345,U67890'      # Slack user IDs to @mention
```

## Caching

Cache dependencies to speed up workflows:

```yaml
- name: Cache Terraform providers
  uses: ./.github/workflows/shared-services/foundation/actions/cache-strategy
  with:
    cache_type: terraform                    # terraform | npm | docker | go | pip | custom
    working_directory: infra
```

Supported types: `terraform`, `npm`, `docker`, `go`, `pip`, `custom`.

## PR Automation

Auto-label, size-label, enforce conventional commit titles, and clean up stale PRs:

```yaml
jobs:
  pr-checks:
    uses: ./.github/workflows/shared-services/foundation/pr-automation.yml
    with:
      enable_auto_label: true
      enable_size_label: true
      enable_conventional_title: true
      enable_stale_check: false
      label_rules: '{"infra": ["infra/**"], "ci": [".github/**"], "docs": ["**/*.md"]}'
    secrets: inherit
```

## Required Secrets / Variables

| Type | Name | Description |
|------|------|-------------|
| **Secret** | `GCP_WORKLOAD_IDENTITY_PROVIDER` | GCP Workload Identity Federation provider |
| **Secret** | `GCP_SERVICE_ACCOUNT` | GCP service account email for impersonation |
| **Variable** | `GCP_PROJECT_ID` | GCP project ID (contains secrets) |
| **GSM Secret** | `artifactory-access-token` | JFrog access token (if Artifactory enabled) |
| **GSM Secret** | `artifactory-username` | Artifactory username (if Artifactory enabled) |
| **GSM Secret** | `consul-token` | Consul ACL token (if Consul enabled) |

## Permissions

The foundation pipeline requires these GitHub Actions permissions:

```yaml
permissions:
  id-token: write      # Required for GCP Workload Identity (OIDC)
  contents: write      # Required for semantic-release to create tags
  issues: write        # Required for semantic-release PR comments
  pull-requests: write # Required for PR feedback
```
