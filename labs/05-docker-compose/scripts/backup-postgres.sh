#!/usr/bin/env bash

set -Eeuo pipefail
umask 077

CONTAINER="notes-app-db-1"
DB_NAME="postgres"
DB_USER="postgres"
BACKUP_DIR="/home/sufiyan/lab/notes-app/backups"
LAST_SUCCESS_FILE="${BACKUP_DIR}/.last-successful-backup-date"
TIMESTAMP="$(date +%Y-%m-%d-%H%M%S)"
TODAY="$(date +%F)"
FINAL_FILE="${BACKUP_DIR}/notes-db-${TIMESTAMP}.dump"
TEMP_FILE=""
STATE_TEMP_FILE=""

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
}

trap cleanup EXIT

mkdir -p "$BACKUP_DIR"
chmod 700 "$BACKUP_DIR"

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

for ATTEMPT in $(seq 1 30); do
    if [[ "$(docker inspect -f '{{.State.Running}}' "$CONTAINER" 2>/dev/null || true)" != "true" ]]; then
        log "PostgreSQL container is not running (attempt ${ATTEMPT}/30)."
    elif docker exec "$CONTAINER" pg_isready -U "$DB_USER" -d "$DB_NAME" >/dev/null 2>&1; then
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

if ! docker exec "$CONTAINER" pg_dump \
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

if ! docker exec -i "$CONTAINER" pg_restore --list \
    < "$TEMP_FILE" > /dev/null; then
    log "ERROR: Backup archive validation failed."
    exit 1
fi

chmod 600 "$TEMP_FILE"
mv -- "$TEMP_FILE" "$FINAL_FILE"
TEMP_FILE=""

log "Backup created and validated: $FINAL_FILE"

mapfile -t OLD_BACKUPS < <(
    find "$BACKUP_DIR" -maxdepth 1 -type f \
        -name 'notes-db-*.dump' \
        -printf '%f\n' |
    sort -r |
    tail -n +8
)

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
