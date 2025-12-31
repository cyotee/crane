// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {TestBase_ConstProdUtils} from "./TestBase_ConstProdUtils.sol";
import {ConstProdUtils} from "contracts/crane/utils/math/ConstProdUtils.sol";
import {IUniswapV2Pair} from "contracts/crane/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Pair.sol";
import {ICamelotPair} from "contracts/crane/interfaces/protocols/dexes/camelot/v2/ICamelotPair.sol";
import {IERC20MintBurn} from "contracts/crane/interfaces/IERC20MintBurn.sol";
import "forge-std/console.sol";

/**
 * @title Test_ConstProdUtils_minZapInAmount
 * @dev Comprehensive tests for _minZapInAmount() with execution validation
 */
// contract Test_ConstProdUtils_minZapInAmount is TestBase_ConstProdUtils {

//     using ConstProdUtils for uint256;

//     // Test constants
//     uint256 constant FEE_PERCENT = 300; // 0.3% fee
//     uint256 constant FEE_DENOMINATOR = 100000;

//     // Uniswap V2 Tests
//     function test_minZapInAmount_Uniswap_BalancedPool() public {
//         _testMinZapInAmount(uniswapBalancedPair, uniswapBalancedTokenA, uniswapBalancedTokenB);
//     }

//     function test_minZapInAmount_Uniswap_UnbalancedPool() public {
//         _testMinZapInAmount(uniswapUnbalancedPair, uniswapUnbalancedTokenA, uniswapUnbalancedTokenB);
//     }

//     function test_minZapInAmount_Uniswap_ExtremeUnbalancedPool() public {
//         _testMinZapInAmount(uniswapExtremeUnbalancedPair, uniswapExtremeTokenA, uniswapExtremeTokenB);
//     }

//     // Camelot V2 Tests
//     // function test_minZapInAmount_Camelot_BalancedPool() public {
//     //     _testMinZapInAmount(camelotBalancedPair, camelotBalancedTokenA, camelotBalancedTokenB);
//     // }

//     // function test_minZapInAmount_Camelot_UnbalancedPool() public {
//     //     _testMinZapInAmount(camelotUnbalancedPair, camelotUnbalancedTokenA, camelotUnbalancedTokenB);
//     // }

//     // function test_minZapInAmount_Camelot_ExtremeUnbalancedPool() public {
//     //     _testMinZapInAmount(camelotExtremeUnbalancedPair, camelotExtremeTokenA, camelotExtremeTokenB);
//     // }

//     function _testMinZapInAmount(
//         IUniswapV2Pair pair,
//         IERC20MintBurn tokenA,
//         IERC20MintBurn tokenB
//     ) internal {
//         // Get current pool state
//         (uint112 reserveA, uint112 reserveB, ) = pair.getReserves();
//         uint256 totalSupply = pair.totalSupply();

//         // Calculate minimum ZapIn amount
//         uint256 minAmountIn = ConstProdUtils._minZapInAmount(
//             reserveA,
//             reserveB,
//             totalSupply,
//             FEE_PERCENT,
//             FEE_DENOMINATOR
//         );

//         // Verify minimum amount is positive
//         assertTrue(minAmountIn > 0, "Minimum amount should be positive");

//         // Test execution validation
//         _testMinZapInAmountExecution(
//             pair,
//             tokenA,
//             tokenB,
//             minAmountIn,
//             reserveA,
//             reserveB,
//             totalSupply
//         );
//     }

//     function _testMinZapInAmountExecution(
//         IUniswapV2Pair pair,
//         IERC20MintBurn tokenA,
//         IERC20MintBurn tokenB,
//         uint256 minAmountIn,
//         uint256 reserveA,
//         uint256 reserveB,
//         uint256 totalSupply
//     ) internal {
//         // Calculate swap amount using _swapDepositSaleAmt
//         uint256 swapAmount = minAmountIn._swapDepositSaleAmt(reserveA, FEE_PERCENT);

//         // Calculate equivalent liquidity from swap amount
//         uint256 equivLiquidity = swapAmount._equivLiquidity(reserveA, reserveB);

//         // Calculate remaining amount after swap
//         uint256 remainingAmount = minAmountIn - swapAmount;

//         // Verify that swap amount + remaining amount equals original input
//         assertEq(swapAmount + remainingAmount, minAmountIn, "Swap amount + remaining should equal original input");

//         // Verify that equivalent liquidity calculation is consistent
//         assertTrue(equivLiquidity >= 1, "Equivalent liquidity should be positive");

//         // Verify that the minimum amount is sufficient for at least 1 unit of output
//         assertTrue(minAmountIn >= swapAmount, "Minimum amount should be at least the swap amount");
//         assertTrue(remainingAmount > 0, "Remaining amount should be positive");
//     }

//     // function _testMinZapInAmountExecution(
//     //     IUniswapV2Pair pair,
//     //     IERC20MintBurn tokenA,
//     //     IERC20MintBurn tokenB,
//     //     uint256 minAmountIn,
//     //     uint256 reserveA,
//     //     uint256 reserveB,
//     //     uint256 totalSupply
//     // ) internal {
//     //     // Calculate minAmountB needed
//     //     uint256 minAmountB = (reserveB + totalSupply - 1) / totalSupply; // ceil(reserveB / totalSupply)
//     //     // Calculate swap amount to get minAmountB
//     //     uint256 swapAmount = ConstProdUtils._purchaseQuote(minAmountB, reserveA, reserveB, FEE_PERCENT, FEE_DENOMINATOR);
//     //     // Calculate remaining amount (token A)
//     //     uint256 remainingAmount = minAmountIn - swapAmount;
//     //     // Calculate amountB from swap
//     //     uint256 amountB = ConstProdUtils._saleQuote(swapAmount, reserveA, reserveB, FEE_PERCENT, FEE_DENOMINATOR);
//     //     // Calculate equivalent liquidity
//     //     uint256 newReserveA = reserveA + swapAmount;
//     //     uint256 newReserveB = reserveB - amountB;
//     //     uint256 equivLiquidity = ConstProdUtils._depositQuote(remainingAmount, amountB, totalSupply, newReserveA, newReserveB);
//     //     // Verify
//     //     assertEq(swapAmount + remainingAmount, minAmountIn, "Swap amount + remaining should equal original input");
//     //     assertTrue(equivLiquidity >= 1, "Equivalent liquidity should be at least 1 LP");
//     //     assertTrue(minAmountIn >= swapAmount, "Minimum amount should be at least the swap amount");
//     //     assertTrue(remainingAmount > 0, "Remaining amount should be positive");
//     // }

// }
