// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.24;

/// @title FixedPointMath — mulDiv and sqrt helpers
/// @notice Standard full-precision mulDiv (Remco Bloemen's implementation, as
///         used by Uniswap/OZ) and a Babylonian integer sqrt.
library FixedPointMath {
    error MulDivOverflow();

    /// @notice floor(a × b / d) with full 512-bit intermediate precision.
    function mulDiv(uint256 a, uint256 b, uint256 d) internal pure returns (uint256 result) {
        unchecked {
            uint256 prod0;
            uint256 prod1;
            assembly {
                let mm := mulmod(a, b, not(0))
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }
            if (prod1 == 0) {
                return prod0 / d;
            }
            if (d <= prod1) revert MulDivOverflow();
            uint256 remainder;
            assembly {
                remainder := mulmod(a, b, d)
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }
            uint256 twos = d & (0 - d);
            assembly {
                d := div(d, twos)
                prod0 := div(prod0, twos)
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;
            uint256 inverse = (3 * d) ^ 2;
            inverse *= 2 - d * inverse;
            inverse *= 2 - d * inverse;
            inverse *= 2 - d * inverse;
            inverse *= 2 - d * inverse;
            inverse *= 2 - d * inverse;
            inverse *= 2 - d * inverse;
            result = prod0 * inverse;
        }
    }

    /// @notice ceil(a × b / d).
    function mulDivUp(uint256 a, uint256 b, uint256 d) internal pure returns (uint256) {
        uint256 result = mulDiv(a, b, d);
        if (mulmod(a, b, d) > 0) result += 1;
        return result;
    }

    /// @notice floor(sqrt(x)), Babylonian method.
    function sqrt(uint256 x) internal pure returns (uint256 z) {
        if (x == 0) return 0;
        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) {
            xx >>= 128;
            r <<= 64;
        }
        if (xx >= 0x10000000000000000) {
            xx >>= 64;
            r <<= 32;
        }
        if (xx >= 0x100000000) {
            xx >>= 32;
            r <<= 16;
        }
        if (xx >= 0x10000) {
            xx >>= 16;
            r <<= 8;
        }
        if (xx >= 0x100) {
            xx >>= 8;
            r <<= 4;
        }
        if (xx >= 0x10) {
            xx >>= 4;
            r <<= 2;
        }
        if (xx >= 0x4) r <<= 1;
        z = r;
        unchecked {
            z = (z + x / z) >> 1;
            z = (z + x / z) >> 1;
            z = (z + x / z) >> 1;
            z = (z + x / z) >> 1;
            z = (z + x / z) >> 1;
            z = (z + x / z) >> 1;
            z = (z + x / z) >> 1;
            uint256 z1 = x / z;
            if (z1 < z) z = z1;
        }
    }
}
