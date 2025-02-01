!/bin/bash

mkdir -p certs

handle_error() {
    echo "Error: $1"
    exit 1
}

# ====================
# Step 1: Generate Root CA
# ====================
echo "=== Step 1: Generating Root CA ==="

# non-interactive passphrase (NIP)
openssl genpkey -algorithm RSA -out certs/root-ca.key -aes256 -pass pass:MySecurePassword || handle_error "Failed to generate Root CA private key."

openssl req -x509 -new -nodes \
    -key certs/root-ca.key \
    -sha256 \
    -days 3650 \
    -out certs/root-ca.crt \
    -subj "/C=US/ST=California/L=San Francisco/O=TLS-Certificate-Generator/CN=My Root CA" \
    -extensions v3_ca \
    -config config/ca.cnf \
    -passin file:<(echo "MySecurePassword") || handle_error "Failed to generate Root CA certificate."
echo "Root CA certificate generated successfully: certs/root-ca.crt"

# ====================
# Step 2: Generate Intermediate CA
# ====================
echo "=== Step 2: Generating Intermediate CA ==="

# NIP
openssl genpkey -algorithm RSA -out certs/intermediate-ca.key -aes256 -pass pass:MySecurePassword || handle_error "Failed to generate Intermediate CA private key."

# Generate Intermediate CA CSR
openssl req -new \
    -key certs/intermediate-ca.key \
    -out certs/intermediate-ca.csr \
    -subj "/C=US/ST=California/L=San Francisco/O=TLS-Certificate-Generator/CN=My Intermediate CA" \
    -passin file:<(echo "MySecurePassword") || handle_error "Failed to generate Intermediate CA CSR."

# Sign Intermediate CA CSR with Root CA
openssl x509 -req \
    -in certs/intermediate-ca.csr \
    -CA certs/root-ca.crt \
    -CAkey certs/root-ca.key \
    -CAcreateserial \
    -out certs/intermediate-ca.crt \
    -days 1825 \
    -sha256 \
    -extfile config/ca.cnf \
    -extensions v3_intermediate_ca \
    -passin file:<(echo "MySecurePassword") || handle_error "Failed to sign Intermediate CA certificate."
echo "Intermediate CA certificate generated successfully: certs/intermediate-ca.crt"

# ====================
# Step 3: Generate Server Certificate
# ====================
echo "=== Step 3: Generating Server Certificate ==="

# Generate Server private key (no passphrase for simplicity)
openssl genpkey -algorithm RSA -out certs/server.key || handle_error "Failed to generate Server private key."

# Generate Server CSR
openssl req -new \
    -key certs/server.key \
    -out certs/server.csr \
    -subj "/C=US/ST=California/L=San Francisco/O=TLS-Certificate-Generator/CN=myproject.local" \
    -config config/server.ext || handle_error "Failed to generate Server CSR."

# Sign Server CSR with Intermediate CA
openssl x509 -req \
    -in certs/server.csr \
    -CA certs/intermediate-ca.crt \
    -CAkey certs/intermediate-ca.key \
    -CAcreateserial \
    -out certs/server.crt \
    -days 365 \
    -sha256 \
    -extfile config/server.ext \
    -extensions server_cert \
    -passin file:<(echo "MySecurePassword") || handle_error "Failed to sign Server certificate."
echo "Server certificate generated successfully: certs/server.crt"

# ====================
# Step 4: Generate Wildcard Certificate
# ====================
echo "=== Step 4: Generating Wildcard Certificate ==="

# Generate Wildcard private key (ECDSA P-384, no passphrase for simplicity)
openssl ecparam -genkey -name secp384r1 -out certs/wildcard.key || handle_error "Failed to generate Wildcard private key."

# Generate Wildcard CSR
openssl req -new \
    -key certs/wildcard.key \
    -out certs/wildcard.csr \
    -subj "/C=US/ST=California/L=San Francisco/O=TLS-Certificate-Generator/CN=*.myproject.local" \
    -config config/server.ext || handle_error "Failed to generate Wildcard CSR."

# Sign Wildcard CSR with Intermediate CA
openssl x509 -req \
    -in certs/wildcard.csr \
    -CA certs/intermediate-ca.crt \
    -CAkey certs/intermediate-ca.key \
    -CAcreateserial \
    -out certs/wildcard.crt \
    -days 365 \
    -sha256 \
    -extfile config/server.ext \
    -extensions server_cert \
    -passin file:<(echo "MySecurePassword") || handle_error "Failed to sign Wildcard certificate."
echo "Wildcard certificate generated successfully: certs/wildcard.crt"

# ====================
# Step 5: Generate Certificate Chain
# ====================
echo "=== Step 5: Generating Certificate Chain ==="

cat certs/server.crt certs/intermediate-ca.crt certs/root-ca.crt > certs/fullchain.pem || handle_error "Failed to generate certificate chain."
echo "Certificate chain generated successfully: certs/fullchain.pem"

echo "All certificates generated successfully!"
