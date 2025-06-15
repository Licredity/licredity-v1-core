// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "@forge-std/Test.sol";
import {CreditTokenMock} from "test/mocks/CreditTokenMock.sol";

contract CreditTokenTest is Test {
    CreditTokenMock public token;

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function setUp() public {
        token = new CreditTokenMock("CreditToken", "CT", 18);
    }

    function test_metadata() public view {
        assertEq(token.name(), "CreditToken");
        assertEq(token.symbol(), "CT");
        assertEq(token.decimals(), 18);
    }

    function test_mint(address to, uint256 amount) public {
        vm.assume(to != address(0));

        token.mint(to, amount);
        assertEq(token.balanceOf(to), amount);
        assertEq(token.totalSupply(), amount);
    }

    function test_burn(address user, uint256 amount, uint256 otherAmount) public {
        vm.assume(user != address(0));

        if (amount >= otherAmount) {
            token.mint(user, amount);
            token.burn(user, otherAmount);

            assertEq(token.balanceOf(user), amount - otherAmount);
            assertEq(token.totalSupply(), amount - otherAmount);
        } else {
            token.mint(user, otherAmount);
            token.burn(user, amount);

            assertEq(token.balanceOf(user), otherAmount - amount);
            assertEq(token.totalSupply(), otherAmount - amount);
        }
    }

    function test_approve(address from, address spender, uint256 amount) public {
        vm.assume(from != address(0));
        vm.assume(spender != address(0));

        vm.startPrank(from);

        vm.expectEmit(true, true, false, true);
        emit Approval(from, spender, amount);

        token.approve(spender, amount);

        vm.stopPrank();
        assertEq(token.allowance(from, spender), amount);
    }

    function test_transfer(address from, address to, uint256 amount, uint256 mintAmount) public {
        vm.assume(from != address(0));
        vm.assume(to != address(0));
        vm.assume(mintAmount >= amount);

        token.mint(from, mintAmount);

        vm.startPrank(from);

        vm.expectEmit(true, true, false, true);
        emit Transfer(from, to, amount);
        token.transfer(to, amount);

        vm.stopPrank();

        if (from == to) {
            assertEq(token.balanceOf(from), mintAmount);
            assertEq(token.balanceOf(to), mintAmount);
        } else {
            assertEq(token.balanceOf(from), mintAmount - amount);
            assertEq(token.balanceOf(to), amount);
        }

        assertEq(token.totalSupply(), mintAmount);
    }

    function test_transferFrom(
        address from,
        address to,
        address spender,
        uint256 mintAmount,
        uint256 approveAmount,
        uint256 amount
    ) public {
        vm.assume(from != address(0));
        vm.assume(to != address(0));
        vm.assume(spender != address(0));

        vm.assume(mintAmount >= amount);
        vm.assume(approveAmount >= amount);

        token.mint(from, mintAmount);
        vm.prank(from);
        token.approve(spender, approveAmount);

        vm.prank(spender);
        token.transferFrom(from, to, amount);

        if (from == to) {
            assertEq(token.balanceOf(from), mintAmount);
            assertEq(token.balanceOf(to), mintAmount);
        } else {
            assertEq(token.balanceOf(from), mintAmount - amount);
            assertEq(token.balanceOf(to), amount);
        }

        if (approveAmount != type(uint256).max) {
            assertEq(token.allowance(from, spender), approveAmount - amount);
        } else {
            assertEq(token.allowance(from, spender), type(uint256).max);
        }
    }
}
