# licredity-v1-core

Licredity is a permissionless, self-custodial credit protocol built on Uniswap v4. It allows borrowers to mint a larger amount of interest-bearing debt tokens against a smaller amount of collateral and then swap or deploy both for desired assets, while LPs earn enhanced yields through proactive interest donations.

Licredity v1 Core is built in public and we appreciate any meaningful feedback and contribution.

## Architecture

The `Licredity.sol` contract contains the core logic for managing leveraged positions - adding/removing collaterals, borrowing/repaying debt, and taking over at-risk position for profit. In general, only the position owner can modify their position, except in two cases:

- Anyone may supply debt tokens to reduce a position’s debt.
- Anyone may take over at-risk positions.

Each collateral asset has its own debt-bearing capacity, and a position’s health is determined by the weighted average of its assets. Operations that degrade a position’s health, such as increasing debt or reducing collateral, require an initial call to `unlock`. Multiple positions may be modified during a single `unlock`, but each must remain healthy by the end of the transaction.

Interest accrues continuously and is proactively donated to active LPs—before any repayments occur. As a result, the total supply of debt tokens in circulation closely reflects the total outstanding debt, including both principal and interest.

Additionally, `Licredity.sol` inheirts from several modules in the `src\` folder:

- **BaseERC20.sol**: An abstract `IERC20` implementation that provides debt token functionality.
- **BaseHooks.sol**: An abstract `IHooks` implementation for interacting with the Uniswap v4 base/debt token pool.
- **Extsload.sol**: An abstract contract that enables external sload operations.
- **RiskConfigs.sol**: An abstract contract for managing risk-related configurations.

Oracles (for pricing), routers (for asset deployment), and the NFT position manager (for approval and transfer of positions) are implemented externally and are not part of this repository.

## License

Licredity v1 Core is licensed under the Business Source License 1.1 (`BUSL-1.1`), see [BUSL_LICENSE](https://github.com/Licredity/licredity-v1-core/blob/main/docs/licenses/BUSL_LICENSE), and the MIT License (`MIT`), see [MIT_LICENSE](https://github.com/Licredity/licredity-v1-core/blob/main/docs/licenses/MIT_LICENSE). Each file in Licredity v1 Core states the applicable license type in the header.
