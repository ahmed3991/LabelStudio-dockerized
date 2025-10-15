#!/bin/bash
# backup/scripts/backup.sh
set -euo pipefail

# env from .env
: "${POSTGRES_USER:?}"
: "${POSTGRES_PASSWORD:?}"
: "${POSTGRES_DB:?}"
: "${RCLONE_REMOTE:?}"
: "${RCLONE_REMOTE_PATH:?}"
: "${BACKUP_RETENTION_DAYS:=14}"

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_DIR="/backups"
TMPDIR="${BACKUP_DIR}/tmp_${TIMESTAMP}"
mkdir -p "${TMPDIR}"

# 1) dump Postgres (custom format)
echo "Dumping Postgres..."
export PGPASSWORD="${POSTGRES_PASSWORD}"
pg_dump -U "${POSTGRES_USER}" -h db -F c -b -f "${TMPDIR}/${POSTGRES_DB}_${TIMESTAMP}.dump" "${POSTGRES_DB}"

# 2) archive labelstudio uploaded files and projects
echo "Archiving Label Studio files..."
tar -C / -czf "${TMPDIR}/labelstudio_data_${TIMESTAMP}.tar.gz" label-studio/data || true
tar -C / -czf "${TMPDIR}/projects_${TIMESTAMP}.tar.gz" label-studio/projects || true

# 3) create one archive
ARCHIVE="${BACKUP_DIR}/labelstudio_backup_${TIMESTAMP}.tar.gz"
tar -C "${TMPDIR}" -czf "${ARCHIVE}" .

# 4) upload with rclone
echo "Uploading ${ARCHIVE} to ${RCLONE_REMOTE}:${RCLONE_REMOTE_PATH}..."
rclone --config=/root/.config/rclone/rclone.conf copyto "${ARCHIVE}" "${RCLONE_REMOTE}:${RCLONE_REMOTE_PATH}/$(basename ${ARCHIVE})" --progress

# 5) prune local backups older than retention days
echo "Pruning local backups older than ${BACKUP_RETENTION_DAYS} days..."
find "${BACKUP_DIR}" -maxdepth 1 -type f -mtime +${BACKUP_RETENTION_DAYS} -name "labelstudio_backup_*.tar.gz" -delete

# 6) optional: prune remote (use rclone's --min-age or 'lsf' + delete if you want)
# Example to delete remote older than retention:
rclone --config=/root/.config/rclone/rclone.conf delete --min-age ${BACKUP_RETENTION_DAYS}d ${RCLONE_REMOTE}:${RCLONE_REMOTE_PATH}

# cleanup tmp
rm -rf "${TMPDIR}"

echo "Backup completed at $(date)."
