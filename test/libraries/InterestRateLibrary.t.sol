// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "@forge-std/Test.sol";
import {InterestRate, InterestRateLibrary} from "src/types/InterestRate.sol";
import {AAVEIntertestMath} from "../utils/AAVEMathInterest.sol";

contract InterestRateLibraryTest is Test {
    function AAVERayMul(uint256 a, uint256 b) public pure returns (uint256) {
        return AAVEIntertestMath.rayMul(a, b);
    }

    function mul(InterestRate a, InterestRate b) public pure returns (InterestRate) {
        return InterestRateLibrary.mul(a, b);
    }

    function test_mul(uint256 x, uint256 y) public view {
        (bool success0, bytes memory result0) =
            address(this).staticcall(abi.encodeWithSignature("AAVERayMul(uint256,uint256)", x, y));
        (bool success1, bytes memory result1) =
            address(this).staticcall(abi.encodeWithSignature("mul(uint256,uint256)", x, y));

        assertEq(success0, success1);
        if (success0) {
            assertEq(abi.decode(result0, (uint256)), abi.decode(result1, (uint256)));
        }
    }

    function AAVECalculateCompoundedInterest(uint256 rate, uint256 elapsed) public pure returns (uint256) {
        return AAVEIntertestMath.calculateCompoundedInterest(rate, elapsed);
    }

    function calculateInterest(InterestRate rate, uint256 principal, uint256 elapsed) public pure returns (uint256) {
        return InterestRateLibrary.calculateInterest(rate, principal, elapsed);
    }

    function test_calculateCompoundedInterest(uint256 yearRate, uint256 elapsed) public view {
        yearRate = bound(yearRate, 1, 3.65e27);
        elapsed = bound(elapsed, 0, 100 * 365 days);

        (bool success0, bytes memory result0) = address(this).staticcall(
            abi.encodeWithSignature("AAVECalculateCompoundedInterest(uint256,uint256)", yearRate, elapsed)
        );
        (bool success1, bytes memory result1) = address(this).staticcall(
            abi.encodeWithSignature("calculateInterest(uint256,uint256,uint256)", yearRate, 1e27, elapsed)
        );
        assertEq(success0, success1);
        if (success0) {
            uint256 aaveResult = abi.decode(result0, (uint256));
            uint256 licredityResult = abi.decode(result1, (uint256)) + 1e27;

            assertApproxEqRel(aaveResult, licredityResult, 0.005e16);
        }
    }
}
