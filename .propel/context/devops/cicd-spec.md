# CI/CD Pipeline Specification

## Project Overview
Security-first CI/CD architecture for the requirement "need to create a secure pipeline". The pipeline is designed to enforce least privilege, mandatory security gates, controlled promotions, and auditable infrastructure deployments.

## Target Configuration
| Attribute | Value |
|-----------|-------|
| CI/CD Platform | GitHub Actions |
| Deployment Target | GCP infrastructure via Terraform |
| Environments | dev, qa, staging, prod |
| Branching Strategy | GitHub Flow with protected main |

## Technology Stack Summary
| Layer | Technology | Build Tool | Test Framework |
|-------|------------|------------|----------------|
| Infrastructure | Terraform | terraform | terraform validate/plan |
| Security | CodeQL, Checkov, GitLeaks, Trivy | GitHub Actions | policy and security gates |

---

## Security Baseline
- CICD-000: All workflows MUST set explicit minimum `permissions` and default to read-only.
- CICD-001: All third-party actions MUST be pinned to full commit SHA.
- CICD-002: Cloud authentication MUST use OIDC (`id-token: write`) and MUST NOT use long-lived keys.
- CICD-003: Deployments to staging/prod MUST run through protected environments with required reviewers.
- CICD-004: Branch protection MUST require status checks for security and plan jobs before merge.

---

## Pipeline Stages

### Stage 1: Build and Validation (CICD-XXX)
- CICD-010: Pipeline MUST run `terraform fmt -check -recursive` and fail on formatting drift.
- CICD-011: Pipeline MUST run `terraform init -backend=false` and `terraform validate`.
- CICD-012: Pipeline MUST publish metadata (commit SHA, actor, timestamp, workflow run id).
- CICD-013: Pipeline MUST stop immediately on validation failure.

### Stage 2: Quality and Policy (CICD-XXX)
- CICD-020: Pipeline MUST lint workflow and IaC definitions.
- CICD-021: Pipeline MUST execute policy-as-code checks (Checkov) in blocking mode.
- CICD-022: Pipeline MUST retain machine-readable reports for audit and triage.

### Stage 3: Security Scanning (CICD-XXX)
- CICD-030: Pipeline MUST run SAST with CodeQL on pull requests and main branch pushes.
- CICD-031: Pipeline MUST run secrets detection with GitLeaks with full git history on protected branches.
- CICD-032: Pipeline MUST run IaC scanning with Checkov.
- CICD-033: Pipeline MUST run container scan (Trivy) when image artifacts exist.
- CICD-034: Pipeline MUST fail on critical/high vulnerabilities and unresolved secret leaks.
- CICD-035: [UNCLEAR] Pipeline MUST define allow-list and suppression process ownership for accepted risks.

### Stage 4: Plan and Test (CICD-XXX)
- CICD-040: Pipeline MUST run `terraform plan` per target environment and store immutable plan artifacts.
- CICD-041: Pipeline MUST execute environment smoke checks after apply for dev and qa.
- CICD-042: Pipeline MUST run post-deployment health checks for staging and prod.
- CICD-043: Pipeline SHOULD estimate cost impact for staging/prod changes.

### Stage 5: Deployment and Promotion (CICD-XXX)
- CICD-050: dev/qa deployments MUST be automated after passing security gates.
- CICD-051: staging deployment MUST require one human approval.
- CICD-052: prod deployment MUST require two human approvals.
- CICD-053: Deployments MUST use environment-scoped secrets only.
- CICD-054: Deployments MUST use concurrency control to prevent overlapping applies per environment.

### Stage 6: Rollback and Incident Controls (CICD-XXX)
- CICD-060: Rollback MUST trigger on failed smoke tests, health check failures, or security gate bypass attempts.
- CICD-061: Pipeline MUST keep prior plan and state references for rapid rollback execution.
- CICD-062: Pipeline MUST notify on-call responders and create incident tickets for failed prod deploys.

---

## Environment Pipeline Matrix

| Stage | dev | qa | staging | prod |
|-------|-----|----|---------|------|
| Validate (fmt/init/validate) | Auto | Auto | Auto | Auto |
| Security Scan | Auto | Auto | Auto | Auto |
| Terraform Plan | Auto | Auto | Auto | Auto |
| Approval Gate | No | No | Yes (1 reviewer) | Yes (2 reviewers) |
| Terraform Apply | Auto | Auto | After approval | After approval |
| Post-deploy Health | Basic | Basic | Full | Full |

---

## Security Gates Configuration

| Gate | Tool | Threshold | Blocking | Environments |
|------|------|-----------|----------|--------------|
| SAST | CodeQL | 0 Critical, 0 High | Yes | All |
| IaC Security | Checkov | 0 Critical | Yes | All |
| Secrets | GitLeaks | 0 findings | Yes | All |
| Container | Trivy | 0 Critical | Yes | Applicable workloads |
| Workflow Integrity | Action pinning check | 100% pinned SHAs | Yes | All |

---

## Deployment Strategy

| Environment | Strategy | Approval | Rollback | Timeout |
|-------------|----------|----------|----------|---------|
| dev | Rolling apply | None | Manual | N/A |
| qa | Rolling apply | None | Manual | N/A |
| staging | Blue/green equivalent by controlled apply and validation | 1 reviewer | Automated | 24h |
| prod | Progressive promotion (canary-style infra changes where possible) | 2 reviewers | Automated | 72h |

---

## Notification Strategy

| Event | Recipients | Channel | Priority |
|-------|------------|---------|----------|
| Validation failure | Commit author, platform team | GitHub notifications + chat | High |
| Security gate failure | Security team, platform team | Chat + email | Critical |
| Deployment approved/started | Operations | Chat | Info |
| Rollback triggered | On-call, incident commander | Pager + chat | Critical |
| Approval pending | Required reviewers | GitHub environment notifications | High |

---

## Secrets Configuration
- Use GitHub Environment secrets and repository secrets for non-runtime values.
- Use OIDC trust with GCP workload identity federation for deployment authentication.
- Do not store service-account JSON keys in repository or long-lived CI variables.
- Rotate security scanning tokens on a 90-day schedule.
- Restrict secret visibility by environment and repository permissions.

---

## Requirement Traceability

| CICD ID | Description | Source Requirement |
|---------|-------------|-------------------|
| CICD-000 | Least-privilege workflow permissions | Security-first pipeline requirement |
| CICD-002 | OIDC-only cloud auth | Security-first pipeline requirement |
| CICD-034 | Blocking vulnerability thresholds | Security-first pipeline requirement |
| CICD-052 | Two-person production approval | Secure production controls |

---

## Human Review Checklist
- [ ] Confirm GitHub environment protection rules and required reviewers are configured.
- [ ] Confirm OIDC trust relationship is configured for GCP workload identity federation.
- [ ] Confirm branch protection requires CI, security, and plan checks.
- [ ] Confirm all third-party workflow actions are SHA pinned.
- [ ] Resolve or accept all [UNCLEAR] items with named ownership.
