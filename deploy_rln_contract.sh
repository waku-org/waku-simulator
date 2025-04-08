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

# if [ -z "$RLN_CONTRACT_REPO_COMMIT" ]; then
#     echo "RLN_CONTRACT_REPO_COMMIT is not set"
#     exit 1
# fi

cd /waku-rlnv2-contract
# git checkout $RLN_CONTRACT_REPO_COMMIT

# #3. Replace the hardcoded MAX_MESSAGE_LIMIT
# sed -i "s/\b100\b/${MAX_MESSAGE_LIMIT}/g" script/Deploy.s.sol

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

# 6. Deploy the TestToken
echo "Deploying TestToken..."
forge script test/TestToken.sol --broadcast -vvvv --rpc-url http://foundry:8545 --tc TestTokenFactory --private-key $PRIVATE_KEY
export TOKEN_ADDRESS=0x5FbDB2315678afecb367f032d93F642f64180aa3
echo "Deploying PriceCalculator"
forge script script/Deploy.s.sol --broadcast --rpc-url http://foundry:8545 --tc DeployPriceCalculator -vvvv --private-key $PRIVATE_KEY
echo "Deploying RLN contract..."
forge script script/Deploy.s.sol --broadcast --rpc-url http://foundry:8545 --tc DeployWakuRlnV2 -vvvv --private-key $PRIVATE_KEY
echo "Deploying Proxy contract..."
forge script script/Deploy.s.sol --broadcast --rpc-url http://foundry:8545 --tc DeployProxy -vvvv --private-key $PRIVATE_KEY
CONTRACT_ADDRESS=0x5FC8d32690cc91D4c39d9d3abcBD16989F875707

# echo "Deploying TestToken...2"
# forge script test/TestToken.sol --broadcast -vvvv --rpc-url http://foundry:8545 --tc TestTokenFactory --private-key 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
# export TOKEN2=0x0165878A594ca255338adfa4d48449f69242Eb8F
echo "Minting...1"
  cast send $TOKEN_ADDRESS "mint(address,uint256)" $ETH_FROM 90000000000000000000 --private-key $PRIVATE_KEY --rpc-url $RPC_URL
  cast send $TOKEN_ADDRESS "approve(address,uint256)" $CONTRACT_ADDRESS 3000000000000000000 --private-key $PRIVATE_KEY --rpc-url $RPC_URL

echo "Transfer tokens from account1 to others..."
# account1 transfers tokens to account2
  # cast send $TOKEN_ADDRESS "transfer(address,uint256)" 0x70997970c51812dc3a010c7d01b50e0d17dc79c8 3000000000000000000  --private-key $PRIVATE_KEY --rpc-url $RPC_URL
  # cast send $TOKEN_ADDRESS "transfer(address,uint256)" 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC 3000000000000000000  --private-key $PRIVATE_KEY --rpc-url $RPC_URL
  # cast send $TOKEN_ADDRESS "transfer(address,uint256)" 0x90F79bf6EB2c4f870365E785982E1f101E93b906 1100000000000000000  --private-key $PRIVATE_KEY --rpc-url $RPC_URL
  # cast send $TOKEN_ADDRESS "transfer(address,uint256)" 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65 1000000000000000000  --private-key $PRIVATE_KEY --rpc-url $RPC_URL
echo "Minting..2"
# account2 approves the smart contract
  # cast send --from 0x70997970c51812dc3a010c7d01b50e0d17dc79c8 $TOKEN_ADDRESS "approve(address,uint256)" $CONTRACT_ADDRESS 3000000000000000000 --private-key 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d --rpc-url $RPC_URL
# echo "Allowance:"  
#   cast call $TOKEN_ADDRESS "allowance(address,address)" 0x70997970c51812dc3a010c7d01b50e0d17dc79c8 $CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $PRIVATE_KEY

  export ID_COMMITMENT=1234
  export RATE_LIMIT=20
  export PATH=$PATH:$HOME/.foundry/bin
  echo "REGISTERING"
  # TX_HASH=$(cast send $CONTRACT_ADDRESS "register(uint256,uint32,uint256[])" $ID_COMMITMENT $RATE_LIMIT "[]" --rpc-url $RPC_URL --private-key $private_key)
  # echo "Transaction hash: $TX_HASH"

# echo "Minting..3"
#   cast send  --from 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC $TOKEN_ADDRESS "approve(address,uint256)" $CONTRACT_ADDRESS 2000000000000000000 --private-key 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a --rpc-url $RPC_URL
#   cast call $TOKEN_ADDRESS "allowance(address,address)" 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC $CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a
# # echo "Minting..4"
  # cast send  --from 0x90F79bf6EB2c4f870365E785982E1f101E93b906 $TOKEN_ADDRESS "approve(address,uint256)" $CONTRACT_ADDRESS 1100000000000000000 --private-key 0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6 --rpc-url $RPC_URL
  # cast send  --from 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65 $TOKEN_ADDRESS "approve(address,uint256)" $CONTRACT_ADDRESS 1000000000000000000 --private-key 0x47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a --rpc-url $RPC_URL
  # cast send $TOKEN_ADDRESS "mint(address,uint256)" 0x70997970c51812dc3a010c7d01b50e0d17dc79c8 3000000000000000000 --private-key $PRIVATE_KEY --rpc-url $RPC_URL
  # cast send $TOKEN_ADDRESS "approve(address,uint256)" 0x70997970c51812dc3a010c7d01b50e0d17dc79c8 3000000000000000000 --private-key $PRIVATE_KEY --rpc-url $RPC_URL
#   cast send $TOKEN_ADDRESS "approve(address,uint256)" $CONTRACT_ADDRESS 3000000000000000000 --private-key 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d --rpc-url $RPC_URL

# echo "Minting...3"
#   cast send $TOKEN_ADDRESS "mint(address,uint256)" 0x3c44cdddb6a900fa2b585dd299e03d12fa4293bc 3000000000000000000 --private-key $PRIVATE_KEY --rpc-url $RPC_URL
#   cast send $TOKEN_ADDRESS "approve(address,uint256)" 0x3c44cdddb6a900fa2b585dd299e03d12fa4293bc 3000000000000000000 --private-key $PRIVATE_KEY --rpc-url $RPC_URL
# echo "Minting...4"
#   cast send $TOKEN_ADDRESS "mint(address,uint256)" 0x90f79bf6eb2c4f870365e785982e1f101e93b906 3000000000000000000 --private-key $PRIVATE_KEY --rpc-url $RPC_URL
#   cast send $TOKEN_ADDRESS "approve(address,uint256)" 0x90f79bf6eb2c4f870365e785982e1f101e93b906 3000000000000000000 --private-key $PRIVATE_KEY --rpc-url $RPC_URL
# echo "Minting...5"


#  cast call 0x5FC8d32690cc91D4c39d9d3abcBD16989F875707 "getMembershipInfo(uint256)(uint32,uint32,uint256)" 21204544607239115553923357468848196222422962366969722479087435796807960273791 --private-key 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d --rpc-url http://10.2.0.2:8545
#  cast call 0x5FC8d32690cc91D4c39d9d3abcBD16989F875707 "getMembershipInfo(uint256)(uint32,uint32,uint256)" 5494780760687378186440165448823694579544849163701100293317352188071056809499 --private-key 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d --rpc-url http://10.2.0.2:8545
#  cast call 0x5FC8d32690cc91D4c39d9d3abcBD16989F875707 "getMerkleProof(uint40)(uint256[20])" 1 --private-key 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d --rpc-url http://10.2.0.2:8545

# DBG 2025-04-03 08:58:32.855+00:00 credentials                                topics="rln_keystore_generator" tid=46 file=rln_keystore_generator.nim:41 idTrapdoor=02a739626fff4f7881f38184191af32619992ce80e9d4a2278fa56db06addc90 idNullifier=0dcf56c07a1198fec0961dd263a85712e68bff55c427c7b52e93111b67cd08e5 idSecretHash=07fc9279feae269da1c6578ce820b18b6ddf7c21877b8d54e76fa7f6a2098fab idCommitment=2ee158d0cc064ddcd579a23585c4996180b1e3245388321a6127e3c27714a37f
# DBG 2025-04-03 08:58:32.877+00:00 registering the member                     topics="waku rln_relay onchain_group_manager" tid=46 file=group_manager.nim:266 idCommitment=21204544607239115553923357468848196222422962366969722479087435796807960273791 userMessageLimit=20 idCommitmentsToErase=@[]