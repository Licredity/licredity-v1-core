// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.30;

import {IERC721TokenReceiver} from "@forge-std/interfaces/IERC721.sol";
import {ILicredity} from "./interfaces/ILicredity.sol";
import {BaseHooks} from "./BaseHooks.sol";
import {PED} from "./PED.sol";
import {Positions} from "./Positions.sol";

contract Licredity is ILicredity, IERC721TokenReceiver, BaseHooks, PED, Positions {
    constructor(address poolManager) BaseHooks(poolManager) {}

    /// @inheritdoc ILicredity
    function unlock(bytes calldata data) external returns (bytes memory result) {
        // TODO: require locked
        // TODO: unlock

        // TODO: invoke unlock callback and assign result

        // TODO: ensure every modified position is healthy
        // TODO: lock
    }

    /// @inheritdoc IERC721TokenReceiver
    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
