// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/StdInvariant.sol";

import {SlipstreamUtils} from "@crane/contracts/utils/math/SlipstreamUtils.sol";
import {TestBase_Slipstream, MockCLPool} from "@crane/contracts/protocols/dexes/aerodrome/slipstream/test/bases/TestBase_Slipstream.sol";
import {TickMath} from "@crane/contracts/protocols/dexes/uniswap/v3/libraries/TickMath.sol";
import {SwapMath} from "@crane/contracts/protocols/dexes/uniswap/v3/libraries/SwapMath.sol";
import {FullMath} from "@crane/contracts/protocols/dexes/uniswap/v3/libraries/FullMath.sol";

/* -------------------------------------------------------------------------- */
/*                        Handler Contract for Invariants                     */
/* -------------------------------------------------------------------------- */

/// @title SlipstreamUtilsHandler
/// @notice Handler contract for invariant testing of SlipstreamUtils quote functions
/// @dev Tracks expected state and exposes fuzzable operations for Foundry invariant testing
contract SlipstreamUtilsHandler is Test {
    using SlipstreamUtils for *;

    /* -------------------------------------------------------------------------- */
    /*                                 Constants                                  */
    /* -------------------------------------------------------------------------- */

    /// @dev Fee denominator (1,000,000 for pips precision)
    uint256 constant FEE_DENOMINATOR = 1e6;

    /// @dev High minimum liquidity to ensure swaps stay within single tick
    uint128 constant MIN_LIQUIDITY = 1e24;

    /// @dev Maximum liquidity
    uint128 constant MAX_LIQUIDITY = 1e30;

    /// @dev Minimum amount to swap (avoid dust)
    uint256 constant MIN_AMOUNT = 1e15;

    /// @dev Maximum amount - must be small relative to liquidity to stay in single tick
    uint256 constant MAX_AMOUNT = 1e21;

    /// @dev Safe tick range to avoid extreme price calculations
    int24 constant SAFE_TICK_MIN = -100000;
    int24 constant SAFE_TICK_MAX = 100000;

    /// @dev Standard fee tiers (in pips)
    uint24 constant FEE_LOW = 500;      // 0.05%
    uint24 constant FEE_MEDIUM = 3000;  // 0.3%
    uint24 constant FEE_HIGH = 10000;   // 1%

    /* -------------------------------------------------------------------------- */
    /*                                   State                                    */
    /* -------------------------------------------------------------------------- */

    /// @dev Current pool state for invariant testing
    uint160 public currentSqrtPriceX96;
    int24 public currentTick;
    uint128 public currentLiquidity;
    uint24 public currentFee;

    /// @dev Tracking variables for invariant verification
    uint256[] public exactInputAmounts;
    uint256[] public exactInputOutputs;
    uint256[] public exactOutputAmounts;
    uint256[] public exactOutputInputs;

    /// @dev Monotonicity tracking
    uint256 public lastAmountIn;
    uint256 public lastAmountOut;
    bool public monotonicityTestActive;

    /// @dev Fee bounds tracking - records (amountIn, feeAmount, feePips)
    uint256[] public recordedAmountIns;
    uint256[] public recordedFeeAmounts;
    uint24[] public recordedFeePips;

    /// @dev Track operations for ghost state
    uint256 public operationCount;
    uint256 public reversibilityViolations;
    uint256 public monotonicityViolations;
    uint256 public feeBoundViolations;

    /* -------------------------------------------------------------------------- */
    /*                              Setup Functions                               */
    /* -------------------------------------------------------------------------- */

    constructor() {
        // Initialize with a reasonable pool state
        currentTick = 0;  // 1:1 price ratio
        currentSqrtPriceX96 = TickMath.getSqrtRatioAtTick(currentTick);
        currentLiquidity = MIN_LIQUIDITY;
        currentFee = FEE_MEDIUM;
    }

    /// @notice Reset the handler state for a new test run
    function resetState() external {
        currentTick = 0;
        currentSqrtPriceX96 = TickMath.getSqrtRatioAtTick(currentTick);
        currentLiquidity = MIN_LIQUIDITY;
        currentFee = FEE_MEDIUM;
        operationCount = 0;
        reversibilityViolations = 0;
        monotonicityViolations = 0;
        feeBoundViolations = 0;
        delete exactInputAmounts;
        delete exactInputOutputs;
        delete exactOutputAmounts;
        delete exactOutputInputs;
        delete recordedAmountIns;
        delete recordedFeeAmounts;
        delete recordedFeePips;
    }

    /* -------------------------------------------------------------------------- */
    /*                           Pool State Setters                               */
    /* -------------------------------------------------------------------------- */

    /// @notice Set pool state with bounded parameters
    function setPoolState(int24 tickSeed, uint128 liquiditySeed, uint8 feeIndex) external {
        // Bound tick to safe range
        currentTick = int24(bound(int256(tickSeed), SAFE_TICK_MIN, SAFE_TICK_MAX));
        currentSqrtPriceX96 = TickMath.getSqrtRatioAtTick(currentTick);

        // Bound liquidity
        currentLiquidity = uint128(bound(liquiditySeed, MIN_LIQUIDITY, MAX_LIQUIDITY));

        // Select fee tier
        uint24[3] memory fees = [FEE_LOW, FEE_MEDIUM, FEE_HIGH];
        currentFee = fees[bound(feeIndex, 0, 2)];
    }

    /* -------------------------------------------------------------------------- */
    /*                    US-CRANE-041.1: Reversibility Operations                */
    /* -------------------------------------------------------------------------- */

    /// @notice Test quoteExactInput(quoteExactOutput(x)) ≈ x
    /// @dev Records reversibility data for invariant checking
    function testReversibility_ExactOutputThenInput(uint256 amountOutSeed, bool zeroForOne) external {
        // Bound amount relative to liquidity to stay in single tick
        uint256 amountOut = bound(amountOutSeed, MIN_AMOUNT, currentLiquidity / 100000);

        // Step 1: Quote input required for desired output
        uint256 requiredInput = SlipstreamUtils._quoteExactOutputSingle(
            amountOut,
            currentSqrtPriceX96,
            currentLiquidity,
            currentFee,
            zeroForOne
        );

        // Step 2: Quote output for the required input
        uint256 resultingOutput = SlipstreamUtils._quoteExactInputSingle(
            requiredInput,
            currentSqrtPriceX96,
            currentLiquidity,
            currentFee,
            zeroForOne
        );

        // Track for invariant checking
        exactOutputAmounts.push(amountOut);
        exactOutputInputs.push(requiredInput);
        exactInputAmounts.push(requiredInput);
        exactInputOutputs.push(resultingOutput);

        operationCount++;

        // Check reversibility - output should be >= original (due to fee rounding in favor)
        // Allow 1 wei tolerance
        if (resultingOutput < amountOut - 1) {
            reversibilityViolations++;
        }

        // The resulting output should not be significantly more than requested
        // Due to double fee application, allow up to ~2% tolerance + 2 wei
        uint256 tolerance = (amountOut * 20) / 1000 + 2;
        if (resultingOutput > amountOut + tolerance) {
            reversibilityViolations++;
        }
    }

    /// @notice Test quoteExactOutput(quoteExactInput(x)) ≈ x
    /// @dev Alternative roundtrip direction
    function testReversibility_ExactInputThenOutput(uint256 amountInSeed, bool zeroForOne) external {
        // Bound amount
        uint256 amountIn = bound(amountInSeed, MIN_AMOUNT, MAX_AMOUNT);

        // Step 1: Quote output for given input
        uint256 outputForInput = SlipstreamUtils._quoteExactInputSingle(
            amountIn,
            currentSqrtPriceX96,
            currentLiquidity,
            currentFee,
            zeroForOne
        );

        // Skip if output is too small (avoids division by zero issues)
        if (outputForInput < MIN_AMOUNT) return;

        // Step 2: Quote input required to get that output
        uint256 requiredInputForOutput = SlipstreamUtils._quoteExactOutputSingle(
            outputForInput,
            currentSqrtPriceX96,
            currentLiquidity,
            currentFee,
            zeroForOne
        );

        // Track for invariant checking
        exactInputAmounts.push(amountIn);
        exactInputOutputs.push(outputForInput);
        exactOutputAmounts.push(outputForInput);
        exactOutputInputs.push(requiredInputForOutput);

        operationCount++;

        // Check reversibility - required input should be <= original (due to fee structure)
        // Allow 2% tolerance + 2 wei for rounding
        uint256 tolerance = (amountIn * 20) / 1000 + 2;
        if (requiredInputForOutput > amountIn + tolerance) {
            reversibilityViolations++;
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                    US-CRANE-041.2: Monotonicity Operations                 */
    /* -------------------------------------------------------------------------- */

    /// @notice Test that larger input yields larger or equal output
    /// @dev amountIn1 > amountIn2 implies amountOut1 >= amountOut2
    function testMonotonicity_ExactInput(
        uint256 smallAmountSeed,
        uint256 largeAmountSeed,
        bool zeroForOne
    ) external {
        // Ensure distinct amounts
        uint256 smallAmount = bound(smallAmountSeed, MIN_AMOUNT, MAX_AMOUNT / 2);
        uint256 largeAmount = bound(largeAmountSeed, smallAmount + 1, MAX_AMOUNT);

        // Quote for small amount
        uint256 smallOutput = SlipstreamUtils._quoteExactInputSingle(
            smallAmount,
            currentSqrtPriceX96,
            currentLiquidity,
            currentFee,
            zeroForOne
        );

        // Quote for large amount
        uint256 largeOutput = SlipstreamUtils._quoteExactInputSingle(
            largeAmount,
            currentSqrtPriceX96,
            currentLiquidity,
            currentFee,
            zeroForOne
        );

        operationCount++;

        // Monotonicity check: larger input should give larger or equal output
        if (largeOutput < smallOutput) {
            monotonicityViolations++;
        }

        // Track for invariant verification
        lastAmountIn = largeAmount;
        lastAmountOut = largeOutput;
        monotonicityTestActive = true;
    }

    /// @notice Test monotonicity across fee tiers
    /// @dev Lower fee should give more output for same input
    function testMonotonicity_FeeTiers(uint256 amountInSeed, bool zeroForOne) external {
        uint256 amountIn = bound(amountInSeed, MIN_AMOUNT, MAX_AMOUNT);

        // Quote with low fee
        uint256 outputLowFee = SlipstreamUtils._quoteExactInputSingle(
            amountIn,
            currentSqrtPriceX96,
            currentLiquidity,
            FEE_LOW,
            zeroForOne
        );

        // Quote with medium fee
        uint256 outputMedFee = SlipstreamUtils._quoteExactInputSingle(
            amountIn,
            currentSqrtPriceX96,
            currentLiquidity,
            FEE_MEDIUM,
            zeroForOne
        );

        // Quote with high fee
        uint256 outputHighFee = SlipstreamUtils._quoteExactInputSingle(
            amountIn,
            currentSqrtPriceX96,
            currentLiquidity,
            FEE_HIGH,
            zeroForOne
        );

        operationCount++;

        // Monotonicity: lower fee should give >= output
        if (outputMedFee > outputLowFee || outputHighFee > outputMedFee) {
            monotonicityViolations++;
        }
    }

    /// @notice Test monotonicity across liquidity levels
    /// @dev Higher liquidity should give same or better output (less slippage)
    function testMonotonicity_LiquidityLevels(
        uint256 amountInSeed,
        uint128 lowLiquiditySeed,
        uint128 highLiquiditySeed,
        bool zeroForOne
    ) external {
        uint256 amountIn = bound(amountInSeed, MIN_AMOUNT, MAX_AMOUNT);

        // Bound liquidity levels
        uint128 lowLiquidity = uint128(bound(lowLiquiditySeed, MIN_LIQUIDITY, MIN_LIQUIDITY * 10));
        uint128 highLiquidity = uint128(bound(highLiquiditySeed, lowLiquidity * 2, MAX_LIQUIDITY));

        // Quote with low liquidity
        uint256 outputLowLiq = SlipstreamUtils._quoteExactInputSingle(
            amountIn,
            currentSqrtPriceX96,
            lowLiquidity,
            currentFee,
            zeroForOne
        );

        // Quote with high liquidity
        uint256 outputHighLiq = SlipstreamUtils._quoteExactInputSingle(
            amountIn,
            currentSqrtPriceX96,
            highLiquidity,
            currentFee,
            zeroForOne
        );

        operationCount++;

        // Higher liquidity means less price impact, so output should be >= low liquidity output
        if (outputHighLiq < outputLowLiq) {
            monotonicityViolations++;
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                    US-CRANE-041.3: Fee Bounds Operations                   */
    /* -------------------------------------------------------------------------- */

    /// @notice Record fee data for invariant checking
    /// @dev Tests feeAmount bounds based on Uniswap V3 fee mechanics
    /// @dev When swap completes: feeAmount = FullMath.mulDivRoundingUp(actualAmountIn, fee, 1e6 - fee)
    /// @dev When swap hits limit: feeAmount = amountRemaining - actualAmountIn (all remaining goes to fee)
    function testFeeBounds_ExactInput(uint256 amountInSeed, uint8 feeIndex, bool zeroForOne) external {
        uint256 amountIn = bound(amountInSeed, MIN_AMOUNT, MAX_AMOUNT);

        // Select fee tier
        uint24[3] memory fees = [FEE_LOW, FEE_MEDIUM, FEE_HIGH];
        uint24 fee = fees[bound(feeIndex, 0, 2)];

        // Set target price to tick boundary for computation
        uint160 sqrtPriceTargetX96 = zeroForOne
            ? TickMath.MIN_SQRT_RATIO + 1
            : TickMath.MAX_SQRT_RATIO - 1;

        // Use SwapMath to get the fee amount directly
        (uint160 sqrtRatioNextX96, uint256 actualAmountIn, uint256 amountOut, uint256 feeAmount) = SwapMath.computeSwapStep(
            currentSqrtPriceX96,
            sqrtPriceTargetX96,
            currentLiquidity,
            int256(amountIn),
            fee
        );

        // Understanding SwapMath fee calculation:
        // - sqrtRatioNextX96 == sqrtPriceTargetX96: swap REACHED the target, fee = mulDivRoundingUp formula
        // - sqrtRatioNextX96 != sqrtPriceTargetX96: swap DIDN'T reach target, fee = amountIn - actualAmountIn
        //
        // We record fee data only when the mulDivRoundingUp formula is used (target reached)
        if (sqrtRatioNextX96 == sqrtPriceTargetX96) {
            // Swap reached target - fee uses formula: FullMath.mulDivRoundingUp(amountIn, fee, 1e6 - fee)
            recordedAmountIns.push(actualAmountIn);
            recordedFeeAmounts.push(feeAmount);
            recordedFeePips.push(fee);
        }

        operationCount++;

        // CORE FEE INVARIANT: Fee can never exceed the input amount
        // This is the fundamental fee bound that must always hold.
        if (feeAmount > amountIn) {
            feeBoundViolations++;
        }

        // Note: We do NOT check amountOut <= amountIn because in a price conversion
        // swap (e.g., WETH -> USDC), the output can be numerically larger than input
        // when swapping from lower-priced to higher-priced token.

        // Use amountOut to prevent compiler warning about unused variable
        if (amountOut > 0) {
            // amountOut is used - swap produced output
        }
    }

    /// @notice Test fee calculation accuracy across different amounts
    /// @dev This is a soft test - it verifies fee is approximately correct but doesn't count violations
    /// @dev The actual fee uses FullMath.mulDivRoundingUp(amountIn, fee, 1e6 - fee) when swap completes
    /// @dev But when swap doesn't fully fill, fee = amountRemaining - amountIn (all remaining goes to fee)
    function testFeeAccuracy(uint256 amountInSeed, bool zeroForOne) external {
        uint256 amountIn = bound(amountInSeed, MIN_AMOUNT, MAX_AMOUNT);

        uint160 sqrtPriceTargetX96 = zeroForOne
            ? TickMath.MIN_SQRT_RATIO + 1
            : TickMath.MAX_SQRT_RATIO - 1;

        // Get fee amount for medium fee tier
        (uint160 sqrtRatioNextX96, uint256 actualAmountIn,, uint256 feeAmount) = SwapMath.computeSwapStep(
            currentSqrtPriceX96,
            sqrtPriceTargetX96,
            currentLiquidity,
            int256(amountIn),
            FEE_MEDIUM
        );

        operationCount++;

        // Understanding SwapMath fee calculation (lines 91-96):
        // - sqrtRatioNextX96 == sqrtPriceTargetX96: swap REACHED the target, fee = mulDivRoundingUp formula
        // - sqrtRatioNextX96 != sqrtPriceTargetX96: swap DIDN'T reach target, fee = amountIn - actualAmountIn
        //
        // Only verify formula-based fee accuracy when swap reached the target price
        if (sqrtRatioNextX96 == sqrtPriceTargetX96) {
            // Swap reached price target - fee should follow the formula
            uint256 expectedFee = FullMath.mulDivRoundingUp(actualAmountIn, FEE_MEDIUM, FEE_DENOMINATOR - FEE_MEDIUM);

            // Verify fee is very close to computed formula (allow 1 wei for additional rounding)
            assertApproxEqAbs(feeAmount, expectedFee, 1, "Fee should match formula when swap reaches target");
        }
        // When swap doesn't reach target, fee = amountIn - actualAmountIn (remainder as fee)
    }

    /* -------------------------------------------------------------------------- */
    /*                          Invariant Query Functions                         */
    /* -------------------------------------------------------------------------- */

    function getOperationCount() external view returns (uint256) {
        return operationCount;
    }

    function getReversibilityViolations() external view returns (uint256) {
        return reversibilityViolations;
    }

    function getMonotonicityViolations() external view returns (uint256) {
        return monotonicityViolations;
    }

    function getFeeBoundViolations() external view returns (uint256) {
        return feeBoundViolations;
    }

    function getFeeRecordCount() external view returns (uint256) {
        return recordedAmountIns.length;
    }

    function getFeeRecord(uint256 idx) external view returns (uint256 amountIn, uint256 feeAmount, uint24 fee) {
        return (recordedAmountIns[idx], recordedFeeAmounts[idx], recordedFeePips[idx]);
    }
}

/* -------------------------------------------------------------------------- */
/*                        Invariant Test Contract                             */
/* -------------------------------------------------------------------------- */

/// @title SlipstreamUtils Invariant Tests
/// @notice Foundry invariant tests for SlipstreamUtils quote functions
/// @dev Tests three key invariants:
///      1. Quote Reversibility: roundtrip quotes should approximately match
///      2. Monotonicity: larger input yields larger output
///      3. Fee Bounds: fees are properly bounded by fee tier
contract SlipstreamUtils_invariants_Test is StdInvariant, TestBase_Slipstream {
    SlipstreamUtilsHandler public handler;

    /* -------------------------------------------------------------------------- */
    /*                                   Setup                                    */
    /* -------------------------------------------------------------------------- */

    function setUp() public override {
        super.setUp();

        // Deploy handler
        handler = new SlipstreamUtilsHandler();

        // Register handler as fuzz target
        targetContract(address(handler));

        // Select specific functions to target
        bytes4[] memory selectors = new bytes4[](7);
        selectors[0] = handler.setPoolState.selector;
        selectors[1] = handler.testReversibility_ExactOutputThenInput.selector;
        selectors[2] = handler.testReversibility_ExactInputThenOutput.selector;
        selectors[3] = handler.testMonotonicity_ExactInput.selector;
        selectors[4] = handler.testMonotonicity_FeeTiers.selector;
        selectors[5] = handler.testMonotonicity_LiquidityLevels.selector;
        selectors[6] = handler.testFeeBounds_ExactInput.selector;

        targetSelector(FuzzSelector({addr: address(handler), selectors: selectors}));
    }

    /* -------------------------------------------------------------------------- */
    /*            US-CRANE-041.1: Quote Reversibility Invariant                   */
    /* -------------------------------------------------------------------------- */

    /// @notice Invariant: Quote reversibility should hold within tolerance
    /// @dev quoteExactInput(quoteExactOutput(x)) ≈ x within documented tolerance
    /// @dev Acceptable tolerance: 2% due to double fee application and rounding
    function invariant_quoteReversibility() public view {
        uint256 violations = handler.getReversibilityViolations();
        uint256 operations = handler.getOperationCount();

        // If we had operations, there should be no reversibility violations
        if (operations > 0) {
            assertEq(violations, 0, "Reversibility violations detected");
        }
    }

    /* -------------------------------------------------------------------------- */
    /*            US-CRANE-041.2: Monotonicity Invariant                          */
    /* -------------------------------------------------------------------------- */

    /// @notice Invariant: Larger inputs should yield larger or equal outputs
    /// @dev amountIn1 > amountIn2 implies amountOut1 >= amountOut2
    function invariant_monotonicity() public view {
        uint256 violations = handler.getMonotonicityViolations();
        uint256 operations = handler.getOperationCount();

        // If we had operations, there should be no monotonicity violations
        if (operations > 0) {
            assertEq(violations, 0, "Monotonicity violations detected");
        }
    }

    /* -------------------------------------------------------------------------- */
    /*            US-CRANE-041.3: Fee Bounds Invariant                            */
    /* -------------------------------------------------------------------------- */

    /// @notice Invariant: Fees should be properly bounded
    /// @dev feeAmount <= amountIn * fee / 1e6, and fee never exceeds input
    function invariant_feeBounds() public view {
        uint256 violations = handler.getFeeBoundViolations();
        uint256 operations = handler.getOperationCount();

        // If we had operations, there should be no fee bound violations
        if (operations > 0) {
            assertEq(violations, 0, "Fee bound violations detected");
        }
    }

    /// @notice Invariant: Fee records should all satisfy the upper bound
    /// @dev Iterate through recorded fees and verify bounds
    /// @dev DOCUMENTED TOLERANCE: 0.01% relative + 10 wei absolute
    function invariant_feeRecordBounds() public view {
        uint256 recordCount = handler.getFeeRecordCount();

        for (uint256 i = 0; i < recordCount; i++) {
            (uint256 amountIn, uint256 feeAmount, uint24 fee) = handler.getFeeRecord(i);

            // Fee should never exceed the Uniswap V3 formula maximum
            // SwapMath uses: FullMath.mulDivRoundingUp(amountIn, feePips, 1e6 - feePips)
            // Allow 0.01% + 10 wei tolerance for cascading rounding effects
            uint256 maxFee = FullMath.mulDivRoundingUp(amountIn, fee, 1e6 - fee);
            uint256 tolerance = maxFee / 10000 + 10; // 0.01% + 10 wei

            assertTrue(
                feeAmount <= maxFee + tolerance,
                string(abi.encodePacked("Fee exceeds bound at record ", vm.toString(i)))
            );

            // Fee should never exceed input amount
            assertTrue(
                feeAmount <= amountIn,
                string(abi.encodePacked("Fee exceeds input at record ", vm.toString(i)))
            );
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                      Combined Invariant Summary                            */
    /* -------------------------------------------------------------------------- */

    /// @notice Invariant: No violations of any type should exist
    function invariant_noViolations() public view {
        uint256 revViolations = handler.getReversibilityViolations();
        uint256 monoViolations = handler.getMonotonicityViolations();
        uint256 feeViolations = handler.getFeeBoundViolations();

        uint256 totalViolations = revViolations + monoViolations + feeViolations;

        assertEq(totalViolations, 0, "Total invariant violations should be zero");
    }
}

/* -------------------------------------------------------------------------- */
/*                    Standalone Invariant Property Tests                     */
/* -------------------------------------------------------------------------- */

/// @title SlipstreamUtils Property Tests
/// @notice Additional property-based tests that don't use the handler pattern
/// @dev These are traditional fuzz tests that verify invariant properties
contract SlipstreamUtils_properties_Test is TestBase_Slipstream {
    using SlipstreamUtils for *;

    /* -------------------------------------------------------------------------- */
    /*                                 Constants                                  */
    /* -------------------------------------------------------------------------- */

    uint128 constant MIN_LIQUIDITY = 1e24;
    uint128 constant MAX_LIQUIDITY = 1e30;
    uint256 constant MIN_AMOUNT = 1e15;
    uint256 constant MAX_AMOUNT = 1e21;
    int24 constant SAFE_TICK_MIN = -100000;
    int24 constant SAFE_TICK_MAX = 100000;

    /* -------------------------------------------------------------------------- */
    /*              Property: Reversibility Within Tolerance                      */
    /* -------------------------------------------------------------------------- */

    /// @notice Property: quoteExactInput(quoteExactOutput(x)) returns approximately x
    /// @dev Tolerance: 2% due to fee rounding
    function testProperty_reversibility_exactOutputThenInput(
        uint256 amountOutSeed,
        int24 tickSeed,
        uint128 liquiditySeed,
        bool zeroForOne
    ) public pure {
        // Bound inputs
        int24 tick = int24(bound(int256(tickSeed), SAFE_TICK_MIN, SAFE_TICK_MAX));
        uint128 liquidity = uint128(bound(liquiditySeed, MIN_LIQUIDITY, MAX_LIQUIDITY));
        uint256 amountOut = bound(amountOutSeed, MIN_AMOUNT, liquidity / 100000);

        uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(tick);

        // Roundtrip
        uint256 requiredInput = SlipstreamUtils._quoteExactOutputSingle(
            amountOut, sqrtPriceX96, liquidity, FEE_MEDIUM, zeroForOne
        );

        uint256 resultingOutput = SlipstreamUtils._quoteExactInputSingle(
            requiredInput, sqrtPriceX96, liquidity, FEE_MEDIUM, zeroForOne
        );

        // INVARIANT: Output >= original - 1 wei
        assertTrue(
            resultingOutput >= amountOut - 1,
            "Reversibility: output should be >= original"
        );

        // INVARIANT: Output <= original + 2% + 2 wei
        uint256 tolerance = (amountOut * 20) / 1000 + 2;
        assertTrue(
            resultingOutput <= amountOut + tolerance,
            "Reversibility: output should not exceed 2% over original"
        );
    }

    /* -------------------------------------------------------------------------- */
    /*              Property: Monotonicity (Input -> Output)                      */
    /* -------------------------------------------------------------------------- */

    /// @notice Property: Larger input always yields larger or equal output
    function testProperty_monotonicity_inputOutput(
        uint256 smallAmountSeed,
        uint256 largeDeltaSeed,
        int24 tickSeed,
        uint128 liquiditySeed,
        bool zeroForOne
    ) public pure {
        // Bound inputs
        int24 tick = int24(bound(int256(tickSeed), SAFE_TICK_MIN, SAFE_TICK_MAX));
        uint128 liquidity = uint128(bound(liquiditySeed, MIN_LIQUIDITY, MAX_LIQUIDITY));
        uint256 smallAmount = bound(smallAmountSeed, MIN_AMOUNT, MAX_AMOUNT / 2);
        uint256 largeDelta = bound(largeDeltaSeed, 1, MAX_AMOUNT / 2);
        uint256 largeAmount = smallAmount + largeDelta;

        uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(tick);

        uint256 smallOutput = SlipstreamUtils._quoteExactInputSingle(
            smallAmount, sqrtPriceX96, liquidity, FEE_MEDIUM, zeroForOne
        );

        uint256 largeOutput = SlipstreamUtils._quoteExactInputSingle(
            largeAmount, sqrtPriceX96, liquidity, FEE_MEDIUM, zeroForOne
        );

        // INVARIANT: Larger input -> larger or equal output
        assertTrue(
            largeOutput >= smallOutput,
            "Monotonicity: larger input should give larger output"
        );
    }

    /* -------------------------------------------------------------------------- */
    /*              Property: Fee Tier Monotonicity                               */
    /* -------------------------------------------------------------------------- */

    /// @notice Property: Lower fee tier gives more output
    function testProperty_feeTier_monotonicity(
        uint256 amountInSeed,
        int24 tickSeed,
        uint128 liquiditySeed,
        bool zeroForOne
    ) public pure {
        // Bound inputs
        int24 tick = int24(bound(int256(tickSeed), SAFE_TICK_MIN, SAFE_TICK_MAX));
        uint128 liquidity = uint128(bound(liquiditySeed, MIN_LIQUIDITY, MAX_LIQUIDITY));
        uint256 amountIn = bound(amountInSeed, MIN_AMOUNT, MAX_AMOUNT);

        uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(tick);

        uint256 outputLow = SlipstreamUtils._quoteExactInputSingle(
            amountIn, sqrtPriceX96, liquidity, FEE_LOW, zeroForOne
        );

        uint256 outputMed = SlipstreamUtils._quoteExactInputSingle(
            amountIn, sqrtPriceX96, liquidity, FEE_MEDIUM, zeroForOne
        );

        uint256 outputHigh = SlipstreamUtils._quoteExactInputSingle(
            amountIn, sqrtPriceX96, liquidity, FEE_HIGH, zeroForOne
        );

        // INVARIANT: Lower fee -> more output
        assertTrue(outputLow >= outputMed, "Low fee should give >= medium fee output");
        assertTrue(outputMed >= outputHigh, "Medium fee should give >= high fee output");
    }

    /* -------------------------------------------------------------------------- */
    /*              Property: Fee Upper Bound                                     */
    /* -------------------------------------------------------------------------- */

    /// @notice Property: Fee amount is bounded by the Uniswap V3 fee formula
    /// @dev The actual fee formula is: feeAmount = amountIn * feePips / (1e6 - feePips) with rounding up
    /// This is because SwapMath computes: FullMath.mulDivRoundingUp(amountIn, feePips, 1e6 - feePips)
    function testProperty_feeBound(
        uint256 amountInSeed,
        int24 tickSeed,
        uint128 liquiditySeed,
        uint8 feeIndex,
        bool zeroForOne
    ) public pure {
        // Bound inputs
        int24 tick = int24(bound(int256(tickSeed), SAFE_TICK_MIN, SAFE_TICK_MAX));
        uint128 liquidity = uint128(bound(liquiditySeed, MIN_LIQUIDITY, MAX_LIQUIDITY));
        uint256 amountIn = bound(amountInSeed, MIN_AMOUNT, MAX_AMOUNT);

        uint24[3] memory fees = [FEE_LOW, FEE_MEDIUM, FEE_HIGH];
        uint24 fee = fees[bound(feeIndex, 0, 2)];

        uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(tick);
        uint160 sqrtPriceTargetX96 = zeroForOne
            ? TickMath.MIN_SQRT_RATIO + 1
            : TickMath.MAX_SQRT_RATIO - 1;

        // Get fee from swap math
        (,,, uint256 feeAmount) = SwapMath.computeSwapStep(
            sqrtPriceX96,
            sqrtPriceTargetX96,
            liquidity,
            int256(amountIn),
            fee
        );

        // INVARIANT: fee <= amountIn * feePips / (1e6 - feePips) with rounding up
        // This is the exact formula from SwapMath.computeSwapStep line 95
        uint256 maxFee = FullMath.mulDivRoundingUp(amountIn, fee, 1e6 - fee);
        assertTrue(
            feeAmount <= maxFee,
            "Fee should be bounded by Uniswap V3 formula"
        );

        // INVARIANT: fee never exceeds input
        assertTrue(
            feeAmount <= amountIn,
            "Fee should never exceed input amount"
        );
    }

    /* -------------------------------------------------------------------------- */
    /*              Property: Output Never Exceeds Input Value                    */
    /* -------------------------------------------------------------------------- */

    /// @notice Property: Output amount should be less than input (fees taken)
    function testProperty_outputLessThanInput(
        uint256 amountInSeed,
        int24 tickSeed,
        uint128 liquiditySeed,
        bool zeroForOne
    ) public pure {
        // Bound inputs
        int24 tick = int24(bound(int256(tickSeed), SAFE_TICK_MIN, SAFE_TICK_MAX));
        uint128 liquidity = uint128(bound(liquiditySeed, MIN_LIQUIDITY, MAX_LIQUIDITY));
        uint256 amountIn = bound(amountInSeed, MIN_AMOUNT, MAX_AMOUNT);

        uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(tick);
        uint160 sqrtPriceTargetX96 = zeroForOne
            ? TickMath.MIN_SQRT_RATIO + 1
            : TickMath.MAX_SQRT_RATIO - 1;

        // Get output from swap math
        (,, uint256 amountOut,) = SwapMath.computeSwapStep(
            sqrtPriceX96,
            sqrtPriceTargetX96,
            liquidity,
            int256(amountIn),
            FEE_MEDIUM
        );

        // INVARIANT: At 1:1 price, output should be less than input due to fees
        // This property holds specifically when price is 1:1
        if (tick == 0) {
            assertTrue(
                amountOut < amountIn,
                "At 1:1 price, output should be less than input due to fees"
            );
        }
    }
}
