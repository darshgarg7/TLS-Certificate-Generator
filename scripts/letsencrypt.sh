#!/bin/bash

# ================================
# Configuration (Change as needed)
# ================================
DOMAIN="TLS-Certificate_Generator.local"
EMAIL="<enter your email here>"
LOG_DIR="logs"  # Subdirectory for logs
LOG_FILE="$LOG_DIR/certbot_request.log"

mkdir -p "$LOG_DIR"

log() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] $message" | tee -a "$LOG_FILE"
}

request_certificate() {
    log "Requesting certificate from Let's Encrypt for domain: $DOMAIN..."

    # check for errors
    if ! certbot certonly --standalone --non-interactive --agree-tos --email "$EMAIL" --domains "$DOMAIN"; then
        log "Failed to request certificate for domain: $DOMAIN."
        exit 1
    fi

    log "Let's Encrypt certificate issued successfully for domain: $DOMAIN."
}


request_certificate

exit 0
