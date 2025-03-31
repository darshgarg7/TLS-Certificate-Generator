#!/bin/bash
# ================================
# Script: letsencrypt.sh
# Description: Automates certificate issuance using Let's Encrypt.
# Usage: ./scripts/letsencrypt.sh [DOMAIN] [EMAIL]
# ================================
DOMAIN="${1:-TLS-Certificate-Generator.local}"
EMAIL="${2:-admin@example.com}"
LOG_FILE="$HOME/Library/logs/letsencrypt.log"
CERT_DIR="certs"

log() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] $message" | tee -a "$LOG_FILE"
}

handle_error() {
    log "Error: $1"
    exit 1
}

# Ensure Certbot is installed
if ! command -v certbot &> /dev/null; then
    handle_error "Certbot is not installed. Please install it using 'brew install certbot'."
fi

# Ensure certificates directory exists
mkdir -p "$CERT_DIR" || handle_error "Failed to create directory: $CERT_DIR"

# Request certificate from Let's Encrypt
log "Requesting certificate for domain: $DOMAIN..."
if ! certbot certonly --standalone \
    --non-interactive \
    --agree-tos \
    --email "$EMAIL" \
    --domains "$DOMAIN" \
    --config-dir "$CERT_DIR" \
    --work-dir "$CERT_DIR" \
    --logs-dir "$CERT_DIR"; then
    handle_error "Failed to request certificate for domain: $DOMAIN."
fi

log "Let's Encrypt certificate issued successfully for domain: $DOMAIN."
