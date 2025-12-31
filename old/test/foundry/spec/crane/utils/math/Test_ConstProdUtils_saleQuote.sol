// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {betterconsole as console} from "contracts/crane/utils/vm/foundry/tools/betterconsole.sol";
import {TestBase_ConstProdUtils} from "./TestBase_ConstProdUtils.sol";
import {ConstProdUtils} from "contracts/crane/utils/math/ConstProdUtils.sol";
import {ICamelotV2Router} from "contracts/crane/interfaces/protocols/dexes/camelot/v2/ICamelotV2Router.sol";
import {IUniswapV2Router} from "contracts/crane/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Router.sol";

/**
 * @title Test_ConstProdUtils_saleQuote
 * @dev Tests ConstProdUtils._saleQuote against actual DEX swap operations
 */
contract Test_ConstProdUtils_saleQuote is TestBase_ConstProdUtils {
    function setUp() public override {
        super.setUp();
    }

    function run() public override {
        super.run();
    }

    // // Helper function to create swap path
    // function _getPath(address tokenIn, address tokenOut) internal pure returns (address[] memory path) {
    //     path = new address[](2);
    //     path[0] = tokenIn;
    //     path[1] = tokenOut;
    // }

    // ============================================================================
    // A→B Direction Tests (TokenA → TokenB)
    // ============================================================================

    function test_saleQuote_Camelot_balancedPool_sellsTokenA() public {
        // Get reserves (A = input, B = output)
        (uint112 reserve0, uint112 reserve1, uint16 token0Fee, uint16 token1Fee) = camelotBalancedPair.getReserves();
        (uint256 reserveA, uint256 feePercent, uint256 reserveB,) = ConstProdUtils._sortReserves(
            address(camelotBalancedTokenA),
            camelotBalancedPair.token0(),
            reserve0,
            uint256(token0Fee),
            reserve1,
            uint256(token1Fee)
        );

        // Set swap amount (10% of input reserve)
        uint256 swapAmount = reserveA / 10;

        // Calculate expected output using 5-parameter version
        uint256 expectedAmountOut = ConstProdUtils._saleQuote(swapAmount, reserveA, reserveB, feePercent, 100_000);

        // Mint input tokens and perform actual swap A→B
        camelotBalancedTokenA.mint(address(this), swapAmount);
        uint256 initialBalanceB = camelotBalancedTokenB.balanceOf(address(this));

        // Execute actual swap A→B
        camelotBalancedTokenA.approve(address(camV2Router()), swapAmount);
        ICamelotV2Router(camV2Router())
            .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                swapAmount,
                0, // accept any amount of output tokens
                _getPath(address(camelotBalancedTokenA), address(camelotBalancedTokenB)),
                address(this),
                address(0), // referrer
                block.timestamp + 300 // deadline
            );
        uint256 actualAmountOut = camelotBalancedTokenB.balanceOf(address(this)) - initialBalanceB;

        // Validate results
        assertEq(actualAmountOut, expectedAmountOut, "Expected vs Actual mismatch");
        assertEq(
            camelotBalancedTokenB.balanceOf(address(this)) - initialBalanceB,
            actualAmountOut,
            "Balance change should match"
        );

        // console.log("_saleQuote Camelot balanced pool A->B test passed:");
        // console.log("  ReserveA:", reserveA);
        // console.log("  ReserveB:", reserveB);
        // console.log("  Swap Amount:", swapAmount);
        // console.log("  Fee Percent:", feePercent);
        // console.log("  Expected AmountOut:", expectedAmountOut);
        // console.log("  Actual AmountOut:", actualAmountOut);
    }

    function test_saleQuote_Camelot_unbalancedPool_sellsTokenA() public {
        // Get reserves (A = input, B = output)
        (uint112 reserve0, uint112 reserve1, uint16 token0Fee, uint16 token1Fee) = camelotUnbalancedPair.getReserves();
        (uint256 reserveA, uint256 feePercent, uint256 reserveB,) = ConstProdUtils._sortReserves(
            address(camelotUnbalancedTokenA),
            camelotUnbalancedPair.token0(),
            reserve0,
            uint256(token0Fee),
            reserve1,
            uint256(token1Fee)
        );

        // Set swap amount (10% of input reserve)
        uint256 swapAmount = reserveA / 10;

        // Calculate expected output using 5-parameter version
        uint256 expectedAmountOut = ConstProdUtils._saleQuote(swapAmount, reserveA, reserveB, feePercent, 100_000);

        // Mint input tokens and perform actual swap A→B
        camelotUnbalancedTokenA.mint(address(this), swapAmount);
        uint256 initialBalanceB = camelotUnbalancedTokenB.balanceOf(address(this));

        // Execute actual swap A→B
        camelotUnbalancedTokenA.approve(address(camV2Router()), swapAmount);
        ICamelotV2Router(camV2Router())
            .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                swapAmount,
                0, // accept any amount of output tokens
                _getPath(address(camelotUnbalancedTokenA), address(camelotUnbalancedTokenB)),
                address(this),
                address(0), // referrer
                block.timestamp + 300 // deadline
            );
        uint256 actualAmountOut = camelotUnbalancedTokenB.balanceOf(address(this)) - initialBalanceB;

        // Validate results
        assertEq(actualAmountOut, expectedAmountOut, "Expected vs Actual mismatch");
        assertEq(
            camelotUnbalancedTokenB.balanceOf(address(this)) - initialBalanceB,
            actualAmountOut,
            "Balance change should match"
        );

        // console.log("_saleQuote Camelot unbalanced pool A->B test passed:");
        // console.log("  ReserveA:", reserveA);
        // console.log("  ReserveB:", reserveB);
        // console.log("  Swap Amount:", swapAmount);
        // console.log("  Fee Percent:", feePercent);
        // console.log("  Expected AmountOut:", expectedAmountOut);
        // console.log("  Actual AmountOut:", actualAmountOut);
    }

    function test_saleQuote_Camelot_extremeUnbalancedPool_sellsTokenA() public {
        // Get reserves and sort them properly
        (uint112 reserve0, uint112 reserve1, uint16 token0Fee, uint16 token1Fee) =
            camelotExtremeUnbalancedPair.getReserves();
        (uint256 reserveA, uint256 feePercent, uint256 reserveB,) = ConstProdUtils._sortReserves(
            address(camelotExtremeTokenA),
            camelotExtremeUnbalancedPair.token0(),
            reserve0,
            uint256(token0Fee),
            reserve1,
            uint256(token1Fee)
        );

        // Set swap amount (10% of input reserve)
        uint256 swapAmount = reserveA / 10;

        // Calculate expected output using 5-parameter version
        uint256 expectedAmountOut = ConstProdUtils._saleQuote(swapAmount, reserveA, reserveB, feePercent, 100_000);

        // Mint input tokens and perform actual swap A→B
        camelotExtremeTokenA.mint(address(this), swapAmount);
        uint256 initialBalanceB = camelotExtremeTokenB.balanceOf(address(this));

        // Execute actual swap A→B
        camelotExtremeTokenA.approve(address(camV2Router()), swapAmount);
        ICamelotV2Router(camV2Router())
            .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                swapAmount,
                0, // accept any amount of output tokens
                _getPath(address(camelotExtremeTokenA), address(camelotExtremeTokenB)),
                address(this),
                address(0), // referrer
                block.timestamp + 300 // deadline
            );
        uint256 actualAmountOut = camelotExtremeTokenB.balanceOf(address(this)) - initialBalanceB;

        // Validate results
        assertEq(actualAmountOut, expectedAmountOut, "Expected vs Actual mismatch");
        assertEq(
            camelotExtremeTokenB.balanceOf(address(this)) - initialBalanceB,
            actualAmountOut,
            "Balance change should match"
        );

        // console.log("_saleQuote Camelot extreme unbalanced pool A->B test passed:");
        // console.log("  ReserveA:", reserveA);
        // console.log("  ReserveB:", reserveB);
        // console.log("  Swap Amount:", swapAmount);
        // console.log("  Fee Percent:", feePercent);
        // console.log("  Expected AmountOut:", expectedAmountOut);
        // console.log("  Actual AmountOut:", actualAmountOut);
    }

    function test_saleQuote_Uniswap_balancedPool_sellsTokenA() public {
        // Get reserves and sort them properly
        (uint112 reserve0, uint112 reserve1,) = uniswapBalancedPair.getReserves();
        (uint256 reserveA, uint256 feePercent, uint256 reserveB,) = ConstProdUtils._sortReserves(
            address(uniswapBalancedTokenA), uniswapBalancedPair.token0(), reserve0, 300, reserve1, 300
        );

        // Set swap amount (10% of input reserve)
        uint256 swapAmount = reserveA / 10;

        // Calculate expected output using 5-parameter version
        uint256 expectedAmountOut = ConstProdUtils._saleQuote(swapAmount, reserveA, reserveB, feePercent, 100_000);

        // Mint input tokens and perform actual swap A→B
        uniswapBalancedTokenA.mint(address(this), swapAmount);
        uint256 initialBalanceB = uniswapBalancedTokenB.balanceOf(address(this));

        // Execute actual swap A→B
        uniswapBalancedTokenA.approve(address(uniswapV2Router()), swapAmount);
        IUniswapV2Router(address(uniswapV2Router()))
            .swapExactTokensForTokens(
                swapAmount,
                0, // accept any amount of output tokens
                _getPath(address(uniswapBalancedTokenA), address(uniswapBalancedTokenB)),
                address(this),
                block.timestamp
            );
        uint256 actualAmountOut = uniswapBalancedTokenB.balanceOf(address(this)) - initialBalanceB;

        // Validate results
        assertEq(actualAmountOut, expectedAmountOut, "Expected vs Actual mismatch");
        assertEq(
            uniswapBalancedTokenB.balanceOf(address(this)) - initialBalanceB,
            actualAmountOut,
            "Balance change should match"
        );

        // console.log("_saleQuote Uniswap balanced pool A->B test passed:");
        // console.log("  ReserveA:", reserveA);
        // console.log("  ReserveB:", reserveB);
        // console.log("  Swap Amount:", swapAmount);
        // console.log("  Fee Percent:", feePercent);
        // console.log("  Expected AmountOut:", expectedAmountOut);
        // console.log("  Actual AmountOut:", actualAmountOut);
    }

    function test_saleQuote_Uniswap_unbalancedPool_sellsTokenA() public {
        // Get reserves and sort them properly
        (uint112 reserve0, uint112 reserve1,) = uniswapUnbalancedPair.getReserves();
        (uint256 reserveA, uint256 feePercent, uint256 reserveB,) = ConstProdUtils._sortReserves(
            address(uniswapUnbalancedTokenA), uniswapUnbalancedPair.token0(), reserve0, 300, reserve1, 300
        );

        // Set swap amount (10% of input reserve)
        uint256 swapAmount = reserveA / 10;

        // Calculate expected output using 5-parameter version
        uint256 expectedAmountOut = ConstProdUtils._saleQuote(swapAmount, reserveA, reserveB, feePercent, 100_000);

        // Mint input tokens and perform actual swap A→B
        uniswapUnbalancedTokenA.mint(address(this), swapAmount);
        uint256 initialBalanceB = uniswapUnbalancedTokenB.balanceOf(address(this));

        // Execute actual swap A→B
        uniswapUnbalancedTokenA.approve(address(uniswapV2Router()), swapAmount);
        IUniswapV2Router(address(uniswapV2Router()))
            .swapExactTokensForTokens(
                swapAmount,
                0, // accept any amount of output tokens
                _getPath(address(uniswapUnbalancedTokenA), address(uniswapUnbalancedTokenB)),
                address(this),
                block.timestamp
            );
        uint256 actualAmountOut = uniswapUnbalancedTokenB.balanceOf(address(this)) - initialBalanceB;

        // Validate results
        assertEq(actualAmountOut, expectedAmountOut, "Expected vs Actual mismatch");
        assertEq(
            uniswapUnbalancedTokenB.balanceOf(address(this)) - initialBalanceB,
            actualAmountOut,
            "Balance change should match"
        );

        // console.log("_saleQuote Uniswap unbalanced pool A->B test passed:");
        // console.log("  ReserveA:", reserveA);
        // console.log("  ReserveB:", reserveB);
        // console.log("  Swap Amount:", swapAmount);
        // console.log("  Fee Percent:", feePercent);
        // console.log("  Expected AmountOut:", expectedAmountOut);
        // console.log("  Actual AmountOut:", actualAmountOut);
    }

    function test_saleQuote_Uniswap_extremeUnbalancedPool_sellsTokenA() public {
        // Get reserves and sort them properly
        (uint112 reserve0, uint112 reserve1,) = uniswapExtremeUnbalancedPair.getReserves();
        (uint256 reserveA, uint256 feePercent, uint256 reserveB,) = ConstProdUtils._sortReserves(
            address(uniswapExtremeTokenA), uniswapExtremeUnbalancedPair.token0(), reserve0, 300, reserve1, 300
        );

        // Set swap amount (10% of input reserve)
        uint256 swapAmount = reserveA / 10;

        // Calculate expected output using 5-parameter version
        uint256 expectedAmountOut = ConstProdUtils._saleQuote(swapAmount, reserveA, reserveB, feePercent, 100_000);

        // Mint input tokens and perform actual swap A→B
        uniswapExtremeTokenA.mint(address(this), swapAmount);
        uint256 initialBalanceB = uniswapExtremeTokenB.balanceOf(address(this));

        // Execute actual swap A→B
        uniswapExtremeTokenA.approve(address(uniswapV2Router()), swapAmount);
        IUniswapV2Router(address(uniswapV2Router()))
            .swapExactTokensForTokens(
                swapAmount,
                0, // accept any amount of output tokens
                _getPath(address(uniswapExtremeTokenA), address(uniswapExtremeTokenB)),
                address(this),
                block.timestamp
            );
        uint256 actualAmountOut = uniswapExtremeTokenB.balanceOf(address(this)) - initialBalanceB;

        // Validate results
        assertEq(actualAmountOut, expectedAmountOut, "Expected vs Actual mismatch");
        assertEq(
            uniswapExtremeTokenB.balanceOf(address(this)) - initialBalanceB,
            actualAmountOut,
            "Balance change should match"
        );

        // console.log("_saleQuote Uniswap extreme unbalanced pool A->B test passed:");
        // console.log("  ReserveA:", reserveA);
        // console.log("  ReserveB:", reserveB);
        // console.log("  Swap Amount:", swapAmount);
        // console.log("  Fee Percent:", feePercent);
        // console.log("  Expected AmountOut:", expectedAmountOut);
        // console.log("  Actual AmountOut:", actualAmountOut);
    }

    // ============================================================================
    // B→A Direction Tests (TokenB → TokenA)
    // ============================================================================

    function test_saleQuote_Camelot_balancedPool_sellsTokenB() public {
        // Get reserves and sort them properly
        (uint112 reserve0, uint112 reserve1, uint16 token0Fee, uint16 token1Fee) = camelotBalancedPair.getReserves();
        (uint256 reserveA, uint256 feePercent, uint256 reserveB,) = ConstProdUtils._sortReserves(
            address(camelotBalancedTokenB),
            camelotBalancedPair.token0(),
            reserve0,
            uint256(token0Fee),
            reserve1,
            uint256(token1Fee)
        );

        // Set swap amount (10% of input reserve)
        uint256 swapAmount = reserveA / 10;

        // Calculate expected output using 5-parameter version (B→A)
        uint256 expectedAmountOut = ConstProdUtils._saleQuote(swapAmount, reserveA, reserveB, feePercent, 100_000);

        // Mint input tokens and perform actual swap B→A
        camelotBalancedTokenB.mint(address(this), swapAmount);
        uint256 initialBalanceA = camelotBalancedTokenA.balanceOf(address(this));

        // Execute actual swap B→A
        camelotBalancedTokenB.approve(address(camV2Router()), swapAmount);
        ICamelotV2Router(camV2Router())
            .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                swapAmount,
                0, // accept any amount of output tokens
                _getPath(address(camelotBalancedTokenB), address(camelotBalancedTokenA)),
                address(this),
                address(0), // referrer
                block.timestamp + 300 // deadline
            );
        uint256 actualAmountOut = camelotBalancedTokenA.balanceOf(address(this)) - initialBalanceA;

        // Validate results
        assertEq(actualAmountOut, expectedAmountOut, "Expected vs Actual mismatch");
        assertEq(
            camelotBalancedTokenA.balanceOf(address(this)) - initialBalanceA,
            actualAmountOut,
            "Balance change should match"
        );

        // console.log("_saleQuote Camelot balanced pool B->A test passed:");
        // console.log("  ReserveA:", reserveA);
        // console.log("  ReserveB:", reserveB);
        // console.log("  Swap Amount:", swapAmount);
        // console.log("  Fee Percent:", feePercent);
        // console.log("  Expected AmountOut:", expectedAmountOut);
        // console.log("  Actual AmountOut:", actualAmountOut);
    }

    function test_saleQuote_Camelot_unbalancedPool_sellsTokenB() public {
        // Get reserves and sort them properly
        (uint112 reserve0, uint112 reserve1, uint16 token0Fee, uint16 token1Fee) = camelotUnbalancedPair.getReserves();
        (uint256 reserveA, uint256 feePercent, uint256 reserveB,) = ConstProdUtils._sortReserves(
            address(camelotUnbalancedTokenB),
            camelotUnbalancedPair.token0(),
            reserve0,
            uint256(token0Fee),
            reserve1,
            uint256(token1Fee)
        );

        // Set swap amount (10% of input reserve)
        uint256 swapAmount = reserveA / 10;

        // Calculate expected output using 5-parameter version (B→A)
        uint256 expectedAmountOut = ConstProdUtils._saleQuote(swapAmount, reserveA, reserveB, feePercent, 100_000);

        // Mint input tokens and perform actual swap B→A
        camelotUnbalancedTokenB.mint(address(this), swapAmount);
        uint256 initialBalanceA = camelotUnbalancedTokenA.balanceOf(address(this));

        // Execute actual swap B→A
        camelotUnbalancedTokenB.approve(address(camV2Router()), swapAmount);
        ICamelotV2Router(camV2Router())
            .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                swapAmount,
                0, // accept any amount of output tokens
                _getPath(address(camelotUnbalancedTokenB), address(camelotUnbalancedTokenA)),
                address(this),
                address(0), // referrer
                block.timestamp + 300 // deadline
            );
        uint256 actualAmountOut = camelotUnbalancedTokenA.balanceOf(address(this)) - initialBalanceA;

        // Validate results
        assertEq(actualAmountOut, expectedAmountOut, "Expected vs Actual mismatch");
        assertEq(
            camelotUnbalancedTokenA.balanceOf(address(this)) - initialBalanceA,
            actualAmountOut,
            "Balance change should match"
        );

        // console.log("_saleQuote Camelot unbalanced pool B->A test passed:");
        // console.log("  ReserveA:", reserveA);
        // console.log("  ReserveB:", reserveB);
        // console.log("  Swap Amount:", swapAmount);
        // console.log("  Fee Percent:", feePercent);
        // console.log("  Expected AmountOut:", expectedAmountOut);
        // console.log("  Actual AmountOut:", actualAmountOut);
    }

    function test_saleQuote_Camelot_extremeUnbalancedPool_sellsTokenB() public {
        // Get reserves and sort them properly
        (uint112 reserve0, uint112 reserve1, uint16 token0Fee, uint16 token1Fee) =
            camelotExtremeUnbalancedPair.getReserves();
        (uint256 reserveA, uint256 feePercent, uint256 reserveB,) = ConstProdUtils._sortReserves(
            address(camelotExtremeTokenB),
            camelotExtremeUnbalancedPair.token0(),
            reserve0,
            uint256(token0Fee),
            reserve1,
            uint256(token1Fee)
        );

        // Set swap amount (10% of input reserve)
        uint256 swapAmount = reserveA / 10;

        // Calculate expected output using 5-parameter version (B→A)
        uint256 expectedAmountOut = ConstProdUtils._saleQuote(swapAmount, reserveA, reserveB, feePercent, 100_000);

        // Mint input tokens and perform actual swap B→A
        camelotExtremeTokenB.mint(address(this), swapAmount);
        uint256 initialBalanceA = camelotExtremeTokenA.balanceOf(address(this));

        // Execute actual swap B→A
        camelotExtremeTokenB.approve(address(camV2Router()), swapAmount);
        ICamelotV2Router(camV2Router())
            .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                swapAmount,
                0, // accept any amount of output tokens
                _getPath(address(camelotExtremeTokenB), address(camelotExtremeTokenA)),
                address(this),
                address(0), // referrer
                block.timestamp + 300 // deadline
            );
        uint256 actualAmountOut = camelotExtremeTokenA.balanceOf(address(this)) - initialBalanceA;

        // Validate results
        assertEq(actualAmountOut, expectedAmountOut, "Expected vs Actual mismatch");
        assertEq(
            camelotExtremeTokenA.balanceOf(address(this)) - initialBalanceA,
            actualAmountOut,
            "Balance change should match"
        );

        // console.log("_saleQuote Camelot extreme unbalanced pool B->A test passed:");
        // console.log("  ReserveA:", reserveA);
        // console.log("  ReserveB:", reserveB);
        // console.log("  Swap Amount:", swapAmount);
        // console.log("  Fee Percent:", feePercent);
        // console.log("  Expected AmountOut:", expectedAmountOut);
        // console.log("  Actual AmountOut:", actualAmountOut);
    }

    function test_saleQuote_Uniswap_balancedPool_sellsTokenB() public {
        // Get reserves and sort them properly
        (uint112 reserve0, uint112 reserve1,) = uniswapBalancedPair.getReserves();
        (uint256 reserveA, uint256 feePercent, uint256 reserveB,) = ConstProdUtils._sortReserves(
            address(uniswapBalancedTokenB), uniswapBalancedPair.token0(), reserve0, 300, reserve1, 300
        );

        // Set swap amount (10% of input reserve)
        uint256 swapAmount = reserveA / 10;

        // Calculate expected output using 5-parameter version (B→A)
        uint256 expectedAmountOut = ConstProdUtils._saleQuote(swapAmount, reserveA, reserveB, feePercent, 100_000);

        // Mint input tokens and perform actual swap B→A
        uniswapBalancedTokenB.mint(address(this), swapAmount);
        uint256 initialBalanceA = uniswapBalancedTokenA.balanceOf(address(this));

        // Execute actual swap B→A
        uniswapBalancedTokenB.approve(address(uniswapV2Router()), swapAmount);
        IUniswapV2Router(address(uniswapV2Router()))
            .swapExactTokensForTokens(
                swapAmount,
                0, // accept any amount of output tokens
                _getPath(address(uniswapBalancedTokenB), address(uniswapBalancedTokenA)),
                address(this),
                block.timestamp
            );
        uint256 actualAmountOut = uniswapBalancedTokenA.balanceOf(address(this)) - initialBalanceA;

        // Validate results
        assertEq(actualAmountOut, expectedAmountOut, "Expected vs Actual mismatch");
        assertEq(
            uniswapBalancedTokenA.balanceOf(address(this)) - initialBalanceA,
            actualAmountOut,
            "Balance change should match"
        );

        // console.log("_saleQuote Uniswap balanced pool B->A test passed:");
        // console.log("  ReserveA:", reserveA);
        // console.log("  ReserveB:", reserveB);
        // console.log("  Swap Amount:", swapAmount);
        // console.log("  Fee Percent:", feePercent);
        // console.log("  Expected AmountOut:", expectedAmountOut);
        // console.log("  Actual AmountOut:", actualAmountOut);
    }

    function test_saleQuote_Uniswap_unbalancedPool_sellsTokenB() public {
        // Get reserves and sort them properly
        (uint112 reserve0, uint112 reserve1,) = uniswapUnbalancedPair.getReserves();
        (uint256 reserveA, uint256 feePercent, uint256 reserveB,) = ConstProdUtils._sortReserves(
            address(uniswapUnbalancedTokenB), uniswapUnbalancedPair.token0(), reserve0, 300, reserve1, 300
        );

        // Set swap amount (10% of input reserve)
        uint256 swapAmount = reserveA / 10;

        // Calculate expected output using 5-parameter version (B→A)
        uint256 expectedAmountOut = ConstProdUtils._saleQuote(swapAmount, reserveA, reserveB, feePercent, 100_000);

        // Mint input tokens and perform actual swap B→A
        uniswapUnbalancedTokenB.mint(address(this), swapAmount);
        uint256 initialBalanceA = uniswapUnbalancedTokenA.balanceOf(address(this));

        // Execute actual swap B→A
        uniswapUnbalancedTokenB.approve(address(uniswapV2Router()), swapAmount);
        IUniswapV2Router(address(uniswapV2Router()))
            .swapExactTokensForTokens(
                swapAmount,
                0, // accept any amount of output tokens
                _getPath(address(uniswapUnbalancedTokenB), address(uniswapUnbalancedTokenA)),
                address(this),
                block.timestamp
            );
        uint256 actualAmountOut = uniswapUnbalancedTokenA.balanceOf(address(this)) - initialBalanceA;

        // Validate results
        assertEq(actualAmountOut, expectedAmountOut, "Expected vs Actual mismatch");
        assertEq(
            uniswapUnbalancedTokenA.balanceOf(address(this)) - initialBalanceA,
            actualAmountOut,
            "Balance change should match"
        );

        // console.log("_saleQuote Uniswap unbalanced pool B->A test passed:");
        // console.log("  ReserveA:", reserveA);
        // console.log("  ReserveB:", reserveB);
        // console.log("  Swap Amount:", swapAmount);
        // console.log("  Fee Percent:", feePercent);
        // console.log("  Expected AmountOut:", expectedAmountOut);
        // console.log("  Actual AmountOut:", actualAmountOut);
    }

    function test_saleQuote_Uniswap_extremeUnbalancedPool_sellsTokenB() public {
        // Get reserves and sort them properly
        (uint112 reserve0, uint112 reserve1,) = uniswapExtremeUnbalancedPair.getReserves();
        (uint256 reserveA, uint256 feePercent, uint256 reserveB,) = ConstProdUtils._sortReserves(
            address(uniswapExtremeTokenB), uniswapExtremeUnbalancedPair.token0(), reserve0, 300, reserve1, 300
        );

        // Set swap amount (10% of input reserve)
        uint256 swapAmount = reserveA / 10;

        // Calculate expected output using 5-parameter version (B→A)
        uint256 expectedAmountOut = ConstProdUtils._saleQuote(swapAmount, reserveA, reserveB, feePercent, 100_000);

        // Mint input tokens and perform actual swap B→A
        uniswapExtremeTokenB.mint(address(this), swapAmount);
        uint256 initialBalanceA = uniswapExtremeTokenA.balanceOf(address(this));

        // Execute actual swap B→A
        uniswapExtremeTokenB.approve(address(uniswapV2Router()), swapAmount);
        IUniswapV2Router(address(uniswapV2Router()))
            .swapExactTokensForTokens(
                swapAmount,
                0, // accept any amount of output tokens
                _getPath(address(uniswapExtremeTokenB), address(uniswapExtremeTokenA)),
                address(this),
                block.timestamp
            );
        uint256 actualAmountOut = uniswapExtremeTokenA.balanceOf(address(this)) - initialBalanceA;

        // Validate results
        assertEq(actualAmountOut, expectedAmountOut, "Expected vs Actual mismatch");
        assertEq(
            uniswapExtremeTokenA.balanceOf(address(this)) - initialBalanceA,
            actualAmountOut,
            "Balance change should match"
        );

        // console.log("_saleQuote Uniswap extreme unbalanced pool B->A test passed:");
        // console.log("  ReserveA:", reserveA);
        // console.log("  ReserveB:", reserveB);
        // console.log("  Swap Amount:", swapAmount);
        // console.log("  Fee Percent:", feePercent);
        // console.log("  Expected AmountOut:", expectedAmountOut);
        // console.log("  Actual AmountOut:", actualAmountOut);
    }
}
