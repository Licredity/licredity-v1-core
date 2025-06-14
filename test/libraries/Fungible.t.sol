// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.20;

// import {Test} from "@forge-std/Test.sol";
// import {Fungible} from "src/types/Fungible.sol";
// import {TestERC20} from "@uniswap-v4-core/test/TestERC20.sol";

// contract FungibleTest is Test {
//     TestERC20 public token;
//     Fungible public constant NATIVE = Fungible.wrap(address(0));

//     function setUp() public {
//         token = new TestERC20(0);
//     }

//     function test_NativeFungible_BalanceOf(address owner, uint256 amount) public {
//         vm.deal(owner, amount);
//         assertEq(NATIVE.balanceOf(owner), amount);
//     }

//     function test_Fungible_BalanceOf(address owner, uint256 amount) public {
//         token.mint(owner, amount);
//         assertEq(Fungible.wrap(address(token)).balanceOf(owner), amount);
//     }
// }
