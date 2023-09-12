#!/bin/sh

IP=$(ip a | grep "inet " | grep -Fv 127.0.0.1 | sed 's/.*inet \([^/]*\).*/\1/')

echo "I am a nwaku node"
echo "I am replica $REPLICA"

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

echo "Bootstrap node: ${BOOTSTRAP_ENR}"
echo "Using bootstrap node: ${BOOTSTRAP_ENR}"
exec /usr/bin/wakunode\
      --relay=true\
      --rpc-admin=true\
      --rpc-address=0.0.0.0\
      --rest=true \
      --rest-admin=true \
      --rest-private=true \
      --rest-address=0.0.0.0 \
      --max-connections=100\
      --dns-discovery=true\
      --discv5-discovery=true\
      --discv5-enr-auto-update=True\
      --log-level=DEBUG\
      --metrics-server=True\
      --metrics-server-address=0.0.0.0\
      --discv5-bootstrap-node=${BOOTSTRAP_ENR}\
      --nat=extip:${IP} \
      --rln-relay=true \
      --rln-relay-dynamic=true \
      --rln-relay-cred-password=password \
      --rln-relay-cred-path=/rlnKeystore_$REPLICA.json \
      --rln-relay-tree-path=/data/rln_tree_$REPLICA.db \
      --rln-relay-eth-contract-address=0x0A988fd9CA5BAebDf098b8A73621b2AaDa6492E8  \
      --rln-relay-eth-client-address=ws://linux-01.ih-eu-mda1.nimbus.sepolia.wg:9558
