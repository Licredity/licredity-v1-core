// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {InterestRateLibrary} from "src/types/InterestRate.sol";

library AaveIntertestMath {
    function rayMul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        uint256 ray = InterestRateLibrary.RAY;
        uint256 halfRay = InterestRateLibrary.HALF_RAY;

        // to avoid overflow, a <= (type(uint256).max - halfRay) / b
        assembly {
            if iszero(or(iszero(b), iszero(gt(a, div(sub(not(0), halfRay), b))))) { revert(0, 0) }

            c := div(add(mul(a, b), halfRay), ray)
        }
    }

    function calculateCompoundedInterest(uint256 rate, uint256 exp) internal pure returns (uint256) {
        if (exp == 0) {
            return InterestRateLibrary.RAY;
        }

        uint256 expMinusOne;
        uint256 expMinusTwo;
        uint256 basePowerTwo;
        uint256 basePowerThree;
        unchecked {
            expMinusOne = exp - 1;

            expMinusTwo = exp > 2 ? exp - 2 : 0;

            basePowerTwo =
                rayMul(rate, rate) / (InterestRateLibrary.SECONDS_PER_YEAR * InterestRateLibrary.SECONDS_PER_YEAR);
            basePowerThree = rayMul(basePowerTwo, rate) / InterestRateLibrary.SECONDS_PER_YEAR;
        }

        uint256 secondTerm = exp * expMinusOne * basePowerTwo;
        unchecked {
            secondTerm /= 2;
        }
        uint256 thirdTerm = exp * expMinusOne * expMinusTwo * basePowerThree;
        unchecked {
            thirdTerm /= 6;
        }

        return InterestRateLibrary.RAY + (rate * exp) / InterestRateLibrary.SECONDS_PER_YEAR + secondTerm + thirdTerm;
    }
}
