// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "@forge-std/Test.sol";
import {SafeCast} from "src/libraries/SafeCast.sol";

contract SafeCastTest is Test {
    error Overflow();

    /// forge-config: default.allow_internal_expect_revert = true
    function test_fuzz_toUint64(uint256 x) public {
        if (x <= type(uint64).max) {
            assertEq(SafeCast.toUint64(x), x);
        } else {
            vm.expectRevert(Overflow.selector);
            SafeCast.toUint64(x);
        }
    }

    /// forge-config: default.allow_internal_expect_revert = true
    function test_fuzz_toUint128(uint256 x) public {
        if (x <= type(uint128).max) {
            assertEq(SafeCast.toUint128(x), x);
        } else {
            vm.expectRevert(Overflow.selector);
            SafeCast.toUint128(x);
        }
    }
}
