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

# Upload to S3
echo_step "Uploading backup to S3"
aws s3 cp ${BACKUP_FILE}.zip s3://${S3_BUCKET}/${DUMP_NAME}/

# Clean up local files
echo_step "Cleaning up local backup file"
rm ${BACKUP_FILE}.zip

# Keep only the 3 most recent backups in S3
echo_step "Removing old backups, keeping only the 3 most recent"
aws s3 ls s3://${S3_BUCKET}/${DUMP_NAME}/ | sort -r | awk 'NR>3 {print $4}' | xargs -I {} aws s3 rm s3://${S3_BUCKET}/${DUMP_NAME}/{}

echo_step "Backup process completed successfully"
