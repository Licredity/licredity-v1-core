// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.30;

import {IERC721TokenReceiver} from "@forge-std/interfaces/IERC721.sol";
import {IHooks} from "@uniswap-v4-core/interfaces/IHooks.sol";
import {IPoolManager} from "@uniswap-v4-core/interfaces/IPoolManager.sol";
import {BalanceDelta} from "@uniswap-v4-core/types/BalanceDelta.sol";
import {BeforeSwapDelta} from "@uniswap-v4-core/types/BeforeSwapDelta.sol";
import {Currency} from "@uniswap-v4-core/types/Currency.sol";
import {PoolId} from "@uniswap-v4-core/types/PoolId.sol";
import {PoolKey} from "@uniswap-v4-core/types/PoolKey.sol";
import {ILicredity} from "./interfaces/ILicredity.sol";
import {IUnlockCallback} from "./interfaces/IUnlockCallback.sol";
import {Locker} from "./libraries/Locker.sol";
import {Fungible} from "./types/Fungible.sol";
import {NonFungible} from "./types/NonFungible.sol";
import {Position} from "./types/Position.sol";
import {BaseHooks} from "./BaseHooks.sol";
import {DebtToken} from "./DebtToken.sol";
import {Extsload} from "./Extsload.sol";
import {RiskConfigs} from "./RiskConfigs.sol";

/// @title Licredity
/// @notice Provides the core functionalities of the Licredity protocol
contract Licredity is ILicredity, IERC721TokenReceiver, BaseHooks, DebtToken, Extsload, RiskConfigs {
    uint24 private constant FEE = 100;
    int24 private constant TICK_SPACING = 1;
    uint160 private constant INITIAL_SQRT_PRICE_X96 = 0x1000000000000000000000000;

    Fungible internal transient stagedFungible;
    uint256 internal transient stagedFungibleBalance;
    NonFungible internal transient stagedNonFungible;

    Fungible internal immutable baseFungible;
    PoolKey internal poolKey;
    PoolId internal immutable poolId;
    uint64 internal positionCount;
    uint128 internal baseAmountAvailable;
    uint128 internal debtAmountOutstanding;
    mapping(uint256 => Position) internal positions;

    constructor(address baseToken, address _poolManager, address _governor, string memory name, string memory symbol)
        BaseHooks(_poolManager)
        DebtToken(name, symbol, Fungible.wrap(baseToken).decimals())
        RiskConfigs(_governor)
    {
        if (address(this) <= baseToken) {
            assembly ("memory-safe") {
                mstore(0x00, 0xe6c4247b) // 'InvalidAddress()'
                revert(0x1c, 0x04)
            }
        }

        baseFungible = Fungible.wrap(baseToken);

        poolKey =
            PoolKey(Currency.wrap(baseToken), Currency.wrap(address(this)), FEE, TICK_SPACING, IHooks(address(this)));
        poolId = poolKey.toId();
        poolManager.initialize(poolKey, INITIAL_SQRT_PRICE_X96);
    }

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
        stagedFungible = fungible;
        if (!fungible.isNative()) {
            stagedFungibleBalance = fungible.balanceOf(address(this));
        }
    }

    /// @inheritdoc ILicredity
    function exchangeFungible(address recipient) external {
        Fungible fungible = stagedFungible;
        assembly ("memory-safe") {
            if iszero(eq(fungible, address())) {
                mstore(0x00, 0x93bbf24d) // 'NotDebtFungible()'
                revert(0x1c, 0x04)
            }
        }

        uint128 _baseAmountAvailable = baseAmountAvailable;
        uint128 _debtAmountOutstanding = debtAmountOutstanding;
        uint256 amount = fungible.balanceOf(address(this)) - stagedFungibleBalance;
        assembly ("memory-safe") {
            if iszero(eq(amount, _debtAmountOutstanding)) {
                mstore(0x00, 0xb2afc83e) // 'NotAmountOutstanding()'
                revert(0x1c, 0x04)
            }

            // clear staged fungible and exchange amounts
            tstore(stagedFungible.slot, 0)
            mstore(baseAmountAvailable.slot, 0)
            mstore(debtAmountOutstanding.slot, 0)
        }

        _burn(address(this), _debtAmountOutstanding);
        baseFungible.transfer(recipient, _baseAmountAvailable);

        // emit Exchange(recipient, _debtAmountOutstanding, _baseAmountAvailable);
        assembly ("memory-safe") {
            mstore(0x00, _debtAmountOutstanding)
            mstore(0x20, _baseAmountAvailable)
            log2(0x00, 0x40, 0x26981b9aefbb0f732b0264bd34c255e831001eb50b06bc85b32cc39e14389721, recipient)
        }
    }

    /// @inheritdoc ILicredity
    function depositFungible(uint256 positionId) external payable {
        Position storage position = positions[positionId];
        if (position.owner == address(0)) {
            assembly ("memory-safe") {
                mstore(0x00, 0xf7b3b391) // 'PositionDoesNotExist()'
                revert(0x1c, 0x04)
            }
        }
        Fungible fungible = stagedFungible;

        uint256 amount;
        if (fungible.isNative()) {
            amount = msg.value;
        } else {
            assembly ("memory-safe") {
                if iszero(iszero(callvalue())) {
                    mstore(0x00, 0x19d245cf) // 'NonZeroNativeValue()'
                    revert(0x1c, 0x04)
                }
            }
            amount = fungible.balanceOf(address(this)) - stagedFungibleBalance;
        }

        assembly ("memory-safe") {
            tstore(stagedFungible.slot, 0)
        }
        position.addFungible(fungible, amount);

        // emit DepositFungible(positionId, fungible, amount);
        assembly ("memory-safe") {
            mstore(0x00, amount)
            log3(0x00, 0x20, 0x0e02681f4373fa55c60df5d9889b62e8adfe3253bc50a7dd512607e6327e90c6, positionId, fungible)
        }
    }

    /// @inheritdoc ILicredity
    function withdrawFungible(uint256 positionId, address recipient, Fungible fungible, uint256 amount) external {
        Position storage position = positions[positionId];
        if (position.owner != msg.sender) {
            assembly ("memory-safe") {
                mstore(0x00, 0x70d645e3) // 'NotPositionOwner()'
                revert(0x1c, 0x04)
            }
        }

        Locker.register(bytes32(positionId));
        position.removeFungible(fungible, amount);
        fungible.transfer(recipient, amount);

        // emit WithdrawFungible(positionId, recipient, fungible, amount);
        assembly ("memory-safe") {
            mstore(0x00, amount)
            log4(
                0x00,
                0x20,
                0x1d48ddd3ba3d0b826b92ce100b333c318522d68579237d273a3e3619d0d46c72,
                positionId,
                recipient,
                fungible
            )
        }
    }

    /// @inheritdoc ILicredity
    function stageNonFungible(NonFungible nonFungible) external {
        if (nonFungible.owner() == address(this)) {
            assembly ("memory-safe") {
                mstore(0x00, 0x37cf3ba4) // 'NonFungibleAlreadyOwned()'
                revert(0x1c, 0x04)
            }
        }

        stagedNonFungible = nonFungible;
    }

    /// @inheritdoc ILicredity
    function depositNonFungible(uint256 positionId) external {
        Position storage position = positions[positionId];
        if (position.owner == address(0)) {
            assembly ("memory-safe") {
                mstore(0x00, 0xf7b3b391) // 'PositionDoesNotExist()'
                revert(0x1c, 0x04)
            }
        }
        NonFungible nonFungible = stagedNonFungible;
        if (nonFungible.owner() != address(this)) {
            assembly ("memory-safe") {
                mstore(0x00, 0xc485032c) // 'NonFungibleNotOwned()'
                revert(0x1c, 0x04)
            }
        }

        assembly ("memory-safe") {
            tstore(stagedNonFungible.slot, 0)
        }
        position.addNonFungible(nonFungible);

        // emit DepositNonFungible(positionId, nonFungible);
        assembly ("memory-safe") {
            log3(
                0x00, 0x00, 0x113d8217beb98f6a392770deea72be5d6d47842b1511e5c0f55e6607a6ffa4c3, positionId, nonFungible
            )
        }
    }

    /// @inheritdoc ILicredity
    function withdrawNonFungible(uint256 positionId, address recipient, NonFungible nonFungible) external {
        Position storage position = positions[positionId];
        if (position.owner != msg.sender) {
            assembly ("memory-safe") {
                mstore(0x00, 0x70d645e3) // 'NotPositionOwner()'
                revert(0x1c, 0x04)
            }
        }

        Locker.register(bytes32(positionId));
        if (!position.removeNonFungible(nonFungible)) {
            assembly ("memory-safe") {
                mstore(0x00, 0x1f353c1f) // 'NonFungibleNotInPosition()'
                revert(0x1c, 0x04)
            }
        }
        nonFungible.transfer(recipient);

        // emit WithdrawNonFungible(positionId, recipient, nonFungible);
        assembly ("memory-safe") {
            log4(
                0x00,
                0x00,
                0x472a88e11786f436885e90e4a73c1555038dd47cb5035ccd1928cc974ad9d1bf,
                positionId,
                recipient,
                nonFungible
            )
        }
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
