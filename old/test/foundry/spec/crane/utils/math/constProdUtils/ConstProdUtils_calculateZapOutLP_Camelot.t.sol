// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {TestBase_ConstProdUtils_Camelot} from "@crane/test/foundry/spec/utils/math/constProdUtils/TestBase_ConstProdUtils_Camelot.sol";
import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";
import {ERC20PermitMintableStub} from "contracts/tokens/ERC20/ERC20PermitMintableStub.sol";

contract ConstProdUtils_calculateZapOutLP_Camelot_Test is TestBase_ConstProdUtils_Camelot {
    function setUp() public override {
        TestBase_ConstProdUtils_Camelot.setUp();
    }

    function test_calculateZapOutLP_Camelot_balancedPool() public {
        _initializeCamelotBalancedPools();

        (uint112 reserve0, uint112 reserve1, uint16 token0Fee, uint16 token1Fee) = camelotBalancedPair.getReserves();
        (uint256 reserveA, uint256 feePercent, uint256 reserveB, uint256 tokenBFee) = ConstProdUtils._sortReserves(
            address(camelotBalancedTokenA), camelotBalancedPair.token0(), reserve0, uint256(token0Fee), reserve1, uint256(token1Fee)
        );
        uint256 lpTotalSupply = camelotBalancedPair.totalSupply();

        uint256 desiredOut = reserveA / 10;

        uint256 expectedLpNeeded = ConstProdUtils._quoteZapOutToTargetWithFee(
            desiredOut,
            lpTotalSupply,
            reserveA,
            reserveB,
            feePercent,
            100000,
            0,
            0,
            false
        );

        uint256 initialTokenABalance = camelotBalancedTokenA.balanceOf(address(this));

        camelotBalancedPair.transfer(address(camelotBalancedPair), expectedLpNeeded);
        (uint256 amt0, uint256 amt1) = camelotBalancedPair.burn(address(this));

        uint256 amountA = camelotBalancedPair.token0() == address(camelotBalancedTokenA) ? amt0 : amt1;
        uint256 amountB = camelotBalancedPair.token0() == address(camelotBalancedTokenA) ? amt1 : amt0;

        if (amountB > 0) {
            camelotBalancedTokenB.approve(address(camelotV2Router), amountB);
            address[] memory path = new address[](2);
            path[0] = address(camelotBalancedTokenB);
            path[1] = address(camelotBalancedTokenA);

            camelotV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(amountB, 1, path, address(this), address(0), block.timestamp);
        }

        uint256 finalTokenABalance = camelotBalancedTokenA.balanceOf(address(this));
        uint256 actualTokenAReceived = finalTokenABalance - initialTokenABalance;

        uint256 diff = actualTokenAReceived > desiredOut ? actualTokenAReceived - desiredOut : desiredOut - actualTokenAReceived;
        assertTrue(diff <= 10, "Should receive approximately the desired TokenA amount within tolerance");
    }

    function test_calculateZapOutLP_Camelot_unbalancedPool() public {
        _initializeCamelotUnbalancedPools();

        (uint112 reserve0, uint112 reserve1, uint16 token0Fee, uint16 token1Fee) = camelotUnbalancedPair.getReserves();
        (uint256 reserveA, uint256 feePercent, uint256 reserveB, uint256 tokenBFee) = ConstProdUtils._sortReserves(
            address(camelotUnbalancedTokenA), camelotUnbalancedPair.token0(), reserve0, uint256(token0Fee), reserve1, uint256(token1Fee)
        );
        uint256 lpTotalSupply = camelotUnbalancedPair.totalSupply();

        uint256 desiredOut = reserveA / 8;

        uint256 expectedLpNeeded = ConstProdUtils._quoteZapOutToTargetWithFee(
            desiredOut,
            lpTotalSupply,
            reserveA,
            reserveB,
            feePercent,
            100000,
            0,
            0,
            false
        );

        uint256 initialTokenABalance = camelotUnbalancedTokenA.balanceOf(address(this));

        camelotUnbalancedPair.transfer(address(camelotUnbalancedPair), expectedLpNeeded);
        (uint256 amt0, uint256 amt1) = camelotUnbalancedPair.burn(address(this));

        uint256 amountA = camelotUnbalancedPair.token0() == address(camelotUnbalancedTokenA) ? amt0 : amt1;
        uint256 amountB = camelotUnbalancedPair.token0() == address(camelotUnbalancedTokenA) ? amt1 : amt0;

        if (amountB > 0) {
            camelotUnbalancedTokenB.approve(address(camelotV2Router), amountB);
            address[] memory path = new address[](2);
            path[0] = address(camelotUnbalancedTokenB);
            path[1] = address(camelotUnbalancedTokenA);

            camelotV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(amountB, 1, path, address(this), address(0), block.timestamp);
        }

        uint256 finalTokenABalance = camelotUnbalancedTokenA.balanceOf(address(this));
        uint256 actualTokenAReceived = finalTokenABalance - initialTokenABalance;

        uint256 diff = actualTokenAReceived > desiredOut ? actualTokenAReceived - desiredOut : desiredOut - actualTokenAReceived;
        assertTrue(diff <= 10, "Should receive approximately the desired TokenA amount within tolerance");
    }

    function test_calculateZapOutLP_Camelot_extremeUnbalancedPool() public {
        _initializeCamelotExtremeUnbalancedPools();

        (uint112 reserve0, uint112 reserve1, uint16 token0Fee, uint16 token1Fee) = camelotExtremeUnbalancedPair.getReserves();
        (uint256 reserveA, uint256 feePercent, uint256 reserveB, uint256 tokenBFee) = ConstProdUtils._sortReserves(
            address(camelotExtremeTokenA), camelotExtremeUnbalancedPair.token0(), reserve0, uint256(token0Fee), reserve1, uint256(token1Fee)
        );
        uint256 lpTotalSupply = camelotExtremeUnbalancedPair.totalSupply();

        uint256 desiredOut = reserveA / 20;

        uint256 expectedLpNeeded = ConstProdUtils._quoteZapOutToTargetWithFee(
            desiredOut,
            lpTotalSupply,
            reserveA,
            reserveB,
            feePercent,
            100000,
            0,
            0,
            false
        );

        uint256 initialTokenABalance = camelotExtremeTokenA.balanceOf(address(this));

        camelotExtremeUnbalancedPair.transfer(address(camelotExtremeUnbalancedPair), expectedLpNeeded);
        (uint256 amt0, uint256 amt1) = camelotExtremeUnbalancedPair.burn(address(this));

        uint256 amountA = camelotExtremeUnbalancedPair.token0() == address(camelotExtremeTokenA) ? amt0 : amt1;
        uint256 amountB = camelotExtremeUnbalancedPair.token0() == address(camelotExtremeTokenA) ? amt1 : amt0;

        if (amountB > 0) {
            camelotExtremeTokenB.approve(address(camelotV2Router), amountB);
            address[] memory path = new address[](2);
            path[0] = address(camelotExtremeTokenB);
            path[1] = address(camelotExtremeTokenA);

            camelotV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(amountB, 1, path, address(this), address(0), block.timestamp);
        }

        uint256 finalTokenABalance = camelotExtremeTokenA.balanceOf(address(this));
        uint256 actualTokenAReceived = finalTokenABalance - initialTokenABalance;

        uint256 diff = actualTokenAReceived > desiredOut ? actualTokenAReceived - desiredOut : desiredOut - actualTokenAReceived;
        assertTrue(diff <= 10, "Should receive approximately the desired TokenA amount within tolerance");
    }
}
