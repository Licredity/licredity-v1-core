// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title PipsMath
/// @notice Library for performing math operations in pips (1 / 1_000_000)
library PipsMath {
    uint256 internal constant UNIT_PIPS = 1_000_000;

    /// @notice Multiplies `x` by `y` in pips, rounding up
    /// @param x The value to multiply
    /// @param y The pips (e.g., 1_000_000 for 100%) to multiply by
    /// @return z The result of the multiplication, rounded up
    function pipsMulUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly ("memory-safe") {
            z := mul(x, y)
            // Equivalent to `require(y == 0 || x <= type(uint256).max / y)`.
            if iszero(eq(div(z, y), x)) {
                if y {
                    mstore(0x00, 0x2c1dba43) // `PipsMulUpFailed()`.
                    revert(0x1c, 0x04)
                }
            }
            z := add(div(z, UNIT_PIPS), iszero(iszero(mod(z, UNIT_PIPS))))
        }
    }
}
