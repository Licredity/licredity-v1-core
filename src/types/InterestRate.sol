// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {FullMath} from "../libraries/FullMath.sol";

/// @title InterestRate
/// @notice Represents a interest rate
/// @dev Interest rate has 27 decimal places (a ray)
type InterestRate is uint256;

using InterestRateLibrary for InterestRate global;

/// @title InterestRateLibrary
/// @notice Library for managing interest rates
library InterestRateLibrary {
    using FullMath for uint256;

    uint256 private constant SECONDS_PER_YEAR = 365 days;
    uint256 private constant RAY = 1e27;
    uint256 private constant HALF_RAY = 0.5e27;

    /// @notice Multiplies two interest rates, "normal" rouding (half up)
    /// @param x The first interest rate
    /// @param y The second interest rate
    /// @return z The product of the two interest rates
    function mul(InterestRate x, InterestRate y) internal pure returns (InterestRate z) {
        assembly {
            // to avoid overflow, x <= (type(uint256).max - HALF_RAY) / y
            if iszero(or(iszero(y), iszero(gt(x, div(sub(not(0), HALF_RAY), y))))) {
                mstore(0x00, 0x35278d12) // 'Overflow()'
                revert(0x1c, 0x04)
            }

            z := div(add(mul(x, y), HALF_RAY), RAY)
        }
    }

    /// @notice Calculates the interest accrued over a period of time
    /// @param rate The interest rate
    /// @param principal The principal amount
    /// @param elapsed The time elapsed in seconds
    /// @return interest The interest accrued
    function calculateInterest(InterestRate rate, uint256 principal, uint256 elapsed)
        internal
        pure
        returns (uint256 interest)
    {
        uint256 expMinusOne;
        uint256 expMinusTwo;
        uint256 basePowerTwo;
        uint256 basePowerThree;
        unchecked {
            expMinusOne = elapsed - 1;
            expMinusTwo = elapsed > 2 ? elapsed - 2 : 0;
            basePowerTwo = InterestRate.unwrap(mul(rate, rate)) / (SECONDS_PER_YEAR * SECONDS_PER_YEAR);
            basePowerThree = InterestRate.unwrap(mul(InterestRate.wrap(basePowerTwo), rate)) / SECONDS_PER_YEAR;
        }

        uint256 firstTerm = InterestRate.unwrap(rate).fullMulDiv(elapsed, SECONDS_PER_YEAR);
        uint256 secondTerm = basePowerTwo.fullMulDiv(elapsed * expMinusOne, 2);
        uint256 thirdTerm = basePowerThree.fullMulDiv(elapsed * expMinusOne * expMinusTwo, 6);

        interest = principal.fullMulDivUp(firstTerm + secondTerm + thirdTerm, RAY);
    }
}
