// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import {Test} from "forge-std/Test.sol";
import {TestBase_ConstProdUtils} from "./TestBase_ConstProdUtils.sol";
import {ConstProdUtils} from "contracts/crane/utils/math/ConstProdUtils.sol";
// import {FEE_DENOMINATOR} from "@crane/src/constants/Constants.sol";

// contract Test_ConstProdUtils_withdrawSwapQuote is TestBase_ConstProdUtils {

//     function setUp() public override {
//         super.setUp();
//     }

//     // Basic Functionality Tests (6 tests)

//     function test_withdrawSwapQuote_Camelot_balancedPool() public {
//         (uint112 reserve0, uint112 reserve1, uint16 token0Fee , uint16 token1Fee) = camelotBalancedPair.getReserves();
//         // (,,uint32 feeA,) = camelotBalancedPair.getReserves();

//         // Sort reserves and fees to match token order using 6-parameter _sortReserves
//         (uint256 reserveA, uint256 feeA, uint256 reserveB, uint256 feeB) = ConstProdUtils._sortReserves(
//             address(camelotBalancedTokenA),
//             camelotBalancedPair.token0(),
//             reserve0,
//             uint256(token0Fee),
//             reserve1,
//             uint256(token1Fee)
//         );
//         uint256 feePercent = uint256(feeA);
//         uint256 lpTotalSupply = camelotBalancedPair.totalSupply();

//         uint256 lpBalance = camelotBalancedPair.balanceOf(address(this));
//         uint256 ownedLPAmount = lpBalance / 2;

//         uint256 expectedTotalTokenA = ConstProdUtils._withdrawSwapQuote(
//             ownedLPAmount, lpTotalSupply, reserveA, reserveB, feePercent
//         );

//         // Execute actual withdraw + swap
//         uint256 initialTokenABalance = camelotBalancedTokenA.balanceOf(address(this));
//         uint256 initialTokenBBalance = camelotBalancedTokenB.balanceOf(address(this));

//         // Withdraw LP tokens
//         camelotBalancedPair.transfer(address(camelotBalancedPair), ownedLPAmount);
//         (uint256 amountA, uint256 amountB) = camelotBalancedPair.burn(address(this));

//         uint256 actualAmountA = amountA;
//         uint256 actualAmountB = amountB;

//         // Swap amountB for TokenA
//         if (actualAmountB > 0) {
//             camelotBalancedTokenB.approve(address(camV2Router()), actualAmountB);
//             address[] memory path = new address[](2);
//             path[0] = address(camelotBalancedTokenB);
//             path[1] = address(camelotBalancedTokenA);

//             camV2Router().swapExactTokensForTokensSupportingFeeOnTransferTokens(
//                 actualAmountB, 1, path, address(this), address(0), block.timestamp
//             );
//         }

//         uint256 finalTokenABalance = camelotBalancedTokenA.balanceOf(address(this));
//         uint256 actualTotalTokenA = finalTokenABalance - initialTokenABalance;

//         assertEq(actualTotalTokenA, expectedTotalTokenA,
//             "Should receive exactly the expected total TokenA amount");
//     }

//     function test_withdrawSwapQuote_Camelot_unbalancedPool() public {
//         (uint112 reserve0, uint112 reserve1, uint16 token0Fee, uint16 token1Fee) = camelotUnbalancedPair.getReserves();
//         uint256 lpTotalSupply = camelotUnbalancedPair.totalSupply();

//         // Sort reserves and fees to match token order using 6-parameter _sortReserves
//         (uint256 reserveA, uint256 tokenAFee, uint256 reserveB, uint256 tokenBFee) = ConstProdUtils._sortReserves(
//             address(camelotUnbalancedTokenA),
//             camelotUnbalancedPair.token0(),
//             reserve0,
//             uint256(token0Fee),
//             reserve1,
//             uint256(token1Fee)
//         );

//         uint256 feePercent = tokenAFee;
//         uint256 lpBalance = camelotUnbalancedPair.balanceOf(address(this));
//         uint256 ownedLPAmount = lpBalance / 2;

//         uint256 expectedTotalTokenA = ConstProdUtils._withdrawSwapQuote(
//             ownedLPAmount, lpTotalSupply, reserveA, reserveB, feePercent
//         );

//         // Execute actual withdraw + swap
//         uint256 initialTokenABalance = camelotUnbalancedTokenA.balanceOf(address(this));

//         // Withdraw LP tokens
//         camelotUnbalancedPair.transfer(address(camelotUnbalancedPair), ownedLPAmount);
//         (uint256 amount0, uint256 amount1) = camelotUnbalancedPair.burn(address(this));

//         // Map burn return values to token A and B based on token0 order
//         uint256 actualAmountA;
//         uint256 actualAmountB;
//         if (camelotUnbalancedPair.token0() == address(camelotUnbalancedTokenA)) {
//             actualAmountA = amount0;
//             actualAmountB = amount1;
//         } else {
//             actualAmountA = amount1;
//             actualAmountB = amount0;
//         }

//         // Swap amountB for TokenA
//         if (actualAmountB > 0) {
//             camelotUnbalancedTokenB.approve(address(camV2Router()), actualAmountB);
//             address[] memory path = new address[](2);
//             path[0] = address(camelotUnbalancedTokenB);
//             path[1] = address(camelotUnbalancedTokenA);

//             camV2Router().swapExactTokensForTokensSupportingFeeOnTransferTokens(
//                 actualAmountB, 1, path, address(this), address(0), block.timestamp
//             );
//         }

//         uint256 finalTokenABalance = camelotUnbalancedTokenA.balanceOf(address(this));
//         uint256 actualTotalTokenA = finalTokenABalance - initialTokenABalance;

//         assertEq(actualTotalTokenA, expectedTotalTokenA,
//             "Should receive exactly the expected total TokenA amount");
//     }

//     function test_withdrawSwapQuote_Camelot_extremeUnbalancedPool() public {
//         (uint112 reserveA, uint112 reserveB, , ) = camelotBalancedPair.getReserves();
//         (,,uint32 feeA,) = camelotBalancedPair.getReserves();
//         uint256 feePercent = uint256(feeA);
//         uint256 lpTotalSupply = camelotBalancedPair.totalSupply();

//         uint256 lpBalance = camelotBalancedPair.balanceOf(address(this));
//         uint256 ownedLPAmount = lpBalance / 2;

//         uint256 expectedTotalTokenA = ConstProdUtils._withdrawSwapQuote(
//             ownedLPAmount, lpTotalSupply, reserveA, reserveB, feePercent
//         );

//         // Execute actual withdraw + swap
//         uint256 initialTokenABalance = camelotBalancedTokenA.balanceOf(address(this));

//         // Withdraw LP tokens
//         camelotBalancedPair.transfer(address(camelotBalancedPair), ownedLPAmount);
//         (uint256 amountA, uint256 amountB) = camelotBalancedPair.burn(address(this));

//         uint256 actualAmountA = amountA;
//         uint256 actualAmountB = amountB;

//         // Swap amountB for TokenA
//         if (actualAmountB > 0) {
//             camelotBalancedTokenB.approve(address(camV2Router()), actualAmountB);
//             address[] memory path = new address[](2);
//             path[0] = address(camelotBalancedTokenB);
//             path[1] = address(camelotBalancedTokenA);

//             camV2Router().swapExactTokensForTokensSupportingFeeOnTransferTokens(
//                 actualAmountB, 1, path, address(this), address(0), block.timestamp
//             );
//         }

//         uint256 finalTokenABalance = camelotBalancedTokenA.balanceOf(address(this));
//         uint256 actualTotalTokenA = finalTokenABalance - initialTokenABalance;

//         assertEq(actualTotalTokenA, expectedTotalTokenA,
//             "Should receive exactly the expected total TokenA amount");
//     }

//     function test_withdrawSwapQuote_Uniswap_balancedPool() public {
//         (uint112 reserve0, uint112 reserve1, ) = uniswapBalancedPair.getReserves();
//         (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
//             address(uniswapBalancedTokenA), uniswapBalancedPair.token0(), reserve0, reserve1
//         );
//         uint256 lpTotalSupply = uniswapBalancedPair.totalSupply();

//         uint256 lpBalance = uniswapBalancedPair.balanceOf(address(this));
//         uint256 ownedLPAmount = lpBalance / 2;

//         uint256 expectedTotalTokenA = ConstProdUtils._withdrawSwapQuote(
//             ownedLPAmount, lpTotalSupply, reserveA, reserveB, 300
//         );

//         // Execute actual withdraw + swap
//         uint256 initialTokenABalance = uniswapBalancedTokenA.balanceOf(address(this));

//         // Withdraw LP tokens
//         uniswapBalancedPair.transfer(address(uniswapBalancedPair), ownedLPAmount);
//         (uint256 amountA, uint256 amountB) = uniswapBalancedPair.burn(address(this));

//         uint256 actualAmountA = amountA;
//         uint256 actualAmountB = amountB;

//         // Swap amountB for TokenA
//         if (actualAmountB > 0) {
//             uniswapBalancedTokenB.approve(address(uniswapV2Router()), actualAmountB);
//             address[] memory path = new address[](2);
//             path[0] = address(uniswapBalancedTokenB);
//             path[1] = address(uniswapBalancedTokenA);

//             uniswapV2Router().swapExactTokensForTokensSupportingFeeOnTransferTokens(
//                 actualAmountB, 1, path, address(this), block.timestamp
//             );
//         }

//         uint256 finalTokenABalance = uniswapBalancedTokenA.balanceOf(address(this));
//         uint256 actualTotalTokenA = finalTokenABalance - initialTokenABalance;

//         assertEq(actualTotalTokenA, expectedTotalTokenA,
//             "Should receive exactly the expected total TokenA amount");
//     }

//     function test_withdrawSwapQuote_Uniswap_unbalancedPool() public {
//         (uint112 reserve0, uint112 reserve1, ) = uniswapUnbalancedPair.getReserves();
//         (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
//             address(uniswapUnbalancedTokenA), uniswapUnbalancedPair.token0(), reserve0, reserve1
//         );
//         uint256 lpTotalSupply = uniswapUnbalancedPair.totalSupply();

//         uint256 lpBalance = uniswapBalancedPair.balanceOf(address(this));
//         uint256 ownedLPAmount = lpBalance / 2;

//         uint256 expectedTotalTokenA = ConstProdUtils._withdrawSwapQuote(
//             ownedLPAmount, lpTotalSupply, reserveA, reserveB, 300
//         );

//         // Execute actual withdraw + swap
//         uint256 initialTokenABalance = uniswapBalancedTokenA.balanceOf(address(this));

//         // Withdraw LP tokens
//         uniswapBalancedPair.transfer(address(uniswapBalancedPair), ownedLPAmount);
//         (uint256 amountA, uint256 amountB) = uniswapBalancedPair.burn(address(this));

//         uint256 actualAmountA = amountA;
//         uint256 actualAmountB = amountB;

//         // Swap amountB for TokenA
//         if (actualAmountB > 0) {
//             uniswapBalancedTokenB.approve(address(uniswapV2Router()), actualAmountB);
//             address[] memory path = new address[](2);
//             path[0] = address(uniswapBalancedTokenB);
//             path[1] = address(uniswapBalancedTokenA);

//             uniswapV2Router().swapExactTokensForTokensSupportingFeeOnTransferTokens(
//                 actualAmountB, 1, path, address(this), block.timestamp
//             );
//         }

//         uint256 finalTokenABalance = uniswapBalancedTokenA.balanceOf(address(this));
//         uint256 actualTotalTokenA = finalTokenABalance - initialTokenABalance;

//         assertEq(actualTotalTokenA, expectedTotalTokenA,
//             "Should receive exactly the expected total TokenA amount");
//     }

//     function test_withdrawSwapQuote_Uniswap_extremeUnbalancedPool() public {
//         (uint112 reserveA, uint112 reserveB, ) = uniswapBalancedPair.getReserves();
//         uint256 lpTotalSupply = uniswapBalancedPair.totalSupply();

//         uint256 lpBalance = uniswapBalancedPair.balanceOf(address(this));
//         uint256 ownedLPAmount = lpBalance / 2;

//         uint256 expectedTotalTokenA = ConstProdUtils._withdrawSwapQuote(
//             ownedLPAmount, lpTotalSupply, reserveA, reserveB, 300
//         );

//         // Execute actual withdraw + swap
//         uint256 initialTokenABalance = uniswapBalancedTokenA.balanceOf(address(this));

//         // Withdraw LP tokens
//         uniswapBalancedPair.transfer(address(uniswapBalancedPair), ownedLPAmount);
//         (uint256 amountA, uint256 amountB) = uniswapBalancedPair.burn(address(this));

//         uint256 actualAmountA = amountA;
//         uint256 actualAmountB = amountB;

//         // Swap amountB for TokenA
//         if (actualAmountB > 0) {
//             uniswapBalancedTokenB.approve(address(uniswapV2Router()), actualAmountB);
//             address[] memory path = new address[](2);
//             path[0] = address(uniswapBalancedTokenB);
//             path[1] = address(uniswapBalancedTokenA);

//             uniswapV2Router().swapExactTokensForTokensSupportingFeeOnTransferTokens(
//                 actualAmountB, 1, path, address(this), block.timestamp
//             );
//         }

//         uint256 finalTokenABalance = uniswapBalancedTokenA.balanceOf(address(this));
//         uint256 actualTotalTokenA = finalTokenABalance - initialTokenABalance;

//         assertEq(actualTotalTokenA, expectedTotalTokenA,
//             "Should receive exactly the expected total TokenA amount");
//     }

//     // Edge Case Tests (6 tests)

//     function test_withdrawSwapQuote_edgeCase_smallLPAmount() public {
//         (uint112 reserveA, uint112 reserveB, , ) = camelotBalancedPair.getReserves();
//         (,,uint32 feeA,) = camelotBalancedPair.getReserves();
//         uint256 feePercent = uint256(feeA);
//         uint256 lpTotalSupply = camelotBalancedPair.totalSupply();

//         uint256 lpBalance = camelotBalancedPair.balanceOf(address(this));
//         uint256 ownedLPAmount = lpBalance / 4; // Smaller amount

//         uint256 expectedTotalTokenA = ConstProdUtils._withdrawSwapQuote(
//             ownedLPAmount, lpTotalSupply, reserveA, reserveB, feePercent
//         );

//         // Execute actual withdraw + swap
//         uint256 initialTokenABalance = camelotBalancedTokenA.balanceOf(address(this));

//         // Withdraw LP tokens
//         camelotBalancedPair.transfer(address(camelotBalancedPair), ownedLPAmount);
//         (uint256 amountA, uint256 amountB) = camelotBalancedPair.burn(address(this));

//         uint256 actualAmountA = amountA;
//         uint256 actualAmountB = amountB;

//         // Swap amountB for TokenA
//         if (actualAmountB > 0) {
//             camelotBalancedTokenB.approve(address(camV2Router()), actualAmountB);
//             address[] memory path = new address[](2);
//             path[0] = address(camelotBalancedTokenB);
//             path[1] = address(camelotBalancedTokenA);

//             camV2Router().swapExactTokensForTokensSupportingFeeOnTransferTokens(
//                 actualAmountB, 1, path, address(this), address(0), block.timestamp
//             );
//         }

//         uint256 finalTokenABalance = camelotBalancedTokenA.balanceOf(address(this));
//         uint256 actualTotalTokenA = finalTokenABalance - initialTokenABalance;

//         assertEq(actualTotalTokenA, expectedTotalTokenA,
//             "Should receive exactly the expected total TokenA amount");
//     }

//     function test_withdrawSwapQuote_edgeCase_largeLPAmount() public {
//         (uint112 reserveA, uint112 reserveB, , ) = camelotBalancedPair.getReserves();
//         (,,uint32 feeA,) = camelotBalancedPair.getReserves();
//         uint256 feePercent = uint256(feeA);
//         uint256 lpTotalSupply = camelotBalancedPair.totalSupply();

//         uint256 lpBalance = camelotBalancedPair.balanceOf(address(this));
//         uint256 ownedLPAmount = (lpBalance * 3) / 4; // Larger amount

//         uint256 expectedTotalTokenA = ConstProdUtils._withdrawSwapQuote(
//             ownedLPAmount, lpTotalSupply, reserveA, reserveB, feePercent
//         );

//         // Execute actual withdraw + swap
//         uint256 initialTokenABalance = camelotBalancedTokenA.balanceOf(address(this));

//         // Withdraw LP tokens
//         camelotBalancedPair.transfer(address(camelotBalancedPair), ownedLPAmount);
//         (uint256 amountA, uint256 amountB) = camelotBalancedPair.burn(address(this));

//         uint256 actualAmountA = amountA;
//         uint256 actualAmountB = amountB;

//         // Swap amountB for TokenA
//         if (actualAmountB > 0) {
//             camelotBalancedTokenB.approve(address(camV2Router()), actualAmountB);
//             address[] memory path = new address[](2);
//             path[0] = address(camelotBalancedTokenB);
//             path[1] = address(camelotBalancedTokenA);

//             camV2Router().swapExactTokensForTokensSupportingFeeOnTransferTokens(
//                 actualAmountB, 1, path, address(this), address(0), block.timestamp
//             );
//         }

//         uint256 finalTokenABalance = camelotBalancedTokenA.balanceOf(address(this));
//         uint256 actualTotalTokenA = finalTokenABalance - initialTokenABalance;

//         assertEq(actualTotalTokenA, expectedTotalTokenA,
//             "Should receive exactly the expected total TokenA amount");
//     }

//     function test_withdrawSwapQuote_edgeCase_differentFees() public {
//         (uint112 reserveA, uint112 reserveB, , ) = camelotBalancedPair.getReserves();
//         (,,uint32 feeA,) = camelotBalancedPair.getReserves();
//         uint256 feePercent = uint256(feeA);
//         uint256 lpTotalSupply = camelotBalancedPair.totalSupply();

//         uint256 lpBalance = camelotBalancedPair.balanceOf(address(this));
//         uint256 ownedLPAmount = lpBalance / 2;

//         uint256 expectedTotalTokenA = ConstProdUtils._withdrawSwapQuote(
//             ownedLPAmount, lpTotalSupply, reserveA, reserveB, feePercent
//         );

//         // Execute actual withdraw + swap
//         uint256 initialTokenABalance = camelotBalancedTokenA.balanceOf(address(this));

//         // Withdraw LP tokens
//         camelotBalancedPair.transfer(address(camelotBalancedPair), ownedLPAmount);
//         (uint256 amountA, uint256 amountB) = camelotBalancedPair.burn(address(this));

//         uint256 actualAmountA = amountA;
//         uint256 actualAmountB = amountB;

//         // Swap amountB for TokenA
//         if (actualAmountB > 0) {
//             camelotBalancedTokenB.approve(address(camV2Router()), actualAmountB);
//             address[] memory path = new address[](2);
//             path[0] = address(camelotBalancedTokenB);
//             path[1] = address(camelotBalancedTokenA);

//             camV2Router().swapExactTokensForTokensSupportingFeeOnTransferTokens(
//                 actualAmountB, 1, path, address(this), address(0), block.timestamp
//             );
//         }

//         uint256 finalTokenABalance = camelotBalancedTokenA.balanceOf(address(this));
//         uint256 actualTotalTokenA = finalTokenABalance - initialTokenABalance;

//         assertEq(actualTotalTokenA, expectedTotalTokenA,
//             "Should receive exactly the expected total TokenA amount");
//     }

//     function test_withdrawSwapQuote_edgeCase_verySmallReserves() public {
//         (uint112 reserveA, uint112 reserveB, , ) = camelotBalancedPair.getReserves();
//         (,,uint32 feeA,) = camelotBalancedPair.getReserves();
//         uint256 feePercent = uint256(feeA);
//         uint256 lpTotalSupply = camelotBalancedPair.totalSupply();

//         uint256 lpBalance = camelotBalancedPair.balanceOf(address(this));
//         uint256 ownedLPAmount = lpBalance / 2;

//         uint256 expectedTotalTokenA = ConstProdUtils._withdrawSwapQuote(
//             ownedLPAmount, lpTotalSupply, reserveA, reserveB, feePercent
//         );

//         // Execute actual withdraw + swap
//         uint256 initialTokenABalance = camelotBalancedTokenA.balanceOf(address(this));

//         // Withdraw LP tokens
//         camelotBalancedPair.transfer(address(camelotBalancedPair), ownedLPAmount);
//         (uint256 amountA, uint256 amountB) = camelotBalancedPair.burn(address(this));

//         uint256 actualAmountA = amountA;
//         uint256 actualAmountB = amountB;

//         // Swap amountB for TokenA
//         if (actualAmountB > 0) {
//             camelotBalancedTokenB.approve(address(camV2Router()), actualAmountB);
//             address[] memory path = new address[](2);
//             path[0] = address(camelotBalancedTokenB);
//             path[1] = address(camelotBalancedTokenA);

//             camV2Router().swapExactTokensForTokensSupportingFeeOnTransferTokens(
//                 actualAmountB, 1, path, address(this), address(0), block.timestamp
//             );
//         }

//         uint256 finalTokenABalance = camelotBalancedTokenA.balanceOf(address(this));
//         uint256 actualTotalTokenA = finalTokenABalance - initialTokenABalance;

//         assertEq(actualTotalTokenA, expectedTotalTokenA,
//             "Should receive exactly the expected total TokenA amount");
//     }

//     function test_withdrawSwapQuote_edgeCase_midRangeLPAmount() public {
//         (uint112 reserveA, uint112 reserveB, , ) = camelotBalancedPair.getReserves();
//         (,,uint32 feeA,) = camelotBalancedPair.getReserves();
//         uint256 feePercent = uint256(feeA);
//         uint256 lpTotalSupply = camelotBalancedPair.totalSupply();

//         uint256 lpBalance = camelotBalancedPair.balanceOf(address(this));
//             /// forge-lint: disable-next-line(erc20-unchecked-transfer)
//         uint256 ownedLPAmount = (lpBalance * 2) / 3; // Mid-range amount

//         uint256 expectedTotalTokenA = ConstProdUtils._withdrawSwapQuote(
//             ownedLPAmount, lpTotalSupply, reserveA, reserveB, feePercent
//         );

//         // Execute actual withdraw + swap
//         uint256 initialTokenABalance = camelotBalancedTokenA.balanceOf(address(this));

//         // Withdraw LP tokens
//         camelotBalancedPair.transfer(address(camelotBalancedPair), ownedLPAmount);
//         (uint256 amountA, uint256 amountB) = camelotBalancedPair.burn(address(this));

//         uint256 actualAmountA = amountA;
//         uint256 actualAmountB = amountB;

//         // Swap amountB for TokenA
//         if (actualAmountB > 0) {
//             camelotBalancedTokenB.approve(address(camV2Router()), actualAmountB);
//             address[] memory path = new address[](2);
//             path[0] = address(camelotBalancedTokenB);
//             path[1] = address(camelotBalancedTokenA);

//             camV2Router().swapExactTokensForTokensSupportingFeeOnTransferTokens(
//                 actualAmountB, 1, path, address(this), address(0), block.timestamp
//             );
//         }

//         uint256 finalTokenABalance = camelotBalancedTokenA.balanceOf(address(this));
//         uint256 actualTotalTokenA = finalTokenABalance - initialTokenABalance;

//         assertEq(actualTotalTokenA, expectedTotalTokenA,
//             "Should receive exactly the expected total TokenA amount");
//     }

//     function test_withdrawSwapQuote_edgeCase_maxLPAmount() public {
//         (uint112 reserveA, uint112 reserveB, ) = uniswapBalancedPair.getReserves();
//         uint256 lpTotalSupply = uniswapBalancedPair.totalSupply();

//         uint256 lpBalance = uniswapBalancedPair.balanceOf(address(this));
//             /// forge-lint: disable-next-line(mixed-case-variable)
//         uint256 ownedLPAmount = (lpBalance * 3) / 4; // Large amount

//         uint256 expectedTotalTokenA = ConstProdUtils._withdrawSwapQuote(
//             ownedLPAmount, lpTotalSupply, reserveA, reserveB, 300
//         );

//         // Execute actual withdraw + swap
//         uint256 initialTokenABalance = uniswapBalancedTokenA.balanceOf(address(this));

//         // Withdraw LP tokens
//             /// forge-lint: disable-next-line(erc20-unchecked-transfer)
//         uniswapBalancedPair.transfer(address(uniswapBalancedPair), ownedLPAmount);
//         (uint256 amountA, uint256 amountB) = uniswapBalancedPair.burn(address(this));

//         uint256 actualAmountA = amountA;
//         uint256 actualAmountB = amountB;

//         // Swap amountB for TokenA
//         if (actualAmountB > 0) {
//             uniswapBalancedTokenB.approve(address(uniswapV2Router()), actualAmountB);
//             address[] memory path = new address[](2);
//             path[0] = address(uniswapBalancedTokenB);
//             path[1] = address(uniswapBalancedTokenA);

//             uniswapV2Router().swapExactTokensForTokensSupportingFeeOnTransferTokens(
//                 actualAmountB, 1, path, address(this), block.timestamp
//             );
//         }

//         uint256 finalTokenABalance = uniswapBalancedTokenA.balanceOf(address(this));
//         uint256 actualTotalTokenA = finalTokenABalance - initialTokenABalance;

//         assertEq(actualTotalTokenA, expectedTotalTokenA,
//             "Should receive exactly the expected total TokenA amount");
//     }
// }
