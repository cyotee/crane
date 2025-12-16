// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {TestBase_ConstProdUtils_Uniswap} from "./TestBase_ConstProdUtils_Uniswap.sol";
import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";

contract ConstProdUtils_swapDepositQuote_Uniswap is TestBase_ConstProdUtils_Uniswap {
    function setUp() public override {
        super.setUp();
    }

    function test_quoteSwapDepositWithFee_Uniswap_balancedPool_basic() public {
        _initializeUniswapBalancedPools();
        (uint112 reserve0, uint112 reserve1,) = uniswapBalancedPair.getReserves();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
            address(uniswapBalancedTokenA), uniswapBalancedPair.token0(), reserve0, reserve1
        );

        uint256 lpTotalSupply = uniswapBalancedPair.totalSupply();
        uint256 amountIn = 1e18;

        uint256 expectedLp = ConstProdUtils._quoteSwapDepositWithFee(
            amountIn, lpTotalSupply, reserveA, reserveB, 300, 0, 0, false
        );

        // Basic sanity: expected LP should be non-zero for meaningful inputs
        assertGt(expectedLp, 0, "Expected LP quote should be greater than 0");
    }

    function test_swapDepositQuote_Uniswap_balancedPool() public {
        _initializeUniswapBalancedPools();

        (uint112 reserve0, uint112 reserve1,) = uniswapBalancedPair.getReserves();
        uint256 amountIn = 1000e18;
        uint256 lpTotalSupply = uniswapBalancedPair.totalSupply();

        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(address(uniswapBalancedTokenA), uniswapBalancedPair.token0(), reserve0, reserve1);
        uint256 feePercent = 300;

        uint256 expectedLPTokens = ConstProdUtils._quoteSwapDepositWithFee(
            amountIn,
            lpTotalSupply,
            reserveA,
            reserveB,
            feePercent,
            0,
            0,
            false
        );
        uint256 swapAmount = ConstProdUtils._swapDepositSaleAmt(amountIn, reserveA, feePercent);

        uniswapBalancedTokenA.mint(address(this), amountIn);
        uniswapBalancedTokenA.approve(address(uniswapV2Router), amountIn);

        address[] memory path = new address[](2);
        path[0] = address(uniswapBalancedTokenA);
        path[1] = address(uniswapBalancedTokenB);

        uint256 tokenBBeforeSwap = uniswapBalancedTokenB.balanceOf(address(this));
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(swapAmount, 0, path, address(this), block.timestamp + 300);
        uint256 tokenBReceived = uniswapBalancedTokenB.balanceOf(address(this)) - tokenBBeforeSwap;

        uint256 remainingTokenA = amountIn - swapAmount;
        uniswapBalancedTokenA.approve(address(uniswapV2Router), remainingTokenA);
        uniswapBalancedTokenB.approve(address(uniswapV2Router), tokenBReceived);

        (,, uint256 actualLPTokens) = uniswapV2Router.addLiquidity(address(uniswapBalancedTokenA), address(uniswapBalancedTokenB), remainingTokenA, tokenBReceived, 1, 1, address(this), block.timestamp + 300);

        assertEq(actualLPTokens, expectedLPTokens, "Actual LP tokens should equal expected LP tokens exactly");
    }

}
