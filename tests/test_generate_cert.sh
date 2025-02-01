#!/bin/bash

# Function to handle errors
handle_error() {
    echo "Error: $1"
    exit 1
}

echo "=== Running Certificate Generation Tests ==="

echo "Running certificate generation scripts..."
./scripts/generate_ca.sh || handle_error "Failed to generate CA certificates."
./scripts/generate_cert.sh || handle_error "Failed to generate server certificates."

echo "Checking if required files exist..."
FILES=("certs/root-ca.key" "scripts/generate_cert.sh")
for FILE in "${FILES[@]}"; do
    if [[ ! -f "$FILE" ]]; then
        handle_error "File not found: $FILE"
    fi
done
echo "All required files exist."

echo "Validating Root CA certificate..."
openssl x509 -in certs/root-ca.crt -text -noout > /dev/null || handle_error "Invalid Root CA certificate."
echo "Root CA certificate is valid."

echo "Validating Intermediate CA certificate..."
openssl verify -CAfile certs/root-ca.crt certs/intermediate-ca.crt || handle_error "Intermediate CA certificate validation failed."
echo "Intermediate CA certificate is valid."

echo "Validating Server certificate..."
openssl verify -CAfile certs/fullchain.pem certs/server.crt || handle_error "Server certificate validation failed."
echo "Server certificate is valid."

echo "Validating Wildcard certificate..."
openssl verify -CAfile certs/fullchain.pem certs/wildcard.crt || handle_error "Wildcard certificate validation failed."
echo "Wildcard certificate is valid."

echo "Validating certificate expiration dates..."
EXPIRATION_DATE=$(openssl x509 -enddate -noout -in certs/server.crt | cut -d= -f2)
echo "Server certificate expires on: $EXPIRATION_DATE"

echo "Validating cryptographic strength..."
# Check server private key size (RSA 2048-bit)
KEY_SIZE=$(openssl rsa -in certs/server.key -text -noout 2>/dev/null | grep "Private-Key" | cut -d'(' -f2 | cut -d' ' -f1)
if [[ "$KEY_SIZE" -ne 2048 ]]; then
    handle_error "Server private key size is invalid. Expected 2048 bits, got $KEY_SIZE bits."
fi
echo "Server private key size is valid (2048 bits)."

# Check server certificate signature algorithm (SHA-256)
SIGNATURE_ALGORITHM=$(openssl x509 -in certs/server.crt -text -noout | grep "Signature Algorithm" | head -n1 | awk '{print $2}')
if [[ "$SIGNATURE_ALGORITHM" != "sha256WithRSAEncryption" ]]; then
    handle_error "Server certificate uses an invalid signature algorithm. Expected sha256WithRSAEncryption, got $SIGNATURE_ALGORITHM."
fi
echo "Server certificate uses a valid signature algorithm (SHA-256)."

echo "Validating Subject Alternative Names (SANs)..."
SAN_OUTPUT=$(openssl x509 -in certs/server.crt -text -noout | grep -A1 "Subject Alternative Name")
if [[ -z "$SAN_OUTPUT" ]]; then
    handle_error "No Subject Alternative Names (SANs) found in server certificate."
fi
echo "Subject Alternative Names (SANs) are valid: $SAN_OUTPUT"

echo "Validating certificate chain..."
openssl verify -CAfile certs/fullchain.pem certs/server.crt || handle_error "Certificate chain validation failed."
echo "Certificate chain is valid."

echo "=== All tests completed successfully! ==="
