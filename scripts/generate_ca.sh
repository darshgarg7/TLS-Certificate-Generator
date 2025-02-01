#!/bin/bash
# ====================
# Script: Generate CA Certificate
# Description: Automates the generation of a self-signed CA certificate and private key.
# Usage: ./scripts/generate_ca.sh [optional: CA_NAME] [optional: VALIDITY_DAYS]
# ====================
# Function to handle errors
handle_error() {
    echo "Error: $1"
    exit 1
}
# ====================
# Step 1: Parse Input Arguments
# ====================
CA_NAME="${1:-My CA}"                  # Default CA name: "My CA"
VALIDITY_DAYS="${2:-365}"              # Default validity: 365 days
CERTS_DIR="certs"                      # Directory to store certificates
CONFIG_FILE="config/ca.cnf"            # Configuration file for OpenSSL
# Validate input
if [[ ! -f "$CONFIG_FILE" ]]; then
    handle_error "Configuration file not found: $CONFIG_FILE"
fi
# ====================
# Step 2: Ensure Certificates Directory Exists
# ====================
echo "Ensuring certificates directory exists..."
mkdir -p "$CERTS_DIR" || handle_error "Failed to create directory: $CERTS_DIR"
# ====================
# Step 3: Generate CA Private Key
# ====================
echo "Generating CA private key using Dilithium2..."
PRIVATE_KEY="$CERTS_DIR/ca.key"
PASSPHRASE="${CA_PASSPHRASE:-MySecurePassword}"  # Default passphrase (override with env var)
openssl genpkey -algorithm dilithium2 -out "$PRIVATE_KEY" || handle_error "Failed to generate CA private key."
echo "CA private key generated successfully: $PRIVATE_KEY"
# ====================
# Step 4: Initialize CA Database Files
# ====================
echo "Initializing CA database files..."
touch "$CERTS_DIR/index.txt" || handle_error "Failed to create index.txt"
echo 1000 > "$CERTS_DIR/serial" || handle_error "Failed to create serial file."
# ====================
# Step 5: Generate Self-Signed CA Certificate
# ====================
echo "Generating self-signed CA certificate..."
CA_CERT="$CERTS_DIR/ca.crt"
openssl req -x509 -new -nodes \
    -config "$CONFIG_FILE" \
    -key "$PRIVATE_KEY" \
    -sha256 \
    -days "$VALIDITY_DAYS" \
    -out "$CA_CERT" \
    -subj "/C=US/ST=California/L=San Francisco/O=TLS-Certificate-Generator/CN=$CA_NAME" || handle_error "Failed to generate CA certificate."
echo "CA certificate generated successfully: $CA_CERT"
# ====================
# Step 6: Verify the CA Certificate
# ====================
echo "Verifying CA certificate..."
openssl x509 -in "$CA_CERT" -text -noout || handle_error "Failed to verify CA certificate."
echo "CA certificate verification completed."
# ====================
# Step 7: Security Recommendations
# ====================
echo "Security Recommendations:"
echo "- Store the private key (\`$PRIVATE_KEY\`) securely (e.g., HashiCorp Vault)."
echo "- Rotate the passphrase periodically."
echo "- Restrict access to the \`$CERTS_DIR\` directory using filesystem permissions."
echo "CA setup completed successfully!"
