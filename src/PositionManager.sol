// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.30;

import {IPositionManager} from "./interfaces/IPositionManager.sol";
import {Fungible} from "./types/Fungible.sol";
import {NonFungible} from "./types/NonFungible.sol";

/// @title PositionManager
/// @notice Implementation of the IPositionManager interface
contract PositionManager is IPositionManager {
    /// @inheritdoc IPositionManager
    function unlock(bytes calldata data) external returns (bytes memory result) {
        // TODO: require locked
        // TODO: unlock

        // TODO: invoke unlock callback and assign result

        // TODO: ensure every modified position is healthy
        // TODO: lock
    }

    /// @inheritdoc IPositionManager
    function openPosition() external returns (uint256 positionId) {
        // TODO: initialize a new position with id == ++positionCount, owner == msg.sender

        // TODO: emit OpenPosition event
    }

    /// @inheritdoc IPositionManager
    function closePosition(uint256 positionId) external {
        // TODO: require position owner is msg.sender
        // TODO: require empty position

        // TODO: delete position from storage

        // TODO: emit ClosePosition event
    }

    /// @inheritdoc IPositionManager
    function stageFungible(Fungible fungible) external {
        // TODO: transiently store fungible
        // TODO: if fungible is not native, transiently store balance
    }

    /// @inheritdoc IPositionManager
    function exchangeFungible(address recipient) external {
        // TODO: require staged fungible is debt fungible
        // TODO: calculate amount of debt fungible received
        // TODO: require received == excess

        // TODO: burn excess debt fungible
        // TODO: transfer base fungible balance to recipient

        // TODO: emit ExchangeFungible event
    }

    /// @inheritdoc IPositionManager
    function settleFungible(uint256 positionId) external payable returns (uint256 amount) {
        // TODO: require position exists

        // TODO: calculate amount of staged fungible received
        // TODO: increase position fungible balance by amount

        // TODO: emit SettleFungible event
    }

    /// @inheritdoc IPositionManager
    function takeFungible(uint256 positionId, Fungible fungible, uint256 amount, address recipient) external {
        // TODO: require position owner == msg.sender
        // TODO: require position fungible balance >= amount

        // TODO: add position to health check list
        // TODO: decrease position fungible balance by amount
        // TODO: transfer fungible balance to recipient

        // TODO: emit TakeFungible event
    }

    /// @inheritdoc IPositionManager
    function stageNonFungible(NonFungible nonFungible) external {
        // TODO: require nonFungible's owner is not this contract

        // TODO: transiently store fungible
    }

    /// @inheritdoc IPositionManager
    function settleNonFungible(uint256 positionId) external {
        // TODO: require position exists
        // TODO: require staged nonFungible's owner is this contract

        // TODO: add nonFungible to the position

        // TODO: emit SettleNonFungible event
    }

    /// @inheritdoc IPositionManager
    function takeNonFungible(uint256 positionId, NonFungible nonFungible, address recipient) external {
        // TODO: require position owner == msg.sender
        // TODO: require position nonFungible contains nonFungible

        // TODO: add position to health check list
        // TODO: remove nonFungible from the position
        // TODO: transfer nonFungible to recipient

        // TODO: emit TakeNonFungible event
    }

    /// @inheritdoc IPositionManager
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

    /// @inheritdoc IPositionManager
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

    /// @inheritdoc IPositionManager
    function seizePosition(uint256 positionId, address recipient) external returns (uint256 deficit) {
        // TODO: require position is unhealthy

        // TODO: calculate deficit
        // TODO: if any then mint 2x to this contract, increase position debt fungible balance, and increase global debt fungible amount
        // TODO: position owner == recipient

        // TODO: emit SeizePosition event
    }
}
