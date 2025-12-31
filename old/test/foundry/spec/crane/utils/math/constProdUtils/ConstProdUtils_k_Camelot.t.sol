// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";
import {TestBase_ConstProdUtils_Camelot} from "./TestBase_ConstProdUtils_Camelot.sol";

contract ConstProdUtils_k_Camelot is TestBase_ConstProdUtils_Camelot {
    function setUp() public override {
        super.setUp();
        _initializeCamelotBalancedPools();
    }

    function test_k_Camelot_balancedPool() public view {
        (uint112 reserve0, uint112 reserve1, , ) = camelotBalancedPair.getReserves();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(address(camelotBalancedTokenA), camelotBalancedPair.token0(), reserve0, reserve1);
        uint256 expectedK = reserveA * reserveB;
        uint256 actualK = ConstProdUtils._k(reserveA, reserveB);
        assertEq(actualK, expectedK);
    }

    function test_k_Camelot_unbalancedPool() public view {
        (uint112 reserve0, uint112 reserve1, , ) = camelotUnbalancedPair.getReserves();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(address(camelotUnbalancedTokenA), camelotUnbalancedPair.token0(), reserve0, reserve1);
        uint256 expectedK = reserveA * reserveB;
        uint256 actualK = ConstProdUtils._k(reserveA, reserveB);
        assertEq(actualK, expectedK);
    }

    function test_k_Camelot_extremeUnbalancedPool() public view {
        (uint112 reserve0, uint112 reserve1, , ) = camelotExtremeUnbalancedPair.getReserves();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(address(camelotExtremeTokenA), camelotExtremeUnbalancedPair.token0(), reserve0, reserve1);
        uint256 expectedK = reserveA * reserveB;
        uint256 actualK = ConstProdUtils._k(reserveA, reserveB);
        assertEq(actualK, expectedK);
    }

    function test_k_edgeCase_zeroBalances() public pure {
        uint256 balanceA = 0;
        uint256 balanceB = 0;
        uint256 expectedK = balanceA * balanceB;
        uint256 actualK = ConstProdUtils._k(balanceA, balanceB);
        assertEq(actualK, expectedK);
    }

    function test_k_edgeCase_oneZeroBalance() public view {
        uint256 balanceA = 1000e18;
        uint256 balanceB = 0;
        uint256 expectedK = balanceA * balanceB;
        uint256 actualK = ConstProdUtils._k(balanceA, balanceB);
        assertEq(actualK, expectedK);
    }

    function test_k_edgeCase_smallBalances() public pure {
        uint256 balanceA = 1;
        uint256 balanceB = 1;
        uint256 expectedK = balanceA * balanceB;
        uint256 actualK = ConstProdUtils._k(balanceA, balanceB);
        assertEq(actualK, expectedK);
    }

    function test_k_edgeCase_largeBalances() public pure {
        uint256 balanceA = 1e30;
        uint256 balanceB = 1e30;
        uint256 expectedK = balanceA * balanceB;
        uint256 actualK = ConstProdUtils._k(balanceA, balanceB);
        assertEq(actualK, expectedK);
    }

    function test_k_edgeCase_veryDifferentBalances() public pure {
        uint256 balanceA = 1e30;
        uint256 balanceB = 1;
        uint256 expectedK = balanceA * balanceB;
        uint256 actualK = ConstProdUtils._k(balanceA, balanceB);
        assertEq(actualK, expectedK);
    }

    function test_k_edgeCase_maxUint256() public pure {
        uint256 balanceA = type(uint256).max;
        uint256 balanceB = 1;
        uint256 expectedK = balanceA * balanceB;
        uint256 actualK = ConstProdUtils._k(balanceA, balanceB);
        assertEq(actualK, expectedK);
    }
}
