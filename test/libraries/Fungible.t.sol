// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "@forge-std/Test.sol";
import {IERC20} from "@forge-std/interfaces/IERC20.sol";
import {Fungible} from "src/types/Fungible.sol";
import {ChainInfo} from "src/libraries/ChainInfo.sol";
import {DebtTokenMock} from "test/mocks/DebtTokenMock.sol";

contract FungibleTest is Test {
    error NativeTransferFailed();

    DebtTokenMock public token;
    Fungible public constant NATIVE = Fungible.wrap(address(0));
    Fungible public fungible;

    function setUp() public {
        token = new DebtTokenMock("Token", "T", 18);
        fungible = Fungible.wrap(address(token));
    }

    function _newAsset(uint8 decimals) internal returns (Fungible) {
        token = new DebtTokenMock("Token", "T", decimals);
        return Fungible.wrap(address(token));
    }

    function test_Fungible_decimals(uint8 decimals) public {
        Fungible asset = _newAsset(decimals);
        assertEq(asset.decimals(), decimals);
    }

    function test_Native_decimals() public view {
        assertEq(NATIVE.decimals(), ChainInfo.NATIVE_DECIMALS);
    }

    function test_isNative() public {
        assertEq(NATIVE.isNative(), true);
        assertEq(_newAsset(18).isNative(), false);
    }

    function test_Native_balanceOf(address owner, uint256 amount) public {
        vm.deal(owner, amount);
        assertEq(NATIVE.balanceOf(owner), amount);
    }

    function test_Fungible_balanceOf(address owner, uint256 amount) public {
        vm.assume(owner != address(0));
        token.mint(owner, amount);
        assertEq(Fungible.wrap(address(token)).balanceOf(owner), amount);
    }

    function test_Native_transfer(uint256 amount) public {
        address user = address(0xE585379156909287F8aA034B2F4b1Cb88aa3d29D);
        vm.deal(address(this), amount);
        NATIVE.transfer(user, amount);
        assertEq(address(this).balance, 0);
        assertEq(user.balance, amount);
    }

    /// forge-config: default.allow_internal_expect_revert = true
    function test_Native_transfer_error(uint256 amount) public {
        vm.deal(address(this), amount);
        vm.expectRevert();
        NATIVE.transfer(address(0x0a), amount);
    }

    function test_Fungible_transfer(address to, uint256 amount) public {
        vm.assume(to != address(0));
        token.mint(address(this), amount);

        vm.expectCall(address(token), abi.encodeCall(IERC20.transfer, (to, amount)));
        fungible.transfer(to, amount);

        if (to != address(this)) {
            assertEq(token.balanceOf(address(this)), 0);
            assertEq(token.balanceOf(to), amount);
        } else {
            assertEq(token.balanceOf(address(this)), amount);
        }
    }
}
