// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {ICamelotPair} from "@crane/contracts/interfaces/protocols/dexes/camelot/v2/ICamelotPair.sol";
import {CamelotV2Service} from "@crane/contracts/protocols/dexes/camelot/v2/services/CamelotV2Service.sol";
import {TestBase_ConstProdUtils_Camelot} from "@crane/test/foundry/spec/utils/math/constProdUtils/TestBase_ConstProdUtils_Camelot.sol";
import {ERC20PermitMintableStub} from "@crane/contracts/tokens/ERC20/ERC20PermitMintableStub.sol";
import {CamelotPair} from "@crane/contracts/protocols/dexes/camelot/v2/stubs/CamelotPair.sol";
import {CamelotFactory} from "@crane/contracts/protocols/dexes/camelot/v2/stubs/CamelotFactory.sol";

/**
 * @title CamelotV2_stableSwap_Test
 * @notice Tests for Camelot V2 stable swap pool behavior
 * @dev Camelot V2 stable swap mode uses a cubic invariant (x^3*y + y^3*x >= k)
 *      instead of the constant product invariant (x * y = k).
 *      This provides lower slippage for assets that should trade near 1:1.
 */
contract CamelotV2_stableSwap_Test is TestBase_ConstProdUtils_Camelot {
    using CamelotV2Service for ICamelotPair;

    /* ---------------------------------------------------------------------- */
    /*                              Test Tokens                               */
    /* ---------------------------------------------------------------------- */

    ERC20PermitMintableStub stableTokenA;
    ERC20PermitMintableStub stableTokenB;
    ICamelotPair stablePair;

    // For testing different decimal combinations
    ERC20PermitMintableStub stableToken6Dec;
    ERC20PermitMintableStub stableToken8Dec;
    ICamelotPair mixedDecimalPair;

    /* ---------------------------------------------------------------------- */
    /*                              Constants                                 */
    /* ---------------------------------------------------------------------- */

    uint256 constant FEE_DENOMINATOR = 100000;
    uint256 constant STABLE_INITIAL_LIQUIDITY = 10000e18;
    uint256 constant DEFAULT_FEE = 500; // 0.5%

    /* ---------------------------------------------------------------------- */
    /*                                 Setup                                  */
    /* ---------------------------------------------------------------------- */

    function setUp() public override {
        TestBase_ConstProdUtils_Camelot.setUp();
        _createStableTokens();
        _createStablePair();
    }

    function _createStableTokens() internal {
        stableTokenA = new ERC20PermitMintableStub("StableTokenA", "STA", 18, address(this), 0);
        vm.label(address(stableTokenA), "StableTokenA");

        stableTokenB = new ERC20PermitMintableStub("StableTokenB", "STB", 18, address(this), 0);
        vm.label(address(stableTokenB), "StableTokenB");

        // Create tokens with different decimals for edge case testing
        stableToken6Dec = new ERC20PermitMintableStub("Stable6Dec", "ST6", 6, address(this), 0);
        vm.label(address(stableToken6Dec), "Stable6Dec");

        stableToken8Dec = new ERC20PermitMintableStub("Stable8Dec", "ST8", 8, address(this), 0);
        vm.label(address(stableToken8Dec), "Stable8Dec");
    }

    function _createStablePair() internal {
        stablePair = ICamelotPair(camelotV2Factory.createPair(address(stableTokenA), address(stableTokenB)));
        vm.label(address(stablePair), "StablePair");

        mixedDecimalPair = ICamelotPair(camelotV2Factory.createPair(address(stableToken6Dec), address(stableToken8Dec)));
        vm.label(address(mixedDecimalPair), "MixedDecimalPair");
    }

    function _initializeStablePool() internal {
        stableTokenA.mint(address(this), STABLE_INITIAL_LIQUIDITY);
        stableTokenA.approve(address(camelotV2Router), STABLE_INITIAL_LIQUIDITY);
        stableTokenB.mint(address(this), STABLE_INITIAL_LIQUIDITY);
        stableTokenB.approve(address(camelotV2Router), STABLE_INITIAL_LIQUIDITY);

        CamelotV2Service._deposit(camelotV2Router, stableTokenA, stableTokenB, STABLE_INITIAL_LIQUIDITY, STABLE_INITIAL_LIQUIDITY);
    }

    function _initializeMixedDecimalPool() internal {
        uint256 amount6Dec = 10000e6; // 10,000 with 6 decimals
        uint256 amount8Dec = 10000e8; // 10,000 with 8 decimals

        stableToken6Dec.mint(address(this), amount6Dec);
        stableToken6Dec.approve(address(camelotV2Router), amount6Dec);
        stableToken8Dec.mint(address(this), amount8Dec);
        stableToken8Dec.approve(address(camelotV2Router), amount8Dec);

        CamelotV2Service._deposit(camelotV2Router, stableToken6Dec, stableToken8Dec, amount6Dec, amount8Dec);
    }

    function _enableStableSwap(ICamelotPair pair) internal {
        (uint112 reserve0, uint112 reserve1,,) = pair.getReserves();
        // The setStableOwner is the deployer (this test contract)
        vm.prank(address(this));
        CamelotPair(address(pair)).setStableSwap(true, reserve0, reserve1);
    }

    /* ---------------------------------------------------------------------- */
    /*                     Cubic Invariant Tests (US-CRANE-045.1)             */
    /* ---------------------------------------------------------------------- */

    /// @notice Test that enabling stable swap mode works correctly
    function test_enableStableSwap_setsFlag() public {
        _initializeStablePool();

        assertFalse(CamelotPair(address(stablePair)).stableSwap(), "Stable swap should be disabled initially");

        _enableStableSwap(stablePair);

        assertTrue(CamelotPair(address(stablePair)).stableSwap(), "Stable swap should be enabled");
    }

    /// @notice Test cubic invariant formula: x^3*y + y^3*x
    /// @dev Verifies _k() calculation matches expected cubic formula by directly
    ///      comparing the test-computed expectedK against the stub's k() return value.
    function test_cubicInvariant_calculation() public {
        _initializeStablePool();
        _enableStableSwap(stablePair);

        (uint112 reserve0, uint112 reserve1,,) = stablePair.getReserves();

        // Calculate expected K using the cubic formula
        // _k() normalizes to 18 decimals internally
        uint256 precMult0 = 10 ** stableTokenA.decimals();
        uint256 precMult1 = 10 ** stableTokenB.decimals();

        uint256 x = uint256(reserve0) * 1e18 / precMult0;
        uint256 y = uint256(reserve1) * 1e18 / precMult1;

        // x^3*y + y^3*x = xy(x^2 + y^2)
        uint256 a = (x * y) / 1e18;
        uint256 b = (x * x / 1e18) + (y * y / 1e18);
        uint256 expectedK = (a * b) / 1e18;

        // Direct assertion: compare test-computed expectedK against the stub's k()
        uint256 actualK = CamelotPair(address(stablePair)).k();
        assertEq(actualK, expectedK, "On-chain _k() must match expected cubic invariant xy(x^2 + y^2)");

        // Also verify swap output uses the cubic invariant (lower slippage)
        uint256 amountIn = 100e18;
        stableTokenA.mint(address(this), amountIn);

        uint256 amountOut = stablePair.getAmountOut(amountIn, address(stableTokenA));

        // For stable pairs with equal reserves, output should be close to input (minus fees)
        uint256 expectedFee = amountIn * DEFAULT_FEE / FEE_DENOMINATOR;
        uint256 expectedOutApprox = amountIn - expectedFee;

        assertGt(amountOut, expectedOutApprox * 95 / 100, "Stable swap output should be close to input minus fee");
        assertLt(amountOut, expectedOutApprox * 105 / 100, "Stable swap output should not exceed expected range");
    }

    /// @notice Test that _k() returns different values for stable vs constant product
    function test_kCalculation_stableVsConstantProduct() public {
        _initializeStablePool();

        (uint112 reserve0, uint112 reserve1,,) = stablePair.getReserves();

        // Get output in constant product mode
        uint256 amountIn = 100e18;
        uint256 outputConstantProduct = stablePair.getAmountOut(amountIn, address(stableTokenA));

        // Enable stable swap
        _enableStableSwap(stablePair);

        // Get output in stable swap mode
        uint256 outputStable = stablePair.getAmountOut(amountIn, address(stableTokenA));

        // Stable swap should give better (higher) output for balanced pools
        assertGt(outputStable, outputConstantProduct, "Stable swap should give better output for balanced pools");
    }

    /// @notice Test K preservation across swaps
    function test_kPreservation_afterSwap() public {
        _initializeStablePool();
        _enableStableSwap(stablePair);

        // Get initial reserves
        (uint112 reserve0Before, uint112 reserve1Before,,) = stablePair.getReserves();
        uint256 kBefore = _calculateK(reserve0Before, reserve1Before, stableTokenA.decimals(), stableTokenB.decimals());

        // Perform a swap
        uint256 swapAmount = 100e18;
        stableTokenA.mint(address(this), swapAmount);
        stableTokenA.approve(address(camelotV2Router), swapAmount);

        CamelotV2Service._swap(
            camelotV2Router,
            stablePair,
            swapAmount,
            stableTokenA,
            stableTokenB,
            address(0)
        );

        // Get reserves after swap
        (uint112 reserve0After, uint112 reserve1After,,) = stablePair.getReserves();
        uint256 kAfter = _calculateK(reserve0After, reserve1After, stableTokenA.decimals(), stableTokenB.decimals());

        // K should be preserved or increased (due to fees)
        assertGe(kAfter, kBefore, "K should be preserved or increased after swap");
    }

    /* ---------------------------------------------------------------------- */
    /*                       _get_y() Convergence Tests                       */
    /* ---------------------------------------------------------------------- */

    /// @notice Test Newton-Raphson convergence with small swap amounts
    /// @dev Asserts on actual balance delta rather than _swap() return value
    function test_getY_convergence_smallAmount() public {
        _initializeStablePool();
        _enableStableSwap(stablePair);

        uint256 swapAmount = 1e15; // 0.001 tokens
        stableTokenA.mint(address(this), swapAmount);
        stableTokenA.approve(address(camelotV2Router), swapAmount);

        uint256 balBefore = stableTokenB.balanceOf(address(this));

        // Should not revert - convergence should succeed
        CamelotV2Service._swap(
            camelotV2Router,
            stablePair,
            swapAmount,
            stableTokenA,
            stableTokenB,
            address(0)
        );

        uint256 received = stableTokenB.balanceOf(address(this)) - balBefore;
        assertGt(received, 0, "Small swap should produce output");
    }

    /// @notice Test Newton-Raphson convergence with large swap amounts
    /// @dev Asserts on actual balance delta rather than _swap() return value
    function test_getY_convergence_largeAmount() public {
        _initializeStablePool();
        _enableStableSwap(stablePair);

        uint256 swapAmount = 1000e18; // 10% of liquidity
        stableTokenA.mint(address(this), swapAmount);
        stableTokenA.approve(address(camelotV2Router), swapAmount);

        uint256 balBefore = stableTokenB.balanceOf(address(this));

        // Should not revert - convergence should succeed
        CamelotV2Service._swap(
            camelotV2Router,
            stablePair,
            swapAmount,
            stableTokenA,
            stableTokenB,
            address(0)
        );

        uint256 received = stableTokenB.balanceOf(address(this)) - balBefore;
        assertGt(received, 0, "Large swap should produce output");
    }

    /// @notice Test Newton-Raphson convergence with unbalanced reserves
    /// @dev Asserts on actual balance delta rather than _swap() return value
    function test_getY_convergence_unbalancedReserves() public {
        // Create pool with unbalanced initial liquidity
        uint256 amountA = 15000e18;
        uint256 amountB = 5000e18;

        stableTokenA.mint(address(this), amountA);
        stableTokenA.approve(address(camelotV2Router), amountA);
        stableTokenB.mint(address(this), amountB);
        stableTokenB.approve(address(camelotV2Router), amountB);

        CamelotV2Service._deposit(camelotV2Router, stableTokenA, stableTokenB, amountA, amountB);
        _enableStableSwap(stablePair);

        uint256 swapAmount = 500e18;
        stableTokenA.mint(address(this), swapAmount);
        stableTokenA.approve(address(camelotV2Router), swapAmount);

        uint256 balBefore = stableTokenB.balanceOf(address(this));

        // Should not revert even with unbalanced reserves
        CamelotV2Service._swap(
            camelotV2Router,
            stablePair,
            swapAmount,
            stableTokenA,
            stableTokenB,
            address(0)
        );

        uint256 received = stableTokenB.balanceOf(address(this)) - balBefore;
        assertGt(received, 0, "Unbalanced pool swap should produce output");
    }

    /* ---------------------------------------------------------------------- */
    /*                       Swap Output Accuracy Tests                       */
    /* ---------------------------------------------------------------------- */

    /// @notice Test swap output accuracy for balanced stable pool
    /// @dev The actual swap output is determined by the pair's stable swap math,
    ///      not the CamelotV2Service return value (which uses constant product formulas).
    ///      We verify the actual token balance change matches getAmountOut.
    function test_swapOutput_balancedPool() public {
        _initializeStablePool();
        _enableStableSwap(stablePair);

        uint256 swapAmount = 100e18;
        stableTokenA.mint(address(this), swapAmount);
        stableTokenA.approve(address(camelotV2Router), swapAmount);

        uint256 balanceBBefore = stableTokenB.balanceOf(address(this));

        uint256 expectedOut = stablePair.getAmountOut(swapAmount, address(stableTokenA));

        // Execute swap - note: CamelotV2Service._swap returns a value calculated with
        // constant product math, but the actual swap uses the pair's stable swap math.
        // We verify correctness by checking actual balance change.
        CamelotV2Service._swap(
            camelotV2Router,
            stablePair,
            swapAmount,
            stableTokenA,
            stableTokenB,
            address(0)
        );

        uint256 balanceBAfter = stableTokenB.balanceOf(address(this));
        uint256 actualReceived = balanceBAfter - balanceBBefore;

        // The actual balance change should be close to getAmountOut
        // Note: There may be small differences due to protocol fees being extracted during swap
        assertGt(actualReceived, 0, "Should receive tokens from swap");
        // Allow small tolerance for protocol fee extraction
        assertGt(actualReceived, expectedOut * 95 / 100, "Actual received should be close to expected");
        assertLe(actualReceived, expectedOut, "Should not receive more than expected");
    }

    /// @notice Test that stable swap has lower slippage than constant product
    function test_swapOutput_lowerSlippage() public {
        _initializeStablePool();

        uint256 swapAmount = 500e18; // 5% of liquidity - significant enough to show slippage difference

        // Get output in constant product mode
        uint256 outputConstantProduct = stablePair.getAmountOut(swapAmount, address(stableTokenA));

        _enableStableSwap(stablePair);

        // Get output in stable mode
        uint256 outputStable = stablePair.getAmountOut(swapAmount, address(stableTokenA));

        // Calculate slippage for each (ignoring fees for comparison)
        uint256 idealOutput = swapAmount * (FEE_DENOMINATOR - DEFAULT_FEE) / FEE_DENOMINATOR;

        uint256 slippageConstantProduct = idealOutput - outputConstantProduct;
        uint256 slippageStable = idealOutput - outputStable;

        // Stable swap should have significantly lower slippage
        assertLt(slippageStable, slippageConstantProduct, "Stable swap should have lower slippage");
    }

    /// @notice Test swap output with mixed decimals
    /// @dev Verifies actual token balance change is correct for tokens with different decimals
    function test_swapOutput_mixedDecimals() public {
        _initializeMixedDecimalPool();
        _enableStableSwap(mixedDecimalPair);

        uint256 swapAmount = 100e6; // 100 tokens with 6 decimals
        stableToken6Dec.mint(address(this), swapAmount);
        stableToken6Dec.approve(address(camelotV2Router), swapAmount);

        uint256 expectedOut = mixedDecimalPair.getAmountOut(swapAmount, address(stableToken6Dec));
        uint256 balanceBefore = stableToken8Dec.balanceOf(address(this));

        CamelotV2Service._swap(
            camelotV2Router,
            mixedDecimalPair,
            swapAmount,
            stableToken6Dec,
            stableToken8Dec,
            address(0)
        );

        uint256 balanceAfter = stableToken8Dec.balanceOf(address(this));
        uint256 actualReceived = balanceAfter - balanceBefore;

        // Verify output is reasonable and positive
        assertGt(actualReceived, 0, "Mixed decimal swap should produce output");
        // The stable swap math normalizes to 18 decimals internally, so output scaling is correct
        // Allow tolerance for protocol fee extraction
        assertGt(actualReceived, expectedOut * 95 / 100, "Actual received should be close to expected");
        assertLe(actualReceived, expectedOut, "Should not receive more than expected");
    }

    /// @notice Test bidirectional swaps maintain consistency
    /// @dev Asserts on actual balance deltas rather than _swap() return values
    function test_swapOutput_bidirectional() public {
        _initializeStablePool();
        _enableStableSwap(stablePair);

        uint256 swapAmount = 100e18;

        // Swap A -> B — measure balance delta
        stableTokenA.mint(address(this), swapAmount);
        stableTokenA.approve(address(camelotV2Router), swapAmount);

        uint256 balBBefore = stableTokenB.balanceOf(address(this));

        CamelotV2Service._swap(
            camelotV2Router,
            stablePair,
            swapAmount,
            stableTokenA,
            stableTokenB,
            address(0)
        );

        uint256 receivedB = stableTokenB.balanceOf(address(this)) - balBBefore;

        // Swap B -> A with the actual received amount
        stableTokenB.approve(address(camelotV2Router), receivedB);

        uint256 balABefore = stableTokenA.balanceOf(address(this));

        CamelotV2Service._swap(
            camelotV2Router,
            stablePair,
            receivedB,
            stableTokenB,
            stableTokenA,
            address(0)
        );

        uint256 receivedA = stableTokenA.balanceOf(address(this)) - balABefore;

        // Round trip should lose approximately 2x fee
        uint256 expectedLoss = swapAmount * 2 * DEFAULT_FEE / FEE_DENOMINATOR;

        // Should get back roughly input minus fees
        assertGt(receivedA, swapAmount - expectedLoss * 2, "Round trip loss should be reasonable");
        assertLt(receivedA, swapAmount, "Round trip should not be profitable");
    }

    /* ---------------------------------------------------------------------- */
    /*                       Invariant Fuzz Tests                             */
    /* ---------------------------------------------------------------------- */

    /// @notice Fuzz test for K preservation across random swaps
    function testFuzz_kPreservation(uint256 swapAmount) public {
        _initializeStablePool();
        _enableStableSwap(stablePair);

        // Bound swap amount to reasonable range (0.1% to 20% of liquidity)
        swapAmount = bound(swapAmount, 10e18, 2000e18);

        (uint112 reserve0Before, uint112 reserve1Before,,) = stablePair.getReserves();
        uint256 kBefore = _calculateK(reserve0Before, reserve1Before, stableTokenA.decimals(), stableTokenB.decimals());

        stableTokenA.mint(address(this), swapAmount);
        stableTokenA.approve(address(camelotV2Router), swapAmount);

        CamelotV2Service._swap(
            camelotV2Router,
            stablePair,
            swapAmount,
            stableTokenA,
            stableTokenB,
            address(0)
        );

        (uint112 reserve0After, uint112 reserve1After,,) = stablePair.getReserves();
        uint256 kAfter = _calculateK(reserve0After, reserve1After, stableTokenA.decimals(), stableTokenB.decimals());

        assertGe(kAfter, kBefore, "K should be preserved or increased");
    }

    /// @notice Fuzz test for swap output validity
    /// @dev Verifies actual token balance change is correct (not the service return value)
    function testFuzz_swapOutput_valid(uint256 swapAmount) public {
        _initializeStablePool();
        _enableStableSwap(stablePair);

        // Bound to reasonable range
        swapAmount = bound(swapAmount, 1e15, 1000e18);

        stableTokenA.mint(address(this), swapAmount);
        stableTokenA.approve(address(camelotV2Router), swapAmount);

        uint256 expectedOut = stablePair.getAmountOut(swapAmount, address(stableTokenA));
        uint256 balanceBefore = stableTokenB.balanceOf(address(this));

        CamelotV2Service._swap(
            camelotV2Router,
            stablePair,
            swapAmount,
            stableTokenA,
            stableTokenB,
            address(0)
        );

        uint256 balanceAfter = stableTokenB.balanceOf(address(this));
        uint256 actualReceived = balanceAfter - balanceBefore;

        // Verify actual received amount (accounting for protocol fee extraction)
        assertGt(actualReceived, 0, "Output should be positive");
        assertGt(actualReceived, expectedOut * 95 / 100, "Actual received should be close to expected");
        assertLe(actualReceived, expectedOut, "Should not receive more than expected");
    }

    /// @notice Fuzz test for Newton-Raphson convergence with varying inputs
    /// @dev Uses reasonable reserve bounds to avoid precision issues in stable swap math
    function testFuzz_newtonRaphson_convergence(uint256 swapAmount, uint256 reserve0, uint256 reserve1) public {
        // Bound reserves to reasonable range - stable swap needs sufficient precision
        // Use minimum 1000 tokens (1000e18) to ensure stable math precision
        reserve0 = bound(reserve0, 1000e18, 100000e18);
        reserve1 = bound(reserve1, 1000e18, 100000e18);

        // Bound swap to be reasonable relative to reserves - max 30% to avoid extreme slippage
        uint256 minReserve = reserve0 < reserve1 ? reserve0 : reserve1;
        swapAmount = bound(swapAmount, 1e16, minReserve * 30 / 100);

        // Setup fresh pool with specific reserves
        ERC20PermitMintableStub tokenA = new ERC20PermitMintableStub("FuzzA", "FUZA", 18, address(this), 0);
        ERC20PermitMintableStub tokenB = new ERC20PermitMintableStub("FuzzB", "FUZB", 18, address(this), 0);

        ICamelotPair fuzzPair = ICamelotPair(camelotV2Factory.createPair(address(tokenA), address(tokenB)));

        tokenA.mint(address(this), reserve0);
        tokenA.approve(address(camelotV2Router), reserve0);
        tokenB.mint(address(this), reserve1);
        tokenB.approve(address(camelotV2Router), reserve1);

        CamelotV2Service._deposit(camelotV2Router, tokenA, tokenB, reserve0, reserve1);

        // Enable stable swap
        (uint112 r0, uint112 r1,,) = fuzzPair.getReserves();
        vm.prank(address(this));
        CamelotPair(address(fuzzPair)).setStableSwap(true, r0, r1);

        // Mint and swap
        tokenA.mint(address(this), swapAmount);
        tokenA.approve(address(camelotV2Router), swapAmount);

        // Should not revert - Newton-Raphson should converge
        uint256 balanceBefore = tokenB.balanceOf(address(this));

        CamelotV2Service._swap(
            camelotV2Router,
            fuzzPair,
            swapAmount,
            tokenA,
            tokenB,
            address(0)
        );

        uint256 balanceAfter = tokenB.balanceOf(address(this));
        uint256 output = balanceAfter - balanceBefore;

        assertGt(output, 0, "Newton-Raphson should converge and produce output");
    }

    /// @notice Fuzz test for stable swap vs constant product comparison
    function testFuzz_stableSwap_betterThanConstantProduct(uint256 swapAmount) public {
        // Use balanced pool for fair comparison
        _initializeStablePool();

        // Bound to 0.1% to 10% of liquidity
        swapAmount = bound(swapAmount, 10e18, 1000e18);

        // Get constant product output
        uint256 outputCP = stablePair.getAmountOut(swapAmount, address(stableTokenA));

        // Enable stable swap and get output
        _enableStableSwap(stablePair);
        uint256 outputStable = stablePair.getAmountOut(swapAmount, address(stableTokenA));

        // Stable swap should always give equal or better output for balanced pools
        assertGe(outputStable, outputCP, "Stable swap should give equal or better output for balanced pools");
    }

    /* ---------------------------------------------------------------------- */
    /*                            Edge Case Tests                             */
    /* ---------------------------------------------------------------------- */

    /// @notice Test stable swap with very small amounts
    /// @dev Asserts on actual balance delta rather than _swap() return value
    function test_stableSwap_verySmallAmount() public {
        _initializeStablePool();
        _enableStableSwap(stablePair);

        uint256 swapAmount = 1e12; // 0.000001 tokens
        stableTokenA.mint(address(this), swapAmount);
        stableTokenA.approve(address(camelotV2Router), swapAmount);

        uint256 balBefore = stableTokenB.balanceOf(address(this));

        // Should not revert - convergence should succeed even for tiny amounts
        CamelotV2Service._swap(
            camelotV2Router,
            stablePair,
            swapAmount,
            stableTokenA,
            stableTokenB,
            address(0)
        );

        uint256 received = stableTokenB.balanceOf(address(this)) - balBefore;
        // Output might be very small or zero due to rounding at this scale,
        // but the swap itself should not revert
        assertGe(received, 0, "Very small swap should not revert");
    }

    /// @notice Test stable swap approaching reserve limits
    /// @dev Asserts on actual balance delta rather than _swap() return value
    function test_stableSwap_nearReserveLimit() public {
        _initializeStablePool();
        _enableStableSwap(stablePair);

        (uint112 reserve0,,,) = stablePair.getReserves();

        // Swap 80% of reserve (approaching but not exceeding limit)
        uint256 swapAmount = uint256(reserve0) * 80 / 100;
        stableTokenA.mint(address(this), swapAmount);
        stableTokenA.approve(address(camelotV2Router), swapAmount);

        uint256 balBefore = stableTokenB.balanceOf(address(this));

        CamelotV2Service._swap(
            camelotV2Router,
            stablePair,
            swapAmount,
            stableTokenA,
            stableTokenB,
            address(0)
        );

        uint256 received = stableTokenB.balanceOf(address(this)) - balBefore;
        assertGt(received, 0, "Large swap should still produce output");

        // Verify reserves are still positive
        (uint112 r0After, uint112 r1After,,) = stablePair.getReserves();
        assertGt(r0After, 0, "Reserve0 should remain positive");
        assertGt(r1After, 0, "Reserve1 should remain positive");
    }

    /// @notice Test that pair type can be made immutable
    function test_stableSwap_immutableFlag() public {
        _initializeStablePool();
        _enableStableSwap(stablePair);

        // Set pair type as immutable
        vm.prank(address(this));
        CamelotPair(address(stablePair)).setPairTypeImmutable();

        assertTrue(CamelotPair(address(stablePair)).pairTypeImmutable(), "Pair type should be immutable");

        // Attempting to change stable swap should fail
        (uint112 reserve0, uint112 reserve1,,) = stablePair.getReserves();

        vm.expectRevert("CamelotPair: immutable");
        vm.prank(address(this));
        CamelotPair(address(stablePair)).setStableSwap(false, reserve0, reserve1);
    }

    /// @notice Test multiple sequential swaps
    /// @dev Asserts on actual balance deltas rather than _swap() return values
    function test_stableSwap_multipleSequentialSwaps() public {
        _initializeStablePool();
        _enableStableSwap(stablePair);

        // Perform multiple swaps back and forth
        for (uint256 i = 0; i < 5; i++) {
            uint256 swapAmount = 50e18;

            // Swap A -> B — measure balance delta
            stableTokenA.mint(address(this), swapAmount);
            stableTokenA.approve(address(camelotV2Router), swapAmount);

            uint256 balBBefore = stableTokenB.balanceOf(address(this));

            CamelotV2Service._swap(
                camelotV2Router,
                stablePair,
                swapAmount,
                stableTokenA,
                stableTokenB,
                address(0)
            );

            uint256 receivedB = stableTokenB.balanceOf(address(this)) - balBBefore;
            assertGt(receivedB, 0, "Swap A->B should produce output");

            // Swap B -> A — use actual received amount
            stableTokenB.approve(address(camelotV2Router), receivedB);

            uint256 balABefore = stableTokenA.balanceOf(address(this));

            CamelotV2Service._swap(
                camelotV2Router,
                stablePair,
                receivedB,
                stableTokenB,
                stableTokenA,
                address(0)
            );

            uint256 receivedA = stableTokenA.balanceOf(address(this)) - balABefore;
            assertGt(receivedA, 0, "Swap B->A should produce output");
        }

        // Verify pool is still healthy
        (uint112 r0, uint112 r1,,) = stablePair.getReserves();
        assertGt(r0, 0, "Reserve0 should be positive after multiple swaps");
        assertGt(r1, 0, "Reserve1 should be positive after multiple swaps");
    }

    /* ---------------------------------------------------------------------- */
    /*                           Helper Functions                             */
    /* ---------------------------------------------------------------------- */

    /// @notice Calculate K using the cubic invariant formula
    function _calculateK(uint256 balance0, uint256 balance1, uint8 decimals0, uint8 decimals1)
        internal
        pure
        returns (uint256)
    {
        uint256 precisionMultiplier0 = 10 ** uint256(decimals0);
        uint256 precisionMultiplier1 = 10 ** uint256(decimals1);

        uint256 x = balance0 * 1e18 / precisionMultiplier0;
        uint256 y = balance1 * 1e18 / precisionMultiplier1;

        uint256 a = (x * y) / 1e18;
        uint256 b = (x * x / 1e18) + (y * y / 1e18);

        return (a * b) / 1e18;
    }
}
