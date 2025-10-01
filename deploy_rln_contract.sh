#!/bin/sh

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

# 5. Deploy the TestToken Proxy with the TestToken implementation contracts
echo "\nDeploying TestToken Proxy (ERC20 Token Contract)...\n"
DEPLOY_TST_PROXY_OUTPUT=$(ETH_FROM=$ETH_FROM forge script script/DeployTokenWithProxy.s.sol:DeployTokenWithProxy --broadcast -vv --rpc-url http://foundry:8545 --tc TestTokenFactory --private-key $PRIVATE_KEY)
PROXY_TOKEN_ADDRESS=$(echo "$DEPLOY_TST_PROXY_OUTPUT" | grep -o "0: address 0x[a-fA-F0-9]\{40\}" | cut -d' ' -f3)
export TOKEN_ADDRESS=$PROXY_TOKEN_ADDRESS

echo "\nDeploying LinearPriceCalculator Contract..."
forge script script/Deploy.s.sol --broadcast -vv --rpc-url http://foundry:8545 --tc DeployPriceCalculator --private-key $PRIVATE_KEY

echo "\nDeploying RLN contract..."
forge script script/Deploy.s.sol --broadcast -vv --rpc-url http://foundry:8545 --tc DeployWakuRlnV2 --private-key $PRIVATE_KEY

echo "\nDeploying Proxy contract..."
DEPLOY_WAKURLN_PROXY_OUTPUT=$(ETH_FROM=$ETH_FROM forge script script/Deploy.s.sol --broadcast -vvv --rpc-url http://foundry:8545 --tc DeployProxy --private-key $PRIVATE_KEY)
export CONTRACT_ADDRESS=$(echo "$DEPLOY_WAKURLN_PROXY_OUTPUT" | grep -o "0: address 0x[a-fA-F0-9]\{40\}" | cut -d' ' -f3)

# 6. Contract deployment completed
echo "\nContract deployment completed successfully"
echo "TOKEN_ADDRESS: $TOKEN_ADDRESS"
echo "CONTRACT_ADDRESS: $CONTRACT_ADDRESS"
echo "\nEach account registering a membership needs to first mint the token and approve the contract to spend it on their behalf."