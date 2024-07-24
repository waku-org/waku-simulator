#!/bin/bash

# Function to print the usage of the script
usage() {
    echo "Usage: $0 --delay-seconds <int> --msg-size-kbytes <int> --pubsub-topic <string> --nodes <range>"
    exit 1
}

# Default values
DEFAULT_MSG_SIZE=10
DEFAULT_PUBSUB_TOPIC="/waku/2/rs/66/0"

# Initialize variables
DELAY_SECONDS=""
MSG_SIZE_KBYTES=$DEFAULT_MSG_SIZE
PUBSUB_TOPIC=$DEFAULT_PUBSUB_TOPIC
NODES=""

# Parse named parameters
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --delay-seconds)
            DELAY_SECONDS="$2"
            shift 2
            ;;
        --msg-size-kbytes)
            MSG_SIZE_KBYTES="$2"
            shift 2
            ;;
        --pubsub-topic)
            PUBSUB_TOPIC="$2"
            shift 2
            ;;
        --nodes)
            NODES="$2"
            shift 2
            ;;
        *)
            echo "Unknown parameter passed: $1"
            usage
            ;;
    esac
done

# Validate required parameters
if [[ -z "$DELAY_SECONDS" || -z "$NODES" ]]; then
    echo "Error: --delay-seconds and --nodes are required."
    usage
fi

# Validate delay-seconds is an integer
if ! [[ "$DELAY_SECONDS" =~ ^[0-9]+$ ]]; then
    echo "Error: --delay-seconds must be an integer."
    exit 1
fi

# Validate msg-size-kbytes is an integer
if ! [[ "$MSG_SIZE_KBYTES" =~ ^[0-9]+$ ]]; then
    echo "Error: --msg-size-kbytes must be an integer."
    exit 1
fi

# Validate nodes format
if ! [[ "$NODES" =~ ^[0-9]+\.\.[0-9]+$ ]]; then
    echo "Error: --nodes must be a range of integers."
    exit 1
fi

# Check if default values are used and warn
if [[ "$MSG_SIZE_KBYTES" -eq $DEFAULT_MSG_SIZE ]]; then
    echo "Warning: Using default value for --msg-size-kbytes: $DEFAULT_MSG_SIZE"
fi

if [[ "$PUBSUB_TOPIC" == "$DEFAULT_PUBSUB_TOPIC" ]]; then
    echo "Warning: Using default value for --pubsub-topic: $DEFAULT_PUBSUB_TOPIC"
fi

# Output the parameters as a summary
echo "====================================="
echo "         Summary of Parameters       "
echo "====================================="
echo "- Delay:           ${DELAY_SECONDS}s"
echo "- Msg Size:        ${MSG_SIZE_KBYTES}KB"
echo "- Pubsub Topic:    ${PUBSUB_TOPIC}"
echo "- Nodes:           ${NODES}"
echo "====================================="

# Run the command
docker run -it --network waku-simulator_simulation alrevuelta/rest-traffic:d936446 \
--delay-seconds=$DELAY_SECONDS \
--msg-size-kbytes=$MSG_SIZE_KBYTES \
--pubsub-topic=$PUBSUB_TOPIC \
--multiple-nodes="http://waku-simulator_nwaku_[$NODES]:8645"

