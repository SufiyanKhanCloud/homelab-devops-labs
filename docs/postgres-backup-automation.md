# PostgreSQL Backup Automation

## Overview

This document describes the PostgreSQL backup automation implemented for the Docker Compose notes application running on a homelab server.

The current implementation uses a root-owned Bash script, Docker, PostgreSQL utilities, and systemd to create timestamped PostgreSQL custom-format backups, validate the resulting archives, and retain the seven newest matching backup files.

A successful backup is recorded against the server's local calendar date. This prevents duplicate successful backups on the same day.

The systemd service is enabled for startup-triggered execution. It waits five minutes after the service is triggered before running the backup script. The previous daily 2 AM timer is disabled, so this configuration does not guarantee a new backup every day while the server remains online.

## Environment

| Component | Details |
|---|---|
| Operating system | Ubuntu Server 24.04.5 LTS |
| Database | PostgreSQL 16 |
| Docker Compose database service | `db` |
| Database name | `postgres` |
| Database user | `postgres` |
| Backup format | PostgreSQL custom archive (`pg_dump -Fc`) |
| Backup directory | Host-local backup directory |
| Backup script on server | `/usr/local/sbin/postgres-backup` |
| Script owner and permissions | `root:root`, `0700` |
| systemd service | `postgres-backup.service` |
| Automation | systemd oneshot service |
| Retention policy | Seven newest matching dump files |

Runtime container identifiers and absolute filesystem paths are intentionally omitted from this public documentation.

## Repository Files

- Repository backup script: [`labs/05-docker-compose/scripts/backup-postgres.sh`](../labs/05-docker-compose/scripts/backup-postgres.sh)
- Docker Compose lab: [`labs/05-docker-compose/README.md`](../labs/05-docker-compose/README.md)
- Backup and restore lab: [`labs/04-postgresql-backup-restore/README.md`](../labs/04-postgresql-backup-restore/README.md)

**Implementation distinction:** The script stored in the repository is a lab/reference script. The currently deployed server implementation uses a separately installed root-owned backup script. Do not assume the repository script is identical to the deployed script.

The server script and its configuration must be reviewed and adapted before use on another machine.

## Backup Workflow

The deployed backup script performs the following operations:

1. Enables strict Bash error handling and sets a restrictive default file-creation mask.
2. Creates the backup directory if necessary and applies directory permissions of `0700`.
3. Acquires a non-blocking file lock to prevent concurrent backup processes.
4. Checks whether a successful backup has already been recorded for the current local calendar date.
5. Checks whether the PostgreSQL container is available.
6. Waits for PostgreSQL readiness, retrying up to 30 times with a 10-second interval.
7. Creates a temporary backup file inside the backup directory.
8. Runs `pg_dump` to create a custom-format database archive.
9. Rejects an empty backup file.
10. Validates the archive using `pg_restore --list`.
11. Applies file permissions of `0600` to the completed temporary archive.
12. Moves the validated archive to its timestamped final filename.
13. Retains the seven newest matching dump files and removes older matching files.
14. Writes the successful backup date to a temporary state file and atomically moves it into place.
15. Logs successful completion.

The script also uses an exit trap to remove temporary backup and state files if they remain when the script exits.

### Backup Validation

The script checks that:

- The generated archive is non-empty.
- PostgreSQL can read its archive structure using `pg_restore --list`.

These checks help reject incomplete or unreadable archive files before they are accepted as completed backups.

However, archive listing validation is not equivalent to restoring the database. Recovery testing must be performed separately.

## Backup Naming

Backup filenames use the following format:

`notes-db-YYYY-MM-DD-HHMMSS.dump`

Example:

`notes-db-2026-11-06-162336.dump`

The date and time in the filename are based on the server's local clock when the script initializes.

The naming convention makes backups identifiable by their creation timestamp and allows the retention logic to sort matching filenames in reverse lexical order.

## Permissions and Runtime State

The deployed script uses:

```bash
umask 077
```

This restricts default permissions for newly created files and directories to the owning user, subject to the permissions applied by the script and filesystem.

| Item | Verified configuration or behavior |
|---|---|
| Backup directory | `root:root`, `0700` |
| Completed backup archives | `root:root`, `0600` |
| Backup script on the server | `root:root`, `0700` |
| systemd service user | `root` |
| systemd service group | `root` |
| systemd service umask | `0077` |
| `.backup.lock` | Runtime file used for process locking |
| `.last-successful-backup-date` | Records the last successful backup date |
| Temporary backup file | Created inside the backup directory and removed on exit if it remains |
| Temporary state file | Used when recording successful completion |

The lock and success-state files are operational runtime state. They should not be committed to the repository.

Database dumps, credentials, private keys, and temporary environment files must not be published in Git.

## systemd Service

The service unit is installed on the homelab server at:

`/etc/systemd/system/postgres-backup.service`

The service is named:

`postgres-backup.service`

Its verified configuration is:

```ini
[Unit]
Description=Homelab PostgreSQL Backup (Root)
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
User=root
Group=root
UMask=0077
TimeoutStartSec=15min
ExecStartPre=/bin/sleep 300
ExecStart=/usr/local/sbin/postgres-backup

[Install]
WantedBy=multi-user.target
```

The service:

- Requires Docker and runs after Docker starts.
- Executes the backup script as `root`.
- Applies a restrictive service umask of `0077`.
- Waits 300 seconds (five minutes) before executing the backup script.
- Has a 15-minute service start timeout.
- Is enabled for startup through `multi-user.target`.

The service uses oneshot execution. It runs its configured operation and exits rather than remaining active as a continuously running application.

After a successful execution, systemd may show the service as `inactive (dead)`. This is normal for a completed oneshot service; the execution result and service logs should be checked to determine whether it succeeded.

### Startup Delay and Readiness Checks

The service includes a five-minute pre-start delay through:

```ini
ExecStartPre=/bin/sleep 300
```

After this delay, the backup script performs its own PostgreSQL readiness checks.

The script allows up to 30 attempts, with a 10-second sleep between unsuccessful attempts. If PostgreSQL does not become ready, the script exits unsuccessfully.

The service's configured 15-minute timeout and the script's retry behavior should be considered together when troubleshooting a failed startup-triggered backup.

## Daily Execution Behavior

The script records the current local calendar date only after the backup and retention operations have completed successfully.

When another invocation occurs on the same date and the recorded successful date matches today's date, the script skips another backup.

If an attempt fails before the successful date is recorded, a later invocation can try again. However, the current service configuration does not establish a recurring retry schedule.

This is startup-triggered automation, not a recurring daily schedule:

- A successful startup-triggered run can create a backup.
- A subsequent run on the same local calendar date skips another backup.
- If the server remains powered off, no backup can run.
- If the server stays online across multiple days without another service trigger, this service alone does not guarantee a backup every day.

If daily backups are required while the server remains online, a recurring schedule should be configured and tested separately.

## Validation Performed

The following implementation and operational checks have been performed:

- [x] Bash syntax validation using `bash -n`.
- [x] Inspection of the root-owned systemd service configuration.
- [x] Confirmation that the service is enabled.
- [x] Confirmation that the previous daily timer is disabled.
- [x] Confirmation that Docker is active.
- [x] Successful execution of the systemd backup service.
- [x] Successful creation and archive validation of PostgreSQL dumps.
- [x] Verification of the recorded successful-backup date.
- [x] Verification that a second invocation on the same day skips the backup.
- [x] Verification of automatic service startup after a server reboot.
- [x] Verification that the five-minute startup delay completed and the backup script executed.
- [x] Verification that the service skipped duplicate backups when a successful backup was already recorded for that day.
- [x] Inspection of backup directory ownership and permissions.
- [x] Inspection of retained backup archives and systemd journal entries.

### Observed Backup Evidence

The backup directory was inspected on 6 November 2026.

The following seven archives were retained at that time:

| Backup archive | Size |
|---|---:|
| `notes-db-2026-11-01-133100.dump` | 2,599 bytes |
| `notes-db-2026-11-01-173137.dump` | 2,599 bytes |
| `notes-db-2026-11-02-193939.dump` | 2,599 bytes |
| `notes-db-2026-11-03-125032.dump` | 2,599 bytes |
| `notes-db-2026-11-04-125923.dump` | 2,599 bytes |
| `notes-db-2026-11-05-125029.dump` | 2,599 bytes |
| `notes-db-2026-11-06-162336.dump` | 2,599 bytes |

The success-state file contained:

`2026-11-06`

Systemd journal entries confirmed successful backup executions on 4, 5, and 6 November 2026. Additional invocations on 4 November correctly skipped execution when the successful backup date was already recorded.

The seven retained files are the seven newest matching archives at the time of inspection. They should not be interpreted as seven consecutive daily backups: two retained archives are from 1 November.

These observations establish evidence for the inspected configuration and test runs. They do not guarantee that every future execution will succeed.

## Recovery Testing

Restore testing is documented separately in [`labs/04-postgresql-backup-restore/README.md`](../labs/04-postgresql-backup-restore/README.md).

### Recovery Test: 24 October 2026

The test used the backup archive:

`notes-db-2026-10-15-202858.dump`

The archive was restored into an isolated PostgreSQL environment. The documented verification included comparisons of selected record IDs and text hashes, along with the restored sequence state.

The tested record IDs and text hashes matched, and the sequence reported:

- `last_value = 34`
- `is_called = true`

**Result:** The documented checks passed for the records and sequence state examined during this test.

### Recovery Test: 28 October 2026

The test used the backup archive:

`notes-db-2026-10-28-132725.dump`

The archive was restored into a separate PostgreSQL 16 container named `postgres-restore-test`, using the database `restore_test` and a dedicated Docker volume.

The restore completed without reported errors. The restored `public.notes` table contained two records, and the original `public.notes` table also contained two records.

After verification, the temporary restore container, its dedicated volume, and the temporary password environment file were removed. The original application and database remained healthy, and the monitoring containers remained running.

**Result:** The restore completed successfully, and the original and restored tables had matching row counts.

**Verification limitation:** This test did not compare individual record IDs or contents, calculate text hashes, or independently verify the restored sequence state. Matching row counts do not establish exact equality of the records.

## Limitations and Future Improvements

### Current Limitations

- Backups are stored on the same physical machine as the database.
- A disk failure or loss of the server could destroy both the database and its local backups.
- Automatic recurring daily execution is not configured.
- Automatic retries and failure notifications are not configured.
- Archive listing validation does not replace a restore test.
- The documented restore tests cover specific archives and checks; they do not establish that every database object, record, sequence, or application dependency can be recovered correctly.
- The retention policy keeps only seven matching archives, so older local backups are removed as newer archives are retained.

### Potential Improvements

- Copy backups to a separate machine or storage service.
- Configure and test a recurring backup schedule if daily backups are required.
- Add failure monitoring and notifications.
- Periodically restore recent backups into an isolated PostgreSQL instance.
- Extend restore verification to compare record IDs, record contents or hashes, sequence state, and other relevant database objects.
- Document recovery objectives and the retention policy appropriate to the data.

## Recovery Principle

A backup file's existence does not, by itself, establish recoverability.

Archive inspection helps verify that a dump can be read, while an isolated restore test provides evidence that the backup can be used to recreate a database.

Recovery verification should be documented according to the checks actually performed. A successful restore with matching row counts is useful evidence, but stronger verification may be required before relying on the backup for a real recovery scenario.
