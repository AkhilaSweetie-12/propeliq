# =============================================================================
# PropelIQ-Copilot — Project Image
# =============================================================================
# Extends the CI/CD runner base image with the PropelIQ framework files.
# Base image: ghcr.io/<org>/propeliq-runner (built from
#   .github/workflows/shared-services/tech-stack/docker/Dockerfile)
#
# For local builds without the registry image, build the base first:
#   docker build -t propeliq-runner:local \
#     -f .github/workflows/shared-services/tech-stack/docker/Dockerfile \
#     .github/workflows/shared-services/tech-stack/docker/
# =============================================================================

ARG RUNNER_IMAGE=propeliq-runner:local
FROM ${RUNNER_IMAGE}

USER root

WORKDIR /app

# Copy framework files
COPY .github/ ./.github/
COPY .propel/ ./.propel/
COPY .vscode/ ./.vscode/
COPY infra/ ./infra/
COPY README.md ./

# Fix ownership for the runner user
RUN chown -R runner:runner /app

USER runner

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD node --version && terraform version || exit 1

ENTRYPOINT ["/bin/bash"]
