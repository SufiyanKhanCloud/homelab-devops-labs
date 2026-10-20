## Objective

Deploy a self-hosted monitoring stack on the Ubuntu Server homelab to collect host metrics, visualize system health, and evaluate a CPU usage alert.

This is a personal homelab implementation, not a production deployment.

## Environment

| Component | Implementation |
|---|---|
| Server OS | Ubuntu Server 24.04.5 LTS |
| Monitoring | Prometheus |
| Host metrics | Prometheus Node Exporter |
| Dashboards | Grafana |
| Deployment | Docker Compose |
| Dashboard | Node Exporter Full, dashboard ID 1860 |
| Access | SSH tunnel to localhost-bound web interfaces |

The monitoring stack is deployed separately from the notes application and PostgreSQL stack.

## Architecture

```text
Ubuntu Server
|
|-- Monitoring Docker Compose project
|   |
|   |-- Node Exporter
|   |      |
|   |      |-- Exposes host metrics on port 9100
|   |
|   |-- Prometheus
|   |      |
|   |      |-- Scrapes Prometheus and Node Exporter
|   |      |-- Evaluates alert rules
|   |
|   |-- Grafana
|          |
|          |-- Uses Prometheus as its data source
|          |-- Displays host metrics in dashboards
|
|-- Localhost-bound web interfaces
       |
       |-- Prometheus: 127.0.0.1:9090
       |-- Grafana:    127.0.0.1:3000
       |
       `-- Access remotely through an SSH tunnel
```

## Deployment Layout

The monitoring Compose project is stored on the server at:

```text
~/lab/monitoring
```

The deployed services are:

- **Prometheus:** Collects and stores time-series metrics and evaluates alert rules.
- **Node Exporter:** Exposes host-level metrics for Prometheus to scrape.
- **Grafana:** Queries Prometheus and presents metrics in dashboards.

The monitoring containers were verified running after a server reboot.

## Network Exposure

Prometheus and Grafana are bound to the server's loopback interface rather than published on all network interfaces.

This keeps their web interfaces from being directly exposed to the local network through those published ports. Node Exporter is used internally by Prometheus.

Remote access to the dashboards is provided through SSH port forwarding.

### Open a Grafana tunnel

From the management laptop, replace `SERVER_LAN_IP` with the server's current private LAN address:

```bash
ssh -L 3000:127.0.0.1:3000 sufiyan@SERVER_LAN_IP
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
ssh -L 9090:127.0.0.1:9090 sufiyan@SERVER_LAN_IP
```

Then visit:

```text
http://127.0.0.1:9090
```

The actual LAN and Tailscale addresses are intentionally omitted from this public repository.

## Grafana Configuration

Grafana is configured to use Prometheus as its data source:

```text
http://prometheus:9090
```

The Node Exporter Full dashboard, ID `1860`, was imported and verified displaying host metrics.

The Grafana default administrator password was changed through the web interface. Credentials and secrets must not be committed to this repository.

## Prometheus Target Verification

Prometheus's targets API was checked to verify that both configured scrape targets were healthy:

- `prometheus`
- `node-exporter`

Both targets reported `health: up`, with no scrape error reported at the time of verification.

The target status can be checked through the Prometheus web interface under **Status → Targets**, or by querying its targets API.

## CPU Alert Rule

A Prometheus alert rule named `HighCPUUsage` was configured in:

```text
/etc/prometheus/rules/host-alerts.yml
```

The rule expression is:

```promql
100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
```

The rule evaluates average non-idle CPU usage per instance over a five-minute rate window.

| Setting | Value |
|---|---|
| Alert name | `HighCPUUsage` |
| Threshold | CPU usage greater than 80% |
| Evaluation window | 5-minute rate window |
| Pending duration | 5 minutes |
| Severity | `warning` |

The rule's health was verified as `ok`. Under normal load, its state was `inactive`, which is expected when the threshold condition is not met.

### Alert lifecycle test

The alert lifecycle was tested by temporarily lowering the threshold so the condition could be met using actual metrics. The alert progressed through `pending` and `firing`.

The original threshold was then restored to greater than 80%, Prometheus was restarted, and the rule was checked again. It returned to `inactive` with rule health `ok`.

This was a threshold simulation, not a CPU stress test. It verified the rule's evaluation and state transitions without claiming that sustained high CPU load occurred naturally.

## Verification Summary

The following checks were completed:

- [x] Prometheus, Node Exporter, and Grafana containers were running.
- [x] Both Prometheus scrape targets reported healthy.
- [x] Grafana connected to Prometheus successfully.
- [x] The Node Exporter Full dashboard displayed host metrics.
- [x] The CPU alert rule loaded with health `ok`.
- [x] The alert's pending and firing states were tested through a temporary threshold change.
- [x] The original alert threshold was restored and its final state verified.
- [x] Monitoring containers were verified running after reboot.
- [x] Grafana's default administrator password was changed.
- [x] Web interfaces remained bound to localhost and were accessed through SSH tunnelling.

## Current Limitations

- Alert notification delivery is not configured.
- The alert test validated rule state transitions, not delivery to an external notification service.
- A threshold simulation was performed instead of a CPU stress test.
- The setup is a single-server homelab and does not provide high availability for the monitoring stack.

## Future Improvements

- Configure and test an alert notification integration.
- Document recovery procedures for monitoring service failures.
- Add monitoring checks for the application and PostgreSQL services.
- Consider integrating monitoring configuration checks into a future CI/CD workflow.

## Related Labs

- [Linux Server Administration](../01-linux-server/README.md)
- [Tailscale Remote Access](../02-tailscale-remote-access/README.md)
- [Docker Networking](../03-docker-networking/README.md)
- [PostgreSQL Backup and Restore](../04-postgresql-backup-restore/README.md)
- [Docker Compose](../05-docker-compose/README.md)
- [Trivy Container Security](../06-trivy-container-security/README.md)
