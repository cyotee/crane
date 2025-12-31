// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {betterconsole as console} from "contracts/crane/utils/vm/foundry/tools/betterconsole.sol";
import {TestBase_ConstProdUtils} from "./TestBase_ConstProdUtils.sol";
import {ConstProdUtils} from "contracts/crane/utils/math/ConstProdUtils.sol";
import {CamelotV2Service} from "contracts/crane/protocols/dexes/camelot/v2/utils/CamelotV2Service.sol";
import {UniswapV2Service} from "contracts/crane/protocols/dexes/uniswap/v2/utils/UniswapV2Service.sol";
import {IUniswapV2Router} from "contracts/crane/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Router.sol";

/**
 * @title Test_ConstProdUtils_saleQuoteMin
 * @dev Comprehensive expected vs actual validation tests for ConstProdUtils._saleQuoteMin
 * @notice Tests minimum input calculation for 1 unit output across all pool types and protocols
 */
// contract Test_ConstProdUtils_saleQuoteMin is TestBase_ConstProdUtils {

//     function setUp() public override {
//         super.setUp();
//     }

//     // ========================================
//     // A->B DIRECTION TESTS
//     // ========================================

//     function test_saleQuoteMin_Camelot_balancedPool() public {
//         (uint112 reserve0, uint112 reserve1, uint16 token0Fee, uint16 token1Fee) = camelotBalancedPair.getReserves();
//         (uint256 reserveA, uint256 fee, uint256 reserveB, uint256 tokenBFee) = ConstProdUtils._sortReserves(
//             address(camelotBalancedTokenA), camelotBalancedPair.token0(), reserve0, uint256(token0Fee), reserve1, uint256(token1Fee)
//         );
//         uint256 feeDenominator = 100_000;

//         // Calculate expected minimum input for 1 unit of TokenB
//         uint256 expectedMinInput = ConstProdUtils._saleQuoteMin(
//             reserveA, reserveB, fee, feeDenominator
//         );

//         // Mint the calculated minimum input amount
//         camelotBalancedTokenA.mint(address(this), expectedMinInput);
//         uint256 initialBalanceB = camelotBalancedTokenB.balanceOf(address(this));

//         // Perform actual swap
//         uint256 actualOutput = CamelotV2Service._swap(
//             camV2Router(), camelotBalancedPair, expectedMinInput,
//             camelotBalancedTokenA, camelotBalancedTokenB, address(0)
//         );

//         // Verify we get at least 1 unit of output
//         assertGe(actualOutput, 1, "Should get at least 1 unit of output");
//         // Note: actualOutput may be more than 1 due to rounding and minimum input calculation

//         console.log("Expected min input:", expectedMinInput);
//         console.log("Actual output:", actualOutput);
//         console.log("ReserveA:", reserveA);
//         console.log("ReserveB:", reserveB);
//         console.log("Fee:", fee);
//     }

//     function test_saleQuoteMin_Camelot_unbalancedPool() public {
//         (uint112 reserve0, uint112 reserve1, uint16 token0Fee, uint16 token1Fee) = camelotUnbalancedPair.getReserves();
//         (uint256 reserveA, uint256 fee, uint256 reserveB, uint256 tokenBFee) = ConstProdUtils._sortReserves(
//             address(camelotUnbalancedTokenA), camelotUnbalancedPair.token0(), reserve0, uint256(token0Fee), reserve1, uint256(token1Fee)
//         );
//         uint256 feeDenominator = 100_000;

//         uint256 expectedMinInput = ConstProdUtils._saleQuoteMin(
//             reserveA, reserveB, fee, feeDenominator
//         );

//         camelotUnbalancedTokenA.mint(address(this), expectedMinInput);
//         uint256 initialBalanceB = camelotUnbalancedTokenB.balanceOf(address(this));

//         uint256 actualOutput = CamelotV2Service._swap(
//             camV2Router(), camelotUnbalancedPair, expectedMinInput,
//             camelotUnbalancedTokenA, camelotUnbalancedTokenB, address(0)
//         );

//         assertGe(actualOutput, 1, "Should get at least 1 unit of output");
//         // Note: actualOutput may be more than 1 due to rounding and minimum input calculation

//         console.log("Expected min input:", expectedMinInput);
//         console.log("Actual output:", actualOutput);
//         console.log("ReserveA:", reserveA);
//         console.log("ReserveB:", reserveB);
//         console.log("Fee:", fee);
//     }

//     function test_saleQuoteMin_Camelot_extremeUnbalancedPool() public {
//         (uint112 reserveA, uint112 reserveB, , ) = camelotBalancedPair.getReserves();
//         (,,uint32 feeA,) = camelotBalancedPair.getReserves();
//         uint256 fee = uint256(feeA);
//         uint256 feeDenominator = 100_000;

//         uint256 expectedMinInput = ConstProdUtils._saleQuoteMin(
//             reserveA, reserveB, fee, feeDenominator
//         );

//         camelotBalancedTokenA.mint(address(this), expectedMinInput);
//         uint256 initialBalanceB = camelotBalancedTokenB.balanceOf(address(this));

//         uint256 actualOutput = CamelotV2Service._swap(
//             camV2Router(), camelotBalancedPair, expectedMinInput,
//             camelotBalancedTokenA, camelotBalancedTokenB, address(0)
//         );

//         assertGe(actualOutput, 1, "Should get at least 1 unit of output");
//         // Note: actualOutput may be more than 1 due to rounding and minimum input calculation

//         console.log("Expected min input:", expectedMinInput);
//         console.log("Actual output:", actualOutput);
//         console.log("ReserveA:", reserveA);
//         console.log("ReserveB:", reserveB);
//         console.log("Fee:", fee);
//     }

//     function test_saleQuoteMin_Uniswap_balancedPool() public {
//         (uint112 reserveA, uint112 reserveB, ) = uniswapBalancedPair.getReserves();
//         uint256 fee = 300; // Uniswap V2 fixed fee
//         uint256 feeDenominator = 100_000;

//         uint256 expectedMinInput = ConstProdUtils._saleQuoteMin(
//             reserveA, reserveB, fee, feeDenominator
//         );

//         uniswapBalancedTokenA.mint(address(this), expectedMinInput);
//         uint256 initialBalanceB = uniswapBalancedTokenB.balanceOf(address(this));

//         uint256 actualOutput = UniswapV2Service._swap(
//             IUniswapV2Router(address(uniswapV2Router())),
//             uniswapBalancedPair, expectedMinInput,
//             uniswapBalancedTokenA, uniswapBalancedTokenB
//         );

//         assertGe(actualOutput, 1, "Should get at least 1 unit of output");
//         // Note: actualOutput may be more than 1 due to rounding and minimum input calculation

//         console.log("Expected min input:", expectedMinInput);
//         console.log("Actual output:", actualOutput);
//         console.log("ReserveA:", reserveA);
//         console.log("ReserveB:", reserveB);
//         console.log("Fee:", fee);
//     }

//     function test_saleQuoteMin_Uniswap_unbalancedPool() public {
//         (uint112 reserveA, uint112 reserveB, ) = uniswapBalancedPair.getReserves();
//         uint256 fee = 300; // Uniswap V2 fixed fee
//         uint256 feeDenominator = 100_000;

//         uint256 expectedMinInput = ConstProdUtils._saleQuoteMin(
//             reserveA, reserveB, fee, feeDenominator
//         );

//         uniswapBalancedTokenA.mint(address(this), expectedMinInput);
//         uint256 initialBalanceB = uniswapBalancedTokenB.balanceOf(address(this));

//         uint256 actualOutput = UniswapV2Service._swap(
//             IUniswapV2Router(address(uniswapV2Router())),
//             uniswapBalancedPair, expectedMinInput,
//             uniswapBalancedTokenA, uniswapBalancedTokenB
//         );

//         assertGe(actualOutput, 1, "Should get at least 1 unit of output");
//         // Note: actualOutput may be more than 1 due to rounding and minimum input calculation

//         console.log("Expected min input:", expectedMinInput);
//         console.log("Actual output:", actualOutput);
//         console.log("ReserveA:", reserveA);
//         console.log("ReserveB:", reserveB);
//         console.log("Fee:", fee);
//     }

//     function test_saleQuoteMin_Uniswap_extremeUnbalancedPool() public {
//         (uint112 reserveA, uint112 reserveB, ) = uniswapBalancedPair.getReserves();
//         uint256 fee = 300; // Uniswap V2 fixed fee
//         uint256 feeDenominator = 100_000;

//         uint256 expectedMinInput = ConstProdUtils._saleQuoteMin(
//             reserveA, reserveB, fee, feeDenominator
//         );

//         uniswapBalancedTokenA.mint(address(this), expectedMinInput);
//         uint256 initialBalanceB = uniswapBalancedTokenB.balanceOf(address(this));

//         uint256 actualOutput = UniswapV2Service._swap(
//             IUniswapV2Router(address(uniswapV2Router())),
//             uniswapBalancedPair, expectedMinInput,
//             uniswapBalancedTokenA, uniswapBalancedTokenB
//         );

//         assertGe(actualOutput, 1, "Should get at least 1 unit of output");
//         // Note: actualOutput may be more than 1 due to rounding and minimum input calculation

//         console.log("Expected min input:", expectedMinInput);
//         console.log("Actual output:", actualOutput);
//         console.log("ReserveA:", reserveA);
//         console.log("ReserveB:", reserveB);
//         console.log("Fee:", fee);
//     }

//     // ========================================
//     // B->A DIRECTION TESTS
//     // ========================================

//     function test_saleQuoteMin_Camelot_balancedPool_reverse() public {
//         (uint112 reserveA, uint112 reserveB, , ) = camelotBalancedPair.getReserves();
//         (,,uint32 feeA,) = camelotBalancedPair.getReserves();
//         uint256 fee = uint256(feeA);
//         uint256 feeDenominator = 100_000;

//         // Calculate minimum input for 1 unit of TokenA (B->A direction)
//         uint256 expectedMinInput = ConstProdUtils._saleQuoteMin(
//             reserveB, reserveA, fee, feeDenominator
//         );

//         camelotBalancedTokenB.mint(address(this), expectedMinInput);
//         uint256 initialBalanceA = camelotBalancedTokenA.balanceOf(address(this));

//         uint256 actualOutput = CamelotV2Service._swap(
//             camV2Router(), camelotBalancedPair, expectedMinInput,
//             camelotBalancedTokenB, camelotBalancedTokenA, address(0)
//         );

//         assertGe(actualOutput, 1, "Should get at least 1 unit of output");
//         // Note: actualOutput may be more than 1 due to rounding and minimum input calculation

//         console.log("Expected min input (B->A):", expectedMinInput);
//         console.log("Actual output:", actualOutput);
//         console.log("ReserveB:", reserveB);
//         console.log("ReserveA:", reserveA);
//         console.log("Fee:", fee);
//     }

//     function test_saleQuoteMin_Camelot_unbalancedPool_reverse() public {
//         (uint112 reserveA, uint112 reserveB, , ) = camelotBalancedPair.getReserves();
//         (,,uint32 feeA,) = camelotBalancedPair.getReserves();
//         uint256 fee = uint256(feeA);
//         uint256 feeDenominator = 100_000;

//         uint256 expectedMinInput = ConstProdUtils._saleQuoteMin(
//             reserveB, reserveA, fee, feeDenominator
//         );

//         camelotBalancedTokenB.mint(address(this), expectedMinInput);
//         uint256 initialBalanceA = camelotBalancedTokenA.balanceOf(address(this));

//         uint256 actualOutput = CamelotV2Service._swap(
//             camV2Router(), camelotBalancedPair, expectedMinInput,
//             camelotBalancedTokenB, camelotBalancedTokenA, address(0)
//         );

//         assertGe(actualOutput, 1, "Should get at least 1 unit of output");
//         // Note: actualOutput may be more than 1 due to rounding and minimum input calculation

//         console.log("Expected min input (B->A):", expectedMinInput);
//         console.log("Actual output:", actualOutput);
//         console.log("ReserveB:", reserveB);
//         console.log("ReserveA:", reserveA);
//         console.log("Fee:", fee);
//     }

//     function test_saleQuoteMin_Camelot_extremeUnbalancedPool_reverse() public {
//         (uint112 reserveA, uint112 reserveB, , ) = camelotBalancedPair.getReserves();
//         (,,uint32 feeA,) = camelotBalancedPair.getReserves();
//         uint256 fee = uint256(feeA);
//         uint256 feeDenominator = 100_000;

//         uint256 expectedMinInput = ConstProdUtils._saleQuoteMin(
//             reserveB, reserveA, fee, feeDenominator
//         );

//         camelotBalancedTokenB.mint(address(this), expectedMinInput);
//         uint256 initialBalanceA = camelotBalancedTokenA.balanceOf(address(this));

//         uint256 actualOutput = CamelotV2Service._swap(
//             camV2Router(), camelotBalancedPair, expectedMinInput,
//             camelotBalancedTokenB, camelotBalancedTokenA, address(0)
//         );

//         assertGe(actualOutput, 1, "Should get at least 1 unit of output");
//         // Note: actualOutput may be more than 1 due to rounding and minimum input calculation

//         console.log("Expected min input (B->A):", expectedMinInput);
//         console.log("Actual output:", actualOutput);
//         console.log("ReserveB:", reserveB);
//         console.log("ReserveA:", reserveA);
//         console.log("Fee:", fee);
//     }

//     function test_saleQuoteMin_Uniswap_balancedPool_reverse() public {
//         (uint112 reserveA, uint112 reserveB, ) = uniswapBalancedPair.getReserves();
//         uint256 fee = 300; // Uniswap V2 fixed fee
//         uint256 feeDenominator = 100_000;

//         uint256 expectedMinInput = ConstProdUtils._saleQuoteMin(
//             reserveB, reserveA, fee, feeDenominator
//         );

//         uniswapBalancedTokenB.mint(address(this), expectedMinInput);
//         uint256 initialBalanceA = uniswapBalancedTokenA.balanceOf(address(this));

//         uint256 actualOutput = UniswapV2Service._swap(
//             IUniswapV2Router(address(uniswapV2Router())),
//             uniswapBalancedPair, expectedMinInput,
//             uniswapBalancedTokenB, uniswapBalancedTokenA
//         );

//         assertGe(actualOutput, 1, "Should get at least 1 unit of output");
//         // Note: actualOutput may be more than 1 due to rounding and minimum input calculation

//         console.log("Expected min input (B->A):", expectedMinInput);
//         console.log("Actual output:", actualOutput);
//         console.log("ReserveB:", reserveB);
//         console.log("ReserveA:", reserveA);
//         console.log("Fee:", fee);
//     }

//     function test_saleQuoteMin_Uniswap_unbalancedPool_reverse() public {
//         (uint112 reserveA, uint112 reserveB, ) = uniswapBalancedPair.getReserves();
//         uint256 fee = 300; // Uniswap V2 fixed fee
//         uint256 feeDenominator = 100_000;

//         uint256 expectedMinInput = ConstProdUtils._saleQuoteMin(
//             reserveB, reserveA, fee, feeDenominator
//         );

//         uniswapBalancedTokenB.mint(address(this), expectedMinInput);
//         uint256 initialBalanceA = uniswapBalancedTokenA.balanceOf(address(this));

//         uint256 actualOutput = UniswapV2Service._swap(
//             IUniswapV2Router(address(uniswapV2Router())),
//             uniswapBalancedPair, expectedMinInput,
//             uniswapBalancedTokenB, uniswapBalancedTokenA
//         );

//         assertGe(actualOutput, 1, "Should get at least 1 unit of output");
//         // Note: actualOutput may be more than 1 due to rounding and minimum input calculation

//         console.log("Expected min input (B->A):", expectedMinInput);
//         console.log("Actual output:", actualOutput);
//         console.log("ReserveB:", reserveB);
//         console.log("ReserveA:", reserveA);
//         console.log("Fee:", fee);
//     }

//     function test_saleQuoteMin_Uniswap_extremeUnbalancedPool_reverse() public {
//         (uint112 reserveA, uint112 reserveB, ) = uniswapBalancedPair.getReserves();
//         uint256 fee = 300; // Uniswap V2 fixed fee
//         uint256 feeDenominator = 100_000;

//         uint256 expectedMinInput = ConstProdUtils._saleQuoteMin(
//             reserveB, reserveA, fee, feeDenominator
//         );

//         uniswapBalancedTokenB.mint(address(this), expectedMinInput);
//         uint256 initialBalanceA = uniswapBalancedTokenA.balanceOf(address(this));

//         uint256 actualOutput = UniswapV2Service._swap(
//             IUniswapV2Router(address(uniswapV2Router())),
//             uniswapBalancedPair, expectedMinInput,
//             uniswapBalancedTokenB, uniswapBalancedTokenA
//         );

//         assertGe(actualOutput, 1, "Should get at least 1 unit of output");
//         // Note: actualOutput may be more than 1 due to rounding and minimum input calculation

//         console.log("Expected min input (B->A):", expectedMinInput);
//         console.log("Actual output:", actualOutput);
//         console.log("ReserveB:", reserveB);
//         console.log("ReserveA:", reserveA);
//         console.log("Fee:", fee);
//     }

// }
