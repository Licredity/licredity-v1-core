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

    /// @notice Function to mint a new position
    /// @return positionId The ID of the newly minted position
    function mintPosition() external returns (uint256 positionId);

    /// @notice Function to burn an existing position
    /// @param positionId The ID of the position to burn
    function burnPosition(uint256 positionId) external;

    /// @notice Function to deposit fungible assets into a position
    /// @param positionId The ID of the position to deposit into
    /// @param fungible The fungible asset to deposit
    /// @param amount The amount of the fungible asset to deposit
    /// @dev This function is payable to allow for ETH deposits if the fungible asset is ETH
    function depositFungible(uint256 positionId, Fungible fungible, uint256 amount) external payable;

    /// @notice Function to deposit non-fungible assets into a position
    /// @param positionId The ID of the position to deposit into
    /// @param nonFungible The non-fungible asset to deposit
    /// @param tokenId The ID of the non-fungible token to deposit
    function depositNonFungible(uint256 positionId, NonFungible nonFungible, uint256 tokenId) external;

    /// @notice Function to withdraw fungible assets from a position
    /// @param positionId The ID of the position to withdraw from
    /// @param fungible The fungible asset to withdraw
    /// @param amount The amount of the fungible asset to withdraw
    /// @param recipient The address to receive the withdrawn fungible asset
    function withdrawFungible(uint256 positionId, Fungible fungible, uint256 amount, address recipient) external;

    /// @notice Function to withdraw non-fungible assets from a position
    /// @param positionId The ID of the position to withdraw from
    /// @param nonFungible The non-fungible asset to withdraw
    /// @param tokenId The ID of the non-fungible token to withdraw
    /// @param recipient The address to receive the withdrawn non-fungible asset
    function withdrawNonFungible(uint256 positionId, NonFungible nonFungible, uint256 tokenId, address recipient)
        external;

    /// @notice Function to mint debt for a position
    /// @param positionId The ID of the position to mint debt for
    /// @param share The share of the debt to mint
    /// @param originator The address that originated the minted debt
    /// @param recipient The address to receive the minted debt
    /// @return amount The amount of debt minted
    function mintDebt(uint256 positionId, uint256 share, address originator, address recipient)
        external
        returns (uint256 amount);

    /// @notice Function to burn debt for a position
    /// @param positionId The ID of the position to burn debt for
    /// @param share The share of the debt to burn
    /// @return amount The amount of debt burned
    function burnDebt(uint256 positionId, uint256 share) external returns (uint256 amount);

    /// @notice Function to seize an unhealthy position
    /// @param positionId The ID of the position to seize
    /// @param recipient The address to receive the seized position
    /// @return deficit The amount of deficit accrued in the seized position
    function seizePosition(uint256 positionId, address recipient) external returns (uint256 deficit);
}
