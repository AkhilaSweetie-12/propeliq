# PropelIQ Pipeline Runbook - Quick Reference

**Quick Links:** [Full Documentation](PIPELINE_DOCUMENTATION.md) | [Status Dashboard](https://github.com/kanini/propeliq/actions) | [GCP Console](https://console.cloud.google.com/run?project=akhila-gcp-123-493309&region=us-central1)

---

## Table of Contents

1. [First-Time Setup](#first-time-setup)
2. [Typical Development Workflow](#typical-development-workflow)
3. [Pipeline Monitoring](#pipeline-monitoring)
4. [Emergency Procedures](#emergency-procedures)
5. [Common Commands](#common-commands)

---

## First-Time Setup

### Prerequisites
- GitHub account with access to `kanini/propeliq`
- GCP account access
- `gcloud` CLI installed
- Docker installed (optional, for local testing)

### Setup Steps

```bash
# 1. Clone repository
git clone https://github.com/kanini/propeliq.git
cd propeliq

# 2. Install Python dependencies
python -m pip install --upgrade pip
pip install -r requirements.txt
pip install -r requirements-dev.txt  # If exists

# 3. Configure GCP (one-time)
gcloud auth login
gcloud config set project akhila-gcp-123-493309

# 4. Bootstrap GCP resources (one-time, only once per project)
bash scripts/gcp-cicd-bootstrap.sh

# 5. Verify setup
python -m pytest -v
docker build -t app:test .
```

---

## Typical Development Workflow

### Step 1: Create Feature Branch
```bash
git checkout -b feature/my-feature-name
```

### Step 2: Make Changes
```bash
# Edit files
# Add tests
# Update dependencies if needed
```

### Step 3: Test Locally
```bash
python -m pytest -v
docker build -t app:test .
```

### Step 4: Commit & Push
```bash
git add .
git commit -m "feat: describe your feature"
git push origin feature/my-feature-name
```

### Step 5: Create Pull Request
```
Open GitHub > Create PR > Request reviewers
Wait for CI/CD pipeline to complete
```

### Step 6: Merge to Main
```
GitHub UI > Merge PR
```

**❌ IMPORTANT:** Don't merge if pipeline fails. Fix issues first.

### Step 7: Monitor Deployment
```bash
# Option A: GitHub Actions
open https://github.com/kanini/propeliq/actions

# Option B: Cloud Run
gcloud run services list --region us-central1
```

---

## Pipeline Monitoring

### Check Pipeline Status

```bash
# View recent workflow runs
gh run list --repo kanini/propeliq --limit 10

# View specific run details
gh run view <run-id> --repo kanini/propeliq

# Stream logs for a specific job
gh run view <run-id> --repo kanini/propeliq --log
```

### Verify Deployment

```bash
# Check dev service
curl -s https://app-service-dev-XXXXXXXXX.run.app/health | jq .

# Check prod service (requires auth)
TOKEN=$(gcloud auth print-identity-token)
curl -s -H "Authorization: Bearer $TOKEN" \
  https://app-service-XXXXXXXXX.run.app/health | jq .
```

### View Logs

```bash
# GitHub Actions logs (browser)
open https://github.com/kanini/propeliq/actions

# Cloud Run logs
gcloud run services logs read app-service-dev --limit 50

# Cloud Logging (all logs)
gcloud logging read "resource.type=cloud_run_revision" --limit 100 --format json
```

---

## Emergency Procedures

### URGENT: Pipeline Stuck/Failed

**Action:** Check GitHub Actions, then GCP services

```bash
# 1. Check last workflow run
gh run list --repo kanini/propeliq --limit 1

# 2. View detailed logs
gh run view <run-id> --repo kanini/propeliq --log

# 3. Check Cloud Run services
gcloud run services list --region us-central1

# 4. Check service errors
gcloud run services logs read app-service-dev \
  --filter="severity >= ERROR" \
  --limit 20
```

### URGENT: Need to Rollback

**Option 1: Revert Last Commit (Recommended)**
```bash
# Get last commit
git log --oneline -n 5

# Revert the bad commit
git revert <bad-commit-sha>

# Push (automatic redeploy)
git push origin main

# Monitor deployment
open https://github.com/kanini/propeliq/actions
```

**Option 2: Redeploy Previous Image**
```bash
# List previous images
gcloud artifacts docker images list \
  us-central1-docker.pkg.dev/akhila-gcp-123-493309/app-images

# Deploy specific image
gcloud run deploy app-service-dev \
  --image us-central1-docker.pkg.dev/akhila-gcp-123-493309/app-images/app:<previous-sha> \
  --region us-central1 \
  --allow-unauthenticated
```

### URGENT: GCP Service Account Deleted

**Action:** Re-run bootstrap script

```bash
bash scripts/gcp-cicd-bootstrap.sh

# Verify
gcloud iam service-accounts list \
  --filter="email:github-deployer@*"
```

### URGENT: GitHub Actions Can't Authenticate

**Action:** Check WIF configuration

```bash
# Verify provider exists
gcloud iam workload-identity-pools providers list \
  --location global

# Check service account bindings
gcloud iam service-accounts get-iam-policy \
  github-deployer@akhila-gcp-123-493309.iam.gserviceaccount.com

# If missing, re-add principal set
gcloud iam service-accounts add-iam-policy-binding \
  github-deployer@akhila-gcp-123-493309.iam.gserviceaccount.com \
  --role roles/iam.workloadIdentityUser \
  --member "principalSet://iam.googleapis.com/projects/828956650755/locations/global/workloadIdentityPools/github-pool/attribute.repository/kanini/propeliq"
```

---

## Common Commands

### Git Operations

```bash
# Create feature branch
git checkout -b feature/feature-name

# View recent commits
git log --oneline -n 10

# Sync with main
git fetch origin
git rebase origin/main

# Undo local changes
git restore <file>

# Interactive rebase (last 3 commits)
git rebase -i HEAD~3
```

### GCP Operations

```bash
# Set project
gcloud config set project akhila-gcp-123-493309

# List Cloud Run services
gcloud run services list

# Deploy service (manual)
bash scripts/deploy-cloudrun-basic.sh app-service-dev true

# View service details
gcloud run services describe app-service-dev

# View logs (real-time)
gcloud run services logs read app-service-dev --follow

# SSH into container (not directly, but via debug container)
gcloud run services update app-service-dev --revision-suffix debug
```

### Docker Operations

```bash
# Build image
docker build -t app:test .

# Run locally
docker run -p 8080:8080 app:test

# Test endpoints
curl http://localhost:8080/health
curl -X POST http://localhost:8080/api/prompt \
  -H "Content-Type: application/json" \
  -d '{"prompt": "hello"}'

# View image details
docker inspect app:test
```

### Python Operations

```bash
# Run unit tests
python -m pytest -v

# Run with coverage
python -m pytest --cov=. --cov-report=html

# Run specific test
python -m pytest tests/test_api.py::test_health_check -v

# Install dependencies
pip install -r requirements.txt

# Freeze current environment
pip freeze > requirements.txt
```

### Terraform Operations

```bash
# Initialize Terraform
cd infra
terraform init

# Validate configuration
terraform validate

# Plan changes
terraform plan -out=tfplan

# Apply changes
terraform apply tfplan

# Show current state
terraform show

# Get outputs
terraform output -raw service_url_dev
```

### GitHub CLI Operations

```bash
# List workflows
gh workflow list --repo kanini/propeliq

# List recent runs
gh run list --repo kanini/propeliq

# View specific run
gh run view <run-id> --repo kanini/propeliq

# Re-run a failed workflow
gh run rerun <run-id> --repo kanini/propeliq

# View logs
gh run logs <run-id> --repo kanini/propeliq

# Create issue
gh issue create --title "Bug: ..." --body "..."

# Create PR (requires web UI typically)
gh pr create --title "feat: ..." --body "..."
```

---

## Troubleshooting Quick Links

| Problem | Solution |
|---------|----------|
| pytest fails locally | Run `pip install -r requirements-dev.txt` first |
| Docker build fails | Verify `requirements.txt` exists and is valid |
| Pipeline never starts | Check GitHub branch protection rules |
| Deploy fails with auth error | Re-run `bash scripts/gcp-cicd-bootstrap.sh` |
| Cloud Run service 500 error | Check `gcloud run services logs read app-service-dev` |
| Can't push to main | Ensure PR is merged, status checks pass |

---

## Deployment Status Indicators

### ✅ Healthy

- GitHub Actions: All jobs green
- Cloud Run: Services running (check mark in console)
- Health checks: Returning 200 OK
- Logs: No ERROR or CRITICAL level entries

### ⚠️ Warning

- Pipeline jobs taking 2x longer than usual
- Health checks returning 200 but with latency
- Minor ERROR entries in logs (non-critical)
- CPU/Memory utilization > 70%

### 🚨 Critical

- Any job failing in pipeline
- Health check returning non-200 status
- Cloud Run service showing "Error" state
- Multiple ERROR or CRITICAL entries in logs
- Gitleaks/Trivy/Checkov failing

**Action:** If critical, follow [Emergency Procedures](#emergency-procedures)

---

## Key Metrics to Monitor

### Performance

- **Pipeline Duration:** Target < 5 minutes
- **Deployment Duration:** Target < 2 minutes  
- **Health Check Latency:** Target < 100ms
- **API Response Time:** Target < 500ms

### Reliability

- **Pipeline Success Rate:** Target > 99%
- **Deployment Success Rate:** Target > 99%
- **Service Uptime:** Target > 99.95%
- **Error Rate:** Target < 0.1%

### Security

- **Secrets Found in Scan:** Target = 0
- **Vulnerabilities Found:** Target = 0 (CRITICAL/HIGH)
- **IaC Compliance Failures:** Target = 0 (CRITICAL)

---

## Support & Escalation

### Level 1: Self-Help

- Check [Full Documentation](PIPELINE_DOCUMENTATION.md)
- Search GitHub issues: https://github.com/kanini/propeliq/issues
- Review recent commits: `git log --oneline -n 20`

### Level 2: Team Support

- Post in team Slack channel: #propeliq-devops
- Create GitHub issue with details
- Review [Common Commands](#common-commands) above

### Level 3: Escalation

- Contact DevOps lead
- Report security issue: GitHub Security Advisory
- Fire page: (contact details)

---

## Appendix: One-Liners

**Deploy manually:**
```bash
bash scripts/deploy-cloudrun-basic.sh app-service-dev true && sleep 30 && curl https://app-service-dev-*.run.app/health
```

**Check all services healthy:**
```bash
gcloud run services list --output=json | jq '.[].status.conditions[] | select(.status != "True")'
```

**View last 10 deployments:**
```bash
gcloud run services list --region us-central1 && gcloud run revisions list --service app-service-dev --limit 10
```

**Force redeploy latest code:**
```bash
git push origin main --force-with-lease && sleep 120 && gcloud run services describe app-service-dev --format="value(status.url)"
```

**Test API endpoint:**
```bash
curl -X POST https://app-service-dev-*.run.app/api/prompt \
  -H "Content-Type: application/json" \
  -d '{"prompt": "test message"}'
```

---

**Last Updated:** 2026-04-17  
**Next Review:** 2026-05-17  
For detailed documentation, see [PIPELINE_DOCUMENTATION.md](PIPELINE_DOCUMENTATION.md)
