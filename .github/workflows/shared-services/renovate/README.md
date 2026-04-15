# Renovate Container Setup Guide

This guide explains how to set up and run the Renovate container for automated dependency management.

## Overview

Renovate is a tool that automatically updates dependencies in your repositories. This setup provides a containerized deployment with generic container image detection capabilities.

## Prerequisites

- Docker installed (for local development)
- Kubernetes cluster (for production deployment)
- GitHub Personal Access Token or GitHub App
- Container registry access (if using custom images)

## Environment Variables

### Required Variables

```bash
# GitHub Configuration
RENOVATE_TOKEN=github_pat_xxxxxxxxxxxx
RENOVATE_PLATFORM=github
RENOVATE_ENDPOINT=https://api.github.com
RENOVATE_REPOSITORY=your-username/your-repo

# Optional: For SSH operations
RENOVATE_GIT_PRIVATE_KEY=-----BEGIN OPENSSH PRIVATE KEY-----
...
-----END OPENSSH PRIVATE KEY-----
```

### Optional Variables

```bash
# Logging
RENOVATE_LOG_LEVEL=info
LOG_LEVEL=info

# Repository Configuration
RENOVATE_AUTODISCOVER=true
RENOVATE_AUTODISCOVER_FILTER=

# Scheduling
RENOVATE_SCHEDULE=before 6am on monday
RENOVATE_TIMEZONE=UTC

# Automation
RENOVATE_AUTOMERGE_DOCKER=true
RENOVATE_AUTOMERGE_NODEJS=true
RENOVATE_AUTOMERGE_PYTHON=true
```

## Setup Options

### Option 1: Docker Compose (Recommended for Local/Small Scale)

1. **Create environment file:**
```bash
cp .env.example .env
# Edit .env with your configuration
```

2. **Run with Docker Compose:**
```bash
docker-compose up -d
```

3. **View logs:**
```bash
docker-compose logs -f renovate
```

### Option 2: Docker Run (Direct Container)

```bash
docker run --rm \
  -e RENOVATE_TOKEN=your_github_token \
  -e RENOVATE_PLATFORM=github \
  -e RENOVATE_ENDPOINT=https://api.github.com \
  -e RENOVATE_REPOSITORY=your-username/your-repo \
  -v $(pwd)/renovate.json:/usr/src/app/renovate.json \
  ghcr.io/renovatebot/renovate:38
```

### Option 3: Kubernetes (Production)

1. **Create namespace:**
```bash
kubectl create namespace renovate
```

2. **Create secret:**
```bash
kubectl create secret generic renovate-secrets \
  --from-literal=RENOVATE_TOKEN=your_github_token \
  --namespace=renovate
```

3. **Apply manifests:**
```bash
kubectl apply -f k8s/ --namespace=renovate
```

## Configuration Files

### Main Configuration (`renovate.json`)
- Contains core Renovate settings
- Defines package rules and grouping
- Configures automation and scheduling

### Group Configuration (`renovate-group.yml`)
- Defines dependency groups
- Sets update priorities
- Configures schedules per group

### Container Configuration (`container/config.js`)
- Environment variable handling
- Dynamic configuration
- Container-specific settings

### Helm Values (`values.yaml`)
- Kubernetes deployment configuration
- Resource limits and requests
- Helm chart customization

## Container Image Detection

This setup includes generic container image detection across:

- **Dockerfiles**: `FROM nginx:1.21`
- **Docker Compose**: `image: redis:6.2`
- **Kubernetes**: `image: nginx:1.21`
- **Terraform**: `image = "nginx:1.21"`
- **Shell Scripts**: `docker pull nginx:1.21`
- **Programming Languages**: `image = "nginx:1.21"`
- **JSON Files**: `"image": "nginx:1.21"`

## Monitoring and Logging

### Log Levels
- `error`: Only errors
- `warn`: Warnings and errors
- `info`: General information (default)
- `debug`: Detailed debugging

### Health Checks
The container includes health checks for:
- Liveness probe: Every 10 seconds
- Readiness probe: Every 5 seconds
- Startup probe: First 5 minutes

## Security Considerations

1. **Token Security**: Never commit tokens to version control
2. **Network Policies**: Restrict network access in production
3. **Resource Limits**: Set appropriate CPU/memory limits
4. **Image Scanning**: Scan container images for vulnerabilities

## Troubleshooting

### Common Issues

1. **Authentication Errors**
   - Check GitHub token permissions
   - Verify token hasn't expired
   - Ensure proper scopes

2. **Permission Errors**
   - Check repository access
   - Verify write permissions
   - Check organization policies

3. **Configuration Errors**
   - Validate JSON syntax
   - Check file paths
   - Verify environment variables

### Debug Commands

```bash
# Check container logs
docker logs renovate-container

# Test configuration
docker run --rm -v $(pwd)/renovate.json:/usr/src/app/renovate.json \
  ghcr.io/renovatebot/renovate:38 renovate --help

# Validate configuration
docker run --rm -v $(pwd)/renovate.json:/usr/src/app/renovate.json \
  ghcr.io/renovatebot/renovate:38 renovate --validate-config
```

## Maintenance

### Regular Tasks

1. **Update Container Image**: Monthly
2. **Review Configuration**: Quarterly
3. **Audit Dependencies**: Bi-annually
4. **Backup Configuration**: Before major changes

### Scaling

For large deployments:
- Use Kubernetes HorizontalPodAutoscaler
- Implement rate limiting
- Consider multiple instances
- Use Redis for caching

## Integration Examples

### GitHub Actions Integration
The workflow automatically runs Renovate on:
- Daily schedule (2 AM UTC)
- Manual dispatch
- Push to main/master branches
- Pull request updates

### CI/CD Pipeline Integration
Add to your pipeline:
```yaml
- name: Run Renovate
  uses: docker://ghcr.io/renovatebot/renovate:38
  env:
    RENOVATE_TOKEN: ${{ secrets.RENOVATE_TOKEN }}
```

## Support

- **Documentation**: https://docs.renovatebot.com
- **Issues**: https://github.com/renovatebot/renovate/issues
- **Discussions**: https://github.com/renovatebot/renovate/discussions
- **Community**: https://discord.gg/renovate

## Advanced Configuration

### Custom Managers
Add custom regex managers in `renovate.json`:
```json
{
  "regexManagers": [
    {
      "fileMatch": ["*.custom"],
      "matchStrings": ["custom_dep:\\s*(?<depName>[^:]+):(?<currentValue>.+)"],
      "datasourceTemplate": "docker"
    }
  ]
}
```

### Private Registries
Configure private container registries:
```json
{
  "hostRules": [
    {
      "hostType": "docker",
      "domain": "private-registry.com",
      "username": "your-username",
      "password": "your-password"
    }
  ]
}
```

### Organization-Level Setup
For organization-wide deployment:
1. Create GitHub App
2. Configure organization permissions
3. Use organization-level secrets
4. Implement centralized configuration
