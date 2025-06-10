#!/bin/sh

# Check Linux Distro Version - it can differ depending on the nwaku image used
OS=$(cat /etc/os-release)
if echo $OS | grep -q "Debian"; then
    echo "The operating system is Debian."
    apt update
    apt install -y dnsutils
    apt install -y jq
elif echo $OS | grep -q "Alpine"; then
    echo "The operating system is Alpine."
    apk add bind-tools
    apk add jq
fi

if test -f .env; then
  echo "Using .env file"  
  . $(pwd)/.env
fi

IP=$(ip a | grep "inet " | grep -Fv 127.0.0.1 | sed 's/.*inet \([^/]*\).*/\1/')

echo "I am a nwaku edge node"

RETRIES=${RETRIES:=10}

echo "My IP is: ${IP}"

exec /usr/bin/wakunode\
      --relay=false\
      --lightpushnode=${SERVICENODE_MULTIADDRESS}\
      --filternode=${SERVICENODE_MULTIADDRESS}\
      --storenode=${SERVICENODE_MULTIADDRESS}\
      --max-connections=80\
      --rest=true\
      --rest-admin=true\
      --rest-address=0.0.0.0\
      --rest-port=8645\
      --rest-allow-origin="waku-org.github.iLightPushResponse.relayPeerCount.typeo"\
      --rest-allow-origin="localhost:*"\
      --log-level=INFO\
      --metrics-server=True\
      --metrics-server-address=0.0.0.0\
      --nat=extip:${IP}\
      --tcp-port:60002\
      --shard=0\
      --cluster-id=66\
      --nodekey=5358f02c157accb30a6c1d5920e778604de12e23d6009512be44f72f1a64d828
