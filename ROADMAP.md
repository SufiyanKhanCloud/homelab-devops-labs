# Homelab Roadmap

This roadmap tracks implementation and verification, not just planned ideas. Completed items reflect work that has been implemented and tested.

## Phase 1: Remote Administration

- [x] Install Tailscale on the server and client.
- [x] Verify connectivity between both devices.
- [x] Test SSH over a mobile-data hotspot.
- [x] Verify MagicDNS hostname-based SSH.
- [x] Verify Tailscale service startup at boot.
- [x] Test SSH connectivity after a controlled reboot.
- [x] Configure key-based SSH authentication and review the active UFW access rules.
- [x] Restrict the CI/CD deployment SSH key to the server-side deployment command.

## Phase 2: Docker and Database Reliability

- [x] Run the Flask/Gunicorn application container.
- [x] Connect the application to PostgreSQL.
- [x] Verify Docker DNS resolution.
- [x] Create a PostgreSQL custom-format backup.
- [x] Inspect the backup archive.
- [x] Restore backups into isolated temporary databases.
- [x] Verify restored schema, data, and sequence state during the documented restore tests.
- [x] Migrate the setup to Docker Compose.
- [x] Verify application health, API behavior, and data persistence.
- [x] Automate PostgreSQL backups using a startup-triggered systemd oneshot service.
- [x] Verify backup creation and archive validation, including the October 31, 2026 execution.

## Phase 3: Container Security

- [x] Scan the application image using Trivy.
- [x] Generate and inspect a JSON vulnerability report.
- [x] Summarize historical HIGH findings and unique CVEs.
- [x] Apply Docker runtime hardening controls.
- [x] Verify application behavior after hardening.
- [ ] Investigate vendor fixes for the reported CVEs.
- [ ] Rebuild the image after appropriate package updates.
- [ ] Perform and document a post-remediation scan.
- [ ] Evaluate Trivy integration into CI/CD.

## Phase 4: Monitoring

- [x] Deploy Prometheus and Node Exporter.
- [x] Deploy Grafana and configure its Prometheus data source.
- [x] Build and verify the Node Exporter Full dashboard.
- [x] Configure and test the CPU alert rule, including a controlled threshold simulation.
- [x] Verify Prometheus and Grafana use persistent storage volumes.
- [x] Keep Prometheus and Grafana web interfaces bound to localhost.
- [x] Verify monitoring containers and scrape targets.
- [ ] Configure alert notifications.

## Phase 5: CI/CD

- [x] Add a GitHub Actions workflow for automated testing and coverage reporting.
- [x] Build the application Docker image in CI.
- [x] Configure Docker Hub publishing for pushes to `main`.
- [x] Tag published images with the full Git commit SHA.
- [x] Configure Tailscale authentication for GitHub Actions.
- [x] Configure SSH deployment with strict host-key verification.
- [x] Restrict the deployment SSH key to a server-side deployment script.
- [x] Validate deployment arguments and accept only full SHA-tagged images.
- [x] Pull and deploy the requested image on the homelab.
- [x] Update only the application service during deployment.
- [x] Verify the initial automated deployment and API health.
- [x] Confirm existing notes remain accessible after deployment.
- [x] Verify a subsequent automated deployment triggered by a workflow configuration change.
- [ ] Test deployment triggered by a fresh application-code change pushed to `main`.
- [ ] Verify the new application image is deployed and healthy.
- [ ] Implement and test deployment failure recovery and rollback procedures.

## Ongoing Work

- Investigate Wi-Fi latency using measured evidence.
- Document troubleshooting decisions and verified outcomes.
- Review security before every public push.
- Keep historical vulnerability scan results separate from current image security status.
- Keep documentation aligned with the actual implementation.
