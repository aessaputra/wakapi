#!/bin/bash

# ==============================================================================
# WAKAPI BACKUP SCRIPT
#
# Task:
# - Back up the MariaDB database and the 'secrets' directory.
# - Upload the archives to an Rclone remote.
# - Clean up old local backups.
# ==============================================================================


# ------------------------------------------------------------------------------
# CONFIGURATION
# ------------------------------------------------------------------------------

# Database service name within the docker-compose.yml file
DB_SERVICE="db"

# Target database name
DB_NAME="wakapi"

# Local backup storage directory
BACKUP_DIR="backup"

# Directory containing critical secrets for recovery
SECRETS_DIR="secrets"

# Rclone configuration for off-site upload
RCLONE_REMOTE_NAME="WakapiBackup"
RCLONE_REMOTE_PATH="WakapiBackup"


# ------------------------------------------------------------------------------
# BACKUP EXECUTION
# ------------------------------------------------------------------------------

# This option ensures the script will exit if any command in a
# pipeline (e.g., `cmd1 | cmd2`) fails. Crucial for proper error handling.
set -o pipefail

echo "=================================================="
echo "Starting Wakapi backup process at $(date)"
echo "=================================================="

mkdir -p "$BACKUP_DIR"

# --- Database Dump ---
DB_FILENAME="${BACKUP_DIR}/wakapi-db-backup-$(date +%F).sql.gz"
echo "--> Backing up database '${DB_NAME}'..."

# Running the dump as the 'root' user via a socket is the most reliable method.
# This avoids 'Access Denied' issues by bypassing network/host-based
# authentication inside the container.
docker-compose exec -T "$DB_SERVICE" sh -c \
  'mariadb-dump --protocol=socket --socket=/run/mysqld/mysqld.sock -u"root" -p"$(cat /run/secrets/db_root_password)" "$MYSQL_DATABASE"' | gzip > "$DB_FILENAME"

if [ $? -ne 0 ]; then
  echo "❌ FAILED: An error occurred during database backup."
  exit 1
fi
echo "    ✅ Database successfully backed up to: ${DB_FILENAME}"


# --- Secrets Archive ---
SECRETS_FILENAME="${BACKUP_DIR}/wakapi-secrets-backup-$(date +%F).tar.gz"
echo "--> Archiving secrets directory '${SECRETS_DIR}'..."
tar -czf "$SECRETS_FILENAME" -C "./" "$SECRETS_DIR"

if [ $? -ne 0 ]; then
  echo "❌ FAILED: An error occurred while archiving the secrets directory."
  exit 1
fi
echo "    ✅ Secrets directory successfully archived to: ${SECRETS_FILENAME}"


# --- Rclone Upload ---
echo "--> Uploading backup files to remote '${RCLONE_REMOTE_NAME}'..."
rclone copy "$BACKUP_DIR" "${RCLONE_REMOTE_NAME}:${RCLONE_REMOTE_PATH}" --progress

if [ $? -ne 0 ]; then
  echo "❌ FAILED: An error occurred while uploading with rclone."
  exit 1
fi
echo "    ✅ All new backup files uploaded successfully."


# --- Local Cleanup ---
echo "--> Cleaning up local backup files older than 30 days..."
find "${BACKUP_DIR}" -name "*.sql.gz" -mtime +30 -delete
find "${BACKUP_DIR}" -name "*.tar.gz" -mtime +30 -delete
echo "    ✅ Cleanup complete."

echo "=================================================="
echo "Backup process finished successfully at $(date)"
echo "=================================================="

exit 0
