// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "@forge-std/Test.sol";
import {ILicredity} from "src/interfaces/ILicredity.sol";
import {FungibleState, FungibleStateLibrary} from "src/types/FungibleState.sol";

contract FungibleStateTest is Test {
    function test_FungibleState_packAndUnpack(uint64 index, uint128 balance) public pure {
        FungibleState state = FungibleStateLibrary.from(index, balance);
        assertEq(state.index(), index);
        assertEq(state.balance(), balance);
    }

    function test_fuzz_from(uint256 index, uint256 balance) public {
        if (index > type(uint64).max) {
            vm.expectRevert(ILicredity.MaxFungibleIndexExceeded.selector);
        } else if (balance > type(uint128).max) {
            vm.expectRevert(ILicredity.MaxFungibleBalanceExceeded.selector);
        }

        (, bytes memory data) = address(this).call{value: 0}(abi.encodeCall(this.from, (index, balance)));
        FungibleState state = abi.decode(data, (FungibleState));

        if (index <= type(uint64).max && balance <= type(uint128).max) {
            assertEq(state.index(), index);
            assertEq(state.balance(), balance);
        }
    }

    function from(uint256 index, uint256 balance) public returns (FungibleState) {
        return FungibleStateLibrary.from(index, balance);
    }
}
