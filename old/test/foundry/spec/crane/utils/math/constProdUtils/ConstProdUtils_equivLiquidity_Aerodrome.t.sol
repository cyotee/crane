// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {TestBase_ConstProdUtils_Aerodrome} from "test/foundry/spec/utils/math/constProdUtils/TestBase_ConstProdUtils_Aerodrome.sol";
import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";

contract ConstProdUtils_equivLiquidity_Aerodrome_Test is TestBase_ConstProdUtils_Aerodrome {
    function setUp() public override {
        TestBase_ConstProdUtils_Aerodrome.setUp();
    }

    function test_equivLiquidity_Aerodrome_balancedPool() public {
        _initializeAerodromeBalancedPools();
        (uint256 reserve0, uint256 reserve1,) = aeroBalancedPool.getReserves();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
            address(aeroBalancedTokenA), aeroBalancedPool.token0(), reserve0, reserve1
        );

        uint256 amountA = reserveA;
        uint256 expectedAmountB = ConstProdUtils._equivLiquidity(amountA, reserveA, reserveB);
        assertEq(expectedAmountB, reserveB, "Calculated equivalent liquidity should match actual pool reserve");
    }

    function test_equivLiquidity_Aerodrome_unbalancedPool() public {
        _initializeAerodromeUnbalancedPools();
        (uint256 reserve0, uint256 reserve1,) = aeroUnbalancedPool.getReserves();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
            address(aeroUnbalancedTokenA), aeroUnbalancedPool.token0(), reserve0, reserve1
        );

        uint256 amountA = reserveA;
        uint256 expectedAmountB = ConstProdUtils._equivLiquidity(amountA, reserveA, reserveB);
        assertEq(expectedAmountB, reserveB, "Calculated equivalent liquidity should match actual pool reserve");
    }

    function test_equivLiquidity_Aerodrome_extremeUnbalancedPool() public {
        _initializeAerodromeExtremeUnbalancedPools();
        (uint256 reserve0, uint256 reserve1,) = aeroExtremeUnbalancedPool.getReserves();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
            address(aeroExtremeTokenA), aeroExtremeUnbalancedPool.token0(), reserve0, reserve1
        );

        uint256 amountA = reserveA;
        uint256 expectedAmountB = ConstProdUtils._equivLiquidity(amountA, reserveA, reserveB);
        assertEq(expectedAmountB, reserveB, "Calculated equivalent liquidity should match actual pool reserve");
    }
}
