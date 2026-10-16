# PostgreSQL Backup and Restore

## Objective

Create a PostgreSQL backup, inspect the archive, restore it into a separate
database, and validate that the recovered data and sequence state match
the original.

## Environment

- Database: PostgreSQL 16
- Runtime: Docker container
- Backup format: PostgreSQL custom archive
- Storage: Local backup directory
- Original database: `postgres`
- Temporary restore database: `restore_test`

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
that the archive can be read, but does not prove that restoration will
succeed or that all application data is recoverable.

## Restore and Verification

The backup was restored into a separate temporary database named
`restore_test`, leaving the original database unchanged.

### Validation Results

- [x] Create a PostgreSQL custom-format backup.
- [x] Inspect the archive using `pg_restore --list`.
- [x] Create a temporary restore database.
- [x] Restore the archive into the temporary database.
- [x] Verify that the restored `public.notes` table exists.
- [x] Confirm that the original and restored tables each contain 2 rows.
- [x] Compare record IDs and MD5 hashes of the text fields.
- [x] Verify the restored sequence state.

### Data Comparison

The original and restored databases returned the same results:

| Record ID | MD5 Hash | Result |
|---:|---|---|
| 1 | `1120044d656fc583db224b62504c67fb` | Match |
| 34 | `408cc34e023f49873f746c71ca9763e0` | Match |

The matching IDs and hashes confirm that the text values in both
restored records match their original counterparts.

### Sequence Verification

The restored sequence returned:

| Property | Value |
|---|---|
| `last_value` | 34 |
| `is_called` | `true` |

This indicates that the sequence has been used and its last recorded
value is 34. Under normal sequence behavior, the next `nextval()` call
will return 35, assuming no concurrent calls or manual sequence changes.

## Result

**The PostgreSQL restore test passed.**

The custom-format backup was restored successfully into a separate
database. The restored table exists, both records match the original
by ID and MD5 hash, and the sequence state was restored as expected.

This validates the tested database objects and records. It does not,
by itself, establish a complete disaster-recovery process or guarantee
recovery of every possible application dependency.

## Operational Considerations

- Store backups outside the container's disposable writable layer.
- Restrict access to backup files.
- Do not commit database dumps or credentials to Git.
- Consider encryption and an off-host copy for important data.
- Test restoration regularly rather than relying only on backup creation.
- Define retention and recovery requirements appropriate to the data.
- Clean up temporary restore databases after verification, once they
  are no longer needed.

## Status

- Backup creation: Complete
- Archive inspection: Complete
- Restore into a temporary database: Complete
- Table and data verification: Complete
- Sequence verification: Complete
- Restore result documentation: Complete
- Temporary database cleanup: Pending
