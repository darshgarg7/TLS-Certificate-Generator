#!/bin/bash

# Path to the key rotation script
SCRIPT_PATH="<add your path to>/TLS-Certificate-Generator/scripts/rotate_keys.sh"
LOG_PATH="$HOME/Library/Logs/key_rotation.log"

# Add the cron job
CRON_JOB="0 0 1 1 * $SCRIPT_PATH >> $LOG_PATH 2>&1"

# Check if the cron job already exists
if ! crontab -l | grep -q "$SCRIPT_PATH"; then
    echo "Adding cron job..."
    (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
    echo "Cron job added successfully."
else
    echo "Cron job already exists. No changes made."
fi
