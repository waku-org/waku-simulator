#!/bin/sh

set -e

# 1. Install foundry
curl -L https://foundry.paradigm.xyz | bash && . /root/.bashrc && foundryup && export PATH=$PATH:$HOME/.foundry/bin

#. 2. Clone and build waku-rln-contract repo
git clone https://github.com/waku-org/waku-rln-contract.git
cd /waku-rln-contract
forge install && yarn install && yarn compile

# 3. Create .env file with RPC_PROVIDER variable
echo "creating .env file with RPC_PROVIDER=$RPC_URL"
echo "RPC_PROVIDER=$RPC_URL" > .env

# 3. Deploy the contracts
yarn deploy localhost_integration