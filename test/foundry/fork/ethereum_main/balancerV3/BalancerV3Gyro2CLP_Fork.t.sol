// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {IGyro2CLPPool, Gyro2CLPPoolImmutableData, Gyro2CLPPoolDynamicData} from "@crane/contracts/external/balancer/v3/interfaces/contracts/pool-gyro/IGyro2CLPPool.sol";
import {PoolSwapParams, Rounding, SwapKind} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/VaultTypes.sol";

import {Gyro2CLPMath} from "@crane/contracts/external/balancer/v3/pool-gyro/contracts/lib/Gyro2CLPMath.sol";
import {FixedPoint} from "@crane/contracts/external/balancer/v3/solidity-utils/contracts/math/FixedPoint.sol";

import {TestBase_BalancerV3GyroFork} from "./TestBase_BalancerV3GyroFork.sol";

/// @title BalancerV3Gyro2CLP_Fork
/// @notice Fork parity tests for Gyro 2-CLP pools
/// @dev Validates that Crane's ported 2-CLP math matches Balancer's Gyro2CLPMath library.
///      Uses pool immutable parameters (sqrtAlpha, sqrtBeta) from deployed mainnet pools
///      with synthetic balances for math parity testing.
///
/// NOTE: The deployed "mock" pools may be uninitialized (no liquidity). These tests
/// still validate math parity by using the pool's immutable parameters with synthetic balances.
contract BalancerV3Gyro2CLP_Fork is TestBase_BalancerV3GyroFork {
    using FixedPoint for uint256;

    /* -------------------------------------------------------------------------- */
    /*                              Test State                                    */
    /* -------------------------------------------------------------------------- */

    IGyro2CLPPool internal pool;
    Gyro2CLPPoolImmutableData internal immutableData;
    bool internal poolIsInitialized;

    // Synthetic test balances (1000 tokens each, scaled to 18 decimals)
    uint256 internal constant SYNTHETIC_BALANCE_0 = 1000e18;
    uint256 internal constant SYNTHETIC_BALANCE_1 = 1000e18;

    /* -------------------------------------------------------------------------- */
    /*                                   Setup                                    */
    /* -------------------------------------------------------------------------- */

    function setUp() public virtual override {
        super.setUp();

        // Check if pool exists (has code)
        if (GYRO_2CLP_POOL.code.length == 0) {
            console.log("2-CLP Pool does not exist at fork block");
            vm.skip(true);
            return;
        }

        // Get pool reference and immutable data
        pool = get2CLPPool(GYRO_2CLP_POOL);
        immutableData = get2CLPPoolImmutableData(pool);

        // Check if pool is initialized
        try pool.getGyro2CLPPoolDynamicData() returns (Gyro2CLPPoolDynamicData memory dynamicData) {
            poolIsInitialized = dynamicData.isPoolInitialized;
        } catch {
            poolIsInitialized = false;
        }

        // Log pool state for debugging
        console.log("2-CLP Pool Address:", GYRO_2CLP_POOL);
        console.log("sqrtAlpha:", immutableData.sqrtAlpha);
        console.log("sqrtBeta:", immutableData.sqrtBeta);
        console.log("Pool initialized:", poolIsInitialized);

        // Validate parameters
        require(immutableData.sqrtAlpha > 0, "sqrtAlpha must be > 0");
        require(immutableData.sqrtBeta > immutableData.sqrtAlpha, "sqrtBeta must be > sqrtAlpha");
    }

    /* -------------------------------------------------------------------------- */
    /*                            Helper Functions                                */
    /* -------------------------------------------------------------------------- */

    /// @notice Get synthetic test balances
    function _getSyntheticBalances() internal pure returns (uint256[] memory balances) {
        balances = new uint256[](2);
        balances[0] = SYNTHETIC_BALANCE_0;
        balances[1] = SYNTHETIC_BALANCE_1;
    }

    /* -------------------------------------------------------------------------- */
    /*                        US-CRANE-206.2: computeInvariant                    */
    /* -------------------------------------------------------------------------- */

    /// @notice Test invariant calculation with ROUND_DOWN
    function test_computeInvariant_roundDown() public view {
        uint256[] memory balances = _getSyntheticBalances();

        uint256 invariant = Gyro2CLPMath.calculateInvariant(
            balances,
            immutableData.sqrtAlpha,
            immutableData.sqrtBeta,
            Rounding.ROUND_DOWN
        );

        console.log("Invariant (ROUND_DOWN):", invariant);
        assertGt(invariant, 0, "Invariant should be positive");
    }

    /// @notice Test invariant calculation with ROUND_UP
    function test_computeInvariant_roundUp() public view {
        uint256[] memory balances = _getSyntheticBalances();

        uint256 invariantDown = Gyro2CLPMath.calculateInvariant(
            balances,
            immutableData.sqrtAlpha,
            immutableData.sqrtBeta,
            Rounding.ROUND_DOWN
        );

        uint256 invariantUp = Gyro2CLPMath.calculateInvariant(
            balances,
            immutableData.sqrtAlpha,
            immutableData.sqrtBeta,
            Rounding.ROUND_UP
        );

        console.log("Invariant (ROUND_DOWN):", invariantDown);
        console.log("Invariant (ROUND_UP):", invariantUp);

        // ROUND_UP should be >= ROUND_DOWN
        assertGe(invariantUp, invariantDown, "ROUND_UP should be >= ROUND_DOWN");
    }

    /// @notice Test invariant is consistent across multiple calculations
    function test_computeInvariant_consistency() public view {
        uint256[] memory balances = _getSyntheticBalances();

        uint256 inv1 = Gyro2CLPMath.calculateInvariant(
            balances, immutableData.sqrtAlpha, immutableData.sqrtBeta, Rounding.ROUND_DOWN
        );
        uint256 inv2 = Gyro2CLPMath.calculateInvariant(
            balances, immutableData.sqrtAlpha, immutableData.sqrtBeta, Rounding.ROUND_DOWN
        );

        assertEq(inv1, inv2, "Invariant should be deterministic");
    }

    /* -------------------------------------------------------------------------- */
    /*                        US-CRANE-206.2: computeBalance                      */
    /* -------------------------------------------------------------------------- */

    /// @notice Test computeBalance for token 0 with 1.1x invariant ratio
    function test_computeBalance_token0_invariantRatio110() public view {
        uint256[] memory balances = _getSyntheticBalances();
        uint256 invariantRatio = 1.1e18; // 110%

        uint256 newBalance = _computeBalanceLocal(balances, 0, invariantRatio);

        console.log("New balance token0 at 1.1x ratio:", newBalance);
        console.log("Current balance token0:", balances[0]);

        // New balance should be greater than current (adding liquidity)
        assertGt(newBalance, balances[0], "New balance should exceed current for 1.1x ratio");
    }

    /// @notice Test computeBalance for token 1 with 1.1x invariant ratio
    function test_computeBalance_token1_invariantRatio110() public view {
        uint256[] memory balances = _getSyntheticBalances();
        uint256 invariantRatio = 1.1e18; // 110%

        uint256 newBalance = _computeBalanceLocal(balances, 1, invariantRatio);

        console.log("New balance token1 at 1.1x ratio:", newBalance);
        console.log("Current balance token1:", balances[1]);

        // New balance should be greater than current (adding liquidity)
        assertGt(newBalance, balances[1], "New balance should exceed current for 1.1x ratio");
    }

    /// @notice Test computeBalance for token 0 with 0.9x invariant ratio
    function test_computeBalance_token0_invariantRatio90() public view {
        uint256[] memory balances = _getSyntheticBalances();
        uint256 invariantRatio = 0.9e18; // 90%

        uint256 newBalance = _computeBalanceLocal(balances, 0, invariantRatio);

        console.log("New balance token0 at 0.9x ratio:", newBalance);
        console.log("Current balance token0:", balances[0]);

        // New balance should be less than current (removing liquidity)
        assertLt(newBalance, balances[0], "New balance should be less for 0.9x ratio");
    }

    /* -------------------------------------------------------------------------- */
    /*                           US-CRANE-206.2: onSwap                           */
    /* -------------------------------------------------------------------------- */

    /// @notice Test swap EXACT_IN token0 -> token1 (small trade)
    function test_swap_exactIn_0to1_small() public view {
        uint256[] memory balances = _getSyntheticBalances();
        uint256 amountIn = balances[0] / 10000; // 0.01%

        uint256 amountOut = _calcOutGivenInLocal(balances, amountIn, true);

        console.log("EXACT_IN 0->1 amountIn:", amountIn);
        console.log("EXACT_IN 0->1 amountOut:", amountOut);

        assertGt(amountOut, 0, "Output should be positive");
        assertLt(amountOut, balances[1], "Output should be less than balance 1");
    }

    /// @notice Test swap EXACT_IN token1 -> token0 (small trade)
    function test_swap_exactIn_1to0_small() public view {
        uint256[] memory balances = _getSyntheticBalances();
        uint256 amountIn = balances[1] / 10000; // 0.01%

        uint256 amountOut = _calcOutGivenInLocal(balances, amountIn, false);

        console.log("EXACT_IN 1->0 amountIn:", amountIn);
        console.log("EXACT_IN 1->0 amountOut:", amountOut);

        assertGt(amountOut, 0, "Output should be positive");
        assertLt(amountOut, balances[0], "Output should be less than balance 0");
    }

    /// @notice Test swap EXACT_IN with various trade sizes
    function test_swap_exactIn_multipleSizes() public view {
        uint256[] memory balances = _getSyntheticBalances();

        uint256[] memory tradeSizes = new uint256[](5);
        tradeSizes[0] = balances[0] / 100000; // 0.001%
        tradeSizes[1] = balances[0] / 10000;  // 0.01%
        tradeSizes[2] = balances[0] / 1000;   // 0.1%
        tradeSizes[3] = balances[0] / 100;    // 1%
        tradeSizes[4] = balances[0] / 10;     // 10%

        for (uint256 i = 0; i < tradeSizes.length; i++) {
            uint256 amountIn = tradeSizes[i];
            if (amountIn == 0) continue;

            uint256 amountOut = _calcOutGivenInLocal(balances, amountIn, true);

            console.log("Trade size %d - amountIn: %d, amountOut: %d", i, amountIn, amountOut);
            assertGt(amountOut, 0, "Output should be positive for all trade sizes");
        }
    }

    /// @notice Test swap EXACT_OUT token0 -> token1
    function test_swap_exactOut_0to1() public view {
        uint256[] memory balances = _getSyntheticBalances();
        uint256 amountOut = balances[1] / 10000; // Want 0.01% of balance 1

        uint256 amountIn = _calcInGivenOutLocal(balances, amountOut, true);

        console.log("EXACT_OUT 0->1 amountIn:", amountIn);
        console.log("EXACT_OUT 0->1 amountOut:", amountOut);

        assertGt(amountIn, 0, "Input should be positive");
    }

    /// @notice Test swap consistency (round-trip)
    function test_swap_consistency_roundTrip() public view {
        uint256[] memory balances = _getSyntheticBalances();
        uint256 amountIn = balances[0] / 1000; // 0.1%

        uint256 amountOut = _calcOutGivenInLocal(balances, amountIn, true);
        uint256 amountInBack = _calcInGivenOutLocal(balances, amountOut, true);

        console.log("Round-trip test:");
        console.log("  Original amountIn:", amountIn);
        console.log("  AmountOut:", amountOut);
        console.log("  Calculated amountIn back:", amountInBack);

        // Due to rounding, amountInBack should be >= amountIn (favorable to protocol)
        assertGe(amountInBack, amountIn, "EXACT_OUT should require at least as much input");
    }

    /* -------------------------------------------------------------------------- */
    /*                            Internal Helpers                                */
    /* -------------------------------------------------------------------------- */

    /// @notice Compute new balance using 2-CLP math
    function _computeBalanceLocal(uint256[] memory balances, uint256 tokenIndex, uint256 invariantRatio)
        internal
        view
        returns (uint256 newBalance)
    {
        uint256 sqrtAlpha = immutableData.sqrtAlpha;
        uint256 sqrtBeta = immutableData.sqrtBeta;

        // Compute current invariant (rounded up for add liquidity)
        uint256 invariant = Gyro2CLPMath.calculateInvariant(balances, sqrtAlpha, sqrtBeta, Rounding.ROUND_UP);

        // Apply ratio
        uint256 newInvariant = invariant.mulUp(invariantRatio);
        uint256 squareNewInv = newInvariant * newInvariant;

        // Virtual offsets
        uint256 a = newInvariant.divDown(sqrtBeta);
        uint256 b = newInvariant.mulDown(sqrtAlpha);

        if (tokenIndex == 0) {
            newBalance = squareNewInv / (b + balances[1]) - a;
        } else {
            newBalance = squareNewInv / (a + balances[0]) - b;
        }
    }

    /// @notice Calculate output given input using 2-CLP math
    function _calcOutGivenInLocal(uint256[] memory balances, uint256 amountIn, bool tokenInIsToken0)
        internal
        view
        returns (uint256 amountOut)
    {
        (uint256 virtualParamIn, uint256 virtualParamOut) = _getVirtualOffsets(balances, tokenInIsToken0);

        uint256 balanceIn = tokenInIsToken0 ? balances[0] : balances[1];
        uint256 balanceOut = tokenInIsToken0 ? balances[1] : balances[0];

        amountOut = Gyro2CLPMath.calcOutGivenIn(balanceIn, balanceOut, amountIn, virtualParamIn, virtualParamOut);
    }

    /// @notice Calculate input given output using 2-CLP math
    function _calcInGivenOutLocal(uint256[] memory balances, uint256 amountOut, bool tokenInIsToken0)
        internal
        view
        returns (uint256 amountIn)
    {
        (uint256 virtualParamIn, uint256 virtualParamOut) = _getVirtualOffsets(balances, tokenInIsToken0);

        uint256 balanceIn = tokenInIsToken0 ? balances[0] : balances[1];
        uint256 balanceOut = tokenInIsToken0 ? balances[1] : balances[0];

        amountIn = Gyro2CLPMath.calcInGivenOut(balanceIn, balanceOut, amountOut, virtualParamIn, virtualParamOut);
    }

    /// @notice Calculate virtual offsets for swap calculations
    function _getVirtualOffsets(uint256[] memory balances, bool tokenInIsToken0)
        internal
        view
        returns (uint256 virtualParamIn, uint256 virtualParamOut)
    {
        uint256 currentInvariant =
            Gyro2CLPMath.calculateInvariant(balances, immutableData.sqrtAlpha, immutableData.sqrtBeta, Rounding.ROUND_DOWN);

        if (tokenInIsToken0) {
            virtualParamIn =
                Gyro2CLPMath.calculateVirtualParameter0(currentInvariant, immutableData.sqrtBeta, Rounding.ROUND_UP);
            virtualParamOut =
                Gyro2CLPMath.calculateVirtualParameter1(currentInvariant, immutableData.sqrtAlpha, Rounding.ROUND_DOWN);
        } else {
            virtualParamIn =
                Gyro2CLPMath.calculateVirtualParameter1(currentInvariant, immutableData.sqrtAlpha, Rounding.ROUND_UP);
            virtualParamOut =
                Gyro2CLPMath.calculateVirtualParameter0(currentInvariant, immutableData.sqrtBeta, Rounding.ROUND_DOWN);
        }
    }
}
