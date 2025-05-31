#!/bin/bash

# MySQL credentials
USER=""
PASSWORD=""
HOST="127.0.0.1"

# Backup directory
BACKUP_DIR="$HOME/mysql_backups"

# Timestamp
DATE=$(date +"%Y-%m-%d_%H-%M")

# Tools
MYSQLDUMP="/usr/bin/mysqldump"
DATABASE_NAME=""
LOCK_FILE="/tmp/mysql_backup.lock"
PYTHON_SCRIPT="/root/send_large_file.py"
BACKUP_FILE="$BACKUP_DIR/${DATABASE_NAME}-backup-$DATE.sql"
COMPRESSED_FILE="${BACKUP_FILE}.xz"
CHUNK_PREFIX="${COMPRESSED_FILE}_part_"
XZ="/usr/bin/xz"
# Create backup directory
mkdir -p "$BACKUP_DIR"

# Lock mechanism
if [ -f "$LOCK_FILE" ]; then
    echo "Backup already running. Exiting."
    exit 1
fi
trap "rm -f $LOCK_FILE" EXIT
touch "$LOCK_FILE"

# Step 1: MySQL Dump
echo "[*] Dumping MySQL database..."
$MYSQLDUMP -u$USER -p$PASSWORD -h$HOST $DATABASE_NAME > "$BACKUP_FILE"
if [ $? -ne 0 ]; then
    echo "[!] MySQL dump failed."
    exit 1
fi

# Step 2: Compress using pxz
echo "[*] Compressing with pxz (multi-threaded)..."
$XZ -z -9 -T0 "$BACKUP_FILE"
if [ $? -ne 0 ]; then
    echo "[!] Compression failed."
    exit 1
fi

# Step 3: Split the compressed file into 1.9GB chunks
echo "[*] Splitting into 1.9GB parts..."
split -b 1900M "$COMPRESSED_FILE" "$CHUNK_PREFIX"
if [ $? -ne 0 ]; then
    echo "[!] Splitting failed."
    exit 1
fi

# Step 4: Send each chunk with Python script
for chunk in ${CHUNK_PREFIX}*; do
    echo "[*] Sending: $chunk"
    python3 "$PYTHON_SCRIPT" "$chunk"
    if [ $? -ne 0 ]; then
        echo "[!] Failed to send $chunk"
    else
        echo "[+] Sent $chunk successfully"
    fi
done

# Optional: cleanup chunks after sending
rm -f ${CHUNK_PREFIX}*
rm -f "$COMPRESSED_FILE"

echo "[✓] All done."
