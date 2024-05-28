#!/bin/sh

set -e



# 2. Install pnpm
echo "installing pnpm..."
npm install -g -d pnpm
# curl -L -o /usr/local/bin/pnpm https://github.com/pnpm/pnpm/releases/download/v9.1.3/pnpm-linux-x64
# PNPM_HOME=/usr/local/bin/
# chmod +x /usr/local/bin/pnpm

# 1. Install foundry
echo "installing foundry..."
curl -L https://foundry.paradigm.xyz | bash && . /root/.bashrc && foundryup && export PATH=$PATH:$HOME/.foundry/bin

# 3. Clone and build waku-rln-contract repo
if [ -d "/waku-rln-contract" ]; then
    echo "waku-rln-contract directory already exists."
else
    git clone https://github.com/waku-org/waku-rlnv2-contract.git
    
fi

cd /waku-rlnv2-contract

echo "forge install..."
forge install 
echo "pnpm install..."
pnpm install
echo "forge build..."
forge build

# 4. Create .env file with RPC_PROVIDER variable
echo "creating .env file with RPC_PROVIDER=$RPC_URL"
echo "RPC_PROVIDER=$RPC_URL" > .env

# 5. Deploy the contracts
forge script script/Deploy.s.sol --broadcast --fork-url $RPC_URL