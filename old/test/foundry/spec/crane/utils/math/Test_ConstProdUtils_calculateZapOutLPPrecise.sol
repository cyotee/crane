// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {TestBase_ConstProdUtils} from "./TestBase_ConstProdUtils.sol";
import {ConstProdUtils} from "contracts/crane/utils/math/ConstProdUtils.sol";

// contract Test_ConstProdUtils_calculateZapOutLPPrecise is TestBase_ConstProdUtils {

//     function setUp() public override {
//         super.setUp();
//     }

//     // Basic Functionality Tests (6 tests)

//     function test_calculateZapOutLPPrecise_Camelot_balancedPool() public {
//         (uint112 reserve0, uint112 reserve1, uint16 token0Fee, uint16 token1Fee) = camelotBalancedPair.getReserves();
//         (uint256 reserveA, uint256 feePercent, uint256 reserveB, uint256 tokenBFee) = ConstProdUtils._sortReserves(
//             address(camelotBalancedTokenA), camelotBalancedPair.token0(), reserve0, uint256(token0Fee), reserve1, uint256(token1Fee)
//         );
//         uint256 lpTotalSupply = camelotBalancedPair.totalSupply();

//         // Set desired TokenA amount (reasonable portion of reserves)
//         uint256 desiredOut = reserveA / 10; // 10% of TokenA reserves

//         // Calculate expected LP needed using the PRECISE version
//         uint256 expectedLpNeeded = ConstProdUtils._calculateZapOutLPPrecise(
//             desiredOut, reserveA, reserveB, lpTotalSupply, feePercent, 100000
//         );

//         // Execute actual ZapOut
//         uint256 initialTokenABalance = camelotBalancedTokenA.balanceOf(address(this));

//         // Withdraw the calculated LP amount
//         camelotBalancedPair.transfer(address(camelotBalancedPair), expectedLpNeeded);
//         (uint256 amountA, uint256 amountB) = camelotBalancedPair.burn(address(this));

//         // Swap amountB for TokenA
//         if (amountB > 0) {
//             camelotBalancedTokenB.approve(address(camV2Router()), amountB);
//             address[] memory path = new address[](2);
//             path[0] = address(camelotBalancedTokenB);
//             path[1] = address(camelotBalancedTokenA);

//             camV2Router().swapExactTokensForTokensSupportingFeeOnTransferTokens(
//                 amountB, 1, path, address(this), address(0), block.timestamp
//             );
//         }

//         // Calculate actual TokenA received
//         uint256 finalTokenABalance = camelotBalancedTokenA.balanceOf(address(this));
//         uint256 actualTokenAReceived = finalTokenABalance - initialTokenABalance;

//         // Verify we received exactly the desired amount
//         assertEq(actualTokenAReceived, desiredOut,
//             "Should receive exactly the desired TokenA amount");
//     }

//     function test_calculateZapOutLPPrecise_Camelot_unbalancedPool() public {
//         (uint112 reserve0, uint112 reserve1, uint16 token0Fee, uint16 token1Fee) = camelotUnbalancedPair.getReserves();
//         (uint256 reserveA, uint256 feePercent, uint256 reserveB, uint256 tokenBFee) = ConstProdUtils._sortReserves(
//             address(camelotUnbalancedTokenA), camelotUnbalancedPair.token0(), reserve0, uint256(token0Fee), reserve1, uint256(token1Fee)
//         );
//         uint256 lpTotalSupply = camelotUnbalancedPair.totalSupply();

//         // Set desired TokenA amount (reasonable portion of reserves)
//         uint256 desiredOut = reserveA / 8; // 12.5% of TokenA reserves

//         // Calculate expected LP needed using the PRECISE version
//         uint256 expectedLpNeeded = ConstProdUtils._calculateZapOutLPPrecise(
//             desiredOut, reserveA, reserveB, lpTotalSupply, feePercent, 100000
//         );

//         // Execute actual ZapOut
//         uint256 initialTokenABalance = camelotUnbalancedTokenA.balanceOf(address(this));

//         // Withdraw the calculated LP amount
//         camelotUnbalancedPair.transfer(address(camelotUnbalancedPair), expectedLpNeeded);
//         (uint256 amountA, uint256 amountB) = camelotUnbalancedPair.burn(address(this));

//         // Swap amountB for TokenA
//         if (amountB > 0) {
//             camelotUnbalancedTokenB.approve(address(camV2Router()), amountB);
//             address[] memory path = new address[](2);
//             path[0] = address(camelotUnbalancedTokenB);
//             path[1] = address(camelotUnbalancedTokenA);

//             camV2Router().swapExactTokensForTokensSupportingFeeOnTransferTokens(
//                 amountB, 1, path, address(this), address(0), block.timestamp
//             );
//         }

//         // Calculate actual TokenA received
//         uint256 finalTokenABalance = camelotBalancedTokenA.balanceOf(address(this));
//         uint256 actualTokenAReceived = finalTokenABalance - initialTokenABalance;

//         // Verify we received exactly the desired amount
//         assertEq(actualTokenAReceived, desiredOut,
//             "Should receive exactly the desired TokenA amount");
//     }

//     function test_calculateZapOutLPPrecise_Camelot_extremeUnbalancedPool() public {
//         (uint112 reserveA, uint112 reserveB, , ) = camelotBalancedPair.getReserves();
//         (,,uint32 feeA,) = camelotBalancedPair.getReserves();
//         uint256 feePercent = uint256(feeA);
//         uint256 lpTotalSupply = camelotBalancedPair.totalSupply();

//         // Set desired TokenA amount (reasonable portion of reserves)
//         uint256 desiredOut = reserveA / 20; // 5% of TokenA reserves

//         // Calculate expected LP needed using the PRECISE version
//         uint256 expectedLpNeeded = ConstProdUtils._calculateZapOutLPPrecise(
//             desiredOut, reserveA, reserveB, lpTotalSupply, feePercent, 100000
//         );

//         // Execute actual ZapOut
//         uint256 initialTokenABalance = camelotBalancedTokenA.balanceOf(address(this));

//         // Withdraw the calculated LP amount
//         camelotBalancedPair.transfer(address(camelotBalancedPair), expectedLpNeeded);
//         (uint256 amountA, uint256 amountB) = camelotBalancedPair.burn(address(this));

//         // Swap amountB for TokenA
//         if (amountB > 0) {
//             camelotBalancedTokenB.approve(address(camV2Router()), amountB);
//             address[] memory path = new address[](2);
//             path[0] = address(camelotBalancedTokenB);
//             path[1] = address(camelotBalancedTokenA);

//             camV2Router().swapExactTokensForTokensSupportingFeeOnTransferTokens(
//                 amountB, 1, path, address(this), address(0), block.timestamp
//             );
//         }

//         // Calculate actual TokenA received
//         uint256 finalTokenABalance = camelotBalancedTokenA.balanceOf(address(this));
//         uint256 actualTokenAReceived = finalTokenABalance - initialTokenABalance;

//         // Verify we received exactly the desired amount
//         assertEq(actualTokenAReceived, desiredOut,
//             "Should receive exactly the desired TokenA amount");
//     }

//     function test_calculateZapOutLPPrecise_Uniswap_balancedPool() public {
//         (uint112 reserveA, uint112 reserveB, ) = uniswapBalancedPair.getReserves();
//         uint256 lpTotalSupply = uniswapBalancedPair.totalSupply();

//         // Set desired TokenA amount (reasonable portion of reserves)
//         uint256 desiredOut = reserveA / 10; // 10% of TokenA reserves

//         // Calculate expected LP needed using the PRECISE version
//         uint256 expectedLpNeeded = ConstProdUtils._calculateZapOutLPPrecise(
//             desiredOut, reserveA, reserveB, lpTotalSupply, 300, 100000
//         );

//         // Execute actual ZapOut
//         uint256 initialTokenABalance = uniswapBalancedTokenA.balanceOf(address(this));

//         // Withdraw the calculated LP amount
//         uniswapBalancedPair.transfer(address(uniswapBalancedPair), expectedLpNeeded);
//         (uint256 amountA, uint256 amountB) = uniswapBalancedPair.burn(address(this));

//         // Swap amountB for TokenA
//         if (amountB > 0) {
//             uniswapBalancedTokenB.approve(address(uniswapV2Router()), amountB);
//             address[] memory path = new address[](2);
//             path[0] = address(uniswapBalancedTokenB);
//             path[1] = address(uniswapBalancedTokenA);

//             uniswapV2Router().swapExactTokensForTokensSupportingFeeOnTransferTokens(
//                 amountB, 1, path, address(this), block.timestamp
//             );
//         }

//         // Calculate actual TokenA received
//         uint256 finalTokenABalance = uniswapBalancedTokenA.balanceOf(address(this));
//         uint256 actualTokenAReceived = finalTokenABalance - initialTokenABalance;

//         // Verify we received exactly the desired amount
//         assertEq(actualTokenAReceived, desiredOut,
//             "Should receive exactly the desired TokenA amount");
//     }

//     function test_calculateZapOutLPPrecise_Uniswap_unbalancedPool() public {
//         (uint112 reserveA, uint112 reserveB, ) = uniswapBalancedPair.getReserves();
//         uint256 lpTotalSupply = uniswapBalancedPair.totalSupply();

//         // Set desired TokenA amount (reasonable portion of reserves)
//         uint256 desiredOut = reserveA / 8; // 12.5% of TokenA reserves

//         // Calculate expected LP needed using the PRECISE version
//         uint256 expectedLpNeeded = ConstProdUtils._calculateZapOutLPPrecise(
//             desiredOut, reserveA, reserveB, lpTotalSupply, 300, 100000
//         );

//         // Execute actual ZapOut
//         uint256 initialTokenABalance = uniswapBalancedTokenA.balanceOf(address(this));

//         // Withdraw the calculated LP amount
//         uniswapBalancedPair.transfer(address(uniswapBalancedPair), expectedLpNeeded);
//         (uint256 amountA, uint256 amountB) = uniswapBalancedPair.burn(address(this));

//         // Swap amountB for TokenA
//         if (amountB > 0) {
//             uniswapBalancedTokenB.approve(address(uniswapV2Router()), amountB);
//             address[] memory path = new address[](2);
//             path[0] = address(uniswapBalancedTokenB);
//             path[1] = address(uniswapBalancedTokenA);

//             uniswapV2Router().swapExactTokensForTokensSupportingFeeOnTransferTokens(
//                 amountB, 1, path, address(this), block.timestamp
//             );
//         }

//         // Calculate actual TokenA received
//         uint256 finalTokenABalance = uniswapBalancedTokenA.balanceOf(address(this));
//         uint256 actualTokenAReceived = finalTokenABalance - initialTokenABalance;

//         // Verify we received exactly the desired amount
//         assertEq(actualTokenAReceived, desiredOut,
//             "Should receive exactly the desired TokenA amount");
//     }

//     function test_calculateZapOutLPPrecise_Uniswap_extremeUnbalancedPool() public {
//         (uint112 reserveA, uint112 reserveB, ) = uniswapBalancedPair.getReserves();
//         uint256 lpTotalSupply = uniswapBalancedPair.totalSupply();

//         // Set desired TokenA amount (reasonable portion of reserves)
//         uint256 desiredOut = reserveA / 20; // 5% of TokenA reserves

//         // Calculate expected LP needed using the PRECISE version
//         uint256 expectedLpNeeded = ConstProdUtils._calculateZapOutLPPrecise(
//             desiredOut, reserveA, reserveB, lpTotalSupply, 300, 100000
//         );

//         // Execute actual ZapOut
//         uint256 initialTokenABalance = uniswapBalancedTokenA.balanceOf(address(this));

//         // Withdraw the calculated LP amount
//         uniswapBalancedPair.transfer(address(uniswapBalancedPair), expectedLpNeeded);
//         (uint256 amountA, uint256 amountB) = uniswapBalancedPair.burn(address(this));

//         // Swap amountB for TokenA
//         if (amountB > 0) {
//             uniswapBalancedTokenB.approve(address(uniswapV2Router()), amountB);
//             address[] memory path = new address[](2);
//             path[0] = address(uniswapBalancedTokenB);
//             path[1] = address(uniswapBalancedTokenA);

//             uniswapV2Router().swapExactTokensForTokensSupportingFeeOnTransferTokens(
//                 amountB, 1, path, address(this), block.timestamp
//             );
//         }

//         // Calculate actual TokenA received
//         uint256 finalTokenABalance = uniswapBalancedTokenA.balanceOf(address(this));
//         uint256 actualTokenAReceived = finalTokenABalance - initialTokenABalance;

//         // Verify we received exactly the desired amount
//         assertEq(actualTokenAReceived, desiredOut,
//             "Should receive exactly the desired TokenA amount");
//     }

//     // Edge Case Tests (6 tests)

//     function test_calculateZapOutLPPrecise_edgeCase_smallDesiredOut() public {
//         (uint112 reserveA, uint112 reserveB, , ) = camelotBalancedPair.getReserves();
//         (,,uint32 feeA,) = camelotBalancedPair.getReserves();
//         uint256 feePercent = uint256(feeA);
//         uint256 lpTotalSupply = camelotBalancedPair.totalSupply();

//         // Set small desired TokenA amount
//         uint256 desiredOut = reserveA / 100; // 1% of TokenA reserves

//         // Calculate expected LP needed using the PRECISE version
//         uint256 expectedLpNeeded = ConstProdUtils._calculateZapOutLPPrecise(
//             desiredOut, reserveA, reserveB, lpTotalSupply, feePercent, 100000
//         );

//         // Execute actual ZapOut
//         uint256 initialTokenABalance = camelotBalancedTokenA.balanceOf(address(this));

//         // Withdraw the calculated LP amount
//         camelotBalancedPair.transfer(address(camelotBalancedPair), expectedLpNeeded);
//         (uint256 amountA, uint256 amountB) = camelotBalancedPair.burn(address(this));

//         // Swap amountB for TokenA
//         if (amountB > 0) {
//             camelotBalancedTokenB.approve(address(camV2Router()), amountB);
//             address[] memory path = new address[](2);
//             path[0] = address(camelotBalancedTokenB);
//             path[1] = address(camelotBalancedTokenA);

//             camV2Router().swapExactTokensForTokensSupportingFeeOnTransferTokens(
//                 amountB, 1, path, address(this), address(0), block.timestamp
//             );
//         }

//         // Calculate actual TokenA received
//         uint256 finalTokenABalance = camelotBalancedTokenA.balanceOf(address(this));
//         uint256 actualTokenAReceived = finalTokenABalance - initialTokenABalance;

//         // Verify we received exactly the desired amount
//         assertEq(actualTokenAReceived, desiredOut,
//             "Should receive exactly the desired TokenA amount");
//     }

//     function test_calculateZapOutLPPrecise_edgeCase_largeDesiredOut() public {
//         (uint112 reserveA, uint112 reserveB, , ) = camelotBalancedPair.getReserves();
//         (,,uint32 feeA,) = camelotBalancedPair.getReserves();
//         uint256 feePercent = uint256(feeA);
//         uint256 lpTotalSupply = camelotBalancedPair.totalSupply();

//         // Set large desired TokenA amount
//         uint256 desiredOut = reserveA / 4; // 25% of TokenA reserves

//         // Calculate expected LP needed using the PRECISE version
//         uint256 expectedLpNeeded = ConstProdUtils._calculateZapOutLPPrecise(
//             desiredOut, reserveA, reserveB, lpTotalSupply, feePercent, 100000
//         );

//         // Execute actual ZapOut
//         uint256 initialTokenABalance = camelotBalancedTokenA.balanceOf(address(this));

//         // Withdraw the calculated LP amount
//         camelotBalancedPair.transfer(address(camelotBalancedPair), expectedLpNeeded);
//         (uint256 amountA, uint256 amountB) = camelotBalancedPair.burn(address(this));

//         // Swap amountB for TokenA
//         if (amountB > 0) {
//             camelotBalancedTokenB.approve(address(camV2Router()), amountB);
//             address[] memory path = new address[](2);
//             path[0] = address(camelotBalancedTokenB);
//             path[1] = address(camelotBalancedTokenA);

//             camV2Router().swapExactTokensForTokensSupportingFeeOnTransferTokens(
//                 amountB, 1, path, address(this), address(0), block.timestamp
//             );
//         }

//         // Calculate actual TokenA received
//         uint256 finalTokenABalance = camelotBalancedTokenA.balanceOf(address(this));
//         uint256 actualTokenAReceived = finalTokenABalance - initialTokenABalance;

//         // Verify we received exactly the desired amount
//         assertEq(actualTokenAReceived, desiredOut,
//             "Should receive exactly the desired TokenA amount");
//     }

//     function test_calculateZapOutLPPrecise_edgeCase_differentFees() public {
//         (uint112 reserveA, uint112 reserveB, , ) = camelotBalancedPair.getReserves();
//         (,,uint32 feeA,) = camelotBalancedPair.getReserves();
//         uint256 feePercent = uint256(feeA);
//         uint256 lpTotalSupply = camelotBalancedPair.totalSupply();

//         // Set desired TokenA amount
//         uint256 desiredOut = reserveA / 10; // 10% of TokenA reserves

//         // Calculate expected LP needed using the PRECISE version
//         uint256 expectedLpNeeded = ConstProdUtils._calculateZapOutLPPrecise(
//             desiredOut, reserveA, reserveB, lpTotalSupply, feePercent, 100000
//         );

//         // Execute actual ZapOut
//         uint256 initialTokenABalance = camelotBalancedTokenA.balanceOf(address(this));

//         // Withdraw the calculated LP amount
//         camelotBalancedPair.transfer(address(camelotBalancedPair), expectedLpNeeded);
//         (uint256 amountA, uint256 amountB) = camelotBalancedPair.burn(address(this));

//         // Swap amountB for TokenA
//         if (amountB > 0) {
//             camelotBalancedTokenB.approve(address(camV2Router()), amountB);
//             address[] memory path = new address[](2);
//             path[0] = address(camelotBalancedTokenB);
//             path[1] = address(camelotBalancedTokenA);

//             camV2Router().swapExactTokensForTokensSupportingFeeOnTransferTokens(
//                 amountB, 1, path, address(this), address(0), block.timestamp
//             );
//         }

//         // Calculate actual TokenA received
//         uint256 finalTokenABalance = camelotBalancedTokenA.balanceOf(address(this));
//         uint256 actualTokenAReceived = finalTokenABalance - initialTokenABalance;

//         // Verify we received exactly the desired amount
//         assertEq(actualTokenAReceived, desiredOut,
//             "Should receive exactly the desired TokenA amount");
//     }

//     function test_calculateZapOutLPPrecise_edgeCase_verySmallReserves() public {
//         (uint112 reserveA, uint112 reserveB, , ) = camelotBalancedPair.getReserves();
//         (,,uint32 feeA,) = camelotBalancedPair.getReserves();
//         uint256 feePercent = uint256(feeA);
//         uint256 lpTotalSupply = camelotBalancedPair.totalSupply();

//         // Set small desired TokenA amount for extreme unbalanced pool
//         uint256 desiredOut = reserveA / 50; // 2% of TokenA reserves

//         // Calculate expected LP needed using the PRECISE version
//         uint256 expectedLpNeeded = ConstProdUtils._calculateZapOutLPPrecise(
//             desiredOut, reserveA, reserveB, lpTotalSupply, feePercent, 100000
//         );

//         // Execute actual ZapOut
//         uint256 initialTokenABalance = camelotBalancedTokenA.balanceOf(address(this));

//         // Withdraw the calculated LP amount
//         camelotBalancedPair.transfer(address(camelotBalancedPair), expectedLpNeeded);
//         (uint256 amountA, uint256 amountB) = camelotBalancedPair.burn(address(this));

//         // Swap amountB for TokenA
//         if (amountB > 0) {
//             camelotBalancedTokenB.approve(address(camV2Router()), amountB);
//             address[] memory path = new address[](2);
//             path[0] = address(camelotBalancedTokenB);
//             path[1] = address(camelotBalancedTokenA);

//             camV2Router().swapExactTokensForTokensSupportingFeeOnTransferTokens(
//                 amountB, 1, path, address(this), address(0), block.timestamp
//             );
//         }

//         // Calculate actual TokenA received
//         uint256 finalTokenABalance = camelotBalancedTokenA.balanceOf(address(this));
//         uint256 actualTokenAReceived = finalTokenABalance - initialTokenABalance;

//         // Verify we received exactly the desired amount
//         assertEq(actualTokenAReceived, desiredOut,
//             "Should receive exactly the desired TokenA amount");
//     }

//     function test_calculateZapOutLPPrecise_edgeCase_midRangeDesiredOut() public {
//         (uint112 reserveA, uint112 reserveB, , ) = camelotBalancedPair.getReserves();
//         (,,uint32 feeA,) = camelotBalancedPair.getReserves();
//         uint256 feePercent = uint256(feeA);
//         uint256 lpTotalSupply = camelotBalancedPair.totalSupply();

//         // Set mid-range desired TokenA amount
//         uint256 desiredOut = reserveA / 6; // ~16.7% of TokenA reserves

//         // Calculate expected LP needed using the PRECISE version
//         uint256 expectedLpNeeded = ConstProdUtils._calculateZapOutLPPrecise(
//             desiredOut, reserveA, reserveB, lpTotalSupply, feePercent, 100000
//         );

//         // Execute actual ZapOut
//         uint256 initialTokenABalance = camelotBalancedTokenA.balanceOf(address(this));

//         // Withdraw the calculated LP amount
//         camelotBalancedPair.transfer(address(camelotBalancedPair), expectedLpNeeded);
//         (uint256 amountA, uint256 amountB) = camelotBalancedPair.burn(address(this));

//         // Swap amountB for TokenA
//         if (amountB > 0) {
//             camelotBalancedTokenB.approve(address(camV2Router()), amountB);
//             address[] memory path = new address[](2);
//             path[0] = address(camelotBalancedTokenB);
//             path[1] = address(camelotBalancedTokenA);

//             camV2Router().swapExactTokensForTokensSupportingFeeOnTransferTokens(
//                 amountB, 1, path, address(this), address(0), block.timestamp
//             );
//         }

//         // Calculate actual TokenA received
//         uint256 finalTokenABalance = camelotBalancedTokenA.balanceOf(address(this));
//         uint256 actualTokenAReceived = finalTokenABalance - initialTokenABalance;

//         // Verify we received exactly the desired amount
//         assertEq(actualTokenAReceived, desiredOut,
//             "Should receive exactly the desired TokenA amount");
//     }

//     function test_calculateZapOutLPPrecise_edgeCase_maxDesiredOut() public {
//         (uint112 reserveA, uint112 reserveB, ) = uniswapBalancedPair.getReserves();
//         uint256 lpTotalSupply = uniswapBalancedPair.totalSupply();

//         // Set maximum reasonable desired TokenA amount
//         uint256 desiredOut = reserveA / 3; // ~33.3% of TokenA reserves

//         // Calculate expected LP needed using the PRECISE version
//         uint256 expectedLpNeeded = ConstProdUtils._calculateZapOutLPPrecise(
//             desiredOut, reserveA, reserveB, lpTotalSupply, 300, 100000
//         );

//         // Execute actual ZapOut
//         uint256 initialTokenABalance = uniswapBalancedTokenA.balanceOf(address(this));

//         // Withdraw the calculated LP amount
//         uniswapBalancedPair.transfer(address(uniswapBalancedPair), expectedLpNeeded);
//         (uint256 amountA, uint256 amountB) = uniswapBalancedPair.burn(address(this));

//         // Swap amountB for TokenA
//         if (amountB > 0) {
//             uniswapBalancedTokenB.approve(address(uniswapV2Router()), amountB);
//             address[] memory path = new address[](2);
//             path[0] = address(uniswapBalancedTokenB);
//             path[1] = address(uniswapBalancedTokenA);

//             uniswapV2Router().swapExactTokensForTokensSupportingFeeOnTransferTokens(
//                 amountB, 1, path, address(this), block.timestamp
//             );
//         }

//         // Calculate actual TokenA received
//         uint256 finalTokenABalance = uniswapBalancedTokenA.balanceOf(address(this));
//         uint256 actualTokenAReceived = finalTokenABalance - initialTokenABalance;

//         // Verify we received exactly the desired amount
//         assertEq(actualTokenAReceived, desiredOut,
//             "Should receive exactly the desired TokenA amount");
//     }
// }
