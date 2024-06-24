#!/bin/bash

# Function to print the usage of the script
usage() {
    echo "Usage: $0 --static-node <> --delay-milliseconds <>"
    exit 1
}

# Default values
DEFAULT_DELAY_MILLISECONDS=200

# Initialize variables
DELAY_MILLISECONDS=$DEFAULT_DELAY_MILLISECONDS
STATIC_NODE=""

# Parse named parameters
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --delay-milliseconds)
            DELAY_MILLISECONDS="$2"
            shift 2
            ;;
        --static-node)
            STATIC_NODE="$2"
            shift 2
            ;;
        *)
            echo "Unknown parameter passed: $1"
            usage
            ;;
    esac
done

# Validate required parameters
if [[ -z "$STATIC_NODE" ]]; then
    echo "Error: --static-node is required."
    usage
fi

# Validate delay-seconds is an integer
if ! [[ "$DELAY_MILLISECONDS" =~ ^[0-9]+$ ]]; then
    echo "Error: --delay-milliseconds must be an integer."
    exit 1
fi

# Check if default values are used and warn
if [[ "$DELAY_MILLISECONDS" -eq $DEFAULT_DELAY_MILLISECONDS ]]; then
    echo "Warning: Using default value for --delay-milliseconds: $DEFAULT_DELAY_MILLISECONDS"
fi

# Output the parameters as a summary
echo "====================================="
echo "         Summary of Parameters       "
echo "====================================="
echo "- Delay:           ${DELAY_MILLISECONDS}ms"
echo "- Static Node:     ${STATIC_NODE}"
echo "====================================="

# Run the command
docker run -it --network waku-simulator_simulation quay.io/wakuorg/nwaku-pr:2821 \
      --relay=true \
      --rln-relay=true \
      --rln-relay-dynamic=true \
      --rln-relay-eth-client-address=http://foundry:8545 \
      --rln-relay-eth-contract-address=0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9 \
      --rln-relay-epoch-sec=1 \
      --rln-relay-user-message-limit=1 \
      --log-level=DEBUG \
      --staticnode=${STATIC_NODE} \
      --pubsub-topic=/waku/2/rs/66/0 \
      --cluster-id=66 \
      --rln-relay-eth-private-key=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
      --rln-relay-cred-path=/keystore.json \
      --rln-relay-cred-password=password123 \
      --spammer=true \
      --spammer-delay-between-msg=${DELAY_MILLISECONDS}

