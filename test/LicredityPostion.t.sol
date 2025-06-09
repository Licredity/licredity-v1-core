// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Deployers} from "./utils/Deployer.sol";
import {Fungible} from "src/types/Fungible.sol";
import {NonFungible} from "src/types/NonFungible.sol";

contract LicredityPositionTest is Deployers {
    error NotPositionOwner();
    error PositionNotEmpty();
    error PositionDoesNotExist();
    error NonZeroNativeValue();

    event OpenPosition(uint256 indexed positionId, address indexed owner);
    event ClosePosition(uint256 indexed positionId);
    event DepositFungible(uint256 indexed positionId, Fungible indexed fungible, uint256 amount);

    Fungible public fungible;

    function setUp() public {
        deployFreshETHLicredity();
        deployNonFungibleMock();
        deployFungibleMock();

        fungible = Fungible.wrap(address(fungibleMock));
    }

    function test_openPosition() public {
        vm.expectEmit(true, true, false, false, address(licredity));
        emit OpenPosition(1, address(this));
        uint256 positionId = licredity.open();
        assertEq(positionId, 1);

        positionId = licredity.open();
        assertEq(positionId, 2);
    }

    function test_closeNullPosition() public {
        vm.expectRevert(NotPositionOwner.selector);
        licredity.close(0);
    }

    function test_closeOpenPosition() public {
        licredity.open();
        vm.expectEmit(true, false, false, false, address(licredity));
        emit ClosePosition(1);
        licredity.close(1);
    }

    function test_closeNotFungibleEmptyPosition() public {
        uint256 postionId = licredity.open();

        licredity.stageFungible(Fungible.wrap(address(0)));
        licredity.depositFungible{value: 0.1 ether}(postionId);

        vm.expectRevert(PositionNotEmpty.selector);
        licredity.close(1);
    }

    function test_closeNotNonFungibleEmptyPosition() public {
        nonFungibleMock.mint(address(this), 1);
        NonFungible nonFungible = getMockFungible(1);

        uint256 postionId = licredity.open();

        licredity.stageNonFungible(nonFungible);
        nonFungibleMock.transferFrom(address(this), address(licredity), 1);
        licredity.depositNonFungible(postionId);

        vm.expectRevert(PositionNotEmpty.selector);
        licredity.close(1);
    }

    // TODO: close position when not zero debt share

    function test_depositNullPosition() public {
        vm.expectRevert(PositionDoesNotExist.selector);
        licredity.depositFungible(0);
    }

    function test_depositNativeNotStage() public {
        uint256 positionId = licredity.open();

        vm.expectEmit(true, true, false, true, address(licredity));
        emit DepositFungible(positionId, Fungible.wrap(address(0)), 0.1 ether);
        licredity.depositFungible{value: 0.1 ether}(positionId);
    }

    // TODO: need discuss
    function test_depositERC20NotStage() public {
        uint256 positionId = licredity.open();

        licredity.depositFungible(positionId);
    }

    function test_depositFungible() public {
        fungibleMock.mint(address(this), 10 ether);
        uint256 positionId = licredity.open();

        licredity.stageFungible(fungible);
        fungibleMock.transfer(address(licredity), 10 ether);

        vm.expectEmit(true, true, false, true, address(licredity));
        emit DepositFungible(positionId, fungible, 10 ether);
        licredity.depositFungible(positionId);
    }

    function test_depositFungibleWithNative() public {
        uint256 positionId = licredity.open();

        licredity.stageFungible(fungible);
        vm.expectRevert(NonZeroNativeValue.selector);
        licredity.depositFungible{value: 0.1 ether}(positionId);
    }
}
