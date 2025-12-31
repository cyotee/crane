// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TestBase_ConstProdUtils.sol";
import "../../../../../../contracts/crane/utils/math/ConstProdUtils.sol";
import {CamelotV2Service} from "contracts/crane/protocols/dexes/camelot/v2/utils/CamelotV2Service.sol";
import {UniswapV2Service} from "contracts/crane/protocols/dexes/uniswap/v2/utils/UniswapV2Service.sol";

// contract Test_ConstProdUtils_calculateVaultFee is TestBase_ConstProdUtils {
//     using ConstProdUtils for uint256;

//     struct TestData {
//         uint256 reserveA;
//         uint256 reserveB;
//         uint256 totalSupply;
//         uint256 lastK;
//         uint256 vaultFee;
//         uint256 feeDenominator;
//         uint256 expectedFeeAmount;
//         uint256 expectedNewK;
//         uint256 actualNewK;
//         uint256 actualFeeAmount;
//     }

//     // TODO Stack too deep error
//     // function test_calculateVaultFee_Camelot_balancedPool() public {
//     //     TestData memory data;

//     //     // Get initial reserves and fees from Camelot pool
//     //     (uint112 initialReserve0, uint112 initialReserve1, uint16 token0Fee, uint16 token1Fee) = camelotBalancedPair.getReserves();
//     //     data.totalSupply = camelotBalancedPair.totalSupply();

//     //     // Sort initial reserves and fees to match token order
//     //     (data.reserveA, , data.reserveB, ) = ConstProdUtils._sortReserves(
//     //         address(camelotBalancedTokenA),
//     //         camelotBalancedPair.token0(),
//     //         initialReserve0,
//     //         token0Fee,
//     //         initialReserve1,
//     //         token1Fee
//     //     );

//     //     // Record initial state (last known state)
//     //     data.lastK = data.reserveA * data.reserveB;
//     //     data.vaultFee = 500; // 0.5%
//     //     data.feeDenominator = 100000; // 100,000

//     //     // Perform trades to accumulate fees and increase K
//     //     uint256 tradeAmount = 1000e18; // Reasonable trade amount
//     //     camelotBalancedTokenA.mint(address(this), tradeAmount);

//     //     // Perform multiple trades to create meaningful K growth
//     //     for (uint i = 0; i < 3; i++) {
//     //         CamelotV2Service._swap(
//     //             camV2Router(),
//     //             camelotBalancedPair,
//     //             tradeAmount / 3, // Split into smaller trades
//     //             camelotBalancedTokenA,
//     //             camelotBalancedTokenB,
//     //             address(0) // referrer
//     //         );
//     //     }

//     //     // Record current state after trades
//     //     (uint112 newReserve0, uint112 newReserve1, uint16 newToken0Fee, uint16 newToken1Fee) = camelotBalancedPair.getReserves();
//     //     uint256 newTotalSupply = camelotBalancedPair.totalSupply();

//     //     // Sort new reserves and fees to match token order
//     //     (data.reserveA, , data.reserveB, ) = ConstProdUtils._sortReserves(
//     //         address(camelotBalancedTokenA),
//     //         camelotBalancedPair.token0(),
//     //         newReserve0,
//     //         newToken0Fee,
//     //         newReserve1,
//     //         newToken1Fee
//     //     );

//     //     // Calculate expected vault fee using the function
//     //     (data.expectedFeeAmount, data.expectedNewK) = ConstProdUtils._calculateVaultFee(
//     //         data.reserveA,
//     //         data.reserveB,
//     //         newTotalSupply,
//     //         data.lastK,
//     //         data.vaultFee,
//     //         data.feeDenominator
//     //     );

//     //     // Calculate actual vault fee from K growth using the same formula
//     //     data.actualNewK = data.reserveA * data.reserveB;
//     //     uint256 rootK = Math.sqrt(data.actualNewK);
//     //     uint256 rootKLast = Math.sqrt(data.lastK);

//     //     data.actualFeeAmount = 0;
//     //     if (rootK > rootKLast) {
//     //         uint256 d = (data.feeDenominator * 100 / data.vaultFee) - 100;
//     //         uint256 numerator = newTotalSupply * (rootK - rootKLast) * 100;
//     //         uint256 denominator = rootK * d + rootKLast * 100;
//     //         data.actualFeeAmount = numerator / denominator;
//     //     }

//     //     // Verify the calculation matches actual vault fee
//     //     assertEq(data.expectedFeeAmount, data.actualFeeAmount, "Expected vault fee should match actual");
//     //     assertEq(data.expectedNewK, data.actualNewK, "Expected newK should match actual");

//     //     // Verify fee amount is calculated when K has grown
//     //     assertGt(data.expectedFeeAmount, 0, "Fee amount should be greater than 0 when K has grown");

//     //     // Verify fee amount is reasonable (should be much less than total supply)
//     //     assertLt(data.expectedFeeAmount, newTotalSupply / 10, "Fee amount should be much less than total supply");
//     // }

//     // TODO Stack too deep error
//     // function test_calculateVaultFee_Camelot_unbalancedPool() public {
//     //     TestData memory data;

//     //     // Get initial reserves and fees from Camelot pool
//     //     (uint112 initialReserve0, uint112 initialReserve1, uint16 token0Fee, uint16 token1Fee) = camelotUnbalancedPair.getReserves();
//     //     data.totalSupply = camelotUnbalancedPair.totalSupply();

//     //     // Sort initial reserves and fees to match token order
//     //     (data.reserveA, , data.reserveB, ) = ConstProdUtils._sortReserves(
//     //         address(camelotUnbalancedTokenA),
//     //         camelotUnbalancedPair.token0(),
//     //         initialReserve0,
//     //         token0Fee,
//     //         initialReserve1,
//     //         token1Fee
//     //     );

//     //     // Record initial state (last known state)
//     //     data.lastK = data.reserveA * data.reserveB;
//     //     data.vaultFee = 500; // 0.5%
//     //     data.feeDenominator = 100000; // 100,000

//     //     // Perform trades to accumulate fees and increase K
//     //     uint256 tradeAmount = 100e18; // Smaller trade amount for unbalanced pool
//     //     camelotUnbalancedTokenA.mint(address(this), tradeAmount);

//     //     // Perform multiple trades to create meaningful K growth
//     //     for (uint i = 0; i < 2; i++) {
//     //         CamelotV2Service._swap(
//     //             camV2Router(),
//     //             camelotUnbalancedPair,
//     //             tradeAmount / 2, // Split into smaller trades
//     //             camelotUnbalancedTokenA,
//     //             camelotUnbalancedTokenB,
//     //             address(0) // referrer
//     //         );
//     //     }

//     //     // Record current state after trades
//     //     (uint112 newReserve0, uint112 newReserve1, uint16 newToken0Fee, uint16 newToken1Fee) = camelotUnbalancedPair.getReserves();
//     //     uint256 newTotalSupply = camelotUnbalancedPair.totalSupply();

//     //     // Sort new reserves and fees to match token order
//     //     (data.reserveA, , data.reserveB, ) = ConstProdUtils._sortReserves(
//     //         address(camelotUnbalancedTokenA),
//     //         camelotUnbalancedPair.token0(),
//     //         newReserve0,
//     //         newToken0Fee,
//     //         newReserve1,
//     //         newToken1Fee
//     //     );

//     //     // Calculate expected vault fee using the function
//     //     (data.expectedFeeAmount, data.expectedNewK) = ConstProdUtils._calculateVaultFee(
//     //         data.reserveA,
//     //         data.reserveB,
//     //         newTotalSupply,
//     //         data.lastK,
//     //         data.vaultFee,
//     //         data.feeDenominator
//     //     );

//     //     // Calculate actual vault fee from K growth using the same formula
//     //     data.actualNewK = data.reserveA * data.reserveB;
//     //     uint256 rootK = Math.sqrt(data.actualNewK);
//     //     uint256 rootKLast = Math.sqrt(data.lastK);

//     //     data.actualFeeAmount = 0;
//     //     if (rootK > rootKLast) {
//     //         uint256 d = (data.feeDenominator * 100 / data.vaultFee) - 100;
//     //         uint256 numerator = newTotalSupply * (rootK - rootKLast) * 100;
//     //         uint256 denominator = rootK * d + rootKLast * 100;
//     //         data.actualFeeAmount = numerator / denominator;
//     //     }

//     //     // Verify the calculation matches actual vault fee
//     //     assertEq(data.expectedFeeAmount, data.actualFeeAmount, "Expected vault fee should match actual");
//     //     assertEq(data.expectedNewK, data.actualNewK, "Expected newK should match actual");

//     //     // Verify fee amount is calculated when K has grown
//     //     assertGt(data.expectedFeeAmount, 0, "Fee amount should be greater than 0 when K has grown");

//     //     // Verify fee amount is reasonable (should be much less than total supply)
//     //     assertLt(data.expectedFeeAmount, newTotalSupply / 10, "Fee amount should be much less than total supply");
//     // }

//     function test_calculateVaultFee_Camelot_extremeUnbalancedPool() public {
//         (uint112 reserve0, uint112 reserve1, , ) = camelotExtremeUnbalancedPair.getReserves();
//         uint256 totalSupply = camelotExtremeUnbalancedPair.totalSupply();

//         // Sort reserves to match token order
//         (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
//             address(camelotExtremeTokenA),
//             camelotExtremeUnbalancedPair.token0(),
//             reserve0,
//             reserve1
//         );

//         uint256 lastK = (reserveA * reserveB) / 2; // Previous K was half current
//         uint256 vaultFee = 500; // 0.5%
//         uint256 feeDenominator = 100000; // 100,000

//         // Calculate expected values
//         (uint256 expectedFeeAmount, uint256 expectedNewK) = ConstProdUtils._calculateVaultFee(
//             reserveA,
//             reserveB,
//             totalSupply,
//             lastK,
//             vaultFee,
//             feeDenominator
//         );

//         // Verify newK is calculated correctly
//         assertEq(expectedNewK, reserveA * reserveB, "NewK should equal reserveA * reserveB");

//         // Verify fee amount is calculated when K has grown
//         assertGt(expectedFeeAmount, 0, "Fee amount should be greater than 0 when K has grown");
//     }

//     function test_calculateVaultFee_Uniswap_balancedPool() public {
//         (uint112 reserve0, uint112 reserve1, ) = uniswapBalancedPair.getReserves();
//         uint256 totalSupply = uniswapBalancedPair.totalSupply();

//         // Sort reserves to match token order
//         (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
//             address(uniswapBalancedTokenA),
//             uniswapBalancedPair.token0(),
//             reserve0,
//             reserve1
//         );

//         uint256 lastK = (reserveA * reserveB) / 2; // Previous K was half current
//         uint256 vaultFee = 500; // 0.5%
//         uint256 feeDenominator = 100000; // 100,000

//         // Calculate expected values
//         (uint256 expectedFeeAmount, uint256 expectedNewK) = ConstProdUtils._calculateVaultFee(
//             reserveA,
//             reserveB,
//             totalSupply,
//             lastK,
//             vaultFee,
//             feeDenominator
//         );

//         // Verify newK is calculated correctly
//         assertEq(expectedNewK, reserveA * reserveB, "NewK should equal reserveA * reserveB");

//         // Verify fee amount is calculated when K has grown
//         assertGt(expectedFeeAmount, 0, "Fee amount should be greater than 0 when K has grown");
//     }

//     function test_calculateVaultFee_Uniswap_unbalancedPool() public {
//         (uint112 reserve0, uint112 reserve1, ) = uniswapUnbalancedPair.getReserves();
//         uint256 totalSupply = uniswapUnbalancedPair.totalSupply();

//         // Sort reserves to match token order
//         (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
//             address(uniswapUnbalancedTokenA),
//             uniswapUnbalancedPair.token0(),
//             reserve0,
//             reserve1
//         );

//         uint256 lastK = (reserveA * reserveB) / 2; // Previous K was half current
//         uint256 vaultFee = 500; // 0.5%
//         uint256 feeDenominator = 100000; // 100,000

//         // Calculate expected values
//         (uint256 expectedFeeAmount, uint256 expectedNewK) = ConstProdUtils._calculateVaultFee(
//             reserveA,
//             reserveB,
//             totalSupply,
//             lastK,
//             vaultFee,
//             feeDenominator
//         );

//         // Verify newK is calculated correctly
//         assertEq(expectedNewK, reserveA * reserveB, "NewK should equal reserveA * reserveB");

//         // Verify fee amount is calculated when K has grown
//         assertGt(expectedFeeAmount, 0, "Fee amount should be greater than 0 when K has grown");
//     }

//     function test_calculateVaultFee_Uniswap_extremeUnbalancedPool() public {
//         (uint112 reserve0, uint112 reserve1, ) = uniswapExtremeUnbalancedPair.getReserves();
//         uint256 totalSupply = uniswapExtremeUnbalancedPair.totalSupply();

//         // Sort reserves to match token order
//         (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
//             address(uniswapExtremeTokenA),
//             uniswapExtremeUnbalancedPair.token0(),
//             reserve0,
//             reserve1
//         );

//         uint256 lastK = (reserveA * reserveB) / 2; // Previous K was half current
//         uint256 vaultFee = 500; // 0.5%
//         uint256 feeDenominator = 100000; // 100,000

//         // Calculate expected values
//         (uint256 expectedFeeAmount, uint256 expectedNewK) = ConstProdUtils._calculateVaultFee(
//             reserveA,
//             reserveB,
//             totalSupply,
//             lastK,
//             vaultFee,
//             feeDenominator
//         );

//         // Verify newK is calculated correctly
//         assertEq(expectedNewK, reserveA * reserveB, "NewK should equal reserveA * reserveB");

//         // Verify fee amount is calculated when K has grown
//         assertGt(expectedFeeAmount, 0, "Fee amount should be greater than 0 when K has grown");
//     }

//     // Tests for _calculateVaultFeeNoNewK function
//     function test_calculateVaultFeeNoNewK_Camelot_balancedPool() public {
//         (uint112 reserve0, uint112 reserve1, , ) = camelotBalancedPair.getReserves();
//         uint256 totalSupply = camelotBalancedPair.totalSupply();

//         // Sort reserves to match token order
//         (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
//             address(camelotBalancedTokenA),
//             camelotBalancedPair.token0(),
//             reserve0,
//             reserve1
//         );

//         uint256 lastK = (reserveA * reserveB) / 2; // Previous K was half current
//         uint256 vaultFee = 500; // 0.5%
//         uint256 feeDenominator = 100000; // 100,000

//         // Calculate expected values
//         uint256 expectedLpOfYield = ConstProdUtils._calculateVaultFeeNoNewK(
//             reserveA,
//             reserveB,
//             totalSupply,
//             lastK,
//             vaultFee,
//             feeDenominator
//         );

//         // Verify fee amount is calculated when K has grown
//         assertGt(expectedLpOfYield, 0, "LP of yield should be greater than 0 when K has grown");

//         // Verify fee amount is reasonable (should be much less than total supply)
//         assertLt(expectedLpOfYield, totalSupply / 10, "LP of yield should be much less than total supply");
//     }

//     function test_calculateVaultFeeNoNewK_Camelot_unbalancedPool() public {
//         (uint112 reserve0, uint112 reserve1, , ) = camelotUnbalancedPair.getReserves();
//         uint256 totalSupply = camelotUnbalancedPair.totalSupply();

//         // Sort reserves to match token order
//         (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
//             address(camelotUnbalancedTokenA),
//             camelotUnbalancedPair.token0(),
//             reserve0,
//             reserve1
//         );

//         uint256 lastK = (reserveA * reserveB) / 2; // Previous K was half current
//         uint256 vaultFee = 500; // 0.5%
//         uint256 feeDenominator = 100000; // 100,000

//         // Calculate expected values
//         uint256 expectedLpOfYield = ConstProdUtils._calculateVaultFeeNoNewK(
//             reserveA,
//             reserveB,
//             totalSupply,
//             lastK,
//             vaultFee,
//             feeDenominator
//         );

//         // Verify fee amount is calculated when K has grown
//         assertGt(expectedLpOfYield, 0, "LP of yield should be greater than 0 when K has grown");
//     }

//     function test_calculateVaultFeeNoNewK_Camelot_extremeUnbalancedPool() public {
//         (uint112 reserve0, uint112 reserve1, , ) = camelotExtremeUnbalancedPair.getReserves();
//         uint256 totalSupply = camelotExtremeUnbalancedPair.totalSupply();

//         // Sort reserves to match token order
//         (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
//             address(camelotExtremeTokenA),
//             camelotExtremeUnbalancedPair.token0(),
//             reserve0,
//             reserve1
//         );

//         uint256 lastK = (reserveA * reserveB) / 2; // Previous K was half current
//         uint256 vaultFee = 500; // 0.5%
//         uint256 feeDenominator = 100000; // 100,000

//         // Calculate expected values
//         uint256 expectedLpOfYield = ConstProdUtils._calculateVaultFeeNoNewK(
//             reserveA,
//             reserveB,
//             totalSupply,
//             lastK,
//             vaultFee,
//             feeDenominator
//         );

//         // Verify fee amount is calculated when K has grown
//         assertGt(expectedLpOfYield, 0, "LP of yield should be greater than 0 when K has grown");
//     }

//     function test_calculateVaultFeeNoNewK_Uniswap_balancedPool() public {
//         (uint112 reserve0, uint112 reserve1, ) = uniswapBalancedPair.getReserves();
//         uint256 totalSupply = uniswapBalancedPair.totalSupply();

//         // Sort reserves to match token order
//         (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
//             address(uniswapBalancedTokenA),
//             uniswapBalancedPair.token0(),
//             reserve0,
//             reserve1
//         );

//         uint256 lastK = (reserveA * reserveB) / 2; // Previous K was half current
//         uint256 vaultFee = 500; // 0.5%
//         uint256 feeDenominator = 100000; // 100,000

//         // Calculate expected values
//         uint256 expectedLpOfYield = ConstProdUtils._calculateVaultFeeNoNewK(
//             reserveA,
//             reserveB,
//             totalSupply,
//             lastK,
//             vaultFee,
//             feeDenominator
//         );

//         // Verify fee amount is calculated when K has grown
//         assertGt(expectedLpOfYield, 0, "LP of yield should be greater than 0 when K has grown");
//     }

//     function test_calculateVaultFeeNoNewK_Uniswap_unbalancedPool() public {
//         (uint112 reserve0, uint112 reserve1, ) = uniswapUnbalancedPair.getReserves();
//         uint256 totalSupply = uniswapUnbalancedPair.totalSupply();

//         // Sort reserves to match token order
//         (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
//             address(uniswapUnbalancedTokenA),
//             uniswapUnbalancedPair.token0(),
//             reserve0,
//             reserve1
//         );

//         uint256 lastK = (reserveA * reserveB) / 2; // Previous K was half current
//         uint256 vaultFee = 500; // 0.5%
//         uint256 feeDenominator = 100000; // 100,000

//         // Calculate expected values
//         uint256 expectedLpOfYield = ConstProdUtils._calculateVaultFeeNoNewK(
//             reserveA,
//             reserveB,
//             totalSupply,
//             lastK,
//             vaultFee,
//             feeDenominator
//         );

//         // Verify fee amount is calculated when K has grown
//         assertGt(expectedLpOfYield, 0, "LP of yield should be greater than 0 when K has grown");
//     }

//     function test_calculateVaultFeeNoNewK_Uniswap_extremeUnbalancedPool() public {
//         (uint112 reserve0, uint112 reserve1, ) = uniswapExtremeUnbalancedPair.getReserves();
//         uint256 totalSupply = uniswapExtremeUnbalancedPair.totalSupply();

//         // Sort reserves to match token order
//         (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
//             address(uniswapExtremeTokenA),
//             uniswapExtremeUnbalancedPair.token0(),
//             reserve0,
//             reserve1
//         );

//         uint256 lastK = (reserveA * reserveB) / 2; // Previous K was half current
//         uint256 vaultFee = 500; // 0.5%
//         uint256 feeDenominator = 100000; // 100,000

//         // Calculate expected values
//         uint256 expectedLpOfYield = ConstProdUtils._calculateVaultFeeNoNewK(
//             reserveA,
//             reserveB,
//             totalSupply,
//             lastK,
//             vaultFee,
//             feeDenominator
//         );

//         // Verify fee amount is calculated when K has grown
//         assertGt(expectedLpOfYield, 0, "LP of yield should be greater than 0 when K has grown");
//     }

//     // Test to verify both functions return the same fee amount
//     function test_calculateVaultFee_consistency() public {
//         (uint112 reserve0, uint112 reserve1, , ) = camelotBalancedPair.getReserves();
//         uint256 totalSupply = camelotBalancedPair.totalSupply();

//         // Sort reserves to match token order
//         (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
//             address(camelotBalancedTokenA),
//             camelotBalancedPair.token0(),
//             reserve0,
//             reserve1
//         );

//         uint256 lastK = (reserveA * reserveB) / 2; // Previous K was half current
//         uint256 vaultFee = 500; // 0.5%
//         uint256 feeDenominator = 100000; // 100,000

//         // Calculate using both functions
//         (uint256 feeAmount, uint256 newK) = ConstProdUtils._calculateVaultFee(
//             reserveA,
//             reserveB,
//             totalSupply,
//             lastK,
//             vaultFee,
//             feeDenominator
//         );

//         uint256 lpOfYield = ConstProdUtils._calculateVaultFeeNoNewK(
//             reserveA,
//             reserveB,
//             totalSupply,
//             lastK,
//             vaultFee,
//             feeDenominator
//         );

//         // Verify both functions return the same fee amount
//         assertEq(feeAmount, lpOfYield, "Both functions should return the same fee amount");
//         assertEq(newK, reserveA * reserveB, "NewK should equal reserveA * reserveB");
//     }
// }
