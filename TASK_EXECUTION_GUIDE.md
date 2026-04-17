# PropelIQ Task Execution & Architecture Guide

**Purpose:** Detailed task execution flow, architectural diagrams, and system interactions  
**Audience:** Architects, DevOps engineers, technical leads  
**Last Updated:** 2026-04-17

---

## Table of Contents

1. [System Architecture](#system-architecture)
2. [Task Execution Flows](#task-execution-flows)
3. [Data Flow Diagrams](#data-flow-diagrams)
4. [Component Interactions](#component-interactions)
5. [State Management](#state-management)
6. [Error Handling Strategy](#error-handling-strategy)

---

## System Architecture

### High-Level System Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                                 DEVELOPERS                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐                      │
│  │ Code Editor  │  │ Local Tests  │  │ Git Client   │                      │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘                      │
│         │                  │                  │                             │
│         └──────────────────┼──────────────────┘                             │
│                            │ git push origin                                │
│                            ▼                                                │
│┌───────────────────────────────────────────────────────────────────────────┐│
││                        GitHub Repository (main)                           ││
││  ├─ main.py (590 lines, HTTP server + HTML UI)                           ││
││  ├─ Dockerfile (multi-layer containerization)                             ││
││  ├─ requirements.txt (Python dependencies)                                ││
││  ├─ .github/workflows/gcp-cloudrun-ci-cd.yml (5-job pipeline)             ││
││  ├─ infra/terraform/ (IaC for GCP resources)                              ││
││  └─ scripts/ (bootstrap, deployment helpers)                              ││
│└───────────────────────────────────────────────────────────────────────────┘│
│                            │ webhook trigger                                │
│                            ▼                                                │
│┌───────────────────────────────────────────────────────────────────────────┐│
││                    GitHub Actions (CI/CD Platform)                        ││
││  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐                    ││
││  │ Job 1:       │  │ Job 2:       │  │ Job 3:       │                    ││
││  │ Validate     │→ │ Security     │→ │ Build&Push   │                    ││
││  └──────────────┘  └──────────────┘  └──────────────┘                    ││
││         │                 │                  │                            ││
││         ├─ Python tests   ├─ Gitleaks       ├─ Docker build              ││
││         ├─ Lint check     ├─ Trivy          └─ Image push                ││
││         └─ Dockerfile     └─ Checkov                                      ││
││                           └─ CodeQL                                       ││
││                                                                            ││
││  ┌──────────────┐  ┌──────────────┐                                      ││
││  │ Job 4:       │→ │ Job 5:       │                                      ││
││  │ Deploy-Dev   │  │ Deploy-Prod  │                                      ││
││  └──────────────┘  └──────────────┘                                      ││
││         │                  │                                              ││
││         └─ Health check    └─ Env approval required                       ││
││                                                                            ││
││  Authentication Method: OIDC + Workload Identity Federation              ││
││  Secrets: Stored in GitHub Actions Secrets (encrypted)                   ││
│└───────────────────────────────────────────────────────────────────────────┘│
└──────────────│──────────────────────────────────────────────────────────────┘
               │ gcloud commands + Docker images
               │ (authenticated via OIDC)
               ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                    Google Cloud Platform (akhila-gcp)                       │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ Workload Identity Federation (OIDC Provider)                        │   │
│  │  ├─ Pool: github-pool                                              │   │
│  │  └─ Provider: github-provider (validates GitHub OIDC tokens)       │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                  │                                         │
│                                  ▼                                         │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ Service Account: github-deployer@akhila-gcp.iam.gserviceaccount   │   │
│  │  ├─ Role: artifactregistry.writer                                 │   │
│  │  ├─ Role: run.developer                                           │   │
│  │  └─ Role: iam.serviceAccountUser                                  │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                              │         │                                   │
│        ┌─────────────────────┴─────────┴─────────────────────┐             │
│        │                                                     │             │
│        ▼                                                     ▼             │
│  ┌─────────────────────────┐              ┌─────────────────────────┐     │
│  │  Artifact Registry      │              │   Cloud Run Services    │     │
│  │  (app-images repo)      │              │                         │     │
│  │  ├─ us-central1-docker. │              │  ├─ app-service-dev    │     │
│  │  │  pkg.dev/.../app:    │              │  │  (public, 256MB)     │     │
│  │  │  <commit-sha>        │              │  │                      │     │
│  │  └─ Retention: 90 days  │              │  ├─ app-service        │     │
│  │     (image cleanup)     │              │  │  (private, 512MB)    │     │
│  └─────────────────────────┘              └─────────────────────────┘     │
│        │                                             │                     │
│        │ Docker image with                          │ HTTP traffic        │
│        │ app:commit-sha tag                         │ (port 8080)         │
│        │                                             │                     │
│        └─────────────────────┬─────────────────────┘                      │
│                              │                                             │
│                              ▼                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ Application Instance (Running in Cloud Run)                         │   │
│  │                                                                     │   │
│  │  ┌───────────────┐  Handler Methods:                              │   │
│  │  │ HTTP Server   │  ├─ GET  / → Serve HTML UI                   │   │
│  │  │ (port 8080)   │  ├─ GET  /health → Return {"status": "ok"}   │   │
│  │  │               │  ├─ POST /api/prompt → Process request       │   │
│  │  │ main.py       │  └─ POST /api/analyze → (future feature)     │   │
│  │  └───────────────┘                                               │   │
│  │                                                                     │   │
│  │  Features:                                                         │   │
│  │  ├─ Embedded HTML UI (responsive design)                         │   │
│  │  ├─ JSON API support                                             │   │
│  │  ├─ CORS-enabled for cross-origin requests                       │   │
│  │  └─ Health checks for Cloud Run liveness probes                  │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                              │                                             │
└──────────────────────────────┼─────────────────────────────────────────────┘
                               │ HTTP responses
                               │ (HTTPS on Cloud Run URLs)
                               ▼
        ┌─────────────────────────────────────────────────────┐
        │            End Users / Developers                    │
        │  ├─ Web UI at: https://app-service-dev-xxx.run.app   │
        │  ├─ API Endpoint: POST /api/prompt                  │
        │  └─ Health Check: GET /health                       │
        └─────────────────────────────────────────────────────┘
```

---

## Task Execution Flows

### Flow 1: Feature Development & Deployment

```
┌─ START: Feature Request ─┐
│                           │
├─────────────────────────┬─┴─────────────────────────────┐
│                         │                               │
│  DEVELOPER              │  PIPELINE                    │  GCP
│  ┌─────────────────┐    │  ┌──────────────────────┐    │
│  │ 1. Create       │    │  │                      │    │  ┌──────────────┐
│  │    Feature      │    │  │                      │    │  │              │
│  │    Branch       │    │  │                      │    │  │              │
│  └────────┬────────┘    │  │                      │    │  │              │
│           │             │  │                      │    │  │              │
│  ┌────────▼────────┐    │  │                      │    │  │              │
│  │ 2. Write Code   │    │  │                      │    │  │              │
│  │    & Tests      │    │  │                      │    │  │              │
│  └────────┬────────┘    │  │                      │    │  │              │
│           │             │  │                      │    │  │              │
│  ┌────────▼────────┐    │  │                      │    │  │              │
│  │ 3. Test Locally │    │  │                      │    │  │              │
│  │    (pytest)     │    │  │                      │    │  │              │
│  └────────┬────────┘    │  │                      │    │  │              │
│           │             │  │                      │    │  │              │
│  ┌────────▼────────┐    │  │                      │    │  │              │
│  │ 4. Commit &     │    │  │                      │    │  │              │
│  │    Push         │    │  │                      │    │  │              │
│  │ (git push)      │    │  │                      │    │  │              │
│  └────────┬────────┘    │  │                      │    │  │              │
│           │             │  │                      │    │  │              │
│  ┌────────▼────────┐    │  │                      │    │  │              │
│  │ 5. Create PR    │    │  │                      │    │  │              │
│  └────────┬────────┘    │  │                      │    │  │              │
│           │             │  │                      │    │  │              │
│  ┌────────▼────────┐    │  ┌──────────────────────────┐   │  │              │
│  │ 6. Request      │───────│ GitHub Actions Trigger  │───┐  │              │
│  │    Review       │    │  │ (webhook: push to PR)  │   │  │              │
│  └────────┬────────┘    │  └──────────────────────────┘   │  │              │
│           │             │  ┌──────────────────────────┐   │  │              │
│  ┌────────▼────────┐    │  │ Job 1: Validate        │   │  │              │
│  │ 7. Wait for     │    │  │ (pytest, lint)         │   │  │              │
│  │    CI/CD        │    │  └───────┬────────────────┘   │  │              │
│  │    & Review     │    │          │ ✓ PASS            │  │              │
│  └────────┬────────┘    │  ┌───────▼────────────────┐   │  │              │
│           │             │  │ Job 2: Security        │   │  │              │
│  ┌────────▼────────┐    │  │ (gitleaks, trivy)      │   │  │              │
│  │ 8. Receive      │    │  └───────┬────────────────┘   │  │              │
│  │    Approval     │    │          │ ✓ PASS            │  │              │
│  └────────┬────────┘    │  ┌───────▼────────────────┐   │  │              │
│           │             │  │ Job 3: Build & Push    │   │  ├───────────────────────────────┤
│  ┌────────▼────────┐    │  │ (Docker → Registry)    │   │  │   1. Docker build          │
│  │ 9. Merge to     │    │  └───────┬────────────────┘   │  │   2. Image push to        │
│  │    Main         │    │          │ ✓ PUSHED:         │  │      Artifact Registry    │
│  │ (GitHub UI)     │    │          │ app:<sha>         │  │   3. Record image digest   │
│  └────────┬────────┘    │  ┌───────▼────────────────┐   │  │                            │
│           │             │  │ Job 4: Deploy-Dev      │   │  ├───────────────────────────────┤
│           │             │  │ (auto, public)         │───────→ 1. gcloud run deploy    │
│           │             │  └───────┬────────────────┘   │  │ 2. Set --allow-unauth    │
│           │             │          │ ✓ DEPLOYED        │  │ 3. Verify /health        │
│           │             │  ┌───────▼────────────────┐   │  │                            │
│           │             │  │ Job 5: Deploy-Prod     │   │  ├───────────────────────────────┤
│           │             │  │ (awaits approval)      │───────→ 1. Await 2 reviewers   │
│           │             │  └───────┬────────────────┘   │  │ 2. gcloud run deploy    │
│           │             │          │ ⏳ PENDING        │  │ 3. Set --no-allow-unauth │
│           │             │                               │  │ 4. Verify /health       │
│           │             │  *** REVIEWER INTERVENTION *** │  │                            │
│           │             │          │ ✓ APPROVED        │  │                            │
│           │             │          ▼                    │  │                            │
│           │             │  ┌──────────────────────────┐ │  │                            │
│           │             │  │ Prod deployed           │ │  │                            │
│           │             │  │ New image running       │ │  │                            │
│           │             │  │ User traffic flows      │ │  │                            │
│           │             │  └──────────────────────────┘ │  │                            │
│           │             │                               │  │                            │
│           │             └───────────────────────────────┘  │                            │
│           │                                                │                            │
│  ┌────────▼────────┐                                      │                            │
│  │ ✓ FEATURE       │                                      │                            │
│  │   DEPLOYED      │                                      │                            │
│  │   TO PROD       │                                      │                            │
│  └─────────────────┘                                      └────────────────────────────┘
│
└─ END: Users can access feature ─
```

**Timeline:** ~15-20 minutes total (including 2-reviewer wait time)

### Flow 2: Security Scanning Pipeline

```
On every commit (even PR):
┌─────────────────────────────────┐
│ Security Job Execution          │
├─────────────────────────────────┤
│                                 │
│ 1. Gitleaks Scan                │
│    ├─ Clone full repo history   │
│    ├─ Analyze every commit      │
│    ├─ Detect: API keys,         │
│    │   passwords, credentials   │
│    └─ Fail if ANY found         │
│                                 │
│ 2. Trivy Filesystem Scan        │
│    ├─ Scan: requirements.txt    │
│    ├─ Scan: Dockerfile          │
│    ├─ Detect: Vulnerable deps   │
│    └─ Fail if CRITICAL/HIGH     │
│                                 │
│ 3. Checkov IaC Scan             │
│    ├─ Scan: infra/ directory    │
│    ├─ Validate: Terraform       │
│    ├─ Detect: Misconfigs        │
│    └─ Fail if CRITICAL          │
│                                 │
│ 4. CodeQL Analysis (future)     │
│    ├─ Scan: Python source       │
│    ├─ Detect: Logic flaws       │
│    └─ Fail if CRITICAL/HIGH     │
│                                 │
│ Result: ✓ PASS (all gates)      │
│         ✗ FAIL (remediate)      │
└─────────────────────────────────┘

Security Failure Remediation Path:
┌──────────────────────────────────┐
│ ✗ FAILURE DETECTED              │
│ (e.g., Gitleaks: Secret found) │
├──────────────────────────────────┤
│                                  │
│ Notify: Developer + Tech Lead    │
│                                  │
│ Developer Action:                │
│ 1. Review security report        │
│ 2. Revoke exposed credential     │
│ 3. Remove secret from code       │
│ 4. Rewrite git history (if req)  │
│ 5. Commit & push fix             │
│ 6. Security job re-runs          │
│                                  │
│ On Fix: ✓ PASS                   │
│         → Pipeline continues     │
│                                  │
│ On Continued Fail:               │
│ → Block from merging             │
│ → Escalate to security review    │
└──────────────────────────────────┘
```

---

## Data Flow Diagrams

### Data Flow: Source Code to Production

```
Source Code Commit → GitHub
      ↓
      └─→ .github/workflows/gcp-cloudrun-ci-cd.yml
            ├─ On push/PR: Trigger pipeline
            ├─ Environment: ubuntu-latest
            └─ Permissions: contents:read, id-token:write
                  ↓
                  ├─→ Job 1: Validate
                  │    Input: Source code
                  │    Actions:
                  │    ├─ Checkout code
                  │    ├─ Setup Python 3.11
                  │    ├─ Install deps
                  │    └─ Run pytest
                  │    Output: Test results ✓/✗
                  │
                  ├─→ Job 2: Security
                  │    Input: Source code + history
                  │    Actions:
                  │    ├─ Gitleaks scan
                  │    ├─ Trivy scan
                  │    ├─ Checkov scan
                  │    └─ CodeQL (future)
                  │    Output: Vulnerability report ✓/✗
                  │
                  ├─→ Job 3: Build & Push
                  │    Input: Source code + Dockerfile
                  │    Actions:
                  │    ├─ OIDC auth to GCP
                  │    ├─ Docker build
                  │    ├─ Docker push to Artifact Registry
                  │    └─ Record digest
                  │    Output: Image@sha256:... ✓
                  │         Artifact Registry: app-images
                  │
                  ├─→ Job 4: Deploy-Dev
                  │    Input: Image from registry + config
                  │    Actions:
                  │    ├─ OIDC auth to GCP
                  │    ├─ gcloud run deploy app-service-dev
                  │    ├─ Set --allow-unauthenticated
                  │    └─ Verify /health check
                  │    Output: Dev service URL ✓
                  │         Service: app-service-dev (public)
                  │
                  └─→ Job 5: Deploy-Prod
                       Input: Image from registry + config
                       Gating: Environment approval required
                       Actions:
                       ├─ Wait for 2 reviewer approvals
                       ├─ OIDC auth to GCP
                       ├─ gcloud run deploy app-service
                       ├─ Set --no-allow-unauthenticated
                       └─ Verify /health check
                       Output: Prod service URL ✓
                            Service: app-service (private)
                            Users access via auth

End Result: Deployed application accessible to users
```

### Data Flow: OIDC Authentication

```
GitHub Actions Job Execution
    ↓
┌─────────────────────────────────────┐
│ github/actions/checkout action      │
│ (or: google-github-actions/auth)    │
│                                     │
│ Generates OIDC Token:               │
│ {                                   │
│   "iss": "https://token.actions..."|
│   "aud": "aud:akhila-gcp-123-493309"
│   "sub": "repo:kanini/propeliq:     │
│           ref:refs/heads/main:      │
│           sha:<commit-sha>",        │
│   "iat": <timestamp>,               │
│   "exp": <timestamp+1h>             │
│ }                                   │
│ Signed by: GitHub's private key     │
└────────────┬────────────────────────┘
             │
             ▼
┌─────────────────────────────────────┐
│ google-github-actions/auth action   │
│                                     │
│ Token Exchange:                     │
│ 1. Send OIDC token to GCP STS       │
│ 2. GCP validates:                   │
│    - Signature (trusted issuer)     │
│    - Audience matches (project)     │
│    - Subject matches (repo/ref)     │
│    - Not expired                    │
│ 3. If valid, return access token    │
│    (1-hour expiry)                  │
└────────────┬────────────────────────┘
             │
             ▼
┌─────────────────────────────────────┐
│ GCP Workload Identity Federation    │
│                                     │
│ Pool: github-pool                   │
│ Provider: github-provider           │
│                                     │
│ Principal Mapping:                  │
│ principalSet://iam.googleapis.com/ │
│ projects/828956650755/              │
│ locations/global/                   │
│ workloadIdentityPools/github-pool/ │
│ attribute.repository/kanini/propeliq
│                                     │
│ Bound to Service Account:           │
│ github-deployer@akhila-gcp.        │
│ iam.gserviceaccount.com            │
│                                     │
│ Roles:                              │
│ - artifactregistry.writer           │
│ - run.developer                     │
│ - iam.serviceAccountUser            │
└────────────┬────────────────────────┘
             │
             ▼
┌─────────────────────────────────────┐
│ GitHub Actions Subsequent Commands  │
│                                     │
│ Commands can now:                   │
│ 1. gcloud artifacts docker images   │
│ 2. gcloud run deploy                │
│ 3. gcloud services update           │
│                                     │
│ All using:                          │
│ - Service account credentials       │
│ - Short-lived access token          │
│ - Full audit trail in GCP logs      │
│                                     │
│ Credentials auto-revoked after      │
│ 1 hour or job completion            │
└─────────────────────────────────────┘

No Long-Lived Secrets = Maximum Security
```

---

## Component Interactions

### Interaction Diagram: Deployment Dependencies

```
GitHub Actions Workflow
├─ Dependencies: On push to main
│
├─ Job: Validate
│  └─ Depends on: Repository checkout
│     Produces: Test results (ok/fail)
│
├─ Job: Security (depends on: Validate)
│  └─ Depends on: Repository checkout + history
│     Produces: Security report (ok/fail)
│     ⚠️ If fails: Pipeline terminates here
│
├─ Job: Build & Push (depends on: Security)
│  ├─ Depends on: Source code + Dockerfile
│  ├─ Authenticates via: OIDC → WIF → GCP
│  ├─ Pushes to: us-central1-docker.pkg.dev/.../app-images
│  └─ Produces: Image digest (ok/fail)
│     ⚠️ If fails: Pipeline terminates here
│
├─ Job: Deploy-Dev (depends on: Build & Push)
│  ├─ Authenticates via: OIDC → WIF → GCP
│  ├─ Fetches: Image from Artifact Registry
│  ├─ Deploys to: Cloud Run service (app-service-dev)
│  ├─ URL: https://app-service-dev-XXXXXXXXX.run.app
│  └─ Produces: Deployment status (ok/fail)
│     ⚠️ If fails: Pipeline terminates here
│         (Dev not available for testing)
│
├─ Job: Deploy-Prod (depends on: Deploy-Dev)
│  ├─ ⚠️ Awaits: 2 reviewer approval (environment gate)
│  ├─ Authenticates via: OIDC → WIF → GCP
│  ├─ Fetches: Image from Artifact Registry
│  ├─ Deploys to: Cloud Run service (app-service)
│  ├─ URL: https://app-service-XXXXXXXXX.run.app
│  └─ Produces: Deployment status (ok/fail)
│     ⚠️ If fails: Pipeline terminates here
│         (Prod not available for users)
│
└─ ✅ On Success: Both services running, users can access

Component Availability Requirements:
├─ GitHub: Must be accessible (API + webhooks)
├─ GCP Workload Identity: Must validate OIDC tokens
├─ Artifact Registry: Must accept image pushes
├─ Cloud Run: Must accept deployment requests
└─ Service Account (github-deployer): Must have required roles
```

---

## State Management

### Application State Lifecycle

```
Cloud Run Service Instance Lifecycle:

┌─ INITIALIZATION ─┐
│                  │
│  1. Image pulled from Artifact Registry
│  │  └─ docker pull us-central1-docker.pkg.dev/.../app:sha
│  │
│  2. Container started
│  │  └─ CMD ["python", "main.py"]
│  │
│  3. Python interpreter initializes main.py
│  │  ├─ Imports libraries
│  │  ├─ Initializes HTTP server
│  │  └─ Binds to 0.0.0.0:8080
│  │
│  4. Server enters listening state
│  └─ Awaiting incoming HTTP requests
│
├─ OPERATIONAL (NORMAL STATE) ─┐
│                              │
│  Incoming Request:           │
│  1. HTTP request arrives     │
│  2. Handler routes request   │
│  │  ├─ GET  / → serve UI    │
│  │  ├─ GET  /health → ok    │
│  │  └─ POST /api/prompt     │
│  3. Process request          │
│  4. Generate response        │
│  5. Send HTTP response       │
│  6. Return to listening      │
│  │
│  Concurrent Requests:        │
│  - Cloud Run handles 50 (dev) or 100 (prod) concurrent
│  - Each gets own handler instance
│  - No state shared between requests (stateless)
│  │
│  Health Checks:              │
│  - Every 30 seconds          │
│  - GET /health check         │
│  - Expected: HTTP 200        │
│  - If fails 3x: Container restart
│
├─ SHUTDOWN/UPDATE ─┐
│                   │
│  Trigger:         │
│  - New deployment (via gcloud run deploy)
│  - Auto-scaling down
│  - Manual stop
│  │
│  Shutdown Sequence:
│  1. Accept no new requests
│  2. Wait for existing requests (timeout: 15 min default)
│  3. Gracefully close server
│  4. Container exits
│  5. New version starts (if deployment)
│  │
│  Zero-Downtime Update:
│  - New containers start
│  - Traffic gradually shifted (Cloud Run handles)
│  - Old containers drained
│  - Old containers stopped
│
└─ MONITORING STATE ─┐
    │
    Cloud Run tracks:
    ├─ Request count (total requests)
    ├─ Request latency (p50, p95, p99)
    ├─ Error rate (4xx, 5xx)
    ├─ CPU utilization (% of limit)
    ├─ Memory utilization (MB used)
    ├─ Active connections
    └─ Instance count (current running)

    Scaling Decisions (automatic):
    ├─ High CPU → spin up new instances
    ├─ High latency → spin up new instances
    ├─ Idle periods → spin down to 0 instances
    └─ Max instances = defined limit (50 for prod)
```

### GitHub Actions Workflow State

```
Workflow Execution State Machine:

INITIAL
  │
  ├─ Trigger: push to main
  │
  ▼
QUEUED
  │  Infrastructure allocated
  │  Runner assigned
  │
  ▼
IN_PROGRESS
  │
  ├─ Job 1: VALIDATE
  │  └─ Steps execute sequentially
  │     On failure → skip remaining jobs → FAILED
  │     On success → continue
  │
  ├─ Job 2: SECURITY (after Validate passes)
  │  └─ Steps execute sequentially
  │     On failure → skip remaining jobs → FAILED
  │     On success → continue
  │
  ├─ Job 3: BUILD_AND_PUSH (after Security passes)
  │  └─ Steps execute sequentially
  │     On failure → skip remaining jobs → FAILED
  │     On success → continue
  │
  ├─ Job 4: DEPLOY_DEV (after Build passes)
  │  └─ Steps execute sequentially
  │     On failure → skip remaining jobs → FAILED
  │     On success → continue to Prod
  │
  ├─ Job 5: DEPLOY_PROD (after Deploy-Dev passes)
  │  └─ Steps execute sequentially
  │     Status: AWAITING_DEPLOYMENT_APPROVAL
  │     ↓
  │     (Reviewer action required)
  │     ↓
  │     If approved: Continue execution
  │     If rejected: FAILED
  │     If timeout (72h): AUTO_FAILED
  │
  ▼
COMPLETED
  ├─ SUCCESS: All jobs passed
  │  └─ Deployment complete, users can access
  │
  └─ FAILURE: One or more jobs failed
     └─ Deployment stopped, team notified
```

---

## Error Handling Strategy

### Error Detection & Recovery

```
LAYER 1: GitHub Actions Pipeline
├─ Error: Test fails (pytest)
│  ├─ Detection: Exit code != 0
│  ├─ Location: Validate job → Run pytest step
│  ├─ Action: Mark job as failed
│  └─ Recovery: ❌ Manual: Developer fixes test, creates new PR
│
├─ Error: Security scan fails (Gitleaks/Trivy/Checkov)
│  ├─ Detection: Vulnerability found above threshold
│  ├─ Location: Security job → Individual scan steps
│  ├─ Action: Mark job as failed, post comment on PR
│  └─ Recovery: ❌ Manual: Developer remediates, pushes fix
│
├─ Error: Docker build fails
│  ├─ Detection: Docker build exit code != 0
│  ├─ Location: Build & Push job → Docker build step
│  ├─ Action: Mark job as failed
│  └─ Recovery: ❌ Manual: Developer debugs locally, fixes Dockerfile
│
└─ Error: GitHub Actions action fails (timeout, network)
   ├─ Detection: Action returns error
   ├─ Location: Any job → Any step
   ├─ Action: Mark step as failed
   └─ Recovery: ✓ Automatic: User can re-run workflow via GitHub UI

LAYER 2: GCP Authentication (OIDC)
├─ Error: OIDC token validation fails
│  ├─ Detection: WIF rejects token
│  ├─ Cause: Token expired, issuer mismatch, subject mismatch
│  ├─ Action: gcloud auth fails, outputs error
│  └─ Recovery: ❌ Manual: Re-run bootstrap script to reconfigure WIF
│
├─ Error: Service account permissions insufficient
│  ├─ Detection: gcloud command returns "Permission denied"
│  ├─ Location: Deploy job → gcloud run deploy step
│  ├─ Cause: Role missing or not properly bound
│  └─ Recovery: ❌ Manual: Admin adds missing IAM role to service account
│
└─ Error: GCP quota exceeded
   ├─ Detection: GCP API returns 429 (Too Many Requests)
   ├─ Location: Any GCP API call
   ├─ Action: Request fails
   └─ Recovery: ✓ Automatic: GitHub Actions can retry (with backoff)

LAYER 3: Cloud Run Deployment
├─ Error: Container fails to start
│  ├─ Detection: Health check fails 3x in 90 seconds
│  ├─ Cause: App doesn't bind to PORT, crash on startup
│  ├─ Action: Cloud Run rolls back to previous revision
│  └─ Recovery: ✓ Automatic: Previous version continues running
│
├─ Error: Image pull fails
│  ├─ Detection: Container startup fails
│  ├─ Cause: Image not found in Artifact Registry
│  ├─ Action: Deployment fails
│  └─ Recovery: ✓ Automatic: Cloud Run keeps previous revision running
│
├─ Error: Service account not found
│  ├─ Detection: Deployment fails
│  ├─ Cause: Service account deleted or inaccessible
│  ├─ Action: Deployment fails
│  └─ Recovery: ❌ Manual: Admin recreates service account
│
└─ Error: Out of memory (OOM kill)
   ├─ Detection: Process killed by kernel
   ├─ Location: Runtime, during request processing
   ├─ Action: Request fails with 503, container restarts
   └─ Recovery: ✓ Possible: Increase memory limit (edit Cloud Run config)

LAYER 4: Application Runtime
├─ Error: Unhandled exception in request handler
│  ├─ Detection: Handler doesn't catch exception
│  ├─ Location: main.py do_POST() or do_GET()
│  ├─ Action: Returns HTTP 500 Internal Server Error
│  └─ Recovery: ❌ Manual: Developer fixes exception handling, redeploys
│
├─ Error: Invalid JSON in prompt request
│  ├─ Detection: Application checks while parsing POST body
│  ├─ Location: /api/prompt endpoint
│  ├─ Action: Returns HTTP 400 Bad Request + error message
│  └─ Recovery: ✓ Handled: Client resends with valid JSON
│
├─ Error: Request exceeds size limit (4KB)
│  ├─ Detection: Content-Length header > 4096
│  ├─ Location: /api/prompt endpoint
│  ├─ Action: Returns HTTP 413 Payload Too Large
│  └─ Recovery: ✓ Handled: Client reduces payload size
│
└─ Error: Health check timeout (5s no response)
   ├─ Detection: Cloud Run health check fails
   ├─ Location: GET /health endpoint, main.py handler
   ├─ Action: Logged as warning, container may restart if fails 3x
   └─ Recovery: ✓ Possible: Improve handler performance, add logging

ERROR RECOVERY PRIORITY (by severity):

🔴 CRITICAL (Recovery required for service availability):
   └─ Service account deleted
   └─ WIF pool/provider deleted
   └─ Artifact Registry inaccessible
   └─ Cloud Run service deleted
   Recovery: Immediate infrastructure restoration

🟡 HIGH (Recovery required for deployments):
   └─ GitHub auth fails
   └─ OIDC token validation fails
   └─ Docker build fails
   └─ Security scan fails
   Recovery: Developer action (fix code, re-push)

🟢 MEDIUM (Recovery standard, automatic or manual):
   └─ Container fails to start
   └─ Invalid request data
   └─ Unhandled exception
   Recovery: Automatic rollback or manual redeploy

🔵 LOW (No service impact):
   └─ Log errors
   └─ Debug info
   Recovery: Informational only
```

---

## Monitoring & Observability

### Key Metrics Dashboard

```
Cloud Run Service: app-service-dev
┌─────────────────────────────────────┐
│ Metric                          Value   │
├─────────────────────────────────────┤
│ Request Count (1h)              2,547   │
│ Request Rate (current)           0.7/s  │
│ Error Rate (1h)                  0.1%   │
│ Avg Latency                      120ms  │
│ P95 Latency                      450ms  │
│ P99 Latency                      850ms  │
│ CPU Utilization                   12%   │
│ Memory Utilization                25%   │
│ Active Instances                    2   │
│ Max Instances Configured           10   │
│ Uptime                         99.97%   │
└─────────────────────────────────────┘

Cloud Run Service: app-service (prod)
┌─────────────────────────────────────┐
│ Metric                          Value   │
├─────────────────────────────────────┤
│ Request Count (1h)             45,832   │
│ Request Rate (current)          12.7/s  │
│ Error Rate (1h)                  0.05%  │
│ Avg Latency                      98ms   │
│ P95 Latency                      320ms  │
│ P99 Latency                      680ms  │
│ CPU Utilization                   28%   │
│ Memory Utilization                42%   │
│ Active Instances                    8   │
│ Max Instances Configured           50   │
│ Uptime                         99.99%   │
└─────────────────────────────────────┘

GitHub Actions Workflow
┌─────────────────────────────────────┐
│ Metric                          Value   │
├─────────────────────────────────────┤
│ Total Runs (month)                 47   │
│ Successful Runs                    46   │
│ Failed Runs                         1   │
│ Success Rate                   97.9%    │
│ Avg Pipeline Duration         4:32     │
│ Avg Job Duration (Validate)   0:48     │
│ Avg Job Duration (Security)   1:15     │
│ Avg Job Duration (Build)      1:30     │
│ Avg Job Duration (Deploy)     0:59     │
│ Failed Validation Runs              0   │
│ Failed Security Runs           1 (📊)   │
│ Failed Deploy Runs                 0   │
└─────────────────────────────────────┘
```

---

**Document Version:** 1.0 | **Last Updated:** 2026-04-17  
**For operational details, see:** [PIPELINE_DOCUMENTATION.md](PIPELINE_DOCUMENTATION.md)  
**For quick reference, see:** [RUNBOOK.md](RUNBOOK.md)
