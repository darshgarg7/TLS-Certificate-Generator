#!/bin/bash

# ====================
# Script: Cleanup Generated Files
# Description: Cleans up generated certificate and key files from the specified directory.
# Usage: ./scripts/cleanup.sh [optional: DIRECTORY]
# ====================

handle_error() {
    echo "Error: $1"
    exit 1
}

# ====================
# Step 1: Parse Input Arguments
# ====================
CERTS_DIR="${1:-certs}"
# validate input
if [[ ! -d "$CERTS_DIR" ]]; then
    handle_error "Directory not found: $CERTS_DIR"
fi

echo "Cleaning up generated files in directory: $CERTS_DIR..."

# ====================
# Step 2: Define File Patterns to Clean Up
# ====================
FILE_PATTERNS=(
    "*.key"   # Private keys
    "*.crt"   # Certificates
    "*.csr"   # Certificate signing requests
    "*.pem"   # PEM files
    "*.srl"   # Serial files
)

# ====================
# Step 3: Perform Cleanup
# ====================
for PATTERN in "${FILE_PATTERNS[@]}"; do
    FILES_TO_DELETE=("$CERTS_DIR/$PATTERN")
    if [[ -n $(ls "${FILES_TO_DELETE[@]}" 2>/dev/null) ]]; then
        echo "Deleting files matching pattern: $PATTERN"
        rm -f "${FILES_TO_DELETE[@]}"
    else
        echo "No files found matching pattern: $PATTERN"
    fi
done

# ====================
# Step 4: Verify Cleanup
# ====================
echo "Verifying cleanup..."
REMAINING_FILES=$(find "$CERTS_DIR" -type f \( -name "*.key" -o -name "*.crt" -o -name "*.csr" -o -name "*.pem" -o -name "*.srl" \))
if [[ -z "$REMAINING_FILES" ]]; then
    echo "Cleanup completed successfully."
else
    echo "Some files were not deleted:"
    echo "$REMAINING_FILES"
fi
