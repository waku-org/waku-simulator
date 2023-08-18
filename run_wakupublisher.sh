#!/bin/sh

IP=$(ip a | grep "inet " | grep -Fv 127.0.0.1 | sed 's/.*inet \([^/]*\).*/\1/')

echo "I am a traffic generator"

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
exec /main\
    --pubsub-topic="/waku/2/default-waku/proto"\
    --content-topic="my-ctopic"\
    --msg-per-second=${MSG_PER_SECOND}\
    --msg-size-kb=${MSG_SIZE_KBYTES}\
    --bootstrap-node=${BOOTSTRAP_ENR}\
    --max-peers=50\
    $@
