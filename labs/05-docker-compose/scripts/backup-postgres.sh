#!/usr/bin/env bash

set -Eeuo pipefail
umask 077

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

COMPOSE_FILE="${COMPOSE_FILE:-${PROJECT_DIR}/compose.yaml}"
DB_SERVICE="${DB_SERVICE:-db}"
DB_NAME="${DB_NAME:-postgres}"
DB_USER="${DB_USER:-postgres}"
BACKUP_DIR="${BACKUP_DIR:-${PROJECT_DIR}/backups}"
RETENTION_COUNT="${RETENTION_COUNT:-7}"

# Resolve relative paths from the project directory.
if [[ "$COMPOSE_FILE" != /* ]]; then
    COMPOSE_FILE="${PROJECT_DIR}/${COMPOSE_FILE}"
fi

if [[ "$BACKUP_DIR" != /* ]]; then
    BACKUP_DIR="${PROJECT_DIR}/${BACKUP_DIR}"
fi

LAST_SUCCESS_FILE="${BACKUP_DIR}/.last-successful-backup-date"
TIMESTAMP="$(date +%Y-%m-%d-%H%M%S)"
TODAY="$(date +%F)"
FINAL_FILE="${BACKUP_DIR}/notes-db-${TIMESTAMP}.dump"
TEMP_FILE=""
STATE_TEMP_FILE=""
RETENTION_TEMP_FILE=""

log() {
    printf '[%s] %s\n' "$(date '+%F %T')" "$*"
}

cleanup() {
    if [[ -n "${TEMP_FILE:-}" && -f "$TEMP_FILE" ]]; then
        rm -f -- "$TEMP_FILE"
    fi

    if [[ -n "${STATE_TEMP_FILE:-}" && -f "$STATE_TEMP_FILE" ]]; then
        rm -f -- "$STATE_TEMP_FILE"
    fi

    if [[ -n "${RETENTION_TEMP_FILE:-}" && -f "$RETENTION_TEMP_FILE" ]]; then
        rm -f -- "$RETENTION_TEMP_FILE"
    fi
}

trap cleanup EXIT

if [[ ! -f "$COMPOSE_FILE" ]]; then
    log "ERROR: Compose file not found: $COMPOSE_FILE"
    exit 1
fi

if [[ ! "$RETENTION_COUNT" =~ ^[1-9][0-9]*$ ]]; then
    log "ERROR: RETENTION_COUNT must be a positive integer."
    exit 1
fi

for command in docker flock find sort tail mktemp seq; do
    if ! command -v "$command" >/dev/null 2>&1; then
        log "ERROR: Required command not found: $command"
        exit 1
    fi
done

if ! docker compose version >/dev/null 2>&1; then
    log "ERROR: Docker Compose plugin is not available."
    exit 1
fi

cd "$PROJECT_DIR"

mkdir -p -m 700 "$BACKUP_DIR"

exec 9>"${BACKUP_DIR}/.backup.lock"

if ! flock -n 9; then
    log "ERROR: Another backup process is already running."
    exit 1
fi

if [[ -f "$LAST_SUCCESS_FILE" ]] &&
   [[ "$(<"$LAST_SUCCESS_FILE")" == "$TODAY" ]]; then
    log "A successful backup already ran today; skipping."
    exit 0
fi

log "Waiting for PostgreSQL to become ready."

READY=0
CONTAINER_ID=""

for ATTEMPT in $(seq 1 30); do
    CONTAINER_ID="$(
        docker compose -f "$COMPOSE_FILE" ps -q "$DB_SERVICE" 2>/dev/null || true
    )"

    if [[ -z "$CONTAINER_ID" ]]; then
        log "Database service container not found (attempt ${ATTEMPT}/30)."
    elif [[ "$(docker inspect -f '{{.State.Running}}' "$CONTAINER_ID" 2>/dev/null || true)" != "true" ]]; then
        log "Database container is not running (attempt ${ATTEMPT}/30)."
    elif docker exec "$CONTAINER_ID" pg_isready -U "$DB_USER" -d "$DB_NAME" >/dev/null 2>&1; then
        READY=1
        break
    else
        log "PostgreSQL is not ready yet (attempt ${ATTEMPT}/30)."
    fi

    sleep 10
done

if [[ "$READY" != "1" ]]; then
    log "ERROR: PostgreSQL did not become ready within 5 minutes."
    exit 1
fi

TEMP_FILE="$(mktemp "${BACKUP_DIR}/.notes-db-backup.XXXXXX.tmp")"

log "Starting PostgreSQL backup."

if ! docker exec "$CONTAINER_ID" pg_dump \
    -U "$DB_USER" \
    -d "$DB_NAME" \
    -Fc > "$TEMP_FILE"; then
    log "ERROR: pg_dump failed."
    exit 1
fi

if [[ ! -s "$TEMP_FILE" ]]; then
    log "ERROR: Backup file is empty."
    exit 1
fi

if ! docker exec -i "$CONTAINER_ID" pg_restore --list \
    < "$TEMP_FILE" > /dev/null; then
    log "ERROR: Backup archive validation failed."
    exit 1
fi

chmod 600 "$TEMP_FILE"
mv -- "$TEMP_FILE" "$FINAL_FILE"
TEMP_FILE=""

log "Backup created and validated: $FINAL_FILE"

RETENTION_TEMP_FILE="$(mktemp "${BACKUP_DIR}/.retention-list.XXXXXX.tmp")"

if ! find "$BACKUP_DIR" -maxdepth 1 -type f \
    -name 'notes-db-*.dump' \
    -printf '%f\n' |
    sort -r |
    tail -n "+$((RETENTION_COUNT + 1))" > "$RETENTION_TEMP_FILE"; then
    log "ERROR: Could not calculate backup retention list."
    exit 1
fi

mapfile -t OLD_BACKUPS < "$RETENTION_TEMP_FILE"
rm -- "$RETENTION_TEMP_FILE"
RETENTION_TEMP_FILE=""

for BACKUP in "${OLD_BACKUPS[@]}"; do
    if rm -- "${BACKUP_DIR}/${BACKUP}"; then
        log "Removed old backup: ${BACKUP}"
    else
        log "ERROR: Could not remove old backup: ${BACKUP}"
        exit 1
    fi
done

STATE_TEMP_FILE="$(mktemp "${BACKUP_DIR}/.last-success.XXXXXX.tmp")"
printf '%s\n' "$TODAY" > "$STATE_TEMP_FILE"
chmod 600 "$STATE_TEMP_FILE"
mv -- "$STATE_TEMP_FILE" "$LAST_SUCCESS_FILE"
STATE_TEMP_FILE=""

log "Backup job completed successfully."
