#!/bin/sh
# Helper script to get the index of the container and use it to retrieve a unique account private key.
# Each node uses a unique Ethereum account to register with the RLN contract.
# The account and private key pairs are stored in anvil-config.txt on a shared volume at anvil startup in the foundry service

set -e

ANVIL_CONFIG_PATH=${ANVIL_CONFIG_PATH:-/shared/anvil-config.txt}

# Get container IP and determine index (same method as run_nwaku.sh)
IP=$(ip a | grep "inet " | grep -Fv 127.0.0.1 | sed 's/.*inet \([^/]*\).*/\1/')
echo "Container IP: $IP"

# Extract container name from reverse DNS lookup and get index
CNTR=$(dig -x $IP +short | cut -d'.' -f1)
INDEX=$(echo $CNTR | sed 's/.*[-_]\([0-9]*\)/\1/')

if [ $? -ne 0 ] || [ -z "$INDEX" ]; then
    echo "Error: Failed to determine the replica index from IP." >&2
    exit 1
fi

echo "Determined container index: $INDEX"

# Read anvil config
json_content=$(cat "$ANVIL_CONFIG_PATH")
if [ -z "$json_content" ]; then
    echo "Error: Failed to read the JSON file or the file is empty." >&2
    exit 1
fi

# Get private key and address for this index 
ARRAY_INDEX=$((INDEX - 1))

ACCOUNT_PRIVATE_KEY=$(echo "$json_content" | jq -r ".private_keys[$ARRAY_INDEX]")
ACCOUNT_ADDRESS=$(echo "$json_content" | jq -r ".available_accounts[$ARRAY_INDEX]")

if [ "$ACCOUNT_PRIVATE_KEY" = "null" ] || [ "$ACCOUNT_ADDRESS" = "null" ]; then
    echo "Failed to get account private key or address for index $INDEX (array index $ARRAY_INDEX)" >&2
    exit 1
fi

# Export for the Python script
export NODE_PRIVATE_KEY="$ACCOUNT_PRIVATE_KEY"
export NODE_ADDRESS="$ACCOUNT_ADDRESS"  
export NODE_INDEX="$INDEX"

echo "Node $INDEX using Ethereum account: $ACCOUNT_ADDRESS"

# Run the Python initialization script
exec python3 /app/init_node_tokens.py