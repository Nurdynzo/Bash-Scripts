#!/bin/bash

# Backup file details
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="postgres_backup_${TIMESTAMP}.sql"

# Create backup
echo "${BACKUP_FILE}"

echo "${TEST_VAR}"
