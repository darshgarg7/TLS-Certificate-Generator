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

# Define constants
CONFIG_FILE="config/blockchain_config.json"                                # Path to configuration file
LOG_DIR="logs"                                                             # Default log directory
LOG_FILE="$LOG_DIR/tlsblockchain.log"                                      # Log file location
BLOCKCHAIN_API="${BLOCKCHAIN_API:-https://api.blockchainhash.example/v1}"  # Default API endpoint
MAX_RETRIES=3                                                              # Maximum retries for API calls
RETRY_DELAY=2                                                              # Delay between retries (seconds)

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Function to handle errors
handle_error() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1" | tee -a "$LOG_FILE"
    exit 1
}

# Function to log messages
log_message() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1" | tee -a "$LOG_FILE"
}

# Function to log debug messages
log_debug() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] DEBUG: $1" | tee -a "$LOG_FILE"
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
        handle_error "Certificate file not found: $cert_file"
    fi
    if ! openssl x509 -in "$cert_file" -noout >/dev/null 2>&1; then
        handle_error "Invalid certificate file: $cert_file"
    fi
    log_debug "Certificate file validated: $cert_file"
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
        STATUS=$(echo "$RESPONSE" | jq -r '.status' 2>/dev/null)
        if [[ "$STATUS" == "success" ]]; then
            log_debug "API request succeeded."
            return 0
        fi
        log_debug "API request failed. Retrying in $RETRY_DELAY seconds..."
        sleep "$RETRY_DELAY"
        retries=$((retries + 1))
    done
    handle_error "API request failed after $MAX_RETRIES attempts: $RESPONSE"
}

# ====================
# Step 1: Parse Input Arguments
# ====================

ACTION="$1"          # Action: "store" or "verify"
CERT_FILE="$2"       # Path to the certificate file

# Handle help menu
if [[ "$ACTION" == "--help" || "$ACTION" == "-h" ]]; then
    display_help
fi

# Handle custom configuration file
if [[ "$ACTION" == "--config" ]]; then
    CONFIG_FILE="$2"
    if [[ -z "$CONFIG_FILE" || ! -f "$CONFIG_FILE" ]]; then
        handle_error "Invalid configuration file: $CONFIG_FILE"
    fi
    load_config
    exit 0
fi

# Validate input arguments
if [[ -z "$ACTION" || -z "$CERT_FILE" ]]; then
    echo "Error: Missing required arguments."
    display_help
fi

if [[ "$ACTION" != "store" && "$ACTION" != "verify" ]]; then
    handle_error "Invalid action. Use 'store' or 'verify'."
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
    handle_error "Failed to generate certificate hash."
fi
log_message "Generated Certificate Hash: $CERT_HASH"

# ====================
# Step 5: Perform Action (Store or Verify)
# ====================
if [[ "$ACTION" == "store" ]]; then
    log_message "Storing hash on blockchain..."
    DATA="{\"hash\": \"$CERT_HASH\"}"
    send_request_with_retry "POST" "$BLOCKCHAIN_API/store" "$DATA"
    log_message "Hash successfully stored on blockchain."

elif [[ "$ACTION" == "verify" ]]; then
    log_message "Verifying hash on blockchain..."
    URL="$BLOCKCHAIN_API/hash/$CERT_HASH"
    STORED_HASH=$(curl -s "$URL" | jq -r '.hash')
    if [[ "$STORED_HASH" != "$CERT_HASH" ]]; then
        handle_error "Hash verification failed. Certificate has been tampered with."
    fi
    log_message "Hash verification successful. Certificate is valid."
fi

log_message "$ACTION process completed successfully."
