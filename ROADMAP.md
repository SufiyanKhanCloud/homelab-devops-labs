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
- [ ] Restore the backup into a temporary database.
- [ ] Verify the restored schema and data.
- [ ] Migrate the setup to Docker Compose.

## Phase 3: Monitoring

- [ ] Deploy Prometheus.
- [ ] Deploy Grafana.
- [ ] Build useful dashboards.
- [ ] Configure and test an alert.

## Phase 4: CI/CD

- [ ] Implement automated build and test stages.
- [ ] Configure a controlled deployment workflow.
- [ ] Document failure handling and recovery.

## Ongoing Work

- Investigate Wi-Fi latency using measured evidence.
- Document troubleshooting decisions and verified outcomes.
- Review security before every public push.
