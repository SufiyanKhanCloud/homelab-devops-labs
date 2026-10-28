# Lab 05: Docker Compose

## Objective

Migrate an existing Flask and PostgreSQL application from manually managed containers to Docker Compose while preserving database data.

This lab covers multi-container orchestration, service discovery, persistent storage, health checks, environment-based configuration, container hardening, and deployment verification.

## Architecture

| Component | Configuration |
|---|---|
| Application | Flask |
| WSGI server | Gunicorn |
| Python runtime | Python 3.12 |
| Application image | `notes-app:3` |
| Database | PostgreSQL 16 |
| Orchestration | Docker Compose |
| Application port | `127.0.0.1:5000` |
| Database volume | Existing external Docker volume `pgdata` |
| Application network | Existing external Docker network `notes-net` |
| Application dependencies | Flask, Psycopg, Gunicorn |

### Service Communication

The Compose project defines two services:

- **`app`**: Runs the Flask application using Gunicorn.
- **`db`**: Runs PostgreSQL 16 and stores its data in the existing `pgdata` volume.

The services communicate over the external `notes-net` network. The application uses the Compose service name `db` as its database hostname.

The application port is bound to the host's loopback interface. This makes it accessible locally on the server without directly publishing port `5000` on every host network interface.

## Implementation

### 1. Protected Environment Configuration

A local `.env` file stores the environment variables used by Docker Compose.

The configuration requires:

- `POSTGRES_PASSWORD` for PostgreSQL initialization.
- `DB_PASSWORD` for the application's database connection.

The variables are kept separate in the Compose configuration, so their values must be managed consistently with the database's actual credentials.

The `.env` file has restrictive permissions of `600` and is excluded from Git through `.gitignore`.

Credentials are not included in this repository.

### 2. Defined the Compose Services

The `compose.yaml` file defines the application and database services.

The application image is built from the local Dockerfile:

```yaml
app:
  build: .
  image: notes-app:3
```

The database uses the PostgreSQL 16 image:

```yaml
db:
  image: postgres:16
```

Both services use `restart: unless-stopped`, allowing Docker to restart them under the configured restart policy unless they have been explicitly stopped.

### 3. Configured Health Checks

#### PostgreSQL Health Check

The database service uses `pg_isready` to check whether PostgreSQL is accepting connections.

Its configured parameters are:

- Interval: 10 seconds
- Timeout: 5 seconds
- Retries: 5
- Start period: 10 seconds

#### Application Health Check

The application image defines a health check in the Dockerfile. It sends a request to the local `/health` endpoint.

Its configured parameters are:

- Interval: 30 seconds
- Timeout: 3 seconds
- Retries: 3
- Start period: 5 seconds

These checks allow Docker to report whether each service is healthy according to its configured test.

The application also uses `depends_on` with `condition: service_healthy` for the database. This coordinates initial startup so the application waits for the database to become healthy.

Health checks do not guarantee that an application will recover automatically from every runtime failure.

### 4. Preserved Persistent Storage and Networking

The Compose project reuses two existing external Docker resources.

#### Persistent Volume

```yaml
volumes:
  pgdata:
    external: true
    name: pgdata
```

The `pgdata` volume stores PostgreSQL's database files.

Declaring it as external allows Compose to reuse the existing volume rather than managing it as a new project-owned volume.

This was important during migration because the database already contained records that needed to be preserved.

#### External Network

```yaml
networks:
  notes-net:
    external: true
    name: notes-net
```

The application and database reuse the existing `notes-net` network.

Docker's service discovery allows the application to reach PostgreSQL using the hostname `db` within the Compose network.

### 5. Applied Container Security Controls

The application service uses several runtime security controls.

| Control | Configuration | Purpose |
|---|---|---|
| Non-root user | `USER app` in the Dockerfile | Runs the application without using the root user. |
| Read-only root filesystem | `read_only: true` | Prevents normal writes to the container's root filesystem. |
| Temporary filesystem | `/tmp` mounted as `tmpfs` | Provides temporary writable storage. |
| Linux capabilities | `cap_drop: ALL` | Removes Linux capabilities from the application container. |
| Privilege escalation | `no-new-privileges:true` | Prevents processes from gaining additional privileges through supported privilege-escalation mechanisms. |
| Local port binding | `127.0.0.1:5000:5000` | Limits direct host-port exposure to the loopback interface. |

The Dockerfile creates a dedicated system user named `app` with UID `10001`.

The application runs using Gunicorn with two workers and listens on port `5000` inside the container.

These controls reduce the application's attack surface but do not replace host security, application security, vulnerability management, or appropriate network controls.

### 6. Validated the Compose Configuration

The Compose configuration was validated using:

```bash
docker compose config --quiet
```

This checks whether Docker Compose can parse and resolve the configuration. It does not prove that the services will start successfully.

The application image was then built:

```bash
docker compose build app
```

Before migration, database connectivity was tested from the new application image against the existing database.

The query returned both existing records, providing evidence that the new application image could access the existing data before the deployment was switched over.

### 7. Migrated the Application to Compose

The existing manually managed containers were stopped, and the Compose deployment was started using:

```bash
docker compose up -d
```

After verifying the new deployment, obsolete containers were removed without removing their images or the existing database volume.

The previous `notes-app:2` image and the existing database backup were retained.

**Important:** Removing a container and removing a Docker volume are different operations. Removing the database container does not necessarily remove its persistent volume, and deleting a volume can permanently remove the data stored in it.

## Verification

The following checks were documented during deployment verification.

### 1. Application Health Endpoint

```bash
curl -i http://127.0.0.1:5000/health
```

**Recorded result:** HTTP `200 OK`.

This confirms that the health endpoint returned a successful HTTP response during the documented test.

### 2. Application API

```bash
curl -s http://127.0.0.1:5000/notes
```

The API returned the two original notes:

| ID | Text |
|---:|---|
| 1 | `survives container delete` |
| 34 | `Docker network DNS works` |

These records were present after migration.

### 3. Direct Database Verification

The database was queried through the Compose service:

```bash
docker compose exec db \
  psql -U postgres -d postgres \
  -c 'SELECT id, txt FROM notes ORDER BY id;'
```

Both original records remained present after migration.

This provided an additional check beyond the application API by querying PostgreSQL directly.

### 4. Application Restart Verification

The application service was restarted:

```bash
docker compose restart app
```

After the restart, the application recovered and both API endpoints continued to work.

A final `docker compose ps` check showed both services healthy during the documented verification.

## Key Learnings

- Docker Compose makes multi-container deployments easier to manage and reproduce.
- Compose service names provide DNS-based communication between containers on a shared network.
- Health checks provide service-health information and can coordinate initial startup.
- External volumes allow a Compose project to reuse existing persistent database storage.
- Environment files separate credentials from the application's committed source code.
- Read-only filesystems, non-root execution, dropped capabilities, and restricted privilege escalation help reduce container risk.
- Container removal and volume removal are different operations.
- Testing database connectivity before migration helps detect configuration problems early.
- Application-level checks and direct database queries provide complementary verification.
- A successful deployment should be tested after service restarts.

## Outcome

The existing Flask and PostgreSQL application was migrated to Docker Compose while preserving the documented database records and reusing the existing external volume and network.

The deployment was verified using the application health endpoint, API queries, direct PostgreSQL queries, and an application restart.

The Compose deployment also includes application and database health checks, a non-root application user, and multiple container runtime security controls.

## Related Security Work

The application was subsequently hardened with Docker runtime security controls and scanned for known image vulnerabilities.

See [Lab 06: Trivy Vulnerability Scanning and Container Hardening](../06-trivy-container-security/README.md).

## PostgreSQL Backup Automation

The homelab includes a PostgreSQL backup script that creates timestamped custom-format dumps, validates the archives, and retains the seven newest matching backup files.

A systemd oneshot service triggers the backup workflow during startup. The previous daily timer is disabled, so the service alone does not guarantee recurring daily backups while the server remains online.

The backup script also prevents duplicate successful backups on the same local calendar day.

See [PostgreSQL Backup Automation](../../docs/postgres-backup-automation.md) for the workflow, configuration, validation results, and limitations.

### Backup and Recovery Evidence

Two recovery tests are documented in [Lab 04: PostgreSQL Backup and Restore](../04-postgresql-backup-restore/README.md).

- The 24 October test verified selected record IDs, text hashes, and sequence state.
- The 28 October test restored the backup into an isolated PostgreSQL instance and verified matching row counts between the original and restored tables.

The second test did not independently verify exact record equality or restored sequence state.

**Validation:** Automatic systemd service startup after a real server reboot was verified. The backup script also correctly skipped a duplicate backup when a successful backup was already recorded for that day.
