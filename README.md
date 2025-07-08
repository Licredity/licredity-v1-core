# Licredity v1 Core

> A permissionless, self-custodial credit protocol built on Uniswap v4

Licredity allows borrowers to mint interest-bearing debt tokens against collateral and deploy them for leveraged positions, while liquidity providers earn enhanced yields through proactive interest
donations directly to Uniswap v4 pools.

[![License: BUSL-1.1](https://img.shields.io/badge/License-BUSL--1.1-blue.svg)](docs/licenses/BUSL_LICENSE)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](docs/licenses/MIT_LICENSE)

## 🚀 Quick Start

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)

### Installation

```bash
# Clone the repository
git clone https://github.com/Licredity/licredity-v1-core
cd licredity-v1-core

# Install dependencies
forge install

# Build contracts
forge build

# Run tests
forge test

Development Commands

# Run specific test
forge test --match-test testFunctionName

# Run tests for specific file
forge test --match-path test/LicredityHook.t.sol

# Run with gas reporting
forge test --gas-report

# Fuzz testing with custom runs
forge test --fuzz-runs 50000

# Clean build artifacts
forge clean

```

## 📖 Protocol Overview

### Core Concept

Licredity creates a credit market where:

- Borrowers deposit collateral and mint debt tokens for leveraged positions
- Liquidity Providers earn enhanced yields from interest donations to Uniswap v4 pools
- Liquidators monitor and seize unhealthy positions for profit

### Key Features

- Multi-Asset Collateral: Support for both fungible (ERC20) and non-fungible (ERC721) tokens
- Dynamic Interest Rates: Interest rates adjust based on pool price dynamics
- Automated Liquidation: Unhealthy positions can be seized by anyone
- LP Yield Enhancement: Interest is donated directly to active Uniswap v4 liquidity
- Position Health Monitoring: Continuous health checks ensure system stability

## 🏗️ Architecture

### Core Contract: Licredity.sol

The main contract inherits from four specialized modules:

```
Licredity.sol
|___BaseERC20.sol       # Debt token functionality (ERC20)
|___BaseHooks.sol       # Uniswap v4 hooks integration
|___Extsload.sol        # External storage load operations
|___RiskConfigs.sol     # Risk parameter management
```

### Position Management

Each position can hold:

- Up to 128 fungible tokens as collateral
- Up to 128 non-fungible tokens as collateral
- Debt shares representing borrowed amount

### Position Health

Positions must maintain health across three dimensions:

1. Collateral Value: value ≥ debt + marginRequirement
2. Minimum Margin: marginRequirement ≥ minMargin (prevents dust positions)
3. Position MRR: debt ≤ value - (value × 1%) (prevents over-leveraging)

### Interest Mechanism

- Interest accrues continuously based on pool price
- Interest is donated to active LPs before any repayments
- Total debt token supply reflects outstanding debt + accrued interest

## 🔄 Core Operations

### For Borrowers

**Opening a Position**

```solidity
// 1. Open new position
uint256 positionId = licredity.open();

// 2. Stage and deposit collateral
licredity.stageFungible(collateralToken);
collateralToken.transfer(address(licredity), amount);
licredity.depositFungible(positionId);

// 3. Borrow debt tokens
licredity.unlock(abi.encodeCall(LicredityRouter.increaseDebtShare, (positionId, shares, recipient)));
```

**The Unlock Pattern**

Operations that could make positions unhealthy require the unlock pattern:

```solidity
licredity.unlock(encodedCalldata); // Performs operations + health checks
```

During unlock:

1. Interest is collected
2. Your callback is executed
3. All modified positions are validated for health
4. Transaction reverts if any position becomes unhealthy

### For LPs

Enhanced Yields

- Provide liquidity to Uniswap v4 base/debt token pools
- Receive proactive interest donations from borrowers
- Earn yields from both trading fees and interest

### For Liquidators

**Seizing Positions**

```solidity
// Monitor positions and seize unhealthy ones
uint256 shortfall = licredity.seize(positionId, recipient);
```

Benefits:

- Take ownership of underperforming positions
- Protocol may top-up underwater positions to encourage liquidation
- Profit from restoring position health

## 🧪 Testing

### Test Structure

```
test/
├── Licredity\*.t.sol # Core protocol tests
├── libraries/ # Library-specific tests
├── mocks/ # Mock contracts
└── utils/ # Testing utilities
```

### Running Tests

```solidity
# All tests
forge test

# Specific test categories
forge test --match-path "test/Licredity*.t.sol"
forge test --match-path "test/libraries/*.t.sol"

# Verbose output
forge test -vvv

# Gas profiling
forge test --gas-report
```

### Fuzzing

The protocol includes extensive fuzz testing:

- 10,000 runs by default (configurable in foundry.toml)
- Tests edge cases in position management
- Validates mathematical invariants

## ⚡ Key Design Decisions

### Assembly Optimizations

The codebase uses assembly extensively for gas optimization:

- Custom error handling with assembly reverts
- Optimized storage operations
- Efficient event emission

### Transient Storage

Uses EIP-1153 transient storage for temporary state:

- locker - Temporarily manages a lock and registered positions
- stagedFungible - Temporarily holds tokens for exchange or deposit
- stagedNonFungible - Temporarily holds NFTs for deposit

### Debt Share System

- Inflation-resistant: 1M initial shares prevent manipulation
- Precise accounting: Tracks debt portions accurately
- Compound interest: Interest compounds automatically

## 🔐 Security Considerations

### Audits

- Initial security audit (pending)
- Economic audit (pending)

### Known Considerations

- Oracle Dependency: Relies on external price oracles
- MEV Resistance: Uses EMA pricing to prevent manipulation
- Bad Debt Handling: Socializes underwater position losses
- Emergency Controls: Governance can adjust risk parameters

### Bug Bounty

We welcome security researchers to review the code. Please report vulnerabilities responsibly.

## 🔧 Integration

### External Dependencies

The protocol integrates with:

- Oracles: External price feeds (not included in this repo)
- Routers: Asset deployment logic (not included)
- Position Managers: NFT position management (not included)

### For Integrators

```solidity
// Basic integration example
interface ILicredity {
    function open() external returns (uint256 positionId);
    function unlock(bytes calldata data) external returns (bytes memory);
    function seize(uint256 positionId, address recipient) external returns (uint256);
}
```

## 📁 Repository Structure

```
├── src/
│ ├── Licredity.sol # Main protocol contract
│ ├── BaseERC20.sol # Debt token implementation
│ ├── BaseHooks.sol # Uniswap v4 hooks
│ ├── RiskConfigs.sol # Risk management
│ ├── interfaces/ # Contract interfaces
│ ├── libraries/ # Utility libraries
│ └── types/ # Custom type definitions
├── test/ # Test suite
├── dependencies/ # External dependencies
└── docs/ # Documentation and licenses
```

## 🤝 Contributing

Licredity v1 Core is built in public. We appreciate meaningful feedback and contributions.

### Development Process

1. Fork the repository
2. Create a feature branch
3. Write tests for new functionality
4. Ensure all tests pass: forge test
5. Submit a pull request

### Code Style

- Follow existing Solidity patterns
- Add comprehensive tests
- Document complex logic
- Use assembly judiciously for gas optimization

## 📄 License

This project is dual-licensed:

- BUSL-1.1: Core protocol functionality
- MIT: Utility libraries and interfaces

See the header of each file for its specific license. The BUSL-1.1 licensed code converts to MIT after 2028.

## 🔗 Links

- https://docs.licredity.com (coming soon)
- https://whitepaper.licredity.com (coming soon)
- https://x.com/licredity

---

⚠️ Disclaimer: This software is in development and has not been audited. Use at your own risk.
