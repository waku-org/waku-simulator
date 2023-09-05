#!/bin/bash

echo "Generating rln memberships into a single keystore"

# clean old keystore
#rm rlnKeystore.json

# seems we dont populate the chain id, so infura considers it as replayable and rejects it.
#ws://linux-01.ih-eu-mda1.nimbus.sepolia.wg:9557

for i in {1..10}
do
  docker-compose up -d nwaku_$i
  sleep 5
done


# TODO: add this. run at the end. ensures the size of the keystore matches
# grep -o salt rlnKeystore.json | wc -l
