// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title Math Libaray
/// @notice Library for performing mathematical operations
library Math {
    uint16 internal constant UNIT_BASIS_POINTS = 10000;

    /// @notice Calculates `floor(x * y / d)` with full precision, throws if result overflows a uint256 or when `d` is zero.
    /// @param x The first multiplicand
    /// @param y The second multiplicand
    /// @param d The divisor
    /// @return z The result of the calculation
    /// @dev Credit to Solady under MIT license: https://github.com/Vectorized/solady/blob/main/src/utils/FixedPointMathLib.sol
    function fullMulDiv(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 z) {
        assembly ("memory-safe") {
            // 512-bit multiply `[p1 p0] = x * y`.
            // Compute the product mod `2**256` and mod `2**256 - 1`
            // then use the Chinese Remainder Theorem to reconstruct
            // the 512 bit result. The result is stored in two 256
            // variables such that `product = p1 * 2**256 + p0`.

            // Temporarily use `z` as `p0` to save gas.
            z := mul(x, y) // Lower 256 bits of `x * y`.
            for {} 1 {} {
                // If overflows.
                if iszero(mul(or(iszero(x), eq(div(z, x), y)), d)) {
                    let mm := mulmod(x, y, not(0))
                    let p1 := sub(mm, add(z, lt(mm, z))) // Upper 256 bits of `x * y`.

                    /*------------------- 512 by 256 division --------------------*/

                    // Make division exact by subtracting the remainder from `[p1 p0]`.
                    let r := mulmod(x, y, d) // Compute remainder using mulmod.
                    let t := and(d, sub(0, d)) // The least significant bit of `d`. `t >= 1`.
                    // Make sure `z` is less than `2**256`. Also prevents `d == 0`.
                    // Placing the check here seems to give more optimal stack operations.
                    if iszero(gt(d, p1)) {
                        mstore(0x00, 0xae47f702) // `FullMulDivFailed()`.
                        revert(0x1c, 0x04)
                    }
                    d := div(d, t) // Divide `d` by `t`, which is a power of two.
                    // Invert `d mod 2**256`
                    // Now that `d` is an odd number, it has an inverse
                    // modulo `2**256` such that `d * inv = 1 mod 2**256`.
                    // Compute the inverse by starting with a seed that is correct
                    // correct for four bits. That is, `d * inv = 1 mod 2**4`.
                    let inv := xor(2, mul(3, d))
                    // Now use Newton-Raphson iteration to improve the precision.
                    // Thanks to Hensel's lifting lemma, this also works in modular
                    // arithmetic, doubling the correct bits in each step.
                    inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**8
                    inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**16
                    inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**32
                    inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**64
                    inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**128
                    z :=
                        mul(
                            // Divide [p1 p0] by the factors of two.
                            // Shift in bits from `p1` into `p0`. For this we need
                            // to flip `t` such that it is `2**256 / t`.
                            or(mul(sub(p1, gt(r, z)), add(div(sub(0, t), t), 1)), div(sub(z, r), t)),
                            mul(sub(2, mul(d, inv)), inv) // inverse mod 2**256
                        )
                    break
                }
                z := div(z, d)
                break
            }
        }
    }

    /// @notice Calculates `ceiling(x * y / d)` with full precision, throws if result overflows a uint256 or when `d` is zero.
    /// @param x The first multiplicand
    /// @param y The second multiplicand
    /// @param d The divisor
    /// @return z The result of the calculation
    /// @dev Credit to Solady under MIT license: https://github.com/Vectorized/solady/blob/main/src/utils/FixedPointMathLib.sol
    function fullMulDivUp(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 z) {
        z = fullMulDiv(x, y, d);
        assembly ("memory-safe") {
            if mulmod(x, y, d) {
                z := add(z, 1)
                if iszero(z) {
                    mstore(0x00, 0x5162f02f) // `FullMulDivUpFailed()`.
                    revert(0x1c, 0x04)
                }
            }
        }
    }

    /// @notice Multiplies `x` by `y` in basis points, rounding up
    /// @param x The value to multiply
    /// @param y The basis points to multiply by, represented as a `uint16` (e.g., 10000 for 100%)
    /// @return z The result of the multiplication, rounded up
    function mulBpsUp(uint256 x, uint16 y) internal pure returns (uint256 z) {
        assembly ("memory-safe") {
            y := and(y, 0xffff)
            z := mul(x, y)
            // Equivalent to `require(y == 0 || x <= type(uint256).max / y)`.
            if iszero(eq(div(z, y), x)) {
                if y {
                    mstore(0x00, 0xdc90492a) // `MulBpsUpFailed()`.
                    revert(0x1c, 0x04)
                }
            }
            z := add(div(z, UNIT_BASIS_POINTS), iszero(iszero(mod(z, UNIT_BASIS_POINTS))))
        }
    }
}
