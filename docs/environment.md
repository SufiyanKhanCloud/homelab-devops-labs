# Homelab Environment

## Purpose

This page records the software and components used in the learning
environment without publishing private network identifiers or
authentication details.

## Systems

| Role | Operating system | Purpose |
|---|---|---|
| Server | Ubuntu Server 24.04 LTS | Containers and remote administration |
| Client | Ubuntu Linux | SSH access and testing |

## Services

| Component | Purpose |
|---|---|
| Tailscale | Private connectivity between devices |
| OpenSSH | Remote shell administration |
| Docker | Application and database containers |
| Flask/Gunicorn | Web application |
| PostgreSQL | Relational database |
| Docker bridge network | Container-to-container communication |
| Docker named volume | Database data persistence |

## Network and Identity

Actual IP addresses, account identifiers, private keys, and network
credentials are deliberately excluded.

Public documentation uses placeholders for environment-specific
values.

## Documentation Rules

- Record software versions only after verifying them.
- Distinguish observed results from assumptions.
- Do not publish credentials, raw private logs, or real database data.
- Update this page when the environment changes.
