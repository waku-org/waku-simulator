#!/bin/sh

# Install json parser
apk update
apk add jq

# Read the JSON file
json_content=$(cat /shared/anvil-config.txt)

# Extract private_keys array values using jq
private_keys=$(echo "$json_content" | jq -r '.private_keys[]')

# Write private keys to a new file for easier access
echo "Writing private keys to file"
echo "$private_keys" > /shared/private-keys.txt
