#!/bin/sh

IP=$(ip a | grep "inet " | grep -Fv 127.0.0.1 | sed 's/.*inet \([^/]*\).*/\1/')

echo "I am a nwaku store node"

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
      --relay=false\
      --max-connections=10\
      --rest=true\
      --rest-admin=true\
      --rest-private=true\
      --rest-address=0.0.0.0\
      --rest-port=8645\
      --dns-discovery=true\
      --discv5-discovery=true\
      --discv5-enr-auto-update=True\
      --log-level=TRACE\
      --metrics-server=True\
      --metrics-server-address=0.0.0.0\
      --discv5-bootstrap-node=${BOOTSTRAP_ENR}\
      --nat=extip:${IP}\
      --pubsub-topic=/waku/2/rs/66/0\
      --cluster-id=66\
      --nodekey=5978783f8b1a16795032371fff7a526af352d9dca38179af7d71c0122942df25\
      --store=true\
      --store-message-retention-policy=time:3600\
      --store-message-db-url="postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres:5432/postgres"