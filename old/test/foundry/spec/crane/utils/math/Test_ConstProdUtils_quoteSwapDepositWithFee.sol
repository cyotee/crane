// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {betterconsole as console} from "contracts/crane/utils/vm/foundry/tools/betterconsole.sol";

using ConstProdUtils for uint256;

import {ConstProdUtils} from "contracts/crane/utils/math/ConstProdUtils.sol";
import {TestBase_ConstProdUtils} from "./TestBase_ConstProdUtils.sol";

import {IERC20MintBurn} from "contracts/crane/interfaces/IERC20MintBurn.sol";
import {IUniswapV2Pair} from "contracts/crane/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Pair.sol";
import {ICamelotPair} from "contracts/crane/interfaces/protocols/dexes/camelot/v2/ICamelotPair.sol";
import {ICamelotV2Router} from "contracts/crane/interfaces/protocols/dexes/camelot/v2/ICamelotV2Router.sol";
import {ICamelotFactory} from "contracts/crane/interfaces/protocols/dexes/camelot/v2/ICamelotFactory.sol";
import {IUniswapV2Router} from "contracts/crane/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Router.sol";

contract Test_ConstProdUtils_quoteSwapDepositWithFee is TestBase_ConstProdUtils {
    // ============================================================================
    // TEST CONSTANTS
    // ============================================================================

    uint256 constant TEST_AMOUNT_IN = 1000000; // 1M wei input amount
    uint256 constant UNISWAP_FEE_PERCENT = 300; // 0.3% fee (300/100000)
    uint256 constant UNISWAP_OWNER_FEE_SHARE = 16666; // 1/6 for Uniswap V2

    // ============================================================================
    // UNISWAP V2 TESTS - FEES DISABLED (6 tests: 3 pools × 2 directions)
    // ============================================================================

    function test_quoteSwapDepositWithFee_Uniswap_balancedPool_swapsTokenA_feesDisabled() public {
        console.log("=== Testing Uniswap V2: balancedPool_swapsTokenA_feesDisabled ===");
        _testSwapDepositWithFeeUniswap(uniswapBalancedPair, uniswapBalancedTokenA, uniswapBalancedTokenB, false);
        console.log("Uniswap balanced pool swaps TokenA fees disabled test passed");
    }

    function test_quoteSwapDepositWithFee_Uniswap_balancedPool_swapsTokenB_feesDisabled() public {
        console.log("=== Testing Uniswap V2: balancedPool_swapsTokenB_feesDisabled ===");
        _testSwapDepositWithFeeUniswap(uniswapBalancedPair, uniswapBalancedTokenB, uniswapBalancedTokenA, false);
        console.log("Uniswap balanced pool swaps TokenB fees disabled test passed");
    }

    function test_quoteSwapDepositWithFee_Uniswap_unbalancedPool_swapsTokenA_feesDisabled() public {
        console.log("=== Testing Uniswap V2: unbalancedPool_swapsTokenA_feesDisabled ===");
        _testSwapDepositWithFeeUniswap(uniswapUnbalancedPair, uniswapUnbalancedTokenA, uniswapUnbalancedTokenB, false);
        console.log("Uniswap unbalanced pool swaps TokenA fees disabled test passed");
    }

    function test_quoteSwapDepositWithFee_Uniswap_unbalancedPool_swapsTokenB_feesDisabled() public {
        console.log("=== Testing Uniswap V2: unbalancedPool_swapsTokenB_feesDisabled ===");
        _testSwapDepositWithFeeUniswap(uniswapUnbalancedPair, uniswapUnbalancedTokenB, uniswapUnbalancedTokenA, false);
        console.log("Uniswap unbalanced pool swaps TokenB fees disabled test passed");
    }

    function test_quoteSwapDepositWithFee_Uniswap_extremeUnbalancedPool_swapsTokenA_feesDisabled() public {
        console.log("=== Testing Uniswap V2: extremeUnbalancedPool_swapsTokenA_feesDisabled ===");
        _testSwapDepositWithFeeUniswap(uniswapExtremeUnbalancedPair, uniswapExtremeTokenA, uniswapExtremeTokenB, false);
        console.log("Uniswap extreme unbalanced pool swaps TokenA fees disabled test passed");
    }

    function test_quoteSwapDepositWithFee_Uniswap_extremeUnbalancedPool_swapsTokenB_feesDisabled() public {
        console.log("=== Testing Uniswap V2: extremeUnbalancedPool_swapsTokenB_feesDisabled ===");
        _testSwapDepositWithFeeUniswap(uniswapExtremeUnbalancedPair, uniswapExtremeTokenB, uniswapExtremeTokenA, false);
        console.log("Uniswap extreme unbalanced pool swaps TokenB fees disabled test passed");
    }

    // ============================================================================
    // UNISWAP V2 TESTS - FEES ENABLED (6 tests: 3 pools × 2 directions)
    // ============================================================================

    function test_quoteSwapDepositWithFee_Uniswap_balancedPool_swapsTokenA_feesEnabled() public {
        console.log("=== Testing Uniswap V2: balancedPool_swapsTokenA_feesEnabled ===");
        _testSwapDepositWithFeeUniswap(uniswapBalancedPair, uniswapBalancedTokenA, uniswapBalancedTokenB, true);
        console.log("Uniswap balanced pool swaps TokenA fees enabled test passed");
    }

    function test_quoteSwapDepositWithFee_Uniswap_balancedPool_swapsTokenB_feesEnabled() public {
        console.log("=== Testing Uniswap V2: balancedPool_swapsTokenB_feesEnabled ===");
        _testSwapDepositWithFeeUniswap(uniswapBalancedPair, uniswapBalancedTokenB, uniswapBalancedTokenA, true);
        console.log("Uniswap balanced pool swaps TokenB fees enabled test passed");
    }

    function test_quoteSwapDepositWithFee_Uniswap_unbalancedPool_swapsTokenA_feesEnabled() public {
        console.log("=== Testing Uniswap V2: unbalancedPool_swapsTokenA_feesEnabled ===");
        _testSwapDepositWithFeeUniswap(uniswapUnbalancedPair, uniswapUnbalancedTokenA, uniswapUnbalancedTokenB, true);
        console.log("Uniswap unbalanced pool swaps TokenA fees enabled test passed");
    }

    function test_quoteSwapDepositWithFee_Uniswap_unbalancedPool_swapsTokenB_feesEnabled() public {
        console.log("=== Testing Uniswap V2: unbalancedPool_swapsTokenB_feesEnabled ===");
        _testSwapDepositWithFeeUniswap(uniswapUnbalancedPair, uniswapUnbalancedTokenB, uniswapUnbalancedTokenA, true);
        console.log("Uniswap unbalanced pool swaps TokenB fees enabled test passed");
    }

    function test_quoteSwapDepositWithFee_Uniswap_extremeUnbalancedPool_swapsTokenA_feesEnabled() public {
        console.log("=== Testing Uniswap V2: extremeUnbalancedPool_swapsTokenA_feesEnabled ===");
        _testSwapDepositWithFeeUniswap(uniswapExtremeUnbalancedPair, uniswapExtremeTokenA, uniswapExtremeTokenB, true);
        console.log("Uniswap extreme unbalanced pool swaps TokenA fees enabled test passed");
    }

    function test_quoteSwapDepositWithFee_Uniswap_extremeUnbalancedPool_swapsTokenB_feesEnabled() public {
        console.log("=== Testing Uniswap V2: extremeUnbalancedPool_swapsTokenB_feesEnabled ===");
        _testSwapDepositWithFeeUniswap(uniswapExtremeUnbalancedPair, uniswapExtremeTokenB, uniswapExtremeTokenA, true);
        console.log("Uniswap extreme unbalanced pool swaps TokenB fees enabled test passed");
    }

    // ============================================================================
    // CAMELOT V2 TESTS - FEES DISABLED (6 tests: 3 pools × 2 directions)
    // ============================================================================

    function test_quoteSwapDepositWithFee_Camelot_balancedPool_swapsTokenA_feesDisabled() public {
        console.log("=== Testing Camelot V2: balancedPool_swapsTokenA_feesDisabled ===");
        _testSwapDepositWithFeeCamelot(camelotBalancedPair, camelotBalancedTokenA, camelotBalancedTokenB, false);
        console.log("Camelot balanced pool swaps TokenA fees disabled test passed");
    }

    function test_quoteSwapDepositWithFee_Camelot_balancedPool_swapsTokenB_feesDisabled() public {
        console.log("=== Testing Camelot V2: balancedPool_swapsTokenB_feesDisabled ===");
        _testSwapDepositWithFeeCamelot(camelotBalancedPair, camelotBalancedTokenB, camelotBalancedTokenA, false);
        console.log("Camelot balanced pool swaps TokenB fees disabled test passed");
    }

    function test_quoteSwapDepositWithFee_Camelot_unbalancedPool_swapsTokenA_feesDisabled() public {
        console.log("=== Testing Camelot V2: unbalancedPool_swapsTokenA_feesDisabled ===");
        _testSwapDepositWithFeeCamelot(camelotUnbalancedPair, camelotUnbalancedTokenA, camelotUnbalancedTokenB, false);
        console.log("Camelot unbalanced pool swaps TokenA fees disabled test passed");
    }

    function test_quoteSwapDepositWithFee_Camelot_unbalancedPool_swapsTokenB_feesDisabled() public {
        console.log("=== Testing Camelot V2: unbalancedPool_swapsTokenB_feesDisabled ===");
        _testSwapDepositWithFeeCamelot(camelotUnbalancedPair, camelotUnbalancedTokenB, camelotUnbalancedTokenA, false);
        console.log("Camelot unbalanced pool swaps TokenB fees disabled test passed");
    }

    function test_quoteSwapDepositWithFee_Camelot_extremeUnbalancedPool_swapsTokenA_feesDisabled() public {
        console.log("=== Testing Camelot V2: extremeUnbalancedPool_swapsTokenA_feesDisabled ===");
        _testSwapDepositWithFeeCamelot(camelotExtremeUnbalancedPair, camelotExtremeTokenA, camelotExtremeTokenB, false);
        console.log("Camelot extreme unbalanced pool swaps TokenA fees disabled test passed");
    }

    function test_quoteSwapDepositWithFee_Camelot_extremeUnbalancedPool_swapsTokenB_feesDisabled() public {
        console.log("=== Testing Camelot V2: extremeUnbalancedPool_swapsTokenB_feesDisabled ===");
        _testSwapDepositWithFeeCamelot(camelotExtremeUnbalancedPair, camelotExtremeTokenB, camelotExtremeTokenA, false);
        console.log("Camelot extreme unbalanced pool swaps TokenB fees disabled test passed");
    }

    // ============================================================================
    // CAMELOT V2 TESTS - FEES ENABLED (6 tests: 3 pools × 2 directions)
    // ============================================================================

    function test_quoteSwapDepositWithFee_Camelot_balancedPool_swapsTokenA_feesEnabled() public {
        console.log("=== Testing Camelot V2: balancedPool_swapsTokenA_feesEnabled ===");
        _testSwapDepositWithFeeCamelot(camelotBalancedPair, camelotBalancedTokenA, camelotBalancedTokenB, true);
        console.log("Camelot balanced pool swaps TokenA fees enabled test passed");
    }

    function test_quoteSwapDepositWithFee_Camelot_balancedPool_swapsTokenB_feesEnabled() public {
        console.log("=== Testing Camelot V2: balancedPool_swapsTokenB_feesEnabled ===");
        _testSwapDepositWithFeeCamelot(camelotBalancedPair, camelotBalancedTokenB, camelotBalancedTokenA, true);
        console.log("Camelot balanced pool swaps TokenB fees enabled test passed");
    }

    function test_quoteSwapDepositWithFee_Camelot_unbalancedPool_swapsTokenA_feesEnabled() public {
        console.log("=== Testing Camelot V2: unbalancedPool_swapsTokenA_feesEnabled ===");
        _testSwapDepositWithFeeCamelot(camelotUnbalancedPair, camelotUnbalancedTokenA, camelotUnbalancedTokenB, true);
        console.log("Camelot unbalanced pool swaps TokenA fees enabled test passed");
    }

    function test_quoteSwapDepositWithFee_Camelot_unbalancedPool_swapsTokenB_feesEnabled() public {
        console.log("=== Testing Camelot V2: unbalancedPool_swapsTokenB_feesEnabled ===");
        _testSwapDepositWithFeeCamelot(camelotUnbalancedPair, camelotUnbalancedTokenB, camelotUnbalancedTokenA, true);
        console.log("Camelot unbalanced pool swaps TokenB fees enabled test passed");
    }

    function test_quoteSwapDepositWithFee_Camelot_extremeUnbalancedPool_swapsTokenA_feesEnabled() public {
        console.log("=== Testing Camelot V2: extremeUnbalancedPool_swapsTokenA_feesEnabled ===");
        _testSwapDepositWithFeeCamelot(camelotExtremeUnbalancedPair, camelotExtremeTokenA, camelotExtremeTokenB, true);
        console.log("Camelot extreme unbalanced pool swaps TokenA fees enabled test passed");
    }

    function test_quoteSwapDepositWithFee_Camelot_extremeUnbalancedPool_swapsTokenB_feesEnabled() public {
        console.log("=== Testing Camelot V2: extremeUnbalancedPool_swapsTokenB_feesEnabled ===");
        _testSwapDepositWithFeeCamelot(camelotExtremeUnbalancedPair, camelotExtremeTokenB, camelotExtremeTokenA, true);
        console.log("Camelot extreme unbalanced pool swaps TokenB fees enabled test passed");
    }

    // ============================================================================
    // HELPER FUNCTIONS
    // ============================================================================

    struct SwapDepositTestData {
        uint256 balanceBeforeA;
        uint256 balanceBeforeB;
        uint256 lpBalanceBefore;
        uint256 lpBalanceAfter;
        uint256 lpTokensReceived;
        uint112 reserve0;
        uint112 reserve1;
        uint256 totalSupply;
        uint256 kLast;
        uint256 reserveA;
        uint256 reserveB;
        uint256 quotedLpAmt;
        uint256 actualLpAmt;
    }

    struct CamelotExecutionData {
        uint112 reserve0;
        uint112 reserve1;
        uint16 token0Fee;
        uint16 token1Fee;
        uint256 inputTokenFee;
        uint256 swapAmount;
        uint256 opTokenAmtIn;
        uint256 remainingAmountA;
    }

    struct CamelotCalculationData {
        uint256 updatedReserveA;
        uint256 updatedReserveB;
        uint256 protocolFee;
        uint256 expectedLpAmt;
    }

    function _testSwapDepositWithFeeUniswap(
        IUniswapV2Pair pair,
        IERC20MintBurn tokenA,
        IERC20MintBurn tokenB,
        bool feesEnabled
    ) internal {
        // Setup fees
        _setupUniswapFees(feesEnabled);

        // Initialize test data struct
        SwapDepositTestData memory data;

        // Get initial pool state
        (data.reserve0, data.reserve1,) = pair.getReserves();
        data.totalSupply = pair.totalSupply();
        data.kLast = pair.kLast();

        console.log("Pool state - reserve0:", data.reserve0, "reserve1:", data.reserve1);
        console.log("Pool state - totalSupply:", data.totalSupply, "kLast:", data.kLast);

        // Generate trading activity if fees are enabled
        if (feesEnabled) {
            _generateTradingActivity(pair, tokenA, tokenB, 100); // 1% trading

            // Get updated pool state after trading
            (data.reserve0, data.reserve1,) = pair.getReserves();
            data.totalSupply = pair.totalSupply();
            data.kLast = pair.kLast();

            console.log("Pool state after trading - reserve0:", data.reserve0, "reserve1:", data.reserve1);
            console.log("Pool state after trading - totalSupply:", data.totalSupply, "kLast:", data.kLast);
        }

        // Sort reserves to match tokenA/tokenB order with fees
        (data.reserveA,, data.reserveB,) = ConstProdUtils._sortReserves(
            address(tokenA), // knownToken
            pair.token0(), // token0
            data.reserve0, // reserve0
            UNISWAP_FEE_PERCENT, // token0Fee
            data.reserve1, // reserve1
            UNISWAP_FEE_PERCENT // token1Fee
        );

        console.log("Sorted reserves - reserveA:", data.reserveA, "reserveB:", data.reserveB);

        // Test the quote function
        data.quotedLpAmt = ConstProdUtils._quoteSwapDepositWithFee(
            TEST_AMOUNT_IN, // amountIn
            data.totalSupply, // lpTotalSupply
            data.reserveA, // reserveIn (tokenA)
            data.reserveB, // reserveOut (tokenB)
            UNISWAP_FEE_PERCENT, // feePercent (0.3%)
            data.kLast, // kLast
            UNISWAP_OWNER_FEE_SHARE, // ownerFeeShare (1/6 for Uniswap V2)
            feesEnabled // feeOn
        );

        console.log("Quote result - lpAmt:", data.quotedLpAmt);

        // Execute ZapIn and validate using the same reserves as the quote
        data.actualLpAmt = _executeZapInAndValidate(pair, tokenA, tokenB, TEST_AMOUNT_IN, data.reserveA, data.reserveB);

        console.log("Actual LP tokens received:", data.actualLpAmt);

        // Validate that quote matches execution within tolerance (small difference due to rounding)
        assertTrue(data.quotedLpAmt > 0, "Quoted LP amount should be positive");
        assertTrue(data.actualLpAmt > 0, "Actual LP amount should be positive");
        assertGe(data.quotedLpAmt, data.actualLpAmt, "Quote should be >= actual LP amount");
        assertLe(data.quotedLpAmt - data.actualLpAmt, 10, "Quote should be within 10 wei of actual LP amount");
    }

    function _executeZapInAndValidate(
        IUniswapV2Pair pair,
        IERC20MintBurn tokenA,
        IERC20MintBurn tokenB,
        uint256 amountIn,
        uint256 reserveA,
        uint256 reserveB
    ) internal returns (uint256 actualLpAmt) {
        // Get initial LP balance
        uint256 lpBalanceBefore = pair.balanceOf(address(this));

        // Mint input token
        tokenA.mint(address(this), amountIn);
        tokenA.approve(address(uniswapV2Router()), amountIn);

        // Use the same reserves that the quote function used
        uint256 swapAmount = ConstProdUtils._swapDepositSaleAmt(amountIn, reserveA, UNISWAP_FEE_PERCENT);
        console.log("Calculated swap amount:", swapAmount);

        // Execute swap if needed
        if (swapAmount > 0) {
            address[] memory path = new address[](2);
            path[0] = address(tokenA);
            path[1] = address(tokenB);

            IUniswapV2Router(address(uniswapV2Router()))
                .swapExactTokensForTokens(
                    swapAmount,
                    1, // minAmountOut
                    path,
                    address(this),
                    block.timestamp
                );
        }

        // Calculate the exact amounts that the quote function uses
        uint256 opTokenAmtIn = swapAmount._saleQuote(reserveA, reserveB, UNISWAP_FEE_PERCENT);
        uint256 remainingAmountA = amountIn - swapAmount;

        console.log("Calculated amounts - remainingA:", remainingAmountA, "receivedB:", opTokenAmtIn);

        // Approve tokens for deposit using the calculated amounts
        tokenA.approve(address(uniswapV2Router()), remainingAmountA);
        tokenB.approve(address(uniswapV2Router()), opTokenAmtIn);

        // Execute deposit with the calculated amounts
        IUniswapV2Router(address(uniswapV2Router()))
            .addLiquidity(
                address(tokenA),
                address(tokenB),
                remainingAmountA,
                opTokenAmtIn,
                1, // minAmountA
                1, // minAmountB
                address(this),
                block.timestamp
            );

        // Get final LP balance
        uint256 lpBalanceAfter = pair.balanceOf(address(this));
        actualLpAmt = lpBalanceAfter - lpBalanceBefore;

        console.log("LP tokens received from ZapIn:", actualLpAmt);
    }

    function _setupUniswapFees(bool enableProtocolFees) internal {
        address factoryOwner = uniswapV2Factory().feeToSetter();

        if (enableProtocolFees) {
            vm.prank(factoryOwner);
            uniswapV2Factory().setFeeTo(factoryOwner);
        } else {
            vm.prank(factoryOwner);
            uniswapV2Factory().setFeeTo(address(0));
        }
    }

    function _generateTradingActivity(
        IUniswapV2Pair pair,
        IERC20MintBurn tokenA,
        IERC20MintBurn tokenB,
        uint256 swapPercentage // e.g., 100 = 1%, 500 = 5%
    ) internal {
        console.log("Generating Uniswap trading activity:");

        (uint112 reserveA, uint112 reserveB,) = pair.getReserves();
        console.log("ReserveA:", reserveA, "ReserveB:", reserveB);
        console.log("SwapPercentage:", swapPercentage);

        uint256 swapAmountA = (reserveA * swapPercentage) / 10000;
        uint256 swapAmountB = (reserveB * swapPercentage) / 10000;
        console.log("SwapAmountA:", swapAmountA, "SwapAmountB:", swapAmountB);

        // Mint tokens for trading
        tokenA.mint(address(this), swapAmountA);
        tokenB.mint(address(this), swapAmountB);

        // First swap: A -> B
        tokenA.approve(address(uniswapV2Router()), swapAmountA);
        address[] memory pathAB = new address[](2);
        pathAB[0] = address(tokenA);
        pathAB[1] = address(tokenB);

        uint256 balanceBeforeB = tokenB.balanceOf(address(this));
        IUniswapV2Router(address(uniswapV2Router()))
            .swapExactTokensForTokens(
                swapAmountA,
                1, // minAmountOut
                pathAB,
                address(this),
                block.timestamp
            );
        uint256 receivedB = tokenB.balanceOf(address(this)) - balanceBeforeB;
        console.log("First swap A->B: swapped", swapAmountA, "received", receivedB);

        // Second swap: B -> A
        tokenB.approve(address(uniswapV2Router()), receivedB);
        address[] memory pathBA = new address[](2);
        pathBA[0] = address(tokenB);
        pathBA[1] = address(tokenA);

        uint256 balanceBeforeA = tokenA.balanceOf(address(this));
        IUniswapV2Router(address(uniswapV2Router()))
            .swapExactTokensForTokens(
                receivedB,
                1, // minAmountOut
                pathBA,
                address(this),
                block.timestamp
            );
        uint256 receivedA = tokenA.balanceOf(address(this)) - balanceBeforeA;
        console.log("Second swap B->A: swapped", receivedB, "received", receivedA);

        console.log("Uniswap trading activity complete");
    }

    function _testSwapDepositWithFeeCamelot(
        ICamelotPair pair,
        IERC20MintBurn tokenA,
        IERC20MintBurn tokenB,
        bool feesEnabled
    ) internal {
        // Ensure protocol fee minting does not accrue to this test account
        // Setup fees
        // _setupCamelotFees(feesEnabled);

        // Initialize test data struct
        SwapDepositTestData memory data;

        // Get initial pool state
        uint16 token0Fee;
        uint16 token1Fee;
        (data.reserve0, data.reserve1, token0Fee, token1Fee) = pair.getReserves();
        data.totalSupply = pair.totalSupply();
        data.kLast = pair.kLast();

        console.log("Pool state - reserve0:", data.reserve0, "reserve1:", data.reserve1);
        console.log("Pool state - totalSupply:", data.totalSupply, "kLast:", data.kLast);
        console.log("Pool state - token0Fee:", token0Fee, "token1Fee:", token1Fee);

        // Generate trading activity if fees are enabled
        if (feesEnabled) {
            _generateCamelotTradingActivity(pair, tokenA, tokenB, 100); // 1% trading

            // Get updated pool state after trading
            (data.reserve0, data.reserve1, token0Fee, token1Fee) = pair.getReserves();
            data.totalSupply = pair.totalSupply();
            data.kLast = pair.kLast();

            console.log("Pool state after trading - reserve0:", data.reserve0, "reserve1:", data.reserve1);
            console.log("Pool state after trading - totalSupply:", data.totalSupply, "kLast:", data.kLast);
            console.log("Pool state after trading - token0Fee:", token0Fee, "token1Fee:", token1Fee);
        }

        // Sort reserves to match tokenA/tokenB order with correct fees
        (data.reserveA,, data.reserveB,) = ConstProdUtils._sortReserves(
            address(tokenA), // knownToken
            pair.token0(), // token0
            data.reserve0, // reserve0
            token0Fee, // token0Fee (from getReserves)
            data.reserve1, // reserve1
            token1Fee // token1Fee (from getReserves)
        );

        console.log("Sorted reserves - reserveA:", data.reserveA, "reserveB:", data.reserveB);

        // Get the correct fee for the input token (tokenA)
        uint256 inputTokenFee = (address(tokenA) == pair.token0()) ? token0Fee : token1Fee;

        // Get the actual owner fee share from the Camelot factory
        uint256 ownerFeeShare = ICamelotFactory(camV2Factory()).ownerFeeShare();

        // Test the quote function
        data.quotedLpAmt = ConstProdUtils._quoteSwapDepositWithFee(
            TEST_AMOUNT_IN, // amountIn
            data.totalSupply, // lpTotalSupply
            data.reserveA, // reserveIn (tokenA)
            data.reserveB, // reserveOut (tokenB)
            inputTokenFee, // feePercent (from getReserves)
            data.kLast, // kLast
            ownerFeeShare, // ownerFeeShare (from factory)
            feesEnabled // feeOn
        );

        console.log("Quote result - lpAmt:", data.quotedLpAmt);

        // Execute ZapIn and validate using the same reserves as the quote
        data.actualLpAmt = _executeCamelotZapInAndValidate(
            pair, tokenA, tokenB, TEST_AMOUNT_IN, data.reserveA, data.reserveB, ownerFeeShare
        );

        console.log("Actual LP tokens received:", data.actualLpAmt);

        // Validate exact equality per project preference
        assertTrue(data.quotedLpAmt > 0, "Quoted LP amount should be positive");
        assertTrue(data.actualLpAmt > 0, "Actual LP amount should be positive");
        assertEq(data.quotedLpAmt, data.actualLpAmt, "Quote should exactly match actual LP amount");
    }

    function _executeCamelotZapInAndValidate(
        ICamelotPair pair,
        IERC20MintBurn tokenA,
        IERC20MintBurn tokenB,
        uint256 amountIn,
        uint256 reserveA,
        uint256 reserveB,
        uint256 ownerFeeShare
    ) internal returns (uint256 actualLpAmt) {
        // Initialize execution data struct
        CamelotExecutionData memory execData;

        // Get initial LP balance
        uint256 lpBalanceBefore = pair.balanceOf(address(this));

        // Mint input token
        tokenA.mint(address(this), amountIn);
        tokenA.approve(address(camV2Router()), amountIn);

        // Get the correct fee for the input token
        (execData.reserve0, execData.reserve1, execData.token0Fee, execData.token1Fee) = pair.getReserves();
        execData.inputTokenFee = (address(tokenA) == pair.token0()) ? execData.token0Fee : execData.token1Fee;

        // Compute swap amount to execute using library
        execData.swapAmount = ConstProdUtils._swapDepositSaleAmt(amountIn, reserveA, execData.inputTokenFee);
        console.log("Calculated swap amount:", execData.swapAmount);

        // Execute swap and measure actual received B
        uint256 balBBefore = tokenB.balanceOf(address(this));
        if (execData.swapAmount > 0) {
            address[] memory path = new address[](2);
            path[0] = address(tokenA);
            path[1] = address(tokenB);
            ICamelotV2Router(camV2Router())
                .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    execData.swapAmount, 1, path, address(this), address(0), block.timestamp + 300
                );
        }
        execData.opTokenAmtIn = tokenB.balanceOf(address(this)) - balBBefore;
        execData.remainingAmountA = amountIn - execData.swapAmount;
        console.log("Calculated amounts - remainingA:", execData.remainingAmountA, "receivedB:", execData.opTokenAmtIn);

        // Use actual post-swap reserves from the pair for expected LP math
        (execData.reserve0, execData.reserve1,,) = pair.getReserves();
        uint256 updatedReserveA =
            (address(tokenA) == pair.token0()) ? uint256(execData.reserve0) : uint256(execData.reserve1);
        uint256 updatedReserveB =
            (address(tokenA) == pair.token0()) ? uint256(execData.reserve1) : uint256(execData.reserve0);

        // Initialize calculation data struct
        CamelotCalculationData memory calcData;
        calcData.updatedReserveA = updatedReserveA;
        calcData.updatedReserveB = updatedReserveB;

        console.log("Updated reserves - reserveA:", calcData.updatedReserveA, "reserveB:", calcData.updatedReserveB);

        // Camelot tests do not enable protocol fee minting via feeTo; keep protocol fee at 0
        calcData.protocolFee = 0;

        // Calculate expected LP amount using the same logic as the quote function
        calcData.expectedLpAmt = execData.remainingAmountA
            ._depositQuote(
                execData.opTokenAmtIn, pair.totalSupply(), calcData.updatedReserveA, calcData.updatedReserveB
            );
        console.log("Expected LP amount from _depositQuote:", calcData.expectedLpAmt);

        // Add liquidity via the Camelot router so execution follows the same
        // integer-quoting logic the quote function simulates.
        tokenA.approve(address(camV2Router()), execData.remainingAmountA);
        tokenB.approve(address(camV2Router()), execData.opTokenAmtIn);
        (, , actualLpAmt) = ICamelotV2Router(camV2Router()).addLiquidity(
            address(tokenA),
            address(tokenB),
            execData.remainingAmountA,
            execData.opTokenAmtIn,
            1, // minAmountA
            1, // minAmountB
            address(this),
            block.timestamp + 300
        );

        console.log("LP tokens received from ZapIn:", actualLpAmt);
    }

    // function _setupCamelotFees(bool enableProtocolFees) internal {
    //     // Camelot V2 doesn't have protocol fees like Uniswap V2
    //     // This is a placeholder for future fee mechanisms
    //     if (enableProtocolFees) {
    //         console.log("Camelot V2 protocol fees enabled (placeholder)");
    //     } else {
    //         console.log("Camelot V2 protocol fees disabled");
    //     }
    // }

    function _generateCamelotTradingActivity(
        ICamelotPair pair,
        IERC20MintBurn tokenA,
        IERC20MintBurn tokenB,
        uint256 swapPercentage // e.g., 100 = 1%, 500 = 5%
    ) internal {
        console.log("Generating Camelot trading activity:");

        (uint112 reserveA, uint112 reserveB,,) = pair.getReserves();
        console.log("ReserveA:", reserveA, "ReserveB:", reserveB);
        console.log("SwapPercentage:", swapPercentage);

        uint256 swapAmountA = (reserveA * swapPercentage) / 10000;
        uint256 swapAmountB = (reserveB * swapPercentage) / 10000;
        console.log("SwapAmountA:", swapAmountA, "SwapAmountB:", swapAmountB);

        // Mint tokens for trading
        tokenA.mint(address(this), swapAmountA);
        tokenB.mint(address(this), swapAmountB);

        // First swap: A -> B
        tokenA.approve(address(camV2Router()), swapAmountA);
        address[] memory pathAB = new address[](2);
        pathAB[0] = address(tokenA);
        pathAB[1] = address(tokenB);

        uint256 balanceBeforeB = tokenB.balanceOf(address(this));
        ICamelotV2Router(camV2Router())
            .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                swapAmountA,
                1, // minAmountOut
                pathAB,
                address(this),
                address(0), // referrer
                block.timestamp + 300 // deadline
            );
        uint256 receivedB = tokenB.balanceOf(address(this)) - balanceBeforeB;
        console.log("First swap A->B: swapped", swapAmountA, "received", receivedB);

        // Second swap: B -> A
        tokenB.approve(address(camV2Router()), receivedB);
        address[] memory pathBA = new address[](2);
        pathBA[0] = address(tokenB);
        pathBA[1] = address(tokenA);

        uint256 balanceBeforeA = tokenA.balanceOf(address(this));
        ICamelotV2Router(camV2Router())
            .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                receivedB,
                1, // minAmountOut
                pathBA,
                address(this),
                address(0), // referrer
                block.timestamp + 300 // deadline
            );
        uint256 receivedA = tokenA.balanceOf(address(this)) - balanceBeforeA;
        console.log("Second swap B->A: swapped", receivedB, "received", receivedA);

        console.log("Camelot trading activity complete");
    }
}
