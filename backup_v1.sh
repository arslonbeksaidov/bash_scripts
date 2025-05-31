#!/bin/bash

# MySQL credentials
USER="qabul_user"
PASSWORD="2024@dmission2025"
HOST="127.0.0.1"


# Backup directory (set to your home directory)
BACKUP_DIR="$HOME/mysql_backups"

# Date format for backup file name
DATE=$(date +"%Y-%m-%d_%H-%M")

# MySQL dump options
MYSQLDUMP="/usr/bin/mysqldump"
GZIP="/bin/gzip"

# Name of the database to backup
DATABASE_NAME="qabul_db"

# Lock file location to prevent concurrent execution
LOCK_FILE="/tmp/mysql_backup.lock"
PYTHON_SCRIPT="/root/send_large_file.py"
# Create a backup file path
BACKUP_FILE="$BACKUP_DIR/${DATABASE_NAME}-backup-$DATE.sql"
COMPRESSED_FILE="${BACKUP_FILE}.xz"
CHUNK_PREFIX="${COMPRESSED_FILE}_part_"

# Check if the lock file exists (meaning the previous process is still running)
if [ -f $LOCK_FILE ]; then
    echo "Backup is already running. Exiting."
    exit 1
fi
trap "rm -f $LOCK_FILE" EXIT
# Create the lock file to indicate that the process is running
touch $LOCK_FILE

# Create the backup directory if it doesn't exist
mkdir -p $BACKUP_DIR



# Run the MySQL dump and compress the output
$MYSQLDUMP -u$USER -p$PASSWORD -h$HOST $DATABASE_NAME > $BACKUP_FILE
if [ $? -eq 0 ]; then
    xz -z -9 $BACKUP_FILE
    if [ $? -eq 0 ]; then
        echo "Backup successful: ${BACKUP_FILE}.xz"

        # Call the Python script to send the backup file via Telethon
        python3 $PYTHON_SCRIPT "${BACKUP_FILE}.xz"

        if [ $? -eq 0 ]; then
            echo "Backup file sent to Telegram successfully."
        else
            echo "Error sending the backup file to Telegram."
        fi
    else
        echo "Error compressing the MySQL backup file."
    fi
else
    echo "Error during MySQL backup."
fi

# Remove the lock file to allow the next backup to run
rm
