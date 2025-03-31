#!/bin/bash

VAULT_ADDR="${VAULT_ADDR:-http://127.0.0.1:8200}"  # Default Vault server address
VAULT_TOKEN="${VAULT_TOKEN:-myroot}"               # Default Vault token (override with env var)
LOG_FILE="logs/vault_integration.log"             # Log file location
MAX_RETRIES=3                                      # Maximum retries for API calls
RETRY_DELAY=2                                      # Delay between retries (seconds)

mkdir -p logs

# Function to handle errors
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

# Function to log debug messages
log_debug() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] DEBUG: $1" | tee -a "$LOG_FILE"
}

# Function to display help menu
display_help() {
    echo "Usage:"
    echo "  Store a secret: ./scripts/vault_integration.sh store <key_name> <file_path>"
    echo "  Retrieve a secret: ./scripts/vault_integration.sh retrieve <key_name> <output_file>"
    echo "  Help: ./scripts/vault_integration.sh --help"
    echo ""
    echo "Options:"
    echo "  --help      Display this help menu."
    echo ""
    echo "Environment Variables:"
    echo "  VAULT_ADDR     Override the default Vault server address (default: http://127.0.0.1:8200)."
    echo "  VAULT_TOKEN    Override the default Vault token."
    echo ""
    echo "Logs are stored in $LOG_FILE for debugging purposes."
    exit 0
}

# Function to validate file paths
validate_file() {
    local file_path="$1"
    if [[ ! -f "$file_path" ]]; then
        handle_error "File Not Found" "File not found: $file_path"
    fi
    log_debug "File validated: $file_path"
}

# Function to send a request to Vault with retry logic
send_vault_request_with_retry() {
    local method="$1"
    local url="$2"
    local data="$3"
    local retries=0
    while [[ $retries -lt $MAX_RETRIES ]]; do
        log_debug "Attempting Vault request (Attempt $((retries + 1))/$MAX_RETRIES): $method $url"
        RESPONSE=$(curl -s -X "$method" "$url" \
            -H "X-Vault-Token: $VAULT_TOKEN" \
            -H "Content-Type: application/json" \
            -d "$data")
        STATUS=$(echo "$RESPONSE" | jq -r '.errors' 2>/dev/null)
        if [[ -z "$STATUS" || "$STATUS" == "null" ]]; then
            log_debug "Vault request succeeded."
            return 0
        fi
        log_debug "Vault request failed. Retrying in $RETRY_DELAY seconds..."
        sleep "$RETRY_DELAY"
        retries=$((retries + 1))
    done
    handle_error "Vault Request Failed" "Vault request failed after $MAX_RETRIES attempts: $RESPONSE"
}

# ================================
# Step 1: Parse Input Arguments
# ================================
ACTION="$1"          # Action: "store" or "retrieve"
KEY_NAME="$2"        # Key name in Vault
FILE_PATH="$3"       # File path for storing/retrieving secrets
if [[ "$ACTION" == "--help" || "$ACTION" == "-h" ]]; then
    display_help
fi
if [[ -z "$ACTION" || -z "$KEY_NAME" || -z "$FILE_PATH" ]]; then
    echo "Error: Missing required arguments."
    display_help
fi
if [[ "$ACTION" != "store" && "$ACTION" != "retrieve" ]]; then
    handle_error "Invalid Action" "Use 'store' or 'retrieve'."
fi
log_message "Starting $ACTION process for key: $KEY_NAME"

# ================================
# Step 2: Validate Inputs
# ================================
if [[ "$ACTION" == "store" ]]; then
    validate_file "$FILE_PATH"
fi

# ================================
# Step 3: Perform Action (Store or Retrieve)
# ================================
if [[ "$ACTION" == "store" ]]; then
    log_message "Storing secret in Vault for key: $KEY_NAME..."
    DATA="{\"data\": {\"value\": \"$(cat "$FILE_PATH")\"}}"
    send_vault_request_with_retry "POST" "$VAULT_ADDR/v1/secret/data/$KEY_NAME" "$DATA"
    log_message "Secret successfully stored in Vault for key: $KEY_NAME"
elif [[ "$ACTION" == "retrieve" ]]; then
    log_message "Retrieving secret from Vault for key: $KEY_NAME..."
    RESPONSE=$(curl -s -X GET "$VAULT_ADDR/v1/secret/data/$KEY_NAME" \
        -H "X-Vault-Token: $VAULT_TOKEN")
    SECRET_VALUE=$(echo "$RESPONSE" | jq -r '.data.data.value' 2>/dev/null)
    if [[ -z "$SECRET_VALUE" || "$SECRET_VALUE" == "null" ]]; then
        handle_error "Secret Retrieval Failed" "Failed to retrieve secret for key: $KEY_NAME"
    fi
    echo "$SECRET_VALUE" > "$FILE_PATH"
    log_message "Secret successfully retrieved and saved to: $FILE_PATH"
fi

log_message "Vault integration completed successfully."
