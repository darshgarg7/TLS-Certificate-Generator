#!/bin/bash

handle_error() {
    echo "Error: $1"
    exit 1
}
# ====================
# Step 1: Parse Input Arguments
# ====================
CLIENT_NAME="${1:-Client}"         # Default client name: "Client"
VALIDITY_DAYS="${2:-365}"          # Default validity: 365 days
CERTS_DIR="certs"                  # Directory to store certificates
INTERMEDIATE_CA_CERT="$CERTS_DIR/intermediate-ca.crt"  # Intermediate CA certificate
INTERMEDIATE_CA_KEY="$CERTS_DIR/intermediate-ca.key"   # Intermediate CA private key

# Validate input
if [[ ! -f "$INTERMEDIATE_CA_CERT" || ! -f "$INTERMEDIATE_CA_KEY" ]]; then
    handle_error "Intermediate CA files not found. Ensure certs/intermediate-ca.crt and certs/intermediate-ca.key exist."
fi

# Ensure certificates directory exists
mkdir -p "$CERTS_DIR" || handle_error "Failed to create directory: $CERTS_DIR"

# ====================
# Step 2: Generate Client Private Key (RSA)
# ====================
echo "Generating client private key using RSA..."
CLIENT_KEY="$CERTS_DIR/client.key"
openssl genpkey -algorithm RSA -out "$CLIENT_KEY" || handle_error "Failed to generate client private key."
echo "Client private key generated successfully: $CLIENT_KEY"

# ====================
# Step 3: Generate Client CSR
# ====================
echo "Generating client Certificate Signing Request (CSR)..."
CLIENT_CSR="$CERTS_DIR/client.csr"
openssl req -new \
    -key "$CLIENT_KEY" \
    -out "$CLIENT_CSR" \
    -subj "/C=US/ST=California/L=San Francisco/O=TLS-Certificate-Generator/CN=$CLIENT_NAME" || handle_error "Failed to generate client CSR."
echo "Client CSR generated successfully: $CLIENT_CSR"

# ====================
# Step 4: Sign Client CSR with Intermediate CA
# ====================
echo "Signing client CSR with Intermediate CA..."
CLIENT_CERT="$CERTS_DIR/client.crt"
openssl x509 -req \
    -in "$CLIENT_CSR" \
    -CA "$INTERMEDIATE_CA_CERT" \
    -CAkey "$INTERMEDIATE_CA_KEY" \
    -CAcreateserial \
    -out "$CLIENT_CERT" \
    -days "$VALIDITY_DAYS" \
    -sha256 || handle_error "Failed to sign client certificate."
echo "Client certificate generated successfully: $CLIENT_CERT"

# ====================
# Step 5: Verify Client Certificate
# ====================
echo "Verifying client certificate..."
openssl x509 -in "$CLIENT_CERT" -text -noout || handle_error "Failed to verify client certificate."
echo "Client certificate verification completed."

# ====================
# Step 6: Generate Full Chain for Client Certificate
# ====================
echo "Generating full certificate chain for client..."
cat "$CLIENT_CERT" "$INTERMEDIATE_CA_CERT" "$CERTS_DIR/root-ca.crt" > "$CERTS_DIR/client-fullchain.pem" || handle_error "Failed to generate client full chain."
echo "Client full certificate chain generated successfully: $CERTS_DIR/client-fullchain.pem"

echo "Client certificate setup completed successfully!"
