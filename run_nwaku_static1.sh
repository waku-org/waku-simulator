#!/bin/sh

# Check Linux Distro Version - it can differ depending on the nwaku image used
# Install bind-tools/dnsutils package used for domain name resolution
OS=$(cat /etc/os-release)
if echo $OS | grep -q "Debian"; then
    echo "The operating system is Debian."
    apt update
    apt install -y dnsutils
elif echo $OS | grep -q "Alpine"; then
    echo "The operating system is Alpine."
    apk add bind-tools
fi

if test -f .env; then
  echo "Using .env file"  
  . $(pwd)/.env
fi

# Function to extract IP address from URL, resolve the IP and replace it in the original URL
get_ip_address_and_replace() {
    local url=$1
    local domain_name=$(echo $RPC_URL | awk -F[/:] '{print $4}')
    local ip_address=$(dig +short $domain_name)
    valid_rpc_url="$(echo "$url" | sed "s/$domain_name/$ip_address/g")"
    echo $valid_rpc_url
}

# the format of the RPC URL is checked in the generateRlnKeystore command and hostnames are not valid
pattern="^(https?):\/\/((localhost)|([\w_-]+(?:(?:\.[\w_-]+)+)))(:[0-9]{1,5})?([\w.,@?^=%&:\/~+#-]*[\w@?^=%&\/~+#-])*"
# Perform regex matching
if echo "$RPC_URL" | grep -q "$pattern"; then
    echo "RPC URL is valid"
else
    echo "RPC URL is invalid: $RPC_URL. Attempting to resolve hostname."
    resolved_rpc_url="$(get_ip_address_and_replace $RPC_URL)"
    if [ -z "$resolved_rpc_url" ]; then
        echo -e "Failed to retrieve IP address for $RPC_URL\n"
    else
        echo -e "Resolved RPC URL for $RPC_URL: $resolved_rpc_url"
        RPC_URL="$resolved_rpc_url"
    fi
fi

if test -f .$RLN_CREDENTIAL_PATH; then
  echo "$RLN_CREDENTIAL_PATH already exists. Use it instead of creating a new one."
else
  echo "Generating RLN keystore..."
  /usr/bin/wakunode generateRlnKeystore \
    --rln-relay-eth-client-address="$RPC_URL" \
    --rln-relay-eth-private-key=$PRIVATE_KEY  \
    --rln-relay-eth-contract-address=$RLN_CONTRACT_ADDRESS \
    --rln-relay-cred-path=$RLN_CREDENTIAL_PATH \
    --rln-relay-cred-password=$RLN_CREDENTIAL_PASSWORD \
    --rln-relay-user-message-limit=$RLN_RELAY_MSG_LIMIT \
    --log-level=DEBUG \
    --execute
fi

IP=$(ip a | grep "inet " | grep -Fv 127.0.0.1 | sed 's/.*inet \([^/]*\).*/\1/')

echo "I am a nwaku node"

# Get an unique node index based on the container's IP
FOURTH_OCTET=${IP##*.}
THIRD_OCTET="${IP%.*}"; THIRD_OCTET="${THIRD_OCTET##*.}"
NODE_INDEX=$((FOURTH_OCTET + 256 * THIRD_OCTET))

echo "NODE_INDEX $NODE_INDEX"

RETRIES=${RETRIES:=10}

while [ -z "${BOOTSTRAP_ENR}" ] && [ ${RETRIES} -ge 0 ]; do
  BOOTSTRAP_ENR=$(wget -qO- http://bootstrap:8645/debug/v1/info --header='Content-Type:application/json' 2> /dev/null | sed 's/.*"enrUri":"\([^"]*\)".*/\1/');
  echo "Bootstrap node not ready, retrying (retries left: ${RETRIES})"
  sleep 1
  RETRIES=$(( $RETRIES - 1 ))
done

if [ -z "${BOOTSTRAP_ENR}" ]; then
   echo "Could not get BOOTSTRAP_ENR and none provided. Failing"
   exit 1
fi

echo "Using bootstrap node: ${BOOTSTRAP_ENR}"
exec /usr/bin/wakunode\
      --relay=true\
      --max-connections=250\
      --rest=true\
      --rest-admin=true\
      --rest-private=true\
      --rest-address=0.0.0.0\
      --cluster-id=0\
      --pubsub-topic=/waku/2/default-waku/proto\
      --rest-port=8645\
      --rln-relay=true\
      --rln-relay-dynamic=true\
      --rln-relay-eth-client-address="$RPC_URL"\
      --rln-relay-eth-contract-address=$RLN_CONTRACT_ADDRESS\
      --rln-relay-cred-path=$RLN_CREDENTIAL_PATH\
      --rln-relay-cred-password=$RLN_CREDENTIAL_PASSWORD\
      --rln-relay-tree-path="rlnv2_tree1"\
      --rln-relay-epoch-sec=$RLN_RELAY_EPOCH_SEC\
      --rln-relay-user-message-limit=$RLN_RELAY_MSG_LIMIT\
      --dns-discovery=true\
      --discv5-discovery=true\
      --discv5-enr-auto-update=True\
      --log-level=DEBUG\
      --metrics-server=True\
      --metrics-server-address=0.0.0.0\
      --discv5-bootstrap-node=${BOOTSTRAP_ENR}\
      --nat=extip:${IP}\
      --nodekey=5978783f8b1a16795032371fff7a526af352d9dca38179af7d71c0122942df25