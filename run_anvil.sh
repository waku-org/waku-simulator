#!/bin/sh

echo "anvil script"

# defaults:
# 
exec anvil --port 8540 --chain-id 1337 --block-time 12 --accounts 1

echo "anvil running"