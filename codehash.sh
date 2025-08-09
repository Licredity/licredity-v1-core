#!/bin/bash

# Deployment script for Licredity protocol
# Usage: ./codehash.sh <CHAIN> <BASE_TOKEN>
# Example: ./codehash.sh Ethereum ETH

set -e

if [ $# -ne 2 ]; then
    echo "Usage: $0 <CHAIN> <BASE_TOKEN>"
    echo "Chains: Ethereum, Unichain, Base"
    echo "Base tokens: ETH, USDC"
    echo "Examples:"
    echo "  $0 Ethereum ETH"
    echo "  $0 Base USDC"
    echo "  $0 Unichain ETH"
    exit 1
fi

CHAIN=$1
BASE_TOKEN=$2

# Check if .env file exists
if [ ! -f .env ]; then
    echo "Error: .env file not found. Please copy .env.example to .env and configure it."
    exit 1
fi

# Load environment variables
source .env

# Validate required environment variables
RPC_URL_VAR="${CHAIN}_RPC_URL"
RPC_URL=${!RPC_URL_VAR}

if [ -z "$RPC_URL" ]; then
    echo "Error: ${CHAIN}_RPC_URL not set in .env file"
    exit 1
fi

if [ -z "$PRIVATE_KEY" ]; then
    echo "Error: PRIVATE_KEY not set in .env file"
    exit 1
fi

# Check base token address exists
BASE_TOKEN_VAR="${CHAIN}_${BASE_TOKEN}"
BASE_TOKEN_ADDRESS=${!BASE_TOKEN_VAR}

if [ -z "$BASE_TOKEN_ADDRESS" ]; then
    echo "Error: ${BASE_TOKEN_VAR} not set in .env file"
    exit 1
fi

# Check pool manager address exists
POOL_MANAGER_VAR="${CHAIN}_POOL_MANAGER"
POOL_MANAGER_ADDRESS=${!POOL_MANAGER_VAR}

if [ -z "$POOL_MANAGER_ADDRESS" ]; then
    echo "Error: ${POOL_MANAGER_VAR} not set in .env file"
    exit 1
fi

echo "Starting deployment for chain: $CHAIN with base token: $BASE_TOKEN"
echo "RPC URL: $RPC_URL"
echo "Base token address: $BASE_TOKEN_ADDRESS"
echo "Pool manager address: $POOL_MANAGER_ADDRESS"

# Set environment variables for the deployment script
export CHAIN=$CHAIN
export BASE_TOKEN=$BASE_TOKEN

# Compile contracts
echo "Compiling contracts..."
forge build

# Deploy contracts
echo "Deploying contracts..."
forge script script/CodeHash.s.sol:PrintInitCodeHash
