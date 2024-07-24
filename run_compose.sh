#!/bin/bash

# Function to print the usage of the script
usage() {
    echo "Usage: $0 --nwaku-image <string> --num-nwaku-nodes <int> --traffic-delay-seconds <int> --message-size-kbytes <int> --private-key <string> --eth-from <string> --rln-relay-epoch-seconds <int> --rln-relay-messages-limit <int>"
    exit 1
}

# Default values
DEFAULT_NWAKU_IMAGE="harbor.status.im/wakuorg/nwaku:v0.30.0-rc.0"
DEFAULT_NUM_NWAKU_NODES=5
DEFAULT_TRAFFIC_NUM_NWAKU_NODES=$DEFAULT_NUM_NWAKU_NODES
DEFAULT_SPAM_NUM_NWAKU_NODES=0
DEFAULT_TRAFFIC_DELAY_SECONDS=60
DEFAULT_MSG_SIZE_KBYTES=10
DEFAULT_PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
DEFAULT_ETH_FROM="0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266"
DEFAULT_RLN_RELAY_EPOCH_SEC=60
DEFAULT_RLN_RELAY_MSG_LIMIT=1

# Initialize variables
NWAKU_IMAGE=$DEFAULT_NWAKU_IMAGE
NUM_NWAKU_NODES=$DEFAULT_NUM_NWAKU_NODES
SPAM_NUM_NWAKU_NODES=$DEFAULT_SPAM_NUM_NWAKU_NODES
TRAFFIC_NUM_NWAKU_NODES=$DEFAULT_TRAFFIC_NUM_NWAKU_NODES
TRAFFIC_DELAY_SECONDS=$DEFAULT_TRAFFIC_DELAY_SECONDS
MSG_SIZE_KBYTES=$DEFAULT_MSG_SIZE_KBYTES
PRIVATE_KEY=$DEFAULT_PRIVATE_KEY
ETH_FROM=$DEFAULT_ETH_FROM
RLN_RELAY_EPOCH_SEC=$DEFAULT_RLN_RELAY_EPOCH_SEC
RLN_RELAY_MSG_LIMIT=$DEFAULT_RLN_RELAY_MSG_LIMIT

# Parse named parameters
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --nwaku-image)
            NWAKU_IMAGE="$2"
            shift 2
            ;;
        --num-nwaku-nodes)
            NUM_NWAKU_NODES="$2"
            shift 2
            ;;
        --traffic-num-nwaku-nodes)
            TRAFFIC_NUM_NWAKU_NODES="$2"
            shift 2
            ;;
        --spam-num-nwaku-nodes)
            SPAM_NUM_NWAKU_NODES="$2"
            shift 2
            ;;
        --traffic-delay-seconds)
            TRAFFIC_DELAY_SECONDS="$2"
            shift 2
            ;;
        --message-size-kbytes)
            MSG_SIZE_KBYTES="$2"
            shift 2
            ;;
        --private-key)
            PRIVATE_KEY="$2"
            shift 2
            ;;
        --eth-from)
            ETH_FROM="$2"
            shift 2
            ;;
        --rln-relay-epoch-seconds)
            RLN_RELAY_EPOCH_SEC="$2"
            shift 2
            ;;
        --rln-relay-messages-limit)
            RLN_RELAY_MSG_LIMIT="$2"
            shift 2
            ;;
        *)
            echo "Unknown parameter passed: $1"
            usage
            ;;
    esac
done

# Validate num-nwaku-nodes is an integer
if ! [[ "$NUM_NWAKU_NODES" =~ ^[0-9]+$ ]]; then
    echo "Error: --num-nwaku-nodes must be an integer."
    exit 1
fi

# Validate traffic-num-nwaku-nodes is an integer
if ! [[ "$TRAFFIC_NUM_NWAKU_NODES" =~ ^[0-9]+$ ]]; then
    echo "Error: --num-nwaku-nodes must be an integer."
    exit 1
fi

# Validate traffic-num-nwaku-nodes is less or equal than num-nwaku-nodes
if ! [[ "$TRAFFIC_NUM_NWAKU_NODES" -le "$NUM_NWAKU_NODES" ]]; then
    echo "Error: --traffic-num-nwaku-nodes must be less or equal than --num-nwaku-nodes."
    exit 1
fi

# Validate spam-num-nwaku-nodes is an integer
if ! [[ "$SPAM_NUM_NWAKU_NODES" =~ ^[0-9]+$ ]]; then
    echo "Error: --spam-num-nwaku-nodes must be an integer."
    exit 1
fi

# Validate spam-num-nwaku-nodoes is less or equal than num-nwaku-nodes
if ! [[ "$SPAM_NUM_NWAKU_NODES" -le "$NUM_NWAKU_NODES" ]]; then
    echo "Error: --spam-num-nwaku-nodes must be less or equal than --num-nwaku-nodes."
    exit 1
fi

# Validate traffic-delay-seconds is an integer
if ! [[ "$TRAFFIC_DELAY_SECONDS" =~ ^[0-9]+$ ]]; then
    echo "Error: --traffic-delay-seconds must be an integer."
    exit 1
fi

# Validate msg-size-kbytes
if ! [[ "$MSG_SIZE_KBYTES" =~ ^[0-9]+$ ]]; then
    echo "Error: --msg-size-kbytes must be an integer."
    exit 1
fi

# Validate rln-relay-epoch-seconds
if ! [[ "$RLN_RELAY_EPOCH_SEC" =~ ^[0-9]+$ ]]; then
    echo "Error: --rln-relay-epoch-seconds must be an integer."
    exit 1
fi

# Validate rln-relay-messages-limit
if ! [[ "$RLN_RELAY_MSG_LIMIT" =~ ^[0-9]+$ ]]; then
    echo "Error: --rln-relay-messages-limit must be an integer."
    exit 1
fi

# Check if default values are used and warn
if [[ "$NWAKU_IMAGE" == "$DEFAULT_NWAKU_IMAGE" ]]; then
    echo "Warning: Using default value for --nwaku-image: $DEFAULT_NWAKU_IMAGE"
fi

if [[ "$NUM_NWAKU_NODES" -eq "$DEFAULT_NUM_NWAKU_NODES" ]]; then
    echo "Warning: Using default value for --num-nwaku-nodes: $DEFAULT_NUM_NWAKU_NODES"
fi

if [[ "$TRAFFIC_NUM_NWAKU_NODES" -eq "$DEFAULT_TRAFFIC_NUM_NWAKU_NODES" ]]; then
    echo "Warning: Using default value for --num-nwaku-nodes: $DEFAULT_TRAFFIC_NUM_NWAKU_NODES"
fi

if [[ "$SPAM_NUM_NWAKU_NODES" -eq "$DEFAULT_SPAM_NUM_NWAKU_NODES" ]]; then
    echo "Warning: Using default value for --spam-num-nwaku-nodes: $DEFAULT_SPAM_NUM_NWAKU_NODES"
fi

if [[ "$TRAFFIC_DELAY_SECONDS" -eq "$DEFAULT_TRAFFIC_DELAY_SECONDS" ]]; then
    echo "Warning: Using default value for --traffic-delay-seconds: $DEFAULT_TRAFFIC_DELAY_SECONDS"
fi

if [[ "$MSG_SIZE_KBYTES" -eq "$DEFAULT_MSG_SIZE_KBYTES" ]]; then
    echo "Warning: Using default value for --message-size-kbytes: $DEFAULT_MSG_SIZE_KBYTES"
fi

if [[ "$PRIVATE_KEY" == "$DEFAULT_PRIVATE_KEY" ]]; then
    echo "Warning: Using default value for --private-key: $DEFAULT_PRIVATE_KEY"
fi

if [[ "$ETH_FROM" == "$DEFAULT_ETH_FROM" ]]; then
    echo "Warning: Using default value for --eth-from: $DEFAULT_ETH_FROM"
fi

if [[ "$RLN_RELAY_EPOCH_SEC" -eq "$DEFAULT_RLN_RELAY_EPOCH_SEC" ]]; then
    echo "Warning: Using default value for --rln-relay-epoch-seconds: $DEFAULT_RLN_RELAY_EPOCH_SEC"
fi

if [[ "$RLN_RELAY_MSG_LIMIT" -eq "$DEFAULT_RLN_RELAY_MSG_LIMIT" ]]; then
    echo "Warning: Using default value for --rln-relay-messages-limit: $DEFAULT_RLN_RELAY_MSG_LIMIT"
fi

# Output the parameters as a summary
echo ""
echo "================================================================================================="
echo "                                       Summary of Parameters                                     "
echo "================================================================================================="
echo "- Nwaku Image:                 ${NWAKU_IMAGE}"
echo "- Nodes"
echo "  | Total:                     ${NUM_NWAKU_NODES}"
echo "  | Traffic Injection:         ${TRAFFIC_NUM_NWAKU_NODES}"
echo "  | Spam Injection:            ${SPAM_NUM_NWAKU_NODES}"
echo "- Message Publishing Delay:    ${TRAFFIC_DELAY_SECONDS}s"
echo "- Message Size:                ${MSG_SIZE_KBYTES}KB"
echo "- Private Key:                 ${PRIVATE_KEY}"
echo "- ETH From:                    ${ETH_FROM}"
echo "- RLN Relay Epoch:             ${RLN_RELAY_EPOCH_SEC}s"
echo "- RLN Relay Messages Limit:    ${RLN_RELAY_MSG_LIMIT}"
echo "================================================================================================="
echo ""

# Confirm Parameters
read -n 1 -s -r -p "Press any key to launch docker compose with the specified parameters"
echo ""

# Export parameters and run compose
export NWAKU_IMAGE
export NUM_NWAKU_NODES
export TRAFFIC_NUM_NWAKU_NODES
export SPAM_NUM_NWAKU_NODES
export TRAFFIC_DELAY_SECONDS
export MSG_SIZE_KBYTES
export PRIVATE_KEY
export ETH_FROM
export RLN_RELAY_EPOCH_SEC
export RLN_RELAY_MSG_LIMIT

docker compose --compatibility up

