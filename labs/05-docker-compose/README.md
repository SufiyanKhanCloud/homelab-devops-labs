# Lab 05: Docker Compose

## Objective

Migrate a manually managed Flask and PostgreSQL application to Docker Compose while preserving existing database data.

## Architecture

- **Application:** Flask with Gunicorn
- **Application image:** `notes-app:3`
- **Database:** PostgreSQL 16
- **Orchestration:** Docker Compose
- **Persistent storage:** Existing external Docker volume `pgdata`
- **Network:** Existing external Docker network `notes-net`
- **Application port:** `127.0.0.1:5000`

## Implementation

### 1. Created a protected environment file

Created a local `.env` file containing the application and PostgreSQL password variables.

Set its permissions to `600` so only the file owner can read or modify it.

The real `.env` file is excluded from Git using `.gitignore`. Credentials are not included in this repository documentation.

### 2. Defined the Compose services

Created `compose.yaml` with two services:

- `app`: Builds the Flask application image and runs Gunicorn.
- `db`: Runs PostgreSQL 16.

The application uses the Compose service name `db` as its database hostname.

### 3. Added health checks and startup dependency handling

Configured a PostgreSQL health check using `pg_isready`.

The application uses:

```yaml
depends_on:
  db:
    condition: service_healthy
```

This delays application startup until PostgreSQL reports healthy.

### 4. Preserved persistent storage

Configured `pgdata` as an external volume:

```yaml
volumes:
  pgdata:
    external: true
    name: pgdata
```

This reuses the existing volume instead of creating a replacement.

The existing `notes-net` network is also reused as an external network.

### 5. Validated the deployment

Validated the Compose configuration with:

```bash
docker compose config --quiet
```

Built the application image:

```bash
docker compose build app
```

Tested database connectivity from the new application image against the existing database before migration.

The query returned both existing records.

### 6. Migrated to Compose

Stopped the previous containers and started the Compose deployment:

```bash
docker compose up -d
```

After verifying the new deployment, removed the obsolete containers without removing their images or the database volume.

The previous `notes-app:2` image and the existing database backup were retained.

## Verification

### Application health

```bash
curl -i http://127.0.0.1:5000/health
```

Result: HTTP `200 OK`.

### Application API

```bash
curl -s http://127.0.0.1:5000/notes
```

The API returned the two original notes:

- ID 1: `survives container delete`
- ID 34: `Docker network DNS works`

### Database verification

```bash
docker compose exec db psql -U postgres -d postgres -c 'SELECT id, txt FROM notes ORDER BY id;'
```

Both original records remained present after migration.

### Restart verification

Restarted the application:

```bash
docker compose restart app
```

The application recovered, and both API endpoints continued to work.

Final verification with `docker compose ps` showed both services healthy.

## Key Learnings

- Docker Compose makes multi-container deployments repeatable.
- Service names provide DNS-based communication between containers.
- Health checks and `depends_on` help coordinate startup.
- External volumes allow Compose to reuse existing persistent data.
- Environment files keep credentials separate from application configuration.
- Container removal and volume removal are different operations.
- Testing database connectivity and verifying application data are essential during migration.

## Outcome

Successfully migrated the existing Flask and PostgreSQL deployment to Docker Compose while preserving the database records and reusing the existing volume and network.

The deployment was tested through application health checks, API queries, direct database queries, and an application restart.
