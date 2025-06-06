// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title SafeCast Library
/// @notice Library for safely casting between different integer types
library SafeCast {
    /// @notice Thrown when an overflow occurs during casting
    error Overflow();

    /// @notice Safely cast a uint256 to a uint64, reverting on overflow
    /// @param x The uint256 value to cast
    /// @return y The casted uint64 value
    function toUint64(uint256 x) internal pure returns (uint64 y) {
        require(x <= type(uint64).max, Overflow());

        y = uint64(x);
    }

    /// @notice Safely cast a uint256 to a uint192, reverting on overflow
    /// @param x The uint256 value to cast
    /// @return y The casted uint192 value
    function toUint192(uint256 x) internal pure returns (uint192 y) {
        require(x <= type(uint192).max, Overflow());

        y = uint192(x);
    }
}
