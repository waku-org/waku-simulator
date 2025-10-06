#!/usr/bin/env python3
"""
Per-node token initialization service.

This script runs as an init container for each nwaku node to:
1. Mint ERC20 tokens to the node's address
2. Approve the RLN contract to spend those tokens

Each node gets its own private key and handles its own token setup.
"""

import os
import sys
import time
import logging
from web3 import Web3
from web3.exceptions import TransactionNotFound

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - [Node Init] %(message)s'
)
logger = logging.getLogger(__name__)

class NodeTokenInitializer:
    def __init__(self):
        """Initialize the node token service."""
        # Required environment variables
        self.rpc_url = os.getenv('RPC_URL', 'http://foundry:8545')
        self.token_address = os.getenv('TOKEN_ADDRESS', '0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512')
        self.contract_address = os.getenv('RLN_CONTRACT_ADDRESS', '0x0165878A594ca255338adfa4d48449f69242Eb8F')
        # The values for NODE_PRIVATE_KEY, NODE_ADDRESS, and NODE_INDEX are set by the get_account_key.sh script
        self.private_key = os.getenv('NODE_PRIVATE_KEY')
        self.node_address = os.getenv('NODE_ADDRESS')
        self.node_index = os.getenv('NODE_INDEX', '0')
        # Approver private key for adding accounts to approved minters list
        self.approver_private_key = os.getenv('PRIVATE_KEY')

        self.mint_amount = int(os.getenv('MINT_AMOUNT', '5000000000000000000'))  # at least 5 tokens required for membership with RLN_RELAY_MSG_LIMIT=100
        
        if not self.private_key:
            raise ValueError("NODE_PRIVATE_KEY (Ethereum account private key) environment variable is required")
        if not self.node_address:
            raise ValueError("NODE_ADDRESS (Ethereum account address) environment variable is required")
        if not self.approver_private_key:
            logger.error("PRIVATE_KEY environment variable is missing!")
            raise ValueError("PRIVATE_KEY (Token contract owner private key) environment variable is required")
        else:
            logger.info(f"PRIVATE_KEY loaded successfully")
        
        # Initialize Web3
        self.w3 = Web3(Web3.HTTPProvider(self.rpc_url))
        if not self.w3.is_connected():
            raise Exception(f"Failed to connect to Ethereum node at {self.rpc_url}")
        
        # Get approver address from private key
        try:
            self.approver_address = self.w3.eth.account.from_key(self.approver_private_key).address
            logger.info(f"Approver address derived: {self.approver_address}")
        except Exception as e:
            logger.error(f"Failed to derive approver address from PRIVATE_KEY: {str(e)}")
            raise
        
        # Convert addresses to proper checksum format
        self.node_address = self.w3.to_checksum_address(self.node_address)
        self.token_address = self.w3.to_checksum_address(self.token_address)
        self.contract_address = self.w3.to_checksum_address(self.contract_address)
        self.approver_address = self.w3.to_checksum_address(self.approver_address)
        
        logger.info(f"Node {self.node_index} initializing tokens")
        logger.info(f"Address: {self.node_address}")
        logger.info(f"Token: {self.token_address}")
        logger.info(f"Contract: {self.contract_address}")

    def wait_for_transaction(self, tx_hash: str, timeout: int = 120) -> bool:
        """Wait for transaction to be mined."""
        start_time = time.time()
        while time.time() - start_time < timeout:
            try:
                receipt = self.w3.eth.get_transaction_receipt(tx_hash)
                if receipt.status == 1:
                    logger.info(f"Transaction {tx_hash} confirmed")
                    return True
                else:
                    logger.error(f"Transaction {tx_hash} failed with status {receipt.status}")
                    return False
            except TransactionNotFound:
                time.sleep(2)
                continue
        
        logger.error(f"Transaction {tx_hash} timed out after {timeout} seconds")
        return False

    def approve_account_for_minting(self) -> bool:
        """Add this node's address to the approved minters list."""
        logger.info(f"=== STARTING APPROVAL PROCESS ===")
        logger.info(f"Node address to approve: {self.node_address}")
        logger.info(f"Approver address: {self.approver_address}")
        logger.info(f"Token contract: {self.token_address}")
        
        for attempt in range(3):
            try:
                logger.info(f"Adding {self.node_address} to approved minters list (attempt {attempt + 1}/3)")
                
                # Use the approver's private key (contract owner)
                nonce = self.w3.eth.get_transaction_count(self.approver_address, 'pending')
                
                # Build addApprovedAccount transaction
                function_signature = self.w3.keccak(text="addMinter(address)")[:4]
                encoded_address = self.node_address[2:].lower().zfill(64)
                data = function_signature.hex() + encoded_address
                
                # Increase gas price for retries to avoid underpriced transactions
                gas_price = self.w3.eth.gas_price
                if attempt > 0:
                    gas_price = int(gas_price * (1.1 ** attempt))  # 10% increase per retry
                
                transaction = {
                    'to': self.token_address,
                    'value': 0,
                    'gas': 200000,
                    'gasPrice': gas_price,
                    'nonce': nonce,
                    'data': data,
                }
                
                # Sign and send with approver's key
                signed_txn = self.w3.eth.account.sign_transaction(transaction, self.approver_private_key)
                tx_hash = self.w3.eth.send_raw_transaction(signed_txn.rawTransaction)
                
                logger.info(f"Approve account transaction sent: {tx_hash.hex()}")
                
                if self.wait_for_transaction(tx_hash.hex()):
                    logger.info(f"✓ Account approval successful for node {self.node_index}")
                    return True
                else:
                    logger.error(f"✗ Account approval failed for node {self.node_index} (attempt {attempt + 1})")
                    if attempt < 2:
                        logger.info(f"Retrying account approval in 5 seconds...")
                        time.sleep(5)
                    continue
                    
            except Exception as e:
                logger.error(f"✗ Account approval failed for node {self.node_index} (attempt {attempt + 1}): {str(e)}")
                logger.error(f"Exception type: {type(e).__name__}")
                logger.error(f"Exception details: {repr(e)}")
                if attempt < 2:
                    logger.info(f"Retrying account approval in 5 seconds...")
                    time.sleep(5)
                continue
        
        logger.error(f"✗ Account approval failed for node {self.node_index} after 3 attempts")
        logger.error(f"=== APPROVAL PROCESS FAILED ===")
        return False

    def mint_tokens(self) -> bool:
        """Mint tokens to this node's address using the node's own private key."""
        for attempt in range(3):
            try:
                logger.info(f"Minting {self.mint_amount} tokens to {self.node_address} (attempt {attempt + 1}/3)")
                
                # Use the node's own private key since mint() is public
                nonce = self.w3.eth.get_transaction_count(self.node_address, 'pending')
                
                # Build mint transaction
                function_signature = self.w3.keccak(text="mint(address,uint256)")[:4]
                encoded_address = self.node_address[2:].lower().zfill(64)
                encoded_amount = hex(self.mint_amount)[2:].zfill(64)
                data = function_signature.hex() + encoded_address + encoded_amount
                
                # Increase gas price for retries to avoid underpriced transactions
                gas_price = self.w3.eth.gas_price
                if attempt > 0:
                    gas_price = int(gas_price * (1.1 ** attempt))  # 10% increase per retry
                
                transaction = {
                    'to': self.token_address,
                    'value': 0,
                    'gas': 200000,
                    'gasPrice': gas_price,
                    'nonce': nonce,
                    'data': data,
                }
                
                # Sign and send with node's own key
                signed_txn = self.w3.eth.account.sign_transaction(transaction, self.private_key)
                tx_hash = self.w3.eth.send_raw_transaction(signed_txn.rawTransaction)
                
                logger.info(f"Mint transaction sent: {tx_hash.hex()}")
                
                if self.wait_for_transaction(tx_hash.hex()):
                    logger.info(f"✓ Mint successful for node {self.node_index}")
                    return True
                else:
                    logger.error(f"✗ Mint failed for node {self.node_index} (attempt {attempt + 1})")
                    if attempt < 2:
                        logger.info(f"Retrying mint in 5 seconds...")
                        time.sleep(5)
                    continue
                    
            except Exception as e:
                logger.error(f"✗ Mint failed for node {self.node_index} (attempt {attempt + 1}): {str(e)}")
                if attempt < 2:
                    logger.info(f"Retrying mint in 5 seconds...")
                    time.sleep(5)
                continue
        
        logger.error(f"✗ Mint failed for node {self.node_index} after 3 attempts")
        return False

    def approve_tokens(self) -> bool:
        """Approve RLN contract to spend tokens."""
        for attempt in range(3):
            try:
                logger.info(f"Approving {self.mint_amount} tokens for contract {self.contract_address} (attempt {attempt + 1}/3)")
                
                nonce = self.w3.eth.get_transaction_count(self.node_address, 'pending')
                
                # Build approve transaction
                function_signature = self.w3.keccak(text="approve(address,uint256)")[:4]
                encoded_contract = self.contract_address[2:].lower().zfill(64)
                encoded_amount = hex(self.mint_amount)[2:].zfill(64)
                data = function_signature.hex() + encoded_contract + encoded_amount
                
                # Increase gas price for retries to avoid underpriced transactions
                gas_price = self.w3.eth.gas_price
                if attempt > 0:
                    gas_price = int(gas_price * (1.1 ** attempt))  # 10% increase per retry
                
                transaction = {
                    'to': self.token_address,
                    'value': 0,
                    'gas': 200000,
                    'gasPrice': gas_price,
                    'nonce': nonce,
                    'data': data,
                }
                
                # Sign and send with node's own key
                signed_txn = self.w3.eth.account.sign_transaction(transaction, self.private_key)
                tx_hash = self.w3.eth.send_raw_transaction(signed_txn.rawTransaction)
                
                logger.info(f"Approve transaction sent: {tx_hash.hex()}")
                
                if self.wait_for_transaction(tx_hash.hex()):
                    logger.info(f"✓ Approval successful for node {self.node_index}")
                    return True
                else:
                    logger.error(f"✗ Approval failed for node {self.node_index} (attempt {attempt + 1})")
                    if attempt < 2:
                        logger.info(f"Retrying approval in 5 seconds...")
                        time.sleep(5)
                    continue
                    
            except Exception as e:
                logger.error(f"✗ Approval failed for node {self.node_index} (attempt {attempt + 1}): {str(e)}")
                if attempt < 2:
                    logger.info(f"Retrying approval in 5 seconds...")
                    time.sleep(5)
                continue
        
        logger.error(f"✗ Approval failed for node {self.node_index} after 3 attempts")
        return False

    def run(self) -> bool:
        """Run the token initialization process."""
        try:
            logger.info(f"Starting token initialization for node {self.node_index}")
            logger.info(f"=== DEBUG INFO ===")
            logger.info(f"Node address: {self.node_address}")
            logger.info(f"Approver address: {self.approver_address}")
            logger.info(f"Token address: {self.token_address}")
            logger.info(f"PRIVATE_KEY present: {'Yes' if self.approver_private_key else 'No'}")
            logger.info(f"==================")
            
            # Step 1: Add node address to approved minters list
            logger.info(f"STEP 1: Starting approval process...")
            try:
                if not self.approve_account_for_minting():
                    logger.error(f"STEP 1 FAILED: Could not approve account for minting")
                    return False
                logger.info(f"STEP 1 SUCCESS: Account approved for minting")
            except Exception as e:
                logger.error(f"STEP 1 EXCEPTION: {str(e)}")
                logger.error(f"Exception type: {type(e).__name__}")
                return False
            
            # Step 2: Mint tokens
            if not self.mint_tokens():
                return False
            
            # Step 3: Approve contract
            if not self.approve_tokens():
                return False
            
            logger.info(f"✓ Node {self.node_index} token initialization completed successfully")
            return True
            
        except Exception as e:
            logger.error(f"✗ Node {self.node_index} initialization failed: {str(e)}")
            return False

def main():
    """Main entry point."""
    try:
        initializer = NodeTokenInitializer()
        success = initializer.run()
        
        if success:
            logger.info("Node ready to start")
            sys.exit(0)
        else:
            logger.error("Node initialization failed")
            sys.exit(1)
            
    except Exception as e:
        logger.error(f"Failed to initialize: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    main()