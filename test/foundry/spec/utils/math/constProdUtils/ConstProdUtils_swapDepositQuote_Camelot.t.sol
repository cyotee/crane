// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {TestBase_ConstProdUtils_Camelot} from "./TestBase_ConstProdUtils_Camelot.sol";
import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";

contract ConstProdUtils_swapDepositQuote_Camelot is TestBase_ConstProdUtils_Camelot {
    function setUp() public override {
        super.setUp();
    }

    function test_quoteSwapDepositWithFee_Camelot_balancedPool_basic() public {
        _initializeCamelotBalancedPools();
        (uint112 reserve0, uint112 reserve1, uint16 fee0, uint16 fee1) = camelotBalancedPair.getReserves();

        (uint256 reserveA, uint256 feeA, uint256 reserveB, uint256 feeB) = ConstProdUtils._sortReserves(
            address(camelotBalancedTokenA), camelotBalancedPair.token0(), reserve0, uint256(fee0), reserve1, uint256(fee1)
        );

        uint256 lpTotalSupply = camelotBalancedPair.totalSupply();
        uint256 amountIn = 1e18;

        uint256 expectedLp = ConstProdUtils._quoteSwapDepositWithFee(
            amountIn, lpTotalSupply, reserveA, reserveB, feeA, 0, 0, false
        );

        assertGt(expectedLp, 0, "Expected LP quote should be greater than 0");
    }

    function test_swapDepositQuote_Camelot_balancedPool() public {
        _initializeCamelotBalancedPools();

        (uint112 reserve0, uint112 reserve1, uint16 token0Fee, uint16 token1Fee) = camelotBalancedPair.getReserves();
        uint256 amountIn = 1000e18;
        uint256 lpTotalSupply = camelotBalancedPair.totalSupply();

        (uint256 reserveA, uint256 tokenAFee, uint256 reserveB, uint256 tokenBFee)
            = ConstProdUtils._sortReserves(
                address(camelotBalancedTokenA),
                camelotBalancedPair.token0(),
                reserve0,
                token0Fee,
                reserve1,
                token1Fee
            );

        uint256 feePercent = tokenAFee;

        (uint256 ownerFeeShare, ) = camelotV2Factory.feeInfo();
        uint256 kLast = camelotBalancedPair.kLast();
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

        camelotBalancedTokenA.mint(address(this), amountIn);
        camelotBalancedTokenA.approve(address(camelotV2Router), amountIn);

        address[] memory path = new address[](2);
        path[0] = address(camelotBalancedTokenA);
        path[1] = address(camelotBalancedTokenB);

        uint256 tokenBBeforeSwap = camelotBalancedTokenB.balanceOf(address(this));
        camelotV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            swapAmount,
            0,
            path,
            address(this),
            address(0),
            block.timestamp + 300
        );
        uint256 tokenBReceived = camelotBalancedTokenB.balanceOf(address(this)) - tokenBBeforeSwap;

        uint256 remainingTokenA = amountIn - swapAmount;
        camelotBalancedTokenA.approve(address(camelotV2Router), remainingTokenA);
        camelotBalancedTokenB.approve(address(camelotV2Router), tokenBReceived);

        (,, uint256 actualLPTokens) = camelotV2Router.addLiquidity(
            address(camelotBalancedTokenA),
            address(camelotBalancedTokenB),
            remainingTokenA,
            tokenBReceived,
            1,
            1,
            address(this),
            block.timestamp + 300
        );

        assertEq(actualLPTokens, expectedLPTokens, "Actual LP tokens should equal expected LP tokens exactly");
    }

}
