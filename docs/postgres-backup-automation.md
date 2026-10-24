# PostgreSQL Backup Automation

## Overview

This document describes the PostgreSQL backup automation implemented for the Docker Compose notes application running on a homelab server.

The workflow uses Bash, Docker, PostgreSQL utilities, and systemd to create timestamped database backups, validate the backup archive, and limit successful backups to one per local calendar day.

## Environment

- Operating system: Ubuntu Server 24.04.5 LTS
- Database: PostgreSQL 16
- Container: `notes-app-db-1`
- Database name: `postgres`
- Backup format: PostgreSQL custom archive (`pg_dump -Fc`)
- Backup directory: `/home/sufiyan/lab/notes-app/backups`
- Automation: systemd oneshot service

## Repository Files

- Script: `labs/05-docker-compose/scripts/backup-postgres.sh`
- Lab documentation: `labs/05-docker-compose/README.md`

The absolute paths and container name in the script are specific to the current homelab environment. They must be reviewed before using the script on another server.

## Backup Workflow

The script performs these operations:

1. Creates the backup directory and applies restrictive permissions.
2. Acquires a file lock to prevent concurrent backup processes.
3. Checks whether a successful backup has already run on the current local calendar day.
4. Waits for PostgreSQL to become ready, checking up to 30 times with a 10-second interval.
5. Creates a timestamped custom-format dump with `pg_dump`.
6. Rejects an empty backup file.
7. Validates the archive with `pg_restore --list`.
8. Moves the validated dump to its final filename.
9. Retains the seven newest matching dump files and removes older ones.
10. Records the successful backup date after the backup and retention operations complete.

Temporary files are cleaned up when the script exits.

## Backup Naming

Backup filenames use this format:

`notes-db-YYYY-MM-DD-HHMMSS.dump`

Example:

`notes-db-2026-10-24-153359.dump`

## Permissions and Safety

The script uses `umask 077`.

- Backup directory permissions: `700`
- Backup file permissions: `600`
- Script permissions on the homelab: `700`
- systemd service umask: `0077`

The `.backup.lock` file is used for process locking. The `.last-successful-backup-date` file records the last successful backup date.

These files are runtime state and must not be committed to Git.

Database dumps, environment files, credentials, and private keys must never be published in the repository.

## systemd Service

The service unit is installed on the homelab at:

`/etc/systemd/system/homelab-postgres-backup.service`

The service:

- Requires and runs after Docker starts.
- Waits five minutes before running the script.
- Uses the local `sufiyan` account.
- Has a 15-minute startup timeout.
- Is enabled for automatic startup through `multi-user.target`.

The previous daily 2 AM timer is disabled.

## Daily Execution Behavior

The script records the local calendar date only after a successful backup and retention operation.

If another invocation occurs on the same date after success, the script skips the backup.

This is startup-triggered automation, not a recurring daily schedule. If the server remains powered off, no backup can run. If the server stays powered on across multiple days without another trigger, this service alone does not guarantee a backup every day.

A failed attempt does not record the success date. The current service configuration does not automatically retry failed backups.

## Validation Performed

The following checks passed:

- Bash syntax validation using `bash -n`.
- Inspection of the systemd service configuration.
- Confirmation that the service is enabled.
- Confirmation that the previous timer is disabled.
- Confirmation that Docker is active.
- Successful manual execution of the systemd service.
- Successful creation and archive validation of a PostgreSQL dump.
- Verification of the recorded successful-backup date.
- Verification that a second script invocation on the same day skips the backup.

Automatic execution following an actual server reboot has not yet been verified.

## Limitations and Future Improvements

- Backups are stored on the same physical machine as the database.
- A disk failure or loss of the server could destroy both the database and its local backups.
- Automatic retry and failure notifications are not configured.
- Archive listing validation does not replace a restore test.

Potential improvements include:

- Verifying automatic execution after a real reboot.
- Restoring the latest backup into an isolated PostgreSQL instance.
- Copying backups to a separate machine or storage service.
- Adding failure monitoring and notifications.
- Introducing a recurring schedule if daily backups are required while the server remains online.

## Recovery Principle

A backup is not fully trustworthy merely because a dump file exists.

Periodically restore it into an isolated test database and verify that expected application data is present.
