#!/bin/bash

# ================================
# Configuration (Change as needed)
# ================================
LOG_FILE="$HOME/Library/Logs/key_rotation.log"
CERT_DIR="certs"
CA_CERT="$CERT_DIR/ca.crt"
CA_KEY="$CERT_DIR/ca.key"
SERVER_CERT="$CERT_DIR/server.crt"
SERVER_KEY="$CERT_DIR/server.key"
SERVER_CSR="$CERT_DIR/server.csr"
PASSPHRASE_FILE="$HOME/.server_passphrase"  # Store passphrase securely in a file (ensure proper file permissions)

# ================================
# Logging Function
# ================================
log() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] $message" | tee -a "$LOG_FILE"
}

# ================================
# Check for Required Files
# ================================
check_files() {
    if [[ ! -d "$CERT_DIR" ]]; then
        log "Certificate directory $CERT_DIR does not exist. Exiting."
        exit 1
    fi
    if [[ ! -f "$CA_CERT" ]]; then
        log "CA certificate ($CA_CERT) not found. Exiting."
        exit 1
    fi
    if [[ ! -f "$CA_KEY" ]]; then
        log "CA private key ($CA_KEY) not found. Exiting."
        exit 1
    fi
}

# ================================
# Backup Old Keys
# ================================
backup_old_keys() {
    if [[ -f "$SERVER_KEY" ]]; then
        log "Backing up old server private key..."
        mv "$SERVER_KEY" "$SERVER_KEY.old"
    fi
    if [[ -f "$SERVER_CERT" ]]; then
        log "Backing up old server certificate..."
        mv "$SERVER_CERT" "$SERVER_CERT.old"
    fi
}

# ================================
# Generate New Key and CSR
# ================================
generate_new_keys() {
    log "Generating new server private key..."
    openssl genpkey -algorithm RSA -out "$SERVER_KEY" || { log "Failed to generate new server private key."; exit 1; }

    log "Generating new Certificate Signing Request (CSR)..."
    openssl req -new \
        -key "$SERVER_KEY" \
        -out "$SERVER_CSR" \
        -subj "/C=US/ST=California/L=San Francisco/O=My Cyber Project/CN=myproject.local" || { log "Failed to generate CSR."; exit 1; }
}

# ================================
# Sign New Server Certificate
# ================================
sign_server_cert() {
    log "Signing new server certificate with CA..."
    openssl x509 -req \
        -in "$SERVER_CSR" \
        -CA "$CA_CERT" \
        -CAkey "$CA_KEY" \
        -CAcreateserial \
        -out "$SERVER_CERT" \
        -days 365 \
        -sha256 \
        -extfile config/server.ext \
        -passin file:"$PASSPHRASE_FILE" || { log "Failed to sign new server certificate."; exit 1; }
}

# ================================
# Main Execution
# ================================
main() {
    # Check for necessary files
    check_files

    # Backup old keys and certificates
    backup_old_keys

    # Generate new server key and CSR
    generate_new_keys

    # Sign the new server certificate
    sign_server_cert

    log "Key rotation completed successfully."
}

# Run the script
main

exit 0
