// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.30;

import {IERC721TokenReceiver} from "@forge-std/interfaces/IERC721.sol";
import {ILicredity} from "./interfaces/ILicredity.sol";
import {Fungible} from "./types/Fungible.sol";
import {NonFungible} from "./types/NonFungible.sol";
import {BaseHooks} from "./BaseHooks.sol";
import {DebtToken} from "./DebtToken.sol";

contract Licredity is ILicredity, IERC721TokenReceiver, BaseHooks, DebtToken {
    constructor(address poolManager, string memory name, string memory symbol, uint8 decimals)
        BaseHooks(poolManager)
        DebtToken(name, symbol, decimals)
    {}

    /// @inheritdoc ILicredity
    function unlock(bytes calldata data) external returns (bytes memory result) {
        // TODO: require locked
        // TODO: unlock

        // TODO: invoke unlock callback and assign result

        // TODO: ensure every modified position is healthy
        // TODO: lock
    }

    /// @inheritdoc ILicredity
    function open() external returns (uint256 positionId) {
        // TODO: implement
    }

    /// @inheritdoc ILicredity
    function close(uint256 positionId) external {
        // TODO: implement
    }

    /// @inheritdoc ILicredity
    function stageFungible(Fungible fungible) external {
        // TODO: implement
    }

    /// @inheritdoc ILicredity
    function exchangeFungible(address recipient) external {
        // TODO: implement
    }

    /// @inheritdoc ILicredity
    function depositFungible(uint256 positionId) external payable {
        // TODO: implement
    }

    /// @inheritdoc ILicredity
    function withdrawFungible(uint256 positionId, Fungible fungible, uint256 amount, address recipient) external {
        // TODO: implement
    }

    /// @inheritdoc ILicredity
    function stageNonFungible(NonFungible nonFungible) external {
        // TODO: implement
    }

    /// @inheritdoc ILicredity
    function depositNonFungible(uint256 positionId) external {
        // TODO: implement
    }

    /// @inheritdoc ILicredity
    function withdrawNonFungible(uint256 positionId, NonFungible nonFungible, address recipient) external {
        // TODO: implement
    }

    /// @inheritdoc ILicredity
    function addDebt(uint256 positionId, uint256 share, address recipient) external returns (uint256 amount) {
        // TODO: implement
    }

    /// @inheritdoc ILicredity
    function removeDebt(uint256 positionId, uint256 share) external returns (uint256 amount) {
        // TODO: implement
    }

    /// @inheritdoc ILicredity
    function seize(uint256 positionId, address recipient) external returns (uint256 deficit) {
        // TODO: implement
    }

    /// @inheritdoc IERC721TokenReceiver
    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
