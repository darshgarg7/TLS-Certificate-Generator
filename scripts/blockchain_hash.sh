#!/bin/bash
# ====================
# Script: tlsblockchain.sh
# Description: Hashes a TLS certificate and stores/retrieves the hash on/from a blockchain.
# Usage:
#   - Store a hash: ./scripts/tlsblockchain.sh store <cert_file>
#   - Verify a hash: ./scripts/tlsblockchain.sh verify <cert_file>
#   - Help: ./scripts/tlsblockchain.sh --help
# ====================
# ====================
# Step 0: Configuration
# ====================
CONFIG_FILE="config/blockchain_config.json"                                # Path to configuration file
LOG_DIR="logs"                                                             # Default log directory
LOG_FILE="$LOG_DIR/tlsblockchain.log"                                      # Log file location
BLOCKCHAIN_API="${BLOCKCHAIN_API:-https://api.blockchainhash.example/v1}"  # Default API endpoint
MAX_RETRIES=3                                                              # Maximum retries for API calls
RETRY_DELAY=2                                                              # Delay between retries (seconds)
VAULT_PATH="secret/tls/private_keys"                                       # Vault path for private keys
mkdir -p "$LOG_DIR"

# Function to handle errors with context
handle_error() {
    local context="$1"
    local details="$2"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $context - $details" | tee -a "$LOG_FILE"
    exit 1
}

# Function to log messages
log_message() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1" | tee -a "$LOG_FILE"
}

# Function to log detailed debug messages
log_debug() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] DEBUG: $1" | tee -a "$LOG_FILE"
}

# Function to log API responses
log_api_response() {
    local action="$1"
    local response="$2"
    log_debug "API Response ($action): $response"
}

# Function to display help menu
display_help() {
    echo "Usage:"
    echo "  Store a hash: ./scripts/tlsblockchain.sh store <cert_file>"
    echo "  Verify a hash: ./scripts/tlsblockchain.sh verify <cert_file>"
    echo "  Help: ./scripts/tlsblockchain.sh --help"
    echo ""
    echo "Options:"
    echo "  --help      Display this help menu."
    echo "  --config    Specify a custom configuration file (default: config/blockchain_config.json)."
    echo ""
    echo "Environment Variables:"
    echo "  BLOCKCHAIN_API   Override the default blockchain API endpoint."
    echo ""
    echo "Logs are stored in $LOG_FILE for debugging purposes."
    exit 0
}

# Function to load configuration from a JSON file
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        log_message "Loading configuration from $CONFIG_FILE..."
        BLOCKCHAIN_API=$(jq -r '.blockchain_api' "$CONFIG_FILE" 2>/dev/null || echo "$BLOCKCHAIN_API")
        LOG_DIR=$(jq -r '.log_dir' "$CONFIG_FILE" 2>/dev/null || echo "$LOG_DIR")
        VAULT_PATH=$(jq -r '.vault_path' "$CONFIG_FILE" 2>/dev/null || echo "$VAULT_PATH")
        LOG_FILE="$LOG_DIR/tlsblockchain.log"
        mkdir -p "$LOG_DIR"
        log_message "Configuration loaded successfully."
    else
        log_message "Configuration file not found. Using default settings."
    fi
}

# Function to validate certificate file
validate_cert_file() {
    local cert_file="$1"
    if [[ ! -f "$cert_file" ]]; then
        handle_error "File Not Found" "Certificate file not found: $cert_file"
    fi
    if ! openssl x509 -in "$cert_file" -noout >/dev/null 2>&1; then
        handle_error "Invalid Certificate" "The provided file is not a valid certificate: $cert_file"
    fi
    log_debug "Certificate file validated: $cert_file"
}

# Function to fetch private key from HashiCorp Vault
fetch_private_key_from_vault() {
    local vault_path="$1"
    log_message "Fetching private key from HashiCorp Vault at path: $vault_path..."
    
    if ! command -v vault &> /dev/null; then
        handle_error "Vault CLI Not Installed" "Please install HashiCorp Vault CLI and authenticate."
    fi

    PRIVATE_KEY=$(vault kv get -field=private_key "$vault_path" 2>/dev/null)
    if [[ -z "$PRIVATE_KEY" ]]; then
        handle_error "Vault Fetch Failed" "Failed to fetch private key from Vault at path: $vault_path"
    fi

    log_message "Private key successfully fetched from Vault."
}

# Function to send a request to the blockchain API with retry logic
send_request_with_retry() {
    local method="$1"
    local url="$2"
    local data="$3"
    local retries=0
    while [[ $retries -lt $MAX_RETRIES ]]; do
        log_debug "Attempting API request (Attempt $((retries + 1))/$MAX_RETRIES): $method $url"
        RESPONSE=$(curl -s -X "$method" "$url" \
            -H "Content-Type: application/json" \
            -d "$data")
        log_api_response "$method $url" "$RESPONSE"
        STATUS=$(echo "$RESPONSE" | jq -r '.status' 2>/dev/null)
        if [[ "$STATUS" == "success" ]]; then
            log_debug "API request succeeded."
            return 0
        fi
        log_debug "API request failed. Retrying in $RETRY_DELAY seconds..."
        sleep "$RETRY_DELAY"
        retries=$((retries + 1))
    done
    handle_error "API Request Failed" "API request failed after $MAX_RETRIES attempts: $RESPONSE"
}

# ====================
# Step 1: Parse Input Arguments
# ====================
ACTION="$1"          # Action: "store" or "verify"
CERT_FILE="$2"       # Path to the certificate file

if [[ "$ACTION" == "--help" || "$ACTION" == "-h" ]]; then
    display_help
fi

if [[ "$ACTION" == "--config" ]]; then
    CONFIG_FILE="$2"
    if [[ -z "$CONFIG_FILE" || ! -f "$CONFIG_FILE" ]]; then
        handle_error "Invalid Configuration File" "Configuration file not found: $CONFIG_FILE"
    fi
    load_config
    exit 0
fi

if [[ -z "$ACTION" || -z "$CERT_FILE" ]]; then
    echo "Error: Missing required arguments."
    display_help
fi

if [[ "$ACTION" != "store" && "$ACTION" != "verify" ]]; then
    handle_error "Invalid Action" "Use 'store' or 'verify'."
fi

log_message "Starting $ACTION process for certificate: $CERT_FILE"

# ====================
# Step 2: Load Configuration
# ====================
load_config

# ====================
# Step 3: Validate Certificate File
# ====================
validate_cert_file "$CERT_FILE"

# ====================
# Step 4: Generate Certificate Hash
# ====================
log_message "Generating hash for certificate: $CERT_FILE..."
CERT_HASH=$(openssl x509 -in "$CERT_FILE" -noout -hash | sha256sum | awk '{print $1}')
if [[ -z "$CERT_HASH" ]]; then
    handle_error "Hash Generation Failed" "Failed to generate certificate hash."
fi
log_message "Generated Certificate Hash: $CERT_HASH"

# ====================
# Step 5: Perform Action (Store or Verify)
# ====================
if [[ "$ACTION" == "store" ]]; then
    # Fetch private key from Vault (optional step, e.g., for signing the hash)
    fetch_private_key_from_vault "$VAULT_PATH"

    log_message "Storing hash on blockchain..."
    DATA="{\"hash\": \"$CERT_HASH\"}"
    send_request_with_retry "POST" "$BLOCKCHAIN_API/store" "$DATA"
    log_message "Hash successfully stored on blockchain."
elif [[ "$ACTION" == "verify" ]]; then
    log_message "Verifying hash on blockchain..."
    DATA="{\"hash\": \"$CERT_HASH\"}"
    send_request_with_retry "POST" "$BLOCKCHAIN_API/verify" "$DATA"
    RESPONSE_STATUS=$(echo "$RESPONSE" | jq -r '.status' 2>/dev/null)
    if [[ "$RESPONSE_STATUS" == "success" ]]; then
        log_message "Hash verification succeeded."
    else
        handle_error "Hash Verification Failed" "The hash could not be verified on the blockchain."
    fi
fi

log_message "$ACTION process completed successfully."
