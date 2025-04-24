#!/bin/sh

IP=$(ip a | grep "inet " | grep -Fv 127.0.0.1 | sed 's/.*inet \([^/]*\).*/\1/')

echo "I am a bootstrap node"

exec /usr/bin/wakunode\
      --relay=false\
      --rest=true\
      --rest-admin=true\
      --rest-address=0.0.0.0\
      --rest-port=8645\
      --rest-allow-origin="waku-org.github.io"\
      --rest-allow-origin="localhost:*"\
      --max-connections=300\
      --dns-discovery=true\
      --discv5-discovery=true\
      --discv5-enr-auto-update=True\
      --log-level=DEBUG\
      --metrics-server=True\
      --metrics-server-address=0.0.0.0\
      --nodekey=30348dd51465150e04a5d9d932c72864c8967f806cce60b5d26afeca1e77eb68\
      --nat=extip:${IP}\
      --shard=0\
      --cluster-id=66