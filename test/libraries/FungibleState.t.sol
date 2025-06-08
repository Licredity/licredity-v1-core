// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "@forge-std/Test.sol";
import {FungibleState, toFungibleState} from "src/types/FungibleState.sol";

contract FungibleStateTest is Test {
    function test_FungibleState_packAndUnpack(uint64 index, uint192 balance) public pure {
        FungibleState state = toFungibleState(index, balance);
        assertEq(state.index(), index);
        assertEq(state.balance(), balance);
    }
}
