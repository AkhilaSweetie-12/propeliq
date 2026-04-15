# PropelIQ CI/CD Runner — Custom Docker Image

Custom base image for GitHub Actions workflows containing all tools required by the PropelIQ development pipeline.

## Included Tools

| Tool | Version | Purpose |
|------|---------|---------|
| **Node.js** | 20.x | MCP integrations, npm packages, TypeScript |
| **.NET SDK** | 9.0 | ASP.NET Core builds, C# compilation, `dotnet` CLI |
| **Terraform** | 1.9.8 | Infrastructure-as-Code provisioning |
| **Playwright** | 1.49.1 | E2E / UI testing (Chromium pre-installed) |
| **GitHub CLI** | latest | PR operations, release management |
| **Azure CLI** | latest | Azure resource management, ACR login |
| **TypeScript** | latest | Type checking, transpilation |
| **MCP Tools** | latest | `@modelcontextprotocol/server-sequential-thinking`, `@playwright/mcp` |

## Registry

Images are published to **GitHub Container Registry**:

```
ghcr.io/<org>/propeliq-runner:<tag>
```

## Tags

| Tag Pattern | Description |
|-------------|-------------|
| `latest` | Latest build from the default branch |
| `<sha>` | Git commit SHA (short) |
| `<branch>` | Branch name |
| `YYYYMMDD-<sha>` | Date-stamped build |

## Usage

### In a GitHub Actions workflow

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    container:
      image: ghcr.io/<org>/propeliq-runner:latest
      credentials:
        username: ${{ github.actor }}
        password: ${{ secrets.GITHUB_TOKEN }}
    steps:
      - uses: actions/checkout@v4
      - run: dotnet build
      - run: npm ci && npx playwright test
      - run: terraform plan
```

### Calling the reusable build workflow

```yaml
name: Build Runner Image

on:
  push:
    paths:
      - '.github/workflows/shared-services/tech-stack/docker/**'
  workflow_dispatch:

jobs:
  build-runner:
    uses: ./.github/workflows/shared-services/tech-stack/docker/docker-build-push.yml
    with:
      image_name: propeliq-runner
      push: true
    secrets: inherit
```

### Local build

```bash
docker build \
  -t propeliq-runner:local \
  -f .github/workflows/shared-services/tech-stack/docker/Dockerfile \
  .github/workflows/shared-services/tech-stack/docker/

docker run -it propeliq-runner:local
```

## Build Arguments

| Argument | Default | Description |
|----------|---------|-------------|
| `NODE_VERSION` | `20` | Node.js major version |
| `DOTNET_VERSION` | `9.0` | .NET SDK channel |
| `TERRAFORM_VERSION` | `1.9.8` | Terraform release version |
| `PLAYWRIGHT_VERSION` | `1.49.1` | Playwright npm package version |

Override at build time:

```bash
docker build \
  --build-arg NODE_VERSION=22 \
  --build-arg DOTNET_VERSION=9.0 \
  -t propeliq-runner:custom \
  -f .github/workflows/shared-services/tech-stack/docker/Dockerfile \
  .github/workflows/shared-services/tech-stack/docker/
```

## Security

- Runs as non-root user `runner` (UID 1001)
- OCI labels for provenance tracking
- Build attestation generated on push via `actions/attest-build-provenance`
- GHA build cache for reproducible, fast rebuilds
