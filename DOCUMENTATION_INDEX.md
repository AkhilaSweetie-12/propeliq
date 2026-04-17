# PropelIQ Documentation Index

**Master Documentation Guide**  
**Last Updated:** April 17, 2026  
**Status:** Complete & Current

---

## 📚 Documentation Structure

This project includes comprehensive documentation covering pipeline architecture, task execution, and operations. Use this index to navigate to the section you need.

### Quick Navigation by Role

**👨‍💻 For Developers**
- [Getting Started](#getting-started) — Initial setup
- [Runbook: Typical Development Workflow](RUNBOOK.md#typical-development-workflow) — Step-by-step feature development
- [Runbook: Common Commands](RUNBOOK.md#common-commands) — Git, Docker, Python commands

**🔧 For DevOps Engineers**
- [Pipeline Documentation: Full Reference](PIPELINE_DOCUMENTATION.md) — Complete pipeline details
- [Task Execution Guide: Architecture](TASK_EXECUTION_GUIDE.md) — System design & flows
- [Pipeline Documentation: Deployment Procedures](PIPELINE_DOCUMENTATION.md#deployment-procedures) — Manual & automated deploys

**🔐 For Security Team**
- [Pipeline Documentation: Security & Compliance](PIPELINE_DOCUMENTATION.md#security--compliance) — OIDC, secrets scanning, vulnerabilities
- [Task Execution Guide: Error Handling](TASK_EXECUTION_GUIDE.md#error-handling-strategy) — Security failure scenarios
- [Security Controls Reference](#security-controls)

**📊 For Team Leads**
- [Executive Summary](PIPELINE_DOCUMENTATION.md#executive-summary) — High-level overview
- [System Architecture](TASK_EXECUTION_GUIDE.md#system-architecture) — Component diagram
- [Metrics Dashboard](TASK_EXECUTION_GUIDE.md#monitoring--observability) — Key metrics

---

## Getting Started

### 1. **Initial Setup** (One-Time)

If you're new to the project:

```bash
# Clone repository
git clone https://github.com/kanini/propeliq.git
cd propeliq

# Install dependencies
python -m pip install --upgrade pip
pip install -r requirements.txt

# Configure GCP (one-time)
gcloud auth login
gcloud config set project akhila-gcp-123-493309

# Bootstrap GCP resources (one-time)
bash scripts/gcp-cicd-bootstrap.sh

# Verify setup
python -m pytest -v
```

**See:** [Pipeline Documentation: First-Time Setup](PIPELINE_DOCUMENTATION.md#first-time-setup)

### 2. **First Feature Development**

To create and deploy your first feature:

1. Read: [Runbook: Typical Development Workflow](RUNBOOK.md#typical-development-workflow)
2. Follow: Step-by-step instructions (8 steps)
3. Monitor: [Runbook: Pipeline Monitoring](RUNBOOK.md#pipeline-monitoring)

**Estimated Time:** 30 minutes (including CI/CD pipeline execution)

### 3. **Common Tasks**

For frequent operations:

- **Deploy manually:** [Runbook: Common Commands](RUNBOOK.md#common-commands) → "Deploy manually"
- **Check pipeline status:** [Runbook: Pipeline Monitoring](RUNBOOK.md#pipeline-monitoring)
- **Troubleshoot issues:** [Runbook: Troubleshooting Quick Links](RUNBOOK.md#troubleshooting-quick-links)

---

## 📖 Documentation Files

### 1. **PIPELINE_DOCUMENTATION.md** (Comprehensive Reference)

**Purpose:** Complete technical documentation of the CI/CD pipeline and infrastructure  
**Length:** ~3000 lines  
**Audience:** Architects, DevOps engineers, technical leads

**Sections:**
- Executive Summary
- Architecture Overview
- Infrastructure & Cloud Setup (GCP configuration, Terraform modules)
- CI/CD Pipeline Architecture (5 jobs detailed)
- Task Execution Strategy (workflows for different scenarios)
- Security & Compliance (OIDC, action pinning, gating)
- Deployment Procedures (automatic & manual paths)
- Monitoring & Observability (health checks, logging)
- Troubleshooting & Recovery (error diagnosis, fixes)
- Maintenance & Operations (weekly, monthly, quarterly tasks)
- Scaling Considerations
- Appendices (quick reference, env variables, disaster recovery)

**When to Use:**
- Need deep understanding of how pipeline works
- Planning infrastructure changes
- Implementing new security controls
- Designing multi-region deployment
- Troubleshooting complex issues

**Key Tables:**
- Cloud Run Configuration comparison (dev vs prod)
- Pipeline Jobs execution details
- Environment Secrets & Variables
- GCP Permission mapping
- Security Controls in Pipeline

---

### 2. **RUNBOOK.md** (Quick Reference)

**Purpose:** Quick reference guide for common operations  
**Length:** ~500 lines  
**Audience:** All team members (developers, DevOps, leads)

**Sections:**
- First-Time Setup
- Typical Development Workflow (clear steps)
- Pipeline Monitoring (status checks)
- Emergency Procedures (urgent actions)
- Common Commands (git, GCP, Docker, Python)
- Troubleshooting Quick Links
- Support & Escalation

**When to Use:**
- Need quick answer for common task
- Don't have time to read full documentation
- Want copy-paste ready commands
- Emergency situation requires fast response
- New team member onboarding

**One-Liners:**
- Deploy manually
- Check all services healthy
- View last 10 deployments
- Force redeploy latest code
- Test API endpoint

**Typical Use Patterns:**
```
Problem → Runbook section → One-liner command → Done!
```

---

### 3. **TASK_EXECUTION_GUIDE.md** (Architecture & Flows)

**Purpose:** Detailed task execution flows with visual diagrams  
**Length:** ~2500 lines  
**Audience:** Architects, system designers, tool maintainers

**Sections:**
- System Architecture (high-level diagram)
- Task Execution Flows (feature development flow, security scanning flow)
- Data Flow Diagrams (source to production, OIDC auth)
- Component Interactions (deployment dependencies)
- State Management (application lifecycle, workflow state machine)
- Error Handling Strategy (detection & recovery by layer)
- Monitoring & Observability (metrics dashboard)

**When to Use:**
- Understanding how components interact
- Designing new features that affect pipeline
- Training new team members on architecture
- Documenting system for knowledge transfer
- Planning disaster recovery procedures

**Visual Content:**
- ASCII diagrams of system architecture
- Task execution flow charts
- Data flow end-to-end diagrams
- State machine diagrams
- Error recovery priority matrix

---

## 📋 Quick Reference Tables

### Cloud Platforms & Services

| Service | Configuration | Purpose |
|---------|---------------|---------|
| **GCP Project** | akhila-gcp-123-493309, us-central1 | Hosting & Compute |
| **Cloud Run (Dev)** | app-service-dev, 256MB, public | Development environment |
| **Cloud Run (Prod)** | app-service, 512MB, private | Production environment |
| **Artifact Registry** | app-images, us-central1-docker.pkg.dev | Docker image storage |
| **Workload Identity** | github-pool/github-provider | OIDC authentication |
| **GitHub Actions** | gcp-cloudrun-ci-cd.yml | Automation platform |

### Pipeline Jobs

| Job # | Name | Trigger | Duration | Failure Handling |
|-------|------|---------|----------|------------------|
| 1 | Validate | Always | ~1 min | Stop pipeline |
| 2 | Security | After Validate | ~1 min | Stop pipeline |
| 3 | Build & Push | After Security | ~2 min | Stop pipeline |
| 4 | Deploy-Dev | After Build | ~1 min | Stop pipeline (but can manually retry) |
| 5 | Deploy-Prod | After Deploy-Dev | ~1 min | Requires approval gate |

### Security Controls

| Control | Technology | Scan Scope | Failure Threshold |
|---------|-----------|-----------|------------------|
| Secrets Detection | Gitleaks | Full git history | Any finding |
| Vulnerability Scan | Trivy | Dependencies + filesystem | CRITICAL/HIGH |
| IaC Compliance | Checkov | Terraform in infra/ | CRITICAL |
| Code Analysis | CodeQL | Python source code | CRITICAL/HIGH (future) |
| Action Pinning | Manual review | GitHub Actions | All actions pinned to SHA |

---

## 🔍 Finding Information

### Search by Topic

**Authentication & Security**
- [OIDC Authentication](PIPELINE_DOCUMENTATION.md#oidc-authentication-no-static-keys)
- [Action Pinning](PIPELINE_DOCUMENTATION.md#action-pinning-supply-chain-security)
- [Deployment Gating](PIPELINE_DOCUMENTATION.md#deployment-gating-strategy)
- [Security Controls](PIPELINE_DOCUMENTATION.md#security-controls-in-pipeline)

**Infrastructure & Deployment**
- [GCP Setup](PIPELINE_DOCUMENTATION.md#gcp-project-configuration)
- [Terraform Modules](PIPELINE_DOCUMENTATION.md#terraform-infrastructure-modules)
- [Cloud Run Configuration](PIPELINE_DOCUMENTATION.md#cloud-run-configuration)
- [Manual Deployment](PIPELINE_DOCUMENTATION.md#manual-deployment-emergency-path)

**Operations & Maintenance**
- [Health Checks](PIPELINE_DOCUMENTATION.md#health-checks)
- [Application Logging](PIPELINE_DOCUMENTATION.md#application-logging)
- [Metrics & Dashboards](PIPELINE_DOCUMENTATION.md#metrics--dashboards)
- [Maintenance Tasks](PIPELINE_DOCUMENTATION.md#regular-maintenance-tasks)

**Troubleshooting**
- [Pipeline Failures](PIPELINE_DOCUMENTATION.md#pipeline-failures)
- [GCP Permission Issues](PIPELINE_DOCUMENTATION.md#gcp-permission-issues)
- [Emergency Procedures](RUNBOOK.md#emergency-procedures)
- [Error Handling](TASK_EXECUTION_GUIDE.md#error-handling-strategy)

---

## 📊 Documentation Statistics

| File | Purpose | Sections | Tables | Diagrams |
|------|---------|----------|--------|----------|
| **PIPELINE_DOCUMENTATION.md** | Complete reference | 12 | 25+ | 5+ |
| **RUNBOOK.md** | Quick reference | 6 | 10+ | 0 |
| **TASK_EXECUTION_GUIDE.md** | Architecture diagrams | 6 | 5+ | 15+ |
| **Total** | Full documentation suite | 24+ | 40+ | 20+ |

**Total Lines of Documentation:** ~6000 lines  
**Total Words:** ~30,000+ words  
**Code Examples:** 100+ commands and code snippets

---

## 🎯 Use Case Examples

### Use Case 1: Deploy a New Feature to Production

**Steps:**
1. Read: [Runbook: Typical Development Workflow](RUNBOOK.md#typical-development-workflow) — 5 min
2. Implement feature locally using provided commands
3. Create PR and wait for CI/CD
4. Merge to main when approved
5. Monitor: [Runbook: Pipeline Monitoring](RUNBOOK.md#pipeline-monitoring) — 2 min
6. Approve prod deployment when requested
7. Done! Feature is live

**Time:** ~20 minutes (including CI/CD execution)

### Use Case 2: Debug Failed Pipeline in Production

**Steps:**
1. Go to [Runbook: Emergency Procedures](RUNBOOK.md#emergency-procedures) — 2 min
2. Identify failure type (validate/security/build/deploy)
3. Navigate to [PIPELINE_DOCUMENTATION.md](PIPELINE_DOCUMENTATION.md#troubleshooting--recovery)
4. Find specific error section (e.g., "Validate Job - pytest Tests Fail")
5. Follow resolution steps
6. Re-run pipeline

**Time:** ~10 minutes for typical issues

### Use Case 3: Understand System Architecture

**Steps:**
1. Read: [TASK_EXECUTION_GUIDE.md: System Architecture](TASK_EXECUTION_GUIDE.md#system-architecture)
2. Review: [TASK_EXECUTION_GUIDE.md: Task Execution Flows](TASK_EXECUTION_GUIDE.md#task-execution-flows)
3. Study: [TASK_EXECUTION_GUIDE.md: Data Flow Diagrams](TASK_EXECUTION_GUIDE.md#data-flow-diagrams)
4. Reference: [TASK_EXECUTION_GUIDE.md: Component Interactions](TASK_EXECUTION_GUIDE.md#component-interactions)

**Time:** ~30-45 minutes for complete understanding

### Use Case 4: Rolling Back a Failed Deployment

**Steps:**
1. See: [PIPELINE_DOCUMENTATION.md: Rollback Procedure](PIPELINE_DOCUMENTATION.md#rollback-procedure)
2. Choose method: Traffic splitting, git revert, or redeploy previous image
3. Execute one-liner command
4. Verify health check passes

**Time:** ~5-10 minutes

---

## 🔄 Documentation Maintenance

### Version Control

**Current Version:** 1.0  
**Last Updated:** April 17, 2026  
**Review Schedule:** Quarterly (every 3 months)

### Update Categories

| Category | Frequency | Who | Notes |
|----------|-----------|-----|-------|
| Pipeline Changes | As needed | DevOps team | After workflow updates |
| Security Updates | As needed | Security team | After security review |
| Command References | Monthly | Automation team | Keep GCP/kubectl current |
| Diagrams | Quarterly | Architecture team | Sync with actual system |
| Examples | Quarterly | All teams | Refresh with real scenarios |

### Suggesting Updates

Found an error or want to improve documentation?

1. Create GitHub issue with: `[DOC]` in title
2. Include: Section, current text, suggested change
3. Link to: Specific documentation file and line
4. Example: `[DOC] Runbook: Update deployment time from 5 min to 7 min`

---

## 📞 Support & Questions

### Documentation Questions

**Q: Where do I find information about X?**  
A: Use the [Finding Information](#-finding-information) table above to locate the right section.

**Q: A command in the documentation doesn't work.**  
A: File GitHub issue with: command, error message, OS version. Likely version-specific.

**Q: Can I propose documentation changes?**  
A: Yes! Create PR with changes, include rationale in description.

### Common Questions

**Q: How do I deploy manually?**  
A: See [Runbook: Emergency Procedures → Deploy manually](RUNBOOK.md#common-commands)

**Q: How do I troubleshoot a failed pipeline?**  
A: See [Runbook: Emergency Procedures](RUNBOOK.md#emergency-procedures)

**Q: What's the OIDC flow in detail?**  
A: See [PIPELINE_DOCUMENTATION: OIDC Authentication](PIPELINE_DOCUMENTATION.md#oidc-authentication-no-static-keys)

**Q: How do I understand the system architecture?**  
A: See [TASK_EXECUTION_GUIDE: System Architecture](TASK_EXECUTION_GUIDE.md#system-architecture)

---

## 🎓 Onboarding New Team Members

### Day 1: Basic Understanding
- [ ] Read this index (15 min)
- [ ] Skim [PIPELINE_DOCUMENTATION: Executive Summary](PIPELINE_DOCUMENTATION.md#executive-summary) (10 min)
- [ ] Review [TASK_EXECUTION_GUIDE: System Architecture](TASK_EXECUTION_GUIDE.md#system-architecture) (20 min)

### Day 2: Hands-On Setup
- [ ] Follow [PIPELINE_DOCUMENTATION: First-Time Setup](PIPELINE_DOCUMENTATION.md#first-time-setup) (30 min)
- [ ] Create first feature branch
- [ ] Make small code change
- [ ] Push and observe pipeline

### Day 3: Deeper Learning
- [ ] Complete [RUNBOOK: Typical Development Workflow](RUNBOOK.md#typical-development-workflow) (30 min)
- [ ] Study [TASK_EXECUTION_GUIDE: Task Execution Flows](TASK_EXECUTION_GUIDE.md#task-execution-flows) (30 min)
- [ ] Review specific job you'll be working with

### Week 2: Specialized Training
- [ ] Based on role (DevOps/Security/Developer)
- [ ] Deep-dive into relevant [PIPELINE_DOCUMENTATION](PIPELINE_DOCUMENTATION.md) sections
- [ ] Hands-on practice with commands in [RUNBOOK](RUNBOOK.md)

**Expected Ramp-Up Time:** 2-3 days for basic proficiency, 1-2 weeks for full proficiency

---

## 📄 Document Cross-References

### Internal Links (within Documentation)

All documentation files contain internal cross-references like:
- [Architecture Overview](#architecture-overview)
- Links to other documents

### External Links

- **GitHub Actions:** https://github.com/kanini/propeliq/actions
- **GCP Console:** https://console.cloud.google.com/run?project=akhila-gcp-123-493309
- **Artifact Registry:** https://console.cloud.google.com/artifacts/docker/akhila-gcp-123-493309/us-central1

---

## ✅ Documentation Checklist

### For Users

- [ ] I found the documentation index (DOCUMENTATION_INDEX.md)
- [ ] I identified my role (Developer/DevOps/Security/Lead)
- [ ] I read the "Quick Navigation by Role" section
- [ ] I know which document to consult for my task

### For Documentation Maintainers

- [ ] All sections are current (last review date noted)
- [ ] All links are working and point to correct sections
- [ ] All command examples are tested
- [ ] All GCP project IDs match current values
- [ ] All version numbers are current
- [ ] Diagram ASCII art renders correctly

---

## 📝 Summary

You now have **three comprehensive documentation files** covering your PropelIQ CI/CD pipeline:

1. **PIPELINE_DOCUMENTATION.md** — Complete technical reference (3000+ lines)
   - Best for: Understanding full pipeline, planning changes, troubleshooting
   
2. **RUNBOOK.md** — Quick reference guide (500+ lines)
   - Best for: Quick answers, common operations, emergency procedures
   
3. **TASK_EXECUTION_GUIDE.md** — Architecture & execution flows (2500+ lines)
   - Best for: Understanding system design, explaining to others, training

**Total:** ~6000 lines, 30,000+ words, 40+ tables, 20+ diagrams

---

**Last Updated:** April 17, 2026  
**Status:** Complete & Current  
**Next Review:** July 17, 2026 (Quarterly)

**Start Here:** Pick your role above and navigate to the relevant section!
