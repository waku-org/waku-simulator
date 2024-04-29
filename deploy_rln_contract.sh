#!/bin/sh

set -e

# 1. Install foundry
curl -L https://foundry.paradigm.xyz | bash && . /root/.bashrc && foundryup && export PATH=$PATH:$HOME/.foundry/bin

#. 2. Clone and build waku-rln-contract repo
if [ -d "/waku-rln-contract" ]; then
    echo "waku-rln-contract directory already exists."
else
    git clone https://github.com/waku-org/waku-rln-contract.git
fi

cd /waku-rln-contract
git checkout rln-v2

echo "forge install..."
forge install 
echo "yarn install..."
yarn install
echo "yarn compile..."
yarn compile

# 3. Create .env file with RPC_PROVIDER variable
echo "creating .env file with RPC_PROVIDER=$RPC_URL"
echo "RPC_PROVIDER=$RPC_URL" > .env

# 4. Deploy the contracts
yarn deploy localhost_integration