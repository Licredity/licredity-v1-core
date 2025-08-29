// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Fungible} from "../types/Fungible.sol";
import {NonFungible} from "../types/NonFungible.sol";
import {IExtsload} from "./IExtsload.sol";
import {IRiskConfigs} from "./IRiskConfigs.sol";

/// @title ILicredity
/// @notice Interface for the Licredity contract
interface ILicredity is IExtsload, IRiskConfigs {
    //////////////////////////////
    //        Errors            //
    //////////////////////////////

    error PositionDoesNotExist();
    error NotPositionOwner();
    error PositionIsUnhealthy();
    error PositionIsHealthy();
    error PositionNotEmpty();
    error NonFungibleAlreadyOwned();
    error NonFungibleNotOwned();
    error NonFungibleNotInPosition();
    error MaxFungiblesExceeded();
    error MaxNonFungiblesExceeded();
    error NotBaseFungible();
    error NotDebtFungible();
    error AmountOutstandingExceeded();
    error NonZeroNativeValue();
    error DebtLimitExceeded();
    error CannotSeizeRegisteredPosition();
    error MinLiquidityLifespanNotMet();
    error ZeroAddressNotAllowed();

    //////////////////////////////
    //        Events            //
    //////////////////////////////

    /// @notice Emitted when a position has been opened
    /// @param positionId The ID of the position
    /// @param owner The owner of the position
    event OpenPosition(uint256 indexed positionId, address indexed owner);

    /// @notice Emitted when a position has been closed
    /// @param positionId The ID of the position
    event ClosePosition(uint256 indexed positionId);

    /// @notice Emitted when a debt-for-base exchange has occurred
    /// @param recipient The recipient of the base fungible
    /// @param baseForDebt Whether the exchange is base fungible for debt fungible
    /// @param debtAmountIn The amount of debt fungible exchanged
    /// @param baseAmountOut The amount of base fungible received
    event Exchange(address indexed recipient, bool indexed baseForDebt, uint256 debtAmountIn, uint256 baseAmountOut);

    /// @notice Emitted when a fungible has been deposited into a position
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

    //////////////////////////////
    //        Functions         //
    //////////////////////////////

    /// @notice Unlocks the Licredity contract
    /// @param data The data to be passed to the unlock callback
    /// @return result The result returned from the unlock callback
    function unlock(bytes calldata data) external returns (bytes memory result);

    /// @notice Opens a new position
    /// @return positionId The ID of the newly opened position
    function open() external returns (uint256 positionId);

    /// @notice Closes an existing position
    /// @param positionId The ID of the position to be closed
    function close(uint256 positionId) external;

    /// @notice Stages a fungible for exchange or deposit
    /// @param fungible The fungible to be staged
    function stageFungible(Fungible fungible) external;

    /// @notice Exchanges staged debt fungible for base fungible
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
    function seize(uint256 positionId, address recipient) external returns (uint256 shortfall);
}
