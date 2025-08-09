# Licredity v1 Core Deployment Guide

This guide covers the deployment of the Licredity v1 Core protocol smart contracts to supported blockchain networks.

## Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation) installed
- Access to RPC endpoints for target chains
- Sufficient native tokens for gas fees
- Private key with deployment permissions
- Block explorer API keys for contract verification (optional)

## Quick Start

1. **Copy environment configuration:**

   ```bash
   cp .env.example .env
   ```

2. **Configure deployment parameters in `.env`:**

   ```bash
   # Required: Private key for deployment
   PRIVATE_KEY=0x...

   # Required: Chain-specific addresses
   Ethereum_ETH=0x...
   Ethereum_POOL_MANAGER=0x...
   Ethereum_GOVERNOR=0x...
   Ethereum_RPC_URL=https://eth-mainnet.g.alchemy.com/v2/...
   ```

3. **Deploy to desired network:**
   ```bash
   ./deploy.sh Ethereum ETH
   ```

## Environment Configuration

### Required Variables

| Variable               | Description                        |
| ---------------------- | ---------------------------------- |
| `PRIVATE_KEY`          | Private key for deployment account |
| `{CHAIN}_{TOKEN}`      | Base token contract address        |
| `{CHAIN}_POOL_MANAGER` | Uniswap v4 Pool Manager address    |
| `{CHAIN}_GOVERNOR`     | Protocol governance address        |
| `{CHAIN}_RPC_URL`      | RPC endpoint URL                   |

### Optional Variables

| Variable                   | Description                             | Default          |
| -------------------------- | --------------------------------------- | ---------------- |
| `{CHAIN}_SCAN_API_KEY`     | Block explorer API key for verification | -                |
| `DEBT_TOKEN_NAME_PREFIX`   | Prefix for debt token name              | "Licredity debt" |
| `DEBT_TOKEN_SYMBOL_PREFIX` | Prefix for debt token symbol            | "d"              |

### Environment Variable Pattern

Variables follow the pattern `{CHAIN}_{PARAMETER}` where:

- `CHAIN`: Network name (Ethereum, Base, Unichain)
- `PARAMETER`: Configuration parameter name

Example for Ethereum ETH deployment:

```bash
Ethereum_ETH=0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
Ethereum_POOL_MANAGER=0x...
Ethereum_GOVERNOR=0x...
Ethereum_RPC_URL=https://eth-mainnet.g.alchemy.com/v2/YOUR_API_KEY
Ethereum_SCAN_API_KEY=YOUR_ETHERSCAN_API_KEY
```

## Deployment Process

### Using the Deploy Script

The `deploy.sh` script provides a streamlined deployment process:

```bash
./deploy.sh <CHAIN> <BASE_TOKEN>
```

**Examples:**

```bash
./deploy.sh Ethereum ETH      # Deploy ETH pool on Ethereum
./deploy.sh Base USDC         # Deploy USDC pool on Base
./deploy.sh Unichain ETH      # Deploy ETH pool on Unichain
```

### Manual Deployment

For advanced users or custom configurations:

```bash
# 1. Compile contracts
forge build

# 2. Set environment variables
export CHAIN=Ethereum
export BASE_TOKEN=ETH

# 3. Deploy with verification
forge script script/Deploy.s.sol:DeployScript \
    --rpc-url $Ethereum_RPC_URL \
    --broadcast \
    --verify \
    --etherscan-api-key $Ethereum_SCAN_API_KEY \
    -vvvv
```

## Contract Verification

Contracts are automatically verified during deployment if the corresponding `{CHAIN}_SCAN_API_KEY` is provided.

**Supported Block Explorers:**

- Ethereum: Etherscan
- Base: Basescan
- Unichain: Uniscan

To verify manually after deployment:

```bash
forge verify-contract \
    --chain-id 1 \
    --num-of-optimizations 200 \
    --watch \
    --constructor-args $(cast abi-encode "constructor(address,address,address,string,string)" $BASE_TOKEN $POOL_MANAGER $GOVERNOR $NAME $SYMBOL) \
    --etherscan-api-key $API_KEY \
    $CONTRACT_ADDRESS \
    src/Licredity.sol:Licredity
```

## Deployed Contract Structure

Each deployment creates a single `Licredity` contract instance with the following constructor parameters:

- `baseToken`: Address of the underlying collateral token
- `poolManager`: Uniswap v4 Pool Manager contract address
- `governor`: Protocol governance contract address
- `name`: Debt token name (e.g., "Licredity debt ETH")
- `symbol`: Debt token symbol (e.g., "dETH")

## Output Files

### Deployment Records

Successful deployments create records in the `deployments/` directory:

```
deployments/
├── Ethereum_ETH.env
├── Base_USDC.env
└── Unichain_ETH.env
```

Each file contains:

```bash
# Licredity for ETH on Ethereum deployed at: 0x...
Base token: 0x...
Pool Manager: 0x...
Governor: 0x...
```

### Forge Broadcast Logs

Detailed transaction logs are saved in:

```
broadcast/Deploy.s.sol/{chainId}/
├── dry-run/
└── run-latest.json
```

## Troubleshooting

### Common Issues

**Environment file not found:**

```bash
Error: .env file not found. Please copy .env.example to .env and configure it.
```

Solution: Copy `.env.example` to `.env` and configure required variables.

**Missing RPC URL:**

```bash
Error: Ethereum_RPC_URL not set in .env file
```

Solution: Add the RPC URL for the target chain in `.env`.

**Insufficient gas:**

```bash
Error: insufficient funds for intrinsic transaction cost
```

Solution: Ensure the deployment account has sufficient native tokens for gas.

**Contract verification failed:**

```bash
Warning: No API key found for Ethereum verification. Skipping verification.
```

Solution: Add the block explorer API key to `.env` or verify manually after deployment.

## Security Considerations

### Private Key Management

- Never commit private keys to version control
- Use hardware wallets or secure key management for mainnet deployments
- Consider using deployment-specific addresses with minimal balances

### Pre-deployment Checklist

- [ ] Verify all addresses in `.env` are correct
- [ ] Confirm base token contract is legitimate
- [ ] Validate Pool Manager is official Uniswap v4 deployment
- [ ] Ensure governor address has appropriate permissions
- [ ] Test deployment on testnet first
- [ ] Verify sufficient gas balance

### Post-deployment Verification

- [ ] Confirm contract deployment success
- [ ] Verify contract on block explorer
- [ ] Check deployed addresses match expectations
- [ ] Test basic contract functionality
- [ ] Save deployment records securely
