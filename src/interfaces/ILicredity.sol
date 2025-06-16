// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Fungible} from "../types/Fungible.sol";
import {NonFungible} from "../types/NonFungible.sol";

/// @title ILicredity
/// @notice Interface for the Licredity contract
interface ILicredity {
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
    function exchangeFungible(address recipient) external;

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
}
