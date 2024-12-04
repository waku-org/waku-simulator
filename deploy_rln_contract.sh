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

#3. Replace the hardcoded MAX_MESSAGE_LIMIT
sed -i "s/\b100\b/${MAX_MESSAGE_LIMIT}/g" script/Deploy.s.sol

# 4. Compile
echo "forge install..."
forge install
echo "pnpm install..."
pnpm install
echo "forge build..."
forge build

# 5. Export environment variables
export RCL_URL=$RCL_URL
export PRIVATE_KEY=$PRIVATE_KEY
export ETH_FROM=$ETH_FROM
# Dummy values
export API_KEY_ETHERSCAN=123
export API_KEY_CARDONA=123
export API_KEY_LINEASCAN=123

# 6. Deploy the contract
forge script script/Deploy.s.sol:Deploy --rpc-url $RPC_URL --broadcast -vv --private-key $PRIVATE_KEY --sender $ETH_FROM