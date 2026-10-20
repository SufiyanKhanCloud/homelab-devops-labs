# Homelab Roadmap

This roadmap tracks implementation and verification, not just planned ideas.

## Phase 1: Remote Administration

- [x] Install Tailscale on the server and client.
- [x] Verify connectivity between both devices.
- [x] Test SSH over a mobile-data hotspot.
- [x] Verify MagicDNS hostname-based SSH.
- [ ] Verify Tailscale service startup at boot.
- [ ] Test connectivity after a controlled reboot.
- [ ] Review SSH authentication and access controls.

## Phase 2: Docker and Database Reliability

- [x] Run the Flask/Gunicorn application container.
- [x] Connect the application to PostgreSQL.
- [x] Verify Docker DNS resolution.
- [x] Create a PostgreSQL custom-format backup.
- [x] Inspect the backup archive.
- [x] Restore the backup into a temporary database.
- [x] Verify the restored schema, data, and sequence state.
- [x] Migrate the setup to Docker Compose.
- [x] Verify application health, API behavior, and data persistence.

## Phase 3: Container Security

- [x] Scan the application image using Trivy.
- [x] Generate and inspect a JSON vulnerability report.
- [x] Summarize HIGH findings and unique CVEs.
- [x] Apply Docker runtime hardening controls.
- [x] Verify application behavior after hardening.
- [ ] Investigate current vendor fixes for reported CVEs.
- [ ] Rebuild the image after appropriate package updates.
- [ ] Perform and document a post-remediation scan.
- [ ] Evaluate Trivy integration into CI/CD.

## Phase 4: Monitoring

- [x] Deploy Prometheus and Node Exporter.
- [x] Deploy Grafana and configure its Prometheus data source.
- [x] Build and verify the Node Exporter Full dashboard.
- [x] Configure and test the CPU alert rule, including a threshold simulation.
- [ ] Configure alert notifications.

## Phase 5: CI/CD

- [ ] Implement automated build and test stages.
- [ ] Configure a controlled deployment workflow.
- [ ] Document failure handling and recovery.

## Ongoing Work

- Investigate Wi-Fi latency using measured evidence.
- Document troubleshooting decisions and verified outcomes.
- Review security before every public push.
