# GCP CI/CD Setup (GitHub Actions + Cloud Run)

This setup assumes:
- Project ID: akhila-gcp-123-493309
- No existing deployment resources
- Hosting target: Cloud Run
- Region: us-central1

## 1) Bootstrap GCP resources
Run:

```bash
bash scripts/gcp-cicd-bootstrap.sh
```

Before running, update these in scripts/gcp-cicd-bootstrap.sh:
- GITHUB_ORG
- GITHUB_REPO

## 2) Configure GitHub Environments
Create environments:
- dev
- prod

Protection rules:
- dev: optional reviewer
- prod: required reviewers (2)
- Restrict deployment branches to main for prod

## 3) Update workflow placeholders
Edit .github/workflows/gcp-cloudrun-ci-cd.yml:
- SERVICE_NAME
- WORKLOAD_IDENTITY_PROVIDER
- DEPLOY_SA

## 4) Required repository settings
- Enable branch protection on main
- Require status checks:
  - validate
  - security
  - build-and-push
- Disallow force pushes on main

## 5) Security controls included
- OIDC auth (no long-lived keys)
- Secret scanning with gitleaks
- Vulnerability scanning with trivy
- Environment-gated production deploy
- Least privilege token permissions at workflow level

## 6) App-specific commands
Current workflow assumes Docker build from Dockerfile at repo root.
Python defaults in validate job:
- `pip install -r requirements.txt` (if present)
- `pip install -r requirements-dev.txt` (if present)
- `pytest -q` when tests exist

If your app uses Poetry, Pipenv, or a custom test command, update the validate job in the workflow before image build.
