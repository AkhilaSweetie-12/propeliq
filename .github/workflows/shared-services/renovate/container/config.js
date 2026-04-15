/**
 * Renovate Container Configuration
 * This file contains configuration for running Renovate in a container environment
 */

const config = {
  // Platform configuration
  platform: process.env.RENOVATE_PLATFORM || 'github',
  endpoint: process.env.RENOVATE_ENDPOINT || 'https://api.github.com',
  token: process.env.RENOVATE_TOKEN || process.env.GITHUB_TOKEN,
  
  // Repository configuration
  repositories: process.env.RENOVATE_REPOSITORIES 
    ? process.env.RENOVATE_REPOSITORIES.split(',').map(r => r.trim())
    : [],
  autodiscover: process.env.RENOVATE_AUTODISCOVER !== 'false',
  autodiscoverFilter: process.env.RENOVATE_AUTODISCOVER_FILTER || '',
  
  // Bot configuration
  username: process.env.RENOVATE_USERNAME || 'renovate[bot]',
  gitAuthor: process.env.RENOVATE_GIT_AUTHOR || 'renovate[bot] <29139614+renovate[bot]@users.noreply.github.com>',
  
  // Logging configuration
  logLevel: process.env.RENOVATE_LOG_LEVEL || process.env.LOG_LEVEL || 'info',
  logFile: process.env.RENOVATE_LOG_FILE || '/tmp/renovate.log',
  logFileLevel: process.env.RENOVATE_LOG_FILE_LEVEL || 'debug',
  
  // Onboarding configuration
  onboarding: process.env.RENOVATE_ONBOARDING === 'true',
  requireConfig: process.env.RENOVATE_REQUIRE_CONFIG !== 'false',
  
  // Dashboard configuration
  dependencyDashboard: process.env.RENOVATE_DEPENDENCY_DASHBOARD !== 'false',
  dependencyDashboardTitle: process.env.RENOVATE_DEPENDENCY_DASHBOARD_TITLE || 'Renovate Dashboard',
  dependencyDashboardLabels: process.env.RENOVATE_DEPENDENCY_DASHBOARD_LABELS 
    ? process.env.RENOVATE_DEPENDENCY_DASHBOARD_LABELS.split(',').map(l => l.trim())
    : ['renovate', 'dependencies'],
  
  // PR management configuration
  prConcurrentLimit: parseInt(process.env.RENOVATE_PR_CONCURRENT_LIMIT) || 10,
  prHourlyLimit: parseInt(process.env.RENOVATE_PR_HOURLY_LIMIT) || 2,
  branchConcurrentLimit: parseInt(process.env.RENOVATE_BRANCH_CONCURRENT_LIMIT) || 10,
  branchPrefix: process.env.RENOVATE_BRANCH_PREFIX || 'renovate/',
  rebaseWhen: process.env.RENOVATE_REBASE_WHEN || 'auto',
  rebaseLabel: process.env.RENOVATE_REBASE_LABEL || 'renovate/rebase',
  stopUpdatingLabel: process.env.RENOVATE_STOP_UPDATING_LABEL || 'renovate/stop-updating',
  
  // Labels and assignees
  labels: process.env.RENOVATE_LABELS 
    ? process.env.RENOVATE_LABELS.split(',').map(l => l.trim())
    : ['renovate', 'dependencies'],
  assignees: process.env.RENOVATE_ASSIGNEES 
    ? process.env.RENOVATE_ASSIGNEES.split(',').map(a => a.trim())
    : [],
  reviewers: process.env.RENOVATE_REVIEWERS 
    ? process.env.RENOVATE_REVIEWERS.split(',').map(r => r.trim())
    : [],
  
  // Schedule configuration
  schedule: process.env.RENOVATE_SCHEDULE 
    ? process.env.RENOVATE_SCHEDULE.split(',').map(s => s.trim())
    : ['before 6am on monday'],
  timezone: process.env.RENOVATE_TIMEZONE || 'UTC',
  
  // Semantic commits
  semanticCommits: process.env.RENOVATE_SEMANTIC_COMMITS === 'true' ? 'enabled' : 'disabled',
  semanticCommitType: process.env.RENOVATE_SEMANTIC_COMMIT_TYPE || 'chore',
  semanticCommitScope: process.env.RENOVATE_SEMANTIC_COMMIT_SCOPE || 'deps',
  
  // Post-update options
  postUpdateOptions: process.env.RENOVATE_POST_UPDATE_OPTIONS 
    ? process.env.RENOVATE_POST_UPDATE_OPTIONS.split(',').map(o => o.trim())
    : ['gomodTidy', 'npmDedupe', 'yarnDedupe'],
  
  // Suppress notifications
  suppressNotifications: process.env.RENOVATE_SUPPRESS_NOTIFICATIONS 
    ? process.env.RENOVATE_SUPPRESS_NOTIFICATIONS.split(',').map(n => n.trim())
    : ['prEdited'],
  
  // Package rules
  packageRules: [
    // GitHub Actions
    {
      groupName: "GitHub Actions",
      matchManagers: ["github-actions"],
      matchFileNames: [".github/workflows/**"],
      automerge: process.env.RENOVATE_AUTOMERGE_GITHUB_ACTIONS !== 'false',
      automergeType: "pr",
      minimumReleaseAge: process.env.RENOVATE_MIN_RELEASE_AGE_GITHUB_ACTIONS || "3 days",
      prPriority: 1,
      labels: ["renovate", "github-actions"]
    },
    
    // Node.js dependencies
    {
      groupName: "Node.js dependencies",
      matchManagers: ["npm", "yarn"],
      matchFileNames: ["package.json", "package-lock.json", "yarn.lock"],
      automerge: process.env.RENOVATE_AUTOMERGE_NODEJS !== 'false',
      automergeType: "pr",
      minimumReleaseAge: process.env.RENOVATE_MIN_RELEASE_AGE_NODEJS || "3 days",
      prPriority: 2,
      labels: ["renovate", "nodejs"]
    },
    
    // Python dependencies
    {
      groupName: "Python dependencies",
      matchManagers: ["pip", "pip-compile", "poetry"],
      matchFileNames: ["requirements.txt", "Pipfile", "pyproject.toml", "poetry.lock"],
      automerge: process.env.RENOVATE_AUTOMERGE_PYTHON !== 'false',
      automergeType: "pr",
      minimumReleaseAge: process.env.RENOVATE_MIN_RELEASE_AGE_PYTHON || "3 days",
      prPriority: 2,
      labels: ["renovate", "python"]
    },
    
    // Docker dependencies
    {
      groupName: "Docker dependencies",
      matchManagers: ["dockerfile", "docker-compose"],
      matchFileNames: [
        "Dockerfile*", 
        "*.dockerfile",
        "docker-compose*.yml", 
        "docker-compose*.yaml",
        "*.yml",
        "*.yaml",
        "k8s/*.yaml",
        "k8s/*.yml",
        "helm/**/*.yaml",
        "helm/**/*.yml",
        "*.tf",
        "**/*.tf",
        "*.sh",
        "*.bash",
        "*.zsh",
        "scripts/*",
        "*.py",
        "*.js",
        "*.ts",
        "*.go",
        "*.java",
        "*.cs",
        "*.rb",
        "*.php",
        "*.json",
        "*.jsonc"
      ],
      automerge: process.env.RENOVATE_AUTOMERGE_DOCKER !== 'false',
      automergeType: "pr",
      minimumReleaseAge: process.env.RENOVATE_MIN_RELEASE_AGE_DOCKER || "7 days",
      prPriority: 3,
      labels: ["renovate", "docker", "containers"]
    },
    
    // Terraform modules
    {
      groupName: "Terraform modules",
      matchManagers: ["terraform"],
      matchFileNames: ["**/*.tf"],
      automerge: process.env.RENOVATE_AUTOMERGE_TERRAFORM !== 'false',
      automergeType: "pr",
      minimumReleaseAge: process.env.RENOVATE_MIN_RELEASE_AGE_TERRAFORM || "7 days",
      prPriority: 3,
      labels: ["renovate", "terraform"]
    },
    
    // Security updates
    {
      groupName: "Security updates",
      matchDatasources: ["github-tags", "npm", "pypi", "docker"],
      matchUpdateTypes: ["patch", "minor"],
      matchCurrentVersion: "!/^0/",
      automerge: process.env.RENOVATE_AUTOMERGE_SECURITY !== 'false',
      automergeType: "pr",
      minimumReleaseAge: process.env.RENOVATE_MIN_RELEASE_AGE_SECURITY || "1 day",
      prPriority: 0,
      labels: ["renovate", "security"]
    },
    
    // Major updates
    {
      groupName: "Major updates",
      matchUpdateTypes: ["major"],
      automerge: false,
      prPriority: -1,
      labels: ["renovate", "major"],
      dependencyDashboardApproval: process.env.RENOVATE_MAJOR_DASHBOARD_APPROVAL === 'true'
    },
    
    // Development dependencies
    {
      groupName: "Development dependencies",
      matchDepTypes: ["devDependencies", "dev-dependencies", "dev"],
      automerge: process.env.RENOVATE_AUTOMERGE_DEV_DEPS !== 'false',
      automergeType: "pr",
      minimumReleaseAge: process.env.RENOVATE_MIN_RELEASE_AGE_DEV_DEPS || "3 days",
      prPriority: 3,
      labels: ["renovate", "dev-deps"]
    }
  ],
  
  // Lock file maintenance
  lockFileMaintenance: {
    enabled: process.env.RENOVATE_LOCKFILE_MAINTENANCE !== 'false',
    automerge: process.env.RENOVATE_AUTOMERGE_LOCKFILE !== 'false',
    automergeType: "pr",
    schedule: process.env.RENOVATE_LOCKFILE_SCHEDULE 
      ? process.env.RENOVATE_LOCKFILE_SCHEDULE.split(',').map(s => s.trim())
      : ["before 6am on the first day of the month"],
    prPriority: 4,
    labels: ["renovate", "lockfile-maintenance"]
  },
  
  // Vulnerability alerts
  vulnerabilityAlerts: {
    enabled: process.env.RENOVATE_VULNERABILITY_ALERTS !== 'false',
    labels: ["renovate", "security", "vulnerability"]
  },
  
  // Regex managers for custom patterns
  regexManagers: [
    {
      fileMatch: ["(^|/)\\.env\\.sample$", "(^|/)\\.env\\.example$"],
      matchStrings: ["(?<depName>[A-Z_]+)_VERSION=(?<currentValue>.+)"],
      datasourceTemplate: "github-tags",
      versioningTemplate: "semver"
    },
    // Dockerfile patterns
    {
      fileMatch: ["Dockerfile*", "*.dockerfile"],
      matchStrings: [
        "FROM\\s+(?<depName>[^:]+):(?<currentValue>[^\\s]+)",
        "FROM\\s+(?<depName>[^:]+):(?<currentValue>[^\\s]+)\\s+AS",
        "FROM\\s+--platform=[^\\s]+\\s+(?<depName>[^:]+):(?<currentValue>[^\\s]+)"
      ],
      datasourceTemplate: "docker",
      versioningTemplate: "docker"
    },
    // Docker Compose patterns
    {
      fileMatch: ["docker-compose*.yml", "docker-compose*.yaml", "*.yml", "*.yaml"],
      matchStrings: [
        "image:\\s*['\"]?(?<depName>[^:]+):(?<currentValue>[^'\"]+)['\"]?",
        "\\s+image:\\s*['\"]?(?<depName>[^:]+):(?<currentValue>[^'\"]+)['\"]?"
      ],
      datasourceTemplate: "docker",
      versioningTemplate: "docker"
    },
    // Kubernetes/Helm patterns
    {
      fileMatch: ["*.yaml", "*.yml", "k8s/*.yaml", "k8s/*.yml", "helm/**/*.yaml", "helm/**/*.yml"],
      matchStrings: [
        "image:\\s*['\"]?(?<depName>[^:]+):(?<currentValue>[^'\"]+)['\"]?",
        "containerImage:\\s*['\"]?(?<depName>[^:]+):(?<currentValue>[^'\"]+)['\"]?",
        "repository:\\s*['\"]?(?<depName>[^'\"]+)['\"]?",
        "tag:\\s*['\"]?(?<currentValue>[^'\"]+)['\"]?"
      ],
      datasourceTemplate: "docker",
      versioningTemplate: "docker"
    },
    // Terraform patterns
    {
      fileMatch: ["*.tf", "**/*.tf"],
      matchStrings: [
        "image\\s*=\\s*['\"]?(?<depName>[^:]+):(?<currentValue>[^'\"]+)['\"]?",
        "container_image\\s*=\\s*['\"]?(?<depName>[^:]+):(?<currentValue>[^'\"]+)['\"]?",
        "repository\\s*=\\s*['\"]?(?<depName>[^'\"]+)['\"]?",
        "tag\\s*=\\s*['\"]?(?<currentValue>[^'\"]+)['\"]?"
      ],
      datasourceTemplate: "docker",
      versioningTemplate: "docker"
    },
    // Shell script patterns
    {
      fileMatch: ["*.sh", "*.bash", "*.zsh", "scripts/*"],
      matchStrings: [
        "docker\\s+pull\\s+(?<depName>[^:]+):(?<currentValue>[^\\s]+)",
        "docker\\s+run[^\\n]*\\s+(?<depName>[^:]+):(?<currentValue>[^\\s]+)",
        "IMAGE\\s*=\\s*['\"]?(?<depName>[^:]+):(?<currentValue>[^'\"]+)['\"]?",
        "CONTAINER_IMAGE\\s*=\\s*['\"]?(?<depName>[^:]+):(?<currentValue>[^'\"]+)['\"]?"
      ],
      datasourceTemplate: "docker",
      versioningTemplate: "docker"
    },
    // Programming language patterns
    {
      fileMatch: ["*.py", "*.js", "*.ts", "*.go", "*.java", "*.cs", "*.rb", "*.php"],
      matchStrings: [
        "image\\s*=\\s*['\"]?(?<depName>[^:]+):(?<currentValue>[^'\"]+)['\"]?",
        "container_image\\s*=\\s*['\"]?(?<depName>[^:]+):(?<currentValue>[^'\"]+)['\"]?",
        "docker_image\\s*=\\s*['\"]?(?<depName>[^:]+):(?<currentValue>[^'\"]+)['\"]?",
        "IMAGE\\s*=\\s*['\"]?(?<depName>[^:]+):(?<currentValue>[^'\"]+)['\"]?"
      ],
      datasourceTemplate: "docker",
      versioningTemplate: "docker"
    },
    // JSON patterns
    {
      fileMatch: ["*.json", "*.jsonc"],
      matchStrings: [
        "\"image\"\\s*:\\s*\"(?<depName>[^:]+):(?<currentValue>[^\"]+)\"",
        "\"containerImage\"\\s*:\\s*\"(?<depName>[^:]+):(?<currentValue>[^\"]+)\"",
        "\"repository\"\\s*:\\s*\"(?<depName>[^\"]+)\"",
        "\"tag\"\\s*:\\s*\"(?<currentValue>[^\"]+)\""
      ],
      datasourceTemplate: "docker",
      versioningTemplate: "docker"
    }
  ],
  
  // Extends configuration
  extends: [
    "config:base",
    ":dependencyDashboard",
    ":semanticCommits",
    ":automergeBranchMerge",
    ":rebaseStalePrs",
    ":gitSignOff",
    ":prNotPending",
    "group:monorepos",
    "group:recommended",
    "helpers:pinGitHubActionDigests"
  ],
  
  // Additional configuration options
  onboardingConfig: {
    extends: ["config:base"]
  },
  
  // Commit message configuration
  commitMessageTopic: "{{depName}}",
  commitMessageExtra: "to {{newVersion}}",
  
  // PR body configuration
  prBodyDefinitions: {
    Change: "If applicable, any changes in behavior",
    Usage: "Any usage advice for this update",
    Testing: "Any testing instructions or advice",
    Migration: "Any migration advice for this update"
  },
  
  prBodyColumns: [
    "Package",
    "Type", 
    "Update",
    "Change",
    "Usage",
    "Testing",
    "Migration"
  ],
  
  // Host rules for private registries
  hostRules: process.env.RENOVATE_HOST_RULES 
    ? JSON.parse(process.env.RENOVATE_HOST_RULES)
    : []
};

// Export configuration
module.exports = config;

// Also export as JSON for compatibility
if (typeof window === 'undefined') {
  // Node.js environment
  module.exports.config = config;
} else {
  // Browser environment
  window.renovateConfig = config;
}
