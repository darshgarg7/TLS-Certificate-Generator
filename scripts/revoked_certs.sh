#!/bin/bash
# ================================
# Script: revoked_certs.sh
# Description: Automates the generation and verification of Certificate Revocation Lists (CRLs).
# Usage: ./scripts/revoked_certs.sh
# ================================

# ================================
# Configuration (Change as needed)
# ================================
CONFIG_FILE="config/ca.cnf"            # OpenSSL CA configuration file
CERTS_DIR="certs"                      # Directory to store certificates and CRLs
CRL_FILE="$CERTS_DIR/crl.pem"          # Path to the generated CRL file
CRL_DAYS=30                            # Validity period of the CRL (in days)
LOG_FILE="$HOME/Library/logs/crl.log"  # Log file location

# ================================
# Logging Function
# ================================
log() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] $message" | tee -a "$LOG_FILE"
}

handle_error() {
    local message="$1"
    log "Error: $message"
    exit 1
}

# ================================
# Validate Configuration
# ================================
validate_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        handle_error "Configuration file not found: $CONFIG_FILE"
    fi

    if [[ ! -d "$CERTS_DIR" ]]; then
        log "Creating certificates directory: $CERTS_DIR"
        mkdir -p "$CERTS_DIR" || handle_error "Failed to create directory: $CERTS_DIR"
    fi
}

# ================================
# Generate CRL
# ================================
generate_crl() {
    log "Generating Certificate Revocation List (CRL)..."
    openssl ca -config "$CONFIG_FILE" \
        -gencrl \
        -out "$CRL_FILE" \
        -crldays "$CRL_DAYS" || handle_error "Failed to generate CRL."

    log "CRL generated successfully: $CRL_FILE"
}

# ================================
# Verify CRL
# ================================
verify_crl() {
    log "Verifying CRL..."
    if openssl crl -in "$CRL_FILE" -text -noout >/dev/null 2>&1; then
        log "CRL verification completed successfully."
    else
        handle_error "Failed to verify CRL."
    fi
}

# ================================
# Update Server Configuration
# ================================
update_server_config() {
    log "Updating server configuration to use CRL..."
    echo "ssl_crl $CRL_FILE;" | tee -a config/nginx.conf || handle_error "Failed to update server configuration."
    log "Server configuration updated to use CRL: $CRL_FILE"
}

# ================================
# Main Execution
# ================================
main() {
    validate_config
    generate_crl
    verify_crl
    update_server_config
    log "CRL setup completed successfully!"
}

# Run the script
main
exit 0
