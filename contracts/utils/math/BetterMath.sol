// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../constants/Constants.sol";

struct Uint512 {
    uint256 hi; // 256 most significant bits
    uint256 lo; // 256 least significant bits
}

library BetterMath {

    using BetterMath for uint256;
    
    /* ---------------------------------------------------------------------- */
    /*                                Constants                               */
    /* ---------------------------------------------------------------------- */

    uint8 constant ERC20_DEFAULT_DECIMALS = 18;
    uint224 constant Q112 = 2**112;

    /* ---------------------------------------------------------------------- */
    /*                                 Errors                                 */
    /* ---------------------------------------------------------------------- */

    error Overflow();
  
    /**
     * @dev Muldiv operation overflow.
     */
    error MathOverflowedMulDiv();

    /* ---------------------------------------------------------------------- */
    /*                                 Structs                                */
    /* ---------------------------------------------------------------------- */

    enum Rounding {
        Floor, // Toward negative infinity
        Ceil, // Toward positive infinity
        Trunc, // Toward zero
        Expand // Away from zero
    }

    /* ---------------------------------------------------------------------- */
    /*                              Unsigned Math                             */
    /* ---------------------------------------------------------------------- */

    /**
     * @dev Returns the smallest of two numbers.
     */
    function _min(
        uint256 a,
        uint256 b
    ) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function _max(
        uint256 a,
        uint256 b
    ) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    function _asc(uint256 a, uint256 b)
    internal pure returns(uint256 min, uint256 max) {
        require(a != b);
        min = a._min(b);
        max = min == a
        ? b
        : a;
    }

    function _diff(uint256 a, uint256 b)
    internal pure returns(uint256 diff) {
        (uint256 min, uint256 max) = a._asc(b);
        return max - min;
    }

    function _mod(
        uint256 a,
        uint256 b
    ) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }

    function _safeHalf(
        uint256 value
    ) internal pure returns(uint256 safeHalf) {
        safeHalf = value / 2;
        if(value._mod(2) == 0) {
            return safeHalf;
        }
        return value - safeHalf;
    }

    function _convertDecimalsFromTo(
        uint256 amount,
        uint8 amountDecimals,
        uint8 targetDecimals
    ) internal pure returns(uint256 convertedAmount) {
        if(amountDecimals == targetDecimals) {
            return amount;
        }
        convertedAmount = amountDecimals > targetDecimals
            ? amount / 10**(amountDecimals - targetDecimals)
            : amount * 10**(targetDecimals - amountDecimals);
    }

    function _precision(
        uint256 value,
        uint8 precision,
        uint8 targetPrecision
    ) internal pure returns(uint256 preciseValue) {
        preciseValue = value._convertDecimalsFromTo(
            precision,
            targetPrecision
        );
    }

    function _normalize(
        uint256 value
    ) internal pure returns(uint256) {
        return value._precision(ERC20_DEFAULT_DECIMALS, 2);
    }

    /* ---------------------------------------------------------------------- */
    /*                          Unsafe Unsigned Math                          */
    /* ---------------------------------------------------------------------- */

    /**
     * @dev returns `(x + y) % 2 ^ 256`
     */
    function _unsafeAdd(uint256 x, uint256 y)
    private pure returns (uint256) {
        unchecked {
            return x + y;
        }
    }

    /**
     * @dev returns `(x - y) % 2 ^ 256`
     */
    function _unsafeSub(uint256 x, uint256 y)
    private pure returns (uint256) {
        unchecked {
            return x - y;
        }
    }

    /**
     * @dev returns `(x * y) % 2 ^ 256`
     */
    function _unsafeMul(uint256 x, uint256 y)
    private pure returns (uint256) {
        unchecked {
            return x * y;
        }
    }

    /* ---------------------------------------------------------------------- */
    /*                           Safe Unsigned Math                           */
    /* ---------------------------------------------------------------------- */

    /**
     * @dev returns `x * y % (2 ^ 256 - 1)`
     */
    function _mulModMax(uint256 x, uint256 y)
    private pure returns (uint256) {
        return mulmod(x, y, type(uint256).max);
    }

    /* ---------------------------------------------------------------------- */
    /*                                  Roots                                 */
    /* ---------------------------------------------------------------------- */

    function _sqrt(uint256 x)
    internal pure returns (uint z) {
        assembly {
            // Start off with z at 1.
            z := 1

            // Used below to help find a nearby power of 2.
            let y := x

            // Find the lowest power of 2 that is at least sqrt(x).
            if iszero(lt(y, 0x100000000000000000000000000000000)) {
                y := shr(128, y) // Like dividing by 2 ** 128.
                z := shl(64, z) // Like multiplying by 2 ** 64.
            }
            if iszero(lt(y, 0x10000000000000000)) {
                y := shr(64, y) // Like dividing by 2 ** 64.
                z := shl(32, z) // Like multiplying by 2 ** 32.
            }
            if iszero(lt(y, 0x100000000)) {
                y := shr(32, y) // Like dividing by 2 ** 32.
                z := shl(16, z) // Like multiplying by 2 ** 16.
            }
            if iszero(lt(y, 0x10000)) {
                y := shr(16, y) // Like dividing by 2 ** 16.
                z := shl(8, z) // Like multiplying by 2 ** 8.
            }
            if iszero(lt(y, 0x100)) {
                y := shr(8, y) // Like dividing by 2 ** 8.
                z := shl(4, z) // Like multiplying by 2 ** 4.
            }
            if iszero(lt(y, 0x10)) {
                y := shr(4, y) // Like dividing by 2 ** 4.
                z := shl(2, z) // Like multiplying by 2 ** 2.
            }
            if iszero(lt(y, 0x8)) {
                // Equivalent to 2 ** z.
                z := shl(1, z)
            }

            // Shifting right by 1 is like dividing by 2.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // Compute a rounded down version of z.
            let zRoundDown := div(x, z)

            // If zRoundDown is smaller, use it.
            if lt(zRoundDown, z) {
                z := zRoundDown
            }
        }
    }

    /* ---------------------------------------------------------------------- */
    /*                             Percentage Math                            */
    /* ---------------------------------------------------------------------- */

    /**
     * 0.01% = 100
     * 0.1% = 1_000
     * 1% = 10_000
     * 5% = 50_000
     * 10% = 100_000
     * 25% = 250_000
     * 50% = 500_000
     * 75% = 750_000
     * 100% = 1_000_000
     */

    /**
     * @dev Returns the part of the total that is the percentage of the total.
     */
    function _percentageOfPPM(
        uint256 total,
        uint256 percentage
    ) internal pure returns (uint256 part) {
        return (total * percentage) / PPM_RESOLUTION;
    }

    /**
     * @dev Returns the percentage of which part is of the total.
     */
    function _percentageOfTotalPPM(
        uint256 part,
        uint256 total
    ) internal pure returns (uint256 percentage) {
        return (part * PPM_RESOLUTION) / total;
    }

    /**
     * @dev Returns the total of which the part is the percentage.
     */
    function _totalFromPercentageOfPPM(
        uint256 part,
        uint256 percentage
    ) internal pure returns (uint256 total) {
        return (part * PPM_RESOLUTION) / percentage;
    }

    /**
     * 10 = 0.01%
     * 30 = 0.03%
     * 100 = 0.1%
     * 300 = 0.3%
     * 1000 = 1%
     * 3000 = 3%
     * 5000 = 5%
     * 10000 = 10%
     */

    /**
     * @dev Expects percentage to be trailed by 000,
     */
    function _percentageAmountExpanded(
        uint256 total_, uint256 percentage_
    ) internal pure returns ( uint256 percentAmount_ ) {
        return ( ( total_ * percentage_ ) / 100000 );
    }

    function _percentageOfTotalExpanded(uint256 part_, uint256 total_)
    internal pure returns ( uint256 percent_ ) {
        return ( (part_ * 100000) / total_ );
    }

    function calculateGrossAmount(uint256 netAmount, uint256 feeBps) internal pure returns (uint256) {
        // Ensure fee is less than 100% (100,000 bps in this system)
        require(feeBps < 100000, "Fee cannot be 100% or more");
        
        // Calculate denominator
        uint256 denominator = 100000 - feeBps;
        
        // Ceiling division to calculate gross amount
        uint256 grossAmount = (netAmount * 100000 + denominator - 1) / denominator;
        
        return grossAmount;
    }

    /* ------------------------------- Shares ------------------------------- */

    function _proportionalSplit(
        uint256 ownedShares,
        uint256 totalShares,
        uint256 totalReserveA,
        uint256 totalReserveB
    ) internal pure returns(
        uint256 shareA,
        uint256 shareB
    ) {
        // shareA = ((ownedShares * totalReserveA) / totalShares);
        shareA = _shareOfProportionalSplit(ownedShares, totalShares, totalReserveA);
        // shareB = ((ownedShares * totalReserveB) / totalShares);
        shareB = _shareOfProportionalSplit(ownedShares, totalShares, totalReserveB);
    }

    function _shareOfProportionalSplit(
        uint256 ownedLPAmount,
        uint256 lpTotalSupply,
        uint256 totalReserveA
    ) internal pure returns(uint256 ownedReserveA) {
        ownedReserveA = ((ownedLPAmount * totalReserveA) / lpTotalSupply);
    }

    // Shares are just a way to calculate percentages using integers and state.

    // tag::_decimalsOffset()[]
    /**
     * @return The precision offset to use with the underlying asset used as the underlying reserve.
     */
    function _decimalsOffset()
    internal pure returns (uint8) {
        // Return the default precision offset.
        return 0;
        // return 1;
    }
    // end::_decimalsOffset()[]

    // tag::_convertToShares[]
    /**
     * @dev Internal conversion function (from assets to shares) with support for rounding direction.
     * @param assets The amount of assets from which to calculate equivalent shares.
     * @param reserve The reserve amount of which to calculate shares.
     * @return shares The equivalent amount of shares for `assets` of `reserve`.
     */
    function _convertToShares(
        uint256 assets,
        uint256 reserve,
        uint256 totalShares
    ) internal pure returns (uint256 shares) {
        shares = _convertToShares(
            assets,
            reserve,
            totalShares,
            _decimalsOffset(),
            Rounding.Floor
        );
    }
    // end::_convertToShares[]

    // tag::_convertToShares(uint256,uint256)[]
    /**
     * @dev Internal conversion function (from assets to shares) with support for rounding direction.
     * @param assets The amount of assets from which to calculate equivalent shares.
     * @param reserve The reserve amount of which to calculate shares.
     * @return shares The equivalent amount of shares for `assets` of `reserve`.
     */
    function _convertToShares(
        uint256 assets,
        uint256 reserve,
        uint256 totalShares,
        uint8 decimalOffset
    ) internal pure returns (uint256 shares) {
        shares = _convertToShares(
            assets,
            reserve,
            totalShares,
            decimalOffset,
            Rounding.Floor
        );
    }
    // end::_convertToShares(uint256,uint256)[]

    // tag::_convertToShares(uint256,uint256,Math.Rounding)[]
    /**
     * @dev Internal conversion function (from assets to shares) with support for rounding direction.
     * @param assets The amount of assets from which to calculate equivalent sharres.
     * @param reserve The reserve amount of which to calculate shares.
     * @param rounding The desired rounding to apply to calculated `shares`
     * @return shares The equivalent amount of shares for `assets` of `reserve`.
     */
    function _convertToShares(
        uint256 assets,
        uint256 reserve,
        uint256 totalShares,
        uint8 decimalOffset,
        Rounding rounding
    ) internal pure returns (uint256 shares) {
        shares = assets._mulDiv(
            // Offset the decimals to minimize frontrun attacks.
            totalShares + 10 ** decimalOffset,
            reserve + 1,
            rounding
        );
    }
    // end::_convertToShares(uint256,uint256,Math.Rounding)[]

    // tag::_convertToAssets[]
    /**
     * @dev Internal conversion function (from shares to assets) with support for rounding direction.
     * @param shares The amount of shares from which to calculate the equivalent assets.
     * @param reserve The reserve amount of which to calculate assets.
     * @return The equivalent amount of assets for `shares` of `reserve`.
     */
    function _convertToAssets(
        uint256 shares,
        uint256 reserve,
        uint256 totalShares
    ) internal pure returns (uint256) {
        return _convertToAssets(
            shares,
            reserve,
            totalShares,
            _decimalsOffset(),
            Rounding.Floor
        );
    }
    // end::_convertToAssets[]

    // tag::_convertToAssets(uint256,uint256)[]
    /**
     * @dev Internal conversion function (from shares to assets) with support for rounding direction.
     * @param shares The amount of shares from which to calculate the equivalent assets.
     * @param reserve The reserve amount of which to calculate assets.
     * @return The equivalent amount of assets for `shares` of `reserve`.
     */
    function _convertToAssets(
        uint256 shares,
        uint256 reserve,
        uint256 totalShares,
        uint8 decimalOffset
    ) internal pure returns (uint256) {
        return _convertToAssets(
            shares,
            reserve,
            totalShares,
            decimalOffset,
            Rounding.Floor
        );
    }
    // end::_convertToAssets(uint256,uint256)[]
    
    // tag::_convertToAssets(uint256,uint256,Math.Rounding)[]
    /**
     * @dev Internal conversion function (from shares to assets) with support for rounding direction.
     * @param shares The amount of shares from which to calculate the equivalent assets.
     * @param reserve The reserve amount of which to calculate assets.
     * @param rounding The desired rounding to apply to calculated `shares`
     * @return The equivalent amount of assets for `shares` of `reserve`.
     */
    function _convertToAssets(
        uint256 shares,
        uint256 reserve,
        uint256 totalShares,
        uint8 decimalOffset,
        Rounding rounding
    ) internal pure returns (uint256) {
        // Calculate the amount of asset due for a given amount of shares.
        // Multiply the shares quote by the reserve, then divide by the total shares.
        return shares._mulDiv(
            reserve + 1,
            // Undo the precision offset done during shares conversion.
            totalShares + 10 ** decimalOffset,
            rounding
        );
    }
    // end::_convertToAssets(uint256,uint256,Math.Rounding)[]

    /* ---------------------------------------------------------------------- */
    /*                             Fractional Math                            */
    /* ---------------------------------------------------------------------- */

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or
     * denominator == 0.
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv) with further edits by
     * Uniswap Labs also under MIT license.
     */
    function _mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0 = x * y; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            if (denominator <= prod1) {
                revert MathOverflowedMulDiv();
            }

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator.
            // Always >= 1. See https://cs.stackexchange.com/q/138556/92363.

            uint256 twos = denominator & (0 - denominator);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also
            // works in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    function _mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // Divide z by the denominator.
            z := div(z, denominator)
        }
    }

    /**
     * @dev Returns whether a provided rounding mode is considered rounding up for unsigned integers.
     */
    function _unsignedRoundsUp(
        Rounding rounding
    ) internal pure returns (bool) {
        return uint8(rounding) % 2 == 1;
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function _mulDiv(
        uint256 x, 
        uint256 y, 
        uint256 denominator, 
        Rounding rounding
    )
    internal pure returns (uint256) {
        uint256 result = _mulDiv(x, y, denominator);
        if (_unsignedRoundsUp(rounding) && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /* ---------------------------- WAD/RAY Math ---------------------------- */

    function _mulWadDown(uint256 x, uint256 y)
    internal pure returns (uint256) {
        return _mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function _divWadDown(uint256 x, uint256 y)
    internal pure returns (uint256) {
      // require( (y != 0), "FixedPointWadMathLib:_divWadDown:: Attempting to divide by 0");
      return _mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    /* ------------------------------ UQ112x112 ----------------------------- */

    // uint224 constant Q112 = 2**112;

    // encode a uint112 as a UQ112x112
    function _encode(uint112 y)
    internal pure returns (uint224 z) {
        z = uint224(y) * Q112; // never overflows
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function _uqdiv(uint224 x, uint112 y)
    internal pure returns (uint224 z) {
        z = x / uint224(y);
    }

    /* ---------------------------------------------------------------------- */
    /*                              512-bit Math                              */
    /* ---------------------------------------------------------------------- */

    /**
     * @dev returns the value of `x * y`
     */
    function _mul512(uint256 x, uint256 y)
    internal pure returns (Uint512 memory) {
        uint256 p = _mulModMax(x, y);
        uint256 q = _unsafeMul(x, y);
        if (p >= q) {
            return Uint512({hi: p - q, lo: q});
        }
        return Uint512({hi: _unsafeSub(p, q) - 1, lo: q});
    }

    /**
     * @dev returns the value of `x / pow2n`, given that `x` is divisible by `pow2n`
     */
    function _div512(Uint512 memory x, uint256 pow2n)
    internal pure returns (uint256) {
        uint256 pow2nInv = _unsafeAdd(_unsafeSub(0, pow2n) / pow2n, 1); // `1 << (256 - n)`
        return _unsafeMul(x.hi, pow2nInv) | (x.lo / pow2n); // `(x.hi << (256 - n)) | (x.lo >> n)`
    }

    function _div256(Uint512 memory x, uint256 y)
    internal pure returns (uint256) {
        if (x.hi == 0) {
            return x.lo / y;
        }

        if (x.hi >= y) {
            revert Overflow();
        }

        uint256 p = _unsafeSub(0, y) & y; // `p` is the largest power of 2 which `z` is divisible by
        uint256 q = _div512(x, p); // `n` is divisible by `p` because `n` is divisible by `z` and `z` is divisible by `p`
        uint256 r = _inv256(y / p); // `z / p = 1 mod 2` hence `inverse(z / p) = 1 mod 2 ^ 256`
        return _unsafeMul(q, r); // `q * r = (n / p) * inverse(z / p) = n / z`
    }

    /**
     * @dev returns the inverse of `d` modulo `2 ^ 256`, given that `d` is congruent to `1` modulo `2`
     */
    function _inv256(uint256 d)
    private pure returns (uint256) {
        // approximate the root of `f(x) = 1 / x - d` using the newton–raphson convergence method
        uint256 x = 1;
        for (uint256 i = 0; i < 8; i++) {
            x = _unsafeMul(x, _unsafeSub(2, _unsafeMul(x, d))); // `x = x * (2 - x * d) mod 2 ^ 256`
        }
        return x;
    }

}