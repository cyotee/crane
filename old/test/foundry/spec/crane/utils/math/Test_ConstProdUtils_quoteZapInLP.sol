// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TestBase_ConstProdUtils.sol";
import "../../../../../../contracts/crane/utils/math/ConstProdUtils.sol";

// contract Test_ConstProdUtils_quoteZapInLP is TestBase_ConstProdUtils {

//     // Fee parameters
//     uint256 constant CAMELOT_FEE_PERCENT = 300; // 0.3%
//     uint256 constant UNISWAP_FEE_PERCENT = 300; // 0.3%

//     // Protocol fee parameters
//     uint256 constant CAMELOT_OWNER_FEE_SHARE = 2;
//     uint256 constant UNISWAP_OWNER_FEE_SHARE = 1;
//     uint256 constant CAMELOT_OWNER_FEE_DENOMINATOR = 5;
//     uint256 constant UNISWAP_OWNER_FEE_DENOMINATOR = 6;
//     // uint256 constant K_LAST = 100000000000000000000000000; // 100M * 100M

//     function setUp() public override {
//         super.setUp();
//     }

//     // ============ 9-PARAMETER VERSION TESTS ============

//     function test_quoteZapInLP_Camelot_balancedPool() public {
//         (uint112 reserve0, uint112 reserve1, uint16 token0Fee, uint16 token1Fee) = camelotBalancedPair.getReserves();
//         (uint256 reserveA, uint256 tokenAFee, uint256 reserveB, uint256 tokenBFee) = ConstProdUtils._sortReserves(
//             address(camelotBalancedTokenA), camelotBalancedPair.token0(), reserve0, token0Fee, reserve1, token1Fee
//         );
//         uint256 totalSupply = camelotBalancedPair.totalSupply();

//         // Calculate expected LP using ConstProdUtils
//         uint256 expectedLP = ConstProdUtils._quoteZapInLP(
//             BALANCED_TEST_AMOUNT,
//             reserveA,
//             reserveB,
//             totalSupply,
//             tokenAFee,
//             FEE_DENOMINATOR,
//             CAMELOT_OWNER_FEE_SHARE,
//             CAMELOT_OWNER_FEE_DENOMINATOR,
//             camelotBalancedPair.kLast()
//         );

//         // Mint tokens for the test
//         camelotBalancedTokenA.mint(address(this), BALANCED_TEST_AMOUNT);

//         // Execute actual ZapIn operation (single token deposit with swap)
//         uint256 initialLPBalance = camelotBalancedPair.balanceOf(address(this));

//         // Calculate how much to swap vs deposit directly
//         uint256 swapAmount = ConstProdUtils._swapDepositSaleAmt(
//             BALANCED_TEST_AMOUNT,
//             reserveA,
//             tokenAFee
//         );

//         // Swap portion for the other token
//         if (swapAmount > 0) {
//             camelotBalancedTokenA.approve(address(camV2Router()), swapAmount);
//             address[] memory path = new address[](2);
//             path[0] = address(camelotBalancedTokenA);
//             path[1] = address(camelotBalancedTokenB);

//             camV2Router().swapExactTokensForTokensSupportingFeeOnTransferTokens(
//                 swapAmount, 0, path, address(this), address(0), block.timestamp
//             );
//         }

//         // Add liquidity with remaining tokens
//         uint256 remainingA = BALANCED_TEST_AMOUNT - swapAmount;
//         uint256 tokenBBalance = camelotBalancedTokenB.balanceOf(address(this));

//         camelotBalancedTokenA.approve(address(camV2Router()), remainingA);
//         camelotBalancedTokenB.approve(address(camV2Router()), tokenBBalance);

//         camV2Router().addLiquidity(
//             address(camelotBalancedTokenA),
//             address(camelotBalancedTokenB),
//             remainingA,
//             tokenBBalance,
//             1, // Minimum amounts (slippage tolerance)
//             1,
//             address(this),
//             block.timestamp
//         );

//         uint256 finalLPBalance = camelotBalancedPair.balanceOf(address(this));
//         uint256 actualLP = finalLPBalance - initialLPBalance;

//         // Verify the calculation matches actual execution
//         assertEq(expectedLP, actualLP, "Expected LP should match actual LP received");
//     }

//     function test_quoteZapInLP_Camelot_unbalancedPool() public {
//         (uint112 reserve0, uint112 reserve1, uint16 token0Fee, uint16 token1Fee) = camelotUnbalancedPair.getReserves();
//         (uint256 reserveA, uint256 tokenAFee, uint256 reserveB, uint256 tokenBFee) = ConstProdUtils._sortReserves(
//             address(camelotUnbalancedTokenA), camelotUnbalancedPair.token0(), reserve0, token0Fee, reserve1, token1Fee
//         );
//         uint256 totalSupply = camelotUnbalancedPair.totalSupply();

//         // Calculate expected LP using ConstProdUtils
//         uint256 expectedLP = ConstProdUtils._quoteZapInLP(
//             UNBALANCED_TEST_AMOUNT,
//             reserveA,
//             reserveB,
//             totalSupply,
//             tokenAFee,
//             FEE_DENOMINATOR,
//             CAMELOT_OWNER_FEE_SHARE,
//             CAMELOT_OWNER_FEE_DENOMINATOR,
//             camelotUnbalancedPair.kLast()
//         );

//         // Mint tokens for the test
//         camelotUnbalancedTokenA.mint(address(this), UNBALANCED_TEST_AMOUNT);

//         // Execute actual ZapIn operation (single token deposit with swap)
//         uint256 initialLPBalance = camelotUnbalancedPair.balanceOf(address(this));

//         // Calculate how much to swap vs deposit directly
//         uint256 swapAmount = ConstProdUtils._swapDepositSaleAmt(
//             UNBALANCED_TEST_AMOUNT,
//             reserveA,
//             tokenAFee
//         );

//         // Swap portion for the other token
//         if (swapAmount > 0) {
//             camelotUnbalancedTokenA.approve(address(camV2Router()), swapAmount);
//             address[] memory path = new address[](2);
//             path[0] = address(camelotUnbalancedTokenA);
//             path[1] = address(camelotUnbalancedTokenB);

//             camV2Router().swapExactTokensForTokensSupportingFeeOnTransferTokens(
//                 swapAmount, 0, path, address(this), address(0), block.timestamp
//             );
//         }

//         // Add liquidity with remaining tokens
//         uint256 remainingA = UNBALANCED_TEST_AMOUNT - swapAmount;
//         uint256 tokenBBalance = camelotUnbalancedTokenB.balanceOf(address(this));

//         camelotUnbalancedTokenA.approve(address(camV2Router()), remainingA);
//         camelotUnbalancedTokenB.approve(address(camV2Router()), tokenBBalance);

//         camV2Router().addLiquidity(
//             address(camelotUnbalancedTokenA),
//             address(camelotUnbalancedTokenB),
//             remainingA,
//             tokenBBalance,
//             remainingA * 95 / 100, // 5% slippage tolerance
//             tokenBBalance * 95 / 100, // 5% slippage tolerance
//             address(this),
//             block.timestamp
//         );

//         uint256 finalLPBalance = camelotUnbalancedPair.balanceOf(address(this));
//         uint256 actualLP = finalLPBalance - initialLPBalance;

//         // Verify the calculation matches actual execution
//         assertEq(expectedLP, actualLP, "Expected LP should match actual LP received");
//     }

//     function test_quoteZapInLP_Camelot_extremeUnbalancedPool() public {
//         (uint112 reserve0, uint112 reserve1, uint16 token0Fee, uint16 token1Fee) = camelotExtremeUnbalancedPair.getReserves();
//         (uint256 reserveA, uint256 tokenAFee, uint256 reserveB, uint256 tokenBFee) = ConstProdUtils._sortReserves(
//             address(camelotExtremeTokenA), camelotExtremeUnbalancedPair.token0(), reserve0, token0Fee, reserve1, token1Fee
//         );
//         uint256 totalSupply = camelotExtremeUnbalancedPair.totalSupply();

//         // Calculate expected LP using ConstProdUtils
//         uint256 expectedLP = ConstProdUtils._quoteZapInLP(
//             EXTREME_UNBALANCED_TEST_AMOUNT,
//             reserveA,
//             reserveB,
//             totalSupply,
//             tokenAFee,
//             FEE_DENOMINATOR,
//             CAMELOT_OWNER_FEE_SHARE,
//             CAMELOT_OWNER_FEE_DENOMINATOR,
//             camelotExtremeUnbalancedPair.kLast()
//         );

//         // Mint tokens for the test
//         camelotExtremeTokenA.mint(address(this), EXTREME_UNBALANCED_TEST_AMOUNT);

//         // Execute actual ZapIn operation (single token deposit with swap)
//         uint256 initialLPBalance = camelotExtremeUnbalancedPair.balanceOf(address(this));

//         // Calculate how much to swap vs deposit directly
//         uint256 swapAmount = ConstProdUtils._swapDepositSaleAmt(
//             EXTREME_UNBALANCED_TEST_AMOUNT,
//             reserveA,
//             tokenAFee
//         );

//         // Swap portion for the other token
//         if (swapAmount > 0) {
//             camelotExtremeTokenA.approve(address(camV2Router()), swapAmount);
//             address[] memory path = new address[](2);
//             path[0] = address(camelotExtremeTokenA);
//             path[1] = address(camelotExtremeTokenB);

//             camV2Router().swapExactTokensForTokensSupportingFeeOnTransferTokens(
//                 swapAmount, 0, path, address(this), address(0), block.timestamp
//             );
//         }

//         // Add liquidity with remaining tokens
//         uint256 remainingA = EXTREME_UNBALANCED_TEST_AMOUNT - swapAmount;
//         uint256 tokenBBalance = camelotExtremeTokenB.balanceOf(address(this));

//         camelotExtremeTokenA.approve(address(camV2Router()), remainingA);
//         camelotExtremeTokenB.approve(address(camV2Router()), tokenBBalance);

//         camV2Router().addLiquidity(
//             address(camelotExtremeTokenA),
//             address(camelotExtremeTokenB),
//             remainingA,
//             tokenBBalance,
//             remainingA * 95 / 100, // 5% slippage tolerance
//             tokenBBalance * 95 / 100, // 5% slippage tolerance
//             address(this),
//             block.timestamp
//         );

//         uint256 finalLPBalance = camelotExtremeUnbalancedPair.balanceOf(address(this));
//         uint256 actualLP = finalLPBalance - initialLPBalance;

//         // Verify the calculation matches actual execution
//         assertEq(expectedLP, actualLP, "Expected LP should match actual LP received");
//     }

//     function test_quoteZapInLP_Uniswap_balancedPool() public {
//         (uint112 reserve0, uint112 reserve1, ) = uniswapBalancedPair.getReserves();
//         (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
//             address(uniswapBalancedTokenA), uniswapBalancedPair.token0(), reserve0, reserve1
//         );
//         uint256 totalSupply = uniswapBalancedPair.totalSupply();

//         // Calculate expected LP using ConstProdUtils
//         uint256 expectedLP = ConstProdUtils._quoteZapInLP(
//             BALANCED_TEST_AMOUNT,
//             reserveA,
//             reserveB,
//             totalSupply,
//             UNISWAP_FEE_PERCENT,
//             FEE_DENOMINATOR,
//             UNISWAP_OWNER_FEE_SHARE,
//             UNISWAP_OWNER_FEE_DENOMINATOR,
//             uniswapBalancedPair.kLast()
//         );

//         // Mint tokens for the test
//         uniswapBalancedTokenA.mint(address(this), BALANCED_TEST_AMOUNT);

//         // Execute actual ZapIn operation (single token deposit with swap)
//         uint256 initialLPBalance = uniswapBalancedPair.balanceOf(address(this));

//         // Calculate how much to swap vs deposit directly
//         uint256 swapAmount = ConstProdUtils._swapDepositSaleAmt(
//             BALANCED_TEST_AMOUNT,
//             reserveA,
//             UNISWAP_FEE_PERCENT
//         );

//         // Swap portion for the other token
//         if (swapAmount > 0) {
//             uniswapBalancedTokenA.approve(address(uniswapV2Router()), swapAmount);
//             address[] memory path = new address[](2);
//             path[0] = address(uniswapBalancedTokenA);
//             path[1] = address(uniswapBalancedTokenB);

//             uniswapV2Router().swapExactTokensForTokens(
//                 swapAmount, 0, path, address(this), block.timestamp
//             );
//         }

//         // Add liquidity with remaining tokens
//         uint256 remainingA = BALANCED_TEST_AMOUNT - swapAmount;
//         uint256 tokenBBalance = uniswapBalancedTokenB.balanceOf(address(this));

//         uniswapBalancedTokenA.approve(address(uniswapV2Router()), remainingA);
//         uniswapBalancedTokenB.approve(address(uniswapV2Router()), tokenBBalance);

//         uniswapV2Router().addLiquidity(
//             address(uniswapBalancedTokenA),
//             address(uniswapBalancedTokenB),
//             remainingA,
//             tokenBBalance,
//             1, // Minimum amounts (slippage tolerance)
//             1,
//             address(this),
//             block.timestamp
//         );

//         uint256 finalLPBalance = uniswapBalancedPair.balanceOf(address(this));
//         uint256 actualLP = finalLPBalance - initialLPBalance;

//         // Verify the calculation matches actual execution
//         assertEq(expectedLP, actualLP, "Expected LP should match actual LP received");
//     }

//     function test_quoteZapInLP_Uniswap_unbalancedPool() public {
//         (uint112 reserve0, uint112 reserve1, ) = uniswapUnbalancedPair.getReserves();
//         (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
//             address(uniswapUnbalancedTokenA), uniswapUnbalancedPair.token0(), reserve0, reserve1
//         );
//         uint256 totalSupply = uniswapUnbalancedPair.totalSupply();

//         // Calculate expected LP using ConstProdUtils
//         uint256 expectedLP = ConstProdUtils._quoteZapInLP(
//             UNBALANCED_TEST_AMOUNT,
//             reserveA,
//             reserveB,
//             totalSupply,
//             UNISWAP_FEE_PERCENT,
//             FEE_DENOMINATOR,
//             UNISWAP_OWNER_FEE_SHARE,
//             UNISWAP_OWNER_FEE_DENOMINATOR,
//             uniswapUnbalancedPair.kLast()
//         );

//         // Mint tokens for the test
//         uniswapUnbalancedTokenA.mint(address(this), UNBALANCED_TEST_AMOUNT);

//         // Execute actual ZapIn operation (single token deposit with swap)
//         uint256 initialLPBalance = uniswapUnbalancedPair.balanceOf(address(this));

//         // Calculate how much to swap vs deposit directly
//         uint256 swapAmount = ConstProdUtils._swapDepositSaleAmt(
//             UNBALANCED_TEST_AMOUNT,
//             reserveA,
//             UNISWAP_FEE_PERCENT
//         );

//         // Swap portion for the other token
//         if (swapAmount > 0) {
//             uniswapUnbalancedTokenA.approve(address(uniswapV2Router()), swapAmount);
//             address[] memory path = new address[](2);
//             path[0] = address(uniswapUnbalancedTokenA);
//             path[1] = address(uniswapUnbalancedTokenB);

//             uniswapV2Router().swapExactTokensForTokens(
//                 swapAmount, 0, path, address(this), block.timestamp
//             );
//         }

//         // Add liquidity with remaining tokens
//         uint256 remainingA = UNBALANCED_TEST_AMOUNT - swapAmount;
//         uint256 tokenBBalance = uniswapUnbalancedTokenB.balanceOf(address(this));

//         uniswapUnbalancedTokenA.approve(address(uniswapV2Router()), remainingA);
//         uniswapUnbalancedTokenB.approve(address(uniswapV2Router()), tokenBBalance);

//         uniswapV2Router().addLiquidity(
//             address(uniswapUnbalancedTokenA),
//             address(uniswapUnbalancedTokenB),
//             remainingA,
//             tokenBBalance,
//             remainingA * 95 / 100, // 5% slippage tolerance
//             tokenBBalance * 95 / 100, // 5% slippage tolerance
//             address(this),
//             block.timestamp
//         );

//         uint256 finalLPBalance = uniswapUnbalancedPair.balanceOf(address(this));
//         uint256 actualLP = finalLPBalance - initialLPBalance;

//         // Verify the calculation matches actual execution
//         assertEq(expectedLP, actualLP, "Expected LP should match actual LP received");
//     }

//     function test_quoteZapInLP_Uniswap_extremeUnbalancedPool() public {
//         (uint112 reserve0, uint112 reserve1, ) = uniswapExtremeUnbalancedPair.getReserves();
//         (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
//             address(uniswapExtremeTokenA), uniswapExtremeUnbalancedPair.token0(), reserve0, reserve1
//         );
//         uint256 totalSupply = uniswapExtremeUnbalancedPair.totalSupply();

//         // Calculate expected LP using ConstProdUtils
//         uint256 expectedLP = ConstProdUtils._quoteZapInLP(
//             EXTREME_UNBALANCED_TEST_AMOUNT,
//             reserveA,
//             reserveB,
//             totalSupply,
//             UNISWAP_FEE_PERCENT,
//             FEE_DENOMINATOR,
//             UNISWAP_OWNER_FEE_SHARE,
//             UNISWAP_OWNER_FEE_DENOMINATOR,
//             uniswapExtremeUnbalancedPair.kLast()
//         );

//         // Mint tokens for the test
//         uniswapExtremeTokenA.mint(address(this), EXTREME_UNBALANCED_TEST_AMOUNT);

//         // Execute actual ZapIn operation (single token deposit with swap)
//         uint256 initialLPBalance = uniswapExtremeUnbalancedPair.balanceOf(address(this));

//         // Calculate how much to swap vs deposit directly
//         uint256 swapAmount = ConstProdUtils._swapDepositSaleAmt(
//             EXTREME_UNBALANCED_TEST_AMOUNT,
//             reserveA,
//             UNISWAP_FEE_PERCENT
//         );

//         // Swap portion for the other token
//         if (swapAmount > 0) {
//             uniswapExtremeTokenA.approve(address(uniswapV2Router()), swapAmount);
//             address[] memory path = new address[](2);
//             path[0] = address(uniswapExtremeTokenA);
//             path[1] = address(uniswapExtremeTokenB);

//             uniswapV2Router().swapExactTokensForTokens(
//                 swapAmount, 0, path, address(this), block.timestamp
//             );
//         }

//         // Add liquidity with remaining tokens
//         uint256 remainingA = EXTREME_UNBALANCED_TEST_AMOUNT - swapAmount;
//         uint256 tokenBBalance = uniswapExtremeTokenB.balanceOf(address(this));

//         uniswapExtremeTokenA.approve(address(uniswapV2Router()), remainingA);
//         uniswapExtremeTokenB.approve(address(uniswapV2Router()), tokenBBalance);

//         uniswapV2Router().addLiquidity(
//             address(uniswapExtremeTokenA),
//             address(uniswapExtremeTokenB),
//             remainingA,
//             tokenBBalance,
//             remainingA * 95 / 100, // 5% slippage tolerance
//             tokenBBalance * 95 / 100, // 5% slippage tolerance
//             address(this),
//             block.timestamp
//         );

//         uint256 finalLPBalance = uniswapExtremeUnbalancedPair.balanceOf(address(this));
//         uint256 actualLP = finalLPBalance - initialLPBalance;

//         // Verify the calculation matches actual execution
//         assertEq(expectedLP, actualLP, "Expected LP should match actual LP received");
//     }

// }
