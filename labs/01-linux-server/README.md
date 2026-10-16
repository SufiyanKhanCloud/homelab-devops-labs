# Linux Server Administration

## Objective

Practice Linux server inspection, resource monitoring, service
management, log analysis, and evidence-based troubleshooting.

## Environment

- Server OS: Ubuntu Server 24.04 LTS
- Client OS: Ubuntu Linux
- Access method: SSH over Tailscale

Private IP addresses, credentials, and other sensitive identifiers
are intentionally omitted.

## Troubleshooting Workflow

When a server behaves unexpectedly, investigate before restarting
services or changing resource limits.

### 1. Check system uptime and load

```bash
uptime
```

Shows system uptime, load averages, and the number of logged-in users.

### 2. Inspect processes and resource usage

```bash
top
```

Use this to investigate CPU usage, memory consumption, and processes.

### 3. Check memory

```bash
free -h
```

Displays memory and swap usage in a human-readable format.

### 4. Check filesystem capacity

```bash
df -h
```

Shows filesystem capacity and available space.

### 5. Investigate directory usage

```bash
du -sh /path/to/directory
```

Replace the example path with the directory being investigated.

### 6. Inspect service status

```bash
systemctl status <service-name>
```

Replace `<service-name>` with the actual service being investigated.

### 7. Inspect system logs

```bash
journalctl -p err -b
```

Shows error-priority journal entries from the current boot.

For a specific service:

```bash
journalctl -u <service-name> --since "1 hour ago"
```

## Troubleshooting Principles

1. Identify the reported symptom.
2. Gather system and service evidence.
3. Check logs and recent changes.
4. Form a hypothesis and test it.
5. Apply the smallest appropriate corrective action.
6. Verify the outcome.
7. Document the root cause and prevention steps.

## Verification

Commands listed above are troubleshooting tools. Their inclusion
does not imply that every possible failure scenario has been tested.

Specific incidents, command output, and remediation results will be
documented after they have been observed and verified.

## Security

- Do not publish credentials, private keys, or sensitive logs.
- Review commands before running them with elevated privileges.
- Avoid restarting services before collecting relevant evidence.
- Redact sensitive information from terminal output before sharing it.

## Status

In progress.
