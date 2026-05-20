// SPDX-License-Identifier: ISC
pragma solidity ^0.8.35;

/// @notice Pure math helpers ported from `fraxswap-twamm-test.js` / `twamm-utils.js`.

library TwammTestMath {
    uint256 internal constant FEE_BPS = 30;
    uint256 internal constant FEE_MULTIPLIER = 10_000 - FEE_BPS;

    function expectedSwapOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut, uint256 feeMult)
        internal
        pure
        returns (uint256)
    {
        uint256 amountInWithFee = amountIn * feeMult / 10_000;
        return reserveOut * amountInWithFee / (reserveIn + amountInWithFee);
    }

    /// @dev Instant full-fill TWAMM model from upstream `calculateTwammExpectedFraxswap` (timeIntervals unused there too).
    function calculateTwammExpectedFraxswap(uint256 token0In, uint256 token1In, uint256 reserve0, uint256 reserve1, uint256 feeMult)
        internal
        pure
        returns (uint256 finalReserve0, uint256 finalReserve1, uint256 token0Out, uint256 token1Out)
    {
        uint256 token0InWithFee = token0In * feeMult / 10_000;
        uint256 token1InWithFee = token1In * feeMult / 10_000;
        uint256 k = reserve0 * reserve1;
        uint256 endReserve1 = reserve0 * (reserve1 + token1InWithFee) / (reserve0 + token0InWithFee);
        uint256 endReserve0 = k / endReserve1;
        token0Out = reserve0 + token0InWithFee - endReserve0;
        token1Out = reserve1 + token1InWithFee - endReserve1;
        finalReserve0 = endReserve0;
        finalReserve1 = endReserve1;
    }
}