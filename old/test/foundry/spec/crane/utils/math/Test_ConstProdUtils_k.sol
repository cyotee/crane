// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {TestBase_ConstProdUtils} from "./TestBase_ConstProdUtils.sol";
import {ConstProdUtils} from "contracts/crane/utils/math/ConstProdUtils.sol";

contract Test_ConstProdUtils_k is TestBase_ConstProdUtils {
    function setUp() public override {
        super.setUp();
        _initializePools();
    }

    // Basic Functionality Tests (6 tests)

    function test_k_Camelot_balancedPool() public view {
        (uint112 reserve0, uint112 reserve1,,) = camelotBalancedPair.getReserves();

        // Sort reserves to match token order
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
            address(camelotBalancedTokenA), camelotBalancedPair.token0(), reserve0, reserve1
        );

        // Calculate expected K
        uint256 expectedK = reserveA * reserveB;

        // Calculate actual K using ConstProdUtils
        uint256 actualK = ConstProdUtils._k(reserveA, reserveB);

        // Verify exact match
        assertEq(actualK, expectedK, "K calculation should match expected value");
    }

    function test_k_Camelot_unbalancedPool() public view {
        (uint112 reserve0, uint112 reserve1,,) = camelotUnbalancedPair.getReserves();

        // Sort reserves to match token order
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
            address(camelotUnbalancedTokenA), camelotUnbalancedPair.token0(), reserve0, reserve1
        );

        // Calculate expected K
        uint256 expectedK = reserveA * reserveB;

        // Calculate actual K using ConstProdUtils
        uint256 actualK = ConstProdUtils._k(reserveA, reserveB);

        // Verify exact match
        assertEq(actualK, expectedK, "K calculation should match expected value");
    }

    function test_k_Camelot_extremeUnbalancedPool() public view {
        (uint112 reserve0, uint112 reserve1,,) = camelotExtremeUnbalancedPair.getReserves();

        // Sort reserves to match token order
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
            address(camelotExtremeTokenA), camelotExtremeUnbalancedPair.token0(), reserve0, reserve1
        );

        // Calculate expected K
        uint256 expectedK = reserveA * reserveB;

        // Calculate actual K using ConstProdUtils
        uint256 actualK = ConstProdUtils._k(reserveA, reserveB);

        // Verify exact match
        assertEq(actualK, expectedK, "K calculation should match expected value");
    }

    function test_k_Uniswap_balancedPool() public view {
        (uint112 reserve0, uint112 reserve1,) = uniswapBalancedPair.getReserves();

        // Sort reserves to match token order
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
            address(uniswapBalancedTokenA), uniswapBalancedPair.token0(), reserve0, reserve1
        );

        // Calculate expected K
        uint256 expectedK = reserveA * reserveB;

        // Calculate actual K using ConstProdUtils
        uint256 actualK = ConstProdUtils._k(reserveA, reserveB);

        // Verify exact match
        assertEq(actualK, expectedK, "K calculation should match expected value");
    }

    function test_k_Uniswap_unbalancedPool() public view {
        (uint112 reserve0, uint112 reserve1,) = uniswapUnbalancedPair.getReserves();

        // Sort reserves to match token order
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
            address(uniswapUnbalancedTokenA), uniswapUnbalancedPair.token0(), reserve0, reserve1
        );

        // Calculate expected K
        uint256 expectedK = reserveA * reserveB;

        // Calculate actual K using ConstProdUtils
        uint256 actualK = ConstProdUtils._k(reserveA, reserveB);

        // Verify exact match
        assertEq(actualK, expectedK, "K calculation should match expected value");
    }

    function test_k_Uniswap_extremeUnbalancedPool() public view {
        (uint112 reserve0, uint112 reserve1,) = uniswapExtremeUnbalancedPair.getReserves();

        // Sort reserves to match token order
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
            address(uniswapExtremeTokenA), uniswapExtremeUnbalancedPair.token0(), reserve0, reserve1
        );

        // Calculate expected K
        uint256 expectedK = reserveA * reserveB;

        // Calculate actual K using ConstProdUtils
        uint256 actualK = ConstProdUtils._k(reserveA, reserveB);

        // Verify exact match
        assertEq(actualK, expectedK, "K calculation should match expected value");
    }

    // Edge Case Tests (6 tests)

    function test_k_edgeCase_zeroBalances() public pure {
        // Test with zero balances
        uint256 balanceA = 0;
        uint256 balanceB = 0;

        // Calculate expected K
        uint256 expectedK = balanceA * balanceB; // Should be 0

        // Calculate actual K using ConstProdUtils
        uint256 actualK = ConstProdUtils._k(balanceA, balanceB);

        // Verify exact match
        assertEq(actualK, expectedK, "K calculation should be 0 for zero balances");
    }

    function test_k_edgeCase_oneZeroBalance() public view {
        // Test with one zero balance
        uint256 balanceA = 1000e18;
        uint256 balanceB = 0;

        // Calculate expected K
        uint256 expectedK = balanceA * balanceB; // Should be 0

        // Calculate actual K using ConstProdUtils
        uint256 actualK = ConstProdUtils._k(balanceA, balanceB);

        // Verify exact match
        assertEq(actualK, expectedK, "K calculation should be 0 when one balance is zero");
    }

    function test_k_edgeCase_smallBalances() public pure {
        // Test with small balances
        uint256 balanceA = 1;
        uint256 balanceB = 1;

        // Calculate expected K
        uint256 expectedK = balanceA * balanceB; // Should be 1

        // Calculate actual K using ConstProdUtils
        uint256 actualK = ConstProdUtils._k(balanceA, balanceB);

        // Verify exact match
        assertEq(actualK, expectedK, "K calculation should be 1 for small balances");
    }

    function test_k_edgeCase_largeBalances() public pure {
        // Test with large balances
        uint256 balanceA = 1e30; // Very large number
        uint256 balanceB = 1e30; // Very large number

        // Calculate expected K
        uint256 expectedK = balanceA * balanceB;

        // Calculate actual K using ConstProdUtils
        uint256 actualK = ConstProdUtils._k(balanceA, balanceB);

        // Verify exact match
        assertEq(actualK, expectedK, "K calculation should match for large balances");
    }

    function test_k_edgeCase_veryDifferentBalances() public pure {
        // Test with very different balances
        uint256 balanceA = 1e30; // Very large number
        uint256 balanceB = 1; // Very small number

        // Calculate expected K
        uint256 expectedK = balanceA * balanceB;

        // Calculate actual K using ConstProdUtils
        uint256 actualK = ConstProdUtils._k(balanceA, balanceB);

        // Verify exact match
        assertEq(actualK, expectedK, "K calculation should match for very different balances");
    }

    function test_k_edgeCase_maxUint256() public pure {
        // Test with maximum uint256 values
        uint256 balanceA = type(uint256).max;
        uint256 balanceB = 1;

        // Calculate expected K
        uint256 expectedK = balanceA * balanceB;

        // Calculate actual K using ConstProdUtils
        uint256 actualK = ConstProdUtils._k(balanceA, balanceB);

        // Verify exact match
        assertEq(actualK, expectedK, "K calculation should match for max uint256 values");
    }
}
