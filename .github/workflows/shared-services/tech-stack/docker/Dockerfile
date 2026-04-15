# =============================================================================
# PropelIQ CI/CD Runner — Custom Base Image
# =============================================================================
# A self-contained GitHub Actions runner image with all tools required by the
# PropelIQ development pipeline: Node.js, .NET, Terraform, Playwright, and
# supporting CLI utilities.
#
# Target registry : GitHub Container Registry (ghcr.io)
# Rebuild trigger : shared-services/tech-stack/docker/** changes
# =============================================================================

# ---------------------------------------------------------------------------
# Build Arguments
# ---------------------------------------------------------------------------
ARG NODE_VERSION=20
ARG DOTNET_VERSION=9.0
ARG TERRAFORM_VERSION=1.9.8
ARG PLAYWRIGHT_VERSION=1.49.1

# ---------------------------------------------------------------------------
# Stage 1 — Base OS & system packages
# ---------------------------------------------------------------------------
FROM ubuntu:22.04 AS base

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    wget \
    git \
    unzip \
    jq \
    gnupg \
    lsb-release \
    software-properties-common \
    apt-transport-https \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------------------
# Stage 2 — Install Node.js
# ---------------------------------------------------------------------------
FROM base AS node-installer

ARG NODE_VERSION

RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && npm install -g npm@latest \
    && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------------------
# Stage 3 — Install .NET SDK
# ---------------------------------------------------------------------------
FROM base AS dotnet-installer

ARG DOTNET_VERSION

RUN wget -q https://dot.net/v1/dotnet-install.sh -O dotnet-install.sh \
    && chmod +x dotnet-install.sh \
    && ./dotnet-install.sh --channel ${DOTNET_VERSION} --install-dir /usr/share/dotnet \
    && rm dotnet-install.sh

# ---------------------------------------------------------------------------
# Stage 4 — Install Terraform
# ---------------------------------------------------------------------------
FROM base AS terraform-installer

ARG TERRAFORM_VERSION

RUN curl -fsSL "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip" -o terraform.zip \
    && unzip terraform.zip -d /usr/local/bin/ \
    && rm terraform.zip

# ---------------------------------------------------------------------------
# Stage 5 — Final runner image
# ---------------------------------------------------------------------------
FROM base AS runner

ARG NODE_VERSION
ARG PLAYWRIGHT_VERSION

# --- Node.js ---------------------------------------------------------------
COPY --from=node-installer /usr/bin/node /usr/bin/node
COPY --from=node-installer /usr/bin/npm /usr/bin/npm
COPY --from=node-installer /usr/bin/npx /usr/bin/npx
COPY --from=node-installer /usr/lib/node_modules /usr/lib/node_modules

RUN ln -sf /usr/lib/node_modules/npm/bin/npm-cli.js /usr/bin/npm \
    && ln -sf /usr/lib/node_modules/npm/bin/npx-cli.js /usr/bin/npx

# --- .NET SDK ---------------------------------------------------------------
COPY --from=dotnet-installer /usr/share/dotnet /usr/share/dotnet
ENV DOTNET_ROOT=/usr/share/dotnet
ENV PATH="${PATH}:/usr/share/dotnet"
RUN ln -s /usr/share/dotnet/dotnet /usr/bin/dotnet

# --- Terraform --------------------------------------------------------------
COPY --from=terraform-installer /usr/local/bin/terraform /usr/local/bin/terraform

# --- GitHub CLI --------------------------------------------------------------
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update \
    && apt-get install -y --no-install-recommends gh \
    && rm -rf /var/lib/apt/lists/*

# --- Playwright + Chromium --------------------------------------------------
RUN npm install -g playwright@${PLAYWRIGHT_VERSION} \
    && npx playwright install --with-deps chromium \
    && npm cache clean --force

# --- Additional npm tools used by MCP integrations --------------------------
RUN npm install -g \
    @modelcontextprotocol/server-sequential-thinking@latest \
    @playwright/mcp@latest \
    typescript \
    && npm cache clean --force

# --- Azure CLI (optional — matches MCP server on Azure) ---------------------
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash \
    && rm -rf /var/lib/apt/lists/*

# --- Labels (OCI image spec) ------------------------------------------------
LABEL org.opencontainers.image.title="PropelIQ CI/CD Runner" \
      org.opencontainers.image.description="Custom CI/CD runner with Node.js, .NET 9, Terraform, Playwright, GitHub CLI, and Azure CLI" \
      org.opencontainers.image.source="https://github.com/kanini/propeliq" \
      org.opencontainers.image.vendor="Kanini"

# --- Smoke-test every tool ---------------------------------------------------
RUN echo "=== Tool versions ===" \
    && node --version \
    && npm --version \
    && dotnet --version \
    && terraform version \
    && gh --version \
    && az --version --output table \
    && npx playwright --version \
    && echo "=== All tools verified ==="

# --- Non-root user for pipeline jobs ----------------------------------------
RUN groupadd --gid 1001 runner \
    && useradd --uid 1001 --gid runner --shell /bin/bash --create-home runner

USER runner
WORKDIR /home/runner

CMD ["bash"]
