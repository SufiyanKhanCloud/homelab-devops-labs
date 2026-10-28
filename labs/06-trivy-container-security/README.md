# Lab 06: Trivy Vulnerability Scanning and Container Hardening

## Overview

This lab focuses on identifying known vulnerabilities in a Docker image using Trivy and reducing the runtime attack surface through Docker security controls.

The target is a Flask-based notes application running with PostgreSQL through Docker Compose on a self-hosted Ubuntu Server.

The lab covers vulnerability assessment, machine-readable reporting, container hardening, application verification, and remediation planning.

### Objectives

- Scan a Docker image using Trivy.
- Analyze OS package vulnerabilities and severity classifications.
- Identify unique CVEs and inspect available fixed-version information.
- Generate and inspect a JSON vulnerability report.
- Apply Docker runtime security controls.
- Verify the effective security configuration of the running container.
- Document findings, limitations, and future remediation steps.

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
| Historical JSON report | `trivy-final.json` |

The historical JSON report is stored on the homelab server at:

`/home/sufiyan/lab/notes-app/trivy-final.json`

The report is not stored in this GitHub repository.

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

Generate a machine-readable JSON report:

```bash
trivy image \
  --severity HIGH,CRITICAL \
  --format json \
  --output trivy-followup.json \
  notes-app:3
```

The JSON output file is created in the current working directory unless an absolute path is specified.

**Important:** The command above generates a new report. It does not modify the historical `trivy-final.json` report.

### Historical Scan Details

The saved report records the scan timestamp as:

`2026-10-17T12:44:36.159270286+05:00`

The artifact was identified as `notes-app:3`, with the image ID recorded in the report metadata.

These results represent the historical scan. They should not be interpreted as the current vulnerability status of a newly rebuilt image.

## 2. Historical Scan Results

The saved Trivy report contains the following findings:

| Metric | Result |
|---|---:|
| HIGH findings | 44 |
| CRITICAL findings | 0 |
| Unique CVEs | 8 |
| OS package findings | 44 |
| HIGH/CRITICAL Python dependency findings | 0 |

All 44 findings were associated with Debian OS packages in the saved report.

No HIGH or CRITICAL Python dependency findings were reported in that scan.

A vulnerability finding is not necessarily equivalent to a unique CVE. Multiple installed packages can be associated with the same CVE.

### Unique CVEs

The report identified these eight unique CVE identifiers:

- CVE-2025-69720
- CVE-2026-16742
- CVE-2026-54369
- CVE-2026-76642
- CVE-2026-78408
- CVE-2026-78409
- CVE-2026-78410
- CVE-2026-9538

These identifiers are recorded from the historical report. Their current status and available remediation should be checked against current vendor security advisories before making upgrade decisions.

### Findings by Package Group

The package-level results were grouped as follows:

| Package group | Findings |
|---|---:|
| util-linux-related packages | 36 |
| ncurses packages | 4 |
| systemd and udev libraries | 2 |
| `libacl1` | 1 |
| `perl-base` | 1 |
| **Total** | **44** |

The util-linux-related group includes packages such as `bsdutils`, `libblkid1`, `liblastlog2-2`, `libmount1`, `libsmartcols1`, `libuuid1`, `login`, `mount`, and `util-linux`.

The ncurses group includes `libncursesw6`, `libtinfo6`, `ncurses-base`, and `ncurses-bin`.

The systemd and udev group includes `libsystemd0` and `libudev1`.

### Fixed-Version Information

The saved report did not list a fixed version for any of the 44 findings.

This means that the `FixedVersion` field was absent or empty in the historical report. It does **not** establish that no vendor fix exists.

Further investigation against current Debian security advisories and package repositories is required to determine whether updated packages are available.

## 3. Inspecting the JSON Report

The following commands are intended to run on the homelab server, where the historical report is stored.

Change to the application directory:

```bash
cd /home/sufiyan/lab/notes-app
```

### Count Findings by Severity

```bash
python3 - <<'PY'
import json
from collections import Counter

path = "trivy-final.json"

with open(path) as f:
    report = json.load(f)

counts = Counter()

for result in report.get("Results", []):
    for vulnerability in result.get("Vulnerabilities") or []:
        counts[vulnerability.get("Severity", "UNKNOWN")] += 1

print("Artifact:", report.get("ArtifactName"))
print("Severity counts:")

for severity, count in sorted(counts.items()):
    print(f"{severity}: {count}")
PY
```

### Count Unique CVEs

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

### Inspect Report Metadata

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

These commands read the existing JSON report without printing the full report or changing the running application.

## 4. Docker Runtime Hardening

Image vulnerability scanning and runtime hardening address different security concerns.

The historical Trivy report identifies known vulnerabilities associated with image packages. It does not establish whether the container's runtime security controls are configured correctly.

The following controls were applied to the application container and verified separately.

### Non-Root Execution

The Dockerfile creates a dedicated system user:

```dockerfile
USER app
```

The application runs as the non-root user `app`, with UID `10001`.

Running an application without root privileges limits the privileges available to the application process if it is compromised.

### Read-Only Root Filesystem

The Compose configuration enables:

```yaml
read_only: true
```

This makes the container's root filesystem read-only. Writable locations must be explicitly provided when required.

The application uses a temporary filesystem for `/tmp`.

### Dropping Linux Capabilities

The application service drops all Linux capabilities:

```yaml
cap_drop:
  - ALL
```

This removes the container's Linux capability set. Additional capabilities should only be granted if a demonstrated application requirement exists.

### Preventing Privilege Escalation

The container uses:

```yaml
security_opt:
  - no-new-privileges:true
```

This prevents processes from gaining additional privileges through supported mechanisms such as set-user-ID and set-group-ID executables.

### Restricting Temporary Storage

The application uses the following temporary filesystem configuration:

```yaml
tmpfs:
  - /tmp:rw,noexec,nosuid,size=64m
```

This provides temporary writable storage while applying the `noexec` and `nosuid` mount options.

### Restricting Network Exposure

The application port is bound to the host's loopback interface:

```yaml
ports:
  - "127.0.0.1:5000:5000"
```

This restricts direct host-port exposure to the loopback interface. Remote access requires an appropriate access path, such as an authenticated reverse proxy or VPN.

The PostgreSQL service does not publish its database port directly on the host.

### Other Application Container Settings

The application image uses:

- Python 3.12 slim as its base image.
- Gunicorn with two workers.
- A Docker health check targeting `/health`.
- Environment variables for database connection settings.

The database service has its own health check using `pg_isready`.

These controls improve the deployment's security posture but do not eliminate all container, host, application, or supply-chain risks.

## 5. Verifying Runtime Security Settings

The running application container was inspected using Docker:

```bash
docker inspect notes-app-app-1 \
  --format 'User={{.Config.User}} ReadonlyRootfs={{.HostConfig.ReadonlyRootfs}} CapDrop={{json .HostConfig.CapDrop}} SecurityOpt={{json .HostConfig.SecurityOpt}}'
```

### Verified Output

```text
User=app ReadonlyRootfs=true CapDrop=["ALL"] SecurityOpt=["no-new-privileges:true"]
```

This confirms that the inspected running container had the following settings:

| Security control | Observed value | Status |
|---|---|---|
| Container user | `app` | Verified |
| Read-only root filesystem | `true` | Verified |
| Dropped capabilities | `ALL` | Verified |
| Privilege escalation protection | `no-new-privileges:true` | Verified |

This inspection confirms the effective settings returned by Docker for the running container. It is not a complete security audit and does not prove that the image contains no vulnerabilities.

## 6. Application Verification

After runtime hardening, the application was checked to ensure it remained operational.

### Check Container Status

```bash
docker ps --format 'table {{.Names}}\t{{.Status}}'
```

### Check Application Health

```bash
docker inspect \
  --format '{{.Name}}: {{.State.Status}} / {{if .State.Health}}{{.State.Health.Status}}{{else}}no healthcheck{{end}}' \
  notes-app-app-1
```

### Check Database Health

```bash
docker inspect \
  --format '{{.Name}}: {{.State.Status}} / {{if .State.Health}}{{.State.Health.Status}}{{else}}no healthcheck{{end}}' \
  notes-app-db-1
```

### Test the Application Health Endpoint

```bash
curl -i http://127.0.0.1:5000/health
```

### Test the Notes API

```bash
curl -s http://127.0.0.1:5000/notes
```

### Check Published Ports

```bash
docker port notes-app-app-1
```

The application health endpoint, API behavior, and data persistence were verified after the runtime hardening changes.

These application checks complement the runtime inspection: one checks application behavior, while the other checks selected container configuration settings.

## 7. Understanding the Security Results

### Image Vulnerability Scanning

Trivy helps identify known vulnerabilities associated with installed image packages.

The findings can be used to:

- Prioritize security investigation.
- Identify potentially affected packages.
- Review CVE identifiers and severity classifications.
- Check whether fixed-version information is available.
- Preserve machine-readable scan evidence.

### Runtime Hardening

Docker runtime controls help reduce the privileges and resources available to a running application.

The controls used in this lab include non-root execution, a read-only root filesystem, dropped Linux capabilities, privilege-escalation restrictions, temporary storage restrictions, and loopback-only port binding.

### Why Both Are Necessary

Runtime hardening does not remove vulnerable packages from an image.

Similarly, rebuilding an image with updated packages does not automatically guarantee that the resulting container has appropriate runtime restrictions.

A more complete workflow combines image scanning, package remediation, image rebuilding, runtime hardening, and post-change functional verification.

## 8. Limitations and Future Remediation

The saved scan is historical. Its results should not be treated as a current assessment of a newly rebuilt image.

The following activities remain future work:

1. Review the eight CVEs against current Debian security advisories.
2. Determine whether updated package versions are available.
3. Update the base image or affected packages where appropriate.
4. Rebuild the application image.
5. Scan the rebuilt image using an updated vulnerability database.
6. Compare the new findings with the historical report.
7. Test application functionality and database persistence after rebuilding.
8. Consider integrating Trivy into the CI/CD pipeline.
9. Define a vulnerability policy for failing builds when specified severity thresholds are exceeded.

The historical report should be retained as evidence of the October 17 scan. Any subsequent scan should be saved separately so the results can be compared over time.

No post-remediation scan is claimed in this lab documentation.

## Key Takeaways

- Trivy can identify known vulnerabilities in container images and generate machine-readable reports.
- Package-level findings and unique CVEs represent different measurements.
- A missing fixed-version field does not prove that no vendor fix exists.
- Runtime hardening and image vulnerability remediation are separate activities.
- Docker inspection can verify selected runtime configuration settings.
- Application health checks and API tests help confirm that security changes have not broken the application.
- Rebuilding and rescanning are necessary to assess whether package remediation reduced the reported findings.

## Lab Status

- [x] Scan the application image using Trivy.
- [x] Generate and inspect a JSON vulnerability report.
- [x] Verify severity counts and unique CVEs from the saved report.
- [x] Inspect package-level findings and fixed-version information.
- [x] Apply Docker runtime hardening controls.
- [x] Verify runtime security settings using Docker inspection.
- [x] Verify application health, API behavior, and persistence after hardening.
- [ ] Investigate current vendor fixes for the reported CVEs.
- [ ] Rebuild the image after appropriate package updates.
- [ ] Perform and document a separate post-remediation scan.
- [ ] Integrate image scanning into CI/CD.

---

**Environment:** Self-hosted Ubuntu Server homelab  
**Focus:** Container security, vulnerability assessment, runtime hardening, and verification
