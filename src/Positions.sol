// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.30;

import {IPositions} from "./interfaces/IPositions.sol";
import {Fungible} from "./types/Fungible.sol";
import {NonFungible} from "./types/NonFungible.sol";

/// @title Positions
/// @notice Abstract implementation of the IPositions interface
abstract contract Positions is IPositions {
    /// @inheritdoc IPositions
    function open() external returns (uint256 positionId) {
        // TODO: initialize a new position with id == ++positionCount, owner == msg.sender

        // TODO: emit OpenPosition event
    }

    /// @inheritdoc IPositions
    function close(uint256 positionId) external {
        // TODO: require position owner is msg.sender
        // TODO: require empty position

        // TODO: delete position from storage

        // TODO: emit ClosePosition event
    }

    /// @inheritdoc IPositions
    function stageFungible(Fungible fungible) external {
        // TODO: transiently store fungible
        // TODO: if fungible is not native, transiently store balance
    }

    /// @inheritdoc IPositions
    function exchangeFungible(address recipient) external {
        // TODO: require staged fungible is debt fungible
        // TODO: calculate amount of debt fungible received
        // TODO: require received == excess

        // TODO: burn excess debt fungible
        // TODO: transfer base fungible balance to recipient

        // TODO: emit ExchangeFungible event
    }

    /// @inheritdoc IPositions
    function settleFungible(uint256 positionId) external payable returns (uint256 amount) {
        // TODO: require position exists

        // TODO: calculate amount of staged fungible received
        // TODO: increase position fungible balance by amount

        // TODO: emit SettleFungible event
    }

    /// @inheritdoc IPositions
    function takeFungible(uint256 positionId, Fungible fungible, uint256 amount, address recipient) external {
        // TODO: require position owner == msg.sender
        // TODO: require position fungible balance >= amount

        // TODO: add position to health check list
        // TODO: decrease position fungible balance by amount
        // TODO: transfer fungible balance to recipient

        // TODO: emit TakeFungible event
    }

    /// @inheritdoc IPositions
    function stageNonFungible(NonFungible nonFungible) external {
        // TODO: require nonFungible's owner is not this contract

        // TODO: transiently store fungible
    }

    /// @inheritdoc IPositions
    function settleNonFungible(uint256 positionId) external {
        // TODO: require position exists
        // TODO: require staged nonFungible's owner is this contract

        // TODO: add nonFungible to the position

        // TODO: emit SettleNonFungible event
    }

    /// @inheritdoc IPositions
    function takeNonFungible(uint256 positionId, NonFungible nonFungible, address recipient) external {
        // TODO: require position owner == msg.sender
        // TODO: require position nonFungible contains nonFungible

        // TODO: add position to health check list
        // TODO: remove nonFungible from the position
        // TODO: transfer nonFungible to recipient

        // TODO: emit TakeNonFungible event
    }

    /// @inheritdoc IPositions
    function addDebt(uint256 positionId, uint256 share, address recipient) external returns (uint256 amount) {
        // TODO: require position owner == msg.sender

        // TODO: add position to health check list
        // TODO: calculate amount of debt fungible to add
        // TODO: increase position debt share
        // TODO: increase position debt fungible balance by amount
        // TODO: increase global debt share and amount
        // TODO: mint debt fungible to recipient

        // TODO: emit AddDebt event
    }

    /// @inheritdoc IPositions
    function removeDebt(uint256 positionId, uint256 share) external returns (uint256 amount) {
        // TODO: require position exists
        // TODO: require share <= position debt share

        // TODO: calculate amount of debt fungible to remove
        // TODO: burn debt fungible from this contract
        // TODO: decrease global debt share and amount
        // TODO: decrease position debt fungible balance by amount
        // TODO: decrease position debt share

        // TODO: emit RemoveDebt event
    }

    /// @inheritdoc IPositions
    function seize(uint256 positionId, address recipient) external returns (uint256 deficit) {
        // TODO: require position is unhealthy

        // TODO: calculate deficit
        // TODO: if any then mint 2x to this contract, increase position debt fungible balance, and increase global debt fungible amount
        // TODO: position owner == recipient

        // TODO: emit SeizePosition event
    }
}
