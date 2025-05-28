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
        // TODO: implement
    }

    /// @inheritdoc IPositionManager
    function openPosition(address originator) external returns (uint256 positionId) {
        // TODO: implement
    }

    /// @inheritdoc IPositionManager
    function closePosition(uint256 positionId) external {
        // TODO: implement
    }

    /// @inheritdoc IPositionManager
    function stageFungible(Fungible fungible) external {
        // TODO: implement
    }

    /// @inheritdoc IPositionManager
    function settleFungible(uint256 positionId) external returns (uint256 amount) {
        // TODO: implement
    }

    /// @inheritdoc IPositionManager
    function takeFungible(uint256 positionId, Fungible fungible, uint256 amount, address recipient) external {
        // TODO: implement
    }

    /// @inheritdoc IPositionManager
    function stageNonFungible(NonFungible nonFungible, uint256 tokenId) external {
        // TODO: implement
    }

    /// @inheritdoc IPositionManager
    function settleNonFungible(uint256 positionId) external {
        // TODO: implement
    }

    /// @inheritdoc IPositionManager
    function takeNonFungible(uint256 positionId, NonFungible nonFungible, uint256 tokenId, address recipient)
        external
    {
        // TODO: implement
    }

    /// @inheritdoc IPositionManager
    function addDebt(uint256 positionId, uint256 share, address recipient) external returns (uint256 amount) {
        // TODO: implement
    }

    /// @inheritdoc IPositionManager
    function removeDebt(uint256 positionId, uint256 share) external returns (uint256 amount) {
        // TODO: implement
    }

    /// @inheritdoc IPositionManager
    function seizePosition(uint256 positionId, address recipient) external returns (uint256 deficit) {
        // TODO: implement
    }
}
