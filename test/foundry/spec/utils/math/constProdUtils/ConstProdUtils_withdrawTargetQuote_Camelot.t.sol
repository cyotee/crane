// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";
import {TestBase_ConstProdUtils_Camelot} from "./TestBase_ConstProdUtils_Camelot.sol";
import {ICamelotPair} from "contracts/interfaces/protocols/dexes/camelot/v2/ICamelotPair.sol";
import {CamelotV2Service} from "@crane/contracts/protocols/dexes/camelot/v2/CamelotV2Service.sol";

contract ConstProdUtils_withdrawTargetQuote_Camelot is TestBase_ConstProdUtils_Camelot {
    function setUp() public override {
        super.setUp();
    }

    function test_withdrawTargetQuote_Camelot_balancedPool() public {
        _initializeCamelotBalancedPools();

        ICamelotPair pair = camelotBalancedPair;
        (uint112 reserve0, uint112 reserve1,,) = pair.getReserves();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(address(camelotBalancedTokenA), pair.token0(), reserve0, reserve1);
        uint256 totalSupply = pair.totalSupply();

        uint256 targetAmount = reserveA / 10;
        uint256 expectedLPTokens = ConstProdUtils._withdrawTargetQuote(targetAmount, totalSupply, reserveA);

        uint256 lpBalance = pair.balanceOf(address(this));
        assertGe(lpBalance, expectedLPTokens, "Must have enough LP tokens for withdrawal");

        uint256 initialBalanceA = camelotBalancedTokenA.balanceOf(address(this));

        (uint256 amount0, uint256 amount1) = CamelotV2Service._withdrawDirect(pair, expectedLPTokens);
        uint256 actualAmountA = address(camelotBalancedTokenA) == pair.token0() ? amount0 : amount1;

        assertGe(actualAmountA, targetAmount, "Actual withdrawal should be at least target amount");
        assertEq(camelotBalancedTokenA.balanceOf(address(this)) - initialBalanceA, actualAmountA, "TokenA balance change should match withdrawal");
    }

    function test_withdrawTargetQuote_Camelot_unbalancedPool() public {
        _initializeCamelotUnbalancedPools();

        ICamelotPair pair = camelotUnbalancedPair;
        (uint112 reserve0, uint112 reserve1,,) = pair.getReserves();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(address(camelotUnbalancedTokenA), pair.token0(), reserve0, reserve1);
        uint256 totalSupply = pair.totalSupply();

        uint256 targetAmount = reserveA / 10;
        uint256 expectedLPTokens = ConstProdUtils._withdrawTargetQuote(targetAmount, totalSupply, reserveA);

        uint256 lpBalance = pair.balanceOf(address(this));
        assertGe(lpBalance, expectedLPTokens, "Must have enough LP tokens for withdrawal");

        uint256 initialBalanceA = camelotUnbalancedTokenA.balanceOf(address(this));

        (uint256 amount0, uint256 amount1) = CamelotV2Service._withdrawDirect(pair, expectedLPTokens);
        uint256 actualAmountA = address(camelotUnbalancedTokenA) == pair.token0() ? amount0 : amount1;

        assertGe(actualAmountA, targetAmount, "Actual withdrawal should be at least target amount");
        assertEq(camelotUnbalancedTokenA.balanceOf(address(this)) - initialBalanceA, actualAmountA, "TokenA balance change should match withdrawal");
    }

    function test_withdrawTargetQuote_Camelot_extremeUnbalancedPool() public {
        _initializeCamelotExtremeUnbalancedPools();

        ICamelotPair pair = camelotExtremeUnbalancedPair;
        (uint112 reserve0, uint112 reserve1,,) = pair.getReserves();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(address(camelotExtremeTokenA), pair.token0(), reserve0, reserve1);
        uint256 totalSupply = pair.totalSupply();

        uint256 targetAmount = reserveA / 10;
        uint256 expectedLPTokens = ConstProdUtils._withdrawTargetQuote(targetAmount, totalSupply, reserveA);

        uint256 lpBalance = pair.balanceOf(address(this));
        assertGe(lpBalance, expectedLPTokens, "Must have enough LP tokens for withdrawal");

        uint256 initialBalanceA = camelotExtremeTokenA.balanceOf(address(this));

        (uint256 amount0, uint256 amount1) = CamelotV2Service._withdrawDirect(pair, expectedLPTokens);
        uint256 actualAmountA = address(camelotExtremeTokenA) == pair.token0() ? amount0 : amount1;

        assertGe(actualAmountA, targetAmount, "Actual withdrawal should be at least target amount");
        assertEq(camelotExtremeTokenA.balanceOf(address(this)) - initialBalanceA, actualAmountA, "TokenA balance change should match withdrawal");
    }
}
