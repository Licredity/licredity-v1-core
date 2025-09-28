// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Deployers} from "./utils/Deployer.sol";
import {ILicredity} from "src/interfaces/ILicredity.sol";
import {Fungible} from "src/types/Fungible.sol";
import {NonFungible} from "src/types/NonFungible.sol";
import {BaseERC20Mock} from "src/test/BaseERC20Mock.sol";

contract LicredityPositionTest is Deployers {
    Fungible public fungible;
    BaseERC20Mock public token;

    function setUp() public {
        deployETHLicredityWithUniswapV4();
        deployNonFungibleMock();

        token = _newAsset(18);
        fungible = Fungible.wrap(address(token));
    }

    function test_openPosition() public {
        vm.expectEmit(true, true, false, false, address(licredity));
        emit ILicredity.OpenPosition(1, address(this));
        uint256 positionId = licredity.openPosition();
        assertEq(positionId, 1);
        // assertEq(licredity.getPositionOwner(positionId), address(this));

        positionId = licredity.openPosition();
        assertEq(positionId, 2);
        // assertEq(licredity.getPositionOwner(positionId), address(this));
    }

    function test_closeNullPosition() public {
        vm.expectRevert(ILicredity.NotPositionOwner.selector);
        licredity.closePosition(0);
    }

    function test_closeOtherPosition() public {
        vm.prank(address(1));
        uint256 positionId = licredity.openPosition();

        vm.expectRevert(ILicredity.NotPositionOwner.selector);
        licredity.closePosition(positionId);
    }

    function test_closeOpenPosition() public {
        licredity.openPosition();
        // assertEq(licredity.getPositionOwner(1), address(this));

        vm.expectEmit(true, false, false, false, address(licredity));
        emit ILicredity.ClosePosition(1);
        licredity.closePosition(1);

        vm.expectRevert(ILicredity.NotPositionOwner.selector);
        licredity.closePosition(1);
        // assertEq(licredity.getPositionOwner(1), address(0));
    }

    function test_closeNotFungibleEmptyPosition() public {
        uint256 positionId = licredity.openPosition();

        licredity.stageFungible(Fungible.wrap(address(0)));
        licredity.depositFungible{value: 0.1 ether}(positionId);

        vm.expectRevert(ILicredity.PositionNotEmpty.selector);
        licredity.closePosition(1);
    }

    function test_closeNotNonFungibleEmptyPosition() public {
        nonFungibleMock.mint(address(this), 1);
        NonFungible nonFungible = getMockFungible(1);

        uint256 positionId = licredity.openPosition();

        licredity.stageNonFungible(nonFungible);
        nonFungibleMock.transferFrom(address(this), address(licredity), 1);
        licredity.depositNonFungible(positionId);

        vm.expectRevert(ILicredity.PositionNotEmpty.selector);
        licredity.closePosition(1);
    }

    function test_depositFungibleNullPosition() public {
        vm.expectRevert(ILicredity.NotPositionOwner.selector);
        licredity.depositFungible(1);
    }

    function test_depositFungibleWithNative() public {
        uint256 positionId = licredity.openPosition();

        licredity.stageFungible(fungible);
        vm.expectRevert(ILicredity.NativeValueNotZero.selector);
        licredity.depositFungible{value: 0.1 ether}(positionId);
    }

    function test_depositNativeNotStage() public {
        uint256 positionId = licredity.openPosition();

        vm.expectEmit(true, true, false, true, address(licredity));
        emit ILicredity.DepositFungible(positionId, Fungible.wrap(address(0)), 0.1 ether);
        licredity.depositFungible{value: 0.1 ether}(positionId);
    }

    function test_depositERC20NotStage() public {
        uint256 positionId = licredity.openPosition();

        licredity.depositFungible(positionId);
    }

    function test_depositFungible() public {
        token.mint(address(this), 10 ether);

        uint256 positionId = licredity.openPosition();

        licredity.stageFungible(fungible);
        token.transfer(address(licredity), 10 ether);

        vm.expectEmit(true, true, false, true, address(licredity));
        emit ILicredity.DepositFungible(positionId, fungible, 10 ether);
        licredity.depositFungible(positionId);
    }

    function test_depositNonFungible() public {
        nonFungibleMock.mint(address(this), 1);

        uint256 positionId = licredity.openPosition();
        licredity.stageNonFungible(getMockFungible(1));
        nonFungibleMock.transferFrom(address(this), address(licredity), 1);

        vm.expectEmit(true, false, false, false, address(licredity));
        emit ILicredity.DepositNonFungible(positionId, getMockFungible(1));
        licredity.depositNonFungible(positionId);
    }

    function test_stageNonFungibleInLicredity() public {
        nonFungibleMock.mint(address(licredity), 1);
        vm.expectRevert(ILicredity.NonFungibleAlreadyOwned.selector);
        licredity.stageNonFungible(getMockFungible(1));
    }

    function test_depositNonFungibleNullPosition() public {
        vm.expectRevert(ILicredity.NotPositionOwner.selector);
        licredity.depositNonFungible(1);
    }

    function test_depositNonFungibleNotOwned() public {
        nonFungibleMock.mint(address(1), 1);

        uint256 positionId = licredity.openPosition();
        licredity.stageNonFungible(getMockFungible(1));
        vm.expectRevert(ILicredity.NonFungibleNotOwned.selector);
        licredity.depositNonFungible(positionId);
    }
}
