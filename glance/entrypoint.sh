#!/bin/sh
# glance/entrypoint.sh
set -e

CONFIG_FILE="/config/glance.yml"
OPTIONS_FILE="/data/options.json"

mkdir -p /config

if [ ! -f "$CONFIG_FILE" ]; then
    echo "[glance] No config found at $CONFIG_FILE, seeding starter dashboard"
    cp /app/glance.yml.starter "$CONFIG_FILE"
elif ! grep -q "^server:" "$CONFIG_FILE"; then
    echo "[glance] Existing config has no server: block, adding one for base-url support"
    # shellcheck disable=SC2016 # literal ${GLANCE_BASE_URL} is for Glance's own substitution, not ours
    { printf 'server:\n  base-url: ${GLANCE_BASE_URL}\n'; cat "$CONFIG_FILE"; } > "$CONFIG_FILE.tmp"
    mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
fi

# Glance only supports one static base-url at a time (no per-request dynamic prefix
# detection), so it can't be simultaneously correct for both Ingress and the direct
# port. access_mode picks which one gets a working base-url; see DOCS.md.
ACCESS_MODE="ingress"
if [ -f "$OPTIONS_FILE" ]; then
    PARSED_MODE=$(sed -n 's/.*"access_mode"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$OPTIONS_FILE")
    [ -n "$PARSED_MODE" ] && ACCESS_MODE="$PARSED_MODE"
fi

GLANCE_BASE_URL=""
if [ "$ACCESS_MODE" = "ingress" ]; then
    INGRESS_URL=""
    if [ -n "$SUPERVISOR_TOKEN" ]; then
        INGRESS_URL=$(wget -qO- --header="Authorization: Bearer $SUPERVISOR_TOKEN" \
            "http://supervisor/apps/self/info" 2>/dev/null | \
            sed -n 's/.*"ingress_url"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
        if [ -z "$INGRESS_URL" ]; then
            # Older Supervisor releases only registered the legacy /addons/self route.
            INGRESS_URL=$(wget -qO- --header="Authorization: Bearer $SUPERVISOR_TOKEN" \
                "http://supervisor/addons/self/info" 2>/dev/null | \
                sed -n 's/.*"ingress_url"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
        fi
    fi
    if [ -n "$INGRESS_URL" ]; then
        GLANCE_BASE_URL="${INGRESS_URL%/}"
        echo "[glance] access_mode=ingress, base-url=$GLANCE_BASE_URL"
    else
        echo "[glance] access_mode=ingress but could not determine the ingress URL from Supervisor; starting with base-url empty (Ingress styling/widgets will be broken until this resolves)"
    fi
else
    echo "[glance] access_mode=direct, base-url left empty"
fi
export GLANCE_BASE_URL

echo "[glance] Starting Glance with config $CONFIG_FILE"
exec /app/glance --config "$CONFIG_FILE"
