# Homelab Roadmap

This roadmap tracks implementation and verification, not just planned ideas. Completed items reflect work that has been implemented and tested. Historical test results are identified where relevant.

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
- [x] Automate PostgreSQL backups using a root-owned, startup-triggered systemd oneshot service.
- [x] Add backup locking, archive validation, atomic file handling, and retention of the seven newest backups.
- [x] Verify successful backup creation and archive validation, including the November 6, 2026 execution.

**Backup scheduling note:** The service runs after system startup with a five-minute delay and skips additional backups after a successful backup on the same date. It is not a daily systemd timer and does not guarantee a backup every calendar day if the server remains continuously online.

## Phase 3: Container Security

- [x] Scan the application image using Trivy.
- [x] Generate and inspect a JSON vulnerability report.
- [x] Summarize historical HIGH findings and unique CVEs.
- [x] Apply Docker runtime hardening controls.
- [x] Verify application behavior after hardening.
- [x] Integrate Trivy image scanning into the CI workflow.
- [ ] Investigate vendor fixes for the reported CVEs.
- [ ] Rebuild the image after appropriate package updates.
- [ ] Perform and document a post-remediation scan.

**Security note:** The documented vulnerability findings are from a historical scan. They should not be treated as a verified assessment of the current image until a new scan is completed.

## Phase 4: Monitoring

- [x] Deploy Prometheus and Node Exporter.
- [x] Deploy Grafana and configure its Prometheus data source.
- [x] Build and verify the Node Exporter Full dashboard.
- [x] Configure and test the CPU alert rule, including a controlled threshold simulation.
- [x] Verify Prometheus and Grafana use persistent storage volumes.
- [x] Keep Prometheus and Grafana web interfaces bound to localhost.
- [x] Verify monitoring containers and scrape targets.
- [x] Configure Alertmanager email notifications.
- [x] Verify email delivery using a Prometheus target-down alert.

**Notification note:** Target-down email delivery has been verified. Successful email delivery for the CPU alert has not yet been separately tested.

## Phase 5: CI/CD

- [x] Add a GitHub Actions workflow for automated testing and coverage reporting.
- [x] Build the application Docker image in CI.
- [x] Configure Docker Hub publishing for pushes to `main`.
- [x] Tag published images with the full Git commit SHA.
- [x] Integrate Trivy image scanning into CI.
- [x] Configure Tailscale authentication for GitHub Actions.
- [x] Configure SSH deployment with strict host-key verification.
- [x] Restrict the deployment SSH key to a server-side deployment script.
- [x] Validate deployment arguments and accept only full SHA-tagged images.
- [x] Pull and deploy the requested image on the homelab.
- [x] Update only the application service during deployment.
- [x] Verify the initial automated deployment and API health.
- [x] Confirm existing notes remain accessible after deployment.
- [x] Verify a subsequent automated deployment triggered by a workflow configuration change.
- [x] Implement a restricted deployment account and root-controlled deployment helper.
- [x] Implement deployment health verification and rollback to the previous image.
- [x] Test rollback using a controlled health-verification failure.
- [ ] Test deployment triggered by a fresh application-code change pushed to `main`.
- [ ] Verify the new application image is deployed and healthy following that code change.
- [ ] Test additional deployment failure scenarios and recovery behavior.

**Deployment note:** The rollback test verified recovery from a deliberately forced health-verification failure. It does not establish that every possible deployment failure scenario has been tested.

## Ongoing Work

- Investigate Wi-Fi latency using measured evidence.
- Document troubleshooting decisions and verified outcomes.
- Review security before every public push.
- Keep historical vulnerability scan results separate from current image security status.
- Keep documentation aligned with the actual implementation.
