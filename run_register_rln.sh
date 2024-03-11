#!/bin/sh


if test -f ./keystore/keystore.json; then
  echo "keystore/keystore.json already exists. Use it instead of creating a new one."
  echo "Exiting"
  exit 1
fi


if test -f .env; then
  echo "Using .env file"  
  . $(pwd)/.env
fi

# TODO: Set nwaku release when ready instead of quay


exec /usr/bin/wakunode generateRlnKeystore \
--rln-relay-eth-client-address=http://10.1.0.5:8545 \
--rln-relay-eth-private-key=0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6 \
--rln-relay-eth-contract-address=0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0 \
--rln-relay-cred-path=/keystore/keystore.json \
--rln-relay-cred-password="my_secure_keystore_password" \
--execute