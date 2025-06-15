// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "@forge-std/Test.sol";
import {Fungible} from "src/types/Fungible.sol";
import {DebtTokenMock} from "test/mocks/DebtTokenMock.sol";

contract FungibleTest is Test {
    DebtTokenMock public token;
    Fungible public constant NATIVE = Fungible.wrap(address(0));

    function setUp() public {
        token = new DebtTokenMock("Token", "T", 18);
    }

    function _newAsset(uint8 decimals) internal returns (Fungible) {
        token = new DebtTokenMock("Token", "T", decimals);
        return Fungible.wrap(address(token));
    }

    function test_decimals(uint8 decimals) public {
        Fungible asset = _newAsset(decimals);
        assertEq(asset.decimals(), decimals);
    }

    function test_isNative() public {
        assertEq(NATIVE.isNative(), true);
        assertEq(_newAsset(18).isNative(), false);
    }

    // function test_NativeFungible_BalanceOf(address owner, uint256 amount) public {
    //     vm.deal(owner, amount);
    //     assertEq(NATIVE.balanceOf(owner), amount);
    // }

    // function test_Fungible_BalanceOf(address owner, uint256 amount) public {
    //     token.mint(owner, amount);
    //     assertEq(Fungible.wrap(address(token)).balanceOf(owner), amount);
    // }
}
