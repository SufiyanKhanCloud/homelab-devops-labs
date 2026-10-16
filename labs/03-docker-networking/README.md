# Docker Networking

## Objective

Run a containerized web application and PostgreSQL database on a
user-defined Docker bridge network, then verify container-to-container
communication using Docker DNS.

## Architecture

```mermaid
flowchart TD
    App["Flask + Gunicorn Container"]
    Network["Docker Bridge: notes-net"]
    DB[("PostgreSQL Container")]
    Volume[("Named Volume: pgdata")]

    App <--> Network
    DB <--> Network
    DB --> Volume
```

## Environment

| Component | Role |
|---|---|
| Flask | Web application |
| Gunicorn | Application server |
| PostgreSQL | Relational database |
| Docker bridge | Container networking |
| Docker DNS | Service-name resolution |
| Named volume | Persistent database storage |

## Implementation

### 1. Create a user-defined network

```bash
docker network create notes-net
```

If the network already exists, inspect it instead of creating a duplicate.

### 2. Inspect the network

```bash
docker network inspect notes-net
```

Check the network configuration and attached containers.

### 3. Verify container status

```bash
docker ps
```

Confirm that the application and database containers are running.

### 4. Verify database name resolution

The application uses the database service/container name:

```text
DB_HOST=db
```

This configuration was used in the lab to connect the application
to PostgreSQL through Docker's internal DNS.

Do not publish actual passwords or environment-file contents.

### 5. Verify the application endpoint

The `/notes` endpoint returned HTTP 200 during testing.

An HTTP 200 response confirms a successful HTTP request. Database
functionality should also be checked using appropriate application
and database-level tests.

## Key Findings

- Containers on a shared user-defined bridge can communicate using
  Docker DNS names.
- An application can use a database container name instead of a
  hard-coded container IP address.
- Container networking and persistent storage are separate concerns.
- Successful HTTP responses are useful evidence, but do not replace
  database integrity and persistence tests.

## Security Considerations

- Keep database credentials out of source control.
- Avoid publishing database ports unless external access is required.
- Use least-privilege database accounts.
- Inspect container configuration before sharing terminal output.
- Never publish real database backups containing sensitive data.

## Pending Work

- [ ] Document the exact application and database configuration.
- [ ] Verify database persistence after container recreation.
- [ ] Migrate the lab to Docker Compose.
- [ ] Add a repeatable connectivity test.

## Status

Application-to-database connectivity and Docker name resolution tested.
Additional persistence and automation tests remain pending.
