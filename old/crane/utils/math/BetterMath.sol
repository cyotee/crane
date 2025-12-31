// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                    Forge                                   */
/* -------------------------------------------------------------------------- */

/* -------------------------------------------------------------------------- */
/*                                Open Zeppelin                               */
/* -------------------------------------------------------------------------- */

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {Panic} from "@openzeppelin/contracts/utils/Panic.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

/// forge-lint: disable-next-line(unaliased-plain-import)
import "@crane/src/constants/Constants.sol";

struct Uint512 {
    uint256 hi; // 256 most significant bits
    uint256 lo; // 256 least significant bits
}

library BetterMath {
    using Math for bool;
    using Math for bytes;
    using Math for uint256;
    using Math for Math.Rounding;

    error DivisionByZero(uint256 panicCode);

    /* ---------------------------------------------------------------------- */
    /*               Wrapper Functions for Drop-In Compatibility              */
    /* ---------------------------------------------------------------------- */

    /**
     * @dev Wrapper function for the OZ Math.add512 function.
     */
    function add512(uint256 a, uint256 b) internal pure returns (uint256 high, uint256 low) {
        return a.add512(b);
    }

    /**
     * @dev Wrapper function for the OZ Math.mul512 function.
     */
    function mul512(uint256 a, uint256 b) internal pure returns (uint256 high, uint256 low) {
        return a.mul512(b);
    }

    /**
     * @dev Wrapper function for the OZ Math.tryAdd function.
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool success, uint256 result) {
        return a.tryAdd(b);
    }

    /**
     * @dev Wrapper function for the OZ Math.trySub function.
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool success, uint256 result) {
        return a.trySub(b);
    }

    /**
     * @dev Wrapper function for the OZ Math.tryMul function.
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool success, uint256 result) {
        return a.tryMul(b);
    }

    /**
     * @dev Wrapper function for the OZ Math.tryDiv function.
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool success, uint256 result) {
        return a.tryDiv(b);
    }

    /**
     * @dev Wrapper function for the OZ Math.tryMod function.
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool success, uint256 result) {
        return a.tryMod(b);
    }

    /**
     * @dev Wrapper function for the OZ Math.saturatingAdd function.
     */
    function saturatingAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        return a.saturatingAdd(b);
    }

    /**
     * @dev Wrapper function for the OZ Math.saturatingSub function.
     */
    function saturatingSub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a.saturatingSub(b);
    }

    /**
     * @dev Wrapper function for the OZ Math.saturatingMul function.
     */
    function saturatingMul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a.saturatingMul(b);
    }

    /**
     * @dev Wrapper function for the OZ Math.ternary function.
     */
    function ternary(bool condition, uint256 a, uint256 b) internal pure returns (uint256) {
        return condition.ternary(a, b);
    }

    /**
     * @dev Wrapper function for the OZ Math.max function.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a.max(b);
    }

    /**
     * @dev Wrapper function for the OZ Math.min function.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a.min(b);
    }

    /**
     * @dev Wrapper function for the OZ Math.average function.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        return a.average(b);
    }

    /**
     * @dev Wrapper function for the OZ Math.ceilDiv function.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return a.ceilDiv(b);
    }

    /**
     * @dev Wrapper function for the OZ Math.mulDiv function.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        return x.mulDiv(y, denominator);
    }

    /**
     * @dev Wrapper function for the OZ Math.mulDiv function.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Math.Rounding rounding) internal pure returns (uint256) {
        return x.mulDiv(y, denominator, rounding);
    }

    /**
     * @dev Wrapper function for the OZ Math.mulShr function.
     */
    function mulShr(uint256 x, uint256 y, uint8 n) internal pure returns (uint256 result) {
        return x.mulShr(y, n);
    }

    /**
     * @dev Wrapper function for the OZ Math.mulShr function.
     */
    function mulShr(uint256 x, uint256 y, uint8 n, Math.Rounding rounding) internal pure returns (uint256) {
        return x.mulShr(y, n, rounding);
    }

    /**
     * @dev Wrapper function for the OZ Math.invMod function.
     */
    function invMod(uint256 a, uint256 n) internal pure returns (uint256) {
        return a.invMod(n);
    }

    /**
     * @dev Wrapper function for the OZ Math.invModPrime function.
     */
    function invModPrime(uint256 a, uint256 p) internal view returns (uint256) {
        return a.invModPrime(p);
    }

    /**
     * @dev Wrapper function for the OZ Math.modExp function.
     */
    function modExp(uint256 b, uint256 e, uint256 m) internal view returns (uint256) {
        return b.modExp(e, m);
    }

    /**
     * @dev Wrapper function for the OZ Math.tryModExp function.
     */
    function tryModExp(uint256 b, uint256 e, uint256 m) internal view returns (bool success, uint256 result) {
        return b.tryModExp(e, m);
    }

    /**
     * @dev Wrapper function for the OZ Math.modExp function.
     */
    function modExp(bytes memory b, bytes memory e, bytes memory m) internal view returns (bytes memory) {
        return b.modExp(e, m);
    }

    /**
     * @dev Wrapper function for the OZ Math.tryModExp function.
     */
    function tryModExp(bytes memory b, bytes memory e, bytes memory m)
        internal
        view
        returns (bool success, bytes memory result)
    {
        return b.tryModExp(e, m);
    }

    /**
     * @dev Wrapper function for the OZ Math.sqrt function.
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        return a.sqrt();
    }

    /**
     * @dev Wrapper function for the OZ Math.sqrt function.
     */
    function sqrt(uint256 a, Math.Rounding rounding) internal pure returns (uint256) {
        return a.sqrt(rounding);
    }

    /**
     * @dev Wrapper function for the OZ Math.log2 function.
     */
    function log2(uint256 x) internal pure returns (uint256 r) {
        return x.log2();
    }

    /**
     * @dev Wrapper function for the OZ Math.log2 function.
     */
    function log2(uint256 value, Math.Rounding rounding) internal pure returns (uint256) {
        return value.log2(rounding);
    }

    /**
     * @dev Wrapper function for the OZ Math.log10 function.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        return value.log10();
    }

    /**
     * @dev Wrapper function for the OZ Math.log10 function.
     */
    function log10(uint256 value, Math.Rounding rounding) internal pure returns (uint256) {
        return value.log10(rounding);
    }

    /**
     * @dev Wrapper function for the OZ Math.log256 function.
     */
    function log256(uint256 x) internal pure returns (uint256 r) {
        return x.log256();
    }

    /**
     * @dev Wrapper function for the OZ Math.log256 function.
     */
    function log256(uint256 value, Math.Rounding rounding) internal pure returns (uint256) {
        return value.log256(rounding);
    }

    /**
     * @dev Wrapper function for the OZ Math.unsignedRoundsUp function.
     */
    function unsignedRoundsUp(Math.Rounding rounding) internal pure returns (bool) {
        return rounding.unsignedRoundsUp();
    }
    /* ---------------------------------------------------------------------- */
    /*                                New Logic                               */
    /* ---------------------------------------------------------------------- */

    /* ---------------------------------------------------------------------- */
    /*                                Constants                               */
    /* ---------------------------------------------------------------------- */

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

    function asc(uint256 a, uint256 b) internal pure returns (uint256 min_, uint256 max_) {
        require(a != b);
        min_ = min(a, b);
        max_ = min_ == a ? b : a;
    }

    function diff(uint256 a, uint256 b) internal pure returns (uint256 diff_) {
        (uint256 min_, uint256 max_) = asc(a, b);
        return max_ - min_;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        (bool success, uint256 result) = a.tryMod(b);
        if (!success) {
            revert DivisionByZero(Panic.DIVISION_BY_ZERO);
        }
        return result;
    }

    function safeHalf(uint256 value) internal pure returns (uint256 _safeHalf) {
        _safeHalf = value / 2;
        if (mod(value, 2) == 0) {
            return _safeHalf;
        }
        return value - _safeHalf;
    }

    function convertDecimalsFromTo(uint256 amount, uint8 amountDecimals, uint8 targetDecimals)
        internal
        pure
        returns (uint256 convertedAmount)
    {
        if (amountDecimals == targetDecimals) {
            return amount;
        }
        convertedAmount = amountDecimals > targetDecimals
            ? amount / 10 ** (amountDecimals - targetDecimals)
            : amount * 10 ** (targetDecimals - amountDecimals);
    }

    function precision(uint256 value, uint8 _precision, uint8 targetPrecision)
        internal
        pure
        returns (uint256 preciseValue)
    {
        preciseValue = convertDecimalsFromTo(value, _precision, targetPrecision);
    }

    function normalize(uint256 value) internal pure returns (uint256) {
        return precision(value, ERC20_DEFAULT_DECIMALS, 2);
    }

    /* ---------------------------------------------------------------------- */
    /*                          Unsafe Unsigned Math                          */
    /* ---------------------------------------------------------------------- */

    /**
     * @dev returns `(x + y) % 2 ^ 256`
     */
    function unsafeAdd(uint256 x, uint256 y) private pure returns (uint256) {
        unchecked {
            return x + y;
        }
    }

    /**
     * @dev returns `(x - y) % 2 ^ 256`
     */
    function unsafeSub(uint256 x, uint256 y) private pure returns (uint256) {
        unchecked {
            return x - y;
        }
    }

    /**
     * @dev returns `(x * y) % 2 ^ 256`
     */
    function unsafeMul(uint256 x, uint256 y) private pure returns (uint256) {
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
    function mulModMax(uint256 x, uint256 y) private pure returns (uint256) {
        return mulmod(x, y, type(uint256).max);
    }

    /* ---------------------------------------------------------------------- */
    /*                             Percentage Math                            */
    /* ---------------------------------------------------------------------- */

    function _percentageOf(uint256 total, uint256 percentage, uint256 precision_) internal pure returns (uint256 part) {
        return (total * percentage) / precision_;
    }

    function _percentageOfTotal(uint256 part, uint256 total, uint256 precision_) internal pure returns (uint256 percentage) {
        return (part * precision_) / total;
    }

    function _totalFromPercentage(uint256 part, uint256 percentage, uint256 precision_) internal pure returns (uint256 total) {
        return (part * precision_) / percentage;
    }

    /* ----------------------------------- WAD ---------------------------------- */

    function _percentageOfWAD(uint256 total, uint256 percentage) internal pure returns (uint256 part) {
        return _percentageOf(total, percentage, ONE_WAD);
    }

    function _percentageOfTotalWAD(uint256 part, uint256 total) internal pure returns (uint256 percentage) {
        return _percentageOfTotal(part, total, ONE_WAD);
    }

    function _totalFromPercentageWAD(uint256 part, uint256 percentage) internal pure returns (uint256 total) {
        return _totalFromPercentage(part, percentage, ONE_WAD);
    }

    /* ----------------------------------- PPM ---------------------------------- */

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

    // /**
    //  * @dev Returns the part of the total that is the percentage of the total.
    //  */
    // /// forge-lint: disable-next-line(mixed-case-function)
    // function percentageOfPPM(uint256 total, uint256 percentage) internal pure returns (uint256 part) {
    //     return (total * percentage) / PPM_RESOLUTION;
    // }

    // /**
    //  * @dev Returns the percentage of which part is of the total.
    //  */
    // /// forge-lint: disable-next-line(mixed-case-function)
    // function percentageOfTotalPPM(uint256 part, uint256 total) internal pure returns (uint256 percentage) {
    //     return (part * PPM_RESOLUTION) / total;
    // }

    // /**
    //  * @dev Returns the total of which the part is the percentage.
    //  */
    // /// forge-lint: disable-next-line(mixed-case-function)
    // function totalFromPercentageOfPPM(uint256 part, uint256 percentage) internal pure returns (uint256 total) {
    //     return (part * PPM_RESOLUTION) / percentage;
    // }

    /* ------------------------------ Basis Points ------------------------------ */

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

    // /**
    //  * @dev Expects percentage to be trailed by 000,
    //  */
    // function percentageAmountExpanded(uint256 total_, uint256 percentage_)
    //     internal
    //     pure
    //     returns (uint256 percentAmount_)
    // {
    //     return ((total_ * percentage_) / 100_000);
    // }

    // function percentageOfTotalExpanded(uint256 part_, uint256 total_) internal pure returns (uint256 percent_) {
    //     return ((part_ * 100_000) / total_);
    // }

    // function calculateGrossAmount(uint256 netAmount, uint256 feeBps) internal pure returns (uint256) {
    //     // Ensure fee is less than 100% (100,000 bps in this system)
    //     require(feeBps < 100_000, "Fee cannot be 100% or more");

    //     // Calculate denominator
    //     uint256 denominator = 100_000 - feeBps;

    //     // Ceiling division to calculate gross amount
    //     uint256 grossAmount = (netAmount * 100_000 + denominator - 1) / denominator;

    //     return grossAmount;
    // }

    /* ------------------------------- Shares ------------------------------- */

    function proportionalSplit(uint256 ownedShares, uint256 totalShares, uint256 totalReserveA, uint256 totalReserveB)
        internal
        pure
        returns (uint256 shareA, uint256 shareB)
    {
        // shareA = ((ownedShares * totalReserveA) / totalShares);
        shareA = shareOfProportionalSplit(ownedShares, totalShares, totalReserveA);
        // shareB = ((ownedShares * totalReserveB) / totalShares);
        shareB = shareOfProportionalSplit(ownedShares, totalShares, totalReserveB);
    }

    function shareOfProportionalSplit(
        /// forge-lint: disable-next-line(mixed-case-variable)
        uint256 ownedLPAmount,
        uint256 lpTotalSupply,
        uint256 totalReserveA
    )
        internal
        pure
        returns (uint256 ownedReserveA)
    {
        // Defensive: if total supply is zero, there is no reserve to attribute.
        if (lpTotalSupply == 0) return 0;
        ownedReserveA = ((ownedLPAmount * totalReserveA) / lpTotalSupply);
    }

    // Shares are just a way to calculate percentages using integers and state.

    // tag::_decimalsOffset()[]
    /**
     * @return The precision offset to use with the underlying asset used as the underlying reserve.
     */
    function decimalsOffset() internal pure returns (uint8) {
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
    function convertToShares(uint256 assets, uint256 reserve, uint256 totalShares)
        internal
        pure
        returns (uint256 shares)
    {
        shares = convertToShares(assets, reserve, totalShares, decimalsOffset(), Math.Rounding.Floor);
    }

    // end::_convertToShares[]

    // tag::_convertToShares(uint256,uint256)[]
    /**
     * @dev Internal conversion function (from assets to shares) with support for rounding direction.
     * @param assets The amount of assets from which to calculate equivalent shares.
     * @param reserve The reserve amount of which to calculate shares.
     * @return shares The equivalent amount of shares for `assets` of `reserve`.
     */
    function convertToShares(uint256 assets, uint256 reserve, uint256 totalShares, uint8 decimalOffset)
        internal
        pure
        returns (uint256 shares)
    {
        shares = convertToShares(assets, reserve, totalShares, decimalOffset, Math.Rounding.Floor);
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
    function convertToShares(
        uint256 assets,
        uint256 reserve,
        uint256 totalShares,
        uint8 decimalOffset,
        Math.Rounding rounding
    ) internal pure returns (uint256 shares) {
        shares = assets.mulDiv(
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
    function convertToAssets(uint256 shares, uint256 reserve, uint256 totalShares) internal pure returns (uint256) {
        return convertToAssets(shares, reserve, totalShares, decimalsOffset(), Math.Rounding.Floor);
    }

    // end::_convertToAssets[]

    // tag::_convertToAssets(uint256,uint256)[]
    /**
     * @dev Internal conversion function (from shares to assets) with support for rounding direction.
     * @param shares The amount of shares from which to calculate the equivalent assets.
     * @param reserve The reserve amount of which to calculate assets.
     * @return The equivalent amount of assets for `shares` of `reserve`.
     */
    function convertToAssets(uint256 shares, uint256 reserve, uint256 totalShares, uint8 decimalOffset)
        internal
        pure
        returns (uint256)
    {
        return convertToAssets(shares, reserve, totalShares, decimalOffset, Math.Rounding.Floor);
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
    function convertToAssets(
        uint256 shares,
        uint256 reserve,
        uint256 totalShares,
        uint8 decimalOffset,
        Math.Rounding rounding
    ) internal pure returns (uint256) {
        // Calculate the amount of asset due for a given amount of shares.
        // Multiply the shares quote by the reserve, then divide by the total shares.
        return shares.mulDiv(
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

    function mulDivDown(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) { revert(0, 0) }

            // Divide z by the denominator.
            z := div(z, denominator)
        }
    }

    /* ---------------------------- WAD/RAY Math ---------------------------- */

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        // require( (y != 0), "FixedPointWadMathLib:_divWadDown:: Attempting to divide by 0");
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    /* ------------------------------ UQ112x112 ----------------------------- */

    // uint224 constant Q112 = 2**112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112; // never overflows
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }

    /* ---------------------------------------------------------------------- */
    /*                              512-bit Math                              */
    /* ---------------------------------------------------------------------- */

    function mul512ForUint512(uint256 a, uint256 b) internal pure returns (Uint512 memory) {
        (uint256 high, uint256 low) = mul512(a, b);
        return Uint512({hi: high, lo: low});
    }

    /**
     * @dev returns the value of `x / pow2n`, given that `x` is divisible by `pow2n`
     */
    function div512(Uint512 memory x, uint256 pow2n) internal pure returns (uint256) {
        uint256 pow2nInv = unsafeAdd(unsafeSub(0, pow2n) / pow2n, 1); // `1 << (256 - n)`
        return unsafeMul(x.hi, pow2nInv) | (x.lo / pow2n); // `(x.hi << (256 - n)) | (x.lo >> n)`
    }

    function div256(Uint512 memory x, uint256 y) internal pure returns (uint256) {
        if (x.hi == 0) {
            return x.lo / y;
        }

        if (x.hi >= y) {
            revert Overflow();
        }

        uint256 p = unsafeSub(0, y) & y; // `p` is the largest power of 2 which `z` is divisible by
        uint256 q = div512(x, p); // `n` is divisible by `p` because `n` is divisible by `z` and `z` is divisible by `p`
        uint256 r = inv256(y / p); // `z / p = 1 mod 2` hence `inverse(z / p) = 1 mod 2 ^ 256`
        return unsafeMul(q, r); // `q * r = (n / p) * inverse(z / p) = n / z`
    }

    /**
     * @dev returns the inverse of `d` modulo `2 ^ 256`, given that `d` is congruent to `1` modulo `2`
     */
    function inv256(uint256 d) private pure returns (uint256) {
        // approximate the root of `f(x) = 1 / x - d` using the newton–raphson convergence method
        uint256 x = 1;
        for (uint256 i = 0; i < 8; i++) {
            x = unsafeMul(x, unsafeSub(2, unsafeMul(x, d))); // `x = x * (2 - x * d) mod 2 ^ 256`
        }
        return x;
    }
}
