// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Fungible} from "../types/Fungible.sol";
import {NonFungible} from "../types/NonFungible.sol";

/// @title ILicredity
/// @notice Interface for the Licredity contract
interface ILicredity {
    /// @notice Error thrown when trying attach hooks to more than one pool
    error NotMultiPoolHooks();
    /// @notice Error thrown when an unexpected non-zero value is received
    error NonZeroNativeValue();
    /// @notice Error thrown when a position does not exist
    error PositionDoesNotExist();
    /// @notice Error thrown when the caller is not owner of the position
    error NotPositionOwner();
    /// @notice Error thrown when a position is not empty
    error PositionNotEmpty();
    /// @notice Error thrown when a non-fungible is already owned
    error NonFungibleAlreadyOwned();
    /// @notice Error thrown when a non-fungible is not owned
    error NonFungibleNotOwned();
    /// @notice Error thrown when a non-fungible is not in the position
    error NonFungibleNotInPosition();
    /// @notice Error thrown when a position is healthy
    error PositionIsHealthy();
    /// @notice Error thrown when a position is at risk
    error PositionIsAtRisk();
    /// @notice Error thrown when staged fungible is unexpected
    error UnexpectedStagedFungible();
    /// @notice Error thrown when staged balance is unexpected
    error UnexpectedStagedFungibleBalance();

    /// @notice Event emitted when a new position is opened
    /// @param positionId The ID of the newly opened position
    /// @param owner The owner of the position
    event OpenPosition(uint256 indexed positionId, address indexed owner);

    /// @notice Event emitted when a position is closed
    /// @param positionId The ID of the closed position
    event ClosePosition(uint256 indexed positionId);

    /// @notice Event emitted when a fungible is deposited to a position
    /// @param positionId The ID of the position to which the fungible is deposited
    /// @param fungible The fungible that is deposited
    /// @param amount The amount of fungible that is deposited
    event DepositFungible(uint256 indexed positionId, Fungible indexed fungible, uint256 amount);

    /// @notice Event emitted when a non-fungible is deposited to a position
    /// @param positionId The ID of the position to which the non-fungible is deposited
    /// @param nonFungible The non-fungible that is deposited
    event DepositNonFungible(uint256 indexed positionId, NonFungible indexed nonFungible);

    /// @notice Event emitted when a fungible is withdrawn from a position
    /// @param positionId The ID of the position from which the fungible is withdrawn
    /// @param fungible The fungible that is withdrawn
    /// @param recipient The recipient of the fungible withdrawn
    /// @param amount The amount of fungible that is withdrawn
    event WithdrawFungible(
        uint256 indexed positionId, Fungible indexed fungible, address indexed recipient, uint256 amount
    );

    /// @notice Event emitted when a non-fungible is withdrawn from a position
    /// @param positionId The ID of the position from which the non-fungible is withdrawn
    /// @param nonFungible The non-fungible that is withdrawn
    /// @param recipient The recipient of the non-fungible withdrawn
    event WithdrawNonFungible(uint256 indexed positionId, NonFungible indexed nonFungible, address indexed recipient);

    /// @notice Event emitted when debt is added to a position
    /// @param positionId The ID of the position to which debt is added
    /// @param recipient The recipient of the debt token
    /// @param share The share of debt added
    /// @param amount The amount of debt token received
    event AddDebt(uint256 indexed positionId, address indexed recipient, uint256 share, uint256 amount);

    /// @notice Event emitted when debt is removed from a position
    /// @param positionId The ID of the position from which debt is removed
    /// @param share The share of debt removed
    /// @param amount The amount of debt token given back
    /// @param useBalance Whether to use the balance of the debt token in the position
    event RemoveDebt(uint256 indexed positionId, uint256 share, uint256 amount, bool useBalance);

    /// @notice Event emitted when a position is seized
    /// @param positionId The ID of the seized position
    /// @param recipient The recipient of the seized position
    /// @param shortfall The amount needed to make the position healthy
    event SeizePosition(uint256 indexed positionId, address indexed recipient, uint256 shortfall);

    /// @notice Event emitted when debt fungible is exchanged for base fungible
    /// @param recipient The recipient of the exchanged base fungible
    /// @param debtAmountIn The amount of debt fungible exchanged
    /// @param baseAmountOut The amount of base fungible received
    event Exchange(address indexed recipient, uint256 debtAmountIn, uint256 baseAmountOut);

    /// @notice Function to unlock the Licredity contract
    /// @param data The data to be passed to the unlock callback
    /// @return result The result returned from the unlock callback
    function unlock(bytes calldata data) external returns (bytes memory result);

    /// @notice Function to open a new position
    /// @return positionId The ID of the newly opened position
    function open() external returns (uint256 positionId);

    /// @notice Function to close an existing position
    /// @param positionId The ID of the position to close
    function close(uint256 positionId) external;

    /// @notice Function to stage a fungible for exchange or deposit
    /// @param fungible The fungible to stage
    function stageFungible(Fungible fungible) external;

    /// @notice Function to exchange staged debt fungible for base fungible
    /// @param recipient The recipient of the exchanged base fungible
    function exchangeFungible(address recipient) external;

    /// @notice Function to deposit the staged fungible received to a position
    /// @param positionId The ID of the position to deposit to
    function depositFungible(uint256 positionId) external payable;

    /// @notice Function to withdraw fungible from a position
    /// @param positionId The ID of the position to withdraw from
    /// @param fungible The fungible to withdraw
    /// @param amount The amount of fungible to withdraw
    /// @param recipient The recipient of the fungible withdrawn
    function withdrawFungible(uint256 positionId, Fungible fungible, uint256 amount, address recipient) external;

    /// @notice Function to stage a non-fungible for deposit
    /// @param nonFungible The non-fungible to stage
    function stageNonFungible(NonFungible nonFungible) external;

    /// @notice Function to deposit the staged non-fungible received to a position
    /// @param positionId The ID of the position to deposit to
    function depositNonFungible(uint256 positionId) external;

    /// @notice Function to withdraw a non-fungible from a position
    /// @param positionId The ID of the position to withdraw from
    /// @param nonFungible The non-fungible to withdraw
    /// @param recipient The recipient of the non-fungible withdrawn
    function withdrawNonFungible(uint256 positionId, NonFungible nonFungible, address recipient) external;

    /// @notice Function to add debt to a position
    /// @param positionId The ID of the position to add to
    /// @param share The share of debt to add
    /// @param recipient The recipient of debt token
    /// @return amount The amount of debt token received
    function addDebt(uint256 positionId, uint256 share, address recipient) external returns (uint256 amount);

    /// @notice Function to remove debt from a position
    /// @param positionId The ID of the position to remove from
    /// @param share The share of debt to remove
    /// @param useBalance Whether to use the balance of the debt token in the position
    /// @return amount The amount of debt token given back
    function removeDebt(uint256 positionId, uint256 share, bool useBalance) external returns (uint256 amount);

    /// @notice Function to seize an at risk or underwater position
    /// @param positionId The ID of the position to seize
    /// @param recipient The recipient of the seized position
    /// @return shortfall The amount needed to make the position healthy
    function seize(uint256 positionId, address recipient) external returns (uint256 shortfall);
}
