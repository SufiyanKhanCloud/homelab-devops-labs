# PostgreSQL Backup and Restore

## Objective

Create a PostgreSQL backup, inspect the archive, and establish a
repeatable process for validating recovery.

## Environment

- Database: PostgreSQL
- Runtime: Docker container
- Backup format: PostgreSQL custom archive
- Storage: Local backup directory

Sensitive database contents, credentials, and actual backup files
are intentionally excluded from this repository.

## Backup Workflow

### 1. Create a custom-format backup

Example command:

```bash
pg_dump -U <database-user> -d <database-name> -Fc -f backup.dump
```

Replace the placeholders with the correct database user and name.
Supply credentials securely rather than embedding passwords in commands.

### 2. Inspect the archive

```bash
pg_restore --list backup.dump
```

This lists the archive's recorded database objects. It helps establish
that the archive can be read, but does not prove that restoration
will succeed or that all application data is recoverable.

## Verified Progress

- [x] Create a PostgreSQL custom-format backup.
- [x] Inspect the archive using `pg_restore --list`.
- [ ] Restore into a temporary database.
- [ ] Verify restored tables and data.
- [ ] Document the restore result.

## Planned Restore Validation

The recovery test will use a separate temporary database to avoid
overwriting the original database.

The validation process will include:

1. Create a temporary database.
2. Restore the archive into that database.
3. Inspect the restored schema.
4. Compare appropriate table counts or known test records.
5. Record any errors and the final outcome.
6. Remove the temporary database after verification.

The restore has not yet been marked as successful.

## Operational Considerations

- Store backups outside the container's disposable writable layer.
- Restrict access to backup files.
- Do not commit database dumps to Git.
- Consider encryption and an off-host copy for important data.
- Test restoration regularly rather than relying only on backup creation.
- Define retention and recovery requirements appropriate to the data.

## Status

Backup creation and archive inspection completed. Restore and data
verification remain pending.
