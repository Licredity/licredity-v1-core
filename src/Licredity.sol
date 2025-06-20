// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.30;

import {IERC721TokenReceiver} from "@forge-std/interfaces/IERC721.sol";
import {IHooks} from "@uniswap-v4-core/interfaces/IHooks.sol";
import {IPoolManager} from "@uniswap-v4-core/interfaces/IPoolManager.sol";
import {StateLibrary} from "@uniswap-v4-core/libraries/StateLibrary.sol";
import {BalanceDelta} from "@uniswap-v4-core/types/BalanceDelta.sol";
import {BeforeSwapDelta, toBeforeSwapDelta} from "@uniswap-v4-core/types/BeforeSwapDelta.sol";
import {Currency} from "@uniswap-v4-core/types/Currency.sol";
import {PoolId} from "@uniswap-v4-core/types/PoolId.sol";
import {PoolKey} from "@uniswap-v4-core/types/PoolKey.sol";
import {ILicredity} from "./interfaces/ILicredity.sol";
import {IUnlockCallback} from "./interfaces/IUnlockCallback.sol";
import {FullMath} from "./libraries/FullMath.sol";
import {Locker} from "./libraries/Locker.sol";
import {PipsMath} from "./libraries/PipsMath.sol";
import {Fungible} from "./types/Fungible.sol";
import {InterestRate} from "./types/InterestRate.sol";
import {NonFungible} from "./types/NonFungible.sol";
import {Position} from "./types/Position.sol";
import {BaseERC20} from "./BaseERC20.sol";
import {BaseHooks} from "./BaseHooks.sol";
import {Extsload} from "./Extsload.sol";
import {RiskConfigs} from "./RiskConfigs.sol";

/// @title Licredity
/// @notice Provides the core functionalities of the Licredity protocol
contract Licredity is ILicredity, IERC721TokenReceiver, BaseERC20, BaseHooks, Extsload, RiskConfigs {
    using FullMath for uint256;
    using PipsMath for uint256;
    using StateLibrary for IPoolManager;

    uint24 private constant FEE = 100;
    int24 private constant TICK_SPACING = 1;
    uint160 private constant ONE_SQRT_PRICE_X96 = 0x1000000000000000000000000;
    uint160 private constant MAX_SQRT_PRICE_X96 = 1461446703485210103287273052203988822378723970342;

    uint256 private constant POSITION_MRR_PIPS = 10_000; // 1% margin requirement
    uint256 private constant MAX_FUNGIBLES = 128; // maximum number of fungibles per position
    uint256 private constant MAX_NON_FUNGIBLES = 128; // maximum number of non-fungibles per position

    Fungible internal transient stagedFungible;
    uint256 internal transient stagedFungibleBalance;
    NonFungible internal transient stagedNonFungible;

    Fungible internal immutable baseFungible;
    PoolId internal immutable poolId;
    PoolKey internal poolKey;
    uint256 internal totalDebtShare = 1e6; // can never be redeemed, prevents inflation attack and behaves like bad debt
    uint256 internal totalDebtBalance = 1; // establishes the initial conversion rate and inflation attack difficulty
    uint256 internal accruedInterest;
    uint256 internal lastInterestCollectionTimestamp;
    uint256 internal baseAmountAvailable;
    uint256 internal debtAmountOutstanding;
    uint256 internal positionCount;
    mapping(uint256 => Position) internal positions;

    constructor(address baseToken, address _poolManager, address _governor, string memory name, string memory symbol)
        BaseERC20(name, symbol, Fungible.wrap(baseToken).decimals())
        BaseHooks(_poolManager)
        RiskConfigs(_governor)
    {
        // require(address(this) > baseToken, InvalidAddress());
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
        poolManager.initialize(poolKey, ONE_SQRT_PRICE_X96);
    }

    /// @inheritdoc ILicredity
    function unlock(bytes calldata data) external returns (bytes memory result) {
        Locker.unlock();

        // callback to message sender, which must implement IUnlockCallback
        result = IUnlockCallback(msg.sender).unlockCallback(data);

        // update total debt balance before appraising positions
        _collectInterest(false);

        // ensure that every registered position is healthy
        bytes32[] memory items = Locker.registeredItems();
        for (uint256 i = 0; i < items.length; ++i) {
            (,,, bool isHealthy) = _appraisePosition(positions[uint256(items[i])]);

            // require(isHealthy, PositionIsUnhealthy());
            assembly ("memory-safe") {
                if iszero(isHealthy) {
                    mstore(0x00, 0x5fba8098) // 'PositionIsUnhealthy()'
                    revert(0x1c, 0x04)
                }
            }
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

        // require(position.owner == msg.sender, NotPositionOwner());
        if (position.owner != msg.sender) {
            assembly ("memory-safe") {
                mstore(0x00, 0x70d645e3) // 'NotPositionOwner()'
                revert(0x1c, 0x04)
            }
        }
        // require(position.isEmpty(), PositionNotEmpty());
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
        assembly ("memory-safe") {
            // stagedFungible = fungible;
            tstore(stagedFungible.slot, and(fungible, 0xffffffffffffffffffffffffffffffffffffffff))
        }

        if (!fungible.isNative()) {
            stagedFungibleBalance = fungible.balanceOf(address(this));
        }
    }

    /// @inheritdoc ILicredity
    function exchangeFungible(address recipient) external {
        Fungible fungible = stagedFungible; // gas saving
        uint256 _baseAmountAvailable = baseAmountAvailable; // gas saving
        uint256 _debtAmountOutstanding = debtAmountOutstanding; // gas saving
        uint256 amount = fungible.balanceOf(address(this)) - stagedFungibleBalance;

        assembly ("memory-safe") {
            // require(Fungible.unwrap(fungible) == address(this), NotDebtFungible());
            if iszero(eq(fungible, address())) {
                mstore(0x00, 0x93bbf24d) // 'NotDebtFungible()'
                revert(0x1c, 0x04)
            }
            // require(amount == _debtAmountOutstanding, NotAmountOutstanding());
            if iszero(eq(amount, _debtAmountOutstanding)) {
                mstore(0x00, 0xb2afc83e) // 'NotAmountOutstanding()'
                revert(0x1c, 0x04)
            }

            // clear staged fungible and exchange amounts
            tstore(stagedFungible.slot, 0)
            sstore(baseAmountAvailable.slot, 0)
            sstore(debtAmountOutstanding.slot, 0)
        }

        // make the exchagne
        _burn(address(this), _debtAmountOutstanding);
        baseFungible.transfer(recipient, _baseAmountAvailable);

        // emit Exchange(recipient, _debtAmountOutstanding, _baseAmountAvailable);
        assembly ("memory-safe") {
            mstore(0x00, _debtAmountOutstanding)
            mstore(0x20, _baseAmountAvailable)
            log2(
                0x00,
                0x40,
                0x26981b9aefbb0f732b0264bd34c255e831001eb50b06bc85b32cc39e14389721,
                and(recipient, 0xffffffffffffffffffffffffffffffffffffffff)
            )
        }
    }

    /// @inheritdoc ILicredity
    function depositFungible(uint256 positionId) external payable {
        Fungible fungible = stagedFungible; // gas saving
        Position storage position = positions[positionId];

        // require(position.owner == msg.sender, NotPositionOwner());
        if (position.owner != msg.sender) {
            assembly ("memory-safe") {
                mstore(0x00, 0x70d645e3) // 'NotPositionOwner()'
                revert(0x1c, 0x04)
            }
        }

        uint256 amount;
        if (fungible.isNative()) {
            amount = msg.value;
        } else {
            assembly ("memory-safe") {
                // require(msg.value == 0, NonZeroNativeValue());
                if iszero(iszero(callvalue())) {
                    mstore(0x00, 0x19d245cf) // 'NonZeroNativeValue()'
                    revert(0x1c, 0x04)
                }
            }

            amount = fungible.balanceOf(address(this)) - stagedFungibleBalance;
        }

        assembly ("memory-safe") {
            // clear staged fungible
            tstore(stagedFungible.slot, 0)
        }
        position.addFungible(fungible, amount);

        // require(position.fungibles.length <= MAX_FUNGIBLES, MaxFungiblesExceeded());
        if (position.fungibles.length > MAX_FUNGIBLES) {
            assembly ("memory-safe") {
                mstore(0x00, 0xe8223a36) // 'MaxFungiblesExceeded()'
                revert(0x1c, 0x04)
            }
        }

        // emit DepositFungible(positionId, fungible, amount);
        assembly ("memory-safe") {
            mstore(0x00, amount)
            log3(0x00, 0x20, 0x035870714bdad9af06468d642c6278777f9a7342ca6c1855dd76f1795f2e495c, positionId, fungible)
        }
    }

    /// @inheritdoc ILicredity
    function withdrawFungible(uint256 positionId, address recipient, Fungible fungible, uint256 amount) external {
        Position storage position = positions[positionId];

        // require(position.owner == msg.sender, NotPositionOwner());
        if (position.owner != msg.sender) {
            assembly ("memory-safe") {
                mstore(0x00, 0x70d645e3) // 'NotPositionOwner()'
                revert(0x1c, 0x04)
            }
        }

        // ensure position health post withdrawal
        Locker.register(bytes32(positionId));

        position.removeFungible(fungible, amount);
        fungible.transfer(recipient, amount);

        // emit WithdrawFungible(positionId, recipient, fungible, amount);
        assembly ("memory-safe") {
            mstore(0x00, amount)
            log4(
                0x00,
                0x20,
                0xfb3042bebfd7f55f21e673d861ca2919c54d953e3ac3e23576141079b10797d0,
                positionId,
                and(recipient, 0xffffffffffffffffffffffffffffffffffffffff),
                and(fungible, 0xffffffffffffffffffffffffffffffffffffffff)
            )
        }
    }

    /// @inheritdoc ILicredity
    function stageNonFungible(NonFungible nonFungible) external {
        // require(nonFungible.owner() != address(this), NonFungibleAlreadyOwned());
        if (nonFungible.owner() == address(this)) {
            assembly ("memory-safe") {
                mstore(0x00, 0x37cf3ba4) // 'NonFungibleAlreadyOwned()'
                revert(0x1c, 0x04)
            }
        }

        assembly ("memory-safe") {
            // stagedNonFungible = nonFungible;
            tstore(stagedNonFungible.slot, nonFungible)
        }
    }

    /// @inheritdoc ILicredity
    function depositNonFungible(uint256 positionId) external {
        NonFungible nonFungible = stagedNonFungible; // gas saving
        Position storage position = positions[positionId];

        // require(position.owner == msg.sender, NotPositionOwner());
        if (position.owner != msg.sender) {
            assembly ("memory-safe") {
                mstore(0x00, 0x70d645e3) // 'NotPositionOwner()'
                revert(0x1c, 0x04)
            }
        }
        // require(nonFungible.owner() == address(this), NonFungibleNotOwned());
        if (nonFungible.owner() != address(this)) {
            assembly ("memory-safe") {
                mstore(0x00, 0xc485032c) // 'NonFungibleNotOwned()'
                revert(0x1c, 0x04)
            }
        }

        assembly ("memory-safe") {
            // clear staged non-fungible
            tstore(stagedNonFungible.slot, 0)
        }
        position.addNonFungible(nonFungible);

        // require(position.nonFungibles.length <= MAX_NON_FUNGIBLES, MaxNonFungiblesExceeded());
        if (position.nonFungibles.length > MAX_NON_FUNGIBLES) {
            assembly ("memory-safe") {
                mstore(0x00, 0x7d653372) // 'MaxNonFungiblesExceeded()'
                revert(0x1c, 0x04)
            }
        }

        // emit DepositNonFungible(positionId, nonFungible);
        assembly ("memory-safe") {
            log3(
                0x00, 0x00, 0x2fcee665a957a4b410c1fb5fb3573a6cd08cfc98f2465898ea1ccfb32139208b, positionId, nonFungible
            )
        }
    }

    /// @inheritdoc ILicredity
    function withdrawNonFungible(uint256 positionId, address recipient, NonFungible nonFungible) external {
        Position storage position = positions[positionId];

        // require(position.owner == msg.sender, NotPositionOwner());
        if (position.owner != msg.sender) {
            assembly ("memory-safe") {
                mstore(0x00, 0x70d645e3) // 'NotPositionOwner()'
                revert(0x1c, 0x04)
            }
        }

        // ensure position health post withdrawal
        Locker.register(bytes32(positionId));

        // require(position.removeNonFungible(nonFungible), NonFungibleNotInPosition());
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
                0x05d4d965df19c2a37a2b5128c3f6738ac62a8351aefe3b9af9f535d46994684a,
                positionId,
                and(recipient, 0xffffffffffffffffffffffffffffffffffffffff),
                nonFungible
            )
        }
    }

    /// @inheritdoc ILicredity
    function increaseDebtShare(uint256 positionId, uint256 delta, address recipient)
        external
        returns (uint256 amount)
    {
        Position storage position = positions[positionId];

        // require(position.owner == msg.sender, NotPositionOwner());
        if (position.owner != msg.sender) {
            assembly ("memory-safe") {
                mstore(0x00, 0x70d645e3) // 'NotPositionOwner()'
                revert(0x1c, 0x04)
            }
        }

        // ensure position health post debt share increase
        Locker.register(bytes32(positionId));
        // collect interest on total debt balance before it is used and updated
        _collectInterest(false);

        uint256 _totalDebtShare = totalDebtShare; // gas saving
        uint256 _totalDebtBalance = totalDebtBalance; // gas saving
        // amount of debt fungible to be minted
        amount = delta.fullMulDiv(_totalDebtBalance, _totalDebtShare);

        assembly ("memory-safe") {
            // require(_totalDebtBalance + amount <= debtLimit, DebtLimitExceeded());
            if gt(add(_totalDebtBalance, amount), sload(debtLimit.slot)) {
                mstore(0x00, 0xc3212f5c) // 'DebtLimitExceeded()'
                revert(0x1c, 0x04)
            }
        }

        position.increaseDebtShare(delta);
        _mint(recipient, amount);

        // if newly minted debt fungible is meant to be held in the position
        if (recipient == address(this)) {
            position.addFungible(Fungible.wrap(address(this)), amount);

            // emit DepositFungible(positionId, Fungible.wrap(address(this)), amount);
            assembly ("memory-safe") {
                mstore(0x00, amount)
                log3(
                    0x00,
                    0x20,
                    0x035870714bdad9af06468d642c6278777f9a7342ca6c1855dd76f1795f2e495c,
                    positionId,
                    address()
                )
            }
        }

        totalDebtShare = _totalDebtShare + delta;
        totalDebtBalance = _totalDebtBalance + amount;

        // emit IncreaseDebtShare(positionId, recipient, delta, amount);
        assembly ("memory-safe") {
            mstore(0x00, delta)
            mstore(0x20, amount)
            log3(
                0x00,
                0x40,
                0xca8a3aa0f86329564c7b4a6d3471e8c5b49b4c589b773bc1f2fc83d1502ebb3f,
                positionId,
                and(recipient, 0xffffffffffffffffffffffffffffffffffffffff)
            )
        }
    }

    /// @inheritdoc ILicredity
    function decreaseDebtShare(uint256 positionId, uint256 delta, bool useBalance) external returns (uint256 amount) {
        Position storage position = positions[positionId];

        // collect interest on total debt balance before it is used and updated
        _collectInterest(false);

        uint256 _totalDebtShare = totalDebtShare; // gas saving
        uint256 _totalDebtBalance = totalDebtBalance; // gas saving
        // amount of debt fungible to be burned
        amount = delta.fullMulDivUp(_totalDebtBalance, _totalDebtShare);

        // if the debt fungible is meant to be withdrawn from the position
        if (useBalance) {
            // require(position.owner == msg.sender, NotPositionOwner());
            if (position.owner != msg.sender) {
                assembly ("memory-safe") {
                    mstore(0x00, 0x70d645e3) // 'NotPositionOwner()'
                    revert(0x1c, 0x04)
                }
            }

            position.removeFungible(Fungible.wrap(address(this)), amount);
            _burn(address(this), amount);

            // emit WithdrawFungible(positionId, address(0), Fungible.wrap(address(this)), amount);
            assembly ("memory-safe") {
                mstore(0x00, amount)
                log4(
                    0x00,
                    0x20,
                    0xfb3042bebfd7f55f21e673d861ca2919c54d953e3ac3e23576141079b10797d0,
                    positionId,
                    0,
                    address()
                )
            }
        } else {
            // require(position.owner != address(0), PositionDoesNotExist());
            if (position.owner == address(0)) {
                assembly ("memory-safe") {
                    mstore(0x00, 0xf7b3b391) // 'PositionDoesNotExist()'
                    revert(0x1c, 0x04)
                }
            }

            _burn(msg.sender, amount);
        }

        position.decreaseDebtShare(delta);

        totalDebtShare = _totalDebtShare - delta;
        totalDebtBalance = _totalDebtBalance - amount;

        // emit DecreaseDebtShare(positionId, delta, amount, useBalance);
        assembly ("memory-safe") {
            let fmp := mload(0x40)
            mstore(fmp, delta)
            mstore(add(fmp, 0x20), amount)
            mstore(add(fmp, 0x40), and(useBalance, 0x1))

            log2(fmp, 0x60, 0xbb844dda1dc3eeb4dc867c5845fc66e006fbfab01f29f94287e597bc8f14c6aa, positionId)

            mstore(fmp, 0)
            mstore(add(fmp, 0x20), 0)
            mstore(add(fmp, 0x40), 0)
        }
    }

    /// @inheritdoc ILicredity
    function seize(uint256 positionId, address recipient) external returns (uint256 shortfall) {
        Position storage position = positions[positionId];

        // require(position.owner != address(0), PositionDoesNotExist());
        if (position.owner == address(0)) {
            assembly ("memory-safe") {
                mstore(0x00, 0xf7b3b391) // 'PositionDoesNotExist()'
                revert(0x1c, 0x04)
            }
        }

        // ensure position health post seizure
        Locker.register(bytes32(positionId));
        // update total debt balance, which in turn updates position's debt
        _collectInterest(false);

        (uint256 value, uint256 marginRequirement, uint256 debt, bool isHealthy) = _appraisePosition(position);

        // require(!isHealthy, PositionIsHealthy());
        assembly ("memory-safe") {
            if iszero(iszero(isHealthy)) {
                mstore(0x00, 0x4051037a) // 'PositionIsHealthy()'
                revert(0x1c, 0x04)
            }
        }

        uint256 topup;
        // if the position is underwater, top it up to encourage seizure
        // this represents a bad debt to the protocol, and is socialized among all debt holders
        if (value < debt) {
            topup = _deficitToTopup(debt - value);

            _mint(address(this), topup);
            position.addFungible(Fungible.wrap(address(this)), topup);

            // update total debt balance, and position's value and debt
            uint256 newTotalDebtBalance;
            assembly ("memory-safe") {
                // newTotalDebtBalance = totalDebtBalance + topup;
                newTotalDebtBalance := add(sload(totalDebtBalance.slot), topup)

                // totalDebtBalance = newTotalDebtBalance;
                sstore(totalDebtBalance.slot, newTotalDebtBalance)

                // value = value + topup;
                value := add(value, topup)
            }
            debt = position.debtShare.fullMulDivUp(newTotalDebtBalance, totalDebtShare);

            // emit DepositFungible(positionId, Fungible.wrap(address(this)), topup);
            assembly ("memory-safe") {
                mstore(0x00, topup)
                log3(
                    0x00,
                    0x20,
                    0x035870714bdad9af06468d642c6278777f9a7342ca6c1855dd76f1795f2e495c,
                    positionId,
                    address()
                )
            }
        }

        // transfer ownership to recipient
        position.setOwner(recipient);
        // calculate shortfall, the amount needed to bring the position back to health
        shortfall = value < debt + marginRequirement ? debt + marginRequirement - value : 0;

        // emit SeizePosition(positionId, recipient, value, debt, marginRequirement, topup);
        assembly ("memory-safe") {
            let fmp := mload(0x40)
            mstore(fmp, value)
            mstore(add(fmp, 0x20), debt)
            mstore(add(fmp, 0x40), marginRequirement)
            mstore(add(fmp, 0x60), topup)

            log3(
                fmp,
                0x80,
                0xe4ead9e85a25cb8008cef34c4d0baa3da1bf7bdd99b1c8f40f9d2423969606a4,
                positionId,
                and(recipient, 0xffffffffffffffffffffffffffffffffffffffff)
            )

            mstore(fmp, 0)
            mstore(add(fmp, 0x20), 0)
            mstore(add(fmp, 0x40), 0)
            mstore(add(fmp, 0x60), 0)
        }
    }

    /// @inheritdoc BaseHooks
    function _beforeInitialize(address sender, PoolKey calldata, uint160) internal view override returns (bytes4) {
        assembly ("memory-safe") {
            // require(sender == address(this), NotLicredity());
            if iszero(eq(and(sender, 0xffffffffffffffffffffffffffffffffffffffff), address())) {
                mstore(0x00, 0x7a08c3ff) // 'NotLicredity()'
                revert(0x1c, 0x04)
            }
        }

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
            // collect and distribute interest before active liquidity is updated
            _collectInterest(true);
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
            // collect and distribute interest before active liquidity is updated
            _collectInterest(true);
        }

        return this.beforeRemoveLiquidity.selector;
    }

    /// @inheritdoc BaseHooks
    function _beforeSwap(address sender, PoolKey calldata, IPoolManager.SwapParams calldata, bytes calldata)
        internal
        override
        returns (bytes4, BeforeSwapDelta, uint24)
    {
        // do nothing during the back run swap
        if (sender != address(this)) {
            // collect and distribute interest before active liquidity is potentially updated
            _collectInterest(true);
        }

        return (this.beforeSwap.selector, toBeforeSwapDelta(0, 0), 0);
    }

    /// @inheritdoc BaseHooks
    function _afterSwap(
        address sender,
        PoolKey calldata,
        IPoolManager.SwapParams calldata,
        BalanceDelta balanceDelta,
        bytes calldata
    ) internal override returns (bytes4, int128) {
        // do nothing during the back run swap
        if (sender != address(this)) {
            (uint256 sqrtPriceX96,,,) = poolManager.getSlot0(poolId);

            // price below 1 will result in negative interest, which is not allowed
            // mint non-interest-bearing debt fungible to revert the effect of the current swap
            // anyone can remove these additional fungible tokens by exchanging them for base fungible collected
            if (sqrtPriceX96 <= ONE_SQRT_PRICE_X96) {
                // back run swap to revert the effect of the current swap, using exactOut to account for fees
                IPoolManager.SwapParams memory params =
                    IPoolManager.SwapParams(false, -balanceDelta.amount0(), MAX_SQRT_PRICE_X96 - 1);
                balanceDelta = poolManager.swap(poolKey, params, "");

                // store amounts eligible for exchange
                uint256 baseAmount = uint128(balanceDelta.amount0());
                uint256 debtAmount = uint128(-balanceDelta.amount1());
                baseAmountAvailable += baseAmount;
                debtAmountOutstanding += debtAmount;

                // reconcile balance delta with the pool manager
                poolManager.sync(Currency.wrap(address(this)));
                _mint(address(poolManager), debtAmount);
                poolManager.settle();
                poolManager.take(Currency.wrap(Fungible.unwrap(baseFungible)), address(this), baseAmount);
            }

            // trigger the oracle for price update
            oracle.update();
        }

        return (this.afterSwap.selector, 0);
    }

    /// @inheritdoc IERC721TokenReceiver
    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function _appraisePosition(Position storage position)
        internal
        returns (uint256 value, uint256 marginRequirement, uint256 debt, bool isHealthy)
    {
        debt = position.debtShare.fullMulDivUp(totalDebtBalance, totalDebtShare);
        // short circuit if the position has no debt
        if (debt == 0) return (0, 0, 0, true);

        uint256 _value;
        uint256 _marginRequirement;

        // prepare parameters for quoting fungibles
        Fungible[] memory fungibles = position.fungibles;
        uint256[] memory amounts = new uint256[](fungibles.length);
        for (uint256 i = 0; i < fungibles.length; ++i) {
            amounts[i] = position.fungibleStates[fungibles[i]].balance();
        }

        // accumulate value and margin requirement from fungibles
        (_value, _marginRequirement) = oracle.quoteFungibles(fungibles, amounts);
        value += _value;
        marginRequirement += _marginRequirement;

        // accumulate value and margin requirement from non-fungibles
        (_value, _marginRequirement) = oracle.quoteNonFungibles(position.nonFungibles);
        value += _value;
        marginRequirement += _marginRequirement;

        // position is healthy only if its margin:
        // 1. meets the margin requirement based on the assets it holds
        // 2. exceeds the minimum margin when carrying debt (to prevent dust positions)
        // 3. exceeds (as percent of value) the margin requirement ratio (to prevent using debt fungible,
        //    which has 0% margin requirement, to take on enormous debt that causes the position to go underwater)
        isHealthy = value >= debt + marginRequirement && marginRequirement >= minMargin
            && debt <= value - value.pipsMulUp(POSITION_MRR_PIPS);
    }

    function _collectInterest(bool distribute) internal {
        uint256 elapsed = block.timestamp - lastInterestCollectionTimestamp;
        if (elapsed == 0) return;

        uint256 _totalDebtBalance = totalDebtBalance; // gas saving
        InterestRate interestRate = _priceToInterestRate(oracle.quotePrice());
        uint256 interest = interestRate.calculateInterest(_totalDebtBalance, elapsed);

        totalDebtBalance = _totalDebtBalance + interest;
        lastInterestCollectionTimestamp = block.timestamp;

        if (distribute && poolManager.getLiquidity(poolId) > 0) {
            assembly ("memory-safe") {
                // interest += accruedInterest; // overflow not possible
                interest := add(interest, sload(accruedInterest.slot))
                // accruedInterest = 0;
                sstore(accruedInterest.slot, 0)
            }

            if (interest != 0) {
                // collect protocol fee if applicable
                if (protocolFeePips > 0 && protocolFeeRecipient != address(0)) {
                    uint256 protocolFee = interest.pipsMulUp(protocolFeePips);
                    interest -= protocolFee;
                    _mint(protocolFeeRecipient, protocolFee);
                }

                // donate interest to active liquidity
                poolManager.donate(poolKey, 0, interest, "");
                poolManager.sync(Currency.wrap(address(this)));
                _mint(address(poolManager), interest);
                poolManager.settle();
            }

        } else {
            assembly ("memory-safe") {
                // accruedInterest += interest; // overflow not possible
                sstore(accruedInterest.slot, add(sload(accruedInterest.slot), interest))
            }
        }
    }

    function _deficitToTopup(uint256 deficit) internal pure returns (uint256 topup) {
        // top up with 2x the deficit
        assembly ("memory-safe") {
            // topup = deficit * 2;
            topup := mul(deficit, 2)
        }
    }

    function _priceToInterestRate(uint256 price) internal pure returns (InterestRate interestRate) {
        assembly ("memory-safe") {
            if lt(price, 1000000000000000000) {
                // if price falls below 1, force 0% interest rate until it recovers
                // defensive programming, should never happen
                interestRate := 0
            }

            if not(lt(price, 1000000000000000000)) {
                // price has 18 decimals, and interest has 27 decimals
                // interestRate = InterestRate.wrap((price - 1e18) * 1e9);
                interestRate := mul(sub(price, 1000000000000000000), 1000000000)
            }
        }
    }

    receive() external payable {}
}
