// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {betterconsole as console} from "contracts/utils/vm/foundry/tools/betterconsole.sol";
import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";
import {CamelotV2Service} from "@crane/contracts/protocols/dexes/camelot/v2/services/CamelotV2Service.sol";
import {TestBase_ConstProdUtils_Camelot} from "@crane/test/foundry/spec/utils/math/constProdUtils/TestBase_ConstProdUtils_Camelot.sol";

contract ConstProdUtils_withdrawQuote_Camelot_Test is TestBase_ConstProdUtils_Camelot {
    function setUp() public override {
        TestBase_ConstProdUtils_Camelot.setUp();
        _initializeCamelotBalancedPools();
        _initializeCamelotUnbalancedPools();
        _initializeCamelotExtremeUnbalancedPools();
    }

    function test_withdrawQuote_Camelot_balancedPool() public {
        (uint112 reserve0, uint112 reserve1,,) = camelotBalancedPair.getReserves();
        uint256 totalSupply = camelotBalancedPair.totalSupply();

        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
            address(camelotBalancedTokenA), camelotBalancedPair.token0(), reserve0, reserve1
        );

        uint256 lpBalance = camelotBalancedPair.balanceOf(address(this));
        uint256 lpTokensToWithdraw = lpBalance / 2;

        (uint256 expectedAmountA, uint256 expectedAmountB) =
            ConstProdUtils._withdrawQuote(lpTokensToWithdraw, totalSupply, reserveA, reserveB);

        uint256 initialBalanceA = camelotBalancedTokenA.balanceOf(address(this));
        uint256 initialBalanceB = camelotBalancedTokenB.balanceOf(address(this));

        (uint256 amount0, uint256 amount1) = CamelotV2Service._withdrawDirect(camelotBalancedPair, lpTokensToWithdraw);

        uint256 actualAmountA = address(camelotBalancedTokenA) == camelotBalancedPair.token0() ? amount0 : amount1;
        uint256 actualAmountB = address(camelotBalancedTokenA) == camelotBalancedPair.token0() ? amount1 : amount0;

        assertEq(actualAmountA, expectedAmountA, "TokenA amounts should match");
        assertEq(actualAmountB, expectedAmountB, "TokenB amounts should match");

        assertEq(
            camelotBalancedTokenA.balanceOf(address(this)) - initialBalanceA,
            actualAmountA,
            "TokenA balance change should match withdrawal"
        );
        assertEq(
            camelotBalancedTokenB.balanceOf(address(this)) - initialBalanceB,
            actualAmountB,
            "TokenB balance change should match withdrawal"
        );

        console.log("_withdrawQuote Camelot balanced pool test passed:");
    }

    function test_withdrawQuote_Camelot_unbalancedPool() public {
        (uint112 reserve0, uint112 reserve1,,) = camelotUnbalancedPair.getReserves();
        uint256 totalSupply = camelotUnbalancedPair.totalSupply();

        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
            address(camelotUnbalancedTokenA), camelotUnbalancedPair.token0(), reserve0, reserve1
        );

        uint256 lpBalance = camelotUnbalancedPair.balanceOf(address(this));
        uint256 lpTokensToWithdraw = lpBalance / 2;

        (uint256 expectedAmountA, uint256 expectedAmountB) =
            ConstProdUtils._withdrawQuote(lpTokensToWithdraw, totalSupply, reserveA, reserveB);

        uint256 initialBalanceA = camelotUnbalancedTokenA.balanceOf(address(this));
        uint256 initialBalanceB = camelotUnbalancedTokenB.balanceOf(address(this));

        (uint256 amount0, uint256 amount1) = CamelotV2Service._withdrawDirect(camelotUnbalancedPair, lpTokensToWithdraw);

        uint256 actualAmountA = address(camelotUnbalancedTokenA) == camelotUnbalancedPair.token0() ? amount0 : amount1;
        uint256 actualAmountB = address(camelotUnbalancedTokenA) == camelotUnbalancedPair.token0() ? amount1 : amount0;

        assertEq(actualAmountA, expectedAmountA, "TokenA amounts should match");
        assertEq(actualAmountB, expectedAmountB, "TokenB amounts should match");

        assertEq(
            camelotUnbalancedTokenA.balanceOf(address(this)) - initialBalanceA,
            actualAmountA,
            "TokenA balance change should match withdrawal"
        );
        assertEq(
            camelotUnbalancedTokenB.balanceOf(address(this)) - initialBalanceB,
            actualAmountB,
            "TokenB balance change should match withdrawal"
        );

        console.log("_withdrawQuote Camelot unbalanced pool test passed:");
    }

    function test_withdrawQuote_Camelot_extremeUnbalancedPool() public {
        (uint112 reserve0, uint112 reserve1,,) = camelotExtremeUnbalancedPair.getReserves();
        uint256 totalSupply = camelotExtremeUnbalancedPair.totalSupply();

        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
            address(camelotExtremeTokenA), camelotExtremeUnbalancedPair.token0(), reserve0, reserve1
        );

        uint256 lpBalance = camelotExtremeUnbalancedPair.balanceOf(address(this));
        uint256 lpTokensToWithdraw = lpBalance / 2;

        (uint256 expectedAmountA, uint256 expectedAmountB) =
            ConstProdUtils._withdrawQuote(lpTokensToWithdraw, totalSupply, reserveA, reserveB);

        uint256 initialBalanceA = camelotExtremeTokenA.balanceOf(address(this));
        uint256 initialBalanceB = camelotExtremeTokenB.balanceOf(address(this));

        (uint256 amount0, uint256 amount1) = CamelotV2Service._withdrawDirect(camelotExtremeUnbalancedPair, lpTokensToWithdraw);

        uint256 actualAmountA = address(camelotExtremeTokenA) == camelotExtremeUnbalancedPair.token0() ? amount0 : amount1;
        uint256 actualAmountB = address(camelotExtremeTokenA) == camelotExtremeUnbalancedPair.token0() ? amount1 : amount0;

        assertEq(actualAmountA, expectedAmountA, "TokenA amounts should match");
        assertEq(actualAmountB, expectedAmountB, "TokenB amounts should match");

        assertEq(
            camelotExtremeTokenA.balanceOf(address(this)) - initialBalanceA,
            actualAmountA,
            "TokenA balance change should match withdrawal"
        );
        assertEq(
            camelotExtremeTokenB.balanceOf(address(this)) - initialBalanceB,
            actualAmountB,
            "TokenB balance change should match withdrawal"
        );

        console.log("_withdrawQuote Camelot extreme unbalanced pool test passed:");
    }
}
