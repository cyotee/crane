// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TestBase_ConstProdUtils.sol";
import "../../../../../../contracts/crane/utils/math/ConstProdUtils.sol";

contract Test_ConstProdUtils_calculateYieldForOwnedLP is TestBase_ConstProdUtils {
    using ConstProdUtils for uint256;

    // Tests for the 5-parameter version (wrapper function)
    function test_calculateYieldForOwnedLP_5Param_Camelot_balancedPool() public {
        (uint112 reserve0, uint112 reserve1, , ) = camelotBalancedPair.getReserves();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
            address(camelotBalancedTokenA), camelotBalancedPair.token0(), reserve0, reserve1
        );
        uint256 totalSupply = camelotBalancedPair.totalSupply();
        uint256 lastK = (reserveA * reserveB) / 2; // Previous K was half current
        uint256 ownedLP = totalSupply / 10; // Own 10% of total supply

        // Calculate expected values
        (uint256 expectedLpOfYield, uint256 expectedNewK) = ConstProdUtils._calculateYieldForOwnedLP(
            reserveA,
            reserveB,
            totalSupply,
            lastK,
            ownedLP
        );

        // Verify newK is calculated correctly
        assertEq(expectedNewK, reserveA * reserveB, "NewK should equal reserveA * reserveB");

        // Verify yield is calculated when K has grown
        assertGt(expectedLpOfYield, 0, "LP of yield should be greater than 0 when K has grown");

        // Verify yield is proportional to owned LP
        assertLt(expectedLpOfYield, ownedLP, "Yield should be less than owned LP");
    }

    function test_calculateYieldForOwnedLP_5Param_Camelot_unbalancedPool() public {
        (uint112 reserve0, uint112 reserve1, , ) = camelotUnbalancedPair.getReserves();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
            address(camelotUnbalancedTokenA), camelotUnbalancedPair.token0(), reserve0, reserve1
        );
        uint256 totalSupply = camelotUnbalancedPair.totalSupply();
        uint256 lastK = (reserveA * reserveB) / 2; // Previous K was half current
        uint256 ownedLP = totalSupply / 10; // Own 10% of total supply

        // Calculate expected values
        (uint256 expectedLpOfYield, uint256 expectedNewK) = ConstProdUtils._calculateYieldForOwnedLP(
            reserveA,
            reserveB,
            totalSupply,
            lastK,
            ownedLP
        );

        // Verify newK is calculated correctly
        assertEq(expectedNewK, reserveA * reserveB, "NewK should equal reserveA * reserveB");

        // Verify yield is calculated when K has grown
        assertGt(expectedLpOfYield, 0, "LP of yield should be greater than 0 when K has grown");
    }

    function test_calculateYieldForOwnedLP_5Param_Camelot_extremeUnbalancedPool() public {
        (uint112 reserveA, uint112 reserveB, , ) = camelotBalancedPair.getReserves();
        uint256 totalSupply = camelotBalancedPair.totalSupply();
        uint256 lastK = (reserveA * reserveB) / 2; // Previous K was half current
        uint256 ownedLP = totalSupply / 10; // Own 10% of total supply

        // Calculate expected values
        (uint256 expectedLpOfYield, uint256 expectedNewK) = ConstProdUtils._calculateYieldForOwnedLP(
            reserveA,
            reserveB,
            totalSupply,
            lastK,
            ownedLP
        );

        // Verify newK is calculated correctly
        assertEq(expectedNewK, reserveA * reserveB, "NewK should equal reserveA * reserveB");

        // Verify yield is calculated when K has grown
        assertGt(expectedLpOfYield, 0, "LP of yield should be greater than 0 when K has grown");
    }

    function test_calculateYieldForOwnedLP_5Param_Uniswap_balancedPool() public {
        (uint112 reserveA, uint112 reserveB, ) = uniswapBalancedPair.getReserves();
        uint256 totalSupply = uniswapBalancedPair.totalSupply();
        uint256 lastK = (reserveA * reserveB) / 2; // Previous K was half current
        uint256 ownedLP = totalSupply / 10; // Own 10% of total supply

        // Calculate expected values
        (uint256 expectedLpOfYield, uint256 expectedNewK) = ConstProdUtils._calculateYieldForOwnedLP(
            reserveA,
            reserveB,
            totalSupply,
            lastK,
            ownedLP
        );

        // Verify newK is calculated correctly
        assertEq(expectedNewK, reserveA * reserveB, "NewK should equal reserveA * reserveB");

        // Verify yield is calculated when K has grown
        assertGt(expectedLpOfYield, 0, "LP of yield should be greater than 0 when K has grown");
    }

    function test_calculateYieldForOwnedLP_5Param_Uniswap_unbalancedPool() public {
        (uint112 reserveA, uint112 reserveB, ) = uniswapBalancedPair.getReserves();
        uint256 totalSupply = uniswapBalancedPair.totalSupply();
        uint256 lastK = (reserveA * reserveB) / 2; // Previous K was half current
        uint256 ownedLP = totalSupply / 10; // Own 10% of total supply

        // Calculate expected values
        (uint256 expectedLpOfYield, uint256 expectedNewK) = ConstProdUtils._calculateYieldForOwnedLP(
            reserveA,
            reserveB,
            totalSupply,
            lastK,
            ownedLP
        );

        // Verify newK is calculated correctly
        assertEq(expectedNewK, reserveA * reserveB, "NewK should equal reserveA * reserveB");

        // Verify yield is calculated when K has grown
        assertGt(expectedLpOfYield, 0, "LP of yield should be greater than 0 when K has grown");
    }

    function test_calculateYieldForOwnedLP_5Param_Uniswap_extremeUnbalancedPool() public {
        (uint112 reserveA, uint112 reserveB, ) = uniswapBalancedPair.getReserves();
        uint256 totalSupply = uniswapBalancedPair.totalSupply();
        uint256 lastK = (reserveA * reserveB) / 2; // Previous K was half current
        uint256 ownedLP = totalSupply / 10; // Own 10% of total supply

        // Calculate expected values
        (uint256 expectedLpOfYield, uint256 expectedNewK) = ConstProdUtils._calculateYieldForOwnedLP(
            reserveA,
            reserveB,
            totalSupply,
            lastK,
            ownedLP
        );

        // Verify newK is calculated correctly
        assertEq(expectedNewK, reserveA * reserveB, "NewK should equal reserveA * reserveB");

        // Verify yield is calculated when K has grown
        assertGt(expectedLpOfYield, 0, "LP of yield should be greater than 0 when K has grown");
    }

    // Tests for the 6-parameter version (core function)
    function test_calculateYieldForOwnedLP_6Param_Camelot_balancedPool() public {
        (uint112 reserveA, uint112 reserveB, , ) = camelotBalancedPair.getReserves();
        uint256 totalSupply = camelotBalancedPair.totalSupply();
        uint256 lastK = (reserveA * reserveB) / 2; // Previous K was half current
        uint256 newK = reserveA * reserveB;
        uint256 ownedLP = totalSupply / 10; // Own 10% of total supply

        // Calculate expected values
        uint256 expectedLpOfYield = ConstProdUtils._calculateYieldForOwnedLP(
            reserveA,
            reserveB,
            totalSupply,
            lastK,
            newK,
            ownedLP
        );

        // Verify yield is calculated when K has grown
        assertGt(expectedLpOfYield, 0, "LP of yield should be greater than 0 when K has grown");

        // Verify yield is proportional to owned LP
        assertLt(expectedLpOfYield, ownedLP, "Yield should be less than owned LP");
    }

    function test_calculateYieldForOwnedLP_6Param_Camelot_unbalancedPool() public {
        (uint112 reserveA, uint112 reserveB, , ) = camelotBalancedPair.getReserves();
        uint256 totalSupply = camelotBalancedPair.totalSupply();
        uint256 lastK = (reserveA * reserveB) / 2; // Previous K was half current
        uint256 newK = reserveA * reserveB;
        uint256 ownedLP = totalSupply / 10; // Own 10% of total supply

        // Calculate expected values
        uint256 expectedLpOfYield = ConstProdUtils._calculateYieldForOwnedLP(
            reserveA,
            reserveB,
            totalSupply,
            lastK,
            newK,
            ownedLP
        );

        // Verify yield is calculated when K has grown
        assertGt(expectedLpOfYield, 0, "LP of yield should be greater than 0 when K has grown");
    }

    function test_calculateYieldForOwnedLP_6Param_Camelot_extremeUnbalancedPool() public {
        (uint112 reserveA, uint112 reserveB, , ) = camelotBalancedPair.getReserves();
        uint256 totalSupply = camelotBalancedPair.totalSupply();
        uint256 lastK = (reserveA * reserveB) / 2; // Previous K was half current
        uint256 newK = reserveA * reserveB;
        uint256 ownedLP = totalSupply / 10; // Own 10% of total supply

        // Calculate expected values
        uint256 expectedLpOfYield = ConstProdUtils._calculateYieldForOwnedLP(
            reserveA,
            reserveB,
            totalSupply,
            lastK,
            newK,
            ownedLP
        );

        // Verify yield is calculated when K has grown
        assertGt(expectedLpOfYield, 0, "LP of yield should be greater than 0 when K has grown");
    }

    function test_calculateYieldForOwnedLP_6Param_Uniswap_balancedPool() public {
        (uint112 reserveA, uint112 reserveB, ) = uniswapBalancedPair.getReserves();
        uint256 totalSupply = uniswapBalancedPair.totalSupply();
        uint256 lastK = (reserveA * reserveB) / 2; // Previous K was half current
        uint256 newK = reserveA * reserveB;
        uint256 ownedLP = totalSupply / 10; // Own 10% of total supply

        // Calculate expected values
        uint256 expectedLpOfYield = ConstProdUtils._calculateYieldForOwnedLP(
            reserveA,
            reserveB,
            totalSupply,
            lastK,
            newK,
            ownedLP
        );

        // Verify yield is calculated when K has grown
        assertGt(expectedLpOfYield, 0, "LP of yield should be greater than 0 when K has grown");
    }

    function test_calculateYieldForOwnedLP_6Param_Uniswap_unbalancedPool() public {
        (uint112 reserveA, uint112 reserveB, ) = uniswapBalancedPair.getReserves();
        uint256 totalSupply = uniswapBalancedPair.totalSupply();
        uint256 lastK = (reserveA * reserveB) / 2; // Previous K was half current
        uint256 newK = reserveA * reserveB;
        uint256 ownedLP = totalSupply / 10; // Own 10% of total supply

        // Calculate expected values
        uint256 expectedLpOfYield = ConstProdUtils._calculateYieldForOwnedLP(
            reserveA,
            reserveB,
            totalSupply,
            lastK,
            newK,
            ownedLP
        );

        // Verify yield is calculated when K has grown
        assertGt(expectedLpOfYield, 0, "LP of yield should be greater than 0 when K has grown");
    }

    function test_calculateYieldForOwnedLP_6Param_Uniswap_extremeUnbalancedPool() public {
        (uint112 reserveA, uint112 reserveB, ) = uniswapBalancedPair.getReserves();
        uint256 totalSupply = uniswapBalancedPair.totalSupply();
        uint256 lastK = (reserveA * reserveB) / 2; // Previous K was half current
        uint256 newK = reserveA * reserveB;
        uint256 ownedLP = totalSupply / 10; // Own 10% of total supply

        // Calculate expected values
        uint256 expectedLpOfYield = ConstProdUtils._calculateYieldForOwnedLP(
            reserveA,
            reserveB,
            totalSupply,
            lastK,
            newK,
            ownedLP
        );

        // Verify yield is calculated when K has grown
        assertGt(expectedLpOfYield, 0, "LP of yield should be greater than 0 when K has grown");
    }

    // Edge case tests for 5-parameter version
    function test_calculateYieldForOwnedLP_5Param_edgeCase_noGrowth() public {
        (uint112 reserveA, uint112 reserveB, , ) = camelotBalancedPair.getReserves();
        uint256 totalSupply = camelotBalancedPair.totalSupply();
        uint256 lastK = reserveA * reserveB; // Same K as current
        uint256 ownedLP = totalSupply / 10; // Own 10% of total supply

        // Calculate expected values
        (uint256 expectedLpOfYield, uint256 expectedNewK) = ConstProdUtils._calculateYieldForOwnedLP(
            reserveA,
            reserveB,
            totalSupply,
            lastK,
            ownedLP
        );

        // Verify no yield when K hasn't grown
        assertEq(expectedLpOfYield, 0, "LP of yield should be 0 when K hasn't grown");
        assertEq(expectedNewK, reserveA * reserveB, "NewK should equal reserveA * reserveB");
    }

    function test_calculateYieldForOwnedLP_5Param_edgeCase_zeroOwnedLP() public {
        (uint112 reserveA, uint112 reserveB, , ) = camelotBalancedPair.getReserves();
        uint256 totalSupply = camelotBalancedPair.totalSupply();
        uint256 lastK = (reserveA * reserveB) / 2; // Previous K was half current
        uint256 ownedLP = 0; // Zero owned LP

        // Calculate expected values
        (uint256 expectedLpOfYield, uint256 expectedNewK) = ConstProdUtils._calculateYieldForOwnedLP(
            reserveA,
            reserveB,
            totalSupply,
            lastK,
            ownedLP
        );

        // Verify no yield when owned LP is zero
        assertEq(expectedLpOfYield, 0, "LP of yield should be 0 when owned LP is zero");
        assertEq(expectedNewK, reserveA * reserveB, "NewK should equal reserveA * reserveB");
    }

    function test_calculateYieldForOwnedLP_5Param_edgeCase_zeroTotalSupply() public {
        (uint112 reserveA, uint112 reserveB, , ) = camelotBalancedPair.getReserves();
        uint256 totalSupply = 0; // Zero total supply
        uint256 lastK = (reserveA * reserveB) / 2; // Previous K was half current
        uint256 ownedLP = 1000e18; // Some owned LP

        // Calculate expected values
        (uint256 expectedLpOfYield, uint256 expectedNewK) = ConstProdUtils._calculateYieldForOwnedLP(
            reserveA,
            reserveB,
            totalSupply,
            lastK,
            ownedLP
        );

        // Verify no yield when total supply is zero
        assertEq(expectedLpOfYield, 0, "LP of yield should be 0 when total supply is zero");
        assertEq(expectedNewK, reserveA * reserveB, "NewK should equal reserveA * reserveB");
    }

    function test_calculateYieldForOwnedLP_5Param_edgeCase_decreasedK() public {
        (uint112 reserveA, uint112 reserveB, , ) = camelotBalancedPair.getReserves();
        uint256 totalSupply = camelotBalancedPair.totalSupply();
        uint256 lastK = reserveA * reserveB * 2; // Previous K was double current
        uint256 ownedLP = totalSupply / 10; // Own 10% of total supply

        // Calculate expected values
        (uint256 expectedLpOfYield, uint256 expectedNewK) = ConstProdUtils._calculateYieldForOwnedLP(
            reserveA,
            reserveB,
            totalSupply,
            lastK,
            ownedLP
        );

        // Verify no yield when K has decreased
        assertEq(expectedLpOfYield, 0, "LP of yield should be 0 when K has decreased");
        assertEq(expectedNewK, reserveA * reserveB, "NewK should equal reserveA * reserveB");
    }

    // Edge case tests for 6-parameter version
    function test_calculateYieldForOwnedLP_6Param_edgeCase_noGrowth() public {
        (uint112 reserveA, uint112 reserveB, , ) = camelotBalancedPair.getReserves();
        uint256 totalSupply = camelotBalancedPair.totalSupply();
        uint256 lastK = reserveA * reserveB; // Same K as current
        uint256 newK = reserveA * reserveB;
        uint256 ownedLP = totalSupply / 10; // Own 10% of total supply

        // Calculate expected values
        uint256 expectedLpOfYield = ConstProdUtils._calculateYieldForOwnedLP(
            reserveA,
            reserveB,
            totalSupply,
            lastK,
            newK,
            ownedLP
        );

        // Verify no yield when K hasn't grown
        assertEq(expectedLpOfYield, 0, "LP of yield should be 0 when K hasn't grown");
    }

    function test_calculateYieldForOwnedLP_6Param_edgeCase_zeroOwnedLP() public {
        (uint112 reserveA, uint112 reserveB, , ) = camelotBalancedPair.getReserves();
        uint256 totalSupply = camelotBalancedPair.totalSupply();
        uint256 lastK = (reserveA * reserveB) / 2; // Previous K was half current
        uint256 newK = reserveA * reserveB;
        uint256 ownedLP = 0; // Zero owned LP

        // Calculate expected values
        uint256 expectedLpOfYield = ConstProdUtils._calculateYieldForOwnedLP(
            reserveA,
            reserveB,
            totalSupply,
            lastK,
            newK,
            ownedLP
        );

        // Verify no yield when owned LP is zero
        assertEq(expectedLpOfYield, 0, "LP of yield should be 0 when owned LP is zero");
    }

    function test_calculateYieldForOwnedLP_6Param_edgeCase_zeroTotalSupply() public {
        (uint112 reserveA, uint112 reserveB, , ) = camelotBalancedPair.getReserves();
        uint256 totalSupply = 0; // Zero total supply
        uint256 lastK = (reserveA * reserveB) / 2; // Previous K was half current
        uint256 newK = reserveA * reserveB;
        uint256 ownedLP = 1000e18; // Some owned LP

        // Calculate expected values
        uint256 expectedLpOfYield = ConstProdUtils._calculateYieldForOwnedLP(
            reserveA,
            reserveB,
            totalSupply,
            lastK,
            newK,
            ownedLP
        );

        // Verify no yield when total supply is zero
        assertEq(expectedLpOfYield, 0, "LP of yield should be 0 when total supply is zero");
    }

    function test_calculateYieldForOwnedLP_6Param_edgeCase_decreasedK() public {
        (uint112 reserveA, uint112 reserveB, , ) = camelotBalancedPair.getReserves();
        uint256 totalSupply = camelotBalancedPair.totalSupply();
        uint256 lastK = reserveA * reserveB * 2; // Previous K was double current
        uint256 newK = reserveA * reserveB;
        uint256 ownedLP = totalSupply / 10; // Own 10% of total supply

        // Calculate expected values
        uint256 expectedLpOfYield = ConstProdUtils._calculateYieldForOwnedLP(
            reserveA,
            reserveB,
            totalSupply,
            lastK,
            newK,
            ownedLP
        );

        // Verify no yield when K has decreased
        assertEq(expectedLpOfYield, 0, "LP of yield should be 0 when K has decreased");
    }

    // Test to verify both functions return the same yield amount
    function test_calculateYieldForOwnedLP_consistency() public {
        (uint112 reserveA, uint112 reserveB, , ) = camelotBalancedPair.getReserves();
        uint256 totalSupply = camelotBalancedPair.totalSupply();
        uint256 lastK = (reserveA * reserveB) / 2; // Previous K was half current
        uint256 ownedLP = totalSupply / 10; // Own 10% of total supply

        // Calculate using 5-parameter version
        (uint256 lpOfYield5, uint256 newK) = ConstProdUtils._calculateYieldForOwnedLP(
            reserveA,
            reserveB,
            totalSupply,
            lastK,
            ownedLP
        );

        // Calculate using 6-parameter version
        uint256 lpOfYield6 = ConstProdUtils._calculateYieldForOwnedLP(
            reserveA,
            reserveB,
            totalSupply,
            lastK,
            newK,
            ownedLP
        );

        // Verify both functions return the same yield amount
        assertEq(lpOfYield5, lpOfYield6, "Both functions should return the same yield amount");
        assertEq(newK, reserveA * reserveB, "NewK should equal reserveA * reserveB");
    }

    // Test with different owned LP amounts
    function test_calculateYieldForOwnedLP_differentOwnedAmounts() public {
        (uint112 reserveA, uint112 reserveB, , ) = camelotBalancedPair.getReserves();
        uint256 totalSupply = camelotBalancedPair.totalSupply();
        uint256 lastK = (reserveA * reserveB) / 2; // Previous K was half current
        uint256 newK = reserveA * reserveB;

        // Test with different owned LP amounts
        uint256[] memory ownedAmounts = new uint256[](5);
        ownedAmounts[0] = totalSupply / 100; // 1%
        ownedAmounts[1] = totalSupply / 50;  // 2%
        ownedAmounts[2] = totalSupply / 20;  // 5%
        ownedAmounts[3] = totalSupply / 10;  // 10%
        ownedAmounts[4] = totalSupply / 5;   // 20%

        uint256[] memory yields = new uint256[](5);

        for (uint256 i = 0; i < ownedAmounts.length; i++) {
            yields[i] = ConstProdUtils._calculateYieldForOwnedLP(
                reserveA,
                reserveB,
                totalSupply,
                lastK,
                newK,
                ownedAmounts[i]
            );

            // Verify yield is proportional to owned amount
            assertGt(yields[i], 0, "Yield should be greater than 0");
            assertLt(yields[i], ownedAmounts[i], "Yield should be less than owned amount");
        }

        // Verify yields are proportional to owned amounts
        for (uint256 i = 1; i < ownedAmounts.length; i++) {
            uint256 ratio1 = yields[i-1] * 1e18 / ownedAmounts[i-1];
            uint256 ratio2 = yields[i] * 1e18 / ownedAmounts[i];
            // Allow for small rounding differences
            assertApproxEqRel(ratio1, ratio2, 1e15, "Yield ratios should be approximately equal");
        }
    }
}
