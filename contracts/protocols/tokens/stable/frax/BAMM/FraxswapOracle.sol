// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.35;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// =========================== FraxswapOracle =========================
// ====================================================================
// Gets token0 and token1 prices from a Fraxswap pair

// Frax Finance: https://github.com/FraxFinance

// Primary Author
// Dennis: https://github.com/denett

// Reviewer(s) / Contributor(s)
// Travis Moore: https://github.com/FortisFortuna

import "./FixedPoint.sol";
import "@crane/contracts/protocols/tokens/stable/frax/Fraxswap/core/libraries/UQ112x112.sol";
import "forge-std/console.sol";

contract FraxswapOracle {
    using UQ112x112 for uint224;
    using FixedPoint for *;

    /// @notice Gets the prices for token0 and token1 from a Fraxswap pool
    /// @param pool The LP contract
    /// @param period The minimum size of the period between observations, in seconds
    /// @param rounds 2 ^ rounds # of blocks to search
    /// @param maxDiffPerc Max price change from last value
    /// @return result0 The price for token0
    /// @return result1 The price for token1
    function getPrice(IFraxswapPair pool, uint256 period, uint256 rounds, uint256 maxDiffPerc)
        public
        view
        returns (uint256 result0, uint256 result1)
    {
        uint256 lastObservationIndex = pool.getTWAPHistoryLength() - 1;
        IFraxswapPair.TWAPObservation memory lastObservation = pool.TWAPObservationHistory(lastObservationIndex);

        // Update last observation up to the current block
        if (lastObservation.timestamp < block.timestamp) {
            // Update the reserves
            (uint112 _reserve0, uint112 _reserve1,) = pool.getReserves();

            // Get the latest observed prices
            uint256 timeElapsed = block.timestamp - lastObservation.timestamp;
            lastObservation.price0CumulativeLast += uint256(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
            lastObservation.price1CumulativeLast += uint256(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
            lastObservation.timestamp = block.timestamp;
        }

        // Search for an observation
        // TODO: Dennis explain math
        IFraxswapPair.TWAPObservation memory foundObservation;
        uint256 step = 2 ** rounds;
        uint256 min = (lastObservationIndex + 2 > step) ? (lastObservationIndex + 2 - step) : 0;
        while (step > 1) {
            step = step >> 1;
            uint256 pos = min + step - 1;
            if (pos <= lastObservationIndex) {
                IFraxswapPair.TWAPObservation memory observation = pool.TWAPObservationHistory(pos);
                if (lastObservation.timestamp - observation.timestamp > period) {
                    foundObservation = observation;
                    min = pos + 1;
                }
            }
        }

        // Reverts when a matching period can not be found
        require(foundObservation.timestamp > 0, "Period too long");

        // Get the price results
        result0 = FixedPoint.uq112x112(
                uint224(
                    (lastObservation.price0CumulativeLast - foundObservation.price0CumulativeLast)
                        / (lastObservation.timestamp - foundObservation.timestamp)
                )
            ).mul(1e18).decode144();
        result1 = FixedPoint.uq112x112(
                uint224(
                    (lastObservation.price1CumulativeLast - foundObservation.price1CumulativeLast)
                        / (lastObservation.timestamp - foundObservation.timestamp)
                )
            ).mul(1e18).decode144();

        // Revert if the price changed too much
        uint256 checkResult0 = 1e36 / result1;
        uint256 diff = (checkResult0 > result0 ? checkResult0 - result0 : result0 - checkResult0);
        uint256 diffPerc = (diff * 10000) / result0;
        if (diffPerc > maxDiffPerc) revert("Max diff");
    }

    /// @notice Gets the prices for token0 from a Fraxswap pool
    /// @param pool The LP contract
    /// @param period The minimum size of the period between observations, in seconds
    /// @param rounds 2 ^ rounds # of blocks to search
    /// @param maxDiffPerc Max price change from last value
    /// @return result0 The price for token0
    function getPrice0(IFraxswapPair pool, uint256 period, uint256 rounds, uint256 maxDiffPerc)
        external
        view
        returns (uint256 result0)
    {
        (result0,) = getPrice(pool, period, rounds, maxDiffPerc);
    }

    /// @notice Gets the price for token1 from a Fraxswap pool
    /// @param pool The LP contract
    /// @param period The minimum size of the period between observations, in seconds
    /// @param rounds 2 ^ rounds # of blocks to search
    /// @param maxDiffPerc Max price change from last value
    /// @return result1 The price for token1
    function getPrice1(IFraxswapPair pool, uint256 period, uint256 rounds, uint256 maxDiffPerc)
        external
        view
        returns (uint256 result1)
    {
        (, result1) = getPrice(pool, period, rounds, maxDiffPerc);
    }
}

// Interface used to call FraxswapPair
interface IFraxswapPair {
    function getTWAPHistoryLength() external view returns (uint256);
    function TWAPObservationHistory(uint256 index) external view returns (TWAPObservation memory);

    struct TWAPObservation {
        uint256 timestamp;
        uint256 price0CumulativeLast;
        uint256 price1CumulativeLast;
    }
    function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
}
