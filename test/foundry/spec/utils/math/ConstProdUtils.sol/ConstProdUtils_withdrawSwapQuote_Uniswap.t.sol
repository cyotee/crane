// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import {TestBase_ConstProdUtils_Uniswap} from "./TestBase_ConstProdUtils_Uniswap.sol";
import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";

contract ConstProdUtils_withdrawSwapQuote_Uniswap is TestBase_ConstProdUtils_Uniswap {
    function setUp() public override {
        super.setUp();
    }

    function test_withdrawSwapQuote_Uniswap_balancedPool() public {
        _initializeUniswapBalancedPools();
        (uint112 reserve0, uint112 reserve1,) = uniswapBalancedPair.getReserves();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
            address(uniswapBalancedTokenA), uniswapBalancedPair.token0(), reserve0, reserve1
        );
        uint256 lpTotalSupply = uniswapBalancedPair.totalSupply();

        uint256 lpBalance = uniswapBalancedPair.balanceOf(address(this));
        uint256 ownedLPAmount = lpBalance / 2;

        uint256 expectedTotalTokenA = ConstProdUtils._quoteWithdrawSwapWithFee(
            ownedLPAmount, lpTotalSupply, reserveA, reserveB, 300, 0, 0, false
        );

        // Execute actual withdraw + swap
        uint256 initialTokenABalance = uniswapBalancedTokenA.balanceOf(address(this));

        uniswapBalancedPair.transfer(address(uniswapBalancedPair), ownedLPAmount);
        (uint256 amountA, uint256 amountB) = uniswapBalancedPair.burn(address(this));

        uint256 actualAmountA = amountA;
        uint256 actualAmountB = amountB;

        if (actualAmountB > 0) {
            uniswapBalancedTokenB.approve(address(uniswapV2Router), actualAmountB);
            address[] memory path = new address[](2);
            path[0] = address(uniswapBalancedTokenB);
            path[1] = address(uniswapBalancedTokenA);

            uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                actualAmountB, 1, path, address(this), block.timestamp
            );
        }

        uint256 finalTokenABalance = uniswapBalancedTokenA.balanceOf(address(this));
        uint256 actualTotalTokenA = finalTokenABalance - initialTokenABalance;

        assertEq(actualTotalTokenA, expectedTotalTokenA, "Should receive exactly the expected total TokenA amount");
    }

    function test_withdrawSwapQuote_Uniswap_unbalancedPool() public {
        _initializeUniswapUnbalancedPools();
        (uint112 reserve0, uint112 reserve1,) = uniswapUnbalancedPair.getReserves();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
            address(uniswapUnbalancedTokenA), uniswapUnbalancedPair.token0(), reserve0, reserve1
        );
        uint256 lpTotalSupply = uniswapUnbalancedPair.totalSupply();

        uint256 lpBalance = uniswapUnbalancedPair.balanceOf(address(this));
        uint256 ownedLPAmount = lpBalance / 2;

        uint256 expectedTotalTokenA = ConstProdUtils._quoteWithdrawSwapWithFee(
            ownedLPAmount, lpTotalSupply, reserveA, reserveB, 300, 0, 0, false
        );

        uint256 initialTokenABalance = uniswapUnbalancedTokenA.balanceOf(address(this));

        uniswapUnbalancedPair.transfer(address(uniswapUnbalancedPair), ownedLPAmount);
        (uint256 amount0, uint256 amount1) = uniswapUnbalancedPair.burn(address(this));

        uint256 actualAmountA;
        uint256 actualAmountB;
        if (uniswapUnbalancedPair.token0() == address(uniswapUnbalancedTokenA)) {
            actualAmountA = amount0;
            actualAmountB = amount1;
        } else {
            actualAmountA = amount1;
            actualAmountB = amount0;
        }

        if (actualAmountB > 0) {
            uniswapUnbalancedTokenB.approve(address(uniswapV2Router), actualAmountB);
            address[] memory path = new address[](2);
            path[0] = address(uniswapUnbalancedTokenB);
            path[1] = address(uniswapUnbalancedTokenA);

            uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                actualAmountB, 1, path, address(this), block.timestamp
            );
        }

        uint256 finalTokenABalance = uniswapUnbalancedTokenA.balanceOf(address(this));
        uint256 actualTotalTokenA = finalTokenABalance - initialTokenABalance;

        assertEq(actualTotalTokenA, expectedTotalTokenA, "Should receive exactly the expected total TokenA amount");
    }

    function test_withdrawSwapQuote_Uniswap_extremeUnbalancedPool() public {
        _initializeUniswapExtremeUnbalancedPools();
        (uint112 reserve0, uint112 reserve1,) = uniswapExtremeUnbalancedPair.getReserves();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
            address(uniswapExtremeTokenA),
            uniswapExtremeUnbalancedPair.token0(),
            reserve0,
            reserve1
        );
        uint256 lpTotalSupply = uniswapExtremeUnbalancedPair.totalSupply();

        uint256 lpBalance = uniswapExtremeUnbalancedPair.balanceOf(address(this));
        uint256 ownedLPAmount = lpBalance / 2;

        uint256 expectedTotalTokenA = ConstProdUtils._quoteWithdrawSwapWithFee(
            ownedLPAmount, lpTotalSupply, reserveA, reserveB, 300, 0, 0, false
        );

        uint256 initialTokenABalance = uniswapExtremeTokenA.balanceOf(address(this));


        uniswapExtremeUnbalancedPair.transfer(address(uniswapExtremeUnbalancedPair), ownedLPAmount);
        (uint256 amountA, uint256 amountB) = uniswapExtremeUnbalancedPair.burn(address(this));


        uint256 actualAmountA;
        uint256 actualAmountB;
        if (uniswapExtremeUnbalancedPair.token0() == address(uniswapExtremeTokenA)) {
            actualAmountA = amountA;
            actualAmountB = amountB;
        } else {
            actualAmountA = amountB;
            actualAmountB = amountA;
        }


        if (actualAmountB > 0) {
            uniswapExtremeTokenB.approve(address(uniswapV2Router), actualAmountB);
            address[] memory path = new address[](2);
            path[0] = address(uniswapExtremeTokenB);
            path[1] = address(uniswapExtremeTokenA);

            uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                actualAmountB, 1, path, address(this), block.timestamp
            );
        }

        uint256 finalTokenABalance = uniswapExtremeTokenA.balanceOf(address(this));
        uint256 actualTotalTokenA = finalTokenABalance - initialTokenABalance;

        

        assertEq(actualTotalTokenA, expectedTotalTokenA, "Should receive exactly the expected total TokenA amount");
    }
}
