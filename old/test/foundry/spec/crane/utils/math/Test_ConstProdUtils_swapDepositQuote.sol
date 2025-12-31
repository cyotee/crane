// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {betterconsole as console} from "contracts/crane/utils/vm/foundry/tools/betterconsole.sol";
import {TestBase_ConstProdUtils} from "./TestBase_ConstProdUtils.sol";
import {ConstProdUtils} from "contracts/crane/utils/math/ConstProdUtils.sol";
// import {CamelotV2Service} from "contracts/crane/protocols/dexes/camelot/v2/utils/CamelotV2Service.sol";
// import {UniswapV2Service} from "contracts/crane/protocols/dexes/uniswap/v2/utils/UniswapV2Service.sol";
// import {IUniswapV2Router} from "contracts/crane/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Router.sol";
import {FEE_DENOMINATOR} from "@crane/src/constants/Constants.sol";

// contract Test_ConstProdUtils_swapDepositQuote is TestBase_ConstProdUtils {
//     using ConstProdUtils for uint256;

//     function setUp() public override {
//         super.setUp();
//         // _initializePools();
//     }

//     /* ---------------------------------------------------------------------- */
//     /*                        BASIC FUNCTIONALITY TESTS                       */
//     /* ---------------------------------------------------------------------- */

//     function test_swapDepositQuote_Camelot_balancedPool() public {
//         // Get current pool state
//         (uint112 reserve0, uint112 reserve1, uint16 token0Fee, uint16 token1Fee) = camelotBalancedPair.getReserves();
//         uint256 amountIn = 1000e18; // Input amount
//         uint256 lpTotalSupply = camelotBalancedPair.totalSupply();

//         // Sort reserves and fees to match token order
//         (uint256 reserveA, uint256 tokenAFee, uint256 reserveB, uint256 tokenBFee)
//             = ConstProdUtils._sortReserves(
//                 address(camelotBalancedTokenA),
//                 camelotBalancedPair.token0(),
//                 reserve0,
//                 token0Fee,
//                 reserve1,
//                 token1Fee
//             );

//         uint256 feePercent = tokenAFee;

//         // Calculate expected LP tokens using ConstProdUtils
//         uint256 expectedLPTokens = ConstProdUtils._swapDepositQuote(
//             lpTotalSupply, amountIn, reserveA, reserveB, feePercent
//         );

//         // Calculate how much to swap using _swapDepositSaleAmt
//         uint256 swapAmount = ConstProdUtils._swapDepositSaleAmt(
//             amountIn, reserveA, feePercent
//         );

//         // Mint tokens for the test
//         camelotBalancedTokenA.mint(address(this), amountIn);
//         camelotBalancedTokenA.approve(address(camV2Router()), amountIn);

//         // Execute the actual zap in operation
//         // Step 1: Swap the calculated amount
//         address[] memory path = new address[](2);
//         path[0] = address(camelotBalancedTokenA);
//         path[1] = address(camelotBalancedTokenB);

//         uint256 tokenBBeforeSwap = camelotBalancedTokenB.balanceOf(address(this));
//         camV2Router().swapExactTokensForTokensSupportingFeeOnTransferTokens(
//             swapAmount,
//             0, // Accept any amount of output tokens
//             path,
//             address(this),
//             address(0), // No referrer
//             block.timestamp + 300
//         );
//         uint256 tokenBReceived = camelotBalancedTokenB.balanceOf(address(this)) - tokenBBeforeSwap;

//         // Step 2: Add liquidity with remaining tokens
//         uint256 remainingTokenA = amountIn - swapAmount;
//         camelotBalancedTokenA.approve(address(camV2Router()), remainingTokenA);
//         camelotBalancedTokenB.approve(address(camV2Router()), tokenBReceived);

//         (,, uint256 actualLPTokens) = camV2Router().addLiquidity(
//             address(camelotBalancedTokenA),
//             address(camelotBalancedTokenB),
//             remainingTokenA,
//             tokenBReceived,
//             1, // Minimum amounts (slippage tolerance)
//             1,
//             address(this),
//             block.timestamp + 300
//         );

//         // Validate exact equality
//         assertEq(actualLPTokens, expectedLPTokens,
//             "Actual LP tokens should equal expected LP tokens exactly");
//     }

//     function test_swapDepositQuote_Camelot_unbalancedPool() public {
//         (uint112 reserve0, uint112 reserve1, uint16 token0Fee, uint16 token1Fee) = camelotUnbalancedPair.getReserves();
//         uint256 amountIn = 100e18; // Smaller input for unbalanced pool
//         uint256 lpTotalSupply = camelotUnbalancedPair.totalSupply();

//         // Sort reserves and fees to match token order
//         (uint256 reserveA, uint256 tokenAFee, uint256 reserveB, uint256 tokenBFee) = ConstProdUtils._sortReserves(
//             address(camelotUnbalancedTokenA),
//             camelotUnbalancedPair.token0(),
//             reserve0,
//             token0Fee,
//             reserve1,
//             token1Fee
//         );

//         uint256 feePercent = tokenAFee;

//         // Calculate expected LP tokens using ConstProdUtils
//         uint256 expectedLPTokens = ConstProdUtils._swapDepositQuote(
//             lpTotalSupply, amountIn, reserveA, reserveB, feePercent
//         );

//         // Calculate how much to swap using _swapDepositSaleAmt
//         uint256 swapAmount = ConstProdUtils._swapDepositSaleAmt(
//             amountIn, reserveA, feePercent
//         );

//         // Mint tokens for the test
//         camelotUnbalancedTokenA.mint(address(this), amountIn);
//         camelotUnbalancedTokenA.approve(address(camV2Router()), amountIn);

//         // Execute the actual zap in operation
//         address[] memory path = new address[](2);
//         path[0] = address(camelotUnbalancedTokenA);
//         path[1] = address(camelotUnbalancedTokenB);

//         uint256 tokenBBeforeSwap = camelotUnbalancedTokenB.balanceOf(address(this));
//         camV2Router().swapExactTokensForTokensSupportingFeeOnTransferTokens(
//             swapAmount,
//             0,
//             path,
//             address(this),
//             address(0),
//             block.timestamp + 300
//         );
//         uint256 tokenBReceived = camelotUnbalancedTokenB.balanceOf(address(this)) - tokenBBeforeSwap;

//         // Add liquidity with remaining tokens
//         uint256 remainingTokenA = amountIn - swapAmount;
//         camelotUnbalancedTokenA.approve(address(camV2Router()), remainingTokenA);
//         camelotUnbalancedTokenB.approve(address(camV2Router()), tokenBReceived);

//         (,, uint256 actualLPTokens) = camV2Router().addLiquidity(
//             address(camelotUnbalancedTokenA),
//             address(camelotUnbalancedTokenB),
//             remainingTokenA,
//             tokenBReceived,
//             1,
//             1,
//             address(this),
//             block.timestamp + 300
//         );

//         // Validate exact equality
//         assertEq(actualLPTokens, expectedLPTokens,
//             "Actual LP tokens should equal expected LP tokens exactly");
//     }

//     function test_swapDepositQuote_Camelot_extremeUnbalancedPool() public {
//         (uint112 reserve0, uint112 reserve1, uint16 token0Fee, uint16 token1Fee) = camelotExtremeUnbalancedPair.getReserves();
//         uint256 amountIn = 10e18; // Very small input for extreme unbalanced pool
//         uint256 lpTotalSupply = camelotExtremeUnbalancedPair.totalSupply();

//         // Sort reserves and fees to match token order
//         (uint256 reserveA, uint256 tokenAFee, uint256 reserveB, uint256 tokenBFee) = ConstProdUtils._sortReserves(
//             address(camelotExtremeTokenA),
//             camelotExtremeUnbalancedPair.token0(),
//             reserve0,
//             token0Fee,
//             reserve1,
//             token1Fee
//         );

//         uint256 feePercent = tokenAFee;

//         // Calculate expected LP tokens using ConstProdUtils
//         uint256 expectedLPTokens = ConstProdUtils._swapDepositQuote(
//             lpTotalSupply, amountIn, reserveA, reserveB, feePercent
//         );

//         // Calculate how much to swap using _swapDepositSaleAmt
//         uint256 swapAmount = ConstProdUtils._swapDepositSaleAmt(
//             amountIn, reserveA, feePercent
//         );

//         // Mint tokens for the test
//         camelotExtremeTokenA.mint(address(this), amountIn);
//         camelotExtremeTokenA.approve(address(camV2Router()), amountIn);

//         // Execute the actual zap in operation
//         address[] memory path = new address[](2);
//         path[0] = address(camelotExtremeTokenA);
//         path[1] = address(camelotExtremeTokenB);

//         uint256 tokenBBeforeSwap = camelotExtremeTokenB.balanceOf(address(this));
//         camV2Router().swapExactTokensForTokensSupportingFeeOnTransferTokens(
//             swapAmount,
//             0,
//             path,
//             address(this),
//             address(0),
//             block.timestamp + 300
//         );
//         uint256 tokenBReceived = camelotExtremeTokenB.balanceOf(address(this)) - tokenBBeforeSwap;

//         // Add liquidity with remaining tokens
//         uint256 remainingTokenA = amountIn - swapAmount;
//         camelotExtremeTokenA.approve(address(camV2Router()), remainingTokenA);
//         camelotExtremeTokenB.approve(address(camV2Router()), tokenBReceived);

//         (,, uint256 actualLPTokens) = camV2Router().addLiquidity(
//             address(camelotExtremeTokenA),
//             address(camelotExtremeTokenB),
//             remainingTokenA,
//             tokenBReceived,
//             1,
//             1,
//             address(this),
//             block.timestamp + 300
//         );

//         // Validate exact equality
//         assertEq(actualLPTokens, expectedLPTokens,
//             "Actual LP tokens should equal expected LP tokens exactly");
//     }

//     function test_swapDepositQuote_Uniswap_balancedPool() public {
//         (uint112 reserve0, uint112 reserve1, ) = uniswapBalancedPair.getReserves();
//         uint256 amountIn = 1000e18; // Input amount
//         uint256 lpTotalSupply = uniswapBalancedPair.totalSupply();

//         // Sort reserves to match token order
//         (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
//             address(uniswapBalancedTokenA),
//             uniswapBalancedPair.token0(),
//             reserve0,
//             reserve1
//         );

//         uint256 feePercent = 300; // Uniswap V2 fixed fee (0.3%)

//         // Calculate expected LP tokens using ConstProdUtils
//         uint256 expectedLPTokens = ConstProdUtils._swapDepositQuote(
//             lpTotalSupply, amountIn, reserveA, reserveB, feePercent
//         );

//         // Calculate how much to swap using _swapDepositSaleAmt
//         uint256 swapAmount = ConstProdUtils._swapDepositSaleAmt(
//             amountIn, reserveA, feePercent
//         );

//         // Mint tokens for the test
//         uniswapBalancedTokenA.mint(address(this), amountIn);
//         uniswapBalancedTokenA.approve(address(uniswapV2Router()), amountIn);

//         // Execute the actual zap in operation
//         address[] memory path = new address[](2);
//         path[0] = address(uniswapBalancedTokenA);
//         path[1] = address(uniswapBalancedTokenB);

//         uint256 tokenBBeforeSwap = uniswapBalancedTokenB.balanceOf(address(this));
//         uniswapV2Router().swapExactTokensForTokensSupportingFeeOnTransferTokens(
//             swapAmount,
//             0,
//             path,
//             address(this),
//             block.timestamp + 300
//         );
//         uint256 tokenBReceived = uniswapBalancedTokenB.balanceOf(address(this)) - tokenBBeforeSwap;

//         // Add liquidity with remaining tokens
//         uint256 remainingTokenA = amountIn - swapAmount;
//         uniswapBalancedTokenA.approve(address(uniswapV2Router()), remainingTokenA);
//         uniswapBalancedTokenB.approve(address(uniswapV2Router()), tokenBReceived);

//         (,, uint256 actualLPTokens) = uniswapV2Router().addLiquidity(
//             address(uniswapBalancedTokenA),
//             address(uniswapBalancedTokenB),
//             remainingTokenA,
//             tokenBReceived,
//             1,
//             1,
//             address(this),
//             block.timestamp + 300
//         );

//         // Validate exact equality
//         assertEq(actualLPTokens, expectedLPTokens,
//             "Actual LP tokens should equal expected LP tokens exactly");
//     }

//     function test_swapDepositQuote_Uniswap_unbalancedPool() public {
//         (uint112 reserve0, uint112 reserve1, ) = uniswapUnbalancedPair.getReserves();
//         uint256 amountIn = 100e18; // Smaller input for unbalanced pool
//         uint256 lpTotalSupply = uniswapUnbalancedPair.totalSupply();

//         // Sort reserves to match token order
//         (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
//             address(uniswapUnbalancedTokenA),
//             uniswapUnbalancedPair.token0(),
//             reserve0,
//             reserve1
//         );

//         uint256 feePercent = 300; // Uniswap V2 fixed fee (0.3%)

//         // Calculate expected LP tokens using ConstProdUtils
//         uint256 expectedLPTokens = ConstProdUtils._swapDepositQuote(
//             lpTotalSupply, amountIn, reserveA, reserveB, feePercent
//         );

//         // Calculate how much to swap using _swapDepositSaleAmt
//         uint256 swapAmount = ConstProdUtils._swapDepositSaleAmt(
//             amountIn, reserveA, feePercent
//         );

//         // Mint tokens for the test
//         uniswapUnbalancedTokenA.mint(address(this), amountIn);
//         uniswapUnbalancedTokenA.approve(address(uniswapV2Router()), amountIn);

//         // Execute the actual zap in operation
//         address[] memory path = new address[](2);
//         path[0] = address(uniswapUnbalancedTokenA);
//         path[1] = address(uniswapUnbalancedTokenB);

//         uint256 tokenBBeforeSwap = uniswapUnbalancedTokenB.balanceOf(address(this));
//         uniswapV2Router().swapExactTokensForTokensSupportingFeeOnTransferTokens(
//             swapAmount,
//             0,
//             path,
//             address(this),
//             block.timestamp + 300
//         );
//         uint256 tokenBReceived = uniswapUnbalancedTokenB.balanceOf(address(this)) - tokenBBeforeSwap;

//         // Add liquidity with remaining tokens
//         uint256 remainingTokenA = amountIn - swapAmount;
//         uniswapUnbalancedTokenA.approve(address(uniswapV2Router()), remainingTokenA);
//         uniswapUnbalancedTokenB.approve(address(uniswapV2Router()), tokenBReceived);

//         (,, uint256 actualLPTokens) = uniswapV2Router().addLiquidity(
//             address(uniswapUnbalancedTokenA),
//             address(uniswapUnbalancedTokenB),
//             remainingTokenA,
//             tokenBReceived,
//             1,
//             1,
//             address(this),
//             block.timestamp + 300
//         );

//         // Validate exact equality
//         assertEq(actualLPTokens, expectedLPTokens,
//             "Actual LP tokens should equal expected LP tokens exactly");
//     }

//     function test_swapDepositQuote_Uniswap_extremeUnbalancedPool() public {
//         (uint112 reserve0, uint112 reserve1, ) = uniswapExtremeUnbalancedPair.getReserves();
//         uint256 amountIn = 10e18; // Very small input for extreme unbalanced pool
//         uint256 lpTotalSupply = uniswapExtremeUnbalancedPair.totalSupply();

//         // Sort reserves to match token order
//         (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
//             address(uniswapExtremeTokenA),
//             uniswapExtremeUnbalancedPair.token0(),
//             reserve0,
//             reserve1
//         );

//         uint256 feePercent = 300; // Uniswap V2 fixed fee (0.3%)

//         // Calculate expected LP tokens using ConstProdUtils
//         uint256 expectedLPTokens = ConstProdUtils._swapDepositQuote(
//             lpTotalSupply, amountIn, reserveA, reserveB, feePercent
//         );

//         // Calculate how much to swap using _swapDepositSaleAmt
//         uint256 swapAmount = ConstProdUtils._swapDepositSaleAmt(
//             amountIn, reserveA, feePercent
//         );

//         // Mint tokens for the test
//         uniswapExtremeTokenA.mint(address(this), amountIn);
//         uniswapExtremeTokenA.approve(address(uniswapV2Router()), amountIn);

//         // Execute the actual zap in operation
//         address[] memory path = new address[](2);
//         path[0] = address(uniswapExtremeTokenA);
//         path[1] = address(uniswapExtremeTokenB);

//         uint256 tokenBBeforeSwap = uniswapExtremeTokenB.balanceOf(address(this));
//         uniswapV2Router().swapExactTokensForTokensSupportingFeeOnTransferTokens(
//             swapAmount,
//             0,
//             path,
//             address(this),
//             block.timestamp + 300
//         );
//         uint256 tokenBReceived = uniswapExtremeTokenB.balanceOf(address(this)) - tokenBBeforeSwap;

//         // Add liquidity with remaining tokens
//         uint256 remainingTokenA = amountIn - swapAmount;
//         uniswapExtremeTokenA.approve(address(uniswapV2Router()), remainingTokenA);
//         uniswapExtremeTokenB.approve(address(uniswapV2Router()), tokenBReceived);

//         (,, uint256 actualLPTokens) = uniswapV2Router().addLiquidity(
//             address(uniswapExtremeTokenA),
//             address(uniswapExtremeTokenB),
//             remainingTokenA,
//             tokenBReceived,
//             1,
//             1,
//             address(this),
//             block.timestamp + 300
//         );

//         // Validate exact equality
//         assertEq(actualLPTokens, expectedLPTokens,
//             "Actual LP tokens should equal expected LP tokens exactly");
//     }

// }
