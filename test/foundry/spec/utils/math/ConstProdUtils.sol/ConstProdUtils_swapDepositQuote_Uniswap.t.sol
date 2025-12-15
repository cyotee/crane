// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {betterconsole as console} from "contracts/utils/vm/foundry/tools/betterconsole.sol";
import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";
import {TestBase_ConstProdUtils_Uniswap} from "@crane/test/foundry/spec/utils/math/ConstProdUtils.sol/TestBase_ConstProdUtils_Uniswap.sol";

contract ConstProdUtils_swapDepositQuote_Uniswap_Test is TestBase_ConstProdUtils_Uniswap {
    function setUp() public override {
        TestBase_ConstProdUtils_Uniswap.setUp();
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
