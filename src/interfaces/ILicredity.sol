// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Fungible} from "../types/Fungible.sol";
import {NonFungible} from "../types/NonFungible.sol";

/// @title ILicredity
/// @notice Interface for the Licredity contract
interface ILicredity {
    /// @notice Error thrown when an unexpected non-zero value is received
    error NonZeroNativeValue();
    /// @notice Error thrown when a position does not exist
    /// @param positionId The ID of the position that does not exist
    error PositionDoesNotExist(uint256 positionId);
    /// @notice Error thrown when the caller is not owner of the position
    error NotPositionOwner();
    /// @notice Error thrown when a position is not empty
    error PositionNotEmpty();

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
    /// @return amount The amount of debt token given back
    function removeDebt(uint256 positionId, uint256 share) external returns (uint256 amount);

    /// @notice Function to seize an unhealthy position
    /// @param positionId The ID of the position to seize
    /// @param recipient The recipient of the seized position
    /// @return deficit The amount of deficit accrued in the seized position
    function seize(uint256 positionId, address recipient) external returns (uint256 deficit);
}
