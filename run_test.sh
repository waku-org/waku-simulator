#!/bin/sh

IP=$(ip a | grep "inet " | grep -Fv 127.0.0.1 | sed 's/.*inet \([^/]*\).*/\1/')

echo "I testdiscv5 node"

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
exec /usr/bin/discv5\
    --bootnodes=${BOOTSTRAP_ENR}
   #--bootnodes="enr:-M-4QLOTEs_ZFxCb09FgIezZd5KeTru5CWWyEtMWMN-yUABrerWxckU-pMIh3yO8VjxHpgZ4jU2WSXuK3goW4uYb6c4BgmlkgnY0gmlwhI_G-a6KbXVsdGlhZGRyc7EALzYobm9kZS0wMS5kby1hbXMzLnN0YXR1cy5wcm9kLnN0YXR1c2ltLm5ldAYBu94DiXNlY3AyNTZrMaECoVyonsTGEQvVioM562Q1fjzTb_vKD152PPIdsV7sM6SDdGNwgnZfg3VkcIIjKIV3YWt1MgM"\
