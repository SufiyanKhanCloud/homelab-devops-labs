# Tailscale Remote Access

## Objective

Configure private connectivity between a Linux client and an Ubuntu Server, then verify remote administration through SSH.

## Architecture

Linux Client → Tailscale Network → Ubuntu Server → SSH

The connection is private to the authorized tailnet. No public server IP address or private network identifier is published here.

## Environment

- Server: Ubuntu Server 24.04.5 LTS
- Client: Ubuntu Linux 26.04 LTS
- Private connectivity: Tailscale
- Remote administration: OpenSSH
- Hostname resolution: Tailscale MagicDNS

## Implementation and Verification

### 1. Verify Tailscale status

Run on each device:

```bash
tailscale status
```

Confirmed that both devices appeared in the tailnet.

### 2. Test connectivity

From the client:

```bash
tailscale ping homelab-server
```

A direct LAN path was observed while both devices were connected to the same home network.

### 3. Test SSH using the Tailscale IP

```bash
ssh <username>@<tailscale-ip>
```

SSH connectivity was successfully tested over a mobile-data hotspot using Tailscale.

### 4. Test MagicDNS

```bash
ssh <username>@homelab-server
```

Hostname-based SSH connectivity was successfully verified.

### 5. Verify boot persistence

Tailscale was configured to start automatically with the server.

After a controlled server reboot, remote SSH connectivity was successfully verified without manually starting Tailscale.

### 6. Review SSH and firewall access controls

- SSH key-based authentication was configured.
- UFW was configured with default-deny incoming traffic and an OpenSSH allow rule.
- The CI/CD deployment SSH key was restricted to the server-side deployment command rather than general shell access.

## Observations

- A direct connection was observed on the home network.
- A DERP relay was observed during testing over a mobile-data hotspot.
- Remote SSH access worked over the hotspot.
- Relay latency was noticeably higher during the observed tests.

These observations describe the tested network conditions and do not establish the root cause of the separate Wi-Fi latency issue.

## Security

- Never publish Tailscale authentication keys.
- Do not publish SSH private keys or credentials.
- Use authorized devices and accounts only.
- Keep SSH access restricted to authorized users.
- Review access controls before exposing additional services.

## Status

Tailscale connectivity, MagicDNS, key-based SSH access, firewall rules, automatic service startup, and post-reboot remote connectivity have been implemented and tested.
