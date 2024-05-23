#!/bin/bash

# Install bind-tools package used for domainname resolution
apk add bind-tools
apk add jq
apk add bash

if test -f .env; then
  echo "Using .env file"  
  . $(pwd)/.env
fi

# Function to extract IP address from URL, resolve the IP and replace it in the original URL
get_ip_address_and_replace() {
    local url=$1
    local domain_name=$(echo $RPC_URL | awk -F[/:] '{print $4}')
    local ip_address=$(dig +short $domain_name)
    valid_rpc_url="${url/$domain_name/$ip_address}" 
    echo $valid_rpc_url
}

# the format of the RPC URL is checked in the generateRlnKeystore command and hostnames are not valid
pattern="^(https?):\/\/((localhost)|([\w_-]+(?:(?:\.[\w_-]+)+)))(:[0-9]{1,5})?([\w.,@?^=%&:\/~+#-]*[\w@?^=%&\/~+#-])*"
# Perform regex matching
if [[ $RPC_URL =~ $pattern ]]; then
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

IP=$(ip a | grep "inet " | grep -Fv 127.0.0.1 | sed 's/.*inet \([^/]*\).*/\1/')
echo "IP: $IP"

# get the service name you specified in the docker-compose.yml 
# by a reverse DNS lookup on the IP
SERVICE=`dig -x $IP +short | cut -d'_' -f2`

# the number of replicas is equal to the A records 
# associated with the service name
COUNT=`dig $SERVICE +short | wc -l`

# extract the replica number from the same PTR entry
INDEX=`dig -x $IP +short | sed 's/.*_\([0-9]*\)\..*/\1/'`

# Hello
echo "Hello I'm container $INDEX of $COUNT"


###########################################################################
if test -f .$RLN_CREDENTIAL_PATH; then
  echo "$RLN_CREDENTIAL_PATH already exists. Use it instead of creating a new one."
else
  val=$(/bin/bash ./opt/parseAccountsDetails.sh $INDEX)
  echo $val

  echo "Generating RLN keystore"
  /usr/bin/wakunode generateRlnKeystore \
    --rln-relay-eth-client-address="$RPC_URL" \
    --rln-relay-eth-private-key=$val  \
    --rln-relay-eth-contract-address=$RLN_CONTRACT_ADDRESS \
    --rln-relay-cred-path=$RLN_CREDENTIAL_PATH \
    --rln-relay-cred-password=$RLN_CREDENTIAL_PASSWORD \
    --log-level=INFO \
    --execute
fi

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
      --rln-relay=true\
      --rln-relay-dynamic=true\
      --rln-relay-eth-client-address="$RPC_URL"\
      --rln-relay-eth-contract-address=$RLN_CONTRACT_ADDRESS\
      --rln-relay-cred-path=$RLN_CREDENTIAL_PATH\
      --rln-relay-cred-password=$RLN_CREDENTIAL_PASSWORD\
      --dns-discovery=true\
      --discv5-discovery=true\
      --discv5-enr-auto-update=True\
      --log-level=DEBUG\
      --metrics-server=True\
      --metrics-server-address=0.0.0.0\
      --discv5-bootstrap-node=${BOOTSTRAP_ENR}\
      --nat=extip:${IP}\
      --pubsub-topic=/waku/2/rs/66/0\
      --cluster-id=66