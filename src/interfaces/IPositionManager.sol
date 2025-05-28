// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Fungible} from "../types/Fungible.sol";
import {NonFungible} from "../types/NonFungible.sol";

/// @title IPositionManager
/// @notice Interface for the position manager contract
interface IPositionManager {
    /// @notice Function to unlock the position manager
    /// @param data The data to be passed to the unlock callback
    /// @return result The result returned from the unlock callback
    function unlock(bytes calldata data) external returns (bytes memory result);

    /// @notice Function to open a new position
    /// @param originator The originator of the position
    /// @return positionId The ID of the newly opened position
    function openPosition(address originator) external returns (uint256 positionId);

    /// @notice Function to close an existing position
    /// @param positionId The ID of the position to close
    function closePosition(uint256 positionId) external;

    /// @notice Function to stage a fungible for settlement
    /// @param fungible The fungible to stage
    function stageFungible(Fungible fungible) external;

    /// @notice Function to settle the staged fungible to a position
    /// @param positionId The ID of the position to settle to
    /// @return amount The amount of fungible settled
    function settleFungible(uint256 positionId) external returns (uint256 amount);

    /// @notice Function to take some fungible from a position
    /// @param positionId The ID of the position to take from
    /// @param fungible The fungible to take
    /// @param amount The amount of fungible to take
    /// @param recipient The recipient of the fungible taken
    function takeFungible(uint256 positionId, Fungible fungible, uint256 amount, address recipient) external;

    /// @notice Function to stage a non-fungible token for settlement
    /// @param nonFungible The non-fungible to stage
    /// @param tokenId The ID of the token to stage
    function stageNonFungible(NonFungible nonFungible, uint256 tokenId) external;

    /// @notice Function to settle the staged non-fungible token to a position
    /// @param positionId The ID of the position to settle to
    function settleNonFungible(uint256 positionId) external;

    /// @notice Function to take a non-fungible token from a position
    /// @param positionId The ID of the position to take from
    /// @param nonFungible The non-fungible to take
    /// @param tokenId The ID of the token to take
    /// @param recipient The recipient of the non-fungible token taken
    function takeNonFungible(uint256 positionId, NonFungible nonFungible, uint256 tokenId, address recipient)
        external;

    /// @notice Function to add debt to a position
    /// @param positionId The ID of the position to add to
    /// @param share The share of debt to add
    /// @param recipient The recipient of the debt added
    /// @return amount The amount of debt added
    function addDebt(uint256 positionId, uint256 share, address recipient) external returns (uint256 amount);

    /// @notice Function to remove debt from a position
    /// @param positionId The ID of the position to remove from
    /// @param share The share of debt to remove
    /// @return amount The amount of debt removed
    function removeDebt(uint256 positionId, uint256 share) external returns (uint256 amount);

    /// @notice Function to seize an unhealthy position
    /// @param positionId The ID of the position to seize
    /// @param recipient The recipient of the seized position
    /// @return deficit The amount of deficit accrued in the seized position
    function seizePosition(uint256 positionId, address recipient) external returns (uint256 deficit);
}
