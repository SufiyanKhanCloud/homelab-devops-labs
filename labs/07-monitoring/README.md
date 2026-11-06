# Lab 07: Monitoring with Prometheus, Grafana and Alertmanager

## Objective

Deploy a self-hosted monitoring stack on an Ubuntu Server homelab to collect host metrics, visualize system health, evaluate alert rules, and deliver monitoring notifications.

This lab covers Prometheus, Node Exporter, Grafana, Alertmanager, Docker Compose, SSH-based remote access, and alert lifecycle testing.

This is a personal homelab implementation, not a production deployment.

## Environment

| Component | Implementation |
|---|---|
| Server OS | Ubuntu Server 24.04.5 LTS |
| Monitoring | Prometheus |
| Host metrics | Prometheus Node Exporter |
| Dashboards | Grafana |
| Alert evaluation | Prometheus alert rules |
| Notification management | Alertmanager |
| Deployment | Docker Compose |
| Dashboard | Node Exporter Full, dashboard ID 1860 |
| Access | SSH tunnel to localhost-bound web interfaces |

The monitoring stack is deployed separately from the application and PostgreSQL stack.

## Architecture

```text
Ubuntu Server
|
|-- Monitoring Docker Compose project
|   |
|   |-- Node Exporter
|   |      |
|   |      |-- Exposes host metrics
|   |
|   |-- Prometheus
|   |      |
|   |      |-- Scrapes monitoring targets
|   |      |-- Stores time-series metrics
|   |      |-- Evaluates alert rules
|   |      |
|   |      +--> Alertmanager
|   |                |
|   |                |-- Receives firing alerts
|   |                |-- Routes notifications
|   |
|   +-- Grafana
|          |
|          |-- Uses Prometheus as its data source
|          |-- Displays host metrics
|
|-- Localhost-bound web interfaces
       |
       |-- Prometheus: 127.0.0.1:9090
       |-- Grafana:    127.0.0.1:3000
       |
       +-- Remote access through SSH tunnelling
```

## Deployment Layout

The monitoring Compose project is maintained separately from the application stack.

The deployed services include:

- **Prometheus:** Collects and stores time-series metrics and evaluates alert rules.
- **Node Exporter:** Exposes host-level metrics for Prometheus to scrape.
- **Grafana:** Queries Prometheus and presents metrics in dashboards.
- **Alertmanager:** Receives alerts from Prometheus and manages notification routing.

The monitoring containers were verified running after a server reboot.

## Network Exposure

Prometheus and Grafana are bound to the server's loopback interface rather than published on all network interfaces.

This prevents their published web interfaces from being directly exposed through those ports to the local network.

Node Exporter and Alertmanager are used by the monitoring stack for metrics collection and alert handling.

Remote access to the dashboards is provided through SSH port forwarding.

### Open a Grafana tunnel

From the management laptop, replace `SERVER_LAN_IP` with the server's current private LAN address:

```bash
ssh -L 3000:127.0.0.1:3000 <server-user>@SERVER_LAN_IP
```

Keep the SSH session open, then visit:

```text
http://127.0.0.1:3000
```

To open the Node Exporter Full dashboard directly:

```text
http://127.0.0.1:3000/d/rYddlPWk/node-exporter-full
```

### Open a Prometheus tunnel

In a separate terminal on the management laptop:

```bash
ssh -L 9090:127.0.0.1:9090 <server-user>@SERVER_LAN_IP
```

Then visit:

```text
http://127.0.0.1:9090
```

Actual LAN addresses, Tailscale addresses, hostnames, and personal usernames are intentionally omitted from this public repository.

## Grafana Configuration

Grafana is configured to use Prometheus as its data source:

```text
http://prometheus:9090
```

The Node Exporter Full dashboard, ID `1860`, was imported and verified displaying host metrics.

The default Grafana administrator password was changed through the web interface.

Credentials and secrets must not be committed to this repository.

## Prometheus Target Verification

Prometheus targets were checked to verify that the configured scrape targets were healthy:

- `prometheus`
- `node-exporter`

Both targets reported `health: up`, with no scrape errors at the time of verification.

Target status can be checked through the Prometheus web interface under **Status → Targets**, or through its targets API.

## CPU Alert Rule

A Prometheus alert rule named `HighCPUUsage` was configured.

The rule evaluates average non-idle CPU usage per instance over a five-minute rate window.

```promql
100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
```

| Setting | Value |
|---|---|
| Alert name | `HighCPUUsage` |
| Threshold | CPU usage greater than 80% |
| Evaluation window | 5-minute rate window |
| Pending duration | 5 minutes |
| Severity | `warning` |

The rule's health was verified as `ok`. Under normal load, its state was `inactive`, which is expected when the threshold condition is not met.

### Alert lifecycle test

The alert lifecycle was tested by temporarily lowering the threshold so the condition could be met using actual metrics.

The alert progressed through:

1. `inactive`
2. `pending`
3. `firing`

The original threshold was then restored to greater than 80%, and the rule was checked again. It returned to `inactive` with rule health `ok`.

This was a threshold simulation, not a CPU stress test. It verified the rule's evaluation and state transitions without claiming that sustained high CPU load occurred naturally.

## Alertmanager and Notification Delivery

Alertmanager is integrated with Prometheus to receive firing alerts and manage notification delivery.

Notification delivery was tested successfully using a Prometheus target-down alert.

The notification was received through the configured email integration.

This confirms that the alerting pipeline can deliver notifications for the tested alert.

**Verification scope:** The successful notification test was for a target-down alert. The `HighCPUUsage` rule's pending and firing transitions were tested separately; a notification specifically triggered by that CPU rule is not claimed here.

Credentials, email addresses, and notification integration secrets are excluded from this public documentation.

## Verification Summary

The following checks were completed:

- [x] Prometheus, Node Exporter, Grafana, and Alertmanager deployed as part of the monitoring stack.
- [x] Prometheus scrape targets reported healthy.
- [x] Grafana connected to Prometheus successfully.
- [x] Node Exporter Full dashboard displayed host metrics.
- [x] CPU alert rule loaded with health `ok`.
- [x] CPU alert transitioned through pending and firing during a threshold simulation.
- [x] Original CPU alert threshold restored and final state verified.
- [x] Alert notification successfully received for a target-down event.
- [x] Monitoring containers verified running after reboot.
- [x] Grafana default administrator password changed.
- [x] Web interfaces remained bound to localhost and were accessed through SSH tunnelling.

## Current Limitations

- The environment is a single-server homelab and does not provide high availability.
- CPU alert lifecycle testing used a temporary threshold change rather than a dedicated CPU stress test.
- Notification delivery was verified for a target-down alert, not separately for the CPU alert.
- Monitoring and notification services depend on the availability of the homelab server and its network connectivity.
- Application and PostgreSQL monitoring can be expanded beyond the current host-level metrics.

## Future Improvements

- Add dedicated application and PostgreSQL monitoring.
- Test CPU alert notification delivery independently.
- Document recovery procedures for monitoring service failures.
- Consider integrating monitoring configuration checks into a future CI/CD workflow.
- Evaluate off-host storage and backup for monitoring configuration and important data.

## Related Labs

- [Linux Server Administration](../01-linux-server/README.md)
- [Tailscale Remote Access](../02-tailscale-remote-access/README.md)
- [Docker Networking](../03-docker-networking/README.md)
- [PostgreSQL Backup and Restore](../04-postgresql-backup-restore/README.md)
- [Docker Compose](../05-docker-compose/README.md)
- [Trivy Container Security](../06-trivy-container-security/README.md)
