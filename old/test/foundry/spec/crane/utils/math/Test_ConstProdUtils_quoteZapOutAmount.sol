// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {TestBase_ConstProdUtils} from "./TestBase_ConstProdUtils.sol";
import {ConstProdUtils} from "contracts/crane/utils/math/ConstProdUtils.sol";

contract Test_ConstProdUtils_quoteZapOutAmount is TestBase_ConstProdUtils {

    function setUp() public override {
        super.setUp();
    }

    // Basic Functionality Tests (6 tests)

    function test_quoteZapOutAmount_Camelot_balancedPool() public {
        (uint112 reserve0, uint112 reserve1, uint16 token0Fee, uint16 token1Fee) = camelotBalancedPair.getReserves();
        (uint256 reserveA, uint256 feePercent, uint256 reserveB, uint256 tokenBFee) = ConstProdUtils._sortReserves(
            address(camelotBalancedTokenA), camelotBalancedPair.token0(), reserve0, uint256(token0Fee), reserve1, uint256(token1Fee)
        );
        uint256 lpTotalSupply = camelotBalancedPair.totalSupply();

        // Set LP amount to withdraw (reasonable portion of held LP tokens)
        uint256 lpBalance = camelotBalancedPair.balanceOf(address(this));
        uint256 lpAmount = lpBalance / 2; // 50% of held LP tokens

        // Calculate expected total TokenA received
        uint256 expectedTotalTokenA = ConstProdUtils._quoteZapOutAmount(
            lpAmount, reserveA, reserveB, lpTotalSupply, tokenBFee, 100000
        );

        // Execute actual ZapOut
        uint256 initialTokenABalance = camelotBalancedTokenA.balanceOf(address(this));

        // Withdraw the LP amount
        camelotBalancedPair.transfer(address(camelotBalancedPair), lpAmount);
        (uint256 amountA, uint256 amountB) = camelotBalancedPair.burn(address(this));

        // Swap amountB for TokenA
        if (amountB > 0) {
            camelotBalancedTokenB.approve(address(camV2Router()), amountB);
            address[] memory path = new address[](2);
            path[0] = address(camelotBalancedTokenB);
            path[1] = address(camelotBalancedTokenA);

            camV2Router().swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amountB, 1, path, address(this), address(0), block.timestamp
            );
        }

        // Calculate actual TokenA received
        uint256 finalTokenABalance = camelotBalancedTokenA.balanceOf(address(this));
        uint256 actualTotalTokenA = finalTokenABalance - initialTokenABalance;

        // Verify we received exactly the expected amount
        assertEq(actualTotalTokenA, expectedTotalTokenA,
            "Should receive exactly the expected total TokenA amount");
    }

    function test_quoteZapOutAmount_Camelot_unbalancedPool() public {
        (uint112 reserve0, uint112 reserve1, uint16 token0Fee, uint16 token1Fee) = camelotUnbalancedPair.getReserves();
        (uint256 reserveA, uint256 feePercent, uint256 reserveB, uint256 tokenBFee) = ConstProdUtils._sortReserves(
            address(camelotUnbalancedTokenA), camelotUnbalancedPair.token0(), reserve0, uint256(token0Fee), reserve1, uint256(token1Fee)
        );
        uint256 lpTotalSupply = camelotUnbalancedPair.totalSupply();

        // Set LP amount to withdraw (reasonable portion of held LP tokens)
        uint256 lpBalance = camelotUnbalancedPair.balanceOf(address(this));
        uint256 lpAmount = lpBalance / 2; // 50% of held LP tokens

        // Calculate expected total TokenA received
        uint256 expectedTotalTokenA = ConstProdUtils._quoteZapOutAmount(
            lpAmount, reserveA, reserveB, lpTotalSupply, tokenBFee, 100000
        );

        // Execute actual ZapOut
        uint256 initialTokenABalance = camelotUnbalancedTokenA.balanceOf(address(this));

        // Withdraw the LP amount
        camelotUnbalancedPair.transfer(address(camelotUnbalancedPair), lpAmount);
        (uint256 amountA, uint256 amountB) = camelotUnbalancedPair.burn(address(this));

        // Swap amountB for TokenA
        if (amountB > 0) {
            camelotBalancedTokenB.approve(address(camV2Router()), amountB);
            address[] memory path = new address[](2);
            path[0] = address(camelotBalancedTokenB);
            path[1] = address(camelotBalancedTokenA);

            camV2Router().swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amountB, 1, path, address(this), address(0), block.timestamp
            );
        }

        // Calculate actual TokenA received
        uint256 finalTokenABalance = camelotBalancedTokenA.balanceOf(address(this));
        uint256 actualTotalTokenA = finalTokenABalance - initialTokenABalance;

        // Verify we received exactly the expected amount
        assertEq(actualTotalTokenA, expectedTotalTokenA,
            "Should receive exactly the expected total TokenA amount");
    }

    function test_quoteZapOutAmount_Camelot_extremeUnbalancedPool() public {
        (uint112 reserveA, uint112 reserveB, , ) = camelotBalancedPair.getReserves();
        (,,uint32 feeA,) = camelotBalancedPair.getReserves();
        uint256 feePercent = uint256(feeA);
        uint256 lpTotalSupply = camelotBalancedPair.totalSupply();

        // Set LP amount to withdraw (reasonable portion of held LP tokens)
        uint256 lpBalance = camelotBalancedPair.balanceOf(address(this));
        uint256 lpAmount = lpBalance / 2; // 50% of held LP tokens

        // Calculate expected total TokenA received
        uint256 expectedTotalTokenA = ConstProdUtils._quoteZapOutAmount(
            lpAmount, reserveA, reserveB, lpTotalSupply, feePercent, 100000
        );

        // Execute actual ZapOut
        uint256 initialTokenABalance = camelotBalancedTokenA.balanceOf(address(this));

        // Withdraw the LP amount
        camelotBalancedPair.transfer(address(camelotBalancedPair), lpAmount);
        (uint256 amountA, uint256 amountB) = camelotBalancedPair.burn(address(this));

        // Swap amountB for TokenA
        if (amountB > 0) {
            camelotBalancedTokenB.approve(address(camV2Router()), amountB);
            address[] memory path = new address[](2);
            path[0] = address(camelotBalancedTokenB);
            path[1] = address(camelotBalancedTokenA);

            camV2Router().swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amountB, 1, path, address(this), address(0), block.timestamp
            );
        }

        // Calculate actual TokenA received
        uint256 finalTokenABalance = camelotBalancedTokenA.balanceOf(address(this));
        uint256 actualTotalTokenA = finalTokenABalance - initialTokenABalance;

        // Verify we received exactly the expected amount
        assertEq(actualTotalTokenA, expectedTotalTokenA,
            "Should receive exactly the expected total TokenA amount");
    }

    function test_quoteZapOutAmount_Uniswap_balancedPool() public {
        (uint112 reserveA, uint112 reserveB, ) = uniswapBalancedPair.getReserves();
        uint256 lpTotalSupply = uniswapBalancedPair.totalSupply();

        // Set LP amount to withdraw (reasonable portion of held LP tokens)
        uint256 lpBalance = uniswapBalancedPair.balanceOf(address(this));
        uint256 lpAmount = lpBalance / 2; // 50% of held LP tokens

        // Calculate expected total TokenA received
        uint256 expectedTotalTokenA = ConstProdUtils._quoteZapOutAmount(
            lpAmount, reserveA, reserveB, lpTotalSupply, 3, 1000
        );

        // Execute actual ZapOut
        uint256 initialTokenABalance = uniswapUnbalancedTokenA.balanceOf(address(this));

        // Withdraw the LP amount
        uniswapBalancedPair.transfer(address(uniswapBalancedPair), lpAmount);
        (uint256 amountA, uint256 amountB) = uniswapBalancedPair.burn(address(this));

        // Swap amountB for TokenA
        if (amountB > 0) {
            uniswapUnbalancedTokenB.approve(address(uniswapV2Router()), amountB);
            address[] memory path = new address[](2);
            path[0] = address(uniswapUnbalancedTokenB);
            path[1] = address(uniswapUnbalancedTokenA);

            uniswapV2Router().swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amountB, 1, path, address(this), block.timestamp
            );
        }

        // Calculate actual TokenA received
        uint256 finalTokenABalance = uniswapUnbalancedTokenA.balanceOf(address(this));
        uint256 actualTotalTokenA = finalTokenABalance - initialTokenABalance;

        // Verify we received exactly the expected amount
        assertEq(actualTotalTokenA, expectedTotalTokenA,
            "Should receive exactly the expected total TokenA amount");
    }

    function test_quoteZapOutAmount_Uniswap_unbalancedPool() public {
        (uint112 reserveA, uint112 reserveB, ) = uniswapUnbalancedPair.getReserves();
        uint256 lpTotalSupply = uniswapUnbalancedPair.totalSupply();

        // Set LP amount to withdraw (reasonable portion of held LP tokens)
        uint256 lpBalance = uniswapUnbalancedPair.balanceOf(address(this));
        uint256 lpAmount = lpBalance / 2; // 50% of held LP tokens

        // Calculate expected total TokenA received
        uint256 expectedTotalTokenA = ConstProdUtils._quoteZapOutAmount(
            lpAmount, reserveA, reserveB, lpTotalSupply, 3, 1000
        );

        // Execute actual ZapOut
        uint256 initialTokenABalance = uniswapExtremeTokenA.balanceOf(address(this));

        // Withdraw the LP amount
        uniswapUnbalancedPair.transfer(address(uniswapUnbalancedPair), lpAmount);
        (uint256 amountA, uint256 amountB) = uniswapUnbalancedPair.burn(address(this));

        // Swap amountB for TokenA
        if (amountB > 0) {
            uniswapExtremeTokenB.approve(address(uniswapV2Router()), amountB);
            address[] memory path = new address[](2);
            path[0] = address(uniswapExtremeTokenB);
            path[1] = address(uniswapExtremeTokenA);

            uniswapV2Router().swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amountB, 1, path, address(this), block.timestamp
            );
        }

        // Calculate actual TokenA received
        uint256 finalTokenABalance = uniswapExtremeTokenA.balanceOf(address(this));
        uint256 actualTotalTokenA = finalTokenABalance - initialTokenABalance;

        // Verify we received exactly the expected amount
        assertEq(actualTotalTokenA, expectedTotalTokenA,
            "Should receive exactly the expected total TokenA amount");
    }

    function test_quoteZapOutAmount_Uniswap_extremeUnbalancedPool() public {
        (uint112 reserveA, uint112 reserveB, ) = uniswapExtremeUnbalancedPair.getReserves();
        uint256 lpTotalSupply = uniswapExtremeUnbalancedPair.totalSupply();

        // Set LP amount to withdraw (reasonable portion of held LP tokens)
        uint256 lpBalance = uniswapExtremeUnbalancedPair.balanceOf(address(this));
        uint256 lpAmount = lpBalance / 2; // 50% of held LP tokens

        // Calculate expected total TokenA received
        uint256 expectedTotalTokenA = ConstProdUtils._quoteZapOutAmount(
            lpAmount, reserveA, reserveB, lpTotalSupply, 3, 1000
        );

        // Execute actual ZapOut
        uint256 initialTokenABalance = uniswapBalancedTokenA.balanceOf(address(this));

        // Withdraw the LP amount
        uniswapExtremeUnbalancedPair.transfer(address(uniswapExtremeUnbalancedPair), lpAmount);
        (uint256 amountA, uint256 amountB) = uniswapExtremeUnbalancedPair.burn(address(this));

        // Swap amountB for TokenA
        if (amountB > 0) {
            uniswapBalancedTokenB.approve(address(uniswapV2Router()), amountB);
            address[] memory path = new address[](2);
            path[0] = address(uniswapBalancedTokenB);
            path[1] = address(uniswapBalancedTokenA);

            uniswapV2Router().swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amountB, 1, path, address(this), block.timestamp
            );
        }

        // Calculate actual TokenA received
        uint256 finalTokenABalance = uniswapBalancedTokenA.balanceOf(address(this));
        uint256 actualTotalTokenA = finalTokenABalance - initialTokenABalance;

        // Verify we received exactly the expected amount
        assertEq(actualTotalTokenA, expectedTotalTokenA,
            "Should receive exactly the expected total TokenA amount");
    }

    // Edge Case Tests (6 tests)

    function test_quoteZapOutAmount_edgeCase_smallLPAmount() public {
        (uint112 reserveA, uint112 reserveB, , ) = camelotBalancedPair.getReserves();
        (,,uint32 feeA,) = camelotBalancedPair.getReserves();
        uint256 feePercent = uint256(feeA);
        uint256 lpTotalSupply = camelotBalancedPair.totalSupply();

        // Set small LP amount to withdraw
        uint256 lpBalance = camelotBalancedPair.balanceOf(address(this));
        uint256 lpAmount = lpBalance / 4; // 25% of held LP tokens

        // Calculate expected total TokenA received
        uint256 expectedTotalTokenA = ConstProdUtils._quoteZapOutAmount(
            lpAmount, reserveA, reserveB, lpTotalSupply, feePercent, 100000
        );

        // Execute actual ZapOut
        uint256 initialTokenABalance = camelotBalancedTokenA.balanceOf(address(this));

        // Withdraw the LP amount
        camelotBalancedPair.transfer(address(camelotBalancedPair), lpAmount);
        (uint256 amountA, uint256 amountB) = camelotBalancedPair.burn(address(this));

        // Swap amountB for TokenA
        if (amountB > 0) {
            camelotBalancedTokenB.approve(address(camV2Router()), amountB);
            address[] memory path = new address[](2);
            path[0] = address(camelotBalancedTokenB);
            path[1] = address(camelotBalancedTokenA);

            camV2Router().swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amountB, 1, path, address(this), address(0), block.timestamp
            );
        }

        // Calculate actual TokenA received
        uint256 finalTokenABalance = camelotBalancedTokenA.balanceOf(address(this));
        uint256 actualTotalTokenA = finalTokenABalance - initialTokenABalance;

        // Verify we received exactly the expected amount
        assertEq(actualTotalTokenA, expectedTotalTokenA,
            "Should receive exactly the expected total TokenA amount");
    }

    function test_quoteZapOutAmount_edgeCase_largeLPAmount() public {
        (uint112 reserveA, uint112 reserveB, , ) = camelotBalancedPair.getReserves();
        (,,uint32 feeA,) = camelotBalancedPair.getReserves();
        uint256 feePercent = uint256(feeA);
        uint256 lpTotalSupply = camelotBalancedPair.totalSupply();

        // Set large LP amount to withdraw
        uint256 lpBalance = camelotBalancedPair.balanceOf(address(this));
        uint256 lpAmount = (lpBalance * 3) / 4; // 75% of held LP tokens

        // Calculate expected total TokenA received
        uint256 expectedTotalTokenA = ConstProdUtils._quoteZapOutAmount(
            lpAmount, reserveA, reserveB, lpTotalSupply, feePercent, 100000
        );

        // Execute actual ZapOut
        uint256 initialTokenABalance = camelotBalancedTokenA.balanceOf(address(this));

        // Withdraw the LP amount
        camelotBalancedPair.transfer(address(camelotBalancedPair), lpAmount);
        (uint256 amountA, uint256 amountB) = camelotBalancedPair.burn(address(this));

        // Swap amountB for TokenA
        if (amountB > 0) {
            camelotBalancedTokenB.approve(address(camV2Router()), amountB);
            address[] memory path = new address[](2);
            path[0] = address(camelotBalancedTokenB);
            path[1] = address(camelotBalancedTokenA);

            camV2Router().swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amountB, 1, path, address(this), address(0), block.timestamp
            );
        }

        // Calculate actual TokenA received
        uint256 finalTokenABalance = camelotBalancedTokenA.balanceOf(address(this));
        uint256 actualTotalTokenA = finalTokenABalance - initialTokenABalance;

        // Verify we received exactly the expected amount
        assertEq(actualTotalTokenA, expectedTotalTokenA,
            "Should receive exactly the expected total TokenA amount");
    }

    function test_quoteZapOutAmount_edgeCase_differentFees() public {
        (uint112 reserveA, uint112 reserveB, , ) = camelotBalancedPair.getReserves();
        (,,uint32 feeA,) = camelotBalancedPair.getReserves();
        uint256 feePercent = uint256(feeA);
        uint256 lpTotalSupply = camelotBalancedPair.totalSupply();

        // Set LP amount to withdraw
        uint256 lpBalance = camelotBalancedPair.balanceOf(address(this));
        uint256 lpAmount = lpBalance / 2; // 50% of held LP tokens

        // Calculate expected total TokenA received
        uint256 expectedTotalTokenA = ConstProdUtils._quoteZapOutAmount(
            lpAmount, reserveA, reserveB, lpTotalSupply, feePercent, 100000
        );

        // Execute actual ZapOut
        uint256 initialTokenABalance = camelotBalancedTokenA.balanceOf(address(this));

        // Withdraw the LP amount
        camelotBalancedPair.transfer(address(camelotBalancedPair), lpAmount);
        (uint256 amountA, uint256 amountB) = camelotBalancedPair.burn(address(this));

        // Swap amountB for TokenA
        if (amountB > 0) {
            camelotBalancedTokenB.approve(address(camV2Router()), amountB);
            address[] memory path = new address[](2);
            path[0] = address(camelotBalancedTokenB);
            path[1] = address(camelotBalancedTokenA);

            camV2Router().swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amountB, 1, path, address(this), address(0), block.timestamp
            );
        }

        // Calculate actual TokenA received
        uint256 finalTokenABalance = camelotBalancedTokenA.balanceOf(address(this));
        uint256 actualTotalTokenA = finalTokenABalance - initialTokenABalance;

        // Verify we received exactly the expected amount
        assertEq(actualTotalTokenA, expectedTotalTokenA,
            "Should receive exactly the expected total TokenA amount");
    }

    function test_quoteZapOutAmount_edgeCase_verySmallReserves() public {
        (uint112 reserveA, uint112 reserveB, , ) = camelotBalancedPair.getReserves();
        (,,uint32 feeA,) = camelotBalancedPair.getReserves();
        uint256 feePercent = uint256(feeA);
        uint256 lpTotalSupply = camelotBalancedPair.totalSupply();

        // Set small LP amount for extreme unbalanced pool
        uint256 lpBalance = camelotBalancedPair.balanceOf(address(this));
        uint256 lpAmount = lpBalance / 8; // 12.5% of held LP tokens

        // Calculate expected total TokenA received
        uint256 expectedTotalTokenA = ConstProdUtils._quoteZapOutAmount(
            lpAmount, reserveA, reserveB, lpTotalSupply, feePercent, 100000
        );

        // Execute actual ZapOut
        uint256 initialTokenABalance = camelotBalancedTokenA.balanceOf(address(this));

        // Withdraw the LP amount
        camelotBalancedPair.transfer(address(camelotBalancedPair), lpAmount);
        (uint256 amountA, uint256 amountB) = camelotBalancedPair.burn(address(this));

        // Swap amountB for TokenA
        if (amountB > 0) {
            camelotBalancedTokenB.approve(address(camV2Router()), amountB);
            address[] memory path = new address[](2);
            path[0] = address(camelotBalancedTokenB);
            path[1] = address(camelotBalancedTokenA);

            camV2Router().swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amountB, 1, path, address(this), address(0), block.timestamp
            );
        }

        // Calculate actual TokenA received
        uint256 finalTokenABalance = camelotBalancedTokenA.balanceOf(address(this));
        uint256 actualTotalTokenA = finalTokenABalance - initialTokenABalance;

        // Verify we received exactly the expected amount
        assertEq(actualTotalTokenA, expectedTotalTokenA,
            "Should receive exactly the expected total TokenA amount");
    }

    function test_quoteZapOutAmount_edgeCase_midRangeLPAmount() public {
        (uint112 reserveA, uint112 reserveB, , ) = camelotBalancedPair.getReserves();
        (,,uint32 feeA,) = camelotBalancedPair.getReserves();
        uint256 feePercent = uint256(feeA);
        uint256 lpTotalSupply = camelotBalancedPair.totalSupply();

        // Set mid-range LP amount to withdraw
        uint256 lpBalance = camelotBalancedPair.balanceOf(address(this));
        uint256 lpAmount = (lpBalance * 2) / 3; // ~66.7% of held LP tokens

        // Calculate expected total TokenA received
        uint256 expectedTotalTokenA = ConstProdUtils._quoteZapOutAmount(
            lpAmount, reserveA, reserveB, lpTotalSupply, feePercent, 100000
        );

        // Execute actual ZapOut
        uint256 initialTokenABalance = camelotBalancedTokenA.balanceOf(address(this));

        // Withdraw the LP amount
        camelotBalancedPair.transfer(address(camelotBalancedPair), lpAmount);
        (uint256 amountA, uint256 amountB) = camelotBalancedPair.burn(address(this));

        // Swap amountB for TokenA
        if (amountB > 0) {
            camelotBalancedTokenB.approve(address(camV2Router()), amountB);
            address[] memory path = new address[](2);
            path[0] = address(camelotBalancedTokenB);
            path[1] = address(camelotBalancedTokenA);

            camV2Router().swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amountB, 1, path, address(this), address(0), block.timestamp
            );
        }

        // Calculate actual TokenA received
        uint256 finalTokenABalance = camelotBalancedTokenA.balanceOf(address(this));
        uint256 actualTotalTokenA = finalTokenABalance - initialTokenABalance;

        // Verify we received exactly the expected amount
        assertEq(actualTotalTokenA, expectedTotalTokenA,
            "Should receive exactly the expected total TokenA amount");
    }

    function test_quoteZapOutAmount_edgeCase_maxLPAmount() public {
        (uint112 reserveA, uint112 reserveB, ) = uniswapBalancedPair.getReserves();
        uint256 lpTotalSupply = uniswapBalancedPair.totalSupply();

        // Set maximum reasonable LP amount to withdraw
        uint256 lpBalance = uniswapBalancedPair.balanceOf(address(this));
        uint256 lpAmount = (lpBalance * 9) / 10; // 90% of held LP tokens

        // Calculate expected total TokenA received
        uint256 expectedTotalTokenA = ConstProdUtils._quoteZapOutAmount(
            lpAmount, reserveA, reserveB, lpTotalSupply, 300, 100000
        );

        // Execute actual ZapOut
        uint256 initialTokenABalance = uniswapBalancedTokenA.balanceOf(address(this));

        // Withdraw the LP amount
        uniswapBalancedPair.transfer(address(uniswapBalancedPair), lpAmount);
        (uint256 amountA, uint256 amountB) = uniswapBalancedPair.burn(address(this));

        // Swap amountB for TokenA
        if (amountB > 0) {
            uniswapBalancedTokenB.approve(address(uniswapV2Router()), amountB);
            address[] memory path = new address[](2);
            path[0] = address(uniswapBalancedTokenB);
            path[1] = address(uniswapBalancedTokenA);

            uniswapV2Router().swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amountB, 1, path, address(this), block.timestamp
            );
        }

        // Calculate actual TokenA received
        uint256 finalTokenABalance = uniswapBalancedTokenA.balanceOf(address(this));
        uint256 actualTotalTokenA = finalTokenABalance - initialTokenABalance;

        // Verify we received exactly the expected amount
        assertEq(actualTotalTokenA, expectedTotalTokenA,
            "Should receive exactly the expected total TokenA amount");
    }
}
