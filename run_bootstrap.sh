#!/bin/sh

echo "I am a bootstrap node"

apt update
apt upgrade
apt -y install wget
apt -y install libpq-dev
apt -y install libpcre3

IP=$(ip a | grep "inet " | grep -Fv 127.0.0.1 | sed 's/.*inet \([^/]*\).*/\1/')
MY_EXT_IP=$(wget -qO- https://api4.ipify.org)

chmod a+x /usr/bin/wakunode

exec /usr/bin/wakunode\
      --relay=false\
      --rest=true\
      --rest-address=0.0.0.0\
      --max-connections=300\
      --dns-discovery=true\
      --discv5-discovery=true\
      --discv5-enr-auto-update=True\
      --log-level=DEBUG\
      --metrics-server=True\
      --metrics-server-address=0.0.0.0\
      --nodekey=30348dd51465150e04a5d9d932c72864c8967f806cce60b5d26afeca1e77eb68\
      --nat=extip:${MY_EXT_IP}\
      --cluster-id=66