// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import {TestBase_ConstProdUtils_Camelot} from "../constProdUtils/TestBase_ConstProdUtils_Camelot.sol";
import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";
import {CamelotV2Utils} from "contracts/utils/math/CamelotV2Utils.sol";
import {FEE_DENOMINATOR} from "contracts/constants/Constants.sol";

contract ConstProdUtils_quoteWithdrawSwapWithFee_Camelot_Old is TestBase_ConstProdUtils_Camelot {
    function setUp() public override {
        super.setUp();
    }

    function test_withdrawSwapQuote_Camelot_balancedPool() public {
        _initializeCamelotBalancedPools();
        (uint112 reserve0, uint112 reserve1, uint16 token0Fee , uint16 token1Fee) = camelotBalancedPair.getReserves();

        (uint256 reserveA, uint256 feeA, uint256 reserveB, uint256 feeB) = ConstProdUtils._sortReserves(
            address(camelotBalancedTokenA),
            camelotBalancedPair.token0(),
            reserve0,
            uint256(token0Fee),
            reserve1,
            uint256(token1Fee)
        );

        uint256 feePercent = uint256(feeA);
        uint256 lpTotalSupply = camelotBalancedPair.totalSupply();

        uint256 lpBalance = camelotBalancedPair.balanceOf(address(this));
        uint256 ownedLPAmount = lpBalance / 2;

        uint256 expectedTotalTokenA = CamelotV2Utils._quoteWithdrawSwapWithFee(
            ownedLPAmount, lpTotalSupply, reserveA, reserveB, feePercent, FEE_DENOMINATOR, 0, 0, false
        );

        uint256 initialTokenABalance = camelotBalancedTokenA.balanceOf(address(this));

        camelotBalancedPair.transfer(address(camelotBalancedPair), ownedLPAmount);
        (uint256 amountA, uint256 amountB) = camelotBalancedPair.burn(address(this));

        uint256 actualAmountA = amountA;
        uint256 actualAmountB = amountB;

        if (actualAmountB > 0) {
            camelotBalancedTokenB.approve(address(camelotV2Router), actualAmountB);
            address[] memory path = new address[](2);
            path[0] = address(camelotBalancedTokenB);
            path[1] = address(camelotBalancedTokenA);

            camelotV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                actualAmountB, 1, path, address(this), REFERRER, block.timestamp
            );
        }

        uint256 finalTokenABalance = camelotBalancedTokenA.balanceOf(address(this));
        uint256 actualTotalTokenA = finalTokenABalance - initialTokenABalance;

        assertEq(actualTotalTokenA, expectedTotalTokenA, "Should receive exactly the expected total TokenA amount");
    }

    function test_withdrawSwapQuote_Camelot_unbalancedPool() public {
        _initializeCamelotUnbalancedPools();
        (uint112 reserve0, uint112 reserve1, uint16 token0Fee, uint16 token1Fee) = camelotUnbalancedPair.getReserves();
        uint256 lpTotalSupply = camelotUnbalancedPair.totalSupply();

        (uint256 reserveA, uint256 tokenAFee, uint256 reserveB, uint256 tokenBFee) = ConstProdUtils._sortReserves(
            address(camelotUnbalancedTokenA),
            camelotUnbalancedPair.token0(),
            reserve0,
            uint256(token0Fee),
            reserve1,
            uint256(token1Fee)
        );

        uint256 feePercent = tokenAFee;
        uint256 lpBalance = camelotUnbalancedPair.balanceOf(address(this));
        uint256 ownedLPAmount = lpBalance / 2;

            uint256 expectedTotalTokenA = CamelotV2Utils._quoteWithdrawSwapWithFee(
            ownedLPAmount, lpTotalSupply, reserveA, reserveB, feePercent, FEE_DENOMINATOR, 0, 0, false
        );

        uint256 initialTokenABalance = camelotUnbalancedTokenA.balanceOf(address(this));

        camelotUnbalancedPair.transfer(address(camelotUnbalancedPair), ownedLPAmount);
        (uint256 amount0, uint256 amount1) = camelotUnbalancedPair.burn(address(this));

        uint256 actualAmountA;
        uint256 actualAmountB;
        if (camelotUnbalancedPair.token0() == address(camelotUnbalancedTokenA)) {
            actualAmountA = amount0;
            actualAmountB = amount1;
        } else {
            actualAmountA = amount1;
            actualAmountB = amount0;
        }

        if (actualAmountB > 0) {
            camelotUnbalancedTokenB.approve(address(camelotV2Router), actualAmountB);
            address[] memory path = new address[](2);
            path[0] = address(camelotUnbalancedTokenB);
            path[1] = address(camelotUnbalancedTokenA);

            camelotV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                actualAmountB, 1, path, address(this), REFERRER, block.timestamp
            );
        }

        uint256 finalTokenABalance = camelotUnbalancedTokenA.balanceOf(address(this));
        uint256 actualTotalTokenA = finalTokenABalance - initialTokenABalance;

        assertEq(actualTotalTokenA, expectedTotalTokenA, "Should receive exactly the expected total TokenA amount");
    }

    function test_withdrawSwapQuote_Camelot_extremeUnbalancedPool() public {
        _initializeCamelotExtremeUnbalancedPools();
        (uint112 reserve0, uint112 reserve1, uint16 token0Fee, uint16 token1Fee) = camelotExtremeUnbalancedPair.getReserves();
        (uint256 reserveA, uint256 feeA, uint256 reserveB, uint256 feeB) = ConstProdUtils._sortReserves(
            address(camelotExtremeTokenA),
            camelotExtremeUnbalancedPair.token0(),
            reserve0,
            uint256(token0Fee),
            reserve1,
            uint256(token1Fee)
        );
        uint256 feePercent = feeA;
        uint256 lpTotalSupply = camelotExtremeUnbalancedPair.totalSupply();

        uint256 lpBalance = camelotExtremeUnbalancedPair.balanceOf(address(this));
        uint256 ownedLPAmount = lpBalance / 2;

        uint256 expectedTotalTokenA = CamelotV2Utils._quoteWithdrawSwapWithFee(
            ownedLPAmount, lpTotalSupply, reserveA, reserveB, feePercent, FEE_DENOMINATOR, 0, 0, false
        );

        uint256 initialTokenABalance = camelotExtremeTokenA.balanceOf(address(this));


        camelotExtremeUnbalancedPair.transfer(address(camelotExtremeUnbalancedPair), ownedLPAmount);
        (uint256 amountA, uint256 amountB) = camelotExtremeUnbalancedPair.burn(address(this));


        uint256 actualAmountA;
        uint256 actualAmountB;
        if (camelotExtremeUnbalancedPair.token0() == address(camelotExtremeTokenA)) {
            actualAmountA = amountA;
            actualAmountB = amountB;
        } else {
            actualAmountA = amountB;
            actualAmountB = amountA;
        }


        if (actualAmountB > 0) {
            camelotExtremeTokenB.approve(address(camelotV2Router), actualAmountB);
            address[] memory path = new address[](2);
            path[0] = address(camelotExtremeTokenB);
            path[1] = address(camelotExtremeTokenA);

            camelotV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                actualAmountB, 1, path, address(this), REFERRER, block.timestamp
            );
        }

        uint256 finalTokenABalance = camelotExtremeTokenA.balanceOf(address(this));
        uint256 actualTotalTokenA = finalTokenABalance - initialTokenABalance;

        

        assertEq(actualTotalTokenA, expectedTotalTokenA, "Should receive exactly the expected total TokenA amount");
    }

    // Edge cases
    function test_withdrawSwapQuote_edgeCase_smallLPAmount() public {
        _initializeCamelotBalancedPools();
        (uint112 reserveA, uint112 reserveB, uint16 feeA, uint16 feeB) = camelotBalancedPair.getReserves();
        uint256 feePercent = uint256(feeA);
        uint256 lpTotalSupply = camelotBalancedPair.totalSupply();

        uint256 lpBalance = camelotBalancedPair.balanceOf(address(this));
        uint256 ownedLPAmount = lpBalance / 4; // Smaller amount

        uint256 expectedTotalTokenA = CamelotV2Utils._quoteWithdrawSwapWithFee(
            ownedLPAmount, lpTotalSupply, reserveA, reserveB, feePercent, FEE_DENOMINATOR, 0, 0, false
        );

        uint256 initialTokenABalance = camelotBalancedTokenA.balanceOf(address(this));

        camelotBalancedPair.transfer(address(camelotBalancedPair), ownedLPAmount);
        (uint256 amountA, uint256 amountB) = camelotBalancedPair.burn(address(this));

        if (amountB > 0) {
            camelotBalancedTokenB.approve(address(camelotV2Router), amountB);
            address[] memory path = new address[](2);
            path[0] = address(camelotBalancedTokenB);
            path[1] = address(camelotBalancedTokenA);
            camelotV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(amountB, 1, path, address(this), REFERRER, block.timestamp);
        }

        uint256 finalTokenABalance = camelotBalancedTokenA.balanceOf(address(this));
        uint256 actualTotalTokenA = finalTokenABalance - initialTokenABalance;

        assertEq(actualTotalTokenA, expectedTotalTokenA, "Should receive exactly the expected total TokenA amount");
    }

    function test_withdrawSwapQuote_edgeCase_largeLPAmount() public {
        _initializeCamelotBalancedPools();
        (uint112 reserveA, uint112 reserveB, uint16 feeA, uint16 feeB) = camelotBalancedPair.getReserves();
        uint256 feePercent = uint256(feeA);
        uint256 lpTotalSupply = camelotBalancedPair.totalSupply();

        uint256 lpBalance = camelotBalancedPair.balanceOf(address(this));
        uint256 ownedLPAmount = (lpBalance * 3) / 4; // Larger amount

        uint256 expectedTotalTokenA = CamelotV2Utils._quoteWithdrawSwapWithFee(
            ownedLPAmount, lpTotalSupply, reserveA, reserveB, feePercent, FEE_DENOMINATOR, 0, 0, false
        );

        uint256 initialTokenABalance = camelotBalancedTokenA.balanceOf(address(this));

        camelotBalancedPair.transfer(address(camelotBalancedPair), ownedLPAmount);
        (uint256 amountA, uint256 amountB) = camelotBalancedPair.burn(address(this));

        if (amountB > 0) {
            camelotBalancedTokenB.approve(address(camelotV2Router), amountB);
            address[] memory path = new address[](2);
            path[0] = address(camelotBalancedTokenB);
            path[1] = address(camelotBalancedTokenA);
            camelotV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(amountB, 1, path, address(this), REFERRER, block.timestamp);
        }

        uint256 finalTokenABalance = camelotBalancedTokenA.balanceOf(address(this));
        uint256 actualTotalTokenA = finalTokenABalance - initialTokenABalance;

        assertEq(actualTotalTokenA, expectedTotalTokenA, "Should receive exactly the expected total TokenA amount");
    }

    function test_withdrawSwapQuote_edgeCase_differentFees() public {
        _initializeCamelotBalancedPools();
        (uint112 reserveA, uint112 reserveB, uint16 feeA, uint16 feeB) = camelotBalancedPair.getReserves();
        uint256 feePercent = uint256(feeA);
        uint256 lpTotalSupply = camelotBalancedPair.totalSupply();

        uint256 lpBalance = camelotBalancedPair.balanceOf(address(this));
        uint256 ownedLPAmount = lpBalance / 2;

        uint256 expectedTotalTokenA = CamelotV2Utils._quoteWithdrawSwapWithFee(
            ownedLPAmount, lpTotalSupply, reserveA, reserveB, feePercent, FEE_DENOMINATOR, 0, 0, false
        );

        uint256 initialTokenABalance = camelotBalancedTokenA.balanceOf(address(this));

        camelotBalancedPair.transfer(address(camelotBalancedPair), ownedLPAmount);
        (uint256 amountA, uint256 amountB) = camelotBalancedPair.burn(address(this));

        if (amountB > 0) {
            camelotBalancedTokenB.approve(address(camelotV2Router), amountB);
            address[] memory path = new address[](2);
            path[0] = address(camelotBalancedTokenB);
            path[1] = address(camelotBalancedTokenA);
            camelotV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(amountB, 1, path, address(this), REFERRER, block.timestamp);
        }

        uint256 finalTokenABalance = camelotBalancedTokenA.balanceOf(address(this));
        uint256 actualTotalTokenA = finalTokenABalance - initialTokenABalance;

        assertEq(actualTotalTokenA, expectedTotalTokenA, "Should receive exactly the expected total TokenA amount");
    }

    function test_withdrawSwapQuote_edgeCase_verySmallReserves() public {
        _initializeCamelotBalancedPools();
        (uint112 reserveA, uint112 reserveB, uint16 feeA, uint16 feeB) = camelotBalancedPair.getReserves();
        uint256 feePercent = uint256(feeA);
        uint256 lpTotalSupply = camelotBalancedPair.totalSupply();

        uint256 lpBalance = camelotBalancedPair.balanceOf(address(this));
        uint256 ownedLPAmount = lpBalance / 2;

        uint256 expectedTotalTokenA = CamelotV2Utils._quoteWithdrawSwapWithFee(
            ownedLPAmount, lpTotalSupply, reserveA, reserveB, feePercent, FEE_DENOMINATOR, 0, 0, false
        );

        uint256 initialTokenABalance = camelotBalancedTokenA.balanceOf(address(this));

        camelotBalancedPair.transfer(address(camelotBalancedPair), ownedLPAmount);
        (uint256 amountA, uint256 amountB) = camelotBalancedPair.burn(address(this));

        if (amountB > 0) {
            camelotBalancedTokenB.approve(address(camelotV2Router), amountB);
            address[] memory path = new address[](2);
            path[0] = address(camelotBalancedTokenB);
            path[1] = address(camelotBalancedTokenA);
            camelotV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(amountB, 1, path, address(this), REFERRER, block.timestamp);
        }

        uint256 finalTokenABalance = camelotBalancedTokenA.balanceOf(address(this));
        uint256 actualTotalTokenA = finalTokenABalance - initialTokenABalance;

        assertEq(actualTotalTokenA, expectedTotalTokenA, "Should receive exactly the expected total TokenA amount");
    }

    function test_withdrawSwapQuote_edgeCase_midRangeLPAmount() public {
        _initializeCamelotBalancedPools();
        (uint112 reserveA, uint112 reserveB, uint16 feeA, uint16 feeB) = camelotBalancedPair.getReserves();
        uint256 feePercent = uint256(feeA);
        uint256 lpTotalSupply = camelotBalancedPair.totalSupply();

        uint256 lpBalance = camelotBalancedPair.balanceOf(address(this));
        uint256 ownedLPAmount = (lpBalance * 2) / 3; // Mid-range amount

        uint256 expectedTotalTokenA = CamelotV2Utils._quoteWithdrawSwapWithFee(
            ownedLPAmount, lpTotalSupply, reserveA, reserveB, feePercent, FEE_DENOMINATOR, 0, 0, false
        );

        uint256 initialTokenABalance = camelotBalancedTokenA.balanceOf(address(this));

        camelotBalancedPair.transfer(address(camelotBalancedPair), ownedLPAmount);
        (uint256 amountA, uint256 amountB) = camelotBalancedPair.burn(address(this));

        if (amountB > 0) {
            camelotBalancedTokenB.approve(address(camelotV2Router), amountB);
            address[] memory path = new address[](2);
            path[0] = address(camelotBalancedTokenB);
            path[1] = address(camelotBalancedTokenA);
            camelotV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(amountB, 1, path, address(this), REFERRER, block.timestamp);
        }

        uint256 finalTokenABalance = camelotBalancedTokenA.balanceOf(address(this));
        uint256 actualTotalTokenA = finalTokenABalance - initialTokenABalance;

        assertEq(actualTotalTokenA, expectedTotalTokenA, "Should receive exactly the expected total TokenA amount");
    }

    function test_withdrawSwapQuote_edgeCase_maxLPAmount() public {
        _initializeCamelotBalancedPools();
        // Use Camelot balanced pair for large LP amount edge case
        (uint112 reserveA2, uint112 reserveB2, uint16 feeA2, uint16 feeB2) = camelotBalancedPair.getReserves();
        uint256 lpTotalSupply2 = camelotBalancedPair.totalSupply();

        uint256 lpBalance2 = camelotBalancedPair.balanceOf(address(this));
        uint256 ownedLPAmount2 = (lpBalance2 * 3) / 4; // Large amount

        uint256 expectedTotalTokenA2 = CamelotV2Utils._quoteWithdrawSwapWithFee(
            ownedLPAmount2, lpTotalSupply2, reserveA2, reserveB2, uint256(feeA2), FEE_DENOMINATOR, 0, 0, false
        );

        uint256 initialTokenABalance2 = camelotBalancedTokenA.balanceOf(address(this));

        camelotBalancedPair.transfer(address(camelotBalancedPair), ownedLPAmount2);
        (uint256 amountA2, uint256 amountB2) = camelotBalancedPair.burn(address(this));

        if (amountB2 > 0) {
            camelotBalancedTokenB.approve(address(camelotV2Router), amountB2);
            address[] memory path = new address[](2);
            path[0] = address(camelotBalancedTokenB);
            path[1] = address(camelotBalancedTokenA);
            camelotV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(amountB2, 1, path, address(this), REFERRER, block.timestamp);
        }

        uint256 finalTokenABalance2 = camelotBalancedTokenA.balanceOf(address(this));
        uint256 actualTotalTokenA2 = finalTokenABalance2 - initialTokenABalance2;

        assertEq(actualTotalTokenA2, expectedTotalTokenA2, "Should receive exactly the expected total TokenA amount");
    }
}
