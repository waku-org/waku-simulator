#!/bin/sh

set -e

# 1. Install foundry, pnpm, and required tools
apt update && apt install -y jq

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

# 6. Setup tokens for nwaku nodes
echo "\nSetting up tokens for nwaku nodes..."

# Read anvil config to get addresses and private keys
ANVIL_CONFIG=$(cat /shared/anvil-config.txt)
ADDRESSES=$(echo "$ANVIL_CONFIG" | jq -r '.available_accounts[]')
echo "Available addresses: $ADDRESSES"
PRIVATE_KEYS=$(echo "$ANVIL_CONFIG" | jq -r '.private_keys[]')

# Get number of nwaku nodes from environment (default 5)
NUM_NODES=${NUM_NWAKU_NODES:-5}

echo "Setting up tokens for $NUM_NODES nwaku nodes"

# Process each account sequentially to ensure reliability
node_index=1
address_index=1

echo "$ADDRESSES" | while read ADDRESS; do
    if [ $node_index -le $NUM_NODES ]; then
        # Get corresponding private key
        PRIV_KEY=$(echo "$PRIVATE_KEYS" | sed -n "${address_index}p")
        
        echo "Setting up tokens for node $node_index: $ADDRESS"
        
        # Mint tokens to the address
        echo "  Minting tokens..."
        cast send $TOKEN_ADDRESS "mint(address,uint256)" $ADDRESS 5000000000000000000 --private-key $PRIVATE_KEY --from $ETH_FROM --rpc-url $RPC_URL
        
        # Approve the RLN contract to spend tokens
        echo "  Approving contract..."
        cast send $TOKEN_ADDRESS "approve(address,uint256)" $CONTRACT_ADDRESS 5000000000000000000 --private-key $PRIV_KEY --from $ADDRESS --rpc-url $RPC_URL
        
        echo "✓ Node $node_index setup complete"
        node_index=$((node_index + 1))
    else
        break
    fi
    
    address_index=$((address_index + 1))
done

echo "Token setup complete for all nwaku nodes"