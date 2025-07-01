#!/bin/bash

set -e

# 1. Install foundry and pnpm
curl -L https://foundry.paradigm.xyz | bash && . /root/.bashrc && foundryup && export PATH=$PATH:$HOME/.foundry/bin

echo "installing pnpm..."
npm install -g pnpm

# 2. Clone and build the repository
if [ ! -d "waku-rlnv2-contract" ]; then
    git clone https://github.com/waku-org/waku-rlnv2-contract.git
fi

if [ -z "$RLN_CONTRACT_REPO_COMMIT" ]; then
    echo "RLN_CONTRACT_REPO_COMMIT is not set"
    exit 1
fi

cd /waku-rlnv2-contract
git checkout $RLN_CONTRACT_REPO_COMMIT

# 3. Compile Contract Repo
echo "forge install..."
forge install
echo "pnpm install..."
pnpm install
echo "forge build..."
forge build

# 4. Export environment variables
export RCL_URL=$RCL_URL
export PRIVATE_KEY=$PRIVATE_KEY
export ETH_FROM=$ETH_FROM
# Dummy values
export API_KEY_ETHERSCAN=123
export API_KEY_CARDONA=123
export API_KEY_LINEASCAN=123

# 5. Deploy the TestToken
echo "\nDeploying TestToken (ERC20 Token Contract)...\n"
forge script test/TestToken.sol --broadcast -vv --rpc-url http://foundry:8545 --tc TestTokenFactory --private-key $PRIVATE_KEY
export TOKEN_ADDRESS=0x5FbDB2315678afecb367f032d93F642f64180aa3

echo "\nDeploying LinearPriceCalculator Contract..."
forge script script/Deploy.s.sol --broadcast -vv --rpc-url http://foundry:8545 --tc DeployPriceCalculator --private-key $PRIVATE_KEY

echo "\nDeploying RLN contract..."
forge script script/Deploy.s.sol --broadcast -vv --rpc-url http://foundry:8545 --tc DeployWakuRlnV2 --private-key $PRIVATE_KEY

echo "\nDeploying Proxy contract..."
forge script script/Deploy.s.sol --broadcast -vvv --rpc-url http://foundry:8545 --tc DeployProxy --private-key $PRIVATE_KEY
export CONTRACT_ADDRESS=0x5FC8d32690cc91D4c39d9d3abcBD16989F875707

# 6. Contract deployment completed
echo "\nContract deployment completed successfully"
echo "TOKEN_ADDRESS: $TOKEN_ADDRESS"
echo "CONTRACT_ADDRESS: $CONTRACT_ADDRESS"
echo "\nEach account registering a membership needs to first mint the token and approve the contract to spend it on their behalf."