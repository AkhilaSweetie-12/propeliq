# Security Scan Pipeline

Reusable GitHub Actions workflow for comprehensive security scanning. Covers IaC security, secret detection, dependency vulnerabilities, SAST, and container image scanning.

## Structure

```
security-scan/
├── security-scan-pipeline.yml    ← Reusable workflow: 5 scan jobs + summary
└── README.md
```

## Scan Jobs

| Job | Scanners | What It Checks |
|-----|----------|---------------|
| **iac-scan** | tfsec, checkov, KICS | Terraform misconfigurations, CIS benchmarks, security best practices |
| **secret-scan** | gitleaks, trufflehog | Hardcoded secrets, API keys, tokens in git history |
| **dependency-scan** | Trivy FS, npm audit, dotnet audit | Known CVEs in dependencies |
| **sast** | Semgrep | Code-level vulnerabilities (OWASP Top 10, injection, XSS, etc.) |
| **container-scan** | Trivy image | OS and library vulnerabilities in container images |

## SARIF Integration

All scanners upload results in SARIF format to GitHub's **Security → Code scanning** tab when `upload_sarif: true` (default). Findings appear as inline annotations on PRs.

## Usage

### Full scan on every PR

```yaml
name: Security Scan

on:
  pull_request:
    branches: [main]

jobs:
  security:
    uses: ./.github/workflows/shared-services/security/security-scan/security-scan-pipeline.yml
    with:
      infra_directory: infra
      enable_iac_scan: true
      enable_secret_scan: true
      enable_dependency_scan: true
      enable_sast: true
      severity_threshold: HIGH
      fail_on_findings: true
    secrets: inherit
```

### IaC scan only

```yaml
jobs:
  iac:
    uses: ./.github/workflows/shared-services/security/security-scan/security-scan-pipeline.yml
    with:
      infra_directory: infra
      enable_iac_scan: true
      enable_secret_scan: false
      enable_dependency_scan: false
      enable_sast: false
    secrets: inherit
```

### With container image scan

```yaml
jobs:
  security:
    uses: ./.github/workflows/shared-services/security/security-scan/security-scan-pipeline.yml
    with:
      enable_iac_scan: true
      enable_secret_scan: true
      enable_dependency_scan: true
      enable_sast: true
      enable_container_scan: true
      container_image: ghcr.io/${{ github.repository_owner }}/propeliq-runner:latest
      severity_threshold: HIGH
    secrets: inherit
```

## Inputs

| Input | Type | Default | Description |
|-------|------|---------|-------------|
| `runner_image` | string | `ghcr.io/<org>/propeliq-runner:latest` | Custom runner image |
| `infra_directory` | string | `infra` | Terraform code path |
| `source_directory` | string | `.` | Application source path |
| `enable_iac_scan` | boolean | `true` | Run IaC scanning |
| `enable_secret_scan` | boolean | `true` | Run secret detection |
| `enable_dependency_scan` | boolean | `true` | Run dependency audit |
| `enable_sast` | boolean | `true` | Run SAST |
| `enable_container_scan` | boolean | `false` | Run container scan |
| `container_image` | string | `''` | Image to scan |
| `severity_threshold` | string | `HIGH` | Minimum severity to report |
| `fail_on_findings` | boolean | `true` | Fail pipeline on findings |
| `upload_sarif` | boolean | `true` | Upload to GitHub Security tab |

## Semgrep Rule Sets

The SAST job runs these Semgrep rule sets:
- `p/default` — General best practices
- `p/javascript` / `p/typescript` — JS/TS specific
- `p/csharp` — .NET specific
- `p/terraform` — IaC specific
- `p/secrets` — Hardcoded credentials
- `p/owasp-top-ten` — OWASP Top 10

## Artifacts

| Artifact | Contents | Retention |
|----------|----------|-----------|
| `iac-scan-results` | tfsec, checkov, KICS SARIF/JSON | 30 days |
| `dependency-scan-results` | Trivy, npm, dotnet SARIF/JSON | 30 days |
| `container-scan-results` | Trivy container SARIF | 30 days |
