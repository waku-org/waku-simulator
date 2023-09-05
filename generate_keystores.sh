#!/bin/bash

echo "Generating rln memberships into a single keystore"

# clean old keystore
#rm rlnKeystore.json

# seems we dont populate the chain id, so infura considers it as replayable and rejects it.
#ws://linux-01.ih-eu-mda1.nimbus.sepolia.wg:9557

for i in {0..5}
do
   echo "Generating membership $i"
   ./build/waku generate-rln-credentials \
--eth-account-private-key=d9f61e035e233e7baabb7ca806f7e9800cfa68397df2d844bf197c3a728cdcef \
--eth-contract-address=0x2992c7bFD42729991b614e95F4C2C78619f49c50 \
--eth-client-address=wss://sepolia.infura.io/ws/v3/4576482c0f474483ac709755f2663b20 \
--cred-path=rlnKeystore.json

done


# TODO: add this. run at the end. ensures the size of the keystore matches
# grep -o salt rlnKeystore.json | wc -l
