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
import {SafeCast} from "./libraries/SafeCast.sol";
import {Fungible} from "./types/Fungible.sol";
import {InterestRate} from "./types/InterestRate.sol";
import {NonFungible} from "./types/NonFungible.sol";
import {Position} from "./types/Position.sol";
import {BaseHooks} from "./BaseHooks.sol";
import {DebtToken} from "./DebtToken.sol";
import {Extsload} from "./Extsload.sol";
import {RiskConfigs} from "./RiskConfigs.sol";

/// @title Licredity
/// @notice Provides the core functionalities of the Licredity protocol
contract Licredity is ILicredity, IERC721TokenReceiver, BaseHooks, DebtToken, Extsload, RiskConfigs {
    using SafeCast for uint256;

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
    uint128 internal accruedInterest;
    uint64 internal lastInterestDisbursementTimestamp;
    uint128 internal baseAmountAvailable;
    uint128 internal debtAmountOutstanding;
    uint128 internal totalDebtShare = 1e6; // can never be redeemed, prevents inflation attack and behaves like bad debt
    uint128 internal totalDebtBalance = 1; // establishes the initial conversion rate and inflation attack difficulty
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
            (,,, bool isHealthy) = _appraisePosition(positions[uint256(items[i])]);

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
                0x3933597222c8b52f5ac7094fac2afa136f151b5d564892abe64509bdac1eef06,
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

    /// @inheritdoc ILicredity
    function increaseDebtShare(uint256 positionId, uint256 delta, address recipient)
        external
        returns (uint256 amount)
    {
        Position storage position = positions[positionId];
        if (position.owner != msg.sender) {
            assembly ("memory-safe") {
                mstore(0x00, 0x70d645e3) // 'NotPositionOwner()'
                revert(0x1c, 0x04)
            }
        }

        Locker.register(bytes32(positionId));
        _disburseInterest(true);

        uint128 _totalDebtShare = totalDebtShare;
        uint128 _totalDebtBalance = totalDebtBalance;
        // assume delta never overflows uint128
        amount = delta * _totalDebtBalance / _totalDebtShare;
        totalDebtShare = (_totalDebtShare + delta).toUint128();
        totalDebtBalance = (_totalDebtBalance + amount).toUint128();
        position.increaseDebtShare(delta);
        _mint(recipient, amount);

        if (recipient == address(this)) {
            position.addFungible(Fungible.wrap(address(this)), amount);

            // emit DepositFungible(positionId, Fungible.wrap(address(this)), amount);
            assembly ("memory-safe") {
                mstore(0x00, amount)
                log3(
                    0x00,
                    0x20,
                    0x0e02681f4373fa55c60df5d9889b62e8adfe3253bc50a7dd512607e6327e90c6,
                    positionId,
                    address()
                )
            }
        }

        // emit IncreaseDebtShare(positionId, recipient, delta, amount);
        assembly ("memory-safe") {
            mstore(0x00, delta)
            mstore(0x20, amount)
            log3(0x00, 0x40, 0xca8a3aa0f86329564c7b4a6d3471e8c5b49b4c589b773bc1f2fc83d1502ebb3f, positionId, recipient)
        }
    }

    /// @inheritdoc ILicredity
    function decreaseDebtShare(uint256 positionId, uint256 delta, bool useBalance) external returns (uint256 amount) {
        Position storage position = positions[positionId];
        if (position.owner == address(0)) {
            assembly ("memory-safe") {
                mstore(0x00, 0xf7b3b391) // 'PositionDoesNotExist()'
                revert(0x1c, 0x04)
            }
        }

        _disburseInterest(true);

        uint128 _totalDebtShare = totalDebtShare;
        uint128 _totalDebtBalance = totalDebtBalance;
        // assume delta never overflows uint128
        amount = delta * _totalDebtBalance / _totalDebtShare;
        totalDebtShare = (_totalDebtShare - delta).toUint128();
        totalDebtBalance = (_totalDebtBalance - amount).toUint128();
        position.decreaseDebtShare(delta);

        if (useBalance) {
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
                    0x3933597222c8b52f5ac7094fac2afa136f151b5d564892abe64509bdac1eef06,
                    positionId,
                    0,
                    address()
                )
            }
        } else {
            _burn(msg.sender, amount);
        }

        // emit DecreaseDebtShare(positionId, delta, amount, useBalance);
        assembly ("memory-safe") {
            let fmp := mload(0x40)
            mstore(fmp, delta)
            mstore(add(fmp, 0x20), amount)
            mstore(add(fmp, 0x40), useBalance)

            log2(fmp, 0x60, 0xbb844dda1dc3eeb4dc867c5845fc66e006fbfab01f29f94287e597bc8f14c6aa, positionId)

            mstore(fmp, 0)
            mstore(add(fmp, 0x20), 0)
            mstore(add(fmp, 0x40), 0)
        }
    }

    /// @inheritdoc ILicredity
    function seize(uint256 positionId, address recipient) external returns (uint256 shortfall) {
        Position storage position = positions[positionId];
        if (position.owner == address(0)) {
            assembly ("memory-safe") {
                mstore(0x00, 0xf7b3b391) // 'PositionDoesNotExist()'
                revert(0x1c, 0x04)
            }
        }

        Locker.register(bytes32(positionId));
        _disburseInterest(true);

        (uint256 value, uint256 marginRequirement, uint256 debt, bool isHealthy) = _appraisePosition(position);
        assembly ("memory-safe") {
            if iszero(iszero(isHealthy)) {
                mstore(0x00, 0x4051037a) // 'PositionIsHealthy()'
                revert(0x1c, 0x04)
            }
        }

        if (value < debt) {
            uint256 topup = _deficitToTopup(debt - value);
            uint256 newTotalDebtBalance = totalDebtBalance + topup;

            _mint(address(this), topup);
            value += topup;
            debt = position.debtShare * newTotalDebtBalance / totalDebtShare;
            totalDebtBalance = newTotalDebtBalance.toUint128();

            position.addFungible(Fungible.wrap(address(this)), topup);

            // emit DepositFungible(positionId, Fungible.wrap(address(this)), topup);
            assembly ("memory-safe") {
                mstore(0x00, topup)
                log3(
                    0x00,
                    0x20,
                    0x0e02681f4373fa55c60df5d9889b62e8adfe3253bc50a7dd512607e6327e90c6,
                    positionId,
                    address()
                )
            }
        }

        position.setOwner(recipient);
        shortfall = value < debt + marginRequirement ? debt + marginRequirement - value : 0;

        // emit SeizePosition(positionId, recipient, shortfall);
        assembly ("memory-safe") {
            mstore(0x00, shortfall)
            log3(0x00, 0x20, 0xae2c51bfd88f5e1b54fd8b5ea1462bced8560c8023cb61996472ae22237ed1e2, positionId, recipient)
        }
    }

    /// @inheritdoc IERC721TokenReceiver
    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /// @inheritdoc BaseHooks
    function _beforeInitialize(address, PoolKey calldata, uint160) internal override returns (bytes4) {
        // TODO: implement
    }

    /// @inheritdoc BaseHooks
    function _beforeAddLiquidity(address, PoolKey calldata, IPoolManager.ModifyLiquidityParams calldata, bytes calldata)
        internal
        override
        returns (bytes4)
    {
        // TODO: implement
    }

    /// @inheritdoc BaseHooks
    function _beforeRemoveLiquidity(
        address,
        PoolKey calldata,
        IPoolManager.ModifyLiquidityParams calldata,
        bytes calldata
    ) internal override returns (bytes4) {
        // TODO: implement
    }

    /// @inheritdoc BaseHooks
    function _beforeSwap(address, PoolKey calldata, IPoolManager.SwapParams calldata, bytes calldata)
        internal
        override
        returns (bytes4, BeforeSwapDelta, uint24)
    {
        // TODO: implement
    }

    /// @inheritdoc BaseHooks
    function _afterSwap(address, PoolKey calldata, IPoolManager.SwapParams calldata, BalanceDelta, bytes calldata)
        internal
        override
        returns (bytes4, int128)
    {
        // TODO: implement
    }

    /// @notice Appraises a position for value, margin requirement, debt, and health status
    /// @param position The position to evaluate
    /// @return value The value of the position
    /// @return marginRequirement The margin requirement of the position
    /// @return debt The amount of debt in the position
    /// @return isHealthy Whether the position is healthy
    function _appraisePosition(Position storage position)
        internal
        returns (uint256 value, uint256 marginRequirement, uint256 debt, bool isHealthy)
    {
        uint256 _value;
        uint256 _marginRequirement;

        Fungible[] memory fungibles = position.fungibles;
        uint256[] memory amounts = new uint256[](fungibles.length);
        for (uint256 i = 0; i < fungibles.length; ++i) {
            amounts[i] = position.fungibleStates[fungibles[i]].balance();
        }

        (_value, _marginRequirement) = oracle.quoteFungibles(fungibles, amounts);
        value += _value;
        marginRequirement += _marginRequirement;

        (_value, _marginRequirement) = oracle.quoteNonFungibles(position.nonFungibles);
        value += _value;
        marginRequirement += _marginRequirement;

        debt = uint256(position.debtShare) * totalDebtBalance / totalDebtShare;
        isHealthy = value >= debt + marginRequirement && debt <= value - value * positionMrrPips / UNIT_PIPS;
    }

    /// @notice Disburses (or accrues) interest to active liquidity providers
    /// @param accrueOnly If true, only accrues interest without disbursing it
    function _disburseInterest(bool accrueOnly) internal {
        uint256 elapsed = block.timestamp - lastInterestDisbursementTimestamp;
        if (elapsed == 0) return;

        uint128 _totalDebtBalance = totalDebtBalance;
        InterestRate interestRate = _priceToInterestRate(oracle.quotePrice());
        // assume interest never overflows uint128
        uint128 interest = uint128(interestRate.calculateInterest(_totalDebtBalance, elapsed));

        totalDebtBalance = _totalDebtBalance + interest;
        // assume timestamp never overflows uint64
        lastInterestDisbursementTimestamp = uint64(block.timestamp);

        if (accrueOnly) {
            accruedInterest += interest;
        } else {
            interest += accruedInterest;
            accruedInterest = 0;

            if (protocolFeePips > 0 && protocolFeeRecipient != address(0)) {
                // protocolFeePips < UNIT_PIPS
                uint128 protocolFee = uint128(uint256(interest) * protocolFeePips / UNIT_PIPS);
                interest -= protocolFee;
                _mint(protocolFeeRecipient, protocolFee);
            }

            poolManager.donate(poolKey, 0, interest, "");
            poolManager.sync(Currency.wrap(address(this)));
            _mint(address(poolManager), interest);
            poolManager.settle();
        }
    }

    /// @notice Converts a deficit amount to a top-up amount
    /// @param deficit The deficit amount to convert
    /// @return topup The converted top-up amount
    function _deficitToTopup(uint256 deficit) internal pure returns (uint256 topup) {
        topup = deficit * 2;
    }

    /// @notice Converts a price with 18 decimals to an interest rate with 27 decimals
    /// @param price The price to convert
    /// @return interestRate The converted interest rate
    function _priceToInterestRate(uint256 price) internal pure returns (InterestRate interestRate) {
        interestRate = InterestRate.wrap(price * 1e9);
    }
}
