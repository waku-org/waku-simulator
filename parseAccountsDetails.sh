#!/bin/bash

# Read the JSON file
json_content=$(cat /shared/anvil-config.txt)

# Extract available_accounts and private_keys arrays using jq
available_accounts=$(echo "$json_content" | jq -r '.available_accounts[]')
private_keys=$(echo "$json_content" | jq -r '.private_keys[]')

# Convert the extracted strings to Bash arrays
available_accounts_array=()
while IFS= read -r account; do
    available_accounts_array+=("$account")
done <<< "$available_accounts"

private_keys_array=()
while IFS= read -r key; do
    private_keys_array+=("$key")
done <<< "$private_keys"

# echo "ACCOUNT: ${available_accounts_array[$1-1]}"
# echo "PRIVATE KEY: ${private_keys_array[$1-1]}"
echo ${private_keys_array[$1-1]}
