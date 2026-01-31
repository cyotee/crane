// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {PoolSwapParams, Rounding, SwapKind} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";
import {FixedPoint} from "@balancer-labs/v3-solidity-utils/contracts/math/FixedPoint.sol";
import {StableMath} from "@balancer-labs/v3-solidity-utils/contracts/math/StableMath.sol";

import {BalancerV3StablePoolTargetStub} from "@crane/contracts/protocols/dexes/balancer/v3/pool-stable/BalancerV3StablePoolTargetStub.sol";
import {BalancerV3StablePoolRepo} from "@crane/contracts/protocols/dexes/balancer/v3/pool-stable/BalancerV3StablePoolRepo.sol";

/**
 * @title BalancerV3StablePoolTarget_Test
 * @notice Tests for the BalancerV3StablePoolTarget stable pool AMM logic.
 * @dev Tests cover invariant calculation, swap math, and amplification parameter handling.
 *
 * Stable pools are optimized for assets that trade near parity (e.g., stablecoins).
 * The amplification parameter controls the "flatness" of the curve.
 */
contract BalancerV3StablePoolTarget_Test is Test {
    using FixedPoint for uint256;

    BalancerV3StablePoolTargetStub internal pool;

    // Common amplification values for testing
    uint256 constant AMP_DEFAULT = 100; // Moderate stability
    uint256 constant AMP_HIGH = 2000; // Very flat curve for stable pairs
    uint256 constant AMP_LOW = 10; // More like constant product

    function setUp() public {
        pool = new BalancerV3StablePoolTargetStub();
        pool.initialize(AMP_DEFAULT);
    }

    /* ---------------------------------------------------------------------- */
    /*                     getAmplificationParameter Tests                     */
    /* ---------------------------------------------------------------------- */

    function test_getAmplificationParameter_returnsInitialValue() public view {
        (uint256 value, bool isUpdating, uint256 precision) = pool.getAmplificationParameter();

        assertEq(value, AMP_DEFAULT * StableMath.AMP_PRECISION, "Amp should be initial value * precision");
        assertFalse(isUpdating, "Should not be updating");
        assertEq(precision, StableMath.AMP_PRECISION, "Precision should be 1000");
    }

    function test_getAmplificationState_returnsCorrectState() public view {
        (
            uint256 startValue,
            uint256 endValue,
            uint256 startTime,
            uint256 endTime,
            uint256 precision
        ) = pool.getAmplificationState();

        assertEq(startValue, AMP_DEFAULT * StableMath.AMP_PRECISION, "Start value incorrect");
        assertEq(endValue, AMP_DEFAULT * StableMath.AMP_PRECISION, "End value incorrect");
        assertEq(startTime, endTime, "Start and end time should be equal (no update)");
        assertEq(precision, StableMath.AMP_PRECISION, "Precision should be 1000");
    }

    /* ---------------------------------------------------------------------- */
    /*                           computeInvariant Tests                        */
    /* ---------------------------------------------------------------------- */

    function test_computeInvariant_balancedPool_returnsCorrectValue() public view {
        uint256[] memory balances = new uint256[](2);
        balances[0] = 1000e18;
        balances[1] = 1000e18;

        uint256 invariantDown = pool.computeInvariant(balances, Rounding.ROUND_DOWN);
        uint256 invariantUp = pool.computeInvariant(balances, Rounding.ROUND_UP);

        // For stable pools, balanced pool invariant should be approximately sum of balances
        // when amp is high enough
        (uint256 amp,,) = pool.getAmplificationParameter();
        uint256 expected = StableMath.computeInvariant(amp, balances);

        assertEq(invariantDown, expected, "ROUND_DOWN invariant should match StableMath");
        assertEq(invariantUp, expected + 1, "ROUND_UP should be ROUND_DOWN + 1");
    }

    function test_computeInvariant_roundDown_lessOrEqualRoundUp() public view {
        uint256[] memory balances = new uint256[](2);
        balances[0] = 1200e18;
        balances[1] = 800e18;

        uint256 invariantDown = pool.computeInvariant(balances, Rounding.ROUND_DOWN);
        uint256 invariantUp = pool.computeInvariant(balances, Rounding.ROUND_UP);

        assertLe(invariantDown, invariantUp, "ROUND_DOWN should be <= ROUND_UP");
    }

    function test_computeInvariant_threeTokenPool_works() public {
        // Re-initialize with a 3-token pool scenario - test StableMath handles it
        uint256[] memory balances = new uint256[](3);
        balances[0] = 1000e18;
        balances[1] = 1000e18;
        balances[2] = 1000e18;

        uint256 invariant = pool.computeInvariant(balances, Rounding.ROUND_DOWN);

        assertTrue(invariant > 0, "3-token invariant should be positive");
    }

    function test_computeInvariant_fiveTokenPool_works() public {
        // Maximum tokens for stable pools
        uint256[] memory balances = new uint256[](5);
        for (uint256 i = 0; i < 5; i++) {
            balances[i] = 1000e18;
        }

        uint256 invariant = pool.computeInvariant(balances, Rounding.ROUND_DOWN);

        assertTrue(invariant > 0, "5-token invariant should be positive");
    }

    function testFuzz_computeInvariant_anyBalances_returnsPositive(uint256 bal0, uint256 bal1) public view {
        // StableMath's iterative solver requires reasonable balance ratios
        // Extreme imbalances (>100x difference) can cause convergence failures
        bal0 = bound(bal0, 1e18, 1e27);
        bal1 = bound(bal1, 1e18, 1e27);

        // Ensure ratio is within StableMath's convergence range
        if (bal0 > bal1 * 100 || bal1 > bal0 * 100) {
            bal1 = bal0; // Force balanced if extreme ratio
        }

        uint256[] memory balances = new uint256[](2);
        balances[0] = bal0;
        balances[1] = bal1;

        uint256 invariant = pool.computeInvariant(balances, Rounding.ROUND_DOWN);

        assertTrue(invariant > 0, "Invariant should be positive for non-zero balances");
    }

    /* ---------------------------------------------------------------------- */
    /*                        Amplification Effect Tests                       */
    /* ---------------------------------------------------------------------- */

    function test_computeInvariant_highAmp_closerToSum() public {
        // High amp makes the curve flatter, invariant closer to sum of balances
        BalancerV3StablePoolTargetStub highAmpPool = new BalancerV3StablePoolTargetStub();
        highAmpPool.initialize(AMP_HIGH);

        uint256[] memory balances = new uint256[](2);
        balances[0] = 1000e18;
        balances[1] = 1000e18;

        uint256 invariant = highAmpPool.computeInvariant(balances, Rounding.ROUND_DOWN);
        uint256 sum = balances[0] + balances[1];

        // With high amp and equal balances, invariant should be close to sum
        assertApproxEqRel(invariant, sum, 0.01e18, "High amp invariant should be close to sum");
    }

    function test_computeInvariant_lowAmp_unbanlancedPool() public {
        // Low amp with unbalanced pool shows more constant-product-like behavior
        // For perfectly balanced pools, invariant ≈ sum regardless of amp
        // The difference shows in imbalanced scenarios
        BalancerV3StablePoolTargetStub lowAmpPool = new BalancerV3StablePoolTargetStub();
        lowAmpPool.initialize(AMP_LOW);

        BalancerV3StablePoolTargetStub highAmpPool = new BalancerV3StablePoolTargetStub();
        highAmpPool.initialize(AMP_HIGH);

        // Use imbalanced pool to see the amp effect
        uint256[] memory balances = new uint256[](2);
        balances[0] = 1500e18;
        balances[1] = 500e18;

        uint256 lowAmpInvariant = lowAmpPool.computeInvariant(balances, Rounding.ROUND_DOWN);
        uint256 highAmpInvariant = highAmpPool.computeInvariant(balances, Rounding.ROUND_DOWN);

        // Low amp should give lower invariant for imbalanced pools
        // (more penalty for imbalance, like constant product)
        assertLt(lowAmpInvariant, highAmpInvariant, "Low amp should give lower invariant for imbalanced pool");
    }

    /* ---------------------------------------------------------------------- */
    /*                            computeBalance Tests                         */
    /* ---------------------------------------------------------------------- */

    function test_computeBalance_invariantRatioOne_returnsSameBalance() public view {
        uint256[] memory balances = new uint256[](2);
        balances[0] = 1000e18;
        balances[1] = 1000e18;

        uint256 newBalance = pool.computeBalance(balances, 0, 1e18);

        assertApproxEqRel(newBalance, 1000e18, 1e14, "Balance should be approximately the same");
    }

    function test_computeBalance_invariantRatioDouble_increasesBalance() public view {
        uint256[] memory balances = new uint256[](2);
        balances[0] = 1000e18;
        balances[1] = 1000e18;

        uint256 newBalance = pool.computeBalance(balances, 0, 2e18);

        assertGt(newBalance, 1000e18, "New balance should be greater than original");
    }

    function testFuzz_computeBalance_positiveRatio_returnsPositive(uint256 bal0, uint256 bal1, uint256 ratio) public view {
        // Keep balances within StableMath convergence range
        bal0 = bound(bal0, 1e18, 1e25);
        bal1 = bound(bal1, 1e18, 1e25);

        // Ensure reasonable ratio between balances
        if (bal0 > bal1 * 10) bal1 = bal0 / 2;
        if (bal1 > bal0 * 10) bal0 = bal1 / 2;

        ratio = bound(ratio, 0.8e18, 1.5e18); // Tighter ratio bounds

        uint256[] memory balances = new uint256[](2);
        balances[0] = bal0;
        balances[1] = bal1;

        uint256 newBalance = pool.computeBalance(balances, 0, ratio);

        assertTrue(newBalance > 0, "New balance should be positive");
    }

    /* ---------------------------------------------------------------------- */
    /*                              onSwap Tests                               */
    /* ---------------------------------------------------------------------- */

    function test_onSwap_exactIn_returnsCorrectOutput() public view {
        uint256[] memory balances = new uint256[](2);
        balances[0] = 1000e18;
        balances[1] = 1000e18;

        PoolSwapParams memory params = PoolSwapParams({
            kind: SwapKind.EXACT_IN,
            amountGivenScaled18: 100e18,
            balancesScaled18: balances,
            indexIn: 0,
            indexOut: 1,
            router: address(0),
            userData: ""
        });

        uint256 amountOut = pool.onSwap(params);

        // Calculate expected using StableMath
        (uint256 amp,,) = pool.getAmplificationParameter();
        uint256 invariant = StableMath.computeInvariant(amp, balances);
        uint256 expected = StableMath.computeOutGivenExactIn(
            amp, balances, 0, 1, 100e18, invariant
        );

        assertEq(amountOut, expected, "EXACT_IN should return correct output amount");
        assertTrue(amountOut > 0, "Output should be positive");
    }

    function test_onSwap_exactOut_returnsCorrectInput() public view {
        uint256[] memory balances = new uint256[](2);
        balances[0] = 1000e18;
        balances[1] = 1000e18;

        PoolSwapParams memory params = PoolSwapParams({
            kind: SwapKind.EXACT_OUT,
            amountGivenScaled18: 50e18,
            balancesScaled18: balances,
            indexIn: 0,
            indexOut: 1,
            router: address(0),
            userData: ""
        });

        uint256 amountIn = pool.onSwap(params);

        // Calculate expected using StableMath
        (uint256 amp,,) = pool.getAmplificationParameter();
        uint256 invariant = StableMath.computeInvariant(amp, balances);
        uint256 expected = StableMath.computeInGivenExactOut(
            amp, balances, 0, 1, 50e18, invariant
        );

        assertEq(amountIn, expected, "EXACT_OUT should return correct input amount");
        assertTrue(amountIn > 0, "Input should be positive");
    }

    function test_onSwap_exactIn_nearParity_lowSlippage() public {
        // Stable pools should have very low slippage for balanced pools with high amp
        BalancerV3StablePoolTargetStub highAmpPool = new BalancerV3StablePoolTargetStub();
        highAmpPool.initialize(AMP_HIGH);

        uint256[] memory balances = new uint256[](2);
        balances[0] = 1000e18;
        balances[1] = 1000e18;

        PoolSwapParams memory params = PoolSwapParams({
            kind: SwapKind.EXACT_IN,
            amountGivenScaled18: 10e18,
            balancesScaled18: balances,
            indexIn: 0,
            indexOut: 1,
            router: address(0),
            userData: ""
        });

        uint256 amountOut = highAmpPool.onSwap(params);

        // For balanced stable pool with high amp, output should be very close to input
        assertApproxEqRel(amountOut, 10e18, 0.01e18, "High amp pool should have ~1:1 swap near parity");
    }

    function test_onSwap_exactIn_reverseDirection() public view {
        uint256[] memory balances = new uint256[](2);
        balances[0] = 1000e18;
        balances[1] = 1000e18;

        PoolSwapParams memory params = PoolSwapParams({
            kind: SwapKind.EXACT_IN,
            amountGivenScaled18: 50e18,
            balancesScaled18: balances,
            indexIn: 1,
            indexOut: 0,
            router: address(0),
            userData: ""
        });

        uint256 amountOut = pool.onSwap(params);

        (uint256 amp,,) = pool.getAmplificationParameter();
        uint256 invariant = StableMath.computeInvariant(amp, balances);
        uint256 expected = StableMath.computeOutGivenExactIn(
            amp, balances, 1, 0, 50e18, invariant
        );

        assertEq(amountOut, expected, "Reverse direction EXACT_IN should work correctly");
    }

    function test_onSwap_exactIn_smallAmount_noRevert() public view {
        uint256[] memory balances = new uint256[](2);
        balances[0] = 1000e18;
        balances[1] = 1000e18;

        // Use a small but not tiny amount - StableMath has precision limits
        // 1e12 is 0.000001 tokens which is reasonable for 18 decimal tokens
        PoolSwapParams memory params = PoolSwapParams({
            kind: SwapKind.EXACT_IN,
            amountGivenScaled18: 1e12,
            balancesScaled18: balances,
            indexIn: 0,
            indexOut: 1,
            router: address(0),
            userData: ""
        });

        uint256 amountOut = pool.onSwap(params);

        // Should not revert for small amounts
        assertLe(amountOut, 1e15, "Small input should produce small output");
        assertTrue(amountOut > 0, "Should still produce some output");
    }

    function testFuzz_onSwap_exactIn_outputPositive(uint256 balA, uint256 balB, uint256 amountIn) public view {
        // Keep balances within StableMath convergence range
        balA = bound(balA, 1e18, 1e24);
        balB = bound(balB, 1e18, 1e24);

        // Ensure reasonable ratio between balances (max 10x difference)
        if (balA > balB * 10) balB = balA / 2;
        if (balB > balA * 10) balA = balB / 2;

        // Swap amount should be reasonable relative to pool size
        amountIn = bound(amountIn, 1e15, balA / 20);

        uint256[] memory balances = new uint256[](2);
        balances[0] = balA;
        balances[1] = balB;

        PoolSwapParams memory params = PoolSwapParams({
            kind: SwapKind.EXACT_IN,
            amountGivenScaled18: amountIn,
            balancesScaled18: balances,
            indexIn: 0,
            indexOut: 1,
            router: address(0),
            userData: ""
        });

        uint256 amountOut = pool.onSwap(params);

        assertTrue(amountOut > 0, "Output should be positive");
    }

    function testFuzz_onSwap_exactOut_inputPositive(uint256 balA, uint256 balB, uint256 amountOutRaw) public view {
        // Keep balances within StableMath convergence range
        balA = bound(balA, 1e18, 1e24);
        balB = bound(balB, 1e18, 1e24);

        // Ensure reasonable ratio between balances
        if (balA > balB * 10) balB = balA / 2;
        if (balB > balA * 10) balA = balB / 2;

        // Bound amountOut to reasonable range (max 5% of output token balance)
        uint256 amountOut = bound(amountOutRaw, 1e15, balB / 20);

        uint256[] memory balances = new uint256[](2);
        balances[0] = balA;
        balances[1] = balB;

        PoolSwapParams memory params = PoolSwapParams({
            kind: SwapKind.EXACT_OUT,
            amountGivenScaled18: amountOut,
            balancesScaled18: balances,
            indexIn: 0,
            indexOut: 1,
            router: address(0),
            userData: ""
        });

        uint256 amountIn = pool.onSwap(params);

        assertTrue(amountIn > 0, "Input should be positive");
    }

    function test_onSwap_exactIn_invariantPreservedOrIncreases() public view {
        uint256[] memory balances = new uint256[](2);
        balances[0] = 1000e18;
        balances[1] = 1000e18;

        uint256 invariantBefore = pool.computeInvariant(balances, Rounding.ROUND_DOWN);

        PoolSwapParams memory params = PoolSwapParams({
            kind: SwapKind.EXACT_IN,
            amountGivenScaled18: 50e18,
            balancesScaled18: balances,
            indexIn: 0,
            indexOut: 1,
            router: address(0),
            userData: ""
        });

        uint256 amountOut = pool.onSwap(params);

        // Update balances after swap
        uint256[] memory newBalances = new uint256[](2);
        newBalances[0] = balances[0] + 50e18;
        newBalances[1] = balances[1] - amountOut;

        uint256 invariantAfter = pool.computeInvariant(newBalances, Rounding.ROUND_DOWN);

        // Invariant should be preserved or slightly increase
        assertApproxEqRel(invariantAfter, invariantBefore, 1e14, "Invariant should be approximately preserved");
    }

    /* ---------------------------------------------------------------------- */
    /*                    Amplification Transition Tests                       */
    /* ---------------------------------------------------------------------- */

    function test_startAmplificationParameterUpdate_startsTransition() public {
        uint256 newAmp = 200;
        uint256 endTime = block.timestamp + 2 days;

        pool.startAmplificationParameterUpdate(newAmp, endTime);

        (uint256 value, bool isUpdating,) = pool.getAmplificationParameter();

        assertTrue(isUpdating, "Should be updating");
        // Value should still be close to initial since we just started
        assertApproxEqRel(value, AMP_DEFAULT * StableMath.AMP_PRECISION, 0.01e18, "Value should be close to initial");
    }

    function test_amplificationParameterUpdate_interpolatesCorrectly() public {
        uint256 newAmp = 200;
        uint256 duration = 2 days;
        uint256 endTime = block.timestamp + duration;

        pool.startAmplificationParameterUpdate(newAmp, endTime);

        // Warp to halfway
        vm.warp(block.timestamp + duration / 2);

        (uint256 value, bool isUpdating,) = pool.getAmplificationParameter();

        assertTrue(isUpdating, "Should still be updating");
        // Value should be approximately halfway between initial and target
        uint256 expectedMidpoint = (AMP_DEFAULT + newAmp) * StableMath.AMP_PRECISION / 2;
        assertApproxEqRel(value, expectedMidpoint, 0.01e18, "Should be at midpoint");
    }

    function test_amplificationParameterUpdate_completesCorrectly() public {
        uint256 newAmp = 200;
        uint256 duration = 2 days;
        uint256 endTime = block.timestamp + duration;

        pool.startAmplificationParameterUpdate(newAmp, endTime);

        // Warp past end time
        vm.warp(endTime + 1);

        (uint256 value, bool isUpdating,) = pool.getAmplificationParameter();

        assertFalse(isUpdating, "Should not be updating anymore");
        assertEq(value, newAmp * StableMath.AMP_PRECISION, "Value should be at target");
    }

    function test_stopAmplificationParameterUpdate_freezesValue() public {
        uint256 newAmp = 200;
        uint256 endTime = block.timestamp + 2 days;

        pool.startAmplificationParameterUpdate(newAmp, endTime);

        // Warp to halfway
        vm.warp(block.timestamp + 1 days);

        (uint256 valueBefore,,) = pool.getAmplificationParameter();

        pool.stopAmplificationParameterUpdate();

        (uint256 valueAfter, bool isUpdating,) = pool.getAmplificationParameter();

        assertFalse(isUpdating, "Should not be updating");
        assertEq(valueAfter, valueBefore, "Value should be frozen at current");
    }

    function test_startAmplificationParameterUpdate_revertsIfDurationTooShort() public {
        uint256 newAmp = 200;
        uint256 endTime = block.timestamp + 12 hours; // Less than 1 day

        vm.expectRevert(BalancerV3StablePoolRepo.AmpUpdateDurationTooShort.selector);
        pool.startAmplificationParameterUpdate(newAmp, endTime);
    }

    function test_startAmplificationParameterUpdate_revertsIfRateTooFast() public {
        uint256 newAmp = 500; // 5x change
        uint256 endTime = block.timestamp + 1 days; // Only 1 day for 5x change

        vm.expectRevert(BalancerV3StablePoolRepo.AmpUpdateRateTooFast.selector);
        pool.startAmplificationParameterUpdate(newAmp, endTime);
    }

    function test_startAmplificationParameterUpdate_revertsIfAlreadyUpdating() public {
        uint256 newAmp = 150;
        uint256 endTime = block.timestamp + 2 days;

        pool.startAmplificationParameterUpdate(newAmp, endTime);

        // Try to start another update
        vm.expectRevert(BalancerV3StablePoolRepo.AmpUpdateAlreadyStarted.selector);
        pool.startAmplificationParameterUpdate(200, block.timestamp + 3 days);
    }

    function test_stopAmplificationParameterUpdate_revertsIfNotUpdating() public {
        vm.expectRevert(BalancerV3StablePoolRepo.AmpUpdateNotStarted.selector);
        pool.stopAmplificationParameterUpdate();
    }

    /* ---------------------------------------------------------------------- */
    /*                           Edge Case Tests                               */
    /* ---------------------------------------------------------------------- */

    function test_initialize_revertsIfAmpTooLow() public {
        BalancerV3StablePoolTargetStub newPool = new BalancerV3StablePoolTargetStub();

        vm.expectRevert(BalancerV3StablePoolRepo.AmplificationFactorTooLow.selector);
        newPool.initialize(0);
    }

    function test_initialize_revertsIfAmpTooHigh() public {
        BalancerV3StablePoolTargetStub newPool = new BalancerV3StablePoolTargetStub();

        vm.expectRevert(BalancerV3StablePoolRepo.AmplificationFactorTooHigh.selector);
        newPool.initialize(50001); // Above 50000 max (StableMath.MAX_AMP)
    }

    function test_initialize_acceptsMinAmp() public {
        BalancerV3StablePoolTargetStub newPool = new BalancerV3StablePoolTargetStub();
        newPool.initialize(StableMath.MIN_AMP);

        (uint256 value,,) = newPool.getAmplificationParameter();
        assertEq(value, StableMath.MIN_AMP * StableMath.AMP_PRECISION, "Should accept MIN_AMP");
    }

    function test_initialize_acceptsMaxAmp() public {
        BalancerV3StablePoolTargetStub newPool = new BalancerV3StablePoolTargetStub();
        newPool.initialize(StableMath.MAX_AMP);

        (uint256 value,,) = newPool.getAmplificationParameter();
        assertEq(value, StableMath.MAX_AMP * StableMath.AMP_PRECISION, "Should accept MAX_AMP");
    }
}
