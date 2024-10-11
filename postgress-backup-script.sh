#!/bin/bash

# Backup file details
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="postgres_backup_${TIMESTAMP}.sql"

# Create backup
PGPASSWORD=${DB_PASSWORD} pg_dump -h ${DB_HOST} -U ${DB_USER} -p ${DB_PORT} -d ${DB_NAME} -N cron > ${BACKUP_FILE}

# Compress the backup
gzip ${BACKUP_FILE}

# Clean up local files
rm ${BACKUP_FILE}.gz
