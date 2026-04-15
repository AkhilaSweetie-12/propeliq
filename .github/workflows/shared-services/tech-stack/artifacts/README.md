# Artifact Publish

Reusable workflow for publishing Docker images, Helm charts, npm packages, and generic artifacts to registries.

## Structure

```
artifacts/
├── artifact-publish.yml   ← Multi-type artifact publish workflow
└── README.md
```

## Usage

### Docker image

```yaml
jobs:
  publish-docker:
    uses: ./.github/workflows/shared-services/tech-stack/artifacts/artifact-publish.yml
    with:
      artifact_type: docker
      docker_registry: ghcr.io
      image_name: ${{ github.repository }}/my-app
      docker_context: .
      docker_file: ./Dockerfile
      push: true
    secrets: inherit
```

### Helm chart

```yaml
jobs:
  publish-helm:
    uses: ./.github/workflows/shared-services/tech-stack/artifacts/artifact-publish.yml
    with:
      artifact_type: helm
      helm_chart_path: ./charts/app
      helm_registry: ghcr.io/${{ github.repository_owner }}/charts
      push: true
    secrets: inherit
```

### npm package

```yaml
jobs:
  publish-npm:
    uses: ./.github/workflows/shared-services/tech-stack/artifacts/artifact-publish.yml
    with:
      artifact_type: npm
      npm_registry: https://npm.pkg.github.com
      npm_scope: '@myorg'
      push: true
    secrets: inherit
```

### Generic artifact (Artifactory)

```yaml
jobs:
  publish-generic:
    uses: ./.github/workflows/shared-services/tech-stack/artifacts/artifact-publish.yml
    with:
      artifact_type: generic
      generic_source_path: ./dist/app.tar.gz
      generic_target_repo: my-generic-repo
      artifactory_url: https://artifactory.example.com
      push: true
    secrets: inherit
```

## Inputs

| Input | Required | Description |
|-------|----------|-------------|
| `artifact_type` | Yes | `docker`, `helm`, `npm`, or `generic` |
| `version` | No | Auto-detected from git tags if empty |
| `push` | No | `true` to publish, `false` for build-only |
| `docker_registry` | No | Default: `ghcr.io` |
| `helm_registry` | No | OCI registry for Helm charts |
| `npm_registry` | No | Default: GitHub Packages |
| `artifactory_url` | No | For generic artifact uploads |

## Outputs

| Output | Description |
|--------|-------------|
| `artifact_version` | Published version string |
| `artifact_digest` | Docker image digest (Docker only) |

## Required Permissions

```yaml
permissions:
  contents: read
  packages: write
  id-token: write
  attestations: write
```
