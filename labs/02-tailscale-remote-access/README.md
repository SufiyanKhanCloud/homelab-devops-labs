# Tailscale Remote Access

## Objective

Configure private connectivity between a Linux client and an Ubuntu
Server, then verify remote administration through SSH.

## Architecture

Linux Client → Tailscale Network → Ubuntu Server → SSH

The connection is private to the authorized tailnet. No public server
IP address or private network identifier is published here.

## Environment

- Server: Ubuntu Server 24.04 LTS
- Client: Ubuntu Linux
- Private connectivity: Tailscale
- Remote administration: OpenSSH
- Hostname resolution: Tailscale MagicDNS

## Implementation and Verification

### 1. Verify Tailscale status

Run on each device:

```bash
tailscale status
```

Confirm that the expected devices appear in the tailnet.

### 2. Test connectivity

From the client:

```bash
tailscale ping homelab-server
```

The connection was observed to use a direct LAN path while both
devices were on the same home network.

### 3. Test SSH using the Tailscale IP

```bash
ssh <username>@<tailscale-ip>
```

Replace the placeholders with the intended account and device's
Tailscale IP.

SSH connectivity was successfully tested over a mobile-data hotspot.

### 4. Test MagicDNS

```bash
ssh <username>@homelab-server
```

Hostname-based SSH connectivity was also tested successfully.

## Observations

- A direct connection was observed on the home network.
- A DERP relay was observed during testing over a mobile-data hotspot.
- Remote SSH access worked over the hotspot.
- Relay latency was noticeably higher during the observed tests.

These observations describe the tested network conditions and do not
establish the root cause of the separate Wi-Fi latency issue.

## Pending Verification

- [ ] Verify Tailscale service startup after a server reboot.
- [ ] Test remote connectivity after a controlled reboot.
- [ ] Review SSH authentication and access controls.
- [ ] Document additional results if network behavior changes.

## Security

- Never publish Tailscale authentication keys.
- Do not publish SSH private keys or credentials.
- Use authorized devices and accounts only.
- Review access controls before exposing additional services.

## Status

Connectivity and remote SSH access tested. Boot persistence and
post-reboot behavior remain to be verified.


Tailscale README commit karne ke baad bas **“done”** likh dena. Phir hum Docker Networking par aage badhenge.
