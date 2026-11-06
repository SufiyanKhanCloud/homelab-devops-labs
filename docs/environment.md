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

The deployed backup service runs with root privileges and uses restricted file permissions. It includes archive validation, atomic file handling, and same-day duplicate prevention.

The service is startup-triggered with a five-minute delay. It is not a daily systemd timer.

## Monitoring and Alerting

| Component | Purpose |
|---|---|
| Prometheus | Metrics collection and alert rule evaluation |
| Node Exporter | Host-level metrics |
| Grafana | Monitoring dashboards and visualization |
| Alertmanager | Alert routing and email notifications |

Prometheus and Grafana web interfaces are restricted to localhost access. Alertmanager email delivery has been verified using a Prometheus target-down alert.

## CI/CD and Deployment

| Component | Purpose |
|---|---|
| GitHub Actions | Automated testing, image building, scanning, and deployment workflows |
| Docker Hub | Container image registry |
| Tailscale | Private connectivity for the deployment runner |
| SSH | Restricted remote deployment access |
| Trivy | Container image vulnerability scanning |
| Root-controlled deployment helper | Validated image deployment, health verification, and rollback |

Deployment uses full Git commit SHA image tags. The server-side deployment process validates the requested image tag and checks application health after deployment.

## Network and Identity

Actual IP addresses, account identifiers, private keys, hostnames, and network credentials are deliberately excluded.

Public documentation uses placeholders for environment-specific values.

## Documentation Rules

- Record software versions only after verifying them.
- Distinguish observed results from assumptions.
- Do not publish credentials, raw private logs, internal network identifiers, or real database data.
- Keep historical test results separate from current system status.
- Update this page when the environment changes.
