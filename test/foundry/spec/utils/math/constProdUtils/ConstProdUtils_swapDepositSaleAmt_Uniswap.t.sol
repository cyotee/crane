// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";
import {TestBase_ConstProdUtils_Uniswap} from "./TestBase_ConstProdUtils_Uniswap.sol";
import {IUniswapV2Pair} from "contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Pair.sol";
import "forge-std/console.sol";

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
        _initializeUniswapBalancedPools();
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
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
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
            reserveA + saleAmt,
            reserveB - tokenBReceived
        );

        // Execute the deposit directly to the pair and mint to avoid router rounding
        uniswapBalancedTokenA.transfer(address(uniswapBalancedPair), remainingTokenA);
        uniswapBalancedTokenB.transfer(address(uniswapBalancedPair), tokenBReceived);
        uint256 actualLPTokens = IUniswapV2Pair(address(uniswapBalancedPair)).mint(address(this));

        // Validate exact equality
        assertEq(actualLPTokens, expectedLPTokens, "Actual LP tokens should equal expected LP tokens exactly");
    }

    function test_swapDepositSaleAmt_Uniswap_unbalancedPool() public {
        _initializeUniswapUnbalancedPools();
        (uint112 reserveA, uint112 reserveB,) = uniswapUnbalancedPair.getReserves();
        (,, uint32 feeA) = uniswapUnbalancedPair.getReserves();
        uint256 feePercent = uint256(feeA);
        uint256 amountIn = 100e18; // Smaller input for unbalanced pool

        // Calculate sale amount using ConstProdUtils
        uint256 saleAmt = ConstProdUtils._swapDepositSaleAmt(amountIn, reserveA, feePercent);

        // Mint tokens for the test
        uniswapUnbalancedTokenA.mint(address(this), amountIn);
        uniswapUnbalancedTokenA.approve(address(uniswapV2Router), amountIn);

        // Execute the swap
        address[] memory path = new address[](2);
        path[0] = address(uniswapUnbalancedTokenA);
        path[1] = address(uniswapUnbalancedTokenB);

        uint256 tokenBBeforeSwap = uniswapUnbalancedTokenB.balanceOf(address(this));
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            saleAmt, 0, path, address(this), block.timestamp + 300
        );
        uint256 tokenBReceived = uniswapUnbalancedTokenB.balanceOf(address(this)) - tokenBBeforeSwap;

        // Calculate expected LP tokens using post-swap reserves and fee-aware quote
        uint256 remainingTokenA = amountIn - saleAmt;

        // Read updated reserves after swap
        (uint112 ur0, uint112 ur1,) = uniswapUnbalancedPair.getReserves();
        uint256 updatedReserveA = (address(uniswapUnbalancedTokenA) == uniswapUnbalancedPair.token0())
            ? uint256(ur0)
            : uint256(ur1);
        uint256 updatedReserveB = (address(uniswapUnbalancedTokenA) == uniswapUnbalancedPair.token0())
            ? uint256(ur1)
            : uint256(ur0);

        // Approve and add liquidity via router to capture actual amounts used
        uint256 lpTotalBefore = uniswapUnbalancedPair.totalSupply();
        console.log("Uniswap unbalanced lpTotalBefore", lpTotalBefore);
        console.log("Uniswap unbalanced reserves after swap A", updatedReserveA);
        console.log("Uniswap unbalanced reserves after swap B", updatedReserveB);
        uniswapUnbalancedTokenA.approve(address(uniswapV2Router), remainingTokenA);
        uniswapUnbalancedTokenB.approve(address(uniswapV2Router), tokenBReceived);
        (uint256 amountAUsed, uint256 amountBUsed, uint256 actualLPTokens) = uniswapV2Router.addLiquidity(
            address(uniswapUnbalancedTokenA),
            address(uniswapUnbalancedTokenB),
            remainingTokenA,
            tokenBReceived,
            1,
            1,
            address(this),
            block.timestamp + 300
        );

        // Use fee-aware quote matching Uniswap mint behaviour (ownerFeeShare ~= 1/6)
        uint256 expected = ConstProdUtils._quoteDepositWithFee(
            amountAUsed,
            amountBUsed,
            lpTotalBefore,
            updatedReserveA,
            updatedReserveB,
            uniswapUnbalancedPair.kLast(),
            16666,
            true
        );

        uint256 lpTotalAfter = uniswapUnbalancedPair.totalSupply();
        console.log("Uniswap unbalanced lpTotalAfter", lpTotalAfter);
        console.log("Uniswap unbalanced amountAUsed", amountAUsed);
        console.log("Uniswap unbalanced amountBUsed", amountBUsed);
        console.log("Uniswap unbalanced actualLPTokens", actualLPTokens);
        console.log("Uniswap unbalanced expected", expected);
        assertEq(actualLPTokens, expected);
    }

    function test_swapDepositSaleAmt_Uniswap_extremeUnbalancedPool() public {
        _initializeUniswapExtremeUnbalancedPools();
        (uint112 reserveA, uint112 reserveB,) = uniswapExtremeUnbalancedPair.getReserves();
        (,, uint32 feeA) = uniswapExtremeUnbalancedPair.getReserves();
        uint256 feePercent = uint256(feeA);
        uint256 amountIn = 10e18; // Very small input for extreme unbalanced pool

        // Calculate sale amount using ConstProdUtils
        uint256 saleAmt = ConstProdUtils._swapDepositSaleAmt(amountIn, reserveA, feePercent);

        // Mint tokens for the test
        uniswapExtremeTokenA.mint(address(this), amountIn);
        uniswapExtremeTokenA.approve(address(uniswapV2Router), amountIn);

        // Execute the swap
        address[] memory path = new address[](2);
        path[0] = address(uniswapExtremeTokenA);
        path[1] = address(uniswapExtremeTokenB);

        uint256 tokenBBeforeSwap = uniswapExtremeTokenB.balanceOf(address(this));
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            saleAmt, 0, path, address(this), block.timestamp + 300
        );
        uint256 tokenBReceived = uniswapExtremeTokenB.balanceOf(address(this)) - tokenBBeforeSwap;

        // Calculate expected LP tokens using post-swap reserves and fee-aware quote
        uint256 remainingTokenA = amountIn - saleAmt;

        // Read updated reserves after swap
        (uint112 ur0, uint112 ur1,) = uniswapExtremeUnbalancedPair.getReserves();
        uint256 updatedReserveA = (address(uniswapExtremeTokenA) == uniswapExtremeUnbalancedPair.token0())
            ? uint256(ur0)
            : uint256(ur1);
        uint256 updatedReserveB = (address(uniswapExtremeTokenA) == uniswapExtremeUnbalancedPair.token0())
            ? uint256(ur1)
            : uint256(ur0);

        // Approve and add liquidity via router
        uint256 lpTotalBefore = uniswapExtremeUnbalancedPair.totalSupply();
        console.log("Uniswap extreme lpTotalBefore", lpTotalBefore);
        console.log("Uniswap extreme reserves after swap A", updatedReserveA);
        console.log("Uniswap extreme reserves after swap B", updatedReserveB);
        uniswapExtremeTokenA.approve(address(uniswapV2Router), remainingTokenA);
        uniswapExtremeTokenB.approve(address(uniswapV2Router), tokenBReceived);
        (uint256 amountAUsed, uint256 amountBUsed, uint256 actualLPTokens) = uniswapV2Router.addLiquidity(
            address(uniswapExtremeTokenA),
            address(uniswapExtremeTokenB),
            remainingTokenA,
            tokenBReceived,
            1,
            1,
            address(this),
            block.timestamp + 300
        );

        // Use fee-aware quote matching Uniswap mint behaviour (ownerFeeShare ~= 1/6)
        uint256 expected = ConstProdUtils._quoteDepositWithFee(
            amountAUsed,
            amountBUsed,
            lpTotalBefore,
            updatedReserveA,
            updatedReserveB,
            uniswapExtremeUnbalancedPair.kLast(),
            16666,
            true
        );

        uint256 lpTotalAfter = uniswapExtremeUnbalancedPair.totalSupply();
        console.log("Uniswap extreme lpTotalAfter", lpTotalAfter);
        console.log("Uniswap extreme amountAUsed", amountAUsed);
        console.log("Uniswap extreme amountBUsed", amountBUsed);
        console.log("Uniswap extreme actualLPTokens", actualLPTokens);
        console.log("Uniswap extreme expected", expected);
        assertEq(actualLPTokens, expected);
    }
}
