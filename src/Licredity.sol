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
import {NoDelegateCall} from "./NoDelegateCall.sol";
import {RiskConfigs} from "./RiskConfigs.sol";

/// @title Licredity
/// @notice Provides the core functionalities of the protocol
contract Licredity is ILicredity, BaseHooks, BaseERC20, RiskConfigs, Extsload, NoDelegateCall {
    using FullMath for uint256;
    using PipsMath for uint256;
    using StateLibrary for IPoolManager;

    uint24 private constant FEE = 100;
    int24 private constant TICK_SPACING = 1;
    uint256 private constant MAX_FUNGIBLES = 128; // maximum number of fungibles per position
    uint256 private constant MAX_NON_FUNGIBLES = 128; // maximum number of non-fungibles per position
    uint256 private constant POSITION_MRR_PIPS = 10_000; // 1% margin requirement
    uint256 private constant MAX_INTEREST_RATE = 3.65e27; // maximum interest rate (365% per year)
    uint256 private constant ONE_D18 = 1e18;
    uint160 private constant ONE_X96 = 0x1000000000000000000000000;

    Fungible internal transient stagedFungible;
    uint256 internal transient stagedFungibleBalance;
    NonFungible internal transient stagedNonFungible;

    Fungible public immutable baseFungible;
    uint256 public immutable scaleFactor; // used to convert price deviation to interest rate, accounting for precision differences
    PoolId public immutable poolId;
    PoolKey public poolKey;
    uint256 public accruedDonation;
    uint256 public accruedProtocolFee;
    uint256 public exchangeableAmount;
    uint256 public lastInterestCollectionTimestamp;
    uint256 public totalDebtShare = 1e6; // can never be redeemed, prevents inflation attack and behaves like bad debt
    uint256 public totalDebtBalance = 1; // establishes the initial conversion rate and inflation attack difficulty
    uint256 public lastPositionId;
    mapping(uint256 => Position) public positions;
    mapping(bytes32 => uint256) public liquidityOnsets; // maps liquidity key to its onset timestamp

    modifier onlyNonZeroAddress(address _address) {
        _onlyNonZeroAddress(_address);
        _;
    }

    function _onlyNonZeroAddress(address _address) internal pure {
        assembly ("memory-safe") {
            if eq(_address, 0) {
                mstore(0x00, 0x8579befe) // 'ZeroAddressNotAllowed()'
                revert(0x1c, 0x04)
            }
        }
    }

    constructor(
        address baseToken,
        uint256 interestSensitivity,
        address _poolManager,
        address _governor,
        string memory name,
        string memory symbol
    ) BaseHooks(_poolManager) BaseERC20(name, symbol, Fungible.wrap(baseToken).decimals()) RiskConfigs(_governor) {
        // require(address(this) > baseToken, LicredityAddressNotValid());
        if (address(this) <= baseToken) {
            assembly ("memory-safe") {
                mstore(0x00, 0xb05fc81d) // 'LicredityAddressNotValid()'
                revert(0x1c, 0x04)
            }
        }

        baseFungible = Fungible.wrap(baseToken);
        scaleFactor = interestSensitivity * 1e9;

        poolKey =
            PoolKey(Currency.wrap(baseToken), Currency.wrap(address(this)), FEE, TICK_SPACING, IHooks(address(this)));
        poolId = poolKey.toId();
        poolManager.initialize(poolKey, ONE_X96);
    }

    /// @inheritdoc ILicredity
    function unlock(bytes calldata data) external noDelegateCall returns (bytes memory result) {
        Locker.unlock();

        // accrue interest and update total debt balance
        _collectInterest(false);

        // callback to message sender, which must implement IUnlockCallback
        result = IUnlockCallback(msg.sender).unlockCallback(data);

        // ensure that every registered position is healthy
        bytes32[] memory items = Locker.registeredItems();
        for (uint256 i = 0; i < items.length; ++i) {
            (,,, bool isHealthy) = _appraisePosition(positions[uint256(items[i])]);

            // require(isHealthy, PositionNotHealthy());
            assembly ("memory-safe") {
                if iszero(isHealthy) {
                    mstore(0x00, 0x58548e84) // 'PositionNotHealthy()'
                    revert(0x1c, 0x04)
                }
            }
        }

        Locker.lock();
    }

    /// @inheritdoc ILicredity
    function openPosition() external returns (uint256 positionId) {
        unchecked {
            positionId = ++lastPositionId; // overflow not plausible
        }
        positions[positionId].setOwner(msg.sender);

        // emit OpenPosition(positionId, msg.sender);
        assembly ("memory-safe") {
            log3(0x00, 0x00, 0x3ffddb72d5a0bb21e612abf8887ea717fc463df82000825adeecd6558bf722e1, positionId, caller())
        }
    }

    /// @inheritdoc ILicredity
    function closePosition(uint256 positionId) external {
        Position storage position;
        // position = positions[positionId];
        assembly ("memory-safe") {
            mstore(0x00, positionId)
            mstore(0x20, positions.slot)
            position.slot := keccak256(0x00, 0x40)
        }

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
    function exchangeFungible(address recipient, bool baseForDebt) external payable onlyNonZeroAddress(recipient) {
        (Fungible fungible, uint256 amount) = _popStagedFungibleAndAmount();

        if (baseForDebt) {
            // allow unlimited exchange of base fungible for debt fungible at 1:1 ratio
            // prevents insufficient liquidity when repaying debt fungible
            Fungible _baseFungible = baseFungible;

            assembly ("memory-safe") {
                // require(fungible == baseFungible, NotBaseFungible());
                if iszero(eq(fungible, _baseFungible)) {
                    mstore(0x00, 0x74db12cd) // 'NotBaseFungible()'
                    revert(0x1c, 0x04)
                }

                // update the exchangeableAmount amount
                sstore(exchangeableAmount.slot, add(sload(exchangeableAmount.slot), amount)) // overflow not plausible
            }

            // complete the exchange
            _mint(recipient, amount);
        } else {
            // allow exchange of debt fungible for base fungible at 1:1. ratio, up to `exchangeableAmount`
            uint256 _exchangeableAmount = exchangeableAmount; // gas saving

            assembly ("memory-safe") {
                // require(Fungible.unwrap(fungible) == address(this), NotDebtFungible());
                if iszero(eq(fungible, address())) {
                    mstore(0x00, 0x93bbf24d) // 'NotDebtFungible()'
                    revert(0x1c, 0x04)
                }

                // require(amount <= _exchangeableAmount, ExchangeableAmountExceeded());
                if gt(amount, _exchangeableAmount) {
                    mstore(0x00, 0xc820ee3a) // 'ExchangeableAmountExceeded()'
                    revert(0x1c, 0x04)
                }

                // update the exchange amounts
                sstore(exchangeableAmount.slot, sub(_exchangeableAmount, amount)) // underflow not possible
            }

            // complete the exchange
            _burn(address(this), amount);
            baseFungible.transfer(recipient, amount);
        }

        assembly ("memory-safe") {
            // emit ExchangeFungible(recipient, baseForDebt, amount);
            mstore(0x00, amount)
            log3(
                0x00,
                0x20,
                0x6dc67a0c2538883de017bbb1f374ecf11c4306d76975d19b61ebd6814b11d583,
                and(recipient, 0xffffffffffffffffffffffffffffffffffffffff),
                and(baseForDebt, 0x1)
            )
        }
    }

    /// @inheritdoc ILicredity
    function depositFungible(uint256 positionId) external payable {
        Position storage position;
        // position = positions[positionId];
        assembly ("memory-safe") {
            mstore(0x00, positionId)
            mstore(0x20, positions.slot)
            position.slot := keccak256(0x00, 0x40)
        }

        // require(position.owner == msg.sender, NotPositionOwner());
        if (position.owner != msg.sender) {
            assembly ("memory-safe") {
                mstore(0x00, 0x70d645e3) // 'NotPositionOwner()'
                revert(0x1c, 0x04)
            }
        }

        (Fungible fungible, uint256 amount) = _popStagedFungibleAndAmount();
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
    function withdrawFungible(uint256 positionId, address recipient, Fungible fungible, uint256 amount)
        external
        onlyNonZeroAddress(recipient)
    {
        Position storage position;
        // position = positions[positionId];
        assembly ("memory-safe") {
            mstore(0x00, positionId)
            mstore(0x20, positions.slot)
            position.slot := keccak256(0x00, 0x40)
        }

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
        Position storage position;
        // position = positions[positionId];
        assembly ("memory-safe") {
            mstore(0x00, positionId)
            mstore(0x20, positions.slot)
            position.slot := keccak256(0x00, 0x40)
        }

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
    function withdrawNonFungible(uint256 positionId, address recipient, NonFungible nonFungible)
        external
        onlyNonZeroAddress(recipient)
    {
        Position storage position;
        // position = positions[positionId];
        assembly ("memory-safe") {
            mstore(0x00, positionId)
            mstore(0x20, positions.slot)
            position.slot := keccak256(0x00, 0x40)
        }

        // require(position.owner == msg.sender, NotPositionOwner());
        if (position.owner != msg.sender) {
            assembly ("memory-safe") {
                mstore(0x00, 0x70d645e3) // 'NotPositionOwner()'
                revert(0x1c, 0x04)
            }
        }

        // ensure position health post withdrawal
        Locker.register(bytes32(positionId));

        position.removeNonFungible(nonFungible);
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
        noDelegateCall
        onlyNonZeroAddress(recipient)
        returns (uint256 amount)
    {
        Position storage position;
        // position = positions[positionId];
        assembly ("memory-safe") {
            mstore(0x00, positionId)
            mstore(0x20, positions.slot)
            position.slot := keccak256(0x00, 0x40)
        }

        // require(position.owner == msg.sender, NotPositionOwner());
        if (position.owner != msg.sender) {
            assembly ("memory-safe") {
                mstore(0x00, 0x70d645e3) // 'NotPositionOwner()'
                revert(0x1c, 0x04)
            }
        }

        // ensure position health post debt share increase
        Locker.register(bytes32(positionId));

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
    function decreaseDebtShare(uint256 positionId, uint256 delta, bool useBalance)
        external
        noDelegateCall
        returns (uint256 amount)
    {
        Position storage position;
        // position = positions[positionId];
        assembly ("memory-safe") {
            mstore(0x00, positionId)
            mstore(0x20, positions.slot)
            position.slot := keccak256(0x00, 0x40)
        }

        // accrue interest and update total debt balance
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
            _burn(msg.sender, amount);
        }

        position.decreaseDebtShare(delta);

        totalDebtShare = _totalDebtShare - delta;
        totalDebtBalance = _totalDebtBalance - amount;

        // emit DecreaseDebtShare(positionId, useBalance, delta, amount);
        assembly ("memory-safe") {
            mstore(0x00, delta)
            mstore(0x20, amount)

            log3(
                0x00,
                0x40,
                0xb1a5dc5e6da79cfa0d771fe626e7c7d839c8f77d8ba8d23219abd0ad42efbfca,
                positionId,
                and(useBalance, 0x1)
            )
        }
    }

    /// @inheritdoc ILicredity
    function seizePosition(uint256 positionId, address recipient)
        external
        noDelegateCall
        onlyNonZeroAddress(recipient)
        returns (uint256 shortfall)
    {
        Position storage position;
        // position = positions[positionId];
        assembly ("memory-safe") {
            mstore(0x00, positionId)
            mstore(0x20, positions.slot)
            position.slot := keccak256(0x00, 0x40)
        }

        // prevents owner from purposely degrading a position to be underwater then profit from seizing it
        // either directly or through a third party contract
        // require(!Locker.isRegistered(bytes32(positionId)), RegisteredPositionCannotBeSeized());
        if (Locker.isRegistered(bytes32(positionId))) {
            assembly ("memory-safe") {
                mstore(0x00, 0x801afa74) // 'RegisteredPositionCannotBeSeized()'
                revert(0x1c, 0x04)
            }
        }

        // ensure position health post seizure
        Locker.register(bytes32(positionId));

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
                newTotalDebtBalance := add(sload(totalDebtBalance.slot), topup) // overflow not plausible

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

    /// @inheritdoc IERC721TokenReceiver
    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return this.onERC721Received.selector;
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
        address sender,
        PoolKey calldata,
        IPoolManager.ModifyLiquidityParams calldata params,
        bytes calldata
    ) internal override returns (bytes4) {
        // add / update liquidity key onset timestamp
        bytes32 liquidityKey = _calculateLiquidityKey(sender, params.tickLower, params.tickUpper, params.salt);
        liquidityOnsets[liquidityKey] = block.timestamp;

        (, int24 tick,,) = poolManager.getSlot0(poolId);

        if (tick >= params.tickLower && tick <= params.tickUpper) {
            // collect and donate interest before active liquidity is updated
            _collectInterest(true);
        }

        return this.beforeAddLiquidity.selector;
    }

    /// @inheritdoc BaseHooks
    function _beforeRemoveLiquidity(
        address sender,
        PoolKey calldata,
        IPoolManager.ModifyLiquidityParams calldata params,
        bytes calldata
    ) internal override returns (bytes4) {
        bytes32 liquidityKey = _calculateLiquidityKey(sender, params.tickLower, params.tickUpper, params.salt);
        // liquidity must have been available for at least `minLiquidityLifespan` seconds
        // prevents emphemeral liquidity from vampiring interest yield
        // require(block.timestamp >= liquidityOnsets[liquidityKey] + minLiquidityLifespan, MinLiquidityLifespanNotMet());
        if (block.timestamp < liquidityOnsets[liquidityKey] + minLiquidityLifespan) {
            assembly ("memory-safe") {
                mstore(0x00, 0x463df77d) // 'MinLiquidityLifespanNotMet()'
                revert(0x1c, 0x04)
            }
        }

        (, int24 tick,,) = poolManager.getSlot0(poolId);

        if (tick >= params.tickLower && tick <= params.tickUpper) {
            // collect and donate interest before active liquidity is updated
            _collectInterest(true);
        }

        return this.beforeRemoveLiquidity.selector;
    }

    /// @inheritdoc BaseHooks
    function _beforeSwap(address, PoolKey calldata, IPoolManager.SwapParams calldata, bytes calldata)
        internal
        override
        returns (bytes4, BeforeSwapDelta, uint24)
    {
        // collect and donate interest before active liquidity is potentially updated
        _collectInterest(true);

        return (this.beforeSwap.selector, toBeforeSwapDelta(0, 0), 0);
    }

    /// @inheritdoc BaseHooks
    function _afterSwap(address, PoolKey calldata, IPoolManager.SwapParams calldata, BalanceDelta, bytes calldata)
        internal
        override
        returns (bytes4, int128)
    {
        (uint256 sqrtPriceX96,,,) = poolManager.getSlot0(poolId);

        // price below 1 will result in negative interest, which is not allowed
        // require(sqrtPriceX96 >= ONE_X96, PriceTooLow());
        if (sqrtPriceX96 < ONE_X96) {
            assembly ("memory-safe") {
                mstore(0x00, 0xdbbbe822) // 'PriceTooLow()'
                revert(0x1c, 0x04)
            }
        }

        // trigger the oracle for price update
        oracle.updatePrice();

        return (this.afterSwap.selector, 0);
    }

    /// @inheritdoc RiskConfigs
    function _collectInterest(bool donate) internal override {
        uint256 elapsed = block.timestamp - lastInterestCollectionTimestamp;
        // short circuit if no time has elapsed and donation is not requested
        // this also prevents distributing any accrued protocol fee which is acceptable
        if (elapsed == 0 && !donate) return;

        uint256 donation;
        uint256 protocolFee;
        if (elapsed > 0) {
            uint256 _protocolFeePips = protocolFeePips; // gas saving
            uint256 _totalDebtBalance = totalDebtBalance; // gas saving
            InterestRate interestRate = _priceToInterestRate(oracle.quotePrice());
            uint256 interest = interestRate.calculateInterest(_totalDebtBalance, elapsed);

            if (_protocolFeePips > 0) {
                // split interest into donation and protocol fee
                protocolFee = interest.pipsMulUp(_protocolFeePips);

                unchecked {
                    donation = interest - protocolFee; // overflow not possible
                }
            }

            // increase total debt balance and update last interest collection timestamp
            totalDebtBalance = _totalDebtBalance + interest;
            lastInterestCollectionTimestamp = block.timestamp;
        }

        // only donate if requested and there is active liquidity in the pool
        if (donate && poolManager.getLiquidity(poolId) > 0) {
            // include any accrued donation and set it to 0
            donation += accruedDonation;
            accruedDonation = 0;

            if (donation > 0) {
                // donate to active liquidity
                poolManager.donate(poolKey, 0, donation, "");
                poolManager.sync(Currency.wrap(address(this)));
                _mint(address(poolManager), donation);
                poolManager.settle();
            }
        } else if (donation > 0) {
            // accrue donation for later distribution
            accruedDonation += donation;
        }

        if (protocolFeeRecipient != address(0)) {
            // include any accrued protocol fee and set it to 0
            protocolFee += accruedProtocolFee;
            accruedProtocolFee = 0;

            if (protocolFee > 0) {
                // collect protocol fee
                _mint(protocolFeeRecipient, protocolFee);
            }
        } else if (protocolFee > 0) {
            // accrue protocol fee for later distribution
            accruedProtocolFee += protocolFee;
        }
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

    function _popStagedFungibleAndAmount() internal returns (Fungible fungible, uint256 amount) {
        assembly ("memory-safe") {
            fungible := tload(stagedFungible.slot)

            // clear staged fungible
            tstore(stagedFungible.slot, 0)
        }

        if (fungible.isNative()) {
            amount = msg.value;
        } else {
            assembly ("memory-safe") {
                // require(msg.value == 0, NativeValueNotZero());
                if iszero(iszero(callvalue())) {
                    mstore(0x00, 0x2a4f6280) // 'NativeValueNotZero()'
                    revert(0x1c, 0x04)
                }
            }

            amount = fungible.balanceOf(address(this)) - stagedFungibleBalance;
        }
    }

    function _calculateLiquidityKey(address provider, int24 tickLower, int24 tickUpper, bytes32 salt)
        internal
        pure
        returns (bytes32 key)
    {
        // calculate the liquidity key as a hash of the message sender, tickLower, tickUpper and salt
        assembly ("memory-safe") {
            provider := and(provider, 0xffffffffffffffffffffffffffffffffffffffff)
            tickLower := and(tickLower, 0xffffff)
            tickUpper := and(tickUpper, 0xffffff)

            // key = keccak256(abi.encodePacked(provider, tickLower, tickUpper, salt));
            mstore(0x00, or(or(shl(48, provider), shl(24, tickLower)), tickUpper))
            mstore(0x20, salt)
            key := keccak256(0x06, 0x3a)
        }
    }

    function _deficitToTopup(uint256 deficit) internal pure returns (uint256 topup) {
        // top up with 2x the deficit
        assembly ("memory-safe") {
            // topup = deficit * 2;
            topup := mul(deficit, 2)
        }
    }

    function _priceToInterestRate(uint256 price) internal view returns (InterestRate interestRate) {
        uint256 oneD18 = ONE_D18;
        uint256 _scaleFactor = scaleFactor;

        assembly ("memory-safe") {
            if lt(price, oneD18) {
                // if price falls below 1, force 0% interest rate until it recovers
                // defensive programming, should never happen
                interestRate := 0
            }

            if gt(price, oneD18) {
                // price has 18 decimals, and interest has 27 decimals
                // interestRate = InterestRate.wrap((price - 1e18) * _scaleFactor);
                interestRate := mul(sub(price, oneD18), _scaleFactor)

                if gt(interestRate, MAX_INTEREST_RATE) { interestRate := MAX_INTEREST_RATE }
            }
        }
    }

    receive() external payable {}
}
