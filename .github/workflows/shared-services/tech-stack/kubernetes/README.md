# Kubernetes Workflows

Reusable GitHub Actions workflows for GKE deployment, health checks, rollback, and ephemeral PR environments.

## Structure

```
kubernetes/
├── k8s-deploy.yml            ← Deploy via Helm, kubectl, or Kustomize
├── helm-lint.yml             ← Helm lint, template render, kubeconform validation
├── health-check.yml          ← Pod/service/HTTP health checks + smoke tests
├── rollback.yml              ← Rollback via kubectl, Helm, or Terraform
├── environment-manager.yml   ← Ephemeral PR environments with TTL
├── charts/
│   └── app/                  ← Starter Helm chart template
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
│           ├── _helpers.tpl
│           ├── deployment.yaml
│           ├── service.yaml
│           ├── ingress.yaml
│           ├── hpa.yaml
│           ├── serviceaccount.yaml
│           ├── configmap.yaml
│           ├── secret.yaml
│           └── pdb.yaml
└── README.md
```

## Workflows

### k8s-deploy.yml

Deploys to a GKE cluster using Helm, kubectl, or Kustomize.

```yaml
jobs:
  deploy:
    uses: ./.github/workflows/shared-services/tech-stack/kubernetes/k8s-deploy.yml
    with:
      cluster_name: my-gke-cluster
      cluster_zone: us-central1-a
      gcp_project_id: ${{ vars.GCP_PROJECT_ID }}
      namespace: production
      deploy_method: helm                # helm | kubectl | kustomize
      helm_chart_path: ./charts/app
      image_tag: ${{ github.sha }}
      environment: production
      wait_for_rollout: true
      rollout_timeout: 5m
    secrets: inherit
```

**Key inputs:**
- **deploy_method** — `helm`, `kubectl`, or `kustomize`
- **dry_run** — preview without applying
- **helm_set_values** — comma-separated `key=value` pairs for `--set`

### health-check.yml

Validates deployment health: pod status, service endpoints, HTTP health endpoint, and optional smoke tests.

```yaml
jobs:
  verify:
    needs: [deploy]
    uses: ./.github/workflows/shared-services/tech-stack/kubernetes/health-check.yml
    with:
      cluster_name: my-gke-cluster
      cluster_zone: us-central1-a
      gcp_project_id: ${{ vars.GCP_PROJECT_ID }}
      namespace: production
      health_endpoint: https://app.example.com/health
      expected_status_code: 200
      retries: 5
      retry_interval: 15
      check_pods: true
      check_services: true
      rollback_on_failure: true
      smoke_test_script: ./tests/smoke.sh
    secrets: inherit
```

**Outputs:** `healthy` (true/false) — use in downstream jobs to gate promotion.

### rollback.yml

Rolls back a failed deployment using kubectl undo, Helm rollback, or Terraform refresh.

```yaml
jobs:
  rollback:
    uses: ./.github/workflows/shared-services/tech-stack/kubernetes/rollback.yml
    with:
      cluster_name: my-gke-cluster
      cluster_zone: us-central1-a
      gcp_project_id: ${{ vars.GCP_PROJECT_ID }}
      namespace: production
      rollback_method: helm              # kubectl | helm | terraform
      helm_release_name: my-app
      helm_revision: 0                   # 0 = previous revision
      verify_after_rollback: true
    secrets: inherit
```

### helm-lint.yml

Validates Helm charts: linting, template rendering, kubeconform manifest validation, and metadata checks.

```yaml
jobs:
  lint:
    uses: ./.github/workflows/shared-services/tech-stack/kubernetes/helm-lint.yml
    with:
      chart_path: ./charts/app
      strict: true
      kube_version: '1.29.0'
      enable_template_test: true
      enable_kubeconform: true
    secrets: inherit
```

**Key inputs:**
- **strict** — fail on warnings
- **kube_version** — target K8s version for schema validation
- **values_files** — comma-separated values files to lint against
- **additional_helm_repos** — `name=url` pairs for dependency repos

### environment-manager.yml

Creates, updates, or destroys ephemeral K8s environments for PRs. Includes resource quotas, limit ranges, TTL annotations, and PR comments with environment URLs.

```yaml
# On PR open/sync
jobs:
  pr-env:
    uses: ./.github/workflows/shared-services/tech-stack/kubernetes/environment-manager.yml
    with:
      action: create                      # create | update | destroy
      cluster_name: my-gke-cluster
      cluster_zone: us-central1-a
      gcp_project_id: ${{ vars.GCP_PROJECT_ID }}
      deploy_method: helm
      image_tag: ${{ github.sha }}
      ttl_hours: 48
    secrets: inherit
```

**Outputs:** `namespace`, `environment_url`

## Required Variables

| Variable | Description |
|----------|-------------|
| `GKE_CLUSTER_NAME` | GKE cluster name |
| `GKE_CLUSTER_ZONE` | GKE cluster zone/region |
| `GCP_PROJECT_ID` | GCP project ID |
| `HEALTH_ENDPOINT` | Application health check URL |

## Required Secrets

| Secret | Description |
|--------|-------------|
| `GCP_WORKLOAD_IDENTITY_PROVIDER` | GCP Workload Identity provider |
| `GCP_SERVICE_ACCOUNT` | GCP service account email |

## Starter Helm Chart

The `charts/app/` directory contains a production-ready starter chart. Copy it into your project:

```bash
cp -r .github/workflows/shared-services/tech-stack/kubernetes/charts/app ./charts/app
```

Then customize `values.yaml` for your app:

```yaml
image:
  repository: ghcr.io/myorg/myapp
  tag: "1.0.0"

service:
  port: 80
  targetPort: 8080

ingress:
  enabled: true
  className: gce
  hosts:
    - host: myapp.example.com
      paths:
        - path: /
          pathType: Prefix

autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
```

**Included templates:** Deployment, Service, Ingress, HPA, ServiceAccount, ConfigMap, Secret, PodDisruptionBudget.

**Security defaults:** `runAsNonRoot`, `readOnlyRootFilesystem`, drops all capabilities.

## Pipeline Flow

```
PR opened/updated:
  environment-manager (create) -> health-check

PR closed/merged:
  environment-manager (destroy)

Push to main:
  k8s-deploy -> health-check -> (rollback on failure)
```
