#!/bin/bash

# Exit on any error
set -e

# Function to echo steps
echo_step() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Backup file details
TIMESTAMP=$(date +%Y%m%d)
BACKUP_FILE="${DUMP_NAME}_${TIMESTAMP}"

echo_step "Starting database backup process"

# Create backup
echo_step "Creating database dump"
PGPASSWORD=${DB_PASSWORD} pg_dump -h ${DB_HOST} -U ${DB_USER} -p ${DB_PORT} -d ${DB_NAME} -N cron --no-owner > ${BACKUP_FILE}.sql

# Upload to S3
echo_step "Zipping backup"
zip ${BACKUP_FILE}.zip ${BACKUP_FILE}.sql

# Upload the dump to Azure Blob Storage
echo "Uploading ${BACKUP_FILE} to Azure Blob Storage..."
az storage blob upload \
    --account-name "${AZURE_STORAGE_ACCOUNT}" \
    --account-key "${AZURE_STORAGE_KEY}" \
    --container-name "${AZURE_STORAGE_CONTAINER}" \
    --file "${BACKUP_FILE}.zip" \
    --name "${BACKUP_FILE}.zip" \
    --overwrite

if [[ $? -eq 0 ]]; then
    echo "Successfully uploaded ${BACKUP_FILE} to Azure Blob Storage"
else
    echo "Error: Failed to upload ${BACKUP_FILE} to Azure Blob Storage"
    exit 1
fi

echo "Backup and upload completed successfully!"

# Clean up local files
echo_step "Cleaning up local backup file"
rm ${BACKUP_FILE}.zip

# Keep only the 3 most recent backups
echo "Checking for old backups to delete (keeping only the 3 most recent)..."
# List blobs, sort by name (newest first, assuming timestamp in filename), and get blobs to delete (beyond the 3rd)
blobs_to_delete=$(az storage blob list \
    --account-name "${AZURE_STORAGE_ACCOUNT}" \
    --account-key "${AZURE_STORAGE_KEY}" \
    --container-name "${AZURE_STORAGE_CONTAINER}" \
    --query "[?name.starts_with(@,'pg_dump_${DB_NAME}_')].name" \
    --output tsv | sort -r | tail -n +4)

# Check if there are blobs to delete
if [[ -n "$blobs_to_delete" ]]; then
    echo "Deleting old backups:"
    while IFS= read -r blob; do
        echo "Deleting blob: ${blob}"
        az storage blob delete \
            --account-name "${AZURE_STORAGE_ACCOUNT}" \
            --account-key "${AZURE_STORAGE_KEY}" \
            --container-name "${AZURE_STORAGE_CONTAINER}" \
            --name "${blob}"
    done <<< "$blobs_to_delete"
else
    echo "No old backups to delete (3 or fewer backups exist)."
fi

echo "Backup, upload, and cleanup completed successfully!"
