// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Fungible} from "../types/Fungible.sol";
import {NonFungible} from "../types/NonFungible.sol";
import {IExtsload} from "../interfaces/IExtsload.sol";

/// @title ILicredity
/// @notice Interface for the Licredity contract
interface ILicredity is IExtsload {
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
    /// @return shortfall The amount of debt fungible required to make the position healthy
    function seize(uint256 positionId, address recipient) external returns (uint256 shortfall);
}
