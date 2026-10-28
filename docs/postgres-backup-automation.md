# PostgreSQL Backup Automation

## Overview

This document describes the PostgreSQL backup automation implemented for the Docker Compose notes application running on a homelab server.

The workflow uses Bash, Docker, PostgreSQL utilities, and systemd to create timestamped PostgreSQL custom-format backups, validate the resulting archives, and retain the seven newest matching backup files.

A successful backup is recorded against the local calendar date to prevent duplicate successful backups on the same day.

The systemd service is configured for startup-triggered execution. The previous daily 2 AM timer is disabled, so the service does not guarantee a new backup every day while the server remains running.

## Environment

| Component | Details |
|---|---|
| Operating system | Ubuntu Server 24.04.5 LTS |
| Database | PostgreSQL 16 |
| Docker container | `notes-app-db-1` |
| Database name | `postgres` |
| Database user | `postgres` |
| Backup format | PostgreSQL custom archive (`pg_dump -Fc`) |
| Backup directory | `/home/sufiyan/lab/notes-app/backups/` |
| Backup script | Bash |
| Automation | systemd oneshot service |
| Retention policy | Seven newest matching dump files |

The container name, database configuration, and absolute filesystem paths are specific to the current homelab environment.

## Repository Files

- Backup script: [`labs/05-docker-compose/scripts/backup-postgres.sh`](../labs/05-docker-compose/scripts/backup-postgres.sh)
- Docker Compose lab: [`labs/05-docker-compose/README.md`](../labs/05-docker-compose/README.md)
- Backup and restore lab: [`labs/04-postgresql-backup-restore/README.md`](../labs/04-postgresql-backup-restore/README.md)

The script must be reviewed and adapted before use on another server. Its current configuration should not be assumed to work unchanged in a different environment.

## Backup Workflow

The backup script performs the following operations:

1. Enables strict Bash error handling and restrictive default file permissions.
2. Creates the backup directory if necessary and applies directory permissions of `700`.
3. Acquires a non-blocking file lock to prevent concurrent backup processes.
4. Checks whether a successful backup has already been recorded for the current local calendar date.
5. Checks whether the PostgreSQL container is running and whether PostgreSQL is accepting connections.
6. Retries readiness checks up to 30 times, with a 10-second sleep between unsuccessful attempts.
7. Creates a temporary backup file inside the backup directory.
8. Runs `pg_dump` to create a custom-format database archive.
9. Rejects an empty backup file.
10. Validates the archive using `pg_restore --list`.
11. Applies file permissions of `600` to the completed temporary archive.
12. Moves the validated archive to its timestamped final filename.
13. Retains the seven newest matching dump files and removes older matching files.
14. Writes the successful backup date to a temporary state file and atomically moves it into place.
15. Logs successful completion.

The script uses an exit trap to remove temporary backup and state files if they remain when the script exits.

### Backup Validation

The script checks both that the generated file is non-empty and that PostgreSQL can read its archive structure using `pg_restore --list`.

These checks help reject incomplete or unreadable backup files before they are accepted as completed backups.

However, archive validation is not equivalent to restoring the database. Recovery testing must be performed separately.

## Backup Naming

Backup filenames use the following format:

`notes-db-YYYY-MM-DD-HHMMSS.dump`

Example:

`notes-db-2026-10-28-132725.dump`

The date and time in the filename are based on the server's local clock when the script initializes.

The naming convention makes backups identifiable by their creation timestamp and allows the retention logic to sort matching filenames in reverse lexical order.

## Permissions and Runtime State

The script uses:

```bash
umask 077
```

This restricts default permissions for newly created files and directories to the owning user, subject to the permissions applied by the script and filesystem.

| Item | Expected permissions or behavior |
|---|---|
| Backup directory | `700` |
| Completed backup archive | `600` |
| Backup script on the homelab | `700` |
| systemd service umask | `0077` |
| `.backup.lock` | Runtime file used for process locking |
| `.last-successful-backup-date` | Records the last successful backup date |
| Temporary backup file | Created inside the backup directory and removed on exit if it remains |
| Temporary state file | Used when recording successful completion |

The script's lock and success-state files are operational runtime state. They should not be committed to the repository.

Database dumps, credentials, private keys, and temporary environment files must not be published in Git.

## systemd Service

The service unit is installed on the homelab server at:

`/etc/systemd/system/homelab-postgres-backup.service`

The documented service configuration:

- Requires Docker and runs after Docker starts.
- Executes the backup script as the local `sufiyan` account.
- Applies a restrictive service umask of `0077`.
- Waits five minutes before starting the backup script.
- Has a 15-minute startup timeout.
- Is enabled for startup through `multi-user.target`.

The service uses oneshot execution, meaning it runs its configured operation and exits rather than remaining active as a continuously running application.

### Startup Delay and Readiness Checks

The service includes a five-minute pre-start delay. After that delay, the backup script performs its own PostgreSQL readiness checks.

The script allows up to 30 attempts with a 10-second sleep after each unsuccessful attempt. If PostgreSQL does not become ready, the script logs an error and exits unsuccessfully.

The service's configured startup timeout and the script's retry behavior should be considered together when troubleshooting a failed startup-triggered backup.

### Timer Status

The previous daily 2 AM systemd timer is disabled.

The service being enabled does not mean that a daily timer is active. These are separate systemd mechanisms.

## Daily Execution Behavior

The script records the current local calendar date only after the backup and retention operations have completed successfully.

When another invocation occurs on the same date and the recorded successful date matches today's date, the script skips the backup.

If an attempt fails before the successful date is recorded, a later invocation can try again. However, the current service configuration does not automatically retry failed executions.

This is startup-triggered automation, not a recurring daily schedule:

- A successful startup-triggered run can create a backup.
- A subsequent run on the same local calendar date skips another backup.
- If the server remains powered off, no backup can run.
- If the server stays online across multiple days without another trigger, this service alone does not guarantee a backup every day.

If daily backups are required while the server remains online, a recurring schedule should be configured and tested separately.

## Validation Performed

The following checks were documented as completed during implementation and operational testing:

- [x] Bash syntax validation using `bash -n`.
- [x] Inspection of the systemd service configuration.
- [x] Confirmation that the service is enabled.
- [x] Confirmation that the previous timer is disabled.
- [x] Confirmation that Docker is active.
- [x] Successful manual execution of the systemd service.
- [x] Successful creation and archive validation of a PostgreSQL dump.
- [x] Verification of the recorded successful-backup date.
- [x] Verification that a second script invocation on the same day skips the backup.
- [x] Verification of automatic service startup after a server reboot.
- [x] Verification that the five-minute startup delay completed and the backup script executed.
- [x] Verification that the script skipped a duplicate backup when a successful backup was already recorded for that day.

These checks establish evidence for the documented implementation and test runs. They do not guarantee that every future execution will succeed.

## Recovery Testing

Restore testing is documented separately in [`labs/04-postgresql-backup-restore/README.md`](../labs/04-postgresql-backup-restore/README.md).

### Recovery Test: 24 October 2026

The test used the backup archive:

`notes-db-2026-10-15-202858.dump`

The archive was restored into an isolated PostgreSQL environment. The documented verification included comparisons of selected record IDs and text hashes, along with the restored sequence state.

The tested record IDs and text hashes matched, and the sequence reported `last_value = 34` with `is_called = true`.

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
- Automatic retries and failure notifications are not configured.
- The disabled daily timer means the service does not guarantee recurring daily backups while the server remains online.
- Archive listing validation does not replace a restore test.
- Successful restoration and matching row counts do not independently prove that every database object, record, sequence, or application dependency has been recovered correctly.

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
