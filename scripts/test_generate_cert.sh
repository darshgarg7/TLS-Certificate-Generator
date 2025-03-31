#!/bin/bash
# ================================
# Script: test_generate_cert.sh
# Description: Validates the certificate generation process.
# Usage: ./tests/test_generate_cert.sh
# ================================
CERT_DIR="certs"
CA_CERT="$CERT_DIR/ca.crt"
SERVER_CERT="$CERT_DIR/server.crt"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [TEST] $1"
}

handle_error() {
    log "Test Failed: $1"
    exit 1
}

# Test 1: Verify CA Certificate
log "Testing CA certificate validity..."
if ! openssl x509 -in "$CA_CERT" -text -noout >/dev/null 2>&1; then
    handle_error "CA certificate is invalid."
fi
log "CA certificate is valid."

# Test 2: Verify Server Certificate
log "Testing server certificate validity..."
if ! openssl x509 -in "$SERVER_CERT" -text -noout >/dev/null 2>&1; then
    handle_error "Server certificate is invalid."
fi
log "Server certificate is valid."

# Test 3: Check Expiration
log "Checking server certificate expiration..."
EXPIRATION_DATE=$(openssl x509 -enddate -noout -in "$SERVER_CERT" | cut -d= -f2)
CURRENT_DATE=$(date --date="now" +%s)
EXPIRATION_TIMESTAMP=$(date --date="$EXPIRATION_DATE" +%s)

if [[ "$CURRENT_DATE" -ge "$EXPIRATION_TIMESTAMP" ]]; then
    handle_error "Server certificate has expired."
fi
log "Server certificate has not expired."

# Test 4: Validate SANs
log "Validating Subject Alternative Names (SANs)..."
SAN_LIST=$(openssl x509 -in "$SERVER_CERT" -text -noout | grep -A1 "Subject Alternative Name" | tail -n1)
if [[ -z "$SAN_LIST" ]]; then
    handle_error "No SANs found in server certificate."
fi
log "SANs validated successfully: $SAN_LIST"

log "All tests passed successfully!"
