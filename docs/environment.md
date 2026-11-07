# Homelab Environment

## Purpose

This page documents the software, services, and infrastructure components used in the homelab learning environment. It provides a high-level reference without publishing private network identifiers, authentication details, or sensitive system information.

## Systems

| Role | Operating system | Purpose |
|---|---|---|
| Server | Ubuntu Server 24.04.5 LTS | Containers, databases, monitoring, and remote administration |
| Management client | Ubuntu 26.04 LTS | SSH access, development, testing, and infrastructure management |

## Core Services

| Component | Purpose |
|---|---|
| Tailscale | Private connectivity between devices |
| OpenSSH | Remote shell administration |
| UFW | Host firewall and access control |
| Docker Engine | Container runtime |
| Docker Compose | Multi-container application management |
| Flask/Gunicorn | Notes API application |
| PostgreSQL | Relational database |
| Docker bridge network | Container-to-container communication |
| Docker volume | Persistent database storage |

## Backup and Recovery

| Component | Purpose |
|---|---|
| PostgreSQL `pg_dump` | Custom-format database backups |
| `pg_restore` | Backup archive inspection and restoration |
| systemd oneshot service | Startup-triggered automated backup execution |
| `flock` | Prevent concurrent backup executions |
| Backup retention | Keep the seven newest validated backup archives |

The deployed backup service runs with root privileges and uses restricted file permissions. It includes archive validation, atomic file handling, locking, retention, and same-day duplicate prevention.

The service runs after system startup with a five-minute delay. It is not a daily systemd timer and does not guarantee a backup every calendar day if the server remains continuously online.

The November 7, 2026 backup archive was successfully created and passed `pg_restore --list` validation. Seven retained archives were present at the time of verification. Archive listing validation does not establish that the latest archive has been restored successfully.

Historical isolated restore tests are documented separately in the relevant PostgreSQL backup and restore lab.

## Monitoring and Alerting

| Component | Purpose |
|---|---|
| Prometheus | Metrics collection and alert rule evaluation |
| Node Exporter | Host-level metrics |
| Grafana | Monitoring dashboards and visualization |
| Alertmanager | Alert routing and email notifications |

Prometheus and Grafana web interfaces are restricted to localhost access.

Alertmanager email delivery has been verified through a controlled Node Exporter-down test:

- A firing notification was received after stopping the exporter.
- A recovery notification was received after restoring the exporter.

The CPU alert rule was also tested through a controlled threshold simulation. Separate email delivery for the CPU alert has not yet been verified.

## CI/CD and Deployment

| Component | Purpose |
|---|---|
| GitHub Actions | Automated testing, dependency validation, image building, scanning, and deployment workflows |
| Docker Hub | Container image registry |
| Tailscale | Private connectivity for the deployment runner |
| SSH | Restricted remote deployment access |
| Trivy | Container image vulnerability scanning |
| Root-controlled deployment helper | Validated image deployment, readiness verification, and rollback |

The CI/CD pipeline uses full Git commit SHA image tags. The workflow includes automated tests, dependency lock-file validation, Docker image building, Trivy scanning, and conditional image publishing.

The CD workflow validates the deployment manifest and deploys the exact SHA-tagged image through restricted remote access. The server-side deployment process validates the requested image tag, updates the application service, checks application readiness, and attempts rollback if deployment verification fails.

The image-changing end-to-end deployment path was successfully verified using a dependency lockfile change. The run completed image building, vulnerability scanning, publishing, manifest validation, and remote deployment. Application health and database readiness were verified afterward.

A controlled health-verification failure was also used to test the rollback path.

**Verification limitation:** The successful image-changing run was triggered by a dependency lockfile change, not a direct application-code change. A fresh application-code-triggered deployment test remains pending.

## Container Security

Trivy is integrated into the CI image-scanning workflow. The pipeline is configured to prevent publishing when the configured HIGH or CRITICAL vulnerability threshold is exceeded.

A separate historical Trivy scan identified HIGH findings and unique CVEs in an earlier application image. Those results are not a verified assessment of the current image. Vendor-fix investigation, rebuilding, and a post-remediation scan remain outstanding.

The application container also uses runtime hardening controls, including:

- Non-root execution.
- Read-only root filesystem.
- Dropped Linux capabilities.
- No-new-privileges security option.
- Temporary filesystem for writable runtime paths.
- Localhost-bound application port exposure.

## Network and Identity

Actual IP addresses, account identifiers, private keys, hostnames, and network credentials are deliberately excluded.

Public documentation uses placeholders for environment-specific values.

## Documentation Rules

- Record software versions only after verifying them.
- Distinguish observed results from assumptions.
- Do not publish credentials, raw private logs, internal network identifiers, or real database data.
- Keep historical test results separate from current system status.
- Do not describe archive validation as a completed restore test.
- Update this page when the environment changes.
