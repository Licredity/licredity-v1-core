#!/bin/bash

# Deployment script for Licredity protocol
# Usage: ./deploy.sh <CHAIN> <BASE_TOKEN>
# Example: ./deploy.sh Ethereum ETH

set -e

if [ $@ -gt 2 ]; then
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

INTEREST_SENSITIVITY_VAR="${CHAIN}_INTEREST_SENSITIVITY"
INTEREST_SENSITIVITY=${!INTEREST_SENSITIVITY_VAR}

if [ -z "$INTEREST_SENSITIVITY" ]; then
    echo "Error: ${INTEREST_SENSITIVITY_VAR} not set in .env file"
    exit 1
fi

echo "Starting deployment for chain: $CHAIN with base token: $BASE_TOKEN"
echo "RPC URL: $RPC_URL"
echo "Base token address: $BASE_TOKEN_ADDRESS"
echo "Pool manager address: $POOL_MANAGER_ADDRESS"
echo "Interest sensitivity: $INTEREST_SENSITIVITY"

# Create deployments directory if it doesn't exist
mkdir -p deployments

# Set environment variables for the deployment script
export CHAIN=$CHAIN
export BASE_TOKEN=$BASE_TOKEN

# Determine which API key to use for verification
# API_KEY_VAR="${CHAIN}_SCAN_API_KEY"
# API_KEY=${!API_KEY_VAR}
# VERIFY_ARGS=""
# if [ ! -z "$API_KEY" ]; then
#     VERIFY_ARGS="--verify --etherscan-api-key $API_KEY"
#     echo "Contract verification enabled"
# else
#     echo "Warning: No API key found for $CHAIN verification. Skipping verification."
# fi

# Compile contracts
echo "Compiling contracts..."
forge build

# Deploy contracts
if [[ $3 == "--deploy" ]]; then
    echo "Dry run deploying contracts..."
    forge script script/Deploy.s.sol:DeployScript \
        --rpc-url "$RPC_URL" \
        --broadcast \
        -vvv
else
    echo "Dry run deploying contracts..."
    forge script script/Deploy.s.sol:DeployScript \
        --rpc-url "$RPC_URL" \
        -vvv
fi

echo "Deployment completed for chain: $CHAIN with base token: $BASE_TOKEN"
echo "Check deployments/${CHAIN}_${BASE_TOKEN}.env for deployed addresses"