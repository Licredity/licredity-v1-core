// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title SafeCast
/// @notice Library for safe casting between types
library SafeCast {
    /// @notice Converts a uint256 to a uint64, reverting on overflow
    /// @param x The uint256 value to convert
    /// @return y The converted uint64 value
    function toUint64(uint256 x) internal pure returns (uint64 y) {
        assembly ("memory-safe") {
            if gt(x, 0xffffffffffffffff) {
                mstore(0x00, 0x35278d12) // 'Overflow()'
                revert(0x1c, 0x04)
            }

            y := x
        }
    }

    /// @notice Converts a uint256 to a uint128, reverting on overflow
    /// @param x The uint256 value to convert
    /// @return y The converted uint128 value
    function toUint128(uint256 x) internal pure returns (uint128 y) {
        assembly ("memory-safe") {
            if gt(x, 0xffffffffffffffffffffffffffffffff) {
                mstore(0x00, 0x35278d12) // 'Overflow()'
                revert(0x1c, 0x04)
            }

            y := x
        }
    }
}
