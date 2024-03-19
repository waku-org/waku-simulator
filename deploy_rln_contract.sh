#/bin/bash

set -e

# 1. Retrieve contract details from the git repo and extract bytecode
apk add curl
repo_url="https://github.com/waku-org/waku-rln-contract/blob/main/deployments/sepolia/"
poseidon_hasher_json="PoseidonHasher.json"
waku_rln_registry_impl_json="WakuRlnRegistry_Implementation.json";
waku_rln_registry_proxy_json="WakuRlnRegistry_Proxy.json"

curl -o "$poseidon_hasher_json" "$repo_url$poseidon_hasher_json"
curl -o "$waku_rln_registry_impl_json" "$repo_url$waku_rln_registry_impl_json"
curl -o "$waku_rln_registry_proxy_json" "$repo_url$waku_rln_registry_proxy_json"

json_contents=$(cat $poseidon_hasher_json)
poseidon_hasher_bytecode=$(echo "$json_contents" | grep -o 'bytecode\\"[^,]*' | awk -F '0x' '{print "0x" substr($2, 1, length($2)-2)}')

json_contents=$(cat $waku_rln_registry_impl_json)
waku_rln_registry_impl_bytecode=$(echo "$json_contents" | grep -o 'bytecode\\"[^,]*' | awk -F '0x' '{print "0x" substr($2, 1, length($2)-2)}')

json_contents=$(cat $waku_rln_registry_proxy_json)
waku_rln_registry_proxy_bytecode=$(echo "$json_contents" | grep -o 'bytecode\\"[^,]*' | awk -F '0x' '{print "0x" substr($2, 1, length($2)-2)}')

echo "Deploying RLN contracts..."

# 2. Deploy Poseidon Hasher
poseidon_address=$(cast send --rpc-url $RPC_URL --private-key $PRIVATE_KEY --create $poseidon_hasher_bytecode | grep contractAddress | cut -d' ' -f10)

# 3. Deploy Waku Rln Registry Implementation
implementation_address=$(cast send --rpc-url $RPC_URL --private-key $PRIVATE_KEY --create $waku_rln_registry_impl_bytecode | grep contractAddress | cut -d' ' -f10)

# 4. Concatenate Waku Rln Registry Proxy Bytecode with constructor arguments in the form of
# constructor(address implementation, bytes memory data)
# where data = abi.encodeWithSignature("initialize(address)", address(poseidonHasher))

constructor_arguments=$(cast abi-encode "constructor(address impl, bytes data)" "$implementation_address" $(cast calldata "initialize(address)" "$poseidon_address") | cut -c 3-)
waku_rln_registry_proxy_bytecode_with_constructor_arguments="$waku_rln_registry_proxy_bytecode$constructor_arguments"

# 5. Deploy Waku Rln Registry Proxy
waku_rln_registry_proxy_address=$(cast send --rpc-url $RPC_URL --private-key $PRIVATE_KEY --create $waku_rln_registry_proxy_bytecode_with_constructor_arguments | grep contractAddress | cut -d' ' -f10)

# 6. Deploy New Storage
deploy_new_storage_out=$(cast send --rpc-url $RPC_URL --private-key $PRIVATE_KEY $waku_rln_registry_proxy_address "newStorage()") 
# Fetch the new storage address
new_storage_address=$(cast call --rpc-url $RPC_URL $waku_rln_registry_proxy_address "storages(uint16)(address)" 0)

printf "%-50s %s\n" "Contract" "Contract Address"
printf "%-50s %s\n" "--------" "----------------"

# Print data in table format
printf "%-50s %s\n" "PoseidonHasher" "$poseidon_address"
printf "%-50s %s\n" "Waku_Rln_Registry_Implementation" "$implementation_address"
printf "%-50s %s\n" "Waku_Rln_Registry_Proxy" "$waku_rln_registry_proxy_address"
printf "%-50s %s\n" "New_Storage" "$new_storage_address"