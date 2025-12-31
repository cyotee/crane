// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {TestBase_ConstProdUtils} from "./TestBase_ConstProdUtils.sol";
import {ConstProdUtils} from "contracts/crane/utils/math/ConstProdUtils.sol";
import {ICamelotPair} from "contracts/crane/interfaces/protocols/dexes/camelot/v2/ICamelotPair.sol";
import {IUniswapV2Pair} from "contracts/crane/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Pair.sol";
import {IERC20MintBurn} from "contracts/crane/interfaces/IERC20MintBurn.sol";
import {betterconsole as console} from "contracts/crane/utils/vm/foundry/tools/betterconsole.sol";

/**
 * @title Test_ConstProdUtils_quoteDepositWithFee
 * @dev Comprehensive test suite for _quoteDepositWithFee() function
 * Tests both Camelot V2 (configurable fees) and Uniswap V2 (fee on/off) scenarios
 */
contract Test_ConstProdUtils_quoteDepositWithFee is TestBase_ConstProdUtils {
    // Test parameters
    uint256 constant TEST_AMOUNT_A = 1000e18;
    uint256 constant TEST_AMOUNT_B = 1000e18;
    uint256 constant SMALL_AMOUNT_A = 100e18;
    uint256 constant SMALL_AMOUNT_B = 100e18;

    // Fee configuration constants
    uint256 constant CAMELOT_MIN_FEE = 10; // 0.1%
    uint256 constant CAMELOT_MAX_FEE = 2000; // 2%
    uint256 constant CAMELOT_DEFAULT_FEE = 300; // 0.3%
    uint256 constant CAMELOT_MIN_OWNER_FEE = 100; // 1%
    uint256 constant CAMELOT_MAX_OWNER_FEE = 10000; // 100%
    uint256 constant CAMELOT_DEFAULT_OWNER_FEE = 1000; // 10%

    function setUp() public override {
        super.setUp();
        console.log("Test_ConstProdUtils_quoteDepositWithFee setup complete");
    }

    // ============================================================================
    // CAMELOT V2 TESTS - Configurable Fees
    // ============================================================================

    function test_quoteDepositWithFee_Camelot_balancedPool_defaultFees() public {
        // vm.skip(true);
        _testCamelotQuoteDepositWithFee(
            camelotBalancedPair,
            camelotBalancedTokenA,
            camelotBalancedTokenB,
            TEST_AMOUNT_A,
            TEST_AMOUNT_B,
            CAMELOT_DEFAULT_FEE,
            CAMELOT_DEFAULT_OWNER_FEE,
            "balancedPool_defaultFees"
        );
    }

    function test_quoteDepositWithFee_Camelot_balancedPool_minFees() public {
        // vm.skip(true);
        _testCamelotQuoteDepositWithFee(
            camelotBalancedPair,
            camelotBalancedTokenA,
            camelotBalancedTokenB,
            TEST_AMOUNT_A,
            TEST_AMOUNT_B,
            CAMELOT_MIN_FEE,
            CAMELOT_MIN_OWNER_FEE,
            "balancedPool_minFees"
        );
    }

    function test_quoteDepositWithFee_Camelot_balancedPool_maxFees() public {
        // vm.skip(true);
        _testCamelotQuoteDepositWithFee(
            camelotBalancedPair,
            camelotBalancedTokenA,
            camelotBalancedTokenB,
            TEST_AMOUNT_A,
            TEST_AMOUNT_B,
            CAMELOT_MAX_FEE,
            CAMELOT_MAX_OWNER_FEE,
            "balancedPool_maxFees"
        );
    }

    function test_quoteDepositWithFee_Camelot_unbalancedPool_defaultFees() public {
        // vm.skip(true);
        _testCamelotQuoteDepositWithFee(
            camelotUnbalancedPair,
            camelotUnbalancedTokenA,
            camelotUnbalancedTokenB,
            UNBALANCED_TEST_AMOUNT,
            UNBALANCED_TEST_AMOUNT,
            CAMELOT_DEFAULT_FEE,
            CAMELOT_DEFAULT_OWNER_FEE,
            "unbalancedPool_defaultFees"
        );
    }

    function test_quoteDepositWithFee_Camelot_unbalancedPool_minFees() public {
        // vm.skip(true);
        _testCamelotQuoteDepositWithFee(
            camelotUnbalancedPair,
            camelotUnbalancedTokenA,
            camelotUnbalancedTokenB,
            UNBALANCED_TEST_AMOUNT,
            UNBALANCED_TEST_AMOUNT,
            CAMELOT_MIN_FEE,
            CAMELOT_MIN_OWNER_FEE,
            "unbalancedPool_minFees"
        );
    }

    function test_quoteDepositWithFee_Camelot_unbalancedPool_maxFees() public {
        // vm.skip(true);
        _testCamelotQuoteDepositWithFee(
            camelotUnbalancedPair,
            camelotUnbalancedTokenA,
            camelotUnbalancedTokenB,
            UNBALANCED_TEST_AMOUNT,
            UNBALANCED_TEST_AMOUNT,
            CAMELOT_MAX_FEE,
            CAMELOT_MAX_OWNER_FEE,
            "unbalancedPool_maxFees"
        );
    }

    function test_quoteDepositWithFee_Camelot_extremeUnbalancedPool_defaultFees() public {
        // vm.skip(true);
        _testCamelotQuoteDepositWithFee(
            camelotExtremeUnbalancedPair,
            camelotExtremeTokenA,
            camelotExtremeTokenB,
            EXTREME_UNBALANCED_TEST_AMOUNT,
            EXTREME_UNBALANCED_TEST_AMOUNT,
            CAMELOT_DEFAULT_FEE,
            CAMELOT_DEFAULT_OWNER_FEE,
            "extremeUnbalancedPool_defaultFees"
        );
    }

    function test_quoteDepositWithFee_Camelot_extremeUnbalancedPool_minFees() public {
        // vm.skip(true);
        _testCamelotQuoteDepositWithFee(
            camelotExtremeUnbalancedPair,
            camelotExtremeTokenA,
            camelotExtremeTokenB,
            EXTREME_UNBALANCED_TEST_AMOUNT,
            EXTREME_UNBALANCED_TEST_AMOUNT,
            CAMELOT_MIN_FEE,
            CAMELOT_MIN_OWNER_FEE,
            "extremeUnbalancedPool_minFees"
        );
    }

    function test_quoteDepositWithFee_Camelot_extremeUnbalancedPool_maxFees() public {
        // vm.skip(true);
        _testCamelotQuoteDepositWithFee(
            camelotExtremeUnbalancedPair,
            camelotExtremeTokenA,
            camelotExtremeTokenB,
            EXTREME_UNBALANCED_TEST_AMOUNT,
            EXTREME_UNBALANCED_TEST_AMOUNT,
            CAMELOT_MAX_FEE,
            CAMELOT_MAX_OWNER_FEE,
            "extremeUnbalancedPool_maxFees"
        );
    }

    // ============================================================================
    // UNISWAP V2 TESTS - Fee On/Off
    // ============================================================================

    function test_quoteDepositWithFee_Uniswap_balancedPool_feesDisabled() public {
        _setupUniswapFees(false);
        _testUniswapQuoteDepositWithFee(
            uniswapBalancedPair,
            uniswapBalancedTokenA,
            uniswapBalancedTokenB,
            TEST_AMOUNT_A,
            TEST_AMOUNT_B,
            false,
            "balancedPool_feesDisabled"
        );
    }

    function test_quoteDepositWithFee_Uniswap_balancedPool_feesEnabled() public {
        _setupUniswapFees(true);
        _testUniswapQuoteDepositWithFee(
            uniswapBalancedPair,
            uniswapBalancedTokenA,
            uniswapBalancedTokenB,
            TEST_AMOUNT_A,
            TEST_AMOUNT_B,
            true,
            "balancedPool_feesEnabled"
        );
    }

    function test_quoteDepositWithFee_Uniswap_unbalancedPool_feesDisabled() public {
        _setupUniswapFees(false);
        _testUniswapQuoteDepositWithFee(
            uniswapUnbalancedPair,
            uniswapUnbalancedTokenA,
            uniswapUnbalancedTokenB,
            UNBALANCED_TEST_AMOUNT,
            UNBALANCED_TEST_AMOUNT,
            false,
            "unbalancedPool_feesDisabled"
        );
    }

    function test_quoteDepositWithFee_Uniswap_unbalancedPool_feesEnabled() public {
        _setupUniswapFees(true);
        _testUniswapQuoteDepositWithFee(
            uniswapUnbalancedPair,
            uniswapUnbalancedTokenA,
            uniswapUnbalancedTokenB,
            UNBALANCED_TEST_AMOUNT,
            UNBALANCED_TEST_AMOUNT,
            true,
            "unbalancedPool_feesEnabled"
        );
    }

    function test_quoteDepositWithFee_Uniswap_extremeUnbalancedPool_feesDisabled() public {
        _setupUniswapFees(false);
        _testUniswapQuoteDepositWithFee(
            uniswapExtremeUnbalancedPair,
            uniswapExtremeTokenA,
            uniswapExtremeTokenB,
            EXTREME_UNBALANCED_TEST_AMOUNT,
            EXTREME_UNBALANCED_TEST_AMOUNT,
            false,
            "extremeUnbalancedPool_feesDisabled"
        );
    }

    function test_quoteDepositWithFee_Uniswap_extremeUnbalancedPool_feesEnabled() public {
        _setupUniswapFees(true);
        _testUniswapQuoteDepositWithFee(
            uniswapExtremeUnbalancedPair,
            uniswapExtremeTokenA,
            uniswapExtremeTokenB,
            EXTREME_UNBALANCED_TEST_AMOUNT,
            EXTREME_UNBALANCED_TEST_AMOUNT,
            true,
            "extremeUnbalancedPool_feesEnabled"
        );
    }

    // ============================================================================
    // EDGE CASE TESTS
    // ============================================================================

    function test_quoteDepositWithFee_Camelot_zeroAmounts() public {
        // Test that zero amounts return zero LP tokens (expected behavior)
        uint256 lpTokens = ConstProdUtils._quoteDepositWithFee(
            0,
            0,
            camelotBalancedPair.totalSupply(),
            uint256(10000000000000000000000), // reserveA
            uint256(10000000000000000000000), // reserveB
            camelotBalancedPair.kLast(),
            camV2Factory().ownerFeeShare(),
            true
        );

        assertEq(lpTokens, 0, "Zero amounts should return zero LP tokens");
    }

    function test_quoteDepositWithFee_Uniswap_zeroAmounts() public {
        _setupUniswapFees(false);
        // Test that zero amounts return zero LP tokens (expected behavior)
        uint256 lpTokens = ConstProdUtils._quoteDepositWithFee(
            0,
            0,
            uniswapBalancedPair.totalSupply(),
            uint256(10000000000000000000000), // reserveA
            uint256(10000000000000000000000), // reserveB
            uniswapBalancedPair.kLast(),
            0, // ownerFeeShare (0 for Uniswap)
            false // feeOn
        );

        assertEq(lpTokens, 0, "Zero amounts should return zero LP tokens");
    }

    function test_quoteDepositWithFee_Camelot_verySmallAmounts() public {
        // Test very small amounts - should return some LP tokens
        uint256 lpTokens = ConstProdUtils._quoteDepositWithFee(
            1,
            1,
            camelotBalancedPair.totalSupply(),
            uint256(10000000000000000000000), // reserveA
            uint256(10000000000000000000000), // reserveB
            camelotBalancedPair.kLast(),
            camV2Factory().ownerFeeShare(),
            true
        );

        assertTrue(lpTokens > 0, "Very small amounts should still produce LP tokens");

        // Test that half amounts (0.5) return 0 (expected behavior for very small amounts)
        uint256 lpTokensHalf = ConstProdUtils._quoteDepositWithFee(
            0,
            0,
            camelotBalancedPair.totalSupply(),
            uint256(10000000000000000000000), // reserveA
            uint256(10000000000000000000000), // reserveB
            camelotBalancedPair.kLast(),
            camV2Factory().ownerFeeShare(),
            true
        );

        assertEq(lpTokensHalf, 0, "Zero amounts should return zero LP tokens");
    }

    function test_quoteDepositWithFee_Uniswap_verySmallAmounts() public {
        _setupUniswapFees(false);
        // Test very small amounts - should return some LP tokens
        uint256 lpTokens = ConstProdUtils._quoteDepositWithFee(
            1,
            1,
            uniswapBalancedPair.totalSupply(),
            uint256(10000000000000000000000), // reserveA
            uint256(10000000000000000000000), // reserveB
            uniswapBalancedPair.kLast(),
            0, // ownerFeeShare (0 for Uniswap)
            false // feeOn
        );

        assertTrue(lpTokens > 0, "Very small amounts should still produce LP tokens");

        // Test that half amounts (0.5) return 0 (expected behavior for very small amounts)
        uint256 lpTokensHalf = ConstProdUtils._quoteDepositWithFee(
            0,
            0,
            uniswapBalancedPair.totalSupply(),
            uint256(10000000000000000000000), // reserveA
            uint256(10000000000000000000000), // reserveB
            uniswapBalancedPair.kLast(),
            0, // ownerFeeShare (0 for Uniswap)
            false // feeOn
        );

        assertEq(lpTokensHalf, 0, "Zero amounts should return zero LP tokens");
    }

    // ============================================================================
    // HELPER FUNCTIONS
    // ============================================================================

    struct CamelotTestData {
        ICamelotPair pair;
        IERC20MintBurn tokenA;
        IERC20MintBurn tokenB;
        uint256 amountA;
        uint256 amountB;
        uint256 swapFee;
        uint256 ownerFeeShare;
        string testName;
        uint112 reserveA;
        uint112 reserveB;
        uint16 token0FeePercent;
        uint16 token1FeePercent;
        uint256 lpTotalSupply;
        uint256 kLast;
        uint256 actualOwnerFeeShare;
        uint256 quotedLpTokens;
        uint256 actualAmountA;
        uint256 actualAmountB;
        uint256 actualLpTokens;
        uint256 balanceBefore;
        uint256 balanceAfter;
    }

    function _testCamelotQuoteDepositWithFee(
        ICamelotPair pair,
        IERC20MintBurn tokenA,
        IERC20MintBurn tokenB,
        uint256 amountA,
        uint256 amountB,
        uint256 swapFee,
        uint256 ownerFeeShare,
        string memory testName
    ) internal {
        console.log("=== Testing Camelot V2:", testName, "===");

        CamelotTestData memory data;
        data.pair = pair;
        data.tokenA = tokenA;
        data.tokenB = tokenB;
        data.amountA = amountA;
        data.amountB = amountB;
        data.swapFee = swapFee;
        data.ownerFeeShare = ownerFeeShare;
        data.testName = testName;

        // Configure Camelot fees
        _configureCamelotFees(data.pair, data.swapFee, data.ownerFeeShare);

        // Get current reserves and fee configuration
        (data.reserveA, data.reserveB, data.token0FeePercent, data.token1FeePercent) = data.pair.getReserves();
        console.log("Initial reserves - A:", data.reserveA, "B:", data.reserveB);
        console.log("Fee configuration - token0Fee:", data.token0FeePercent, "token1Fee:", data.token1FeePercent);

        // Get additional parameters needed for the function
        data.lpTotalSupply = data.pair.totalSupply();
        data.kLast = data.pair.kLast();
        data.actualOwnerFeeShare = camV2Factory().ownerFeeShare();

        // Test the quote function
        data.quotedLpTokens = ConstProdUtils._quoteDepositWithFee(
            data.amountA,
            data.amountB,
            data.lpTotalSupply,
            uint256(data.reserveA),
            uint256(data.reserveB),
            data.kLast,
            data.actualOwnerFeeShare,
            true
        );

        console.log("Quote result - LP tokens:", data.quotedLpTokens);

        // EXECUTION VALIDATION - Execute actual deposit operation via direct mint
        data.balanceBefore = data.pair.balanceOf(address(this));
        data.tokenA.mint(address(this), data.amountA);
        data.tokenB.mint(address(this), data.amountB);
        data.tokenA.transfer(address(data.pair), data.amountA);
        data.tokenB.transfer(address(data.pair), data.amountB);
        data.actualLpTokens = data.pair.mint(address(this));

        // Validate that quote matches execution exactly
        assertTrue(data.quotedLpTokens > 0, "Quoted LP tokens should be positive");
        assertTrue(data.actualLpTokens > 0, "Actual LP tokens should be positive");
        assertEq(data.quotedLpTokens, data.actualLpTokens, "Quote should exactly match actual LP tokens");

        console.log("Camelot test passed:", data.testName);
    }

    struct UniswapTestData {
        IUniswapV2Pair pair;
        IERC20MintBurn tokenA;
        IERC20MintBurn tokenB;
        uint256 amountA;
        uint256 amountB;
        bool feesEnabled;
        string testName;
        uint112 reserveA;
        uint112 reserveB;
        uint256 lpTotalSupply;
        uint256 kLast;
        uint256 lpTokens;
        uint256 lpTokens2;
    }

    function _testUniswapQuoteDepositWithFee(
        IUniswapV2Pair pair,
        IERC20MintBurn tokenA,
        IERC20MintBurn tokenB,
        uint256 amountA,
        uint256 amountB,
        bool feesEnabled,
        string memory testName
    ) internal {
        console.log("=== Testing Uniswap V2:", testName, "===");

        UniswapTestData memory data;
        data.pair = pair;
        data.tokenA = tokenA;
        data.tokenB = tokenB;
        data.amountA = amountA;
        data.amountB = amountB;
        data.feesEnabled = feesEnabled;
        data.testName = testName;

        // Get current reserves
        (data.reserveA, data.reserveB,) = data.pair.getReserves();
        console.log("Initial reserves - A:", data.reserveA, "B:", data.reserveB);

        // Check fee status
        bool feeOn = uniswapV2Factory().feeTo() != address(0);
        console.log("Fee status - enabled:", feeOn, "expected:", data.feesEnabled);

        // Get additional parameters needed for the function
        data.lpTotalSupply = data.pair.totalSupply();
        data.kLast = data.pair.kLast();

        // Test the quote function
        uint256 quotedLpTokens = ConstProdUtils._quoteDepositWithFee(
            data.amountA,
            data.amountB,
            data.lpTotalSupply,
            uint256(data.reserveA),
            uint256(data.reserveB),
            data.kLast,
            0, // ownerFeeShare (0 for Uniswap)
            data.feesEnabled // feeOn
        );

        console.log("Quote result - LP tokens:", quotedLpTokens);

        // EXECUTION VALIDATION - Execute actual deposit operation
        uint256 balanceBefore = data.pair.balanceOf(address(this));

        // Mint tokens and approve for deposit
        data.tokenA.mint(address(this), data.amountA);
        data.tokenB.mint(address(this), data.amountB);
        data.tokenA.approve(address(uniswapV2Router()), data.amountA);
        data.tokenB.approve(address(uniswapV2Router()), data.amountB);

        // Execute actual deposit
        uniswapV2Router()
            .addLiquidity(
                address(data.tokenA),
                address(data.tokenB),
                data.amountA,
                data.amountB,
                1, // minAmountA
                1, // minAmountB
                address(this),
                block.timestamp
            );

        uint256 balanceAfter = data.pair.balanceOf(address(this));
        uint256 actualLpTokens = balanceAfter - balanceBefore;

        console.log("Actual LP tokens received:", actualLpTokens);

        // Validate that quote matches execution (within 1 wei tolerance for precision)
        assertTrue(quotedLpTokens > 0, "Quoted LP tokens should be positive");
        assertTrue(actualLpTokens > 0, "Actual LP tokens should be positive");
        assertEq(quotedLpTokens, actualLpTokens, "Quote should exactly match actual LP tokens");

        // Test with different amounts to verify consistency
        if (data.amountA > 0 && data.amountB > 0) {
            data.lpTokens2 = ConstProdUtils._quoteDepositWithFee(
                data.amountA / 2,
                data.amountB / 2,
                data.lpTotalSupply,
                uint256(data.reserveA),
                uint256(data.reserveB),
                data.kLast,
                0, // ownerFeeShare (0 for Uniswap)
                data.feesEnabled
            );

            assertTrue(data.lpTokens2 > 0, "Half amount should still produce LP tokens");
        }

        console.log("Uniswap test passed:", data.testName);
    }

    function _configureCamelotFees(ICamelotPair pair, uint256 swapFee, uint256 ownerFeeShare) internal {
        // Set swap fee for both tokens (using the same fee for both)
        pair.setFeePercent(uint16(swapFee), uint16(swapFee));

        // Note: ownerFeeShare is a global setting that would need to be set on the factory
        // For now, we'll use the default value from the factory
        console.log("Configured Camelot fees - swapFee:", swapFee, "ownerFeeShare:", ownerFeeShare);

        // Generate trading activity to create protocol fees
        _generateCamelotTradingActivity(pair, IERC20MintBurn(pair.token0()), IERC20MintBurn(pair.token1()), 100); // 1% of reserves
    }

    function _setupUniswapFees(bool enable) internal {
        if (enable) {
            // Enable fees by setting feeTo to a non-zero address
            vm.prank(uniswapV2Factory().feeToSetter());
            uniswapV2Factory().setFeeTo(address(0x1234567890123456789012345678901234567890));

            // Generate trading activity to create protocol fees
            _generateTradingActivity(uniswapBalancedPair, uniswapBalancedTokenA, uniswapBalancedTokenB, 100); // 1% of reserves
        } else {
            // Disable fees by setting feeTo to zero
            vm.prank(uniswapV2Factory().feeToSetter());
            uniswapV2Factory().setFeeTo(address(0));
        }

        console.log("Uniswap fees", enable ? "enabled" : "disabled");
    }

    /**
     * @dev Generate trading activity to create protocol fees
     * @param pair The Uniswap V2 pair to trade on
     * @param tokenA First token in the pair
     * @param tokenB Second token in the pair
     * @param swapPercentage Percentage of reserves to swap (100 = 1%, 500 = 5%)
     */
    function _generateTradingActivity(
        IUniswapV2Pair pair,
        IERC20MintBurn tokenA,
        IERC20MintBurn tokenB,
        uint256 swapPercentage // e.g., 100 = 1%, 500 = 5%
    ) internal {
        // Get current reserves
        (uint112 reserveA, uint112 reserveB,) = pair.getReserves();

        // Calculate swap amounts as percentage of reserves
        uint256 swapAmountA = (reserveA * swapPercentage) / 10000; // 10000 = 100%
        uint256 swapAmountB = (reserveB * swapPercentage) / 10000;

        console.log("Generating trading activity:");
        console.log("  ReserveA:", reserveA);
        console.log("  ReserveB:", reserveB);
        console.log("  SwapPercentage:", swapPercentage);
        console.log("  SwapAmountA:", swapAmountA);
        console.log("  SwapAmountB:", swapAmountB);

        // Mint tokens
        tokenA.mint(address(this), swapAmountA);
        tokenB.mint(address(this), swapAmountB);

        tokenA.approve(address(uniswapV2Router()), swapAmountA);
        tokenB.approve(address(uniswapV2Router()), swapAmountB);

        // First swap: A -> B
        address[] memory pathAB = new address[](2);
        pathAB[0] = address(tokenA);
        pathAB[1] = address(tokenB);

        uint256[] memory amountsAB = uniswapV2Router()
            .swapExactTokensForTokens(
                swapAmountA,
                1, // minAmountOut
                pathAB,
                address(this),
                block.timestamp
            );

        console.log("  First swap A->B: swapped", swapAmountA, "received", amountsAB[1]);

        // Second swap: B -> A (using what we actually received)
        uint256 receivedB = amountsAB[1];
        tokenB.approve(address(uniswapV2Router()), receivedB);

        address[] memory pathBA = new address[](2);
        pathBA[0] = address(tokenB);
        pathBA[1] = address(tokenA);

        uint256[] memory amountsBA = uniswapV2Router()
            .swapExactTokensForTokens(
                receivedB,
                1, // minAmountOut
                pathBA,
                address(this),
                block.timestamp
            );

        console.log("  Second swap B->A: swapped", receivedB, "received", amountsBA[1]);
        console.log("  Trading activity complete");
    }

    /**
     * @dev Generate trading activity for Camelot pairs to create protocol fees
     * @param pair The Camelot pair to trade on
     * @param tokenA First token in the pair
     * @param tokenB Second token in the pair
     * @param swapPercentage Percentage of reserves to swap (100 = 1%, 500 = 5%)
     */
    function _generateCamelotTradingActivity(
        ICamelotPair pair,
        IERC20MintBurn tokenA,
        IERC20MintBurn tokenB,
        uint256 swapPercentage // e.g., 100 = 1%, 500 = 5%
    ) internal {
        // Get current reserves
        (uint112 reserveA, uint112 reserveB,,) = pair.getReserves();

        // Calculate swap amounts as percentage of reserves
        uint256 swapAmountA = (reserveA * swapPercentage) / 10000; // 10000 = 100%
        uint256 swapAmountB = (reserveB * swapPercentage) / 10000;

        console.log("Generating Camelot trading activity:");
        console.log("  ReserveA:", reserveA);
        console.log("  ReserveB:", reserveB);
        console.log("  SwapPercentage:", swapPercentage);
        console.log("  SwapAmountA:", swapAmountA);
        console.log("  SwapAmountB:", swapAmountB);

        // Mint tokens
        tokenA.mint(address(this), swapAmountA);
        tokenB.mint(address(this), swapAmountB);

        tokenA.approve(address(camV2Router()), swapAmountA);
        tokenB.approve(address(camV2Router()), swapAmountB);

        // First swap: A -> B
        address[] memory pathAB = new address[](2);
        pathAB[0] = address(tokenA);
        pathAB[1] = address(tokenB);

        camV2Router()
            .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                swapAmountA,
                1, // minAmountOut
                pathAB,
                address(this),
                address(0), // referrer
                block.timestamp
            );

        // Get the actual amount received (we need to check balance change)
        uint256 receivedB = tokenB.balanceOf(address(this));
        console.log("  First swap A->B: swapped", swapAmountA, "received", receivedB);

        // Second swap: B -> A (using what we actually received)
        tokenB.approve(address(camV2Router()), receivedB);

        address[] memory pathBA = new address[](2);
        pathBA[0] = address(tokenB);
        pathBA[1] = address(tokenA);

        camV2Router()
            .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                receivedB,
                1, // minAmountOut
                pathBA,
                address(this),
                address(0), // referrer
                block.timestamp
            );

        // Get the actual amount received
        uint256 receivedA = tokenA.balanceOf(address(this));

        console.log("  Second swap B->A: swapped", receivedB, "received", receivedA);
        console.log("  Camelot trading activity complete");
    }
}
