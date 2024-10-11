#!/bin/bash

# Backup file details
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${DUMP_NAME}${TIMESTAMP}.sql"

# Create backup
PGPASSWORD=${DB_PASSWORD} pg_dump -h ${DB_HOST} -U ${DB_USER} -p ${DB_PORT} -d ${DB_NAME} -N cron > ${BACKUP_FILE}

# Upload to S3
aws s3 cp ${BACKUP_FILE} s3://${S3_BUCKET}/${DUMP_NAME}/

# Clean up local files
rm ${BACKUP_FILE}
