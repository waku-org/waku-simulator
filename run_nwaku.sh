#!/bin/sh

IP=$(ip a | grep "inet " | grep -Fv 127.0.0.1 | sed 's/.*inet \([^/]*\).*/\1/')

echo "I am a nwaku node"

# Get an unique node index based on the container's IP
FOURTH_OCTET=${IP##*.}
THIRD_OCTET="${IP%.*}"; THIRD_OCTET="${THIRD_OCTET##*.}"
NODE_INDEX=$((FOURTH_OCTET + 256 * THIRD_OCTET))

echo "NODE_INDEX $NODE_INDEX"

RETRIES=${RETRIES:=10}

while [ -z "${BOOTSTRAP_ENR}" ] && [ ${RETRIES} -ge 0 ]; do
  BOOTSTRAP_ENR=$(wget -O - --post-data='{"jsonrpc":"2.0","method":"get_waku_v2_debug_v1_info","params":[],"id":1}' --header='Content-Type:application/json' http://bootstrap:8545/ 2> /dev/null | sed 's/.*"enrUri":"\([^"]*\)".*/\1/');
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
      --rpc-admin=true\
      --max-connections=250\
      --rpc-address=0.0.0.0\
      --rest=true\
      --rest-admin=true\
      --rest-private=true\
      --rest-address=0.0.0.0\
      --rln-relay=true\
      --rln-relay-dynamic=true\
      --rln-relay-eth-client-address=http://10.1.0.4:8545\
      --rln-relay-eth-contract-address=0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0\
      --dns-discovery=true\
      --discv5-discovery=true\
      --discv5-enr-auto-update=True\
      --log-level=DEBUG\
      --rpc-address=0.0.0.0\
      --metrics-server=True\
      --metrics-server-address=0.0.0.0\
      --discv5-bootstrap-node=${BOOTSTRAP_ENR}\
      --nat=extip:${IP}
