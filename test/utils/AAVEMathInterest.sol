// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

uint256 constant SECONDS_PER_YEAR = 365 days;
uint256 constant RAY = 1e27;
uint256 constant HALF_RAY = 0.5e27;

library AAVEIntertestMath {
    function rayMul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // to avoid overflow, a <= (type(uint256).max - HALF_RAY) / b
        assembly {
            if iszero(or(iszero(b), iszero(gt(a, div(sub(not(0), HALF_RAY), b))))) { revert(0, 0) }

            c := div(add(mul(a, b), HALF_RAY), RAY)
        }
    }

    function calculateCompoundedInterest(uint256 rate, uint256 exp) internal pure returns (uint256) {
        if (exp == 0) {
            return RAY;
        }

        uint256 expMinusOne;
        uint256 expMinusTwo;
        uint256 basePowerTwo;
        uint256 basePowerThree;
        unchecked {
            expMinusOne = exp - 1;

            expMinusTwo = exp > 2 ? exp - 2 : 0;

            basePowerTwo = rayMul(rate, rate) / (SECONDS_PER_YEAR * SECONDS_PER_YEAR);
            basePowerThree = rayMul(basePowerTwo, rate) / SECONDS_PER_YEAR;
        }

        uint256 secondTerm = exp * expMinusOne * basePowerTwo;
        unchecked {
            secondTerm /= 2;
        }
        uint256 thirdTerm = exp * expMinusOne * expMinusTwo * basePowerThree;
        unchecked {
            thirdTerm /= 6;
        }

        return RAY + (rate * exp) / SECONDS_PER_YEAR + secondTerm + thirdTerm;
    }
}
