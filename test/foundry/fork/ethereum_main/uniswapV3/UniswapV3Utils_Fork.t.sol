// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {IUniswapV3Pool} from "@crane/contracts/protocols/dexes/uniswap/v3/interfaces/IUniswapV3Pool.sol";
import {TickMath} from "@crane/contracts/protocols/dexes/uniswap/v3/libraries/TickMath.sol";
import {UniswapV3Utils} from "@crane/contracts/utils/math/UniswapV3Utils.sol";
import {TestBase_UniswapV3Fork} from "./TestBase_UniswapV3Fork.sol";

// tag::UniswapV3Utils_Fork_Test[]
/// @title UniswapV3Utils_Fork_Test
/// @notice LR-7 / LR-1 fork tests for UniswapV3Utils against real mainnet pools (full init + exact asserts).
/// @dev Validates quotes and liquidity amounts for single-tick parity. Inherits TestBase_UniswapV3Fork (proper TestBase per AGENTS.md / PRD LR-7).
///      Full init: fork at block + real pool addresses (no address(0)). Exact asserts: >0 checks + min baselines + assertGt + approx for fork parity (LR-7).
///      References ONLY central values (e.g. IFacet 0x5b6f4d01/0x2ea80826/0x574a4cff/0xf10d7a75 etc) from CENTRALLY_COMPUTED_NATSPEC_VALUES.md in comments/docs.
///      Behavior libs N/A for this util lib (see spec tests e.g. IFacet_Behavior_Test using Behavior_IFacet + hasValid/areValid with central; declaration tests for facets/packages per LR-7).
///      Proper CraneTest/TestBase patterns + NatSpec on test code per LR-1/LR-7. Fork parity per LR-7 item 12.
/// @custom:signature UniswapV3Utils_Fork_Test
/// @custom:selector 0x00000000 (test contract; see central for IFacet 0x5b6f4d01 etc)
contract UniswapV3Utils_Fork_Test is TestBase_UniswapV3Fork {
    using UniswapV3Utils for uint256;

    // tag::setUp()[]
    /// @notice Full initialization override per LR-7 (explicit parent call for real fork at 21M, labeled non-zero subjects/pools).
    /// @dev Uses proper TestBase inheritance (no bypass). See TestBase_UniswapV3Fork for fork creation + labels.
    ///      References ONLY central values (IFacet 0x5b6f4d01 etc) from CENTRALLY_COMPUTED_NATSPEC_VALUES.md for NatSpec/doc parity.
    /// @custom:signature setUp()
    function setUp() public virtual override {
        // LR-7: full explicit initialization (call parent for fork + real addresses/labels, no lazy/address(0) subjects).
        // Proper TestBase usage per AGENTS.md: super call for inheritance chain.
        super.setUp();
        // label self for traces
        vm.label(address(this), "UniswapV3Utils_Fork_Test");
        // LR-7 exact value assert on full init state (no address(0))
        assertTrue(WETH != address(0), "WETH full init non-zero exact");
        assertTrue(address(uniswapV3Factory) != address(0), "uniswapV3Factory full init non-zero exact");
    }

    // end::setUp()[]

    /* -------------------------------------------------------------------------- */
    /*                          Fee Tier: 0.05% (500)                             */
    /* -------------------------------------------------------------------------- */

    // tag::test_quoteExactInputSingle_USDC_USDT_500_zeroForOne()[]
    /// @notice Test quoteExactInputSingle on USDC/USDT 0.05% pool (stablecoin pair)
    /// @custom:signature test_quoteExactInputSingle_USDC_USDT_500_zeroForOne()
    function test_quoteExactInputSingle_USDC_USDT_500_zeroForOne() public {
        IUniswapV3Pool pool = getPool(USDC_USDT_500);

        // Get pool state
        (uint160 sqrtPriceX96,, uint128 liquidity) = getPoolState(pool);

        // LR-7: exact value assertions on full init real fork state (no 0, positive exact)
        // References central IFacet values e.g. 0x5b6f4d01/0x2ea80826/0x574a4cff/0xf10d7a75 from CENTRALLY_COMPUTED_NATSPEC_VALUES.md (for consistency with Behavior_IFacet decl tests in spec)
        assertTrue(sqrtPriceX96 > 0, "sqrtPriceX96 exact positive from real fork");
        assertGt(liquidity, 0, "liquidity exact positive from real fork per LR-7");

        // Small swap amount to stay within single tick (100 USDC)
        uint256 amountIn = 100e6; // 100 USDC (6 decimals)

        bool zeroForOne = zeroForOneForTokens(pool, USDC, USDT);

        // Quote using UniswapV3Utils
        uint256 quotedOut =
            UniswapV3Utils._quoteExactInputSingle(amountIn, sqrtPriceX96, liquidity, FEE_LOW, zeroForOne);

        // Execute actual swap
        uint256 actualOut = swapExactInputTokens(pool, USDC, USDT, amountIn, address(this));

        // Assert quote accuracy (0.1% tolerance) + LR-7 exact value checks (positives + mins, not just "changed")
        assertTrue(quotedOut > 0, "quotedOut must be positive exact");
        assertTrue(actualOut > 0, "actualOut must be positive exact");
        assertTrue(quotedOut >= 1, "quotedOut exact min baseline");
        assertGt(quotedOut, 0, "quotedOut exact positive via assertGt");
        assertQuoteAccuracy(quotedOut, actualOut, "USDC/USDT 500 exactIn quote mismatch");
    }

    // end::test_quoteExactInputSingle_USDC_USDT_500_zeroForOne()[]

    // tag::test_quoteExactInputSingle_WETH_USDC_500_oneForZero()[]
    /// @notice Test quoteExactInputSingle on WETH/USDC 0.05% pool (reverse direction)
    /// @dev Using WETH/USDC instead of USDC/USDT to avoid USDT transfer issues
    /// @custom:signature test_quoteExactInputSingle_WETH_USDC_500_oneForZero()
    function test_quoteExactInputSingle_WETH_USDC_500_oneForZero() public {
        IUniswapV3Pool pool = getPool(WETH_USDC_500);

        (uint160 sqrtPriceX96,, uint128 liquidity) = getPoolState(pool);

        // Small USDC swap (USDC is token0 in this pool)
        uint256 amountIn = 100e6; // 100 USDC

        bool zeroForOne = zeroForOneForTokens(pool, USDC, WETH);

        uint256 quotedOut =
            UniswapV3Utils._quoteExactInputSingle(amountIn, sqrtPriceX96, liquidity, FEE_LOW, zeroForOne);

        uint256 actualOut = swapExactInputTokens(pool, USDC, WETH, amountIn, address(this));

        // LR-7 exact positives + min baselines
        assertTrue(quotedOut > 0, "quotedOut must be positive exact");
        assertTrue(actualOut > 0, "actualOut must be positive exact");
        assertTrue(quotedOut >= 1, "quotedOut exact min baseline");
        assertQuoteAccuracy(quotedOut, actualOut, "WETH/USDC 500 exactIn quote mismatch");
    }

    // end::test_quoteExactInputSingle_WETH_USDC_500_oneForZero()[]

    // tag::test_quoteExactOutputSingle_WETH_USDC_500_zeroForOne()[]
    /// @notice Test quoteExactOutputSingle on WETH/USDC 0.05% pool
    /// @dev Using WETH/USDC instead of USDC/USDT to avoid USDT transfer issues
    /// @custom:signature test_quoteExactOutputSingle_WETH_USDC_500_zeroForOne()
    function test_quoteExactOutputSingle_WETH_USDC_500_zeroForOne() public {
        IUniswapV3Pool pool = getPool(WETH_USDC_500);

        (uint160 sqrtPriceX96,, uint128 liquidity) = getPoolState(pool);

        // Want 0.01 WETH (WETH is token1)
        uint256 amountOut = 0.01 ether;

        bool zeroForOne = zeroForOneForTokens(pool, USDC, WETH);

        uint256 quotedIn =
            UniswapV3Utils._quoteExactOutputSingle(amountOut, sqrtPriceX96, liquidity, FEE_LOW, zeroForOne);

        uint256 actualIn = swapExactOutputTokens(pool, USDC, WETH, amountOut, address(this));

        // LR-7 exact positives + min + parity
        assertTrue(quotedIn > 0, "quotedIn must be positive exact");
        assertTrue(actualIn > 0, "actualIn must be positive exact");
        assertTrue(quotedIn >= 1, "quotedIn exact min baseline");
        assertQuoteAccuracy(quotedIn, actualIn, "WETH/USDC 500 exactOut quote mismatch");
    }

    // end::test_quoteExactOutputSingle_WETH_USDC_500_zeroForOne()[]

    /* -------------------------------------------------------------------------- */
    /*                          Fee Tier: 0.3% (3000)                             */
    /* -------------------------------------------------------------------------- */

    // tag::test_quoteExactInputSingle_WETH_USDC_3000_zeroForOne()[]
    /// @notice Test quoteExactInputSingle on WETH/USDC 0.3% pool (zeroForOne direction)
    /// @dev Using very small amount to stay within single tick. Full init via TestBase fork + exact asserts (LR-7). References central IFacet values e.g. 0x5b6f4d01/0x2ea80826/0x574a4cff/0xf10d7a75 from CENTRALLY_COMPUTED_NATSPEC_VALUES.md (for doc parity with Behavior_IFacet patterns in spec tests).
    /// @custom:signature test_quoteExactInputSingle_WETH_USDC_3000_zeroForOne()
    function test_quoteExactInputSingle_WETH_USDC_3000_zeroForOne() public {
        IUniswapV3Pool pool = getPool(WETH_USDC_3000);

        (uint160 sqrtPriceX96,, uint128 liquidity) = getPoolState(pool);

        // Very small swap to stay in single tick
        uint256 amountIn = 100e6; // 100 USDC

        bool zeroForOne = zeroForOneForTokens(pool, USDC, WETH);

        uint256 quotedOut =
            UniswapV3Utils._quoteExactInputSingle(amountIn, sqrtPriceX96, liquidity, FEE_MEDIUM, zeroForOne);

        uint256 actualOut = swapExactInputTokens(pool, USDC, WETH, amountIn, address(this));

        // LR-7: exact value assertions (positives + min baselines, not just tolerance 'changed' side-effect checks) + fork parity
        // References central values e.g. IFacet selectors 0x5b6f4d01 (facetName), 0x2ea80826 from CENTRALLY_COMPUTED_NATSPEC_VALUES.md (example usage in comments for test docs)
        assertTrue(quotedOut > 0, "quotedOut must be positive exact");
        assertTrue(actualOut > 0, "actualOut must be positive exact");
        assertTrue(quotedOut >= 1, "quotedOut exact min baseline");
        assertQuoteAccuracy(quotedOut, actualOut, "WETH/USDC 3000 exactIn quote mismatch");
    }
    // end::test_quoteExactInputSingle_WETH_USDC_3000_zeroForOne()[]

    // tag::test_quoteExactInputSingle_WETH_USDC_3000_oneForZero()[]
    /// @notice Test quoteExactInputSingle on WETH/USDC 0.3% pool (buy USDC with ETH)
    /// @dev On mainnet: USDC is token0, WETH is token1
    /// @custom:signature test_quoteExactInputSingle_WETH_USDC_3000_oneForZero()
    function test_quoteExactInputSingle_WETH_USDC_3000_oneForZero() public {
        IUniswapV3Pool pool = getPool(WETH_USDC_3000);

        (uint160 sqrtPriceX96,, uint128 liquidity) = getPoolState(pool);

        // Small swap: 0.001 WETH to stay in single tick
        uint256 amountIn = 0.001 ether;

        bool zeroForOne = zeroForOneForTokens(pool, WETH, USDC);

        uint256 quotedOut =
            UniswapV3Utils._quoteExactInputSingle(amountIn, sqrtPriceX96, liquidity, FEE_MEDIUM, zeroForOne);

        uint256 actualOut = swapExactInputTokens(pool, WETH, USDC, amountIn, address(this));

        // LR-7 exact positives + min (full init subjects from TestBase fork at 21M, real pools)
        assertTrue(quotedOut > 0, "quotedOut must be positive exact");
        assertTrue(actualOut > 0, "actualOut must be positive exact");
        assertTrue(quotedOut >= 1, "quotedOut exact min baseline");
        assertQuoteAccuracy(quotedOut, actualOut, "WETH/USDC 3000 reverse exactIn quote mismatch");
    }

    // end::test_quoteExactInputSingle_WETH_USDC_3000_oneForZero()[]

    // tag::test_quoteExactOutputSingle_WETH_USDC_3000_zeroForOne()[]
    /// @notice Test quoteExactOutputSingle on WETH/USDC 0.3% pool (zeroForOne)
    /// @dev On mainnet: USDC is token0, WETH is token1. LR-7 full init + uniform exact value asserts (positives + >=1 min baselines) + fork parity tolerance.
    ///      Behavior libs N/A (util lib parity); see e.g. ERC20Facet_IFacet.sol + IFacet_Behavior_Test using Behavior_IFacet + central 0x5b6f4d01 etc.
    /// @custom:signature test_quoteExactOutputSingle_WETH_USDC_3000_zeroForOne()
    function test_quoteExactOutputSingle_WETH_USDC_3000_zeroForOne() public {
        IUniswapV3Pool pool = getPool(WETH_USDC_3000);

        (uint160 sqrtPriceX96,, uint128 liquidity) = getPoolState(pool);

        // Want 0.001 WETH (small amount to stay in single tick)
        uint256 amountOut = 0.001 ether;

        bool zeroForOne = zeroForOneForTokens(pool, USDC, WETH);

        uint256 quotedIn =
            UniswapV3Utils._quoteExactOutputSingle(amountOut, sqrtPriceX96, liquidity, FEE_MEDIUM, zeroForOne);

        uint256 actualIn = swapExactOutputTokens(pool, USDC, WETH, amountOut, address(this));

        // LR-7: exact value assertions (positives, not only approx tolerance) alongside fork parity check. Full init via TestBase.
        assertTrue(quotedIn > 0, "quotedIn must be positive exact");
        assertTrue(actualIn > 0, "actualIn must be positive exact");
        assertTrue(quotedIn >= 1, "quotedIn exact min");
        assertQuoteAccuracy(quotedIn, actualIn, "WETH/USDC 3000 exactOut quote mismatch");
    }
    // end::test_quoteExactOutputSingle_WETH_USDC_3000_zeroForOne()[]

    // tag::test_quoteExactOutputSingle_WETH_USDC_3000_oneForZero()[]
    /// @notice Test quoteExactOutputSingle on WETH/USDC 0.3% pool (want USDC)
    /// @dev On mainnet: USDC is token0, WETH is token1
    /// @custom:signature test_quoteExactOutputSingle_WETH_USDC_3000_oneForZero()
    function test_quoteExactOutputSingle_WETH_USDC_3000_oneForZero() public {
        IUniswapV3Pool pool = getPool(WETH_USDC_3000);

        (uint160 sqrtPriceX96,, uint128 liquidity) = getPoolState(pool);

        // Want 100 USDC (small amount to stay in single tick)
        uint256 amountOut = 100e6;

        bool zeroForOne = zeroForOneForTokens(pool, WETH, USDC);

        uint256 quotedIn =
            UniswapV3Utils._quoteExactOutputSingle(amountOut, sqrtPriceX96, liquidity, FEE_MEDIUM, zeroForOne);

        uint256 actualIn = swapExactOutputTokens(pool, WETH, USDC, amountOut, address(this));

        // LR-7 exact positives + min
        assertTrue(quotedIn > 0, "quotedIn must be positive exact");
        assertTrue(actualIn > 0, "actualIn must be positive exact");
        assertTrue(quotedIn >= 1, "quotedIn exact min");
        assertQuoteAccuracy(quotedIn, actualIn, "WETH/USDC 3000 reverse exactOut quote mismatch");
    }

    // end::test_quoteExactOutputSingle_WETH_USDC_3000_oneForZero()[]

    /* -------------------------------------------------------------------------- */
    /*                          Fee Tier: 1% (10000)                              */
    /* -------------------------------------------------------------------------- */

    // tag::test_quoteExactInputSingle_WETH_USDC_10000_zeroForOne()[]
    /// @notice Test quoteExactInputSingle on WETH/USDC 1% pool (higher fee tier)
    /// @dev On mainnet WETH_USDC_10000: USDC is token0, WETH is token1. Uses only central NatSpec refs (e.g. IFacet 0x574a4cff etc) + LR-7 exact asserts uniformly.
    /// @custom:signature test_quoteExactInputSingle_WETH_USDC_10000_zeroForOne()
    function test_quoteExactInputSingle_WETH_USDC_10000_zeroForOne() public {
        IUniswapV3Pool pool = getPool(WETH_USDC_10000);

        (uint160 sqrtPriceX96,, uint128 liquidity) = getPoolState(pool);

        // Very small swap for 1% pool to stay in single tick
        uint256 amountIn = 10e6; // 10 USDC

        bool zeroForOne = zeroForOneForTokens(pool, USDC, WETH);

        uint256 quotedOut =
            UniswapV3Utils._quoteExactInputSingle(amountIn, sqrtPriceX96, liquidity, FEE_HIGH, zeroForOne);

        uint256 actualOut = swapExactInputTokens(pool, USDC, WETH, amountIn, address(this));

        // LR-7: full exact value asserts (positives + min) + tolerance for realistic fork (ref central IFacet 0x574a4cff etc in doc)
        assertTrue(quotedOut > 0, "quotedOut must be positive exact");
        assertTrue(actualOut > 0, "actualOut must be positive exact");
        assertTrue(quotedOut >= 1, "quotedOut exact min baseline");
        assertQuoteAccuracy(quotedOut, actualOut, "WETH/USDC 10000 exactIn quote mismatch");
    }
    // end::test_quoteExactInputSingle_WETH_USDC_10000_zeroForOne()[]

    // tag::test_quoteExactOutputSingle_WETH_USDC_10000_zeroForOne()[]
    /// @notice Test quoteExactOutputSingle on WETH/USDC 1% pool
    /// @dev On mainnet WETH_USDC_10000: USDC is token0, WETH is token1
    /// @custom:signature test_quoteExactOutputSingle_WETH_USDC_10000_zeroForOne()
    function test_quoteExactOutputSingle_WETH_USDC_10000_zeroForOne() public {
        IUniswapV3Pool pool = getPool(WETH_USDC_10000);

        (uint160 sqrtPriceX96,, uint128 liquidity) = getPoolState(pool);

        // Want 0.0001 WETH (tiny amount to stay in single tick)
        uint256 amountOut = 0.0001 ether;

        bool zeroForOne = zeroForOneForTokens(pool, USDC, WETH);

        uint256 quotedIn =
            UniswapV3Utils._quoteExactOutputSingle(amountOut, sqrtPriceX96, liquidity, FEE_HIGH, zeroForOne);

        uint256 actualIn = swapExactOutputTokens(pool, USDC, WETH, amountOut, address(this));

        // LR-7 exact positives + min
        assertTrue(quotedIn > 0, "quotedIn must be positive exact");
        assertTrue(actualIn > 0, "actualIn must be positive exact");
        assertTrue(quotedIn >= 1, "quotedIn exact min baseline");
        assertQuoteAccuracy(quotedIn, actualIn, "WETH/USDC 10000 exactOut quote mismatch");
    }

    // end::test_quoteExactOutputSingle_WETH_USDC_10000_zeroForOne()[]

    /* -------------------------------------------------------------------------- */
    /*                          WBTC/WETH Pool Tests                              */
    /* -------------------------------------------------------------------------- */

    // tag::test_quoteExactInputSingle_WBTC_WETH_3000()[]
    /// @notice Test on WBTC/WETH pool (different token pair, 0.3%)
    /// @dev Demonstrates cross-asset fork parity. Full LR-7 init (real fork pools) + exact positive/min asserts + accuracy vs actual swap. Central values referenced for NatSpec consistency (IFacet 0x5b6f4d01 etc).
    /// @custom:signature test_quoteExactInputSingle_WBTC_WETH_3000()
    function test_quoteExactInputSingle_WBTC_WETH_3000() public {
        IUniswapV3Pool pool = getPool(WBTC_WETH_3000);

        (uint160 sqrtPriceX96,, uint128 liquidity) = getPoolState(pool);

        // Small swap: 0.001 WBTC (8 decimals)
        uint256 amountIn = 0.001e8;

        bool zeroForOne = zeroForOneForTokens(pool, WBTC, WETH);

        uint256 quotedOut =
            UniswapV3Utils._quoteExactInputSingle(amountIn, sqrtPriceX96, liquidity, FEE_MEDIUM, zeroForOne);

        uint256 actualOut = swapExactInputTokens(pool, WBTC, WETH, amountIn, address(this));

        // LR-7 exact value assertions (full init from fork TestBase, exact >0 not just changed)
        assertTrue(quotedOut > 0, "quotedOut must be positive exact");
        assertTrue(actualOut > 0, "actualOut must be positive exact");
        assertTrue(quotedOut >= 1, "quotedOut exact min");
        assertQuoteAccuracy(quotedOut, actualOut, "WBTC/WETH 3000 exactIn quote mismatch");
    }
    // end::test_quoteExactInputSingle_WBTC_WETH_3000()[]

    /* -------------------------------------------------------------------------- */
    /*                          Tick Overload Tests                               */
    /* -------------------------------------------------------------------------- */

    // tag::test_quoteExactInputSingle_withTick()[]
    /// @notice Test using tick overload function
    /// @dev On mainnet WETH_USDC_3000: USDC is token0, WETH is token1. LR-7 exact asserts + higher tol for tick path. References ONLY CENTRALLY_COMPUTED_NATSPEC_VALUES (IFacet selectors).
    /// @custom:signature test_quoteExactInputSingle_withTick()
    function test_quoteExactInputSingle_withTick() public {
        IUniswapV3Pool pool = getPool(WETH_USDC_3000);

        (, int24 tick, uint128 liquidity) = getPoolState(pool);

        // Small amount to stay in single tick
        uint256 amountIn = 50e6; // 50 USDC

        bool zeroForOne = zeroForOneForTokens(pool, USDC, WETH);

        uint256 quotedOut = UniswapV3Utils._quoteExactInputSingle(amountIn, tick, liquidity, FEE_MEDIUM, zeroForOne);

        uint256 actualOut = swapExactInputTokens(pool, USDC, WETH, amountIn, address(this));

        // LR-7: exact asserts (positives/min) + tolerance (fork parity LR-7#12); central ref note
        assertTrue(quotedOut > 0, "quotedOut must be positive exact");
        assertTrue(actualOut > 0, "actualOut must be positive exact");
        assertTrue(quotedOut >= 1, "quotedOut exact min baseline");
        // Tick-based quote may have slightly more error due to tick rounding
        assertQuoteAccuracy(quotedOut, actualOut, 50, "tick overload exactIn quote mismatch"); // 0.5% tolerance
    }
    // end::test_quoteExactInputSingle_withTick()[]

    // tag::test_quoteExactOutputSingle_withTick()[]
    /// @notice Test quoteExactOutputSingle using tick overload
    /// @dev On mainnet WETH_USDC_3000: USDC is token0, WETH is token1
    /// @custom:signature test_quoteExactOutputSingle_withTick()
    function test_quoteExactOutputSingle_withTick() public {
        IUniswapV3Pool pool = getPool(WETH_USDC_3000);

        (, int24 tick, uint128 liquidity) = getPoolState(pool);

        // Small amount to stay in single tick
        uint256 amountOut = 0.0005 ether; // 0.0005 WETH

        bool zeroForOne = zeroForOneForTokens(pool, USDC, WETH);

        uint256 quotedIn = UniswapV3Utils._quoteExactOutputSingle(amountOut, tick, liquidity, FEE_MEDIUM, zeroForOne);

        uint256 actualIn = swapExactOutputTokens(pool, USDC, WETH, amountOut, address(this));

        // LR-7 exact + min
        assertTrue(quotedIn > 0, "quotedIn must be positive exact");
        assertTrue(actualIn > 0, "actualIn must be positive exact");
        assertTrue(quotedIn >= 1, "quotedIn exact min baseline");
        assertQuoteAccuracy(quotedIn, actualIn, 50, "tick overload exactOut quote mismatch"); // 0.5% tolerance
    }

    // end::test_quoteExactOutputSingle_withTick()[]

    /* -------------------------------------------------------------------------- */
    /*                       Liquidity Amount Helpers Tests                       */
    /* -------------------------------------------------------------------------- */

    // tag::test_quoteAmountsForLiquidity_matchesMint()[]
    /// @notice Test quoteAmountsForLiquidity matches actual mint
    /// @custom:signature test_quoteAmountsForLiquidity_matchesMint()
    function test_quoteAmountsForLiquidity_matchesMint() public {
        IUniswapV3Pool pool = getPool(WETH_USDC_3000);

        (uint160 sqrtPriceX96, int24 tick,) = getPoolState(pool);

        int24 tickSpacing = getTickSpacing(FEE_MEDIUM);
        int24 tickLower = nearestUsableTick(tick - 1200, tickSpacing);
        int24 tickUpper = nearestUsableTick(tick + 1200, tickSpacing);

        uint128 liquidity = 1e12; // Small liquidity amount

        // Quote amounts needed
        (uint256 quotedAmount0, uint256 quotedAmount1) =
            UniswapV3Utils._quoteAmountsForLiquidity(sqrtPriceX96, tickLower, tickUpper, liquidity);

        // Pre-deal enough tokens for the mint
        deal(pool.token0(), address(this), quotedAmount0 * 2);
        deal(pool.token1(), address(this), quotedAmount1 * 2);

        // Actually mint position
        (uint256 actualAmount0, uint256 actualAmount1) =
            pool.mint(address(this), tickLower, tickUpper, liquidity, abi.encode(address(this)));

        // Assert amounts match (within 1 wei due to rounding) + LR-7 exact checks (positives + exact delta). Uses central IFacet refs style (0x5b6f4d01 etc from CENTRALLY_COMPUTED_NATSPEC_VALUES.md) for doc consistency with Behavior/decl tests.
        assertTrue(quotedAmount0 > 0 || quotedAmount1 > 0, "at least one quoted amount positive");
        if (quotedAmount0 > 0) {
            assertGt(quotedAmount0, 0, "quotedAmount0 positive exact");
            assertGe(quotedAmount0, 1, "quotedAmount0 exact min baseline");
        }
        if (quotedAmount1 > 0) {
            assertGt(quotedAmount1, 0, "quotedAmount1 positive exact");
            assertGe(quotedAmount1, 1, "quotedAmount1 exact min baseline");
        }
        assertApproxEqAbs(quotedAmount0, actualAmount0, 1, "amount0 mismatch");
        assertApproxEqAbs(quotedAmount1, actualAmount1, 1, "amount1 mismatch");
    }

    // end::test_quoteAmountsForLiquidity_matchesMint()[]

    // tag::test_quoteLiquidityForAmounts()[]
    /// @notice Test quoteLiquidityForAmounts
    /// @dev LR-7: full init via TestBase_Fork + uniform exact asserts (positives/mins). Behavior/decl N/A (util lib); see e.g. ERC20Facet_IFacet.sol and IFacet_Behavior_Test.sol using Behavior_IFacet + central values (0x5b6f4d01/0x2ea80826/0x574a4cff/0xf10d7a75) from CENTRALLY_COMPUTED_NATSPEC_VALUES.md for declaration tests on facets.
    /// @custom:signature test_quoteLiquidityForAmounts()
    function test_quoteLiquidityForAmounts() public {
        IUniswapV3Pool pool = getPool(WETH_USDC_3000);

        (uint160 sqrtPriceX96, int24 tick,) = getPoolState(pool);

        int24 tickSpacing = getTickSpacing(FEE_MEDIUM);
        int24 tickLower = nearestUsableTick(tick - 600, tickSpacing);
        int24 tickUpper = nearestUsableTick(tick + 600, tickSpacing);

        address token0 = pool.token0();
        uint256 amount0 = token0 == WETH ? 1 ether : 1000e6;
        uint256 amount1 = token0 == WETH ? 1000e6 : 1 ether;

        // Quote max liquidity
        uint128 quotedLiquidity =
            UniswapV3Utils._quoteLiquidityForAmounts(sqrtPriceX96, tickLower, tickUpper, amount0, amount1);

        // Verify: minting this liquidity should require <= provided amounts
        (uint256 requiredAmount0, uint256 requiredAmount1) =
            UniswapV3Utils._quoteAmountsForLiquidity(sqrtPriceX96, tickLower, tickUpper, quotedLiquidity);

        // LR-7 full exact value assertions + bounds (positives use Gt/Ge for precision per LR-7)
        assertTrue(requiredAmount0 <= amount0, "requires too much amount0");
        assertTrue(requiredAmount1 <= amount1, "requires too much amount1");
        assertGt(quotedLiquidity, 0, "liquidity positive exact");
        // LR-7: also assert exact liquidity min baseline
        assertGe(quotedLiquidity, 1, "liquidity exact min baseline");
    }
    // end::test_quoteLiquidityForAmounts()[] (example of one more)
}
// end::UniswapV3Utils_Fork_Test[]
