// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Deployers} from "./utils/Deployer.sol";
import {ShareMath} from "./utils/ShareMath.sol";
import {Fungible} from "src/types/Fungible.sol";
import {NonFungible} from "src/types/NonFungible.sol";
import {StateLibrary} from "./utils/StateLibrary.sol";
import {Licredity} from "src/Licredity.sol";
import {ChainInfo} from "src/libraries/ChainInfo.sol";

contract LicredityUnlockPositionTest is Deployers {
    using ShareMath for uint128;
    using StateLibrary for Licredity;

    error NotPositionOwner();
    error PositionNotEmpty();
    error PositionIsUnhealthy();
    error PositionDoesNotExist();
    error NonFungibleNotInPosition();
    error DebtLimitExceeded();

    event IncreaseDebtShare(uint256 indexed positionId, address indexed recipient, uint256 delta, uint256 amount);
    event DecreaseDebtShare(uint256 indexed positionId, uint256 delta, uint256 amount, bool useBalance);
    event DepositFungible(uint256 indexed positionId, Fungible indexed fungible, uint256 amount);
    event WithdrawFungible(
        uint256 indexed positionId, address indexed recipient, Fungible indexed fungible, uint256 amount
    );
    event WithdrawNonFungible(uint256 indexed positionId, address indexed recipient, NonFungible indexed nonFungible);

    address public user = address(0xE585379156909287F8aA034B2F4b1Cb88aa3d29D);

    function setUp() public {
        deployETHLicredityWithUniswapV4();
        deployNonFungibleMock();
        deployAndSetOracleMock();
        deployLicredityRouter();
    }

    /// increaseDebtShare ///

    function test_increaseDebtShare_notOwner() public {
        vm.expectRevert(NotPositionOwner.selector);
        licredityRouterHelper.addDebt(1, 1, address(this));
    }

    function test_increaseDebt_ltMinMargin() public {
        uint256 positionId = licredityRouter.open();
        licredityRouter.depositFungible{value: 1 ether}(positionId, Fungible.wrap(ChainInfo.NATIVE), 1 ether);

        licredity.setMinMargin(0.0015 ether);

        (uint256 totalShares, uint256 totalAssets) = licredity.getTotalDebt();
        uint256 delta = uint128(0.99 ether).toShares(totalAssets, totalShares);

        vm.expectRevert(PositionIsUnhealthy.selector);
        licredityRouterHelper.addDebt(positionId, delta, address(this));
    }

    function test_increaseDebtShare(uint128 amount) public {
        vm.assume(amount < type(uint128).max / 1e6);

        uint256 positionId = licredityRouter.open();

        licredityRouter.depositFungible{value: 1 ether}(positionId, Fungible.wrap(ChainInfo.NATIVE), 1 ether);

        (uint256 totalShares, uint256 totalAssets) = licredity.getTotalDebt();
        uint256 delta = amount.toShares(totalAssets, totalShares);

        /// margin requirement = 1 ether * 0.1% = 0.01 ether
        /// max debt = value - margin requirement = 1 ether - 0.01 ether = 0.99 ether
        if (amount <= 0.99 ether) {
            vm.expectEmit(true, true, false, true);
            emit IncreaseDebtShare(positionId, address(this), delta, amount);

            licredityRouterHelper.addDebt(positionId, delta, address(this));
            assertEq(licredity.balanceOf(address(this)), amount);
        } else {
            if (amount < 10000 ether) {
                vm.expectRevert(PositionIsUnhealthy.selector);
                licredityRouterHelper.addDebt(positionId, delta, address(this));
            } else {
                vm.expectRevert(DebtLimitExceeded.selector);
                licredityRouterHelper.addDebt(positionId, delta, address(this));
            }
        }
    }

    function test_increaseDebtShare_Position(uint128 amount) public {
        vm.assume(amount < type(uint128).max / 1e6);

        uint256 positionId = licredityRouter.open();

        (uint256 totalShares, uint256 totalAssets) = licredity.getTotalDebt();
        licredityRouter.depositFungible{value: 1 ether}(positionId, Fungible.wrap(ChainInfo.NATIVE), 1 ether);

        uint256 delta = amount.toShares(totalAssets, totalShares);

        if (amount < 99 ether) {
            vm.expectEmit(true, true, false, true);
            emit DepositFungible(positionId, Fungible.wrap(address(licredity)), amount);
            licredityRouterHelper.addDebt(positionId, delta, address(licredity));
            assertEq(licredity.getPositionFungiblesBalance(positionId, address(licredity)), amount);
        } else if (amount > 100 ether) {
            if (amount < 10000 ether) {
                vm.expectRevert(PositionIsUnhealthy.selector);
                licredityRouterHelper.addDebt(positionId, delta, address(this));
            } else {
                vm.expectRevert(DebtLimitExceeded.selector);
                licredityRouterHelper.addDebt(positionId, delta, address(this));
            }
        }
    }

    function test_increaseDebtShare_NonFungible(uint128 amount) public {
        vm.assume(amount < type(uint128).max / 1e6);

        oracleMock.setNonFungibleConfig(getMockFungible(1), 1 ether, 1000);

        uint256 positionId = licredityRouter.open();

        nonFungibleMock.mint(address(licredityRouter), 1);
        licredityRouter.depositNonFungible(positionId, getMockFungible(1));

        (uint256 totalShares, uint256 totalAssets) = licredity.getTotalDebt();
        uint256 delta = amount.toShares(totalAssets, totalShares);

        /// margin requirement = 1 ether * 0.1% = 0.001 ether
        /// max debt = value - margin requirement = 1 ether - 0.001 ether = 0.999 ether
        if (amount <= 0.99 ether) {
            licredityRouterHelper.addDebt(positionId, delta, address(this));
            assertEq(licredity.balanceOf(address(this)), amount);
        } else if (amount < 10000 ether) {
            vm.expectRevert(PositionIsUnhealthy.selector);
            licredityRouterHelper.addDebt(positionId, delta, address(this));
        }
    }

    function test_increaseDebtShare_notEmpty() public {
        uint256 positionId = licredityRouter.open();
        licredityRouter.depositFungible{value: 1 ether}(positionId, Fungible.wrap(ChainInfo.NATIVE), 1 ether);

        licredityRouterHelper.addDebt(positionId, 1, address(this));

        vm.expectRevert(PositionNotEmpty.selector);
        licredityRouter.close(1);
    }

    /// decreaseDebtShare ///

    function test_decreaseDebtShare_notExistPosition() public {
        vm.expectRevert(PositionDoesNotExist.selector);
        licredity.decreaseDebtShare(1, 0, true);
    }

    function test_decreaseDebtShare_useBalance_NotPositionOwner() public {
        uint256 positionId = licredityRouter.open();
        vm.expectRevert(NotPositionOwner.selector);
        licredity.decreaseDebtShare(positionId, 0, true);
    }

    function test_decreaseDebtShare_useBalance(uint128 decreaseAmount) public {
        uint256 positionId = licredityRouter.open();
        uint128 amount = 99 ether;

        (uint256 totalShares, uint256 totalAssets) = licredity.getTotalDebt();
        licredityRouter.depositFungible{value: 1 ether}(positionId, Fungible.wrap(ChainInfo.NATIVE), 1 ether);

        uint256 debtDelta = amount.toShares(totalAssets, totalShares);

        licredityRouterHelper.addDebt(positionId, debtDelta, address(licredity));

        (totalShares, totalAssets) = licredity.getTotalDebt();
        decreaseAmount = uint128(bound(decreaseAmount, 0, 99 ether));

        uint256 decreaseDelta = decreaseAmount.toShares(totalAssets, totalShares);

        vm.expectEmit(true, true, true, false);
        emit WithdrawFungible(positionId, address(0), Fungible.wrap(address(licredity)), amount);
        licredityRouter.decreaseDebtShare(positionId, decreaseDelta, true);
    }

    function test_decreaseDebtShare_notUseBalance() public {
        uint128 decreaseAmount = 1 ether;
        getDebtERC20(address(this), decreaseAmount);

        uint256 positionId = licredityRouter.open();
        uint128 amount = 99 ether;

        (uint256 totalShares, uint256 totalAssets) = licredity.getTotalDebt();
        licredityRouter.depositFungible{value: 1 ether}(positionId, Fungible.wrap(ChainInfo.NATIVE), 1 ether);

        uint256 debtDelta = amount.toShares(totalAssets, totalShares);
        licredityRouterHelper.addDebt(positionId, debtDelta, address(licredity));

        uint256 decreaseDelta = decreaseAmount.toShares(totalAssets, totalShares);

        Fungible.wrap(address(licredity)).transfer(address(licredityRouter), decreaseAmount);

        vm.expectEmit(true, false, false, true);
        emit DecreaseDebtShare(positionId, decreaseDelta, decreaseAmount, false);
        licredityRouter.decreaseDebtShare(positionId, decreaseDelta, false);
    }

    /// withdrawFungible ///

    function test_withdrawFungible_notOwner() public {
        vm.expectRevert(NotPositionOwner.selector);
        licredity.withdrawFungible(1, address(this), Fungible.wrap(address(licredity)), 1);
    }

    function test_withdrawFungible(uint128 withdrawAmount) public {
        withdrawAmount = uint128(bound(withdrawAmount, 0, 2 ether));

        uint256 positionId = licredityRouter.open();

        uint128 amount = 0.99 ether;
        licredityRouter.depositFungible{value: 2 ether}(positionId, Fungible.wrap(ChainInfo.NATIVE), 2 ether);

        (uint256 totalShares, uint256 totalAssets) = licredity.getTotalDebt();
        uint256 delta = amount.toShares(totalAssets, totalShares);
        licredityRouterHelper.addDebt(positionId, delta, address(this));

        if (withdrawAmount <= 1 ether) {
            vm.expectEmit(true, true, true, true);
            emit WithdrawFungible(positionId, user, Fungible.wrap(address(0)), withdrawAmount);
            licredityRouterHelper.withdrawFungible(positionId, user, address(0), withdrawAmount);

            assertEq(user.balance, withdrawAmount);
        } else {
            vm.expectRevert(PositionIsUnhealthy.selector);
            licredityRouterHelper.withdrawFungible(positionId, user, address(0), withdrawAmount);
        }
    }

    /// withdrawNonFungible ///

    function test_withdrawNonFungible_notOwner() public {
        vm.expectRevert(NotPositionOwner.selector);
        licredity.withdrawNonFungible(1, address(this), getMockFungible(1));
    }

    function test_withdrawNonFungible_notInPosition() public {
        uint256 positionId = licredityRouter.open();

        nonFungibleMock.mint(address(licredityRouter), 1);
        licredityRouter.depositNonFungible(positionId, getMockFungible(1));

        vm.expectRevert(NonFungibleNotInPosition.selector);
        licredityRouterHelper.withdrawNonFungible(1, address(this), getMockFungible(20));
    }

    function test_withdrawNonFungible() public {
        uint256 positionId = licredityRouter.open();

        nonFungibleMock.mint(address(licredityRouter), 1);
        licredityRouter.depositNonFungible(positionId, getMockFungible(1));

        vm.expectEmit(true, true, true, false);
        emit WithdrawNonFungible(positionId, user, getMockFungible(1));

        licredityRouterHelper.withdrawNonFungible(1, user, getMockFungible(1));
    }
}
