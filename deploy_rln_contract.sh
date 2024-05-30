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

cd /waku-rlnv2-contract

# 3. Compile
echo "forge install..."
forge install
echo "pnpm install..."
pnpm install
echo "forge build..."
forge build

# 4. Export environment variables
export API_KEY_ETHERSCAN=123
export RCL_URL=$RCL_URL
export PRIVATE_KEY=$PRIVATE_KEY

# 5. Deploy the contract
forge script script/Deploy.s.sol:Deploy --broadcast --fork-url $RPC_URL --private-key $PRIVATE_KEY