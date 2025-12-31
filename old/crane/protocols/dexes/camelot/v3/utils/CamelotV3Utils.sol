// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

library CamelotV3Utils {
    function _calcReduceExposureToTargetV3(
        uint256 targetSettlementAmount,
        uint128 liquidity, // Position liquidity (L)
        uint160 sqrtPriceX96, // Current sqrt price
        int24 tickLower,
        int24 tickUpper,
        // exitTokenFeePercent
        uint16,
        // opTokenFeePercent
        uint16
    ) internal pure returns (uint256 liquidityToWithdraw) {
        // Convert sqrtPriceX96 to token amounts within range
        uint160 sqrtPriceLower = _tickToSqrtPriceX96(tickLower);
        uint160 sqrtPriceUpper = _tickToSqrtPriceX96(tickUpper);
        uint256 exitTokenAmount = _getAmount0ForLiquidity(liquidity, sqrtPriceX96, sqrtPriceLower, sqrtPriceUpper);
        if (exitTokenAmount > targetSettlementAmount) {
            // Calculate fraction of liquidity to withdraw
            uint256 excess = exitTokenAmount - targetSettlementAmount;
            liquidityToWithdraw = (liquidity * excess) / exitTokenAmount;
        } else {
            liquidityToWithdraw = 0;
        }
    }

    // Helper: Convert tick to sqrtPriceX96 (approximation)
    function _tickToSqrtPriceX96(int24 tick) internal pure returns (uint160) {
        // // sqrt(1.0001^tick) * 2^96
        // // Simplified approximation; use a lookup or precise math library in practice
        // uint256 absTick = tick < 0 ? uint256(-tick) : uint256(tick);
        // uint256 ratio = absTick & 0x1 != 0 ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;
        // if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
        // // ... (continue for higher bits as needed)
        // if (tick < 0) ratio = (1 << 256) / ratio;
        // return uint160(ratio >> 32);
    }

    // Helper: Calculate token0 amount from liquidity
    function _getAmount0ForLiquidity(
        uint128 liquidity,
        uint160 sqrtPriceCurrent,
        uint160 sqrtPriceLower,
        uint160 sqrtPriceUpper
    ) internal pure returns (uint256) {
        if (sqrtPriceCurrent < sqrtPriceLower) return 0;
        if (sqrtPriceCurrent > sqrtPriceUpper) sqrtPriceCurrent = sqrtPriceUpper;
        return uint256(liquidity) * (sqrtPriceUpper - sqrtPriceLower) / (sqrtPriceCurrent * sqrtPriceUpper) / (1 << 96);
    }
}
