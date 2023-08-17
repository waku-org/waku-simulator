#!/bin/bash

# Ensure you have wakunode2 built with RLN
# make wakunode2 EXPERIMENTAL=true
echo "Generating rln memberships into a single keystore"

# clean old keystore
rm rlnKeystore.json

# seems we dont populate the chain id, so infura considers it as replayable and rejects it.
#ws://linux-01.ih-eu-mda1.nimbus.sepolia.wg:9557

for i in {0..20}
do
   echo "Generating membership at index $i"
   ./build/wakunode2 \
   --rln-relay=true \
   --rln-relay-dynamic=true \
   --rln-relay-eth-account-private-key=d9f61e035e233e7baabb7ca806f7e9800cfa68397df2d844bf197c3a728cdcef \
   --rln-relay-membership-index=$i \
   --rln-relay-eth-contract-address=0x39558059411112732d73997712b75a865a697330 \
   --rln-relay-eth-client-address=wss://sepolia.infura.io/ws/v3/4576482c0f474483ac709755f2663b20 &
   last_pid=$!
   echo "pid of process is: "
   echo $last_pid

   # this has to be enough to sync the tree and create the keystore. not very efficient 
   sleep 120
   echo "killing $last_pid and generating next membership"
   kill -KILL $last_pid
done


# TODO: add this. run at the end. ensures the size of the keystore matches
# grep -o salt rlnKeystore.json | wc -l
