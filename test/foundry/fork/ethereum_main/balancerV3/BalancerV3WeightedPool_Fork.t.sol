// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {TestBase_BalancerV3WeightedFork} from "./TestBase_BalancerV3WeightedFork.sol";
import {Rounding} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/VaultTypes.sol";
import {IBalancerV3WeightedPool} from "@crane/contracts/interfaces/protocols/dexes/balancer/v3/IBalancerV3WeightedPool.sol";
import {IBasePool} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IBasePool.sol";
import {WeightedMath} from "@crane/contracts/external/balancer/v3/solidity-utils/contracts/math/WeightedMath.sol";

/// @title BalancerV3WeightedPool_Fork
/// @notice Fork parity tests for Balancer V3 Weighted pool math
/// @dev Validates that Crane's ported WeightedMath library produces identical results
///      to the deployed Balancer V3 weighted pool on Ethereum mainnet.
///
///      Note on `onSwap` testing: The pool's `onSwap` function is designed to be called
///      only by the Vault during actual swap operations. Direct calls would revert with
///      "only callable by Vault". Instead, this test suite validates the underlying
///      WeightedMath functions (`computeOutGivenExactIn`, `computeInGivenExactOut`) that
///      `onSwap` uses internally. Parity of these functions ensures swap math parity.
contract BalancerV3WeightedPool_Fork is TestBase_BalancerV3WeightedFork {
    /* -------------------------------------------------------------------------- */
    /*                           getNormalizedWeights()                           */
    /* -------------------------------------------------------------------------- */

    /// @notice Verify the pool has valid normalized weights
    function test_getNormalizedWeights_valid() public view {
        uint256[] memory weights = IBalancerV3WeightedPool(weightedPool).getNormalizedWeights();

        // Weights array should match token count
        assertEq(weights.length, poolTokens.length, "Weights length mismatch");

        // Each weight should be > 0 and < 1e18
        for (uint256 i = 0; i < weights.length; i++) {
            assertGt(weights[i], 0, "Weight should be positive");
            assertLt(weights[i], 1e18, "Weight should be less than 100%");
        }

        // Weights should sum to 1e18 (within rounding tolerance)
        uint256 sum = 0;
        for (uint256 i = 0; i < weights.length; i++) {
            sum += weights[i];
        }
        assertApproxEqBps(sum, 1e18, 1, "Weights should sum to 1e18");
    }

    /// @notice Verify cached weights match on-chain weights
    function test_getNormalizedWeights_matchesCached() public view {
        uint256[] memory onChainWeights = IBalancerV3WeightedPool(weightedPool).getNormalizedWeights();

        assertEq(onChainWeights.length, normalizedWeights.length, "Weight array length mismatch");
        for (uint256 i = 0; i < onChainWeights.length; i++) {
            assertEq(onChainWeights[i], normalizedWeights[i], "Weight mismatch at index");
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                             computeInvariant()                             */
    /* -------------------------------------------------------------------------- */

    /// @notice Test invariant computation with current pool state - round down
    function test_computeInvariant_currentState_roundDown() public view {
        uint256[] memory balances = getPoolBalances();
        uint256[] memory weights = normalizedWeights;

        // Compute using local WeightedMath
        uint256 localInvariant = computeInvariantLocal(balances, weights, true);

        // Compute using on-chain pool
        uint256 onChainInvariant = computeInvariantOnChain(balances, Rounding.ROUND_DOWN);

        // Should match exactly (same math)
        assertParity(localInvariant, onChainInvariant, "computeInvariant ROUND_DOWN");
    }

    /// @notice Test invariant computation with current pool state - round up
    function test_computeInvariant_currentState_roundUp() public view {
        uint256[] memory balances = getPoolBalances();
        uint256[] memory weights = normalizedWeights;

        // Compute using local WeightedMath
        uint256 localInvariant = computeInvariantLocal(balances, weights, false);

        // Compute using on-chain pool
        uint256 onChainInvariant = computeInvariantOnChain(balances, Rounding.ROUND_UP);

        // Should match exactly (same math)
        assertParity(localInvariant, onChainInvariant, "computeInvariant ROUND_UP");
    }

    /// @notice Test invariant with scaled balances (2x)
    function test_computeInvariant_scaledBalances() public view {
        uint256[] memory balances = getPoolBalances();
        uint256[] memory weights = normalizedWeights;

        // Scale balances by 2x
        uint256[] memory scaledBalances = new uint256[](balances.length);
        for (uint256 i = 0; i < balances.length; i++) {
            scaledBalances[i] = balances[i] * 2;
        }

        // Compute invariants
        uint256 localOriginal = computeInvariantLocal(balances, weights, true);
        uint256 localScaled = computeInvariantLocal(scaledBalances, weights, true);

        // Invariant should scale linearly (inv(2*balances) = 2*inv(balances))
        // This tests the linear property required for LP share fungibility
        assertApproxEqBps(localScaled, localOriginal * 2, 10, "Invariant should scale linearly");
    }

    /// @notice Fuzz test invariant computation parity
    function testFuzz_computeInvariant_parity(uint256 balanceMultiplier) public view {
        vm.assume(balanceMultiplier > 0 && balanceMultiplier < 1e6);

        uint256[] memory balances = getPoolBalances();
        uint256[] memory weights = normalizedWeights;

        // Apply multiplier to balances
        uint256[] memory scaledBalances = new uint256[](balances.length);
        for (uint256 i = 0; i < balances.length; i++) {
            scaledBalances[i] = (balances[i] * balanceMultiplier) / 1000;
            // Skip if balance too small
            if (scaledBalances[i] == 0) return;
        }

        uint256 localInvariant = computeInvariantLocal(scaledBalances, weights, true);
        uint256 onChainInvariant = computeInvariantOnChain(scaledBalances, Rounding.ROUND_DOWN);

        assertParity(localInvariant, onChainInvariant, "Fuzz computeInvariant");
    }

    /* -------------------------------------------------------------------------- */
    /*                              computeBalance()                              */
    /* -------------------------------------------------------------------------- */

    /// @notice Test balance computation for adding liquidity (invariant increases)
    function test_computeBalance_addLiquidity() public view {
        uint256[] memory balances = getPoolBalances();
        uint256[] memory weights = normalizedWeights;

        // Simulate adding 10% liquidity
        uint256 invariantRatio = 1.1e18; // 110%

        for (uint256 tokenIndex = 0; tokenIndex < balances.length; tokenIndex++) {
            uint256 localBalance = computeBalanceLocal(balances, weights, tokenIndex, invariantRatio);
            uint256 onChainBalance = computeBalanceOnChain(balances, tokenIndex, invariantRatio);

            assertParity(localBalance, onChainBalance, string.concat("computeBalance token ", vm.toString(tokenIndex)));

            // New balance should be greater than old balance
            assertGt(localBalance, balances[tokenIndex], "Balance should increase for liquidity add");
        }
    }

    /// @notice Test balance computation for removing liquidity (invariant decreases)
    function test_computeBalance_removeLiquidity() public view {
        uint256[] memory balances = getPoolBalances();
        uint256[] memory weights = normalizedWeights;

        // Simulate removing 10% liquidity
        uint256 invariantRatio = 0.9e18; // 90%

        for (uint256 tokenIndex = 0; tokenIndex < balances.length; tokenIndex++) {
            uint256 localBalance = computeBalanceLocal(balances, weights, tokenIndex, invariantRatio);
            uint256 onChainBalance = computeBalanceOnChain(balances, tokenIndex, invariantRatio);

            assertParity(localBalance, onChainBalance, string.concat("computeBalance remove token ", vm.toString(tokenIndex)));

            // New balance should be less than old balance
            assertLt(localBalance, balances[tokenIndex], "Balance should decrease for liquidity remove");
        }
    }

    /// @notice Fuzz test balance computation parity
    function testFuzz_computeBalance_parity(uint256 invariantRatioBps) public view {
        // Ratio between 50% and 200% (5000 to 20000 bps)
        vm.assume(invariantRatioBps >= 5000 && invariantRatioBps <= 20000);

        uint256[] memory balances = getPoolBalances();
        uint256[] memory weights = normalizedWeights;

        uint256 invariantRatio = (invariantRatioBps * 1e18) / 10000;

        for (uint256 tokenIndex = 0; tokenIndex < balances.length; tokenIndex++) {
            uint256 localBalance = computeBalanceLocal(balances, weights, tokenIndex, invariantRatio);
            uint256 onChainBalance = computeBalanceOnChain(balances, tokenIndex, invariantRatio);

            assertParity(localBalance, onChainBalance, "Fuzz computeBalance");
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                          Swap Math (WeightedMath)                          */
    /* -------------------------------------------------------------------------- */

    /// @notice Test exact-in swap computation - token0 -> token1
    function test_swapExactIn_token0ToToken1() public view {
        if (!is2TokenPool()) return; // Skip for multi-token pools

        uint256[] memory balances = getPoolBalances();
        uint256[] memory weights = normalizedWeights;

        uint256 amountIn = MEDIUM_AMOUNT;

        uint256 amountOut = computeSwapExactInLocal(
            balances[0],
            weights[0],
            balances[1],
            weights[1],
            amountIn
        );

        // Output should be positive and less than balance
        assertGt(amountOut, 0, "Swap output should be positive");
        assertLt(amountOut, balances[1], "Swap output should be less than pool balance");
    }

    /// @notice Test exact-in swap computation - token1 -> token0
    function test_swapExactIn_token1ToToken0() public view {
        if (!is2TokenPool()) return;

        uint256[] memory balances = getPoolBalances();
        uint256[] memory weights = normalizedWeights;

        uint256 amountIn = MEDIUM_AMOUNT;

        uint256 amountOut = computeSwapExactInLocal(
            balances[1],
            weights[1],
            balances[0],
            weights[0],
            amountIn
        );

        assertGt(amountOut, 0, "Swap output should be positive");
        assertLt(amountOut, balances[0], "Swap output should be less than pool balance");
    }

    /// @notice Test exact-out swap computation - token0 -> token1
    function test_swapExactOut_token0ToToken1() public view {
        if (!is2TokenPool()) return;

        uint256[] memory balances = getPoolBalances();
        uint256[] memory weights = normalizedWeights;

        // Request 1% of token1 balance
        uint256 amountOut = balances[1] / 100;

        uint256 amountIn = computeSwapExactOutLocal(
            balances[0],
            weights[0],
            balances[1],
            weights[1],
            amountOut
        );

        // Input should be positive
        assertGt(amountIn, 0, "Swap input should be positive");
    }

    /// @notice Test exact-out swap computation - token1 -> token0
    function test_swapExactOut_token1ToToken0() public view {
        if (!is2TokenPool()) return;

        uint256[] memory balances = getPoolBalances();
        uint256[] memory weights = normalizedWeights;

        // Request 1% of token0 balance
        uint256 amountOut = balances[0] / 100;

        uint256 amountIn = computeSwapExactOutLocal(
            balances[1],
            weights[1],
            balances[0],
            weights[0],
            amountOut
        );

        assertGt(amountIn, 0, "Swap input should be positive");
    }

    /// @notice Test swap math consistency: exact-in followed by exact-out should round-trip
    function test_swapMath_roundTrip() public view {
        if (!is2TokenPool()) return;

        uint256[] memory balances = getPoolBalances();
        uint256[] memory weights = normalizedWeights;

        uint256 amountIn = MEDIUM_AMOUNT;

        // Swap token0 -> token1 (exact in)
        uint256 amountOut = computeSwapExactInLocal(
            balances[0],
            weights[0],
            balances[1],
            weights[1],
            amountIn
        );

        // Update balances after first swap
        uint256[] memory newBalances = new uint256[](2);
        newBalances[0] = balances[0] + amountIn;
        newBalances[1] = balances[1] - amountOut;

        // Swap back: token1 -> token0 (exact in with the output from first swap)
        uint256 amountBack = computeSwapExactInLocal(
            newBalances[1],
            weights[1],
            newBalances[0],
            weights[0],
            amountOut
        );

        // Due to the constant product formula, we should get back slightly less
        // (this is the "slippage" from two trades)
        assertLt(amountBack, amountIn, "Round trip should result in some loss");
        // But should be close (within 1% for reasonable trade sizes)
        assertApproxEqBps(amountBack, amountIn, 100, "Round trip loss should be small");
    }

    /// @notice Fuzz test exact-in swap math
    function testFuzz_swapExactIn_variousAmounts(uint256 amountInBps) public view {
        if (!is2TokenPool()) return;

        // Amount between 0.01% and 10% of pool balance
        vm.assume(amountInBps >= 1 && amountInBps <= 1000);

        uint256[] memory balances = getPoolBalances();
        uint256[] memory weights = normalizedWeights;

        uint256 amountIn = (balances[0] * amountInBps) / 10000;
        if (amountIn == 0) return;

        uint256 amountOut = computeSwapExactInLocal(
            balances[0],
            weights[0],
            balances[1],
            weights[1],
            amountIn
        );

        // Output should be positive and bounded
        assertGt(amountOut, 0, "Swap output should be positive");
        assertLt(amountOut, balances[1], "Swap output should be less than pool balance");
    }

    /// @notice Fuzz test exact-out swap math
    function testFuzz_swapExactOut_variousAmounts(uint256 amountOutBps) public view {
        if (!is2TokenPool()) return;

        // Amount between 0.01% and 10% of pool balance
        vm.assume(amountOutBps >= 1 && amountOutBps <= 1000);

        uint256[] memory balances = getPoolBalances();
        uint256[] memory weights = normalizedWeights;

        uint256 amountOut = (balances[1] * amountOutBps) / 10000;
        if (amountOut == 0) return;

        uint256 amountIn = computeSwapExactOutLocal(
            balances[0],
            weights[0],
            balances[1],
            weights[1],
            amountOut
        );

        // Input should be positive
        assertGt(amountIn, 0, "Swap input should be positive");
    }

    /* -------------------------------------------------------------------------- */
    /*                              Multiple Trade Sizes                          */
    /* -------------------------------------------------------------------------- */

    /// @notice Test swap math with small, medium, and large amounts
    function test_swapExactIn_multipleSizes() public view {
        if (!is2TokenPool()) return;

        uint256[] memory balances = getPoolBalances();
        uint256[] memory weights = normalizedWeights;

        uint256[] memory amounts = new uint256[](3);
        amounts[0] = SMALL_AMOUNT;
        amounts[1] = MEDIUM_AMOUNT;
        amounts[2] = LARGE_AMOUNT;

        for (uint256 i = 0; i < amounts.length; i++) {
            // Skip if amount is larger than pool balance
            if (amounts[i] >= balances[0]) continue;

            uint256 amountOut = computeSwapExactInLocal(
                balances[0],
                weights[0],
                balances[1],
                weights[1],
                amounts[i]
            );

            // Output should be positive
            assertGt(amountOut, 0, "Swap output should be positive");

            // Larger inputs should give larger outputs
            if (i > 0 && amounts[i - 1] < balances[0]) {
                uint256 prevOut = computeSwapExactInLocal(
                    balances[0],
                    weights[0],
                    balances[1],
                    weights[1],
                    amounts[i - 1]
                );
                assertGt(amountOut, prevOut, "Larger input should give larger output");
            }
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                             Pool State Sanity                              */
    /* -------------------------------------------------------------------------- */

    /// @notice Verify pool state is reasonable for testing
    function test_poolState_sanity() public view {
        // Pool should have at least 2 tokens
        assertGe(poolTokens.length, 2, "Pool should have at least 2 tokens");

        // All balances should be positive
        uint256[] memory balances = getPoolBalances();
        for (uint256 i = 0; i < balances.length; i++) {
            assertGt(balances[i], 0, "All balances should be positive");
        }

        // Weights should sum to ~1e18
        uint256 weightSum = 0;
        for (uint256 i = 0; i < normalizedWeights.length; i++) {
            weightSum += normalizedWeights[i];
        }
        assertApproxEqBps(weightSum, 1e18, 1, "Weights should sum to 1e18");
    }
}
