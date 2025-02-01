#!/bin/bash
# ================================
# Configuration (Change as needed)
# ================================
DOMAIN="TLS-Certificate-Generator.local"
EMAIL="<enter your email here>"
LOG_FILE="$HOME/Library/Logs/certbot_request.log"  # Log file location
log() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] $message" | tee -a "$LOG_FILE"
}
request_certificate() {
    log "Requesting quantum-resistant certificate from Let's Encrypt for domain: $DOMAIN..."
    # check for errors
    if ! certbot certonly --standalone --non-interactive --agree-tos --email "$EMAIL" --domains "$DOMAIN" --post-quantum; then
        log "Failed to request quantum-resistant certificate for domain: $DOMAIN."
        exit 1
    fi
    log "Let's Encrypt quantum-resistant certificate issued successfully for domain: $DOMAIN."
}

request_certificate
exit 0
