#!/bin/sh
# glance/entrypoint.sh
set -e

CONFIG_FILE="/config/glance.yml"

mkdir -p /config

if [ ! -f "$CONFIG_FILE" ]; then
    echo "[glance] No config found at $CONFIG_FILE, seeding starter dashboard"
    cp /app/glance.yml.starter "$CONFIG_FILE"
fi

echo "[glance] Starting Glance with config $CONFIG_FILE"
exec /app/glance --config "$CONFIG_FILE"
