# PropelIQ Pipeline & Task Execution Documentation

**Document Version:** 1.0  
**Last Updated:** April 17, 2026  
**Project:** PropelIQ - AI-Powered Personal Assistant  
**Deployment Platform:** Google Cloud Platform (GCP)  
**CI/CD Platform:** GitHub Actions  

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Architecture Overview](#architecture-overview)
3. [Infrastructure & Cloud Setup](#infrastructure--cloud-setup)
4. [CI/CD Pipeline Architecture](#cicd-pipeline-architecture)
5. [Task Execution Strategy](#task-execution-strategy)
6. [Security & Compliance](#security--compliance)
7. [Deployment Procedures](#deployment-procedures)
8. [Monitoring & Observability](#monitoring--observability)
9. [Troubleshooting & Recovery](#troubleshooting--recovery)
10. [Maintenance & Operations](#maintenance--operations)
11. [Scaling Considerations](#scaling-considerations)
12. [Appendices](#appendices)

---

## Executive Summary

PropelIQ is deployed on Google Cloud Platform using a modern, security-first CI/CD pipeline implemented via GitHub Actions. The system automatically validates, tests, scans, builds, and deploys containerized Python applications to Cloud Run on every push to the main branch.

### Key Capabilities

| Capability | Details |
|------------|---------|
| **Automatic Deployment** | Triggered on push to main; separate dev/prod environments |
| **Security Gates** | Gitleaks (secrets), Trivy (vulnerabilities), Checkov (IaC compliance) |
| **Infrastructure-as-Code** | Terraform modules for networking, security, compute, storage |
| **Authentication** | OIDC with Workload Identity Federation (no static keys) |
| **Developer Experience** | Web UI + REST API for prompt-based assistant interaction |
| **Observability** | Health checks, structured logging, deployment metrics |

---

## Architecture Overview

### System Components

```
┌─────────────────────────────────────────────────────────────┐
│                    GitHub Repository (PropelIQ)            │
│  ├─ Source Code (Python, Dockerfile)                        │
│  ├─ GitHub Actions Workflow (.github/workflows/)            │
│  ├─ Terraform IaC (.propel/context/iac/)                    │
│  └─ Specifications & Docs (.propel/context/devops/)        │
└─────────────────────────────────────────────────────────────┘
                          │
                          │ push to main
                          ▼
┌─────────────────────────────────────────────────────────────┐
│              GitHub Actions CI/CD Pipeline                  │
│  ├─ Validate Job (Python tests, Dockerfile lint)            │
│  ├─ Security Job (Gitleaks, Trivy, Checkov)                 │
│  ├─ Build & Push Job (Docker build, registry push)          │
│  ├─ Deploy-Dev Job (Automatic, public access)               │
│  └─ Deploy-Prod Job (Automatic, private access)             │
└─────────────────────────────────────────────────────────────┘
                          │
                          │ Docker push / Terraform apply
                          ▼
┌─────────────────────────────────────────────────────────────┐
│         Google Cloud Platform (Project: akhila-gcp)        │
│  ├─ Artifact Registry (Docker image storage)                │
│  ├─ Cloud Run Services (dev & prod instances)               │
│  ├─ Workload Identity Federation (OIDC auth)                │
│  ├─ Secret Manager (sensitive config storage)               │
│  └─ VPC & Security (networking, firewall rules)             │
└─────────────────────────────────────────────────────────────┘
                          │
                          │ HTTP requests
                          ▼
┌─────────────────────────────────────────────────────────────┐
│           End Users & Developers                            │
│  ├─ Web UI (HTML + Vanilla JS at /)                         │
│  ├─ REST API (/api/prompt POST endpoint)                    │
│  └─ Health Check (/health GET endpoint)                     │
└─────────────────────────────────────────────────────────────┘
```

### Key Services

| Service | Purpose | Hosting |
|---------|---------|---------|
| **app-service-dev** | Development deployment; public/unauthenticated | Cloud Run |
| **app-service** | Production deployment; private/authenticated | Cloud Run |
| **app-images** | Docker image registry | Artifact Registry |
| **github-deployer** | CI/CD service account with GCP permissions | IAM |
| **github-pool** | Workload Identity Federation pool for GitHub | IAM |

---

## Infrastructure & Cloud Setup

### GCP Project Configuration

```
Project ID:        akhila-gcp-123-493309
Project Number:    828956650755
Region:            us-central1
Service Account:   github-deployer@akhila-gcp-123-493309.iam.gserviceaccount.com
WIF Pool:          projects/828956650755/locations/global/workloadIdentityPools/github-pool
WIF Provider:      projects/828956650755/locations/global/workloadIdentityPools/github-pool/providers/github-provider
```

### One-Time Setup

Run the bootstrap script to initialize GCP resources:

```bash
bash scripts/gcp-cicd-bootstrap.sh
```

This script:
1. Enables required GCP APIs (Cloud Run, Artifact Registry, IAM, Secret Manager)
2. Creates Workload Identity Federation pool and provider
3. Provisions CI/CD service account with minimal permissions
4. Configures IAM bindings for GitHub Actions

### Terraform Infrastructure Modules

```
infra/
├── providers.tf          # GCP provider configuration
├── versions.tf           # Terraform & provider versions
├── variables.tf          # Input variables (project_id, region, etc.)
├── main.tf              # Root module composition
├── outputs.tf           # Output values (service URLs, etc.)
├── load-balancer.tf     # Load balancing configuration
├── namespace.tf         # GCP resource namespacing
├── secrets.tf           # Secret Manager integration
├── serviceaccount.tf    # Service account definitions
└── environments/
    ├── dev/terraform.tfvars
    ├── qa/terraform.tfvars
    ├── staging/terraform.tfvars
    └── prod/terraform.tfvars
```

#### Terraform State Management

- **Backend**: GCS (Google Cloud Storage)
- **Locking**: Enabled via DynamoDB equivalent
- **Isolation**: Separate state per environment (dev, qa, staging, prod)

### Cloud Run Configuration

**Dev Service:**
- Name: `app-service-dev`
- Memory: 256MB
- CPU: 0.25
- Concurrency: 50
- Authentication: `--allow-unauthenticated`
- Port: 8080
- Health Check: `/health` (HTTP GET)

**Prod Service:**
- Name: `app-service`
- Memory: 512MB
- CPU: 1.0
- Concurrency: 100
- Authentication: `--no-allow-unauthenticated` (requires OIDC/OAuth)
- Port: 8080
- Health Check: `/health` (HTTP GET)

---

## CI/CD Pipeline Architecture

### GitHub Actions Workflow: `gcp-cloudrun-ci-cd.yml`

The pipeline consists of **5 jobs** executing in sequence on push to `main` branch.

#### Job 1: Validate

**Trigger:** On push to main or pull request  
**Runner:** ubuntu-latest  
**Purpose:** Validate code quality and dependencies  

**Steps:**
1. Checkout code
2. Setup Python 3.11
3. Install dependencies (requirements.txt, requirements-dev.txt)
4. Install pytest
5. Run unit tests
6. Validate Dockerfile syntax

**Success Criteria:**
- All pytest tests pass
- No Python syntax errors
- Dockerfile is valid

**Failure Handling:** Pipeline halts; no further jobs execute

#### Job 2: Security

**Trigger:** On successful validation  
**Runner:** ubuntu-latest  
**Purpose:** Scan for secrets, vulnerabilities, and compliance violations  

**Steps:**

1. **Gitleaks Scan**
   - Tool: gitleaks/gitleaks-action v2
   - Scope: Full repository history
   - Detects: API keys, credentials, secrets
   - Failure Threshold: Any secret found (HIGH)

2. **Trivy Filesystem Scan**
   - Tool: aquasecurity/trivy-action
   - Scope: Repository root
   - Detects: Vulnerable dependencies, configuration issues
   - Failure Threshold: CRITICAL or HIGH severity findings

3. **Checkov IaC Scan**
   - Tool: bridgecrewio/checkov-action v12
   - Scope: Terraform files in `infra/`
   - Detects: Security misconfigurations, compliance violations
   - Failure Threshold: CRITICAL severity findings

4. **CodeQL Analysis** (Specified for future integration)
   - Tool: github/codeql-action
   - Scope: Python source code
   - Detects: Logic flaws, injection vulnerabilities
   - Failure Threshold: CRITICAL severity findings

**Success Criteria:**
- No secrets detected
- No CRITICAL/HIGH vulnerabilities found
- All IaC compliance checks pass

**Failure Handling:** Pipeline halts; security review required

#### Job 3: Build & Push

**Trigger:** On successful security scan  
**Runner:** ubuntu-latest  
**Purpose:** Build Docker image and push to Artifact Registry  

**Steps:**
1. Checkout code
2. Setup Cloud SDK
3. Authenticate to GCP via OIDC
4. Configure Docker authentication for Artifact Registry
5. Build Docker image
   - Base image: `python:3.11-slim`
   - Tag: `us-central1-docker.pkg.dev/akhila-gcp-123-493309/app-images/app:${COMMIT_SHA}`
6. Push image to Artifact Registry
7. Log image digest

**Dockerfile Details:**
```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
EXPOSE 8080
CMD ["python", "main.py"]
```

**Success Criteria:**
- Docker build completes without errors
- Image is successfully pushed to registry
- Image digest is recorded

#### Job 4: Deploy-Dev

**Trigger:** On successful build & push  
**Runner:** ubuntu-latest  
**Purpose:** Deploy to development environment  

**Steps:**
1. Setup Cloud SDK
2. Authenticate to GCP via OIDC
3. Deploy to Cloud Run (dev service)
   ```bash
   gcloud run deploy app-service-dev \
     --image us-central1-docker.pkg.dev/akhila-gcp-123-493309/app-images/app:${COMMIT_SHA} \
     --region us-central1 \
     --allow-unauthenticated \
     --memory 256Mi \
     --cpu 0.25 \
     --platform managed
   ```
4. Retrieve service URL
5. Verify health check (curl `/health`)

**Success Criteria:**
- Service deployed successfully
- Health check returns HTTP 200
- Service URL is accessible

**Post-Deployment Verification:**
```bash
curl -s https://${DEV_SERVICE_URL}/health
# Expected: {"status": "ok"}
```

#### Job 5: Deploy-Prod

**Trigger:** On successful dev deployment  
**Runner:** ubuntu-latest  
**Purpose:** Deploy to production environment  

**Steps:**
1. Setup Cloud SDK
2. Authenticate to GCP via OIDC
3. Deploy to Cloud Run (prod service)
   ```bash
   gcloud run deploy app-service \
     --image us-central1-docker.pkg.dev/akhila-gcp-123-493309/app-images/app:${COMMIT_SHA} \
     --region us-central1 \
     --no-allow-unauthenticated \
     --memory 512Mi \
     --cpu 1.0 \
     --platform managed
   ```
4. Retrieve service URL
5. Verify health check (curl `/health` with authentication)

**Success Criteria:**
- Service deployed successfully
- Health check returns HTTP 200 (authenticated requests only)
- Service URL is accessible only with credentials

**Production Protection:**
- Requires environment-level approval rules (2 reviewers minimum)
- Deployment logs are retained for audit purposes
- Rollback procedures available via service versioning

### Pipeline Execution Flow Diagram

```
┌─────────────────┐
│ Push to main    │
└────────┬────────┘
         │
         ▼
┌──────────────────────┐
│ Validate Job         │
│ - Python tests       │
│ - Dockerfile check   │
└────────┬─────────────┘
         │ ✓ pass
         ▼
┌──────────────────────────────────────┐
│ Security Job                         │
│ - Gitleaks (no secrets)              │
│ - Trivy (no vulnerabilities)         │
│ - Checkov (IaC compliance)           │
│ - CodeQL (SAST analysis)             │
└────────┬─────────────────────────────┘
         │ ✓ pass
         ▼
┌──────────────────────────────────────┐
│ Build & Push Job                     │
│ - Docker build                       │
│ - Push to Artifact Registry          │
│ - Record image digest                │
└────────┬─────────────────────────────┘
         │ ✓ pass
         ▼
┌──────────────────────────────────────┐
│ Deploy-Dev Job                       │
│ - Deploy to Cloud Run (dev)          │
│ - Verify health check                │
│ - Public access enabled              │
└────────┬─────────────────────────────┘
         │ ✓ pass
         ▼
┌──────────────────────────────────────┐
│ Deploy-Prod Job                      │
│ - Deploy to Cloud Run (prod)         │
│ - Verify health check                │
│ - Private access (auth required)     │
│ - ⚠️ Requires 2 reviewer approval    │
└────────┬─────────────────────────────┘
         │ ✓ pass
         ▼
    ✅ DEPLOYMENT COMPLETE
```

### Environment Secrets & Variables

Required GitHub Actions secrets (set in repo Settings → Secrets):

```
GCP_PROJECT_ID:                akhila-gcp-123-493309
GCP_WORKLOAD_IDENTITY_PROVIDER: projects/828956650755/locations/global/workloadIdentityPools/github-pool/providers/github-provider
GCP_SERVICE_ACCOUNT:           github-deployer@akhila-gcp-123-493309.iam.gserviceaccount.com
```

---

## Task Execution Strategy

### Development Workflow

#### 1. Local Development

**Before making changes:**
```bash
git checkout -b feature/your-feature-name
```

**Development checklist:**
- [ ] Update source code
- [ ] Add/update tests in appropriate test files
- [ ] Update requirements.txt if adding dependencies
- [ ] Test locally: `python -m pytest`
- [ ] Test Docker build: `docker build -t app:test .`
- [ ] Run security tools locally if available

#### 2. Pre-Commit Validation

**Optional: Install pre-commit hooks**
```bash
pip install pre-commit
pre-commit install
```

**Manual validation before push:**
```bash
# Python tests
python -m pytest -v

# Dockerfile validation
docker build --no-cache -t app:validation .

# Gitleaks scan (if installed)
gitleaks detect --source . --verbose

# Trivy scan (if installed)
trivy fs .
```

#### 3. Commit & Push

```bash
git add .
git commit -m "feat: describe your feature"
git push origin feature/your-feature-name
```

#### 4. Pull Request Review

**Create Pull Request on GitHub:**
- [ ] Provide descriptive title and description
- [ ] Link related issues
- [ ] Mention reviewers
- [ ] CI/CD pipeline automatically runs on PR

**PR Pipeline Execution:**
- Validate job runs (same as main)
- Security job runs (same as main)
- Build & Push job **skipped** on PR (no production push)
- Deploy jobs **skipped** on PR (no infrastructure changes)

**Approval Requirements:**
- Code review approval (1+ reviewers)
- All status checks pass (Validate + Security jobs)
- No merge conflicts

#### 5. Merge to Main

```bash
# Reviewer merges PR via GitHub UI
# Automatically triggers full pipeline
```

**Main Branch Pipeline:**
- Validate job
- Security job
- Build & Push job (new image pushed to registry)
- Deploy-Dev job (automatic)
- Deploy-Prod job (awaits environment approvals)

#### 6. Production Deployment

**Manual Approval Required:**
1. Navigate to Actions → gcp-cloudrun-ci-cd → Latest run
2. Scroll to "Deploy-Prod" job
3. Click "Review Deployments"
4. Assign 2 reviewers for approval
5. Reviewers approve via GitHub UI
6. Deployment proceeds automatically

### Task Categories & Mapping

| Task Type | Trigger | Pipeline Path | Approval Gate | Rollback |
|-----------|---------|---------------|---------------|----------|
| Hotfix (bug fix) | push to main | Validate → Security → Build → Dev → Prod* | 2 reviewers | Service versioning |
| Feature | merge PR to main | Validate → Security → Build → Dev → Prod* | 2 reviewers | Service versioning |
| Configuration | direct push | Skip validate/security if docs only | Manual | Manual revert + push |
| Infrastructure | terraform apply | Checkov scan in security job | Manual review | terraform destroy |
| Release | git tag | Full pipeline (same as main) | 2 reviewers + release mgr | Previous image tag |

*Prod deployment requires environment approval

### Task Execution Example: Adding a Feature

**Scenario:** Add new `/analyze` endpoint to PropelIQ assistant

**Step 1: Create Feature Branch**
```bash
git checkout -b feature/analyze-endpoint
```

**Step 2: Implement Feature**
```python
# main.py - add new handler
def do_POST(self):
    # ... existing code ...
    elif self.path == "/api/analyze":
        # New analyze endpoint logic
        pass
```

**Step 3: Add Tests**
```python
# tests/test_analyze.py
def test_analyze_endpoint_valid_input():
    # Test implementation
    pass
```

**Step 4: Update Dependencies (if needed)**
```
# requirements.txt
requests==2.31.0  # Example: added dependency
```

**Step 5: Local Validation**
```bash
python -m pytest -v
docker build -t app:test .
```

**Step 6: Commit & Push**
```bash
git add main.py tests/test_analyze.py requirements.txt
git commit -m "feat: add /analyze endpoint for sentiment analysis"
git push origin feature/analyze-endpoint
```

**Step 7: Create PR**
- GitHub PR page opens
- CI/CD pipeline runs automatically
- Validate job: pytest passes ✓
- Security job: Gitleaks/Trivy/Checkov pass ✓
- Code review complete

**Step 8: Merge to Main**
- Merge PR via GitHub UI
- Full pipeline triggers automatically

**Pipeline Execution Timeline:**
```
T+0s:   Validate job starts
T+30s:  Validate job completes ✓
T+35s:  Security job starts
T+90s:  Security job completes ✓
T+95s:  Build & Push job starts
T+180s: Build & Push job completes ✓
        New image: us-central1-docker.pkg.dev/akhila-gcp-123-493309/app-images/app:<commit-sha>
T+185s: Deploy-Dev job starts
T+240s: Deploy-Dev job completes ✓
        Dev service URL: https://app-service-dev-xxx.run.app
        Health check successful
T+245s: Deploy-Prod job starts (awaits approval)
T+?:    Prod reviewers approve
T+?:    Prod deployment proceeds
        Prod service URL: https://app-service-xxx.run.app
```

---

## Security & Compliance

### Security Controls in Pipeline

#### 1. Secrets Detection (Gitleaks)

**Configuration:**
- Scans entire repository history
- Detects API keys, passwords, credentials, tokens
- Fails build if any secret found

**Common secrets detected:**
- AWS credentials (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)
- GitHub tokens (GITHUB_TOKEN, PAT)
- Google Cloud credentials (JSON service accounts)
- Database credentials (connection strings)
- API keys (third-party services)

**Prevention:**
```bash
# ✓ Good: Use GitHub Actions secrets
env:
  API_KEY: ${{ secrets.API_KEY }}

# ✗ Bad: Hardcoded in workflow
env:
  API_KEY: "sk-1234567890"
```

#### 2. Vulnerability Scanning (Trivy)

**Configuration:**
- Type: Filesystem scan
- Scope: Full repository root
- Severity Threshold: CRITICAL and HIGH (fail build)

**Vulnerabilities Scanned:**
- Python package vulnerabilities (via pip)
- System library vulnerabilities (Alpine, Debian packages)
- Configuration weaknesses
- License compliance issues

**Sample Report:**
```
app/requirements.txt
├── HIGH: requests 2.20.0 (Use requests >= 2.31.0)
└── CRITICAL: urllib3 (SSL verification bypass)

Dockerfile
└── HIGH: python:3.11 base image (CVEs in Debian)
```

**Remediation:**
```bash
pip install --upgrade requests urllib3
# Update Dockerfile: FROM python:3.11-slim@sha256:abc123
```

#### 3. IaC Security (Checkov)

**Configuration:**
- Framework: Terraform
- Scope: `infra/` directory
- Severity Threshold: CRITICAL (fail build)

**Checks Performed:**
- CKV_GCP_1: Ensure Cloud Run restricts public access
- CKV_GCP_2: Ensure IAM policies follow least privilege
- CKV_GCP_3: Ensure secrets are encrypted
- CKV_GCP_4: Ensure audit logging enabled
- Plus 100+ other compliance checks

**Example Finding:**
```
Check: CKV_GCP_1: Ensure Cloud Run services restrict public ingress
Resource: google_cloud_run_service.app_service_dev
Status: FAILED
Remediation: Set --allow-unauthenticated=false or add IAM policy
```

#### 4. Static Analysis (CodeQL)

**Configuration:** Specified for future integration  
**Language:** Python  
**Scope:** Source code analysis  

**Vulnerabilities Detected:**
- SQL injection
- Cross-site scripting (XSS)
- Path traversal
- Unsafe deserialization
- Hardcoded secrets

### OIDC Authentication (No Static Keys)

**Why OIDC?**
- No long-lived credentials stored in GitHub
- Each workflow run gets a short-lived token (1 hour validity)
- Credentials are automatically revoked after job completion
- Full audit trail in GCP

**Key Components:**

1. **Workload Identity Federation Pool**
   ```
   Name: github-pool
   Location: global
   Provider: github-provider
   ```

2. **Provider Configuration**
   ```
   Provider: github
   Audience: aud:akhila-gcp-123-493309
   Subject Pattern: assertion.repository == 'kanini/propeliq'
   ```

3. **Service Account Binding**
   ```
   Service Account: github-deployer@akhila-gcp-123-493309.iam.gserviceaccount.com
   Roles:
     - roles/artifactregistry.writer (push Docker images)
     - roles/run.developer (deploy Cloud Run)
     - roles/iam.serviceAccountUser (for Cloud Run)
   ```

**Token Exchange Flow:**
```
GitHub Actions Job
    │
    ├─ Generates OIDC token (signed by GitHub)
    │
    ▼
google-github-actions/auth action
    │
    ├─ Exchanges OIDC token for GCP access token
    │
    ▼
GCP Workload Identity Federation
    │
    ├─ Validates GitHub OIDC token signature
    ├─ Authorizes access based on subject/audience
    │
    ▼
google-deployer service account
    │
    ├─ Access token is issued (1-hour expiry)
    │
    ▼
Cloud Run & Artifact Registry
```

### Action Pinning (Supply Chain Security)

**Strategy:** Pin all third-party actions to commit SHAs rather than version tags

**Rationale:**
- Version tags can be moved (e.g., `v4` could point to different code)
- Commit SHAs are immutable
- Reduces risk of malicious action updates

**Example:**

```yaml
# ✓ Safe: Pinned to commit SHA (full 40 characters)
- uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683  # v4.2.2

# ✗ Unsafe: Variable version tag (could change)
- uses: actions/checkout@v4

# ✗ Unsafe: Range version (could change)
- uses: actions/checkout@v4.2.x
```

**Pinned Actions in PropelIQ:**

| Action | Purpose | SHA | Version |
|--------|---------|-----|---------|
| actions/checkout | Code checkout | 11bd71901b... | v4.2.2 |
| actions/setup-python | Python setup | a26af69be9... | v5.6.0 |
| gitleaks/gitleaks-action | Secrets scan | (tag: v2) | v2 |
| aquasecurity/trivy-action | Vulnerability scan | (tag: latest) | latest |
| bridgecrewio/checkov-action | IaC compliance | (tag: v12) | v12 |
| google-github-actions/auth | GCP auth | (tag: v2) | v2 |
| google-github-actions/setup-gcloud | GCP SDK | (tag: v2) | v2 |

### Deployment Gating Strategy

**Dev Environment:**
```yaml
Deploy-Dev:
  if: github.ref == 'refs/heads/main'
  needs: build-and-push
  # No approval required; automatic
```

**Prod Environment:**
```yaml
Deploy-Prod:
  if: github.ref == 'refs/heads/main'
  needs: deploy-dev
  # Requires manual approval via GitHub environment protection rules
  environment:
    name: production
    url: https://app-service-xxx.run.app
```

**Environment Protection Rules:**
```
Name: production
Deployment branches: Allow deployments from: main
Reviewers: 2 required for approval
Dismiss stale reviews: Enabled
Require status checks to pass: All jobs must pass
```

### Compliance & Audit

**Audit Trail:**
- All pipeline runs logged in GitHub Actions history
- Deployment history in Cloud Run revision history
- Access logs in GCP Cloud Logging
- OIDC token exchanges logged in GCP audit logs

**Example Query (GCP Logging):**
```
resource.type="cloud_run_revision"
protoPayload.resourceName=~"app-service"
protoPayload.authenticationInfo.principalEmail="github-deployer@..."
```

---

## Deployment Procedures

### Automatic Deployment (Primary Path)

**Trigger:** Push to main branch

**Procedure:**
1. Commit changes to feature branch
2. Create pull request (optional)
3. Obtain code review and approval
4. Merge PR to main branch
5. GitHub Actions pipeline automatically triggers
6. Follow pipeline execution (Validate → Security → Build → Deploy-Dev → Deploy-Prod)

**Verification:**
```bash
# Check pipeline status
open https://github.com/kanini/propeliq/actions

# Monitor specific run
# Click on the workflow, then on the commit SHA

# Verify dev deployment
curl -s https://app-service-dev-xxx.run.app/health
# Expected: {"status": "ok"}

# Verify prod deployment (after approval)
curl -s -H "Authorization: Bearer $(gcloud auth print-identity-token)" \
  https://app-service-xxx.run.app/health
# Expected: {"status": "ok"}
```

### Manual Deployment (Emergency Path)

**Use Case:** Urgent hotfix or rollback without going through full pipeline

**Prerequisites:**
```bash
# Install GCP Cloud SDK
# Authenticate: gcloud auth login
# Set project: gcloud config set project akhila-gcp-123-493309
```

**Deploy Script:**
```bash
bash scripts/deploy-cloudrun-basic.sh app-service-dev true
# Parameters:
#   - Service name: app-service-dev
#   - Public access: true (--allow-unauthenticated)

bash scripts/deploy-cloudrun-basic.sh app-service false
# Parameters:
#   - Service name: app-service
#   - Public access: false (--no-allow-unauthenticated)
```

**Script Execution:**
```
[ INFO ] Starting deployment...
[ INFO ] Building Docker image: app:latest
Build output...
[ INFO ] Pushing to Artifact Registry...
Push output...
[ INFO ] Deploying to Cloud Run...
Deployment output...
[ INFO ] Deployment completed.
[ INFO ] Service URL: https://app-service-dev-xxxxxxxx.run.app
```

### Rollback Procedure

**Scenario:** Current version has critical bug; need to rollback to previous version

**Method 1: Cloud Run Traffic Splitting (Zero-Downtime)**

```bash
# List service revisions
gcloud run revisions list --service app-service-dev

# Get current and previous revision-sha
gcloud run services describe app-service-dev \
  --format="value(status.traffic[].revisionName)"

# Route traffic to previous revision
gcloud run services update-traffic app-service-dev \
  --to-revisions LATEST:0 PREVIOUS:100

# Monitor traffic
gcloud run services describe app-service-dev \
  --format="value(status.traffic[])"
```

**Method 2: Revert Commit & Re-Push**

```bash
# Identify commit that introduced bug
git log --oneline -n 10

# Revert commit
git revert <bad-commit-sha>

# Push reverted commit
git push origin main

# Pipeline executes automatically; rolls back to previous version
```

**Method 3: Redeploy Previous Image**

```bash
# List images in Artifact Registry
gcloud artifacts docker images list us-central1-docker.pkg.dev/akhila-gcp-123-493309/app-images

# Deploy specific image
gcloud run deploy app-service-dev \
  --image us-central1-docker.pkg.dev/akhila-gcp-123-493309/app-images/app:<previous-sha> \
  --region us-central1 \
  --allow-unauthenticated
```

---

## Monitoring & Observability

### Health Checks

**Endpoint:** GET `/health`

**Expected Response:**
```json
{
  "status": "ok"
}
```

**HTTP Status:** 200 OK

**Cloud Run Configuration:**
```
Path: /health
Timeout: 4 seconds
Check Interval: 30 seconds
Consecutive Failures: 3
Recovery Grace Period: 0 seconds
```

**Monitoring Health:**
```bash
# Dev service
curl -s https://app-service-dev-xxx.run.app/health | jq .

# Prod service (requires auth)
TOKEN=$(gcloud auth print-identity-token)
curl -s -H "Authorization: Bearer $TOKEN" \
  https://app-service-xxx.run.app/health | jq .
```

### Application Logging

**Log Locations:**
1. **GitHub Actions:** GitHub.com → Actions → Workflow runs
2. **Cloud Run:** GCP Console → Cloud Run → Service → Logs
3. **Cloud Logging:** GCP Console → Logging → Logs Explorer

**Query Examples:**

**View Dev Service Logs (last 100 lines, past 24 hours):**
```bash
gcloud run services logs read app-service-dev \
  --limit 100 \
  --region us-central1
```

**View Prod Service Logs with Filtering:**
```bash
gcloud logging read \
  "resource.type=cloud_run_revision \
   AND resource.labels.service_name=app-service \
   AND severity >= WARNING" \
  --limit 50 \
  --format json
```

**Structured Logging Format (Python Application):**
```python
import json
from datetime import datetime

def log(level, message, **kwargs):
    log_entry = {
        "timestamp": datetime.utcnow().isoformat() + "Z",
        "level": level,
        "message": message,
        **kwargs
    }
    print(json.dumps(log_entry))

# Usage:
log("INFO", "API request received", endpoint="/api/prompt", method="POST")
log("ERROR", "Failed to process request", error="Invalid JSON", status_code=400)
```

### Metrics & Dashboards

**Cloud Run Metrics:**
- Request count
- Request latency (p50, p95, p99)
- Error rate
- CPU utilization
- Memory utilization
- Instance count

**Accessing Metrics:**

```bash
# View recent metrics
gcloud monitoring metrics-descriptors list --filter="service=run"

# Get request count for dev service (past 1 hour)
gcloud monitoring time-series list \
  --filter='resource.type="cloud_run_revision" \
            AND resource.labels.service_name="app-service-dev" \
            AND metric.type="run.googleapis.com/request_count"' \
  --interval-start-time="1h ago"
```

**Creating Custom Dashboards:**

1. GCP Console → Monitoring → Dashboards
2. Create New Dashboard
3. Add Chart → Cloud Run metrics
4. Filter by service name (app-service-dev, app-service)
5. Set time range and refresh interval

---

## Troubleshooting & Recovery

### Pipeline Failures

#### Failure: Validate Job - pytest Tests Fail

**Symptom:**
```
Error: 1 failed in 0.12s
Test failed: test_api_endpoint_invalid_input
```

**Root Causes:**
1. Test code is outdated relative to implementation
2. New code is not covered by tests
3. Test environment setup is incomplete

**Resolution:**

```bash
# Step 1: Run tests locally to replicate error
python -m pytest -v tests/

# Step 2: Fix failing test or implementation
# Edit test_*.py or main.py as appropriate

# Step 3: Re-run tests until passing
python -m pytest -v tests/

# Step 4: Commit and push
git add main.py tests/
git commit -m "fix: correct failing tests"
git push origin feature/your-feature
```

#### Failure: Security Job - Gitleaks Detects Secret

**Symptom:**
```
❌ Secret found: AWS_ACCESS_KEY_ID in config.json (line 42)
Incident Type: AWS Manager ID
```

**Root Causes:**
1. Accidentally committed credentials file
2. Hardcoded credentials in code
3. Environment variable exposed as string literal

**Resolution:**

```bash
# Step 1: Identify and remove the secret
# Edit the file and remove credentials

# Step 2: Revoke the exposed secret in AWS/GCP/third-party service
# This is CRITICAL even after removing from repo

# Step 3: Clear git history (use BFG or git-filter-repo)
# ⚠️ This rewrites commit history; coordinate with team
brew install bfg  # or apt-get install bfg
bfg --delete-files config.json  # Remove file from history

# Step 4: Force push (notify team before doing this)
git push origin feature/your-feature --force-with-lease

# Step 5: Re-run pipeline
# Gitleaks should pass now
```

#### Failure: Build & Push - Docker Build Fails

**Symptom:**
```
ERROR: cannot find module 'requests'
Step 5 RUN pip install --no-cache-dir -r requirements.txt
The command '/bin/sh -c pip install --no-cache-dir -r requirements.txt' returned a non-zero code: 1
```

**Root Causes:**
1. Missing or corrupted requirements.txt
2. Dependency has breaking change in newer version
3. Network connectivity issue during pip install

**Resolution:**

```bash
# Step 1: Test Docker build locally
docker build -t app:test .
# If builds successfully locally, issue may be transient; retry pipeline

# Step 2: If build fails locally, debug requirements.txt
cat requirements.txt
# Verify all packages are valid and have compatible versions

# Step 3: Update requirements.txt with working versions
pip install -r requirements.txt  # Test in local Python environment
# If this fails, identify problematic package(s)

# Step 4: Update Dockerfile if needed
# e.g., add system dependencies
RUN apt-get update && apt-get install -y libpq-dev

# Step 5: Commit and push
git add Dockerfile requirements.txt
git commit -m "fix: resolve Docker build dependencies"
git push origin feature/your-feature
```

#### Failure: Deploy-Dev - Service Fails to Start

**Symptom:**
```
ERROR: Cloud Run error: Container failed to start. Failed to start and then listen on the port defined by the PORT environment variable. 
Logs for this Container Instance (revision default@latest):
...
```

**Root Causes:**
1. Application doesn't listen on port 8080
2. Application crashes on startup
3. Required environment variable is missing

**Resolution:**

```bash
# Step 1: Test Docker image locally
docker run -p 8080:8080 us-central1-docker.pkg.dev/akhila-gcp-123-493309/app-images/app:<sha>

# Step 2: Verify application starts and listens
curl http://localhost:8080/health
# Should return {"status": "ok"}

# Step 3: If app doesn't start, check Python code
python main.py  # Run locally to see error messages

# Step 4: Common issues:
# - Application binds to 127.0.0.1 instead of 0.0.0.0
#   Edit main.py: server_address = ('0.0.0.0', 8080)
# - PORT environment variable not respected
#   Edit main.py: port = int(os.environ.get('PORT', 8080))
# - Missing required environment variable
#   Add to Dockerfile: ENV API_KEY=default_value

# Step 5: Rebuild and test
docker build -t app:test .
docker run -p 8080:8080 app:test

# Step 6: Commit and re-push
git add main.py Dockerfile
git commit -m "fix: correct port binding for Cloud Run"
git push origin feature/your-feature
```

### GCP Permission Issues

#### Error: "Permission denied" when Pushing to Artifact Registry

**Symptom:**
```
ERROR: (gcloud.artifacts.docker.push) User [github-deployer@akhila-gcp-123-493309.iam.gserviceaccount.com] does not have permission to access resource [us-central1-docker.pkg.dev/akhila-gcp-123-493309/app-images]
```

**Root Cause:** Service account lacks `artifactregistry.writer` role

**Resolution:**

```bash
# Grant role to service account
gcloud projects add-iam-policy-binding akhila-gcp-123-493309 \
  --member=serviceAccount:github-deployer@akhila-gcp-123-493309.iam.gserviceaccount.com \
  --role=roles/artifactregistry.writer

# Verify role assignment
gcloud projects get-iam-policy akhila-gcp-123-493309 \
  --flatten="bindings[].members" \
  --format='table(bindings.role)' \
  --filter="bindings.members:github-deployer@*"
```

#### Error: "Permission denied" when Deploying to Cloud Run

**Symptom:**
```
ERROR: (gcloud.run.deploy) User does not have permission to access resource [app-service-dev] in region [us-central1]
```

**Root Cause:** Service account lacks `run.developer` or `iam.serviceAccountUser` role

**Resolution:**

```bash
# Grant Cloud Run developer role
gcloud projects add-iam-policy-binding akhila-gcp-123-493309 \
  --member=serviceAccount:github-deployer@akhila-gcp-123-493309.iam.gserviceaccount.com \
  --role=roles/run.developer

# Grant service account impersonation role
gcloud projects add-iam-policy-binding akhila-gcp-123-493309 \
  --member=serviceAccount:github-deployer@akhila-gcp-123-493309.iam.gserviceaccount.com \
  --role=roles/iam.serviceAccountUser

# Verify permissions
gcloud iam service-accounts get-iam-policy \
  github-deployer@akhila-gcp-123-493309.iam.gserviceaccount.com
```

---

## Maintenance & Operations

### Regular Maintenance Tasks

#### Weekly Tasks

**1. Monitor Pipeline Success Rate**
```
Metric: % of main branch commits with successful pipeline execution
Target: ≥ 99%
Action: If below target, review recent failures and remediate
```

**2. Review Cloud Run Error Rates**
```bash
gcloud monitoring time-series list \
  --filter='resource.type="cloud_run_revision" \
            AND metric.type="run.googleapis.com/request_count" \
            AND metric.response_code_class="5xx"'
```

#### Monthly Tasks

**1. Update GitHub Actions Action Versions**

Check for new action versions and security updates:
```bash
# Visit GitHub Dependabot or Actions Marketplace
# Review pending updates in GitHub Security tab
# Test updated actions in a feature branch before merging
```

**2. Review Security Scan Reports**

```bash
# Gitleaks: No new secrets should trend up
# Trivy: Check for new vulnerabilities; prioritize CRITICAL/HIGH
# Checkov: Review IaC compliance violations; update Terraform if needed
```

**3. Analyze Pipeline Performance**

```bash
# Metrics to track:
# - Average pipeline duration
# - Individual job durations
# - Pipeline retry rate
# - Most common failure points

gcloud logging read \
  "resource.type=cloud_run_revision" \
  --format="table(timestamp, protoPayload.resourceName, protoPayload.status.code)" \
  --limit 1000
```

#### Quarterly Tasks

**1. Infrastructure Review & Capacity Planning**

```bash
# Review Cloud Run metrics (request volume, latency, errors)
gcloud monitoring dashboards list

# Check Artifact Registry image count and size
gcloud artifacts docker images list \
  us-central1-docker.pkg.dev/akhila-gcp-123-493309/app-images

# Audit IAM permissions
gcloud projects get-iam-policy akhila-gcp-123-493309

# Verify Terraform state integrity
terraform state list
```

**2. Disaster Recovery Simulation**

```bash
# Test rollback procedure
# 1. Trigger rollback via Cloud Run traffic splitting
# 2. Verify previous version is accessible
# 3. Switch traffic back to latest

# Test database backup/restore (if applicable)
# Test redeployment from Terraform
terraform plan
terraform apply -auto-approve  # In non-prod environment first
```

### Dependency Management

#### Python Dependencies

**File:** `requirements.txt`

**Update Strategy:**
```bash
# List outdated packages
pip list --outdated

# Update specific package
pip install --upgrade requests

# Regenerate requirements.txt with pinned versions
pip freeze > requirements.txt

# Review changes and commit
git diff requirements.txt
git add requirements.txt
git commit -m "chore: update dependencies"
git push origin feature/dependency-updates
```

**Version Pinning Strategy:**
```
# ✓ Recommended: Pin to specific version
requests==2.31.0
numpy==1.24.3

# ~ Acceptable: Allow patch updates
requests~=2.31.0  # Allows 2.31.x, not 2.32.x

# ✗ Avoid: Unpinned versions (security risk)
requests
```

#### GitHub Actions Dependencies

**Update Strategy:**
```bash
# Use GitHub Dependabot for automatic updates
# Settings → Security & analysis → Enable Dependabot version updates
```

**Manual Update:**
```yaml
# Before:
- uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683  # v4.2.2

# After (check GitHub Action releases for latest SHA):
- uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11  # v4.3.0
```

### Cost Optimization

#### Cloud Run Cost Analysis

**Monthly Estimate (Sample):**
```
Compute: $18.75/million requests @ 0.25 CPU
Memory:  $3.33/GB-month
Storage: $0.02/month
Misc:    $2.00

Total Estimate: $24.10/month
```

**Optimization Strategies:**

1. **Reduce Memory/CPU during off-peak**
   ```bash
   # Update Cloud Run service
   gcloud run services update app-service-dev \
     --memory 128Mi \
     --cpu 0.167 \
     --region us-central1
   ```

2. **Enable autoscaling (already default)**
   ```bash
   gcloud run services update app-service-dev \
     --min-instances 0 \
     --max-instances 10 \
     --region us-central1
   ```

3. **Use Artifact Registry image cleanup policies**
   ```bash
   gcloud artifacts repositories create app-images \
     --repository-format=docker \
     --cleanup-policy-delete-condition=older-than-90d \
     --cleanup-policy-delete-condition-tag-state untagged
   ```

### Backup & Recovery

#### Configuration Backup

**Backup GCP Resources via Terraform:**
```bash
cd infra/
terraform plan -out=tfplan
terraform show tfplan > backup_$(date +%Y%m%d).txt
```

**Backup GitHub Actions Secrets:**
```bash
# Export secrets (requires GitHub CLI)
gh secret list --repo kanini/propeliq > secrets_backup.txt

# NOTE: Secret VALUES not included; this is documentation only
```

#### Data Recovery Procedures

**Restore from Terraform State:**
```bash
# If GCP resources are deleted accidentally
cd infra/
terraform apply  # Re-creates all resources

# If Terraform state is corrupted
# 1. Recover from GCS backup
# 2. Reimport resources: terraform import
```

---

## Scaling Considerations

### Horizontal Scaling

**Current Configuration:**
```
Dev Service:  0-10 instances (min-max)
Prod Service: 0-50 instances (min-max)
```

**Scaling Triggers:**
- CPU utilization > 80%
- Request rate spike
- Custom metrics (if configured)

**To Increase Max Instances:**
```bash
gcloud run services update app-service \
  --max-instances 250 \
  --region us-central1
```

### Vertical Scaling

**Current Resources:**
```
Dev:  256 MB memory, 0.25 CPU
Prod: 512 MB memory, 1.0 CPU
```

**To Upgrade Prod Environment:**
```bash
gcloud run services update app-service \
  --memory 1Gi \
  --cpu 2 \
  --region us-central1
```

### Multi-Region Deployment

**Future Enhancement: Deploy to Additional Regions**

```bash
# Deploy to europe-west1
gcloud run deploy app-service \
  --image us-central1-docker.pkg.dev/akhila-gcp-123-493309/app-images/app:latest \
  --region europe-west1 \
  --no-allow-unauthenticated

# Set up Cloud Load Balancer for traffic distribution
# (Beyond scope of current documentation)
```

### Database Scaling (Future)

When adding a database backend:
```
Current: None (stateless)
Phase 1: Cloud SQL (PostgreSQL)
Phase 2: Connection pooling (Cloud SQL Proxy)
Phase 3: Read replicas
Phase 4: Spanner (if global distribution needed)
```

---

## Appendices

### A. Quick Reference Commands

**Local Development:**
```bash
# Clone repository
git clone https://github.com/kanini/propeliq.git
cd propeliq

# Create feature branch
git checkout -b feature/your-feature

# Test locally
python -m pytest -v
docker build -t app:test .

# Push to GitHub
git add .
git commit -m "feat: your feature"
git push origin feature/your-feature
```

**GCP Operations:**
```bash
# Configure project
gcloud config set project akhila-gcp-123-493309

# View Cloud Run services
gcloud run services list --region us-central1

# View deployment logs
gcloud run services logs read app-service-dev --limit 100

# Redeploy service
gcloud run deploy app-service-dev \
  --image us-central1-docker.pkg.dev/akhila-gcp-123-493309/app-images/app:latest \
  --region us-central1 \
  --allow-unauthenticated
```

**GitHub Actions:**
```bash
# View workflow execution history
open https://github.com/kanini/propeliq/actions

# Re-run a failed workflow
# Click on the workflow → Re-run jobs

# View workflow logs
# Click on the job → Expand log sections
```

### B. Environment Variables Reference

**GitHub Actions Secrets:**
```
GCP_PROJECT_ID
GCP_WORKLOAD_IDENTITY_PROVIDER
GCP_SERVICE_ACCOUNT
```

**Application Environment Variables:**
```
PORT              # Default: 8080
ENV               # Default: development (or production)
LOG_LEVEL         # Default: INFO
API_TIMEOUT       # Default: 30 seconds
```

**Terraform Variables:**
```hcl
project_id          # GCP project ID
region              # GCP region (default: us-central1)
environment         # Environment name (dev, qa, staging, prod)
service_memory_mb   # Cloud Run memory (default: 256)
service_cpu         # Cloud Run CPU (default: 0.25)
```

### C. Useful Links

| Resource | URL |
|----------|-----|
| GitHub Repository | https://github.com/kanini/propeliq |
| GitHub Actions | https://github.com/kanini/propeliq/actions |
| GCP Project | https://console.cloud.google.com/run?project=akhila-gcp-123-493309 |
| Cloud Run Services | https://console.cloud.google.com/run?region=us-central1 |
| Artifact Registry | https://console.cloud.google.com/artifacts/docker/akhila-gcp-123-493309/us-central1 |
| Cloud Logging | https://console.cloud.google.com/logs |

### D. Disaster Recovery Plan

**RTO/RPO Targets:**
- Recovery Time Objective (RTO): 15 minutes
- Recovery Point Objective (RPO): Last commit on main

**Disaster Scenarios:**

| Scenario | Recovery Step | Time |
|----------|---------------|------|
| Cloud Run service deleted | `terraform apply` or manual redeploy | 3 min |
| Artifact Registry corrupted | Rebuild image from source + push | 2 min |
| GitHub repo compromised | Restore from backup branch | 5 min |
| Pipeline unable to authenticate | Re-run bootstrap script | 5 min |

**Backup Schedule:**
- Terraform state: Continuous (GCS backend)
- GitHub workflow definition: Continuous (Git history)
- Cloud Run configuration: On-demand (gcloud export)

### E. Glossary

| Term | Definition |
|------|-----------|
| **CI/CD** | Continuous Integration / Continuous Deployment |
| **OIDC** | OpenID Connect (authentication protocol) |
| **WIF** | Workload Identity Federation (GCP's OIDC implementation) |
| **Cloud Run** | Serverless container compute service on GCP |
| **Artifact Registry** | Container and package registry on GCP |
| **GitHub Actions** | CI/CD workflow automation platform |
| **Terraform** | Infrastructure-as-Code tool for cloud provisioning |
| **Gitleaks** | Security scanning tool for detecting secrets in git history |
| **Trivy** | Vulnerability scanner for images and filesystems |
| **Checkov** | IaC compliance scanning tool |

---

## Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-04-17 | DevOps Team | Initial documentation |

---

## Contact & Support

**For Pipeline Issues:**
- Create issue in GitHub repository: https://github.com/kanini/propeliq/issues
- Contact DevOps team for GCP-specific questions

**For Security Concerns:**
- Report via GitHub Security Advisory
- Contact security team (security@example.com)

**For Documentation Updates:**
- Submit PR with documentation changes
- Ensure all links and commands are tested before merge

---

**Document Classification:** Public  
**Last Review Date:** 2026-04-17  
**Next Review Date:** 2026-07-17 (Quarterly)
