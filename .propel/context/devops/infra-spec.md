# Infrastructure Specification

## Project Overview
Infrastructure baseline for "infra setup" to host services on GCP with secure networking, managed secrets, observability, and environment separation.

## Target Configuration
| Attribute | Value |
|-----------|-------|
| Cloud Providers | GCP |
| IaC Tool | Terraform |
| Environments | dev, qa, staging, prod |

## Environment Matrix
| Environment | Purpose | Availability | Scale | Approval Required |
|-------------|---------|--------------|-------|-------------------|
| dev | Development and validation | Single zone | Minimal | None |
| qa | Functional and integration testing | Single zone | Reduced | None |
| staging | Production-like verification | Multi-zone | Medium | 1 approver |
| prod | Production workloads | Multi-zone | Full | 2 approvers |

---

## Infrastructure Requirements

### Compute Requirements (INFRA-XXX)
- INFRA-001: System MUST provision GKE Autopilot clusters for workload orchestration.
- INFRA-002: System MUST configure workload auto-scaling between 2 and 20 replicas based on CPU and memory.
- INFRA-003: System MUST expose public traffic only through managed HTTPS load balancing.
- INFRA-004: [UNCLEAR] System MUST define exact per-service SLO and latency budget targets.

### Networking Requirements (INFRA-XXX)
- INFRA-010: System MUST provision dedicated VPC per environment with non-overlapping CIDR blocks.
- INFRA-011: System MUST isolate application and data workloads into private subnets.
- INFRA-012: System MUST route internet ingress through Cloud Load Balancing with Cloud Armor.
- INFRA-013: System MUST enforce firewall deny-by-default and explicit allow-list ingress.
- INFRA-014: [UNCLEAR] System MUST confirm private connectivity requirement to external enterprise networks.

### Storage Requirements (INFRA-XXX)
- INFRA-020: System MUST provision regional Cloud Storage buckets for artifacts and logs.
- INFRA-021: System MUST run daily backups for stateful data with lifecycle policies.
- INFRA-022: System MUST enable versioning and cross-zone resilience for critical data buckets.
- INFRA-023: [UNCLEAR] System MUST define long-term archival retention period by data class.

### Database Requirements (INFRA-XXX)
- INFRA-030: System MUST provision Cloud SQL PostgreSQL with private IP.
- INFRA-031: System MUST configure HA and backup strategy to target RTO <= 60 minutes and RPO <= 15 minutes.
- INFRA-032: System MUST support read scaling through read replicas in staging and prod.
- INFRA-033: [UNCLEAR] System MUST finalize peak TPS and storage growth assumptions.

---

## Security Requirements (SEC-XXX)

### Network Security
- SEC-001: System MUST implement VPC segmentation by environment and tier.
- SEC-002: System MUST configure Cloud Armor WAF policies for public endpoints.
- SEC-003: System MUST use private service access for managed data services.

### Data Security
- SEC-010: System MUST encrypt data at rest using provider-managed AES-256 (or CMEK where required).
- SEC-011: System MUST enforce TLS 1.2+ for all service-to-service and client traffic.
- SEC-012: System MUST implement KMS-backed key management with rotation.

### Identity and Access
- SEC-020: System MUST use workload identity for service authentication.
- SEC-021: System MUST implement least-privilege IAM roles scoped by environment.
- SEC-022: System MUST store secrets in Secret Manager and never in source control.

### Compliance
- SEC-030: System MUST align with CIS and SOC2 control expectations.
- SEC-031: System MUST enable audit logging for IAM, networking, and data services.
- SEC-032: [UNCLEAR] System MUST confirm additional regulatory obligations (PCI-DSS/GDPR) before prod go-live.

---

## Operations Requirements (OPS-XXX)

### Monitoring
- OPS-001: System MUST collect metrics with Cloud Monitoring dashboards per environment.
- OPS-002: System MUST centralize logs in Cloud Logging with resource labels.
- OPS-003: System MUST capture traces for HTTP services via OpenTelemetry-compatible instrumentation.

### Alerting
- OPS-010: System MUST alert when 5xx error rate exceeds 5% over 5 minutes.
- OPS-011: System MUST alert when p99 latency exceeds 750ms over 10 minutes.
- OPS-012: System MUST alert when CPU or memory usage exceeds 85% sustained for 15 minutes.

### Disaster Recovery
- OPS-020: System MUST support RTO <= 60 minutes for production services.
- OPS-021: System MUST support RPO <= 15 minutes for production databases.
- OPS-022: System MUST enforce daily backup plus 35-day retention for production data.

---

## Environment-Specific Requirements (ENV-XXX)

### Development (dev)
- ENV-001: dev MUST use minimum viable node and database sizing.
- ENV-002: dev MUST permit developer access through least-privilege IAM groups.

### QA (qa)
- ENV-010: qa MUST use anonymized or synthetic test data.
- ENV-011: qa MUST support parallel integration and E2E test execution.

### Staging (staging)
- ENV-020: staging MUST mirror production topology and security controls.
- ENV-021: staging MUST use anonymized data and production-like traffic profiles.

### Production (prod)
- ENV-030: prod MUST deploy across at least two zones.
- ENV-031: prod MUST require approved deployment gates before apply.
- ENV-032: prod MUST restrict console and privileged access to authorized on-call roles.

---

## Cost Estimate

| Environment | Resource Category | Monthly Estimate | Notes |
|-------------|-------------------|------------------|-------|
| dev | Total | $220 - $380 | Minimal compute and shared services |
| qa | Total | $320 - $520 | Test workload and additional scans |
| staging | Total | $700 - $1,050 | Production-like footprint |
| prod | Total | $1,800 - $3,200 | HA data layer and full observability |

Cost optimization opportunities:
- Use committed use discounts for stable prod baseline.
- Use scheduled scale-down or pause strategy for non-prod clusters.
- Apply storage lifecycle tiers for logs and artifacts.

---

## Requirement Traceability

| INFRA/SEC/OPS/ENV ID | Source Requirement | NFR/TR/DR Reference |
|----------------------|-------------------|---------------------|
| INFRA-001 | Infrastructure baseline for containerized workloads | NFR-Performance |
| INFRA-031 | Recovery and availability target | NFR-Availability |
| SEC-022 | Secrets handling and secure operations | NFR-Security |
| OPS-010 | Operational SLO alerting | NFR-Reliability |
| ENV-030 | Production resilience target | NFR-Availability |

---

## Human Review Checklist
- [ ] Confirm exact latency and throughput targets.
- [ ] Confirm compliance frameworks required for production.
- [ ] Confirm final network CIDR allocations and peering needs.
- [ ] Confirm budget ceiling per environment.
