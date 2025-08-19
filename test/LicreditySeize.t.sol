// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Licredity} from "src/Licredity.sol";
import {Fungible} from "src/types/Fungible.sol";
import {Deployers} from "./utils/Deployer.sol";
import {StateLibrary} from "./utils/StateLibrary.sol";
import {ShareMath} from "./utils/ShareMath.sol";
import {Actions} from "./utils/LicredityRouter.sol";
import {BaseERC20Mock} from "test/mocks/BaseERC20Mock.sol";

contract LicreditySeizeTest is Deployers {
    using StateLibrary for Licredity;
    using ShareMath for uint128;

    error PositionDoesNotExist();
    error PositionIsHealthy();
    error CannotSeizeRegisteredPosition();

    event SeizePosition(
        uint256 indexed positionId,
        address indexed recipient,
        uint256 value,
        uint256 debt,
        uint256 marginRequirement,
        uint256 topup
    );
    event DepositFungible(uint256 indexed positionId, Fungible indexed fungible, uint256 amount);

    BaseERC20Mock public token;

    function setUp() public {
        deployETHLicredityWithUniswapV4();
        deployAndSetOracleMock();
        deployLicredityRouter();

        token = _newAsset(18);

        oracleMock.setFungibleConfig(Fungible.wrap(address(token)), 1 ether, 100_000); // 10%
    }

    function test_seize_positionNotExist() public {
        vm.expectRevert(PositionDoesNotExist.selector);
        licredityRouterHelper.seize(1, msg.sender);
    }

    function test_seize_registeredPosition() public {
        uint256 positionId = licredityRouter.open();

        Actions[] memory actions = new Actions[](2);
        bytes[] memory params = new bytes[](2);

        actions[0] = Actions.ADD_DEBT;
        params[0] = abi.encode(positionId, 1, address(1));
        actions[1] = Actions.SEIZE;
        params[1] = abi.encode(positionId, msg.sender);

        vm.expectRevert(CannotSeizeRegisteredPosition.selector);
        licredityRouter.executeActions(actions, params);
    }

    function test_seize_positionIsHealth() public {
        uint256 positionId = licredityRouter.open();
        vm.expectRevert(PositionIsHealthy.selector);
        seizerRouterHelper.seize(positionId, msg.sender);
    }

    function test_seize_position() public {
        /// deposit 1 ether token
        uint256 positionId = licredityRouter.open();
        token.mint(address(this), 1 ether);
        token.approve(address(licredityRouter), 1 ether);

        licredityRouter.depositFungible(positionId, Fungible.wrap(address(token)), 1 ether);

        /// borrow 0.9 ether debt token
        uint128 borrowAmount = 0.9 ether;
        (uint256 totalShares, uint256 totalAssets) = licredity.getTotalDebt();
        uint256 delta = borrowAmount.toShares(totalAssets, totalShares);

        licredityRouterHelper.addDebt(positionId, delta, address(1));

        /// Position: value = 1 ether, debt = 0.9 ether, margin requirement = 0.1 ether
        /// Set token price to 0.95 ether, margin value = 0.95 ether, value = 0.95 ether
        oracleMock.setFungibleConfig(Fungible.wrap(address(token)), 0.95 ether, 100_000);

        /// seize position
        Actions[] memory actions = new Actions[](2);
        bytes[] memory params = new bytes[](2);

        actions[0] = Actions.SEIZE;
        params[0] = abi.encode(positionId, address(seizerRouter));

        actions[1] = Actions.DEPOSIT_FUNGIBLE;
        params[1] = abi.encode(positionId, Fungible.wrap(address(0)), 0.2 ether);
        // params[1] = abi.encode(positionId, Fungible.wrap(address(token)), 20 ether);

        vm.expectEmit(true, true, false, true);
        emit SeizePosition(positionId, address(seizerRouter), 0.95 ether, 0.9 ether, 0.095 ether, 0);

        seizerRouter.executeActions{value: 0.2 ether}(actions, params);
    }

    function test_seize_positionDeficit() public {
        /// deposit 1 ether token
        uint256 positionId = licredityRouter.open();
        token.mint(address(this), 1 ether);
        token.approve(address(licredityRouter), 1 ether);

        licredityRouter.depositFungible(positionId, Fungible.wrap(address(token)), 1 ether);

        /// borrow 0.9 ether debt token
        uint128 borrowAmount = 0.9 ether;
        (uint256 totalShares, uint256 totalAssets) = licredity.getTotalDebt();
        uint256 delta = borrowAmount.toShares(totalAssets, totalShares);

        licredityRouterHelper.addDebt(positionId, delta, address(1));

        /// Position: value = 1 ether, debt = 0.9 ether, margin requirement = 0.1 ether
        /// Set token price to 0.5 ether, value = 0.5 ether, debt = 0.9 ether
        oracleMock.setFungibleConfig(Fungible.wrap(address(token)), 0.5 ether, 100_000);

        (, uint256 totalDebtBefore) = licredity.getTotalDebt();

        Actions[] memory actions = new Actions[](2);
        bytes[] memory params = new bytes[](2);

        actions[0] = Actions.SEIZE;
        params[0] = abi.encode(positionId, address(seizerRouter));

        actions[1] = Actions.DEPOSIT_FUNGIBLE;
        params[1] = abi.encode(positionId, Fungible.wrap(address(0)), 0.451 ether);

        vm.expectEmit(true, true, false, true);
        emit DepositFungible(positionId, Fungible.wrap(address(licredity)), 0.8 ether);

        seizerRouter.executeActions{value: 0.451 ether}(actions, params);

        (, uint256 totalDebtAfter) = licredity.getTotalDebt();

        assertEq(totalDebtAfter - totalDebtBefore, 0.8 ether); // deficit = 0.4 ether * 2 = 0.8 ether
    }
}
