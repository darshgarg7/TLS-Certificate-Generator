# TLS Certificate Generator

This project automates the creation of TLS certificates using OpenSSL and integrates with modern tools like Kubernetes and HashiCorp Vault. It demonstrates advanced security practices, scalability, and innovation.

## Features
Core Features
- Automated Certificate Generation : Generate self-signed certificates or integrate with Let's Encrypt for public-facing services.
- Scalable Deployment : Deploy certificates across multiple Kubernetes clusters using Helm charts and Cert-Manager.
Advanced Security :
- Mutual TLS (mTLS) for client-server authentication.
- Certificate revocation using CRLs and OCSP.
- Key rotation policies for expired or compromised keys. (Automated Annual Rotations, Email Notifications, and Certificate Validation.)
- Comprehensive Testing : Automated tests for certificate validation, expiration, and SAN verification.
Optional Features :
- Blockchain-Based Certificate Hashing : Immutable records for auditing and compliance.
- Automated Certificate Issuance
- HashiCorp Vault Integration


## Prerequisites
- macOS or Linux
- OpenSSL (Install via Homebrew: `brew install openssl`)
- Docker and Kubernetes (optional)
- brew install certbot (optional) 
- brew install vault (optional)
- Look through the files for areas where you have to add your own paths
- run command in terminal: chmod +x ./scripts/*.sh

## Installation
1. Clone the repository:
   git clone https://github.com/darshgarg7/TLS-Certificate_Generator.git
   cd TLS-Certificate_Generator

2. Install dependencies:
    brew install openssl certbot vault

## Usage
Generate a Root CA:
    chmod +x scripts/generate_ca.sh
    ./scripts/generate_ca.sh

Generate a server certificate (RSA):
     chmod +x scripts/generate_cert.sh
    ./scripts/generate_cert.sh

Automate certificate issuance with Let's Encrypt:
    ./scripts/letsencrypt.sh

Rotate keys:
    chmod +x key_rotation.sh 
    ./scripts/rotate_keys.sh

   # add Cron Job to automate key rotation (runs midnight on Jan 1st annually by default)
      chmod +x setup_cron.sh
      ./scripts/setup_cron.sh

Clean up generated files:
    chmod +x scripts/cleanup.sh
    ./scripts/cleanup.sh
        
        - you can specify a custom directory for cleanup:
        ./scripts/cleanup.sh /path/to/custom/directory

Automate Certificate Issuance:
   ./scripts/letsencrypt.sh


## Manage revoked certificates:  

for apple silicon mac go to:
- /opt/homebrew/etc/nginx/nginx.conf
- nano /usr/local/etc/nginx/nginx.conf
   and paste the following:

server {
    listen 443 ssl;
    server_name TLS-Certificate-Generator.local;

    ssl_certificate /Users/darshgarg7/TLS-Certificate-Generator/certs/server.crt;
    ssl_certificate_key /Users/darshgarg7/TLS-Certificate-Generator/certs/server.key;
    ssl_crl /Users/darshgarg7/TLS-Certificate-Generator/certs/crl.pem;

    location / {
        proxy_pass http://localhost:8080;
    }
}
save & exit: Ctrl + O, then Ctrl + X
then run:
- nginx -t (nginx: configuration file /opt/homebrew/etc/nginx/nginx.conf test is successful)
- brew services restart nginx
- brew services list (verify NGINX is running)
- chmod +x scripts/revoked_certs.sh
- ./scripts/revoked_certs.sh

## Testing
Run the test script to validate the certificate generation process:
    chmod +x tests/test_generate_cert.sh
    ./tests/test_generate_cert.sh

To verify the generated CA certificate using OpenSSL:
    openssl x509 -in certs/ca.crt -text -noout

## Test Cases:
- Certificate Exploration: verify certificates are valid within the TTL
- SAN Validation: ensure subject alternative names are correct
- mTLS Handshake: test mutual tls authentication

### Blockchain-Based Certificate Hashing (Experimental)

This project includes an experimental feature for hashing certificates and storing them on a blockchain.
This ensures immutability and transparency for certificate verification.

    #### Usage

    1. Store a Hash:
    ./scripts/blockchain_hash.sh store certs/ca.crt

    2. Verify a Hash:
    ./scripts/blockchain_hash.sh verify certs/ca.crt

## HashiCorp Vault
- brew install vault jq
- vault server -dev
- export VAULT_ADDR=http://127.0.0.1:8200
- export VAULT_TOKEN=myroot
- vault secrets enable -path=secret kv-v2
store a secret:
- ./scripts/vault_integration.sh store ca_private_key certs/ca.key
retrieve a secret:
- ./scripts/vault_integration.sh retrieve ca_private_key certs/ca.key
help menu (if needed lol):
- ./scripts/vault_integration.sh --help

## Deployment
Build the Docker image:
    docker-compose up --build .

Access the container's shell:
    docker exec -it tls-generator bash

Run the scripts directly inside the container:
    ./scripts/generate_ca.sh
    ./scripts/generate_cert.sh

Deploy to Kubernetes:
    kubectl apply -f k8s/tls-secret.yaml
    kubectl apply -f k8s/tls-ingress.yaml

Verify Deployment:
    kubectl get ingress

## Security Audit
Generate a security report using Qualys SSL Labs:

testssl.sh https://TLS-Certificate_Generator.local

    - Common Vulnerabilities to Check:
        Weak cipher suites (e.g., DES, RC4).
        Expired or misconfigured certificates.
        Lack of OCSP stapling.


-----------------------------------------------------------------
-----------------------------------------------------------------

### How to Navigate the Project

1. Understand the Diagram:
   - Start by reviewing the Mermaid.js diagram to understand the flow of the project.

2. Set Up the Environment:
   - Follow the Installation section to set up dependencies.

3. Generate Certificates:
   - Use the scripts (`generate_ca.sh`, `generate_cert.sh`) to create certificates.

4. Deploy to Kubernetes:
   - Apply the Kubernetes manifests to deploy certificates to a cluster.

5. Explore Optional Features:
   - Experiment with integrations like Let's Encrypt, HashiCorp Vault, and experimental features.

6. Test and Validate:
   - Run the automated tests and perform a security audit.

7. Clean Up:
   - Use the cleanup script to remove generated files.
