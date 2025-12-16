// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {TestBase_ConstProdUtils_Uniswap} from "../constProdUtils/TestBase_ConstProdUtils_Uniswap.sol";
import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";

contract ConstProdUtils_swapDepositSaleAmt_Uniswap is TestBase_ConstProdUtils_Uniswap {
    using ConstProdUtils for uint256;

    function setUp() public override {
        super.setUp();
    }

    function _runUniswapAddLiquidityAndAssert(
        uint256 reserveA,
        uint256 reserveB,
        uint256 saleAmt,
        uint256 remainingTokenA,
        uint256 tokenBReceived
    ) internal {
        uint256 lpTotalBefore = uniswapBalancedPair.totalSupply();
        (uint256 amountAUsed, uint256 amountBUsed, uint256 actualLPTokens) = uniswapV2Router
            .addLiquidity(
                address(uniswapBalancedTokenA),
                address(uniswapBalancedTokenB),
                remainingTokenA,
                tokenBReceived,
                1,
                1,
                address(this),
                block.timestamp + 300
            );
        uint256 expected = ConstProdUtils._depositQuote(
            amountAUsed,
            amountBUsed,
            lpTotalBefore,
            reserveA + saleAmt,
            reserveB - tokenBReceived
        );
        assertEq(actualLPTokens, expected);
    }

    function test_swapDepositSaleAmt_Uniswap_balancedPool() public {
        (uint112 reserveA, uint112 reserveB,) = uniswapBalancedPair.getReserves();
        (,, uint32 feeA) = uniswapBalancedPair.getReserves();
        uint256 feePercent = uint256(feeA);
        uint256 amountIn = 1000e18; // Input amount

        // Calculate sale amount using ConstProdUtils
        uint256 saleAmt = ConstProdUtils._swapDepositSaleAmt(amountIn, reserveA, feePercent);

        // Mint tokens for the test
        uniswapBalancedTokenA.mint(address(this), amountIn);
        uniswapBalancedTokenA.approve(address(uniswapV2Router), amountIn);

        // Execute the swap
        address[] memory path = new address[](2);
        path[0] = address(uniswapBalancedTokenA);
        path[1] = address(uniswapBalancedTokenB);

        uint256 tokenBBeforeSwap = uniswapBalancedTokenB.balanceOf(address(this));
        uniswapV2Router
            .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                saleAmt, 0, path, address(this), block.timestamp + 300
            );
        uint256 tokenBReceived = uniswapBalancedTokenB.balanceOf(address(this)) - tokenBBeforeSwap;

        // Calculate remaining token A after swap
        uint256 remainingTokenA = amountIn - saleAmt;
        // Calculate expected LP tokens using _depositQuote
        uint256 expectedLPTokens = ConstProdUtils._depositQuote(
            remainingTokenA,
            tokenBReceived,
            uniswapBalancedPair.totalSupply(),
            reserveA + saleAmt, // New reserveA after swap
            reserveB - tokenBReceived // New reserveB after swap
        );

        // Execute the deposit directly to the pair and mint to avoid router rounding
        uniswapBalancedTokenA.transfer(address(uniswapBalancedPair), remainingTokenA);
        uniswapBalancedTokenB.transfer(address(uniswapBalancedPair), tokenBReceived);
        uint256 actualLPTokens = uniswapBalancedPair.mint(address(this));

        // Validate exact equality
        assertEq(actualLPTokens, expectedLPTokens, "Actual LP tokens should equal expected LP tokens exactly");
    }

    function test_swapDepositSaleAmt_Uniswap_unbalancedPool() public {
        (uint112 reserveA, uint112 reserveB,) = uniswapBalancedPair.getReserves();
        (,, uint32 feeA) = uniswapBalancedPair.getReserves();
        uint256 feePercent = uint256(feeA);
        uint256 amountIn = 100e18; // Smaller input for unbalanced pool

        // Calculate sale amount using ConstProdUtils
        uint256 saleAmt = ConstProdUtils._swapDepositSaleAmt(amountIn, reserveA, feePercent);

        // Mint tokens for the test
        uniswapBalancedTokenA.mint(address(this), amountIn);
        uniswapBalancedTokenA.approve(address(uniswapV2Router), amountIn);

        // Execute the swap
        address[] memory path = new address[](2);
        path[0] = address(uniswapBalancedTokenA);
        path[1] = address(uniswapBalancedTokenB);

        uint256 tokenBBeforeSwap = uniswapBalancedTokenB.balanceOf(address(this));
        uniswapV2Router
            .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                saleAmt, 0, path, address(this), block.timestamp + 300
            );
        uint256 tokenBReceived = uniswapBalancedTokenB.balanceOf(address(this)) - tokenBBeforeSwap;

        // Calculate expected LP tokens using _depositQuote
        uint256 remainingTokenA = amountIn - saleAmt;
        uint256 expectedLPTokens = ConstProdUtils._depositQuote(
            remainingTokenA,
            tokenBReceived,
            uniswapBalancedPair.totalSupply(),
            reserveA + saleAmt, // New reserveA after swap
            reserveB - tokenBReceived // New reserveB after swap
        );

        // Execute the deposit
        uniswapBalancedTokenA.approve(address(uniswapV2Router), remainingTokenA);
        uniswapBalancedTokenB.approve(address(uniswapV2Router), tokenBReceived);

        _runUniswapAddLiquidityAndAssert(reserveA, reserveB, saleAmt, remainingTokenA, tokenBReceived);
    }

    function test_swapDepositSaleAmt_Uniswap_extremeUnbalancedPool() public {
        (uint112 reserveA, uint112 reserveB,) = uniswapBalancedPair.getReserves();
        (,, uint32 feeA) = uniswapBalancedPair.getReserves();
        uint256 feePercent = uint256(feeA);
        uint256 amountIn = 10e18; // Very small input for extreme unbalanced pool

        // Calculate sale amount using ConstProdUtils
        uint256 saleAmt = ConstProdUtils._swapDepositSaleAmt(amountIn, reserveA, feePercent);

        // Mint tokens for the test
        uniswapBalancedTokenA.mint(address(this), amountIn);
        uniswapBalancedTokenA.approve(address(uniswapV2Router), amountIn);

        // Execute the swap
        address[] memory path = new address[](2);
        path[0] = address(uniswapBalancedTokenA);
        path[1] = address(uniswapBalancedTokenB);

        uint256 tokenBBeforeSwap = uniswapBalancedTokenB.balanceOf(address(this));
        uniswapV2Router
            .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                saleAmt, 0, path, address(this), block.timestamp + 300
            );
        uint256 tokenBReceived = uniswapBalancedTokenB.balanceOf(address(this)) - tokenBBeforeSwap;

        // Calculate expected LP tokens using _depositQuote
        uint256 remainingTokenA = amountIn - saleAmt;
        uint256 expectedLPTokens = ConstProdUtils._depositQuote(
            remainingTokenA,
            tokenBReceived,
            uniswapBalancedPair.totalSupply(),
            reserveA + saleAmt, // New reserveA after swap
            reserveB - tokenBReceived // New reserveB after swap
        );

        // Execute the deposit
        uniswapBalancedTokenA.approve(address(uniswapV2Router), remainingTokenA);
        uniswapBalancedTokenB.approve(address(uniswapV2Router), tokenBReceived);

        _runUniswapAddLiquidityAndAssert(reserveA, reserveB, saleAmt, remainingTokenA, tokenBReceived);
    }
}
