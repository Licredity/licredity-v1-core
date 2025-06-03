// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.30;

import {IERC721TokenReceiver} from "@forge-std/interfaces/IERC721.sol";
import {IPoolManager} from "@uniswap-v4-core/interfaces/IPoolManager.sol";
import {FixedPoint96} from "@uniswap-v4-core/libraries/FixedPoint96.sol";
import {StateLibrary} from "@uniswap-v4-core/libraries/StateLibrary.sol";
import {TickMath} from "@uniswap-v4-core/libraries/TickMath.sol";
import {BalanceDelta} from "@uniswap-v4-core/types/BalanceDelta.sol";
import {BeforeSwapDelta, toBeforeSwapDelta} from "@uniswap-v4-core/types/BeforeSwapDelta.sol";
import {Currency} from "@uniswap-v4-core/types/Currency.sol";
import {PoolId} from "@uniswap-v4-core/types/PoolId.sol";
import {PoolKey} from "@uniswap-v4-core/types/PoolKey.sol";
import {ILicredity} from "./interfaces/ILicredity.sol";
import {Math} from "./libraries/Math.sol";
import {Fungible} from "./types/Fungible.sol";
import {NonFungible} from "./types/NonFungible.sol";
import {Position} from "./types/Position.sol";
import {BaseHooks} from "./BaseHooks.sol";
import {DebtToken} from "./DebtToken.sol";

/// @title Licredity
/// @notice Implementation of the ILicredity interface
contract Licredity is ILicredity, IERC721TokenReceiver, BaseHooks, DebtToken {
    using Math for uint256;
    using StateLibrary for IPoolManager;

    Fungible transient stagedFungible;
    uint256 transient stagedFungibleBalance;
    NonFungible transient stagedNonFungible;

    address internal immutable baseToken;
    PoolId internal immutable poolId;
    PoolKey internal poolKey;
    uint256 internal debtAmountIn;
    uint256 internal baseAmountOut;
    uint256 internal totalDebtShare = 1e6; // can never be redeemed, prevents inflation attack and behaves like bad debt
    uint256 internal totalDebtAmount = 1; // establishes the initial conversion rate and inflation attack difficulty
    uint256 internal positionCount;
    mapping(uint256 => Position) internal positions;

    constructor(address _baseToken, address poolManager, string memory name, string memory symbol, uint8 decimals)
        BaseHooks(poolManager)
        DebtToken(name, symbol, decimals)
    {
        baseToken = _baseToken;
        // TODO: set poolKey and poolId
    }

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
        positionId = ++positionCount;
        positions[positionId].setOwner(msg.sender);

        emit OpenPosition(positionId, msg.sender);
    }

    /// @inheritdoc ILicredity
    function close(uint256 positionId) external {
        Position storage position = positions[positionId];
        require(position.owner == msg.sender, NotPositionOwner());
        require(position.isEmpty(), PositionNotEmpty());

        delete positions[positionId];

        emit ClosePosition(positionId);
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
        // TODO: implement
    }

    /// @inheritdoc ILicredity
    function depositFungible(uint256 positionId) external payable {
        Position storage position = positions[positionId];
        require(position.owner != address(0), PositionDoesNotExist());
        Fungible fungible = stagedFungible;

        uint256 amount;
        if (fungible.isNative()) {
            amount = msg.value;
        } else {
            require(msg.value == 0, NonZeroNativeValue());
            amount = fungible.balanceOf(address(this)) - stagedFungibleBalance;
        }

        stagedFungible = Fungible.wrap(address(0));
        position.addFungible(fungible, amount);

        emit DepositFungible(positionId, fungible, amount);
    }

    /// @inheritdoc ILicredity
    function withdrawFungible(uint256 positionId, Fungible fungible, uint256 amount, address recipient) external {
        Position storage position = positions[positionId];
        require(position.owner == msg.sender, NotPositionOwner());

        // TODO: add position to health check list
        position.removeFungible(fungible, amount);
        fungible.transfer(amount, recipient);

        emit WithdrawFungible(positionId, fungible, recipient, amount);
    }

    /// @inheritdoc ILicredity
    function stageNonFungible(NonFungible nonFungible) external {
        require(nonFungible.owner() != address(this), NonFungibleAlreadyOwned());

        stagedNonFungible = nonFungible;
    }

    /// @inheritdoc ILicredity
    function depositNonFungible(uint256 positionId) external {
        Position storage position = positions[positionId];
        require(position.owner != address(0), PositionDoesNotExist());
        NonFungible nonFungible = stagedNonFungible;
        require(nonFungible.owner() == address(this), NonFungibleNotOwned());

        stagedNonFungible = NonFungible.wrap(bytes32(0));
        position.addNonFungible(nonFungible);

        emit DepositNonFungible(positionId, nonFungible);
    }

    /// @inheritdoc ILicredity
    function withdrawNonFungible(uint256 positionId, NonFungible nonFungible, address recipient) external {
        Position storage position = positions[positionId];
        require(position.owner == msg.sender, NotPositionOwner());

        // TODO: add position to health check list
        require(position.removeNonFungible(nonFungible), NonFungibleNotInPosition());
        nonFungible.transfer(recipient);

        emit WithdrawNonFungible(positionId, nonFungible, recipient);
    }

    /// @inheritdoc ILicredity
    function addDebt(uint256 positionId, uint256 share, address recipient) external returns (uint256 amount) {
        Position storage position = positions[positionId];
        require(position.owner == msg.sender, NotPositionOwner());

        // TODO: add position to health check list
        // TODO: disburse interest, which also updates totalDebtAmount
        uint256 _totalDebtShare = totalDebtShare;
        uint256 _totalDebtAmount = totalDebtAmount;
        amount = share.fullMulDiv(_totalDebtAmount, _totalDebtShare);
        _mint(recipient, amount);

        totalDebtShare = _totalDebtShare + share;
        totalDebtAmount = _totalDebtAmount + amount;
        position.addDebtShare(share);
        if (recipient == address(this)) {
            position.addFungible(Fungible.wrap(address(this)), amount);
        }

        emit AddDebt(positionId, share, recipient, amount);
    }

    /// @inheritdoc ILicredity
    function removeDebt(uint256 positionId, uint256 share, bool useBalance) external returns (uint256 amount) {
        Position storage position = positions[positionId];

        // TODO: disburse interest, which also updates totalDebtAmount
        uint256 _totalDebtShare = totalDebtShare;
        uint256 _totalDebtAmount = totalDebtAmount;
        amount = share.fullMulDivUp(_totalDebtAmount, _totalDebtShare);
        if (useBalance) {
            require(position.owner == msg.sender, NotPositionOwner());
            _burn(address(this), amount);
        } else {
            require(position.owner != address(0), PositionDoesNotExist());
            _burn(msg.sender, amount);
        }

        totalDebtShare = _totalDebtShare - share;
        totalDebtAmount = _totalDebtAmount - amount;
        position.removeDebtShare(share);
        position.removeFungible(Fungible.wrap(address(this)), amount);

        emit RemoveDebt(positionId, share, amount, useBalance);
    }

    /// @inheritdoc ILicredity
    function seize(uint256 positionId, address recipient) external returns (uint256 shortfall) {
        Position storage position = positions[positionId];
        require(position.owner != address(0), PositionDoesNotExist());

        // TODO: add position to health check list
        // TODO: disburse interest, which also updates totalDebtAmount
        uint256 _debtShare = position.debtShare;
        uint256 _totalDebtShare = totalDebtShare;
        uint256 _totalDebtAmount = totalDebtAmount;

        uint256 debt = _debtShare.fullMulDivUp(_totalDebtAmount, _totalDebtShare);
        (uint256 value, uint256 marginRequirement) = position.getValueAndMarginRequirement();
        require(value < debt + marginRequirement, PositionIsHealthy());

        if (value < debt) {
            uint256 deficit = debt - value;
            uint256 topUp = _getTopUpAmount(deficit);

            _mint(address(this), topUp);
            totalDebtAmount = _totalDebtAmount + topUp;
            position.addFungible(Fungible.wrap(address(this)), topUp);

            // assets are quoted in debt tokens, which has margin requirement of 0%
            value += topUp;
            debt += _debtShare.fullMulDivUp(_totalDebtAmount + topUp, _totalDebtShare);
        }

        position.setOwner(recipient);
        if (value < debt + marginRequirement) {
            shortfall = debt + marginRequirement - value;
        }

        emit SeizePosition(positionId, recipient, shortfall);
    }

    /// @inheritdoc IERC721TokenReceiver
    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /// @inheritdoc BaseHooks
    function _beforeInitialize(address sender, PoolKey calldata, uint160) internal override returns (bytes4) {
        require(sender == address(this), NotMultiPoolHooks());

        return this.beforeInitialize.selector;
    }

    /// @inheritdoc BaseHooks
    function _beforeAddLiquidity(
        address,
        PoolKey calldata,
        IPoolManager.ModifyLiquidityParams calldata params,
        bytes calldata
    ) internal override returns (bytes4) {
        (, int24 tick,,) = poolManager.getSlot0(poolId);

        if (tick >= params.tickLower && tick <= params.tickUpper) {
            // TODO: disburse interest
        }

        return this.beforeAddLiquidity.selector;
    }

    /// @inheritdoc BaseHooks
    function _beforeRemoveLiquidity(
        address,
        PoolKey calldata,
        IPoolManager.ModifyLiquidityParams calldata params,
        bytes calldata
    ) internal override returns (bytes4) {
        (, int24 tick,,) = poolManager.getSlot0(poolId);

        if (tick >= params.tickLower && tick <= params.tickUpper) {
            // TODO: disburse interest
        }

        return this.beforeRemoveLiquidity.selector;
    }

    /// @inheritdoc BaseHooks
    function _beforeSwap(address sender, PoolKey calldata, IPoolManager.SwapParams calldata, bytes calldata)
        internal
        override
        returns (bytes4, BeforeSwapDelta, uint24)
    {
        if (sender != address(this)) {
            // TODO: disburse interest
            // TODO: ping oracle
        }

        return (this.beforeSwap.selector, toBeforeSwapDelta(0, 0), 0);
    }

    function _afterSwap(
        address sender,
        PoolKey calldata,
        IPoolManager.SwapParams calldata,
        BalanceDelta balanceDelta,
        bytes calldata
    ) internal override returns (bytes4, int128) {
        if (sender != address(this)) {
            (uint256 sqrtPriceX96,,,) = poolManager.getSlot0(poolId);

            if (sqrtPriceX96 <= FixedPoint96.Q96) {
                IPoolManager.SwapParams memory params =
                    IPoolManager.SwapParams(false, -balanceDelta.amount1(), TickMath.MAX_SQRT_PRICE - 1);
                balanceDelta = poolManager.swap(poolKey, params, "");
                uint256 baseAmount = uint128(balanceDelta.amount0());
                uint256 debtAmount = uint128(-balanceDelta.amount1());

                poolManager.sync(Currency.wrap(address(this)));
                _mint(address(poolManager), debtAmount);
                poolManager.settle();
                poolManager.take(Currency.wrap(baseToken), address(this), baseAmount);

                debtAmountIn += debtAmount;
                baseAmountOut += baseAmount;
            }
        }

        return (this.afterSwap.selector, 0);
    }

    /// @notice Calculates top-up amount based on deficit amount in seize()
    function _getTopUpAmount(uint256 deficit) internal view returns (uint256 topUp) {
        topUp = deficit * 2;
    }
}
