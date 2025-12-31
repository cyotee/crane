// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";
import {TestBase_ConstProdUtils_Aerodrome} from "./TestBase_ConstProdUtils_Aerodrome.sol";
import {Pool} from "contracts/protocols/dexes/aerodrome/v1/Pool.sol";

contract ConstProdUtils_k_Aerodrome is TestBase_ConstProdUtils_Aerodrome {
    function setUp() public override {
        super.setUp();
        _initializeAerodromeBalancedPools();
    }

    function test_k_Aerodrome_balancedPool() public view {
        uint256 reserve0 = aeroBalancedPool.reserve0();
        uint256 reserve1 = aeroBalancedPool.reserve1();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(address(aeroBalancedTokenA), aeroBalancedPool.token0(), reserve0, reserve1);
        uint256 expectedK = reserveA * reserveB;
        uint256 actualK = ConstProdUtils._k(reserveA, reserveB);
        assertEq(actualK, expectedK);
    }

    function test_k_Aerodrome_unbalancedPool() public view {
        uint256 reserve0 = aeroUnbalancedPool.reserve0();
        uint256 reserve1 = aeroUnbalancedPool.reserve1();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(address(aeroUnbalancedTokenA), aeroUnbalancedPool.token0(), reserve0, reserve1);
        uint256 expectedK = reserveA * reserveB;
        uint256 actualK = ConstProdUtils._k(reserveA, reserveB);
        assertEq(actualK, expectedK);
    }

    function test_k_Aerodrome_extremeUnbalancedPool() public view {
        uint256 reserve0 = aeroExtremeUnbalancedPool.reserve0();
        uint256 reserve1 = aeroExtremeUnbalancedPool.reserve1();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(address(aeroExtremeTokenA), aeroExtremeUnbalancedPool.token0(), reserve0, reserve1);
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
