// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {betterconsole as console} from "contracts/crane/utils/vm/foundry/tools/betterconsole.sol";
import {TestBase_ConstProdUtils} from "./TestBase_ConstProdUtils.sol";
import {ConstProdUtils} from "contracts/crane/utils/math/ConstProdUtils.sol";
import {ICamelotV2Router} from "contracts/crane/interfaces/protocols/dexes/camelot/v2/ICamelotV2Router.sol";
import {IUniswapV2Router} from "contracts/crane/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Router.sol";

/**
 * @title Test_ConstProdUtils_purchaseQuote
 * @dev Comprehensive expected vs actual validation tests for ConstProdUtils._purchaseQuote
 * @notice Tests both 4-parameter and 5-parameter overloads across all pool types and protocols
 */
contract Test_ConstProdUtils_purchaseQuote is TestBase_ConstProdUtils {
    function setUp() public override {
        super.setUp();
    }

    // Helper function to create swap path
    // function _getPath(address tokenIn, address tokenOut) internal pure returns (address[] memory path) {
    //     path = new address[](2);
    //     path[0] = tokenIn;
    //     path[1] = tokenOut;
    // }

    // ========================================
    // 4-PARAMETER VERSION TESTS (A->B Direction)
    // ========================================

    function test_purchaseQuote_Camelot_balancedPool_purchasesTokenB() public {
        (uint112 reserve0, uint112 reserve1, uint16 token0Fee, uint16 token1Fee) = camelotBalancedPair.getReserves();
        (uint256 reserveA, uint256 feePercent, uint256 reserveB, uint256 tokenBFee) = ConstProdUtils._sortReserves(
            address(camelotBalancedTokenA),
            camelotBalancedPair.token0(),
            reserve0,
            uint256(token0Fee),
            reserve1,
            uint256(token1Fee)
        );

        // Desired output: 10% of TokenB reserve (slightly reduced to account for rounding)
        uint256 desiredOutput = (reserveB / 10) - 1;

        // Calculate expected input using ConstProdUtils
        uint256 expectedInput = ConstProdUtils._purchaseQuote(desiredOutput, reserveA, reserveB, feePercent);

        // Mint the calculated input amount
        camelotBalancedTokenA.mint(address(this), expectedInput);
        uint256 initialBalanceB = camelotBalancedTokenB.balanceOf(address(this));

        // Perform actual swap
        camelotBalancedTokenA.approve(address(camV2Router()), expectedInput);
        ICamelotV2Router(camV2Router())
            .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                expectedInput,
                0, // accept any amount of output tokens
                _getPath(address(camelotBalancedTokenA), address(camelotBalancedTokenB)),
                address(this),
                address(0), // referrer
                block.timestamp + 300 // deadline
            );
        uint256 actualOutput = camelotBalancedTokenB.balanceOf(address(this)) - initialBalanceB;

        // Verify we get at least 99.9% of the desired output (accounting for rounding and fees)
        uint256 minExpectedOutput = (desiredOutput * 999) / 1000;
        assertGe(actualOutput, minExpectedOutput, "Should get at least 99.9% of desired output");
        // Note: actualOutput may be slightly less than desiredOutput due to rounding and fees

        // console.log("Expected input:", expectedInput);
        // console.log("Actual output:", actualOutput);
        // console.log("Desired output:", desiredOutput);
    }

    function test_purchaseQuote_Camelot_unbalancedPool_purchasesTokenB() public {
        (uint112 reserve0, uint112 reserve1, uint16 token0Fee, uint16 token1Fee) = camelotUnbalancedPair.getReserves();
        (uint256 reserveA, uint256 feePercent, uint256 reserveB, uint256 tokenBFee) = ConstProdUtils._sortReserves(
            address(camelotUnbalancedTokenA),
            camelotUnbalancedPair.token0(),
            reserve0,
            uint256(token0Fee),
            reserve1,
            uint256(token1Fee)
        );

        // Desired output: 5% of TokenB reserve (slightly reduced to account for rounding)
        uint256 desiredOutput = (reserveB / 20) - 1;

        uint256 expectedInput = ConstProdUtils._purchaseQuote(desiredOutput, reserveA, reserveB, feePercent);

        camelotUnbalancedTokenA.mint(address(this), expectedInput);
        uint256 initialBalanceB = camelotUnbalancedTokenB.balanceOf(address(this));

        camelotUnbalancedTokenA.approve(address(camV2Router()), expectedInput);
        ICamelotV2Router(camV2Router())
            .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                expectedInput,
                0, // accept any amount of output tokens
                _getPath(address(camelotUnbalancedTokenA), address(camelotUnbalancedTokenB)),
                address(this),
                address(0), // referrer
                block.timestamp + 300 // deadline
            );
        uint256 actualOutput = camelotUnbalancedTokenB.balanceOf(address(this)) - initialBalanceB;

        // Verify we get at least 99.9% of the desired output (accounting for rounding and fees)
        uint256 minExpectedOutput = (desiredOutput * 999) / 1000;
        assertGe(actualOutput, minExpectedOutput, "Should get at least 99.9% of desired output");
        // Note: actualOutput may be slightly less than desiredOutput due to rounding and fees

        // console.log("Expected input:", expectedInput);
        // console.log("Actual output:", actualOutput);
        // console.log("Desired output:", desiredOutput);
    }

    function test_purchaseQuote_Camelot_extremeUnbalancedPool_purchasesTokenB() public {
        (uint112 reserve0, uint112 reserve1, uint16 token0Fee, uint16 token1Fee) =
            camelotExtremeUnbalancedPair.getReserves();
        (uint256 reserveA, uint256 feePercent, uint256 reserveB, uint256 tokenBFee) = ConstProdUtils._sortReserves(
            address(camelotExtremeTokenA),
            camelotExtremeUnbalancedPair.token0(),
            reserve0,
            uint256(token0Fee),
            reserve1,
            uint256(token1Fee)
        );

        // Desired output: 1% of TokenB reserve (slightly reduced to account for rounding)
        uint256 desiredOutput = (reserveB / 100) - 1;

        uint256 expectedInput = ConstProdUtils._purchaseQuote(desiredOutput, reserveA, reserveB, feePercent);

        camelotExtremeTokenA.mint(address(this), expectedInput);
        uint256 initialBalanceB = camelotExtremeTokenB.balanceOf(address(this));

        camelotExtremeTokenA.approve(address(camV2Router()), expectedInput);
        ICamelotV2Router(camV2Router())
            .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                expectedInput,
                0, // accept any amount of output tokens
                _getPath(address(camelotExtremeTokenA), address(camelotExtremeTokenB)),
                address(this),
                address(0), // referrer
                block.timestamp + 300 // deadline
            );
        uint256 actualOutput = camelotExtremeTokenB.balanceOf(address(this)) - initialBalanceB;

        // Verify we get at least 99.9% of the desired output (accounting for rounding and fees)
        uint256 minExpectedOutput = (desiredOutput * 999) / 1000;
        assertGe(actualOutput, minExpectedOutput, "Should get at least 99.9% of desired output");
        // Note: actualOutput may be slightly less than desiredOutput due to rounding and fees

        console.log("Expected input:", expectedInput);
        console.log("Actual output:", actualOutput);
        console.log("Desired output:", desiredOutput);
    }

    function test_purchaseQuote_Uniswap_balancedPool_purchasesTokenB() public {
        (uint112 reserve0, uint112 reserve1,) = uniswapBalancedPair.getReserves();
        (uint256 reserveA, uint256 feePercent, uint256 reserveB, uint256 tokenBFee) = ConstProdUtils._sortReserves(
            address(uniswapBalancedTokenA), uniswapBalancedPair.token0(), reserve0, 300, reserve1, 300
        );

        // Desired output: 10% of TokenB reserve (slightly reduced to account for rounding)
        uint256 desiredOutput = (reserveB / 10) - 1;

        uint256 expectedInput = ConstProdUtils._purchaseQuote(desiredOutput, reserveA, reserveB, feePercent);

        uniswapBalancedTokenA.mint(address(this), expectedInput);
        uint256 initialBalanceB = uniswapBalancedTokenB.balanceOf(address(this));

        uniswapBalancedTokenA.approve(address(uniswapV2Router()), expectedInput);
        IUniswapV2Router(address(uniswapV2Router()))
            .swapExactTokensForTokens(
                expectedInput,
                0, // accept any amount of output tokens
                _getPath(address(uniswapBalancedTokenA), address(uniswapBalancedTokenB)),
                address(this),
                block.timestamp + 300
            );
        uint256 actualOutput = uniswapBalancedTokenB.balanceOf(address(this)) - initialBalanceB;

        // Verify we get at least 99.9% of the desired output (accounting for rounding and fees)
        uint256 minExpectedOutput = (desiredOutput * 999) / 1000;
        assertGe(actualOutput, minExpectedOutput, "Should get at least 99.9% of desired output");
        // Note: actualOutput may be slightly less than desiredOutput due to rounding and fees

        console.log("Expected input:", expectedInput);
        console.log("Actual output:", actualOutput);
        console.log("Desired output:", desiredOutput);
    }

    function test_purchaseQuote_Uniswap_unbalancedPool_purchasesTokenB() public {
        (uint112 reserve0, uint112 reserve1,) = uniswapUnbalancedPair.getReserves();
        (uint256 reserveA, uint256 feePercent, uint256 reserveB, uint256 tokenBFee) = ConstProdUtils._sortReserves(
            address(uniswapUnbalancedTokenA), uniswapUnbalancedPair.token0(), reserve0, 300, reserve1, 300
        );

        // Desired output: 5% of TokenB reserve
        uint256 desiredOutput = reserveB / 20;

        uint256 expectedInput = ConstProdUtils._purchaseQuote(desiredOutput, reserveA, reserveB, feePercent);

        uniswapUnbalancedTokenA.mint(address(this), expectedInput);
        uint256 initialBalanceB = uniswapUnbalancedTokenB.balanceOf(address(this));

        uniswapUnbalancedTokenA.approve(address(uniswapV2Router()), expectedInput);
        IUniswapV2Router(address(uniswapV2Router()))
            .swapExactTokensForTokens(
                expectedInput,
                0, // accept any amount of output tokens
                _getPath(address(uniswapUnbalancedTokenA), address(uniswapUnbalancedTokenB)),
                address(this),
                block.timestamp + 300
            );
        uint256 actualOutput = uniswapUnbalancedTokenB.balanceOf(address(this)) - initialBalanceB;

        // Verify we get at least 99.9% of the desired output (accounting for rounding and fees)
        uint256 minExpectedOutput = (desiredOutput * 999) / 1000;
        assertGe(actualOutput, minExpectedOutput, "Should get at least 99.9% of desired output");
        // Note: actualOutput may be slightly less than desiredOutput due to rounding and fees

        console.log("Expected input:", expectedInput);
        console.log("Actual output:", actualOutput);
        console.log("Desired output:", desiredOutput);
    }

    function test_purchaseQuote_Uniswap_extremeUnbalancedPool_purchasesTokenB() public {
        (uint112 reserve0, uint112 reserve1,) = uniswapExtremeUnbalancedPair.getReserves();
        (uint256 reserveA, uint256 feePercent, uint256 reserveB, uint256 tokenBFee) = ConstProdUtils._sortReserves(
            address(uniswapExtremeTokenA), uniswapExtremeUnbalancedPair.token0(), reserve0, 300, reserve1, 300
        );

        // Desired output: 1% of TokenB reserve
        uint256 desiredOutput = reserveB / 100;

        uint256 expectedInput = ConstProdUtils._purchaseQuote(desiredOutput, reserveA, reserveB, feePercent);

        uniswapExtremeTokenA.mint(address(this), expectedInput);
        uint256 initialBalanceB = uniswapExtremeTokenB.balanceOf(address(this));

        uniswapExtremeTokenA.approve(address(uniswapV2Router()), expectedInput);
        IUniswapV2Router(address(uniswapV2Router()))
            .swapExactTokensForTokens(
                expectedInput,
                0, // accept any amount of output tokens
                _getPath(address(uniswapExtremeTokenA), address(uniswapExtremeTokenB)),
                address(this),
                block.timestamp + 300
            );
        uint256 actualOutput = uniswapExtremeTokenB.balanceOf(address(this)) - initialBalanceB;

        // Verify we get at least 99.9% of the desired output (accounting for rounding and fees)
        uint256 minExpectedOutput = (desiredOutput * 999) / 1000;
        assertGe(actualOutput, minExpectedOutput, "Should get at least 99.9% of desired output");
        // Note: actualOutput may be slightly less than desiredOutput due to rounding and fees

        console.log("Expected input:", expectedInput);
        console.log("Actual output:", actualOutput);
        console.log("Desired output:", desiredOutput);
    }

    // ========================================
    // 4-PARAMETER VERSION TESTS (B->A Direction)
    // ========================================

    function test_purchaseQuote_Camelot_balancedPool_purchasesTokenA() public {
        (uint112 reserve0, uint112 reserve1, uint16 token0Fee, uint16 token1Fee) = camelotBalancedPair.getReserves();
        (uint256 reserveA, uint256 feePercent, uint256 reserveB, uint256 tokenBFee) = ConstProdUtils._sortReserves(
            address(camelotBalancedTokenB),
            camelotBalancedPair.token0(),
            reserve0,
            uint256(token0Fee),
            reserve1,
            uint256(token1Fee)
        );

        // Desired output: 10% of TokenA reserve (B->A direction, slightly reduced to account for rounding)
        uint256 desiredOutput = (reserveA / 10) - 1;

        uint256 expectedInput = ConstProdUtils._purchaseQuote(desiredOutput, reserveB, reserveA, feePercent);

        camelotBalancedTokenB.mint(address(this), expectedInput);
        uint256 initialBalanceA = camelotBalancedTokenA.balanceOf(address(this));

        camelotBalancedTokenB.approve(address(camV2Router()), expectedInput);
        ICamelotV2Router(camV2Router())
            .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                expectedInput,
                0, // accept any amount of output tokens
                _getPath(address(camelotBalancedTokenB), address(camelotBalancedTokenA)),
                address(this),
                address(0), // referrer
                block.timestamp + 300 // deadline
            );
        uint256 actualOutput = camelotBalancedTokenA.balanceOf(address(this)) - initialBalanceA;

        // Verify we get at least 99.9% of the desired output (accounting for rounding and fees)
        uint256 minExpectedOutput = (desiredOutput * 999) / 1000;
        assertGe(actualOutput, minExpectedOutput, "Should get at least 99.9% of desired output");
        // Note: actualOutput may be slightly less than desiredOutput due to rounding and fees

        console.log("Expected input:", expectedInput);
        console.log("Actual output:", actualOutput);
        console.log("Desired output:", desiredOutput);
    }

    function test_purchaseQuote_Camelot_unbalancedPool_purchasesTokenA() public {
        (uint112 reserve0, uint112 reserve1, uint16 token0Fee, uint16 token1Fee) = camelotUnbalancedPair.getReserves();
        (uint256 reserveA, uint256 feePercent, uint256 reserveB, uint256 tokenBFee) = ConstProdUtils._sortReserves(
            address(camelotUnbalancedTokenB),
            camelotUnbalancedPair.token0(),
            reserve0,
            uint256(token0Fee),
            reserve1,
            uint256(token1Fee)
        );

        // Desired output: 5% of TokenA reserve (B->A direction, slightly reduced to account for rounding)
        uint256 desiredOutput = (reserveA / 20) - 1;

        uint256 expectedInput = ConstProdUtils._purchaseQuote(desiredOutput, reserveB, reserveA, feePercent);

        camelotUnbalancedTokenB.mint(address(this), expectedInput);
        uint256 initialBalanceA = camelotUnbalancedTokenA.balanceOf(address(this));

        camelotUnbalancedTokenB.approve(address(camV2Router()), expectedInput);
        ICamelotV2Router(camV2Router())
            .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                expectedInput,
                0, // accept any amount of output tokens
                _getPath(address(camelotUnbalancedTokenB), address(camelotUnbalancedTokenA)),
                address(this),
                address(0), // referrer
                block.timestamp + 300 // deadline
            );
        uint256 actualOutput = camelotUnbalancedTokenA.balanceOf(address(this)) - initialBalanceA;

        // Verify we get at least 99.9% of the desired output (accounting for rounding and fees)
        uint256 minExpectedOutput = (desiredOutput * 999) / 1000;
        assertGe(actualOutput, minExpectedOutput, "Should get at least 99.9% of desired output");
        // Note: actualOutput may be slightly less than desiredOutput due to rounding and fees

        console.log("Expected input:", expectedInput);
        console.log("Actual output:", actualOutput);
        console.log("Desired output:", desiredOutput);
    }

    function test_purchaseQuote_Camelot_extremeUnbalancedPool_purchasesTokenA() public {
        (uint112 reserve0, uint112 reserve1, uint16 token0Fee, uint16 token1Fee) =
            camelotExtremeUnbalancedPair.getReserves();
        (uint256 reserveA, uint256 feePercent, uint256 reserveB, uint256 tokenBFee) = ConstProdUtils._sortReserves(
            address(camelotExtremeTokenB),
            camelotExtremeUnbalancedPair.token0(),
            reserve0,
            uint256(token0Fee),
            reserve1,
            uint256(token1Fee)
        );

        // Desired output: 1% of TokenA reserve (B->A direction, slightly reduced to account for rounding)
        uint256 desiredOutput = (reserveA / 100) - 1;

        uint256 expectedInput = ConstProdUtils._purchaseQuote(desiredOutput, reserveB, reserveA, feePercent);

        camelotExtremeTokenB.mint(address(this), expectedInput);
        uint256 initialBalanceA = camelotExtremeTokenA.balanceOf(address(this));

        camelotExtremeTokenB.approve(address(camV2Router()), expectedInput);
        ICamelotV2Router(camV2Router())
            .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                expectedInput,
                0, // accept any amount of output tokens
                _getPath(address(camelotExtremeTokenB), address(camelotExtremeTokenA)),
                address(this),
                address(0), // referrer
                block.timestamp + 300 // deadline
            );
        uint256 actualOutput = camelotExtremeTokenA.balanceOf(address(this)) - initialBalanceA;

        // Verify we get at least 99.9% of the desired output (accounting for rounding and fees)
        uint256 minExpectedOutput = (desiredOutput * 999) / 1000;
        assertGe(actualOutput, minExpectedOutput, "Should get at least 99.9% of desired output");
        // Note: actualOutput may be slightly less than desiredOutput due to rounding and fees

        console.log("Expected input:", expectedInput);
        console.log("Actual output:", actualOutput);
        console.log("Desired output:", desiredOutput);
    }

    function test_purchaseQuote_Uniswap_balancedPool_purchasesTokenA() public {
        (uint112 reserve0, uint112 reserve1,) = uniswapBalancedPair.getReserves();
        (uint256 reserveA, uint256 feePercent, uint256 reserveB, uint256 tokenBFee) = ConstProdUtils._sortReserves(
            address(uniswapBalancedTokenB), uniswapBalancedPair.token0(), reserve0, 300, reserve1, 300
        );

        // Desired output: 10% of TokenA reserve (B->A direction, slightly reduced to account for rounding)
        uint256 desiredOutput = (reserveA / 10) - 1;

        uint256 expectedInput = ConstProdUtils._purchaseQuote(desiredOutput, reserveB, reserveA, feePercent);

        uniswapBalancedTokenB.mint(address(this), expectedInput);
        uint256 initialBalanceA = uniswapBalancedTokenA.balanceOf(address(this));

        uniswapBalancedTokenB.approve(address(uniswapV2Router()), expectedInput);
        IUniswapV2Router(address(uniswapV2Router()))
            .swapExactTokensForTokens(
                expectedInput,
                0, // accept any amount of output tokens
                _getPath(address(uniswapBalancedTokenB), address(uniswapBalancedTokenA)),
                address(this),
                block.timestamp + 300
            );
        uint256 actualOutput = uniswapBalancedTokenA.balanceOf(address(this)) - initialBalanceA;

        // Verify we get at least 99.9% of the desired output (accounting for rounding and fees)
        uint256 minExpectedOutput = (desiredOutput * 999) / 1000;
        assertGe(actualOutput, minExpectedOutput, "Should get at least 99.9% of desired output");
        // Note: actualOutput may be slightly less than desiredOutput due to rounding and fees

        console.log("Expected input:", expectedInput);
        console.log("Actual output:", actualOutput);
        console.log("Desired output:", desiredOutput);
    }

    function test_purchaseQuote_Uniswap_unbalancedPool_purchasesTokenA() public {
        (uint112 reserve0, uint112 reserve1,) = uniswapUnbalancedPair.getReserves();
        (uint256 reserveA, uint256 feePercent, uint256 reserveB, uint256 tokenBFee) = ConstProdUtils._sortReserves(
            address(uniswapUnbalancedTokenB), uniswapUnbalancedPair.token0(), reserve0, 300, reserve1, 300
        );

        // Desired output: 5% of TokenA reserve (B->A direction, slightly reduced to account for rounding)
        uint256 desiredOutput = (reserveA / 20) - 1;

        uint256 expectedInput = ConstProdUtils._purchaseQuote(desiredOutput, reserveB, reserveA, feePercent);

        uniswapUnbalancedTokenB.mint(address(this), expectedInput);
        uint256 initialBalanceA = uniswapUnbalancedTokenA.balanceOf(address(this));

        uniswapUnbalancedTokenB.approve(address(uniswapV2Router()), expectedInput);
        IUniswapV2Router(address(uniswapV2Router()))
            .swapExactTokensForTokens(
                expectedInput,
                0, // accept any amount of output tokens
                _getPath(address(uniswapUnbalancedTokenB), address(uniswapUnbalancedTokenA)),
                address(this),
                block.timestamp + 300
            );
        uint256 actualOutput = uniswapUnbalancedTokenA.balanceOf(address(this)) - initialBalanceA;

        // Verify we get at least 99.9% of the desired output (accounting for rounding and fees)
        uint256 minExpectedOutput = (desiredOutput * 999) / 1000;
        assertGe(actualOutput, minExpectedOutput, "Should get at least 99.9% of desired output");
        // Note: actualOutput may be slightly less than desiredOutput due to rounding and fees

        console.log("Expected input:", expectedInput);
        console.log("Actual output:", actualOutput);
        console.log("Desired output:", desiredOutput);
    }

    function test_purchaseQuote_Uniswap_extremeUnbalancedPool_purchasesTokenA() public {
        (uint112 reserve0, uint112 reserve1,) = uniswapExtremeUnbalancedPair.getReserves();
        (uint256 reserveA, uint256 feePercent, uint256 reserveB, uint256 tokenBFee) = ConstProdUtils._sortReserves(
            address(uniswapExtremeTokenB), uniswapExtremeUnbalancedPair.token0(), reserve0, 300, reserve1, 300
        );

        // Desired output: 1% of TokenA reserve (B->A direction, slightly reduced to account for rounding)
        uint256 desiredOutput = (reserveA / 100) - 1;

        uint256 expectedInput = ConstProdUtils._purchaseQuote(desiredOutput, reserveB, reserveA, feePercent);

        uniswapExtremeTokenB.mint(address(this), expectedInput);
        uint256 initialBalanceA = uniswapExtremeTokenA.balanceOf(address(this));

        uniswapExtremeTokenB.approve(address(uniswapV2Router()), expectedInput);
        IUniswapV2Router(address(uniswapV2Router()))
            .swapExactTokensForTokens(
                expectedInput,
                0, // accept any amount of output tokens
                _getPath(address(uniswapExtremeTokenB), address(uniswapExtremeTokenA)),
                address(this),
                block.timestamp + 300
            );
        uint256 actualOutput = uniswapExtremeTokenA.balanceOf(address(this)) - initialBalanceA;

        // Verify we get at least 99.9% of the desired output (accounting for rounding and fees)
        uint256 minExpectedOutput = (desiredOutput * 999) / 1000;
        assertGe(actualOutput, minExpectedOutput, "Should get at least 99.9% of desired output");
        // Note: actualOutput may be slightly less than desiredOutput due to rounding and fees

        console.log("Expected input:", expectedInput);
        console.log("Actual output:", actualOutput);
        console.log("Desired output:", desiredOutput);
    }

    // ========================================
    // 5-PARAMETER VERSION TESTS (A->B Direction)
    // ========================================

    function test_purchaseQuote_Camelot_balancedPool_5param_purchasesTokenB() public {
        (uint112 reserve0, uint112 reserve1, uint16 token0Fee, uint16 token1Fee) = camelotBalancedPair.getReserves();
        (uint256 reserveA, uint256 feePercent, uint256 reserveB, uint256 tokenBFee) = ConstProdUtils._sortReserves(
            address(camelotBalancedTokenA),
            camelotBalancedPair.token0(),
            reserve0,
            uint256(token0Fee),
            reserve1,
            uint256(token1Fee)
        );
        uint256 feeDenominator = 100_000;

        // Desired output: 10% of TokenB reserve (slightly reduced to account for rounding)
        uint256 desiredOutput = (reserveB / 10) - 1;

        uint256 expectedInput =
            ConstProdUtils._purchaseQuote(desiredOutput, reserveA, reserveB, feePercent, feeDenominator);

        camelotBalancedTokenA.mint(address(this), expectedInput);
        uint256 initialBalanceB = camelotBalancedTokenB.balanceOf(address(this));

        camelotBalancedTokenA.approve(address(camV2Router()), expectedInput);
        ICamelotV2Router(camV2Router())
            .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                expectedInput,
                0, // accept any amount of output tokens
                _getPath(address(camelotBalancedTokenA), address(camelotBalancedTokenB)),
                address(this),
                address(0), // referrer
                block.timestamp + 300 // deadline
            );
        uint256 actualOutput = camelotBalancedTokenB.balanceOf(address(this)) - initialBalanceB;

        // Verify we get at least 99.9% of the desired output (accounting for rounding and fees)
        uint256 minExpectedOutput = (desiredOutput * 999) / 1000;
        assertGe(actualOutput, minExpectedOutput, "Should get at least 99.9% of desired output");
        // Note: actualOutput may be slightly less than desiredOutput due to rounding and fees

        console.log("Expected input (5-param):", expectedInput);
        console.log("Actual output:", actualOutput);
        console.log("Desired output:", desiredOutput);
    }

    function test_purchaseQuote_Camelot_unbalancedPool_5param_purchasesTokenB() public {
        (uint112 reserve0, uint112 reserve1, uint16 token0Fee, uint16 token1Fee) = camelotUnbalancedPair.getReserves();
        (uint256 reserveA, uint256 feePercent, uint256 reserveB, uint256 tokenBFee) = ConstProdUtils._sortReserves(
            address(camelotUnbalancedTokenA),
            camelotUnbalancedPair.token0(),
            reserve0,
            uint256(token0Fee),
            reserve1,
            uint256(token1Fee)
        );
        uint256 feeDenominator = 100_000;

        // Desired output: 5% of TokenB reserve
        uint256 desiredOutput = reserveB / 20;

        uint256 expectedInput =
            ConstProdUtils._purchaseQuote(desiredOutput, reserveA, reserveB, feePercent, feeDenominator);

        camelotUnbalancedTokenA.mint(address(this), expectedInput);
        uint256 initialBalanceB = camelotUnbalancedTokenB.balanceOf(address(this));

        camelotUnbalancedTokenA.approve(address(camV2Router()), expectedInput);
        ICamelotV2Router(camV2Router())
            .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                expectedInput,
                0, // accept any amount of output tokens
                _getPath(address(camelotUnbalancedTokenA), address(camelotUnbalancedTokenB)),
                address(this),
                address(0), // referrer
                block.timestamp + 300 // deadline
            );
        uint256 actualOutput = camelotUnbalancedTokenB.balanceOf(address(this)) - initialBalanceB;

        // Verify we get at least 99.9% of the desired output (accounting for rounding and fees)
        uint256 minExpectedOutput = (desiredOutput * 999) / 1000;
        assertGe(actualOutput, minExpectedOutput, "Should get at least 99.9% of desired output");
        // Note: actualOutput may be slightly less than desiredOutput due to rounding and fees

        console.log("Expected input (5-param):", expectedInput);
        console.log("Actual output:", actualOutput);
        console.log("Desired output:", desiredOutput);
    }

    function test_purchaseQuote_Camelot_extremeUnbalancedPool_5param_purchasesTokenB() public {
        (uint112 reserve0, uint112 reserve1, uint16 token0Fee, uint16 token1Fee) =
            camelotExtremeUnbalancedPair.getReserves();
        (uint256 reserveA, uint256 feePercent, uint256 reserveB, uint256 tokenBFee) = ConstProdUtils._sortReserves(
            address(camelotExtremeTokenA),
            camelotExtremeUnbalancedPair.token0(),
            reserve0,
            uint256(token0Fee),
            reserve1,
            uint256(token1Fee)
        );
        uint256 feeDenominator = 100_000;

        // Desired output: 1% of TokenB reserve
        uint256 desiredOutput = reserveB / 100;

        uint256 expectedInput =
            ConstProdUtils._purchaseQuote(desiredOutput, reserveA, reserveB, feePercent, feeDenominator);

        camelotExtremeTokenA.mint(address(this), expectedInput);
        uint256 initialBalanceB = camelotExtremeTokenB.balanceOf(address(this));

        camelotExtremeTokenA.approve(address(camV2Router()), expectedInput);
        ICamelotV2Router(camV2Router())
            .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                expectedInput,
                0, // accept any amount of output tokens
                _getPath(address(camelotExtremeTokenA), address(camelotExtremeTokenB)),
                address(this),
                address(0), // referrer
                block.timestamp + 300 // deadline
            );
        uint256 actualOutput = camelotExtremeTokenB.balanceOf(address(this)) - initialBalanceB;

        // Verify we get at least 99.9% of the desired output (accounting for rounding and fees)
        uint256 minExpectedOutput = (desiredOutput * 999) / 1000;
        assertGe(actualOutput, minExpectedOutput, "Should get at least 99.9% of desired output");
        // Note: actualOutput may be slightly less than desiredOutput due to rounding and fees

        console.log("Expected input (5-param):", expectedInput);
        console.log("Actual output:", actualOutput);
        console.log("Desired output:", desiredOutput);
    }

    function test_purchaseQuote_Uniswap_balancedPool_5param_purchasesTokenB() public {
        (uint112 reserve0, uint112 reserve1,) = uniswapBalancedPair.getReserves();
        (uint256 reserveA, uint256 feePercent, uint256 reserveB, uint256 tokenBFee) = ConstProdUtils._sortReserves(
            address(uniswapBalancedTokenA), uniswapBalancedPair.token0(), reserve0, 300, reserve1, 300
        );
        uint256 feeDenominator = 100_000;

        // Desired output: 10% of TokenB reserve (slightly reduced to account for rounding)
        uint256 desiredOutput = (reserveB / 10) - 1;

        uint256 expectedInput =
            ConstProdUtils._purchaseQuote(desiredOutput, reserveA, reserveB, feePercent, feeDenominator);

        uniswapBalancedTokenA.mint(address(this), expectedInput);
        uint256 initialBalanceB = uniswapBalancedTokenB.balanceOf(address(this));

        uniswapBalancedTokenA.approve(address(uniswapV2Router()), expectedInput);
        IUniswapV2Router(address(uniswapV2Router()))
            .swapExactTokensForTokens(
                expectedInput,
                0, // accept any amount of output tokens
                _getPath(address(uniswapBalancedTokenA), address(uniswapBalancedTokenB)),
                address(this),
                block.timestamp + 300
            );
        uint256 actualOutput = uniswapBalancedTokenB.balanceOf(address(this)) - initialBalanceB;

        // Verify we get at least 99.9% of the desired output (accounting for rounding and fees)
        uint256 minExpectedOutput = (desiredOutput * 999) / 1000;
        assertGe(actualOutput, minExpectedOutput, "Should get at least 99.9% of desired output");
        // Note: actualOutput may be slightly less than desiredOutput due to rounding and fees

        console.log("Expected input (5-param):", expectedInput);
        console.log("Actual output:", actualOutput);
        console.log("Desired output:", desiredOutput);
    }

    function test_purchaseQuote_Uniswap_unbalancedPool_5param_purchasesTokenB() public {
        (uint112 reserve0, uint112 reserve1,) = uniswapUnbalancedPair.getReserves();
        (uint256 reserveA, uint256 feePercent, uint256 reserveB, uint256 tokenBFee) = ConstProdUtils._sortReserves(
            address(uniswapUnbalancedTokenA), uniswapUnbalancedPair.token0(), reserve0, 300, reserve1, 300
        );
        uint256 feeDenominator = 100_000;

        // Desired output: 5% of TokenB reserve
        uint256 desiredOutput = reserveB / 20;

        uint256 expectedInput =
            ConstProdUtils._purchaseQuote(desiredOutput, reserveA, reserveB, feePercent, feeDenominator);

        uniswapUnbalancedTokenA.mint(address(this), expectedInput);
        uint256 initialBalanceB = uniswapUnbalancedTokenB.balanceOf(address(this));

        uniswapUnbalancedTokenA.approve(address(uniswapV2Router()), expectedInput);
        IUniswapV2Router(address(uniswapV2Router()))
            .swapExactTokensForTokens(
                expectedInput,
                0, // accept any amount of output tokens
                _getPath(address(uniswapUnbalancedTokenA), address(uniswapUnbalancedTokenB)),
                address(this),
                block.timestamp + 300
            );
        uint256 actualOutput = uniswapUnbalancedTokenB.balanceOf(address(this)) - initialBalanceB;

        // Verify we get at least 99.9% of the desired output (accounting for rounding and fees)
        uint256 minExpectedOutput = (desiredOutput * 999) / 1000;
        assertGe(actualOutput, minExpectedOutput, "Should get at least 99.9% of desired output");
        // Note: actualOutput may be slightly less than desiredOutput due to rounding and fees

        console.log("Expected input (5-param):", expectedInput);
        console.log("Actual output:", actualOutput);
        console.log("Desired output:", desiredOutput);
    }

    function test_purchaseQuote_Uniswap_extremeUnbalancedPool_5param_purchasesTokenB() public {
        (uint112 reserve0, uint112 reserve1,) = uniswapExtremeUnbalancedPair.getReserves();
        (uint256 reserveA, uint256 feePercent, uint256 reserveB, uint256 tokenBFee) = ConstProdUtils._sortReserves(
            address(uniswapExtremeTokenA), uniswapExtremeUnbalancedPair.token0(), reserve0, 300, reserve1, 300
        );
        uint256 feeDenominator = 100_000;

        // Desired output: 1% of TokenB reserve
        uint256 desiredOutput = reserveB / 100;

        uint256 expectedInput =
            ConstProdUtils._purchaseQuote(desiredOutput, reserveA, reserveB, feePercent, feeDenominator);

        uniswapExtremeTokenA.mint(address(this), expectedInput);
        uint256 initialBalanceB = uniswapExtremeTokenB.balanceOf(address(this));

        uniswapExtremeTokenA.approve(address(uniswapV2Router()), expectedInput);
        IUniswapV2Router(address(uniswapV2Router()))
            .swapExactTokensForTokens(
                expectedInput,
                0, // accept any amount of output tokens
                _getPath(address(uniswapExtremeTokenA), address(uniswapExtremeTokenB)),
                address(this),
                block.timestamp + 300
            );
        uint256 actualOutput = uniswapExtremeTokenB.balanceOf(address(this)) - initialBalanceB;

        // Verify we get at least 99.9% of the desired output (accounting for rounding and fees)
        uint256 minExpectedOutput = (desiredOutput * 999) / 1000;
        assertGe(actualOutput, minExpectedOutput, "Should get at least 99.9% of desired output");
        // Note: actualOutput may be slightly less than desiredOutput due to rounding and fees

        console.log("Expected input (5-param):", expectedInput);
        console.log("Actual output:", actualOutput);
        console.log("Desired output:", desiredOutput);
    }

    // ========================================
    // 5-PARAMETER VERSION TESTS (B->A Direction)
    // ========================================

    function test_purchaseQuote_Camelot_balancedPool_5param_purchasesTokenA() public {
        (uint112 reserve0, uint112 reserve1, uint16 token0Fee, uint16 token1Fee) = camelotBalancedPair.getReserves();
        (uint256 reserveA, uint256 feePercent, uint256 reserveB, uint256 tokenBFee) = ConstProdUtils._sortReserves(
            address(camelotBalancedTokenB),
            camelotBalancedPair.token0(),
            reserve0,
            uint256(token0Fee),
            reserve1,
            uint256(token1Fee)
        );
        uint256 feeDenominator = 100_000;

        // Desired output: 10% of TokenA reserve (B->A direction, slightly reduced to account for rounding)
        uint256 desiredOutput = (reserveA / 10) - 1;

        uint256 expectedInput =
            ConstProdUtils._purchaseQuote(desiredOutput, reserveB, reserveA, feePercent, feeDenominator);

        camelotBalancedTokenB.mint(address(this), expectedInput);
        uint256 initialBalanceA = camelotBalancedTokenA.balanceOf(address(this));

        camelotBalancedTokenB.approve(address(camV2Router()), expectedInput);
        ICamelotV2Router(camV2Router())
            .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                expectedInput,
                0, // accept any amount of output tokens
                _getPath(address(camelotBalancedTokenB), address(camelotBalancedTokenA)),
                address(this),
                address(0), // referrer
                block.timestamp + 300 // deadline
            );
        uint256 actualOutput = camelotBalancedTokenA.balanceOf(address(this)) - initialBalanceA;

        // Verify we get at least 99.9% of the desired output (accounting for rounding and fees)
        uint256 minExpectedOutput = (desiredOutput * 999) / 1000;
        assertGe(actualOutput, minExpectedOutput, "Should get at least 99.9% of desired output");
        // Note: actualOutput may be slightly less than desiredOutput due to rounding and fees

        console.log("Expected input (5-param):", expectedInput);
        console.log("Actual output:", actualOutput);
        console.log("Desired output:", desiredOutput);
    }

    function test_purchaseQuote_Camelot_unbalancedPool_5param_purchasesTokenA() public {
        (uint112 reserve0, uint112 reserve1, uint16 token0Fee, uint16 token1Fee) = camelotUnbalancedPair.getReserves();
        (uint256 reserveA, uint256 feePercent, uint256 reserveB, uint256 tokenBFee) = ConstProdUtils._sortReserves(
            address(camelotUnbalancedTokenB),
            camelotUnbalancedPair.token0(),
            reserve0,
            uint256(token0Fee),
            reserve1,
            uint256(token1Fee)
        );
        uint256 feeDenominator = 100_000;

        // Desired output: 5% of TokenA reserve (B->A direction, slightly reduced to account for rounding)
        uint256 desiredOutput = (reserveA / 20) - 1;

        uint256 expectedInput =
            ConstProdUtils._purchaseQuote(desiredOutput, reserveB, reserveA, feePercent, feeDenominator);

        camelotUnbalancedTokenB.mint(address(this), expectedInput);
        uint256 initialBalanceA = camelotUnbalancedTokenA.balanceOf(address(this));

        camelotUnbalancedTokenB.approve(address(camV2Router()), expectedInput);
        ICamelotV2Router(camV2Router())
            .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                expectedInput,
                0, // accept any amount of output tokens
                _getPath(address(camelotUnbalancedTokenB), address(camelotUnbalancedTokenA)),
                address(this),
                address(0), // referrer
                block.timestamp + 300 // deadline
            );
        uint256 actualOutput = camelotUnbalancedTokenA.balanceOf(address(this)) - initialBalanceA;

        // Verify we get at least 99.9% of the desired output (accounting for rounding and fees)
        uint256 minExpectedOutput = (desiredOutput * 999) / 1000;
        assertGe(actualOutput, minExpectedOutput, "Should get at least 99.9% of desired output");
        // Note: actualOutput may be slightly less than desiredOutput due to rounding and fees

        console.log("Expected input (5-param):", expectedInput);
        console.log("Actual output:", actualOutput);
        console.log("Desired output:", desiredOutput);
    }

    function test_purchaseQuote_Camelot_extremeUnbalancedPool_5param_purchasesTokenA() public {
        (uint112 reserve0, uint112 reserve1, uint16 token0Fee, uint16 token1Fee) =
            camelotExtremeUnbalancedPair.getReserves();
        (uint256 reserveA, uint256 feePercent, uint256 reserveB, uint256 tokenBFee) = ConstProdUtils._sortReserves(
            address(camelotExtremeTokenB),
            camelotExtremeUnbalancedPair.token0(),
            reserve0,
            uint256(token0Fee),
            reserve1,
            uint256(token1Fee)
        );
        uint256 feeDenominator = 100_000;

        // Desired output: 1% of TokenA reserve (B->A direction, slightly reduced to account for rounding)
        uint256 desiredOutput = (reserveA / 100) - 1;

        uint256 expectedInput =
            ConstProdUtils._purchaseQuote(desiredOutput, reserveB, reserveA, feePercent, feeDenominator);

        camelotExtremeTokenB.mint(address(this), expectedInput);
        uint256 initialBalanceA = camelotExtremeTokenA.balanceOf(address(this));

        camelotExtremeTokenB.approve(address(camV2Router()), expectedInput);
        ICamelotV2Router(camV2Router())
            .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                expectedInput,
                0, // accept any amount of output tokens
                _getPath(address(camelotExtremeTokenB), address(camelotExtremeTokenA)),
                address(this),
                address(0), // referrer
                block.timestamp + 300 // deadline
            );
        uint256 actualOutput = camelotExtremeTokenA.balanceOf(address(this)) - initialBalanceA;

        // Verify we get at least 99.9% of the desired output (accounting for rounding and fees)
        uint256 minExpectedOutput = (desiredOutput * 999) / 1000;
        assertGe(actualOutput, minExpectedOutput, "Should get at least 99.9% of desired output");
        // Note: actualOutput may be slightly less than desiredOutput due to rounding and fees

        console.log("Expected input (5-param):", expectedInput);
        console.log("Actual output:", actualOutput);
        console.log("Desired output:", desiredOutput);
    }

    function test_purchaseQuote_Uniswap_balancedPool_5param_purchasesTokenA() public {
        (uint112 reserve0, uint112 reserve1,) = uniswapBalancedPair.getReserves();
        (uint256 reserveA, uint256 feePercent, uint256 reserveB, uint256 tokenBFee) = ConstProdUtils._sortReserves(
            address(uniswapBalancedTokenB), uniswapBalancedPair.token0(), reserve0, 300, reserve1, 300
        );
        uint256 feeDenominator = 100_000;

        // Desired output: 10% of TokenA reserve (B->A direction, slightly reduced to account for rounding)
        uint256 desiredOutput = (reserveA / 10) - 1;

        uint256 expectedInput =
            ConstProdUtils._purchaseQuote(desiredOutput, reserveB, reserveA, feePercent, feeDenominator);

        uniswapBalancedTokenB.mint(address(this), expectedInput);
        uint256 initialBalanceA = uniswapBalancedTokenA.balanceOf(address(this));

        uniswapBalancedTokenB.approve(address(uniswapV2Router()), expectedInput);
        IUniswapV2Router(address(uniswapV2Router()))
            .swapExactTokensForTokens(
                expectedInput,
                0, // accept any amount of output tokens
                _getPath(address(uniswapBalancedTokenB), address(uniswapBalancedTokenA)),
                address(this),
                block.timestamp + 300
            );
        uint256 actualOutput = uniswapBalancedTokenA.balanceOf(address(this)) - initialBalanceA;

        // Verify we get at least 99.9% of the desired output (accounting for rounding and fees)
        uint256 minExpectedOutput = (desiredOutput * 999) / 1000;
        assertGe(actualOutput, minExpectedOutput, "Should get at least 99.9% of desired output");
        // Note: actualOutput may be slightly less than desiredOutput due to rounding and fees

        console.log("Expected input (5-param):", expectedInput);
        console.log("Actual output:", actualOutput);
        console.log("Desired output:", desiredOutput);
    }

    function test_purchaseQuote_Uniswap_unbalancedPool_5param_purchasesTokenA() public {
        (uint112 reserve0, uint112 reserve1,) = uniswapUnbalancedPair.getReserves();
        (uint256 reserveA, uint256 feePercent, uint256 reserveB, uint256 tokenBFee) = ConstProdUtils._sortReserves(
            address(uniswapUnbalancedTokenB), uniswapUnbalancedPair.token0(), reserve0, 300, reserve1, 300
        );
        uint256 feeDenominator = 100_000;

        // Desired output: 5% of TokenA reserve (B->A direction, slightly reduced to account for rounding)
        uint256 desiredOutput = (reserveA / 20) - 1;

        uint256 expectedInput =
            ConstProdUtils._purchaseQuote(desiredOutput, reserveB, reserveA, feePercent, feeDenominator);

        uniswapUnbalancedTokenB.mint(address(this), expectedInput);
        uint256 initialBalanceA = uniswapUnbalancedTokenA.balanceOf(address(this));

        uniswapUnbalancedTokenB.approve(address(uniswapV2Router()), expectedInput);
        IUniswapV2Router(address(uniswapV2Router()))
            .swapExactTokensForTokens(
                expectedInput,
                0, // accept any amount of output tokens
                _getPath(address(uniswapUnbalancedTokenB), address(uniswapUnbalancedTokenA)),
                address(this),
                block.timestamp + 300
            );
        uint256 actualOutput = uniswapUnbalancedTokenA.balanceOf(address(this)) - initialBalanceA;

        // Verify we get at least 99.9% of the desired output (accounting for rounding and fees)
        uint256 minExpectedOutput = (desiredOutput * 999) / 1000;
        assertGe(actualOutput, minExpectedOutput, "Should get at least 99.9% of desired output");
        // Note: actualOutput may be slightly less than desiredOutput due to rounding and fees

        console.log("Expected input (5-param):", expectedInput);
        console.log("Actual output:", actualOutput);
        console.log("Desired output:", desiredOutput);
    }

    function test_purchaseQuote_Uniswap_extremeUnbalancedPool_5param_purchasesTokenA() public {
        (uint112 reserve0, uint112 reserve1,) = uniswapExtremeUnbalancedPair.getReserves();
        (uint256 reserveA, uint256 feePercent, uint256 reserveB, uint256 tokenBFee) = ConstProdUtils._sortReserves(
            address(uniswapExtremeTokenB), uniswapExtremeUnbalancedPair.token0(), reserve0, 300, reserve1, 300
        );
        uint256 feeDenominator = 100_000;

        // Desired output: 1% of TokenA reserve (B->A direction, slightly reduced to account for rounding)
        uint256 desiredOutput = (reserveA / 100) - 1;

        uint256 expectedInput =
            ConstProdUtils._purchaseQuote(desiredOutput, reserveB, reserveA, feePercent, feeDenominator);

        uniswapExtremeTokenB.mint(address(this), expectedInput);
        uint256 initialBalanceA = uniswapExtremeTokenA.balanceOf(address(this));

        uniswapExtremeTokenB.approve(address(uniswapV2Router()), expectedInput);
        IUniswapV2Router(address(uniswapV2Router()))
            .swapExactTokensForTokens(
                expectedInput,
                0, // accept any amount of output tokens
                _getPath(address(uniswapExtremeTokenB), address(uniswapExtremeTokenA)),
                address(this),
                block.timestamp + 300
            );
        uint256 actualOutput = uniswapExtremeTokenA.balanceOf(address(this)) - initialBalanceA;

        // Verify we get at least 99.9% of the desired output (accounting for rounding and fees)
        uint256 minExpectedOutput = (desiredOutput * 999) / 1000;
        assertGe(actualOutput, minExpectedOutput, "Should get at least 99.9% of desired output");
        // Note: actualOutput may be slightly less than desiredOutput due to rounding and fees

        console.log("Expected input (5-param):", expectedInput);
        console.log("Actual output:", actualOutput);
        console.log("Desired output:", desiredOutput);
    }
}
