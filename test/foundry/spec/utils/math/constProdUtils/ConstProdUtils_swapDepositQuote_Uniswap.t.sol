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

    function test_quoteSwapDepositWithFee_Uniswap_unbalancedPool_swapsTokenA_feesDisabled() public {
        _initializeUniswapUnbalancedPools();

        (uint112 reserve0, uint112 reserve1,) = uniswapUnbalancedPair.getReserves();
        uint256 amountIn = 1000e18;
        uint256 lpTotalSupply = uniswapUnbalancedPair.totalSupply();

        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(address(uniswapUnbalancedTokenA), uniswapUnbalancedPair.token0(), reserve0, reserve1);
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

        uniswapUnbalancedTokenA.mint(address(this), amountIn);
        uniswapUnbalancedTokenA.approve(address(uniswapV2Router), amountIn);

        address[] memory path = new address[](2);
        path[0] = address(uniswapUnbalancedTokenA);
        path[1] = address(uniswapUnbalancedTokenB);

        uint256 tokenBBeforeSwap = uniswapUnbalancedTokenB.balanceOf(address(this));
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(swapAmount, 0, path, address(this), block.timestamp + 300);
        uint256 tokenBReceived = uniswapUnbalancedTokenB.balanceOf(address(this)) - tokenBBeforeSwap;

        uint256 remainingTokenA = amountIn - swapAmount;
        uniswapUnbalancedTokenA.approve(address(uniswapV2Router), remainingTokenA);
        uniswapUnbalancedTokenB.approve(address(uniswapV2Router), tokenBReceived);

        (,, uint256 actualLPTokens) = uniswapV2Router.addLiquidity(address(uniswapUnbalancedTokenA), address(uniswapUnbalancedTokenB), remainingTokenA, tokenBReceived, 1, 1, address(this), block.timestamp + 300);

        assertEq(actualLPTokens, expectedLPTokens, "Actual LP tokens should equal expected LP tokens exactly (unbalanced A->B)");
    }

    function test_quoteSwapDepositWithFee_Uniswap_unbalancedPool_swapsTokenB_feesDisabled() public {
        _initializeUniswapUnbalancedPools();

        (uint112 reserve0, uint112 reserve1,) = uniswapUnbalancedPair.getReserves();
        uint256 amountIn = 1000e18;
        uint256 lpTotalSupply = uniswapUnbalancedPair.totalSupply();

        // For TokenB input, sort reserves with TokenB as known token
        (uint256 reserveIn, uint256 reserveOut) = ConstProdUtils._sortReserves(address(uniswapUnbalancedTokenB), uniswapUnbalancedPair.token0(), reserve0, reserve1);
        uint256 feePercent = 300;

        uint256 expectedLPTokens = ConstProdUtils._quoteSwapDepositWithFee(
            amountIn,
            lpTotalSupply,
            reserveIn,
            reserveOut,
            feePercent,
            0,
            0,
            false
        );

        uint256 swapAmount = ConstProdUtils._swapDepositSaleAmt(amountIn, reserveIn, feePercent);

        uniswapUnbalancedTokenB.mint(address(this), amountIn);
        uniswapUnbalancedTokenB.approve(address(uniswapV2Router), amountIn);

        address[] memory path = new address[](2);
        path[0] = address(uniswapUnbalancedTokenB);
        path[1] = address(uniswapUnbalancedTokenA);

        uint256 tokenABeforeSwap = uniswapUnbalancedTokenA.balanceOf(address(this));
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(swapAmount, 0, path, address(this), block.timestamp + 300);
        uint256 tokenAReceived = uniswapUnbalancedTokenA.balanceOf(address(this)) - tokenABeforeSwap;

        uint256 remainingTokenB = amountIn - swapAmount;
        uniswapUnbalancedTokenB.approve(address(uniswapV2Router), remainingTokenB);
        uniswapUnbalancedTokenA.approve(address(uniswapV2Router), tokenAReceived);

        (,, uint256 actualLPTokens) = uniswapV2Router.addLiquidity(address(uniswapUnbalancedTokenA), address(uniswapUnbalancedTokenB), tokenAReceived, remainingTokenB, 1, 1, address(this), block.timestamp + 300);

        assertEq(actualLPTokens, expectedLPTokens, "Actual LP tokens should equal expected LP tokens exactly (unbalanced B->A)");
    }

    function test_quoteSwapDepositWithFee_Uniswap_extremeUnbalancedPool_swapsTokenA_feesDisabled() public {
        _initializeUniswapExtremeUnbalancedPools();

        (uint112 reserve0, uint112 reserve1,) = uniswapExtremeUnbalancedPair.getReserves();
        uint256 amountIn = 1000e18;
        uint256 lpTotalSupply = uniswapExtremeUnbalancedPair.totalSupply();

        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(address(uniswapExtremeTokenA), uniswapExtremeUnbalancedPair.token0(), reserve0, reserve1);
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

        uniswapExtremeTokenA.mint(address(this), amountIn);
        uniswapExtremeTokenA.approve(address(uniswapV2Router), amountIn);

        address[] memory path = new address[](2);
        path[0] = address(uniswapExtremeTokenA);
        path[1] = address(uniswapExtremeTokenB);

        uint256 tokenBBeforeSwap = uniswapExtremeTokenB.balanceOf(address(this));
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(swapAmount, 0, path, address(this), block.timestamp + 300);
        uint256 tokenBReceived = uniswapExtremeTokenB.balanceOf(address(this)) - tokenBBeforeSwap;

        uint256 remainingTokenA = amountIn - swapAmount;
        uniswapExtremeTokenA.approve(address(uniswapV2Router), remainingTokenA);
        uniswapExtremeTokenB.approve(address(uniswapV2Router), tokenBReceived);

        (,, uint256 actualLPTokens) = uniswapV2Router.addLiquidity(address(uniswapExtremeTokenA), address(uniswapExtremeTokenB), remainingTokenA, tokenBReceived, 1, 1, address(this), block.timestamp + 300);

        assertEq(actualLPTokens, expectedLPTokens, "Actual LP tokens should equal expected LP tokens exactly (extreme A->B)");
    }

    function test_quoteSwapDepositWithFee_Uniswap_extremeUnbalancedPool_swapsTokenB_feesDisabled() public {
        _initializeUniswapExtremeUnbalancedPools();

                (uint112 reserve0, uint112 reserve1,) = uniswapExtremeUnbalancedPair.getReserves();
        uint256 amountIn = 1000e18;
        uint256 lpTotalSupply = uniswapExtremeUnbalancedPair.totalSupply();
        (uint256 reserveIn, uint256 reserveOut) = ConstProdUtils._sortReserves(address(uniswapExtremeTokenB), uniswapExtremeUnbalancedPair.token0(), reserve0, reserve1);
        uint256 feePercent = 300;

        uint256 expectedLPTokens = ConstProdUtils._quoteSwapDepositWithFee(
            amountIn,
            lpTotalSupply,
            reserveIn,
            reserveOut,
            feePercent,
            0,
            0,
            false
        );

        uint256 swapAmount = ConstProdUtils._swapDepositSaleAmt(amountIn, reserveIn, feePercent);

        uniswapExtremeTokenB.mint(address(this), amountIn);
        uniswapExtremeTokenB.approve(address(uniswapV2Router), amountIn);

        address[] memory path = new address[](2);
        path[0] = address(uniswapExtremeTokenB);
        path[1] = address(uniswapExtremeTokenA);

        uint256 tokenABeforeSwap = uniswapExtremeTokenA.balanceOf(address(this));
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(swapAmount, 0, path, address(this), block.timestamp + 300);
        uint256 tokenAReceived = uniswapExtremeTokenA.balanceOf(address(this)) - tokenABeforeSwap;

        uint256 remainingTokenB = amountIn - swapAmount;
        uniswapExtremeTokenB.approve(address(uniswapV2Router), remainingTokenB);
        uniswapExtremeTokenA.approve(address(uniswapV2Router), tokenAReceived);

        (,, uint256 actualLPTokens) = uniswapV2Router.addLiquidity(address(uniswapExtremeTokenA), address(uniswapExtremeTokenB), tokenAReceived, remainingTokenB, 1, 1, address(this), block.timestamp + 300);

        assertEq(actualLPTokens, expectedLPTokens, "Actual LP tokens should equal expected LP tokens exactly (extreme B->A)");
    }

    // =========================
    // Fees enabled variants
    // =========================

    function test_quoteSwapDepositWithFee_Uniswap_balancedPool_swapsTokenA_feesEnabled() public {
        _initializeUniswapBalancedPools();

        // enable protocol fees
        vm.prank(uniswapV2FeeToSetter);
        uniswapV2Factory.setFeeTo(uniswapV2FeeToSetter);

        (uint112 r0, uint112 r1,) = uniswapBalancedPair.getReserves();
        // generate small trading activity to accrue fees
        uint256 swapAmountA = (uint256(r0) * 100) / 10000; // 1%
        deal(address(uniswapBalancedTokenA), address(this), swapAmountA, true);
        uniswapBalancedTokenA.approve(address(uniswapV2Router), swapAmountA);
        address[] memory p = new address[](2);
        p[0] = address(uniswapBalancedTokenA);
        p[1] = address(uniswapBalancedTokenB);
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(swapAmountA, 0, p, address(this), block.timestamp + 300);
        uint256 receivedB = uniswapBalancedTokenB.balanceOf(address(this));
        uniswapBalancedTokenB.approve(address(uniswapV2Router), receivedB);
        p[0] = address(uniswapBalancedTokenB);
        p[1] = address(uniswapBalancedTokenA);
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(receivedB, 0, p, address(this), block.timestamp + 300);

        // refresh reserves and totals
        (r0, r1,) = uniswapBalancedPair.getReserves();
        uint256 lpTotalSupply = uniswapBalancedPair.totalSupply();
        uint256 kLast = uniswapBalancedPair.kLast();

        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(address(uniswapBalancedTokenA), uniswapBalancedPair.token0(), r0, r1);

        uint256 amountIn = 1000e18;
        uint256 feePercent = 300;
        uint256 ownerFeeShare = 16666;

        uint256 expectedLPTokens = ConstProdUtils._quoteSwapDepositWithFee(
            amountIn,
            lpTotalSupply,
            reserveA,
            reserveB,
            feePercent,
            kLast,
            ownerFeeShare,
            true
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

        assertEq(actualLPTokens, expectedLPTokens, "Actual LP tokens should equal expected LP tokens exactly (balanced fees enabled A->B)");
    }

    function test_quoteSwapDepositWithFee_Uniswap_balancedPool_swapsTokenB_feesEnabled() public {
        _initializeUniswapBalancedPools();

        // enable protocol fees
        vm.prank(uniswapV2FeeToSetter);
        uniswapV2Factory.setFeeTo(uniswapV2FeeToSetter);

        (uint112 r0, uint112 r1,) = uniswapBalancedPair.getReserves();
        // generate small trading activity to accrue fees
        uint256 swapAmountB = (uint256(r1) * 100) / 10000; // 1%
        deal(address(uniswapBalancedTokenB), address(this), swapAmountB, true);
        uniswapBalancedTokenB.approve(address(uniswapV2Router), swapAmountB);
        address[] memory p = new address[](2);
        p[0] = address(uniswapBalancedTokenB);
        p[1] = address(uniswapBalancedTokenA);
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(swapAmountB, 0, p, address(this), block.timestamp + 300);
        uint256 receivedA = uniswapBalancedTokenA.balanceOf(address(this));
        uniswapBalancedTokenA.approve(address(uniswapV2Router), receivedA);
        p[0] = address(uniswapBalancedTokenA);
        p[1] = address(uniswapBalancedTokenB);
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(receivedA, 0, p, address(this), block.timestamp + 300);

        // refresh reserves and totals
        (r0, r1,) = uniswapBalancedPair.getReserves();
        uint256 lpTotalSupply = uniswapBalancedPair.totalSupply();
        uint256 kLast = uniswapBalancedPair.kLast();

        (uint256 reserveIn, uint256 reserveOut) = ConstProdUtils._sortReserves(address(uniswapBalancedTokenB), uniswapBalancedPair.token0(), r0, r1);

        uint256 amountIn = 1000e18;
        uint256 feePercent = 300;
        uint256 ownerFeeShare = 16666;

        uint256 expectedLPTokens = ConstProdUtils._quoteSwapDepositWithFee(
            amountIn,
            lpTotalSupply,
            reserveIn,
            reserveOut,
            feePercent,
            kLast,
            ownerFeeShare,
            true
        );

        uint256 swapAmount = ConstProdUtils._swapDepositSaleAmt(amountIn, reserveIn, feePercent);

        uniswapBalancedTokenB.mint(address(this), amountIn);
        uniswapBalancedTokenB.approve(address(uniswapV2Router), amountIn);

        address[] memory path = new address[](2);
        path[0] = address(uniswapBalancedTokenB);
        path[1] = address(uniswapBalancedTokenA);

        uint256 tokenABeforeSwap = uniswapBalancedTokenA.balanceOf(address(this));
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(swapAmount, 0, path, address(this), block.timestamp + 300);
        uint256 tokenAReceived = uniswapBalancedTokenA.balanceOf(address(this)) - tokenABeforeSwap;

        uint256 remainingTokenB = amountIn - swapAmount;
        uniswapBalancedTokenB.approve(address(uniswapV2Router), remainingTokenB);
        uniswapBalancedTokenA.approve(address(uniswapV2Router), tokenAReceived);

        (,, uint256 actualLPTokens) = uniswapV2Router.addLiquidity(address(uniswapBalancedTokenA), address(uniswapBalancedTokenB), tokenAReceived, remainingTokenB, 1, 1, address(this), block.timestamp + 300);

        assertEq(actualLPTokens, expectedLPTokens, "Actual LP tokens should equal expected LP tokens exactly (balanced fees enabled B->A)");
    }

    function test_quoteSwapDepositWithFee_Uniswap_unbalancedPool_swapsTokenA_feesEnabled() public {
        _initializeUniswapUnbalancedPools();

        // enable protocol fees
        vm.prank(uniswapV2FeeToSetter);
        uniswapV2Factory.setFeeTo(uniswapV2FeeToSetter);

        (uint112 r0, uint112 r1,) = uniswapUnbalancedPair.getReserves();
        // generate small trading activity to accrue fees
        uint256 swapAmountA = (uint256(r0) * 100) / 10000; // 1%
        deal(address(uniswapUnbalancedTokenA), address(this), swapAmountA, true);
        uniswapUnbalancedTokenA.approve(address(uniswapV2Router), swapAmountA);
        address[] memory p = new address[](2);
        p[0] = address(uniswapUnbalancedTokenA);
        p[1] = address(uniswapUnbalancedTokenB);
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(swapAmountA, 0, p, address(this), block.timestamp + 300);
        uint256 receivedB = uniswapUnbalancedTokenB.balanceOf(address(this));
        uniswapUnbalancedTokenB.approve(address(uniswapV2Router), receivedB);
        p[0] = address(uniswapUnbalancedTokenB);
        p[1] = address(uniswapUnbalancedTokenA);
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(receivedB, 0, p, address(this), block.timestamp + 300);

        // refresh reserves and totals
        (r0, r1,) = uniswapUnbalancedPair.getReserves();
        uint256 lpTotalSupply = uniswapUnbalancedPair.totalSupply();
        uint256 kLast = uniswapUnbalancedPair.kLast();

        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(address(uniswapUnbalancedTokenA), uniswapUnbalancedPair.token0(), r0, r1);

        uint256 amountIn = 1000e18;
        uint256 feePercent = 300;
        uint256 ownerFeeShare = 16666;

        uint256 expectedLPTokens = ConstProdUtils._quoteSwapDepositWithFee(
            amountIn,
            lpTotalSupply,
            reserveA,
            reserveB,
            feePercent,
            kLast,
            ownerFeeShare,
            true
        );

        uint256 swapAmount = ConstProdUtils._swapDepositSaleAmt(amountIn, reserveA, feePercent);

        uniswapUnbalancedTokenA.mint(address(this), amountIn);
        uniswapUnbalancedTokenA.approve(address(uniswapV2Router), amountIn);

        address[] memory path = new address[](2);
        path[0] = address(uniswapUnbalancedTokenA);
        path[1] = address(uniswapUnbalancedTokenB);

        uint256 tokenBBeforeSwap = uniswapUnbalancedTokenB.balanceOf(address(this));
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(swapAmount, 0, path, address(this), block.timestamp + 300);
        uint256 tokenBReceived = uniswapUnbalancedTokenB.balanceOf(address(this)) - tokenBBeforeSwap;

        uint256 remainingTokenA = amountIn - swapAmount;
        uniswapUnbalancedTokenA.approve(address(uniswapV2Router), remainingTokenA);
        uniswapUnbalancedTokenB.approve(address(uniswapV2Router), tokenBReceived);

        (,, uint256 actualLPTokens) = uniswapV2Router.addLiquidity(address(uniswapUnbalancedTokenA), address(uniswapUnbalancedTokenB), remainingTokenA, tokenBReceived, 1, 1, address(this), block.timestamp + 300);

        assertEq(actualLPTokens, expectedLPTokens, "Actual LP tokens should equal expected LP tokens exactly (unbalanced fees enabled A->B)");
    }

    function test_quoteSwapDepositWithFee_Uniswap_unbalancedPool_swapsTokenB_feesEnabled() public {
        _initializeUniswapUnbalancedPools();

        // enable protocol fees
        vm.prank(uniswapV2FeeToSetter);
        uniswapV2Factory.setFeeTo(uniswapV2FeeToSetter);

        (uint112 r0, uint112 r1,) = uniswapUnbalancedPair.getReserves();
        // generate small trading activity to accrue fees
        uint256 swapAmountB = (uint256(r1) * 100) / 10000; // 1%
        deal(address(uniswapUnbalancedTokenB), address(this), swapAmountB, true);
        uniswapUnbalancedTokenB.approve(address(uniswapV2Router), swapAmountB);
        address[] memory p = new address[](2);
        p[0] = address(uniswapUnbalancedTokenB);
        p[1] = address(uniswapUnbalancedTokenA);
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(swapAmountB, 0, p, address(this), block.timestamp + 300);
        uint256 receivedA = uniswapUnbalancedTokenA.balanceOf(address(this));
        uniswapUnbalancedTokenA.approve(address(uniswapV2Router), receivedA);
        p[0] = address(uniswapUnbalancedTokenA);
        p[1] = address(uniswapUnbalancedTokenB);
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(receivedA, 0, p, address(this), block.timestamp + 300);

        // refresh reserves and totals
        (r0, r1,) = uniswapUnbalancedPair.getReserves();
        uint256 lpTotalSupply = uniswapUnbalancedPair.totalSupply();
        uint256 kLast = uniswapUnbalancedPair.kLast();

        (uint256 reserveIn, uint256 reserveOut) = ConstProdUtils._sortReserves(address(uniswapUnbalancedTokenB), uniswapUnbalancedPair.token0(), r0, r1);

        uint256 amountIn = 1000e18;
        uint256 feePercent = 300;
        uint256 ownerFeeShare = 16666;

        uint256 expectedLPTokens = ConstProdUtils._quoteSwapDepositWithFee(
            amountIn,
            lpTotalSupply,
            reserveIn,
            reserveOut,
            feePercent,
            kLast,
            ownerFeeShare,
            true
        );

        uint256 swapAmount = ConstProdUtils._swapDepositSaleAmt(amountIn, reserveIn, feePercent);

        uniswapUnbalancedTokenB.mint(address(this), amountIn);
        uniswapUnbalancedTokenB.approve(address(uniswapV2Router), amountIn);

        address[] memory path = new address[](2);
        path[0] = address(uniswapUnbalancedTokenB);
        path[1] = address(uniswapUnbalancedTokenA);

        uint256 tokenABeforeSwap = uniswapUnbalancedTokenA.balanceOf(address(this));
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(swapAmount, 0, path, address(this), block.timestamp + 300);
        uint256 tokenAReceived = uniswapUnbalancedTokenA.balanceOf(address(this)) - tokenABeforeSwap;

        uint256 remainingTokenB = amountIn - swapAmount;
        uniswapUnbalancedTokenB.approve(address(uniswapV2Router), remainingTokenB);
        uniswapUnbalancedTokenA.approve(address(uniswapV2Router), tokenAReceived);

        (,, uint256 actualLPTokens) = uniswapV2Router.addLiquidity(address(uniswapUnbalancedTokenA), address(uniswapUnbalancedTokenB), tokenAReceived, remainingTokenB, 1, 1, address(this), block.timestamp + 300);

        assertEq(actualLPTokens, expectedLPTokens, "Actual LP tokens should equal expected LP tokens exactly (unbalanced fees enabled B->A)");
    }

}
