# TLS Certificate Generator

This project automates the creation of TLS certificates using OpenSSL and integrates with modern tools like Let's Encrypt, Kubernetes, and HashiCorp Vault. It demonstrates advanced security practices, scalability, and innovation.

## Features
Core Features
- Automated Certificate Generation : Generate self-signed certificates or integrate with Let's Encrypt for public-facing services.
- Scalable Deployment : Deploy certificates across multiple Kubernetes clusters using Helm charts and Cert-Manager.
Advanced Security :
- Mutual TLS (mTLS) for client-server authentication.
- Certificate revocation using CRLs and OCSP.
- Key rotation policies for expired or compromised keys. (Automated Annual Rotations, Email Notifications, and Certificate Validation.)
- Comprehensive Testing : Automated tests for certificate validation, expiration, and SAN verification.
Optional Features
- Post-Quantum Cryptography : Experimental support using Open Quantum Safe (liboqs).
- Blockchain-Based Certificate Hashing : Immutable records for auditing and compliance.


## Prerequisites
- macOS or Linux
- OpenSSL (Install via Homebrew: `brew install openssl`)
- Docker and Kubernetes (optional)
- Certbot for Let's Encrypt integration (`brew install certbot`)
- Look through the files for areas where you have to add your own paths

## Installation
1. Clone the repository:
   git clone https://github.com/darshgarg7/TLS-Certificate_Generator.git
   cd TLS-Certificate_Generator

2. Install dependencies:
    brew install openssl certbot

## Usage
Generate a Root CA:
    ./scripts/generate_ca.sh

Generate a server certificate:
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

### Blockchain-Based Certificate Hashing (Experimental) ###

This project includes an experimental feature for hashing certificates and storing them on a blockchain.
This ensures immutability and transparency for certificate verification.

    #### Usage ###

    1. **Store a Hash**:
    ./scripts/blockchain_hash.sh store certs/ca.crt

    2. **Verify a Hash**:
    ./scripts/blockchain_hash.sh verify certs/ca.crt

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

Verift Deployment:
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

### **How to Navigate the Project**

1. **Understand the Diagram**:
   - Start by reviewing the Mermaid.js diagram to understand the flow of the project.

2. **Set Up the Environment**:
   - Follow the **Installation** section to set up dependencies.

3. **Generate Certificates**:
   - Use the scripts (`generate_ca.sh`, `generate_cert.sh`) to create certificates.

4. **Deploy to Kubernetes**:
   - Apply the Kubernetes manifests to deploy certificates to a cluster.

5. **Explore Optional Features**:
   - Experiment with integrations like Let's Encrypt, HashiCorp Vault, and experimental features.

6. **Test and Validate**:
   - Run the automated tests and perform a security audit.

7. **Clean Up**:
   - Use the cleanup script to remove generated files.
