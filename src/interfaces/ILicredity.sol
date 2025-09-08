// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@forge-std/interfaces/IERC20.sol";
import {IERC721TokenReceiver} from "@forge-std/interfaces/IERC721.sol";
import {IHooks} from "@uniswap-v4-core/interfaces/IHooks.sol";
import {Fungible} from "../types/Fungible.sol";
import {NonFungible} from "../types/NonFungible.sol";
import {IExtsload} from "./IExtsload.sol";
import {IRiskConfigs} from "./IRiskConfigs.sol";

/// @title ILicredity
/// @notice Interface for the core functionalities of the protocol
interface ILicredity is IHooks, IERC20, IRiskConfigs, IExtsload, IERC721TokenReceiver {
    /// @notice Thrown when the Licredity contract address is not valid
    error LicredityAddressNotValid();

    /// @notice Thrown when a zero address is used
    error ZeroAddressNotAllowed();

    /// @notice Thrown when a delegate call is attempted
    error DelegateCallNotAllowed();

    /// @notice Thrown when the locker is already unlocked
    error LockerAlreadyUnlocked();

    /// @notice Thrown when the locker is already locked
    error LockerAlreadyLocked();

    /// @notice Thrown when the locker is not unlocked
    error LockerNotUnlocked();

    /// @notice Thrown when full precision mul div fails
    error FullMulDivFailed();

    /// @notice Thrown when full precision mul div with rounding up fails
    error FullMulDivUpFailed();

    /// @notice Thrown when pips multiplication with rounding up fails
    error PipsMulUpFailed();

    /// @notice Thrown when interest rate multiplication fails
    error InterestRateMulFailed();

    /// @notice Thrown when the caller is not the pool manager
    error NotPoolManager();

    /// @notice Thrown when an unimplemented hook is called
    error HookNotImplemented();

    /// @notice Thrown when a native transfer fails
    error NativeTransferFailed();

    /// @notice Thrown when an ERC20 transfer fails
    error ERC20TransferFailed();

    /// @notice Thrown when an ERC20 allowance is exceeded
    error ERC20AllowanceExceeded();

    /// @notice Thrown when max index is exceeded
    error MaxFungibleIndexExceeded();

    /// @notice Thrown when max balance is exceeded
    error MaxFungibleBalanceExceeded();

    /// @notice Thrown when a non-fungible token is not found
    error NonFungibleNotFound();

    /// @notice Thrown when the caller is not the position owner
    error NotPositionOwner();

    /// @notice Thrown when a position is not healthy
    error PositionNotHealthy();

    /// @notice Thrown when a position is not empty
    error PositionNotEmpty();

    /// @notice Thrown when a fungible is not the base fungible
    error NotBaseFungible();

    /// @notice Thrown when a fungible is not the debt fungible
    error NotDebtFungible();

    /// @notice Thrown when the exchangeable amount is exceeded
    error ExchangeableAmountExceeded();

    /// @notice Thrown when the native value sent is not zero
    error NativeValueNotZero();

    /// @notice Thrown when max fungibles per position is exceeded
    error MaxFungiblesExceeded();

    /// @notice Thrown when a non-fungible is already owned
    error NonFungibleAlreadyOwned();

    /// @notice Thrown when a non-fungible is not owned
    error NonFungibleNotOwned();

    /// @notice Thrown when max non-fungibles per position is exceeded
    error MaxNonFungiblesExceeded();

    /// @notice Thrown when the debt limit is exceeded
    error DebtLimitExceeded();

    /// @notice Thrown when seizing a registered position is attempted
    error RegisteredPositionCannotBeSeized();

    /// @notice Thrown when a position is healthy
    error PositionIsHealthy();

    /// @notice Thrown when the sender is not the Licredity contract
    error NotLicredity();

    /// @notice Thrown when the minimum liquidity lifespan is not met
    error MinLiquidityLifespanNotMet();

    /// @notice Thrown when the price is too low
    error PriceTooLow();

    /// @notice Emitted when a position has been opened
    /// @param positionId The ID of the position
    /// @param owner The owner of the position
    event OpenPosition(uint256 indexed positionId, address indexed owner);

    /// @notice Emitted when a position has been closed
    /// @param positionId The ID of the position
    event ClosePosition(uint256 indexed positionId);

    /// @notice Emitted when exchange between base fungible and debt fungible has occurred
    /// @param recipient The recipient of the base fungible
    /// @param baseForDebt Whether the exchange is base fungible for debt fungible
    /// @param amount The amount of fungible exchanged
    event ExchangeFungible(address indexed recipient, bool indexed baseForDebt, uint256 amount);

    /// @notice Emitted when a fungible has been deposited into a positiont
    /// @param positionId The ID of the position
    /// @param fungible The fungible deposited
    /// @param amount The amount of fungible deposited
    event DepositFungible(uint256 indexed positionId, Fungible indexed fungible, uint256 amount);

    /// @notice Emitted when a fungible has been withdrawn from a position
    /// @param positionId The ID of the position
    /// @param recipient The recipient of the withdrawal
    /// @param fungible The fungible withdrawn
    /// @param amount The amount of fungible withdrawn
    event WithdrawFungible(
        uint256 indexed positionId, address indexed recipient, Fungible indexed fungible, uint256 amount
    );

    /// @notice Emitted when a non-fungible has been deposited into a position
    /// @param positionId The ID of the position
    /// @param nonFungible The non-fungible deposited
    event DepositNonFungible(uint256 indexed positionId, NonFungible indexed nonFungible);

    /// @notice Emitted when a non-fungible has been withdrawn from a position
    /// @param positionId The ID of the position
    /// @param recipient The recipient of the withdrawal
    /// @param nonFungible The non-fungible withdrawn
    event WithdrawNonFungible(uint256 indexed positionId, address indexed recipient, NonFungible indexed nonFungible);

    /// @notice Emitted when the debt share in a position has been increased
    /// @param positionId The ID of the position
    /// @param recipient The recipient of the debt fungible
    /// @param delta The delta of debt shares increased by
    /// @param amount The amount of debt fungible received
    event IncreaseDebtShare(uint256 indexed positionId, address indexed recipient, uint256 delta, uint256 amount);

    /// @notice Emitted when the debt share in a position has been decreased
    /// @param positionId The ID of the position
    /// @param useBalance Whether to use the balance of debt fungible in the position
    /// @param delta The delta of debt shares decreased by
    /// @param amount The amount of debt fungible given back
    event DecreaseDebtShare(uint256 indexed positionId, bool indexed useBalance, uint256 delta, uint256 amount);

    /// @notice Emitted when a position has been seized
    /// @param positionId The ID of the position
    /// @param recipient The recipient of the position
    /// @param value The value of the position post-seizure
    /// @param debt The debt of the position, post-seizure
    /// @param marginRequirement The margin requirement of the position
    /// @param topup The amount of debt fungible added to the position
    event SeizePosition(
        uint256 indexed positionId,
        address indexed recipient,
        uint256 value,
        uint256 debt,
        uint256 marginRequirement,
        uint256 topup
    );

    /// @notice Unlocks the Licredity contract
    /// @param data The data to be passed to the unlock callback
    /// @return result The result returned from the unlock callback
    function unlock(bytes calldata data) external returns (bytes memory result);

    /// @notice Opens a new position
    /// @return positionId The ID of the newly opened position
    function openPosition() external returns (uint256 positionId);

    /// @notice Closes an existing position
    /// @param positionId The ID of the position to be closed
    function closePosition(uint256 positionId) external;

    /// @notice Stages a fungible for exchange or deposit
    /// @param fungible The fungible to be staged
    function stageFungible(Fungible fungible) external;

    /// @notice Exchanges staged debt/base fungible for base/debt fungible
    /// @param recipient The recipient of the exchange
    /// @param baseForDebt Whether the exchange is base fungible for debt fungible
    function exchangeFungible(address recipient, bool baseForDebt) external payable;

    /// @notice Deposits staged fungible received into a position
    /// @param positionId The ID of the position to deposit into
    function depositFungible(uint256 positionId) external payable;

    /// @notice Withdraws amount of fungible from a position to a recipient
    /// @param positionId The ID of the position to withdraw from
    /// @param recipient The recipient of the withdrawal
    /// @param fungible The fungible to withdraw
    /// @param amount The amount of fungible to withdraw
    function withdrawFungible(uint256 positionId, address recipient, Fungible fungible, uint256 amount) external;

    /// @notice Stages a non-fungible for deposit
    /// @param nonFungible The non-fungible to be staged
    function stageNonFungible(NonFungible nonFungible) external;

    /// @notice Deposits staged non-fungible received into a position
    /// @param positionId The ID of the position to deposit into
    function depositNonFungible(uint256 positionId) external;

    /// @notice Withdraws a non-fungible from a position to a recipient
    /// @param positionId The ID of the position to withdraw from
    /// @param recipient The recipient of the withdrawal
    /// @param nonFungible The non-fungible to withdraw
    function withdrawNonFungible(uint256 positionId, address recipient, NonFungible nonFungible) external;

    /// @notice Increases the debt share in a position
    /// @param positionId The ID of the position to increase debt share in
    /// @param delta The number of debt shares to increase by
    /// @param recipient The recipient of the debt fungible
    /// @return amount The amount of debt fungible minted
    function increaseDebtShare(uint256 positionId, uint256 delta, address recipient)
        external
        returns (uint256 amount);

    /// @notice Decreases the debt share in a position
    /// @param positionId The ID of the position to decrease debt share in
    /// @param delta The number of debt shares to decrease by
    /// @param useBalance Whether to use debt fungible balance in the position
    function decreaseDebtShare(uint256 positionId, uint256 delta, bool useBalance) external returns (uint256 amount);

    /// @notice Seizes an unhealthy position
    /// @param positionId The ID of the position to seize
    /// @param recipient The recipient of the seized position
    /// @return shortfall The amount of debt fungible needed to bring the position back to health
    function seizePosition(uint256 positionId, address recipient) external returns (uint256 shortfall);
}
