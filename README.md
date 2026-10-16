# Homelab DevOps Labs

**Build it. Test it. Break it safely. Understand why it works.**

A hands-on DevOps homelab documenting Linux administration, secure remote access, containerization, database reliability, troubleshooting, and automation.

## Project Goals

- Practice Linux server administration and troubleshooting.
- Configure secure remote access using Tailscale and SSH.
- Understand Docker networking and containerized applications.
- Implement and validate PostgreSQL backup and restore procedures.
- Build toward monitoring and CI/CD automation.

## Architecture

```mermaid
flowchart TD
    Client["Ubuntu Linux Client"]
    VPN["Tailscale Private Network"]
    Server["Ubuntu Server"]
    Docker["Docker Host"]
    App["Flask + Gunicorn"]
    DB[("PostgreSQL")]
    Volume[("Persistent Volume")]

    Client <--> VPN
    VPN <--> Server
    Server --> Docker
    Docker --> App
    App --> DB
    DB --> Volume
```

*Logical architecture. Private network details and credentials are intentionally omitted.*

## Technology Stack

| Area | Technology |
|---|---|
| Server | Ubuntu Server 24.04 LTS |
| Client | Ubuntu Linux |
| Remote access | Tailscale and SSH |
| Containers | Docker |
| Application | Flask and Gunicorn |
| Database | PostgreSQL |
| Networking | Docker bridge network |
| Persistence | Docker named volume |
| Documentation | Markdown and Mermaid |

## Labs and Progress

| Lab | Status |
|---|---|
| Linux Server Administration | In progress |
| Tailscale Remote Access | Connectivity tested |
| Docker Networking | Implemented; documentation pending |
| PostgreSQL Backup and Restore | Backup created and inspected; restore test pending |
| Docker Compose | Planned |
| Monitoring | Planned |
| CI/CD | Planned |

## Engineering Approach

Each lab will document its objective, architecture, implementation, verification, troubleshooting, security considerations, and limitations.

Only tested results will be described as completed. Planned work will remain clearly identified as planned.

## Current Issues

- Investigate Wi-Fi latency using measured evidence.
- Verify Tailscale connectivity after a controlled server reboot.
- Complete a PostgreSQL restore test and verify the restored data.

## Security

This repository is intended for sanitized documentation and safe examples.

Never commit credentials, private keys, sensitive logs, database backups containing real data, or unnecessary infrastructure identifiers.

See [SECURITY.md](SECURITY.md) for security guidelines.

## Roadmap

See [ROADMAP.md](ROADMAP.md) for planned milestones.

## Author

**Sufiyan Khan**

DevOps | Linux | Docker | Cloud | CI/CD
