#!/bin/bash

CONTAINER_NAME="redis-master"
BACKUP_DIR="./backups"
DATE=$(date +%F_%H-%M-%S)

mkdir -p "$BACKUP_DIR"

# Save latest RDB
docker exec "$CONTAINER_NAME" redis-cli -a masterpass SAVE

# Copy dump.rdb from container to host
docker cp "$CONTAINER_NAME":/data/dump.rdb "$BACKUP_DIR/dump_$DATE.rdb"

# Delete backups older than 7 days (if find command is available on host)
find "$BACKUP_DIR" -type f -mtime +7 -delete