# Lab 06: Trivy Vulnerability Scanning and Container Hardening

## Overview

This lab focuses on scanning a Docker container image for known vulnerabilities and applying runtime security controls to reduce the container's attack surface.

The target application is a Flask-based notes application running with PostgreSQL through Docker Compose on a self-hosted Ubuntu Server.

**Objectives:**
- Scan a Docker image using Trivy.
- Identify and summarize OS package vulnerabilities.
- Inspect vulnerability findings and available fix-version information.
- Generate a machine-readable JSON report.
- Apply Docker runtime hardening controls.
- Verify that the application remains functional after hardening.
- Document findings, limitations, and potential remediation steps.

## Environment

| Component | Details |
|---|---|
| Host OS | Ubuntu Server 24.04.5 LTS |
| Container runtime | Docker |
| Orchestration | Docker Compose |
| Vulnerability scanner | Trivy 0.76.0 |
| Application | Flask notes application |
| Application image | `notes-app:3` |
| Base OS identified by Trivy | Debian 13.7 |
| Database | PostgreSQL 16 |
| Application port | `127.0.0.1:5000` |
| Vulnerability report | `trivy-final.json` |

## 1. Vulnerability Scanning with Trivy

Trivy was used to scan the application image for known vulnerabilities.

Check the installed scanner version:

```bash
trivy --version
```

Scan for HIGH and CRITICAL vulnerabilities:

```bash
trivy image --severity HIGH,CRITICAL notes-app:3
```

Generate a JSON report:

```bash
trivy image \
  --severity HIGH,CRITICAL \
  --format json \
  --output trivy-final.json \
  notes-app:3
```

The existing report was generated on **October 17, 2026, at 12:44:36 PKT**.

The report identifies the scanned artifact as `notes-app:3` and records the image ID associated with that scan.

## 2. Scan Results

The existing Trivy report contains the following results:

| Metric | Result |
|---|---:|
| HIGH findings | 44 |
| CRITICAL findings | 0 |
| Unique CVEs | 8 |
| OS package findings | 44 |
| Python dependency findings | 0 |

All 44 findings in this report were associated with Debian OS packages.

No HIGH or CRITICAL findings were reported for Python dependencies in this scan.

### Unique CVEs

The report identified these eight unique CVEs:

- CVE-2025-69720
- CVE-2026-16742
- CVE-2026-54369
- CVE-2026-76642
- CVE-2026-78408
- CVE-2026-78409
- CVE-2026-78410
- CVE-2026-9538

### Affected Package Groups

| Package group | Findings |
|---|---:|
| util-linux-related packages | 36 |
| ncurses packages | 4 |
| systemd and udev libraries | 2 |
| libacl1 | 1 |
| perl-base | 1 |
| **Total** | **44** |

The same CVE can affect multiple installed packages. Therefore, 44 package-level findings do not represent 44 unique CVEs.

### Fixed-Version Information

The inspected report did not list a fixed version for any of the 44 findings.

This does not establish that no vendor fix exists. It means the report did not provide a fixed version for those findings at the time of the scan.

Further investigation against current Debian security advisories and package repositories would be required before deciding on package upgrades or other remediation.

## 3. Inspecting the JSON Report

The report can be inspected programmatically without printing the entire JSON file.

Count the reported vulnerabilities by severity:

```bash
python3 - <<'PY'
import json
from collections import Counter

with open("trivy-final.json") as f:
    report = json.load(f)

counts = Counter()

for result in report.get("Results", []):
    for vulnerability in result.get("Vulnerabilities") or []:
        counts[vulnerability.get("Severity", "UNKNOWN")] += 1

print("Vulnerability counts:")
for severity, count in sorted(counts.items()):
    print(f"{severity}: {count}")
PY
```

Count unique CVEs:

```bash
python3 - <<'PY'
import json

with open("trivy-final.json") as f:
    report = json.load(f)

cves = {
    vulnerability.get("VulnerabilityID")
    for result in report.get("Results", [])
    for vulnerability in result.get("Vulnerabilities") or []
    if vulnerability.get("VulnerabilityID")
}

print("Unique CVEs:", len(cves))
PY
```

Inspect the report timestamp and artifact information:

```bash
python3 - <<'PY'
import json

with open("trivy-final.json") as f:
    report = json.load(f)

print("Artifact:", report.get("ArtifactName"))
print("Artifact type:", report.get("ArtifactType"))
print("Report timestamp:", report.get("CreatedAt"))
print("Schema version:", report.get("SchemaVersion"))

metadata = report.get("Metadata") or {}
print("Image ID:", metadata.get("ImageID"))
PY
```

## 4. Docker Runtime Hardening

After reviewing the vulnerability findings, runtime security controls were applied to reduce the application's attack surface.

### Non-Root User

The application runs under a dedicated non-root user named `app`.

Running as a non-root user reduces the privileges available to a compromised application process.

### Read-Only Root Filesystem

The application container uses a read-only root filesystem:

```yaml
read_only: true
```

This prevents normal writes to the container's root filesystem. Applications that require writable paths must be provided with explicitly configured writable mounts or temporary filesystems.

### Dropping Linux Capabilities

The container drops all Linux capabilities:

```yaml
cap_drop:
  - ALL
```

This removes the container's default Linux capability set. Additional capabilities should only be granted when there is a demonstrated requirement.

### Preventing Privilege Escalation

The container uses:

```yaml
security_opt:
  - no-new-privileges:true
```

This prevents processes inside the container from gaining additional privileges through mechanisms such as set-user-ID and set-group-ID executables.

### Restricting Temporary Storage

The application uses a temporary filesystem for `/tmp`:

```yaml
tmpfs:
  - /tmp:rw,noexec,nosuid,size=64m
```

This provides temporary writable storage while applying the `noexec` and `nosuid` mount options.

The application must be tested to ensure that its temporary-storage requirements are satisfied.

### Localhost-Only Port Binding

The application port is bound to the host's loopback interface:

```yaml
ports:
  - "127.0.0.1:5000:5000"
```

This limits direct access through the host's external network interfaces. Remote access requires an appropriate access path, such as an authenticated reverse proxy or VPN.

The PostgreSQL service does not publish its database port directly on the host.

## 5. Applying the Hardening Configuration

Before changing the Compose configuration, preserve the previous version:

```bash
cp compose.yaml compose.yaml.before-hardening
```

Review the configuration:

```bash
docker compose config
```

Apply the configuration changes and recreate only the application service:

```bash
docker compose up -d --no-deps app
```

The `--no-deps` option avoids recreating dependent services as part of this application-service operation.

**Note:** The commands above describe the configuration workflow. The hardening changes were applied and tested separately from the October 17 vulnerability report. That report should not be treated as a post-hardening scan.

## 6. Verification

After applying runtime hardening, verify that the application and database remain operational.

Check container status:

```bash
docker ps --format 'table {{.Names}}\t{{.Status}}'
```

Inspect the application health status:

```bash
docker inspect \
  --format '{{.Name}}: {{.State.Status}} / {{if .State.Health}}{{.State.Health.Status}}{{else}}no healthcheck{{end}}' \
  notes-app-app-1
```

Inspect the database health status:

```bash
docker inspect \
  --format '{{.Name}}: {{.State.Status}} / {{if .State.Health}}{{.State.Health.Status}}{{else}}no healthcheck{{end}}' \
  notes-app-db-1
```

Check the application locally:

```bash
curl -i http://127.0.0.1:5000/
```

Use the application's actual health endpoint instead if the root route is not designed for health checks.

Check the published port bindings:

```bash
docker port notes-app-app-1
```

Review the effective runtime configuration without dumping the entire container inspection output:

```bash
docker inspect notes-app-app-1 \
  --format 'User={{.Config.User}} ReadonlyRootfs={{.HostConfig.ReadonlyRootfs}} CapDrop={{json .HostConfig.CapDrop}} SecurityOpt={{json .HostConfig.SecurityOpt}}'
```

The expected configuration includes a non-root application user, a read-only root filesystem, dropped capabilities, and the `no-new-privileges` security option.

Application health, API behavior, and data persistence were verified after the runtime hardening changes.

## 7. Understanding the Results

Vulnerability scanning and runtime hardening address different aspects of container security.

**Image vulnerability scanning:**
- Identifies known vulnerabilities associated with installed packages.
- Helps prioritize investigation and remediation.
- Provides a record of findings for a particular scan and image.

**Runtime hardening:**
- Reduces the privileges available to the application.
- Limits filesystem write access.
- Removes unnecessary Linux capabilities.
- Restricts privilege escalation.
- Limits direct network exposure.

Runtime hardening does not remove vulnerable packages from the image. Image remediation requires separate investigation, package updates or base-image changes, a rebuild, and another scan.

Similarly, a scan with no reported findings would not prove that an image is completely secure.

## 8. Limitations and Next Steps

The existing scan identified 44 HIGH findings across eight unique CVEs in Debian OS packages.

The following work remains appropriate for future iterations:

1. Review the CVEs against current Debian security advisories.
2. Determine whether patched package versions are available.
3. Update the base image and OS packages where appropriate.
4. Rebuild the application image.
5. Scan the rebuilt image using an updated vulnerability database.
6. Compare the new findings with the existing report.
7. Test application functionality and persistence after rebuilding.
8. Consider adding vulnerability scanning to the CI pipeline.
9. Define a policy for failing builds when specified vulnerability thresholds are exceeded.

The existing JSON report is retained as evidence of the October 17 scan. A later scan should be saved separately when comparing findings over time.

## Key Takeaways

- Trivy can identify known vulnerabilities in container images and export machine-readable reports.
- Package-level finding counts and unique CVE counts represent different measurements.
- Vulnerabilities in OS packages require investigation even when application-language dependencies have no reported findings.
- Runtime hardening reduces attack surface but does not patch vulnerable packages.
- Reproducible scans, preserved reports, and post-change verification help establish a reliable security workflow.

## Lab Status

- [x] Scan the Docker image using Trivy.
- [x] Generate and inspect a JSON vulnerability report.
- [x] Summarize severity counts and unique CVEs.
- [x] Apply Docker runtime hardening controls.
- [x] Verify application health and functionality after hardening.
- [ ] Investigate current vendor fixes for the reported CVEs.
- [ ] Rebuild the image after appropriate package updates.
- [ ] Perform and document a separate post-remediation scan.
- [ ] Integrate image scanning into CI/CD.

---

**Environment:** Self-hosted Ubuntu Server homelab  
**Focus:** Container security, vulnerability assessment, Docker hardening, and verification
