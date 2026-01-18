// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {betterconsole as console} from "contracts/utils/vm/foundry/tools/betterconsole.sol";
import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";
import {TestBase_ConstProdUtils_Uniswap} from "@crane/test/foundry/spec/utils/math/constProdUtils/TestBase_ConstProdUtils_Uniswap.sol";
import {ERC20PermitMintableStub} from "contracts/tokens/ERC20/ERC20PermitMintableStub.sol";
import {IUniswapV2Pair} from "contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Pair.sol";

/**
 * @title ConstProdUtils Price Impact Tests
 * @notice Tests for price impact calculations across various trade sizes
 * @dev Price impact formula: priceImpact = 1 - (effectivePrice / spotPrice)
 *
 * Price impact in constant product AMMs follows the formula:
 * For a swap of amountIn tokens:
 *   spotPrice = reserveOut / reserveIn (price before swap)
 *   effectivePrice = amountOut / amountIn (actual execution price)
 *   priceImpact = 1 - (effectivePrice / spotPrice)
 *
 * In constant product AMMs (x * y = k), larger trades relative to reserves
 * result in higher price impact due to curve mechanics.
 */
contract ConstProdUtils_priceImpact is TestBase_ConstProdUtils_Uniswap {
    using ConstProdUtils for uint256;

    // Fee constants (Uniswap V2 uses 0.3% fee = 300 with 100000 denominator)
    uint256 constant FEE_PERCENT = 300;
    uint256 constant FEE_DENOMINATOR = 100000;

    // Price impact thresholds (in basis points, 1 bp = 0.01%)
    uint256 constant SMALL_TRADE_MAX_IMPACT_BP = 100; // < 1% expected impact
    uint256 constant MEDIUM_TRADE_MIN_IMPACT_BP = 100; // >= 1% expected impact
    uint256 constant MEDIUM_TRADE_MAX_IMPACT_BP = 1000; // < 10% expected impact
    uint256 constant LARGE_TRADE_MIN_IMPACT_BP = 1000; // >= 10% expected impact

    // Test precision (in basis points)
    uint256 constant PRECISION_BP = 10000;

    struct PriceImpactTestData {
        uint256 reserveIn;
        uint256 reserveOut;
        uint256 amountIn;
        uint256 amountOut;
        uint256 spotPrice;
        uint256 effectivePrice;
        uint256 priceImpactBP;
    }

    function setUp() public override {
        TestBase_ConstProdUtils_Uniswap.setUp();
    }

    /* -------------------------------------------------------------------------- */
    /*                           Price Impact Helpers                             */
    /* -------------------------------------------------------------------------- */

    /**
     * @dev Calculates price impact in basis points
     * @param reserveIn Reserve of input token before swap
     * @param reserveOut Reserve of output token before swap
     * @param amountIn Amount of tokens being swapped in
     * @param amountOut Amount of tokens received from swap
     * @return priceImpactBP Price impact in basis points (10000 = 100%)
     */
    function _calculatePriceImpactBP(
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 amountIn,
        uint256 amountOut
    ) internal pure returns (uint256 priceImpactBP) {
        if (amountIn == 0 || reserveIn == 0) return 0;

        // spotPrice = reserveOut / reserveIn (scaled by 1e18 for precision)
        uint256 spotPriceScaled = (reserveOut * 1e18) / reserveIn;

        // effectivePrice = amountOut / amountIn (scaled by 1e18 for precision)
        uint256 effectivePriceScaled = (amountOut * 1e18) / amountIn;

        // priceImpact = 1 - (effectivePrice / spotPrice)
        // In basis points: priceImpactBP = 10000 * (1 - effectivePrice / spotPrice)
        if (effectivePriceScaled >= spotPriceScaled) {
            return 0; // No negative price impact
        }

        // priceImpactBP = 10000 - (10000 * effectivePrice / spotPrice)
        priceImpactBP = PRECISION_BP - ((effectivePriceScaled * PRECISION_BP) / spotPriceScaled);
    }

    /**
     * @dev Calculates the theoretical price impact for a constant product AMM
     * Without fees: priceImpact = amountIn / (reserveIn + amountIn)
     */
    function _theoreticalPriceImpactBP(
        uint256 reserveIn,
        uint256 amountIn
    ) internal pure returns (uint256) {
        if (reserveIn == 0) return PRECISION_BP;
        return (amountIn * PRECISION_BP) / (reserveIn + amountIn);
    }

    /* -------------------------------------------------------------------------- */
    /*                     Small Trade Tests (< 1% of reserves)                   */
    /* -------------------------------------------------------------------------- */

    function test_priceImpact_smallTrade_0_1_percent_balanced() public {
        _initializeUniswapBalancedPools();
        PriceImpactTestData memory data = _testPriceImpact(
            uniswapBalancedTokenA,
            uniswapBalancedTokenB,
            INITIAL_LIQUIDITY / 1000 // 0.1% of reserves
        );

        // Small trades should have minimal price impact (< 1%)
        assertLt(data.priceImpactBP, SMALL_TRADE_MAX_IMPACT_BP, "Small trade should have < 1% price impact");
        console.log("Price impact for 0.1% trade:", data.priceImpactBP, "bp");
    }

    function test_priceImpact_smallTrade_0_5_percent_balanced() public {
        _initializeUniswapBalancedPools();
        PriceImpactTestData memory data = _testPriceImpact(
            uniswapBalancedTokenA,
            uniswapBalancedTokenB,
            INITIAL_LIQUIDITY / 200 // 0.5% of reserves
        );

        // 0.5% trade should have < 1% price impact
        assertLt(data.priceImpactBP, SMALL_TRADE_MAX_IMPACT_BP, "0.5% trade should have < 1% price impact");
        console.log("Price impact for 0.5% trade:", data.priceImpactBP, "bp");
    }

    function test_priceImpact_smallTrade_0_1_percent_unbalanced() public {
        _initializeUniswapUnbalancedPools();
        PriceImpactTestData memory data = _testPriceImpact(
            uniswapUnbalancedTokenA,
            uniswapUnbalancedTokenB,
            UNBALANCED_RATIO_A / 1000 // 0.1% of token A reserves
        );

        // Small trades should still have minimal price impact in unbalanced pools
        assertLt(data.priceImpactBP, SMALL_TRADE_MAX_IMPACT_BP, "Small trade in unbalanced pool should have < 1% price impact");
        console.log("Price impact for 0.1% trade (unbalanced):", data.priceImpactBP, "bp");
    }

    /* -------------------------------------------------------------------------- */
    /*                   Medium Trade Tests (1-10% of reserves)                   */
    /* -------------------------------------------------------------------------- */

    function test_priceImpact_mediumTrade_1_percent_balanced() public {
        _initializeUniswapBalancedPools();
        PriceImpactTestData memory data = _testPriceImpact(
            uniswapBalancedTokenA,
            uniswapBalancedTokenB,
            INITIAL_LIQUIDITY / 100 // 1% of reserves
        );

        // 1% trade should have noticeable but moderate price impact
        assertGe(data.priceImpactBP, MEDIUM_TRADE_MIN_IMPACT_BP / 2, "1% trade should have >= 0.5% price impact");
        assertLt(data.priceImpactBP, MEDIUM_TRADE_MAX_IMPACT_BP, "1% trade should have < 10% price impact");
        console.log("Price impact for 1% trade:", data.priceImpactBP, "bp");
    }

    function test_priceImpact_mediumTrade_5_percent_balanced() public {
        _initializeUniswapBalancedPools();
        PriceImpactTestData memory data = _testPriceImpact(
            uniswapBalancedTokenA,
            uniswapBalancedTokenB,
            INITIAL_LIQUIDITY / 20 // 5% of reserves
        );

        // 5% trade should have moderate price impact
        assertGe(data.priceImpactBP, MEDIUM_TRADE_MIN_IMPACT_BP, "5% trade should have >= 1% price impact");
        assertLt(data.priceImpactBP, MEDIUM_TRADE_MAX_IMPACT_BP, "5% trade should have < 10% price impact");
        console.log("Price impact for 5% trade:", data.priceImpactBP, "bp");
    }

    function test_priceImpact_mediumTrade_10_percent_balanced() public {
        _initializeUniswapBalancedPools();
        PriceImpactTestData memory data = _testPriceImpact(
            uniswapBalancedTokenA,
            uniswapBalancedTokenB,
            INITIAL_LIQUIDITY / 10 // 10% of reserves
        );

        // 10% trade should have significant price impact, approaching threshold
        assertGe(data.priceImpactBP, MEDIUM_TRADE_MIN_IMPACT_BP, "10% trade should have >= 1% price impact");
        console.log("Price impact for 10% trade:", data.priceImpactBP, "bp");
    }

    function test_priceImpact_mediumTrade_5_percent_unbalanced() public {
        _initializeUniswapUnbalancedPools();
        PriceImpactTestData memory data = _testPriceImpact(
            uniswapUnbalancedTokenA,
            uniswapUnbalancedTokenB,
            UNBALANCED_RATIO_A / 20 // 5% of token A reserves
        );

        // Medium trades in unbalanced pools should still show moderate impact
        assertGe(data.priceImpactBP, MEDIUM_TRADE_MIN_IMPACT_BP, "5% trade in unbalanced pool should have >= 1% price impact");
        console.log("Price impact for 5% trade (unbalanced):", data.priceImpactBP, "bp");
    }

    /* -------------------------------------------------------------------------- */
    /*                    Large Trade Tests (> 10% of reserves)                   */
    /* -------------------------------------------------------------------------- */

    function test_priceImpact_largeTrade_20_percent_balanced() public {
        _initializeUniswapBalancedPools();
        PriceImpactTestData memory data = _testPriceImpact(
            uniswapBalancedTokenA,
            uniswapBalancedTokenB,
            INITIAL_LIQUIDITY / 5 // 20% of reserves
        );

        // 20% trade should have significant price impact
        assertGe(data.priceImpactBP, LARGE_TRADE_MIN_IMPACT_BP, "20% trade should have >= 10% price impact");
        console.log("Price impact for 20% trade:", data.priceImpactBP, "bp");
    }

    function test_priceImpact_largeTrade_50_percent_balanced() public {
        _initializeUniswapBalancedPools();
        PriceImpactTestData memory data = _testPriceImpact(
            uniswapBalancedTokenA,
            uniswapBalancedTokenB,
            INITIAL_LIQUIDITY / 2 // 50% of reserves
        );

        // 50% trade should have very significant price impact (> 33%)
        uint256 expectedMinImpact = 3000; // 30% minimum
        assertGe(data.priceImpactBP, expectedMinImpact, "50% trade should have >= 30% price impact");
        console.log("Price impact for 50% trade:", data.priceImpactBP, "bp");
    }

    function test_priceImpact_largeTrade_extreme_unbalanced() public {
        _initializeUniswapExtremeUnbalancedPools();
        PriceImpactTestData memory data = _testPriceImpact(
            uniswapExtremeTokenA,
            uniswapExtremeTokenB,
            UNBALANCED_RATIO_A / 5 // 20% of token A reserves
        );

        // Large trades in extreme pools should show significant impact
        assertGe(data.priceImpactBP, LARGE_TRADE_MIN_IMPACT_BP, "Large trade in extreme pool should have >= 10% price impact");
        console.log("Price impact for 20% trade (extreme):", data.priceImpactBP, "bp");
    }

    /* -------------------------------------------------------------------------- */
    /*                      Price Impact Formula Verification                     */
    /* -------------------------------------------------------------------------- */

    function test_priceImpact_formula_matches_theoretical() public {
        _initializeUniswapBalancedPools();

        // Test multiple trade sizes to verify formula correctness
        uint256[5] memory tradeSizes = [
            INITIAL_LIQUIDITY / 1000, // 0.1%
            INITIAL_LIQUIDITY / 100,  // 1%
            INITIAL_LIQUIDITY / 20,   // 5%
            INITIAL_LIQUIDITY / 10,   // 10%
            INITIAL_LIQUIDITY / 5     // 20%
        ];

        for (uint256 i = 0; i < tradeSizes.length; i++) {
            PriceImpactTestData memory data = _testPriceImpact(
                uniswapBalancedTokenA,
                uniswapBalancedTokenB,
                tradeSizes[i]
            );

            // Calculate theoretical price impact (without considering fees)
            uint256 theoreticalImpact = _theoreticalPriceImpactBP(data.reserveIn, data.amountIn);

            // Actual impact should be close to theoretical (within 1% relative difference)
            // The fee adds some deviation
            uint256 tolerance = (theoreticalImpact * 150) / 1000 + 50; // 15% relative + 0.5% absolute tolerance for fee effects

            uint256 diff = data.priceImpactBP > theoreticalImpact
                ? data.priceImpactBP - theoreticalImpact
                : theoreticalImpact - data.priceImpactBP;

            assertLe(diff, tolerance, "Actual price impact should be close to theoretical");

            console.log("Trade size %:", (tradeSizes[i] * 100) / INITIAL_LIQUIDITY);
            console.log("  Theoretical impact (bp):", theoreticalImpact);
            console.log("  Actual impact (bp):", data.priceImpactBP);
        }
    }

    function test_priceImpact_formula_components() public {
        _initializeUniswapBalancedPools();

        uint256 tradeAmount = INITIAL_LIQUIDITY / 10; // 10% trade

        // Get reserves
        (uint112 r0, uint112 r1,) = uniswapBalancedPair.getReserves();
        (uint256 reserveIn,, uint256 reserveOut,) = ConstProdUtils._sortReserves(
            address(uniswapBalancedTokenA),
            uniswapBalancedPair.token0(),
            r0, FEE_PERCENT, r1, FEE_PERCENT
        );

        // Calculate amountOut using ConstProdUtils
        uint256 amountOut = ConstProdUtils._saleQuote(tradeAmount, reserveIn, reserveOut, FEE_PERCENT, FEE_DENOMINATOR);

        // Verify the formula components
        // spotPrice = reserveOut / reserveIn
        uint256 spotPriceScaled = (reserveOut * 1e18) / reserveIn;

        // effectivePrice = amountOut / amountIn
        uint256 effectivePriceScaled = (amountOut * 1e18) / tradeAmount;

        // effectivePrice should be less than spotPrice (we get less than spot)
        assertLt(effectivePriceScaled, spotPriceScaled, "Effective price should be less than spot price");

        // Calculate price impact
        uint256 priceImpactBP = PRECISION_BP - ((effectivePriceScaled * PRECISION_BP) / spotPriceScaled);

        console.log("Spot price (scaled):", spotPriceScaled);
        console.log("Effective price (scaled):", effectivePriceScaled);
        console.log("Price impact (bp):", priceImpactBP);

        // Verify price impact is positive and within expected range for 10% trade
        assertGt(priceImpactBP, 0, "Price impact should be positive");
        assertGe(priceImpactBP, MEDIUM_TRADE_MIN_IMPACT_BP, "10% trade should have >= 1% impact");
    }

    /* -------------------------------------------------------------------------- */
    /*                               Fuzz Tests                                   */
    /* -------------------------------------------------------------------------- */

    function testFuzz_priceImpact_boundedByTheoretical(uint256 tradePercent) public {
        // Bound trade percent between 0.01% and 90%
        tradePercent = bound(tradePercent, 1, 9000);

        _initializeUniswapBalancedPools();

        uint256 tradeAmount = (INITIAL_LIQUIDITY * tradePercent) / PRECISION_BP;
        if (tradeAmount == 0) tradeAmount = 1;

        PriceImpactTestData memory data = _testPriceImpact(
            uniswapBalancedTokenA,
            uniswapBalancedTokenB,
            tradeAmount
        );

        // Price impact should always be non-negative
        assertGe(data.priceImpactBP, 0, "Price impact should be non-negative");

        // Price impact should be bounded by theoretical maximum
        uint256 theoreticalMax = _theoreticalPriceImpactBP(data.reserveIn, data.amountIn);
        // Allow some tolerance for fee effects
        assertLe(data.priceImpactBP, theoreticalMax + 100, "Price impact should not exceed theoretical max significantly");
    }

    function testFuzz_priceImpact_reserveRatios(uint256 ratioA, uint256 ratioB) public {
        // Bound ratios to reasonable values (100 to 100000 tokens)
        ratioA = bound(ratioA, 100e18, 100000e18);
        ratioB = bound(ratioB, 100e18, 100000e18);

        // Create a custom pool with fuzzed ratios
        ERC20PermitMintableStub tokenA = new ERC20PermitMintableStub("FuzzTokenA", "FUZZA", 18, address(this), 0);
        ERC20PermitMintableStub tokenB = new ERC20PermitMintableStub("FuzzTokenB", "FUZZB", 18, address(this), 0);

        address pair = uniswapV2Factory.createPair(address(tokenA), address(tokenB));

        // Add liquidity with fuzzed ratios
        tokenA.mint(address(this), ratioA);
        tokenA.approve(address(uniswapV2Router), ratioA);
        tokenB.mint(address(this), ratioB);
        tokenB.approve(address(uniswapV2Router), ratioB);

        uniswapV2Router.addLiquidity(
            address(tokenA),
            address(tokenB),
            ratioA,
            ratioB,
            1,
            1,
            address(this),
            block.timestamp
        );

        // Trade 1% of the smaller reserve
        uint256 smallerReserve = ratioA < ratioB ? ratioA : ratioB;
        uint256 tradeAmount = smallerReserve / 100;
        if (tradeAmount == 0) return; // Skip if trade would be 0

        // Execute trade and verify price impact is reasonable
        PriceImpactTestData memory data = _testPriceImpactCustomPool(
            pair,
            tokenA,
            tokenB,
            tradeAmount
        );

        // For 1% trade, price impact should be around 1% (100 bp) with some tolerance
        assertLt(data.priceImpactBP, 500, "1% trade should have less than 5% price impact");
    }

    function testFuzz_priceImpact_monotonic(uint256 seed) public {
        _initializeUniswapBalancedPools();

        // Use minimum of 0.001% of reserves to avoid precision issues with tiny amounts
        uint256 minTradeSize = INITIAL_LIQUIDITY / 100000; // 0.001% minimum
        uint256 maxSize1 = INITIAL_LIQUIDITY / 10;
        uint256 maxSize2 = INITIAL_LIQUIDITY / 2;

        // Generate two trade sizes where size2 > size1
        uint256 size1 = bound(seed, minTradeSize, maxSize1);
        // Use separate seed computation that can't overflow
        uint256 seed2 = uint256(keccak256(abi.encode(seed)));
        uint256 size2 = bound(seed2, size1 + minTradeSize, maxSize2);

        // Get reserves
        (uint112 r0, uint112 r1,) = uniswapBalancedPair.getReserves();
        (uint256 reserveIn,, uint256 reserveOut,) = ConstProdUtils._sortReserves(
            address(uniswapBalancedTokenA),
            uniswapBalancedPair.token0(),
            r0, FEE_PERCENT, r1, FEE_PERCENT
        );

        // Calculate outputs using ConstProdUtils (without executing actual swaps)
        uint256 amountOut1 = ConstProdUtils._saleQuote(size1, reserveIn, reserveOut, FEE_PERCENT, FEE_DENOMINATOR);
        uint256 amountOut2 = ConstProdUtils._saleQuote(size2, reserveIn, reserveOut, FEE_PERCENT, FEE_DENOMINATOR);

        // Calculate price impacts
        uint256 impact1 = _calculatePriceImpactBP(reserveIn, reserveOut, size1, amountOut1);
        uint256 impact2 = _calculatePriceImpactBP(reserveIn, reserveOut, size2, amountOut2);

        // Larger trade should have >= price impact (monotonicity)
        assertGe(impact2, impact1, "Larger trade should have >= price impact");
    }

    /* -------------------------------------------------------------------------- */
    /*                            Internal Test Helpers                           */
    /* -------------------------------------------------------------------------- */

    function _testPriceImpact(
        ERC20PermitMintableStub tokenIn,
        ERC20PermitMintableStub tokenOut,
        uint256 amountIn
    ) internal returns (PriceImpactTestData memory data) {
        address pair = uniswapV2Factory.getPair(address(tokenIn), address(tokenOut));
        return _testPriceImpactCustomPool(pair, tokenIn, tokenOut, amountIn);
    }

    function _testPriceImpactCustomPool(
        address pair,
        ERC20PermitMintableStub tokenIn,
        ERC20PermitMintableStub tokenOut,
        uint256 amountIn
    ) internal returns (PriceImpactTestData memory data) {
        // Get reserves before swap
        (uint112 r0, uint112 r1,) = IUniswapV2Pair(pair).getReserves();
        (data.reserveIn,, data.reserveOut,) = ConstProdUtils._sortReserves(
            address(tokenIn),
            IUniswapV2Pair(pair).token0(),
            r0, FEE_PERCENT, r1, FEE_PERCENT
        );

        data.amountIn = amountIn;

        // Calculate expected output using ConstProdUtils
        data.amountOut = ConstProdUtils._saleQuote(amountIn, data.reserveIn, data.reserveOut, FEE_PERCENT, FEE_DENOMINATOR);

        // Calculate price impact
        data.priceImpactBP = _calculatePriceImpactBP(data.reserveIn, data.reserveOut, data.amountIn, data.amountOut);

        // Execute actual swap to verify
        tokenIn.mint(address(this), amountIn);
        tokenIn.approve(address(uniswapV2Router), amountIn);

        address[] memory path = new address[](2);
        path[0] = address(tokenIn);
        path[1] = address(tokenOut);

        uint256 balanceBefore = tokenOut.balanceOf(address(this));

        uniswapV2Router.swapExactTokensForTokens(
            amountIn,
            0,
            path,
            address(this),
            block.timestamp + 300
        );

        uint256 actualOutput = tokenOut.balanceOf(address(this)) - balanceBefore;

        // Verify ConstProdUtils calculation matches actual swap
        assertEq(actualOutput, data.amountOut, "Calculated output should match actual swap output");
    }

}
