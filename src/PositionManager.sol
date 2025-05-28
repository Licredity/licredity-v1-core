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
    function mintPosition() external returns (uint256 positionId) {
        // TODO: implement
    }

    /// @inheritdoc IPositionManager
    function burnPosition(uint256 positionId) external {
        // TODO: implement
    }

    /// @inheritdoc IPositionManager
    function depositFungible(uint256 positionId, Fungible fungible, uint256 amount) external payable {
        // TODO: implement
    }

    /// @inheritdoc IPositionManager
    function depositNonFungible(uint256 positionId, NonFungible nonFungible, uint256 tokenId) external {
        // TODO: implement
    }

    /// @inheritdoc IPositionManager
    function withdrawFungible(uint256 positionId, Fungible fungible, uint256 amount, address recipient) external {
        // TODO: implement
    }

    /// @inheritdoc IPositionManager
    function withdrawNonFungible(uint256 positionId, NonFungible nonFungible, uint256 tokenId, address recipient)
        external
    {
        // TODO: implement
    }

    /// @inheritdoc IPositionManager
    function mintDebt(uint256 positionId, uint256 share, address originator, address recipient)
        external
        returns (uint256 amount)
    {
        // TODO: implement
    }

    /// @inheritdoc IPositionManager
    function burnDebt(uint256 positionId, uint256 share) external returns (uint256 amount) {
        // TODO: implement
    }

    /// @inheritdoc IPositionManager
    function seizePosition(uint256 positionId, address recipient) external returns (uint256 deficit) {
        // TODO: implement
    }
}
