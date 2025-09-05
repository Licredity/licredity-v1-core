# Licredity v1 Core

> **Permissionless, self-custodial credit protocol built on Uniswap v4**

Licredity is a next-generation credit protocol that enables borrowers to mint interest-bearing debt tokens against collateral and deploy them for leveraged positions. The protocol creates a symbiotic credit market where liquidity providers earn enhanced yields through proactive interest donations directly to Uniswap v4 pools.

## 🌟 Key Features

### Multi-Asset Collateral Support
- **ERC20 Tokens**: Support for fungible token collateral
- **ERC721 NFTs**: Support for non-fungible token collateral
- **Flexible Composition**: Mix different asset types within a single position

### Dynamic Interest Mechanics
- **Price-Responsive Rates**: Interest rates automatically adjust based on pool price dynamics
- **Real-Time Accrual**: Continuous interest calculation tied to market conditions
- **LP Yield Enhancement**: Interest donations directly boost Uniswap v4 liquidity provider returns

### Automated Risk Management
- **Health Monitoring**: Continuous position health tracking with configurable risk parameters
- **Multi-Layer Safeguards**: Comprehensive protection through risk parameters, health checks, and automated interventions
- **Liquidation System**: Automated seizure mechanism for unhealthy positions

### Uniswap v4 Integration
- **Native Hooks**: Deep integration with Uniswap v4 hook system
- **Interest Donations**: Direct interest flow to LP positions
- **Pool Synchronization**: Real-time pool state monitoring for interest calculations

## 🏗️ Architecture Overview

### Core Components

**Licredity Contract (`src/Licredity.sol`)**
- Main protocol contract implementing all core functionalities
- Inherits from BaseERC20 (debt token), BaseHooks (Uniswap v4), and governance contracts
- Manages positions, collateral, debt operations, and hook integration

**Position System (`src/types/Position.sol`)**
- Efficient storage-optimized position management
- Dynamic arrays for fungible and non-fungible collateral
- Maintains state consistency through index synchronization

**Type System**
- `Fungible`: Wrapper for ERC20 tokens with metadata
- `NonFungible`: Wrapper for ERC721 tokens
- `FungibleState`: Packed storage for balance and array position data
- `InterestRate`: Interest calculation utilities

**Libraries**
- `FullMath`: High-precision mathematical operations
- `PipsMath`: Price deviation and interest rate calculations
- `Locker`: Reentrancy protection and callback management

### Key Mechanisms

**Two-Step Operations**
Many critical operations use a staging pattern for enhanced security:
1. `stageFungible()` → `depositFungible()`
2. `stageNonFungible()` → `depositNonFungible()`

**Interest Collection**
Interest accrues during specific operations:
- Position unlocking (`unlock()`)
- Swapping operations
- Liquidity management (add/remove)

**Hook Integration**
The protocol implements Uniswap v4 hooks to:
- Donate accrued interest to liquidity providers
- Monitor pool price deviations
- Trigger interest rate adjustments

## 🚀 Getting Started

### Prerequisites

- [Foundry](https://book.getfoundry.sh/) - Ethereum development toolkit
- [Soldeer](https://soldeer.xyz/) - Dependency management

### Installation

```bash
# Clone the repository
git clone https://github.com/Licredity/licredity-v1-core.git
cd licredity-v1-core

# Install dependencies
forge soldeer install

# Build the project
forge build
```

### Testing

```bash
# Run all tests
forge test

# Run tests with verbosity
forge test -vvv

# Run specific test contract
forge test --match-contract LicredityUnlockPosition

# Generate coverage report
forge coverage
```

### Deployment

1. **Configure Environment**
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

2. **Deploy to Network**
   ```bash
   # Deploy using script
   forge script script/Deploy.s.sol --broadcast --rpc-url $RPC_URL
   ```

3. **Verify Contract** (optional)
   ```bash
   forge verify-contract <address> Licredity --etherscan-api-key $API_KEY
   ```

## 🛡️ Security & Audits

### Formal Verification
The protocol includes comprehensive formal verification using Certora Prover:

- **Valid State Invariants**: Core system consistency properties
- **State Transition Rules**: Correct operation sequencing
- **EIP-20 Compliance**: Debt token standard compliance

Run formal verification:
```bash
cd certora
certoraRun confs/licredity_valid_state_single.conf
```

### External Audits
- [**Cyfrin Audits**](/docs/audits/Cyfrin%202025-09-01.pdf) (2025-09)

### Known Considerations
- Heavy assembly usage for gas optimization - exercise caution when modifying storage operations
- Position array synchronization is critical - maintain consistency between arrays and mappings
- Interest accrual timing is sensitive to transaction ordering

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines
- Follow existing code style and patterns
- Add comprehensive tests for new features

## 📜 License

This project is licensed under the [MIT](/docs/licenses/MIT_LICENSE) and [Business Source License 1.1](/docs/licenses/BUSL_LICENSE).

## ⚠️ Disclaimer

This software is experimental and may contain bugs. Use at your own risk. The protocol involves financial risk and users should understand the mechanics before participating. Always review transactions carefully and never invest more than you can afford to lose.