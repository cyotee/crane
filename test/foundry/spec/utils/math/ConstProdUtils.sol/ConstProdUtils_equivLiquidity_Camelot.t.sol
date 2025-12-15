// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {betterconsole as console} from "contracts/utils/vm/foundry/tools/betterconsole.sol";
import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";
import {TestBase_ConstProdUtils_Camelot} from "@crane/test/foundry/spec/utils/math/ConstProdUtils.sol/TestBase_ConstProdUtils_Camelot.sol";

contract ConstProdUtils_equivLiquidity_Camelot_Test is TestBase_ConstProdUtils_Camelot {
    function setUp() public override {
        TestBase_ConstProdUtils_Camelot.setUp();
    }

    function test_equivLiquidity_Camelot_balancedPool() public {
        _initializeCamelotBalancedPools();
        (uint112 reserve0, uint112 reserve1, uint16 token0Fee, uint16 token1Fee) = camelotBalancedPair.getReserves();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
            address(camelotBalancedTokenA), camelotBalancedPair.token0(), reserve0, reserve1
        );

        uint256 amountA = reserveA;
        uint256 expectedAmountB = ConstProdUtils._equivLiquidity(amountA, reserveA, reserveB);
        assertEq(expectedAmountB, reserveB, "Calculated equivalent liquidity should match actual pool reserve");
    }

    function test_equivLiquidity_Camelot_unbalancedPool() public {
        _initializeCamelotUnbalancedPools();
        (uint112 reserve0, uint112 reserve1, uint16 token0Fee, uint16 token1Fee) = camelotUnbalancedPair.getReserves();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
            address(camelotUnbalancedTokenA), camelotUnbalancedPair.token0(), reserve0, reserve1
        );

        uint256 amountA = reserveA;
        uint256 expectedAmountB = ConstProdUtils._equivLiquidity(amountA, reserveA, reserveB);
        assertEq(expectedAmountB, reserveB, "Calculated equivalent liquidity should match actual pool reserve");
    }

    function test_equivLiquidity_Camelot_extremeUnbalancedPool() public {
        _initializeCamelotExtremeUnbalancedPools();
        (uint112 reserve0, uint112 reserve1, uint16 token0Fee, uint16 token1Fee) =
            camelotExtremeUnbalancedPair.getReserves();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
            address(camelotExtremeTokenA), camelotExtremeUnbalancedPair.token0(), reserve0, reserve1
        );

        uint256 amountA = reserveA;
        uint256 expectedAmountB = ConstProdUtils._equivLiquidity(amountA, reserveA, reserveB);
        assertEq(expectedAmountB, reserveB, "Calculated equivalent liquidity should match actual pool reserve");
    }
}
