#!/bin/bash

# Path to the key rotation script
SCRIPT_PATH="<add your path to>/TLS-Certificate-Generator/scripts/rotate_keys.sh"
LOG_PATH="$HOME/Library/Logs/key_rotation.log"

# ================================
# Helper Functions
# ================================
log() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] $message"
}

validate_path() {
    local path="$1"
    if [[ ! -f "$path" ]]; then
        log "Error: File not found at $path."
        exit 1
    fi
    if [[ ! -x "$path" && "$path" == "$SCRIPT_PATH" ]]; then
        log "Error: Script is not executable: $path."
        exit 1
    fi
}

# ================================
# Validate Paths
# ================================
log "Validating paths..."
validate_path "$SCRIPT_PATH"
if [[ ! -d "$(dirname "$LOG_PATH")" ]]; then
    log "Creating log directory: $(dirname "$LOG_PATH")"
    mkdir -p "$(dirname "$LOG_PATH")"
fi

# ================================
# Add the Cron Job
# ================================
CRON_JOB="0 0 1 1 * $SCRIPT_PATH >> $LOG_PATH 2>&1"

log "Checking if cron job already exists..."
if ! crontab -l | grep -q "$SCRIPT_PATH"; then
    log "Adding cron job..."
    (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
    if [[ $? -eq 0 ]]; then
        log "Cron job added successfully."
    else
        log "Failed to add cron job. Please check your permissions."
        exit 1
    fi
else
    log "Cron job already exists. No changes made."
fi
