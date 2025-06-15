// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.30;

import {IERC721TokenReceiver} from "@forge-std/interfaces/IERC721.sol";
import {IPoolManager} from "@uniswap-v4-core/interfaces/IPoolManager.sol";
import {BalanceDelta} from "@uniswap-v4-core/types/BalanceDelta.sol";
import {BeforeSwapDelta} from "@uniswap-v4-core/types/BeforeSwapDelta.sol";
import {PoolKey} from "@uniswap-v4-core/types/PoolKey.sol";
import {ILicredity} from "./interfaces/ILicredity.sol";
import {IUnlockCallback} from "./interfaces/IUnlockCallback.sol";
import {Locker} from "./libraries/Locker.sol";
import {Fungible} from "./types/Fungible.sol";
import {Position} from "./types/Position.sol";
import {BaseHooks} from "./BaseHooks.sol";
import {CreditToken} from "./CreditToken.sol";
import {Extsload} from "./Extsload.sol";
import {RiskConfigs} from "./RiskConfigs.sol";

/// @title Licredity
/// @notice Provides the core functionalities of the Licredity protocol
contract Licredity is ILicredity, IERC721TokenReceiver, BaseHooks, CreditToken, Extsload, RiskConfigs {
    uint64 internal positionCount;
    mapping(uint256 => Position) internal positions;

    constructor(address baseToken, address _poolManager, address _governor, string memory name, string memory symbol)
        BaseHooks(_poolManager)
        RiskConfigs(_governor)
        CreditToken(name, symbol, Fungible.wrap(baseToken).decimals())
    {}

    /// @inheritdoc ILicredity
    function unlock(bytes calldata data) external override returns (bytes memory result) {
        Locker.unlock();

        result = IUnlockCallback(msg.sender).unlockCallback(data);

        bytes32[] memory items = Locker.registeredItems();
        for (uint256 i = 0; i < items.length; ++i) {
            Position storage position = positions[uint256(items[i])];

            // TODO: implement
        }

        Locker.lock();
    }

    /// @inheritdoc ILicredity
    function open() external returns (uint256 positionId) {
        positionId = ++positionCount;
        positions[positionId].setOwner(msg.sender);

        // emit OpenPosition(positionId, msg.sender);
        assembly ("memory-safe") {
            log3(0x00, 0x00, 0x3ffddb72d5a0bb21e612abf8887ea717fc463df82000825adeecd6558bf722e1, positionId, caller())
        }
    }

    /// @inheritdoc ILicredity
    function close(uint256 positionId) external {
        Position storage position = positions[positionId];
        if (position.owner != msg.sender) {
            assembly ("memory-safe") {
                mstore(0x00, 0x70d645e3) // 'NotPositionOwner()'
                revert(0x1c, 0x04)
            }
        }
        if (!position.isEmpty()) {
            assembly ("memory-safe") {
                mstore(0x00, 0x1acb203e) // 'PositionNotEmpty()'
                revert(0x1c, 0x04)
            }
        }

        delete positions[positionId];

        // emit ClosePosition(positionId);
        assembly ("memory-safe") {
            log2(0x00, 0x00, 0x76ea9b4ec8740d36765c806fad62b75c4418d245d5264e20b01f07ca9ef48b1c, positionId)
        }
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
    function withdrawFungible(uint256 positionId, Fungible fungible, address recipient, uint256 amount) external {
        // TODO: implement
    }

    /// @inheritdoc IERC721TokenReceiver
    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function _beforeInitialize(address, PoolKey calldata, uint160) internal override returns (bytes4) {
        // TODO: implement
    }

    function _beforeAddLiquidity(address, PoolKey calldata, IPoolManager.ModifyLiquidityParams calldata, bytes calldata)
        internal
        override
        returns (bytes4)
    {
        // TODO: implement
    }

    function _beforeRemoveLiquidity(
        address,
        PoolKey calldata,
        IPoolManager.ModifyLiquidityParams calldata,
        bytes calldata
    ) internal override returns (bytes4) {
        // TODO: implement
    }

    function _beforeSwap(address, PoolKey calldata, IPoolManager.SwapParams calldata, bytes calldata)
        internal
        override
        returns (bytes4, BeforeSwapDelta, uint24)
    {
        // TODO: implement
    }

    function _afterSwap(address, PoolKey calldata, IPoolManager.SwapParams calldata, BalanceDelta, bytes calldata)
        internal
        override
        returns (bytes4, int128)
    {
        // TODO: implement
    }
}
