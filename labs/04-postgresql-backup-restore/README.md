# PostgreSQL Backup and Restore

## Objective

Implement and test a PostgreSQL backup and recovery workflow using Docker and PostgreSQL's native backup utilities.

The goal is to create a custom-format database backup, inspect the archive, restore it into an isolated PostgreSQL instance, and verify the recovered data.

Separate recovery tests document the checks performed and their respective results.

## Environment

| Component | Details |
|---|---|
| Database | PostgreSQL 16 |
| Container runtime | Docker |
| Backup utility | `pg_dump` |
| Restore utility | `pg_restore` |
| Backup format | PostgreSQL custom archive (`-Fc`) |
| Database configuration | Environment-specific |
| Backup storage | Local server backup directory |

The database, container names, usernames, and filesystem paths used in the examples are environment-specific. Replace the placeholders with values appropriate to your environment.

### Security and Scope

- Backup archives are stored locally and are not committed to this repository.
- Database credentials and temporary password files are excluded from version control.
- Restore tests use separate PostgreSQL containers and dedicated storage to avoid modifying the original database.
- Temporary restore resources are removed after testing.
- The original application database volume and network must remain untouched during restore-test cleanup.
- Archive inspection helps verify that a backup contains expected database objects, but a successful restore test provides stronger evidence of recoverability.

## Backup Workflow

### 1. Create a Custom-Format Backup

The PostgreSQL `pg_dump` utility creates a logical backup of a database.

Example:

```bash
docker exec <postgres-container> pg_dump \
  -U <database-user> \
  -d <database-name> \
  -Fc \
  > notes-db.dump
```

The `-Fc` option creates a custom-format archive that can be inspected and restored using `pg_restore`.

The example writes the archive to the current directory on the machine running the command.

For operational use, specify the intended backup destination and use the configured backup automation rather than relying on an arbitrary working directory.

### 2. Inspect the Backup Archive

Inspect the archive's table of contents:

```bash
pg_restore --list /path/to/notes-db.dump
```

This lists the database objects recorded in the archive without restoring them.

Archive inspection helps confirm that expected objects are present. It does not, by itself, prove that the archive can be restored successfully.

### 3. Automated Backup Process

The deployed backup automation is documented in:

[`docs/postgres-backup-automation.md`](../../docs/postgres-backup-automation.md)

The current server implementation uses a root-owned Bash script and a systemd oneshot service.

The workflow includes:

- Checking PostgreSQL readiness before starting a backup.
- Creating a custom-format archive.
- Preventing overlapping backup runs with `flock`.
- Writing to a temporary file before accepting the completed archive.
- Validating the archive with `pg_restore --list`.
- Retaining the seven newest matching backup archives.
- Recording successful completion in a daily state file.
- Running the backup through a systemd oneshot service.

The service is enabled for startup-triggered execution and includes a five-minute pre-start delay.

**Scheduling limitation:** The previous daily 2 AM timer is disabled. The enabled startup service does not guarantee a new backup every day while the server remains online.

The deployed backup implementation is separate from the repository's lab/reference backup script. Refer to the automation document for the current server configuration.

## Restore and Verification

Recovery tests were performed on **24 October 2026** and **28 October 2026**.

Each test is documented separately because the verification procedures and evidence differ.

### Recovery Test: 24 October 2026

**Backup archive:** `notes-db-2026-10-15-202858.dump`

#### Procedure

1. Inspected the custom-format backup archive.
2. Started an isolated PostgreSQL restore environment using Docker with network access disabled.
3. Restored the archive using `pg_restore --no-owner --no-privileges`.
4. Compared recovered records with the original database using record IDs and text hashes.
5. Checked the restored sequence state.
6. Removed the temporary restore environment after verification.

#### Validation Results

- [x] Inspected the backup archive.
- [x] Restored the backup into an isolated PostgreSQL instance.
- [x] Compared record IDs between the original and restored databases.
- [x] Compared text hashes for the tested records.
- [x] Verified the sequence state.
- [x] Cleaned up the temporary restore environment.

#### Data Comparison

The selected record IDs and their corresponding text hashes matched between the original and restored databases during this test.

These results apply only to the specific records checked during this test.

#### Sequence Verification

The restored sequence reported:

| Property | Verified value |
|---|---|
| Sequence | `notes_id_seq` |
| `last_value` | `34` |
| `is_called` | `true` |

Under normal conditions, with no concurrent inserts or manual sequence changes, the next generated sequence value would be `35`.

#### Outcome

The 24 October recovery test passed its documented checks: the tested record IDs and text hashes matched, and the sequence state was verified.

These checks provide evidence for the specific backup and database objects tested. They do not establish that every database object, application dependency, or future backup will recover successfully.

### Recovery Test: 28 October 2026

**Backup archive:** `notes-db-2026-10-28-132725.dump`

#### Test Environment

A separate PostgreSQL 16 container was created for the restore test.

| Component | Details |
|---|---|
| Temporary container | `postgres-restore-test` |
| Restore database | `restore_test` |
| Temporary database user | Dedicated restore-test user |
| Host port binding | Loopback interface, port `5433` |
| Dedicated Docker volume | `postgres-restore-test-data` |

The separate container, database, and volume isolated the test from the original application database.

The host port was bound to `127.0.0.1`, making it accessible through the server's loopback interface rather than exposing it on all network interfaces.

#### Procedure

1. Inspected the backup archive using `pg_restore --list`.
2. Started the temporary PostgreSQL container with a dedicated Docker volume and temporary credentials.
3. Confirmed that PostgreSQL was accepting connections using `pg_isready`.
4. Restored the archive into the `restore_test` database using `pg_restore --no-owner --no-privileges`.
5. Counted the records in the restored `public.notes` table.
6. Counted the records in the original `public.notes` table.
7. Removed the temporary restore container, its dedicated volume, and the temporary password environment file.
8. Confirmed that the original application, database, and monitoring containers remained running.

#### Restore Command

The restore operation used the following command pattern:

```bash
docker exec -i <restore-container> pg_restore \
  --verbose \
  --no-owner \
  --no-privileges \
  -U <restore-user> \
  -d <restore-database> \
  < /path/to/notes-db.dump
```

Replace the placeholders with the configuration of the isolated restore environment.

The restore output showed that PostgreSQL created the `public.notes` table, its sequence, the sequence ownership and default, restored the table data, and set the sequence value.

No restore errors were reported.

#### Validation Results

- [x] Inspected the backup archive using `pg_restore --list`.
- [x] Confirmed PostgreSQL readiness using `pg_isready`.
- [x] Restored the archive into a separate PostgreSQL container.
- [x] Confirmed that the restored `public.notes` table contained two records.
- [x] Confirmed that the original `public.notes` table contained two records.
- [x] Removed the temporary restore container.
- [x] Removed the dedicated Docker volume used by the restore test.
- [x] Removed the temporary password environment file.
- [x] Confirmed that the original application and database remained healthy after cleanup.

#### Record Count Comparison

| Database | Table | Record count |
|---|---|---:|
| Original | `public.notes` | 2 |
| Restored | `public.notes` | 2 |

Both databases contained two records at the time of verification.

**Verification limitation:** Matching record counts confirm that the restored table contained the same number of records as the original table. They do not prove that every record's ID and contents matched exactly. This test did not compare individual record values or hashes, and it did not independently verify the restored sequence state.

#### Cleanup and Service Health

After verification, the temporary restore container, its dedicated volume, and the temporary password environment file were removed. The backup archive was retained.

A subsequent `docker ps` check confirmed that the original Notes application and PostgreSQL database remained healthy, and that Prometheus, Node Exporter, and Grafana were still running.

The cleanup applied only to resources created specifically for the isolated restore test. The original application database storage was not removed.

#### Outcome

The 28 October recovery test completed successfully. The backup was restored into an isolated PostgreSQL instance, the restore process reported no errors, and the original and restored tables both contained two records.

Temporary test resources were cleaned up without disrupting the original services.

The result demonstrates successful restoration and matching row counts for this test. Exact record equality and sequence-state recovery were not established by this run.

## Operational Considerations

- **Backup creation is not enough:** A backup should be inspected and periodically restored in an isolated environment.
- **Archive validation has limits:** `pg_restore --list` confirms that the archive can be read for listing; it does not guarantee a successful restore.
- **Keep restore tests isolated:** Use a separate container, database, and storage volume to reduce the risk of modifying original application data.
- **Protect credentials and backup files:** Do not commit passwords, temporary environment files, or database dumps to Git.
- **Protect original storage:** Never remove the original application database volume or network as part of restore-test cleanup. Only remove resources created specifically for the isolated test.
- **Verify the appropriate recovery properties:** Row counts, record IDs, content hashes, sequence state, database objects, and application behavior are different checks. Document only the checks actually performed.
- **Review scheduled execution:** The startup service and a recurring timer have different roles. Confirm the actual scheduling mechanism before relying on recurring backups.
- **Review retention and recovery requirements:** Keeping seven recent archives is a retention policy, not a guarantee against every data-loss scenario. Important data may require off-host copies and a separately defined recovery policy.

## Status

| Task | Status |
|---|---|
| Custom-format PostgreSQL backup workflow documented | Complete |
| Backup archive inspection documented | Complete |
| Recovery test from 24 October 2026 documented | Complete |
| Record ID and text-hash comparison from 24 October documented | Complete |
| Sequence-state verification from 24 October documented | Complete |
| Recovery test from 28 October 2026 documented | Complete |
| Matching row counts from 28 October documented | Complete |
| Temporary restore resources cleaned up after the 28 October test | Complete |
| Original services checked after the 28 October test | Complete |
| Root-owned automated backup process documented | Complete |
| Off-host backup and broader recovery testing | Future improvement |
