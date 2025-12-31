// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {TestBase_ConstProdUtils} from "./TestBase_ConstProdUtils.sol";
import {ConstProdUtils} from "contracts/crane/utils/math/ConstProdUtils.sol";

contract Test_ConstProdUtils_sortReserves is TestBase_ConstProdUtils {
    function setUp() public override {
        super.setUp();
        _initializePools();
    }

    // Test 4-parameter _sortReserves function

    function test_sortReserves_4Param_knownTokenIsToken0() public view {
        // Test when knownToken is token0
        address knownToken = address(camelotBalancedTokenA);
        address token0 = address(camelotBalancedTokenA);
        uint256 reserve0 = 1000e18;
        uint256 reserve1 = 2000e18;

        (uint256 knownReserve, uint256 unknownReserve) =
            ConstProdUtils._sortReserves(knownToken, token0, reserve0, reserve1);

        // When knownToken == token0, should return (reserve0, reserve1)
        assertEq(knownReserve, reserve0, "Known reserve should be reserve0");
        assertEq(unknownReserve, reserve1, "Unknown reserve should be reserve1");
    }

    function test_sortReserves_4Param_knownTokenIsToken1() public view {
        // Test when knownToken is token1
        address knownToken = address(camelotBalancedTokenB);
        address token0 = address(camelotBalancedTokenA);
        uint256 reserve0 = 1000e18;
        uint256 reserve1 = 2000e18;

        (uint256 knownReserve, uint256 unknownReserve) =
            ConstProdUtils._sortReserves(knownToken, token0, reserve0, reserve1);

        // When knownToken != token0, should return (reserve1, reserve0)
        assertEq(knownReserve, reserve1, "Known reserve should be reserve1");
        assertEq(unknownReserve, reserve0, "Unknown reserve should be reserve0");
    }

    function test_sortReserves_4Param_sameToken() public view {
        // Test when knownToken is the same as token0
        address knownToken = address(camelotBalancedTokenA);
        address token0 = address(camelotBalancedTokenA);
        uint256 reserve0 = 5000e18;
        uint256 reserve1 = 3000e18;

        (uint256 knownReserve, uint256 unknownReserve) =
            ConstProdUtils._sortReserves(knownToken, token0, reserve0, reserve1);

        // Should return (reserve0, reserve1)
        assertEq(knownReserve, reserve0, "Known reserve should be reserve0");
        assertEq(unknownReserve, reserve1, "Unknown reserve should be reserve1");
    }

    function test_sortReserves_4Param_differentToken() public view {
        // Test when knownToken is different from token0
        address knownToken = address(camelotBalancedTokenB);
        address token0 = address(camelotBalancedTokenA);
        uint256 reserve0 = 7000e18;
        uint256 reserve1 = 4000e18;

        (uint256 knownReserve, uint256 unknownReserve) =
            ConstProdUtils._sortReserves(knownToken, token0, reserve0, reserve1);

        // Should return (reserve1, reserve0)
        assertEq(knownReserve, reserve1, "Known reserve should be reserve1");
        assertEq(unknownReserve, reserve0, "Unknown reserve should be reserve0");
    }

    function test_sortReserves_4Param_zeroReserves() public view {
        // Test with zero reserves
        address knownToken = address(camelotBalancedTokenA);
        address token0 = address(camelotBalancedTokenA);
        uint256 reserve0 = 0;
        uint256 reserve1 = 0;

        (uint256 knownReserve, uint256 unknownReserve) =
            ConstProdUtils._sortReserves(knownToken, token0, reserve0, reserve1);

        // Should return (reserve0, reserve1)
        assertEq(knownReserve, reserve0, "Known reserve should be reserve0");
        assertEq(unknownReserve, reserve1, "Unknown reserve should be reserve1");
    }

    function test_sortReserves_4Param_largeReserves() public view {
        // Test with large reserve values
        address knownToken = address(camelotBalancedTokenB);
        address token0 = address(camelotBalancedTokenA);
        uint256 reserve0 = 1e30; // Very large number
        uint256 reserve1 = 2e30; // Very large number

        (uint256 knownReserve, uint256 unknownReserve) =
            ConstProdUtils._sortReserves(knownToken, token0, reserve0, reserve1);

        // Should return (reserve1, reserve0)
        assertEq(knownReserve, reserve1, "Known reserve should be reserve1");
        assertEq(unknownReserve, reserve0, "Unknown reserve should be reserve0");
    }

    // Test 6-parameter _sortReserves function

    function test_sortReserves_6Param_knownTokenIsToken0() public view {
        // Test when knownToken is token0
        address knownToken = address(camelotBalancedTokenA);
        address token0 = address(camelotBalancedTokenA);
        uint256 reserve0 = 1000e18;
        uint256 reserve0Fee = 300;
        uint256 reserve1 = 2000e18;
        uint256 reserve1Fee = 500;

        (uint256 knownReserve, uint256 knownReserveFee, uint256 unknownReserve, uint256 unknownReserveFee) =
            ConstProdUtils._sortReserves(knownToken, token0, reserve0, reserve0Fee, reserve1, reserve1Fee);

        // When knownToken == token0, should return (reserve0, reserve0Fee, reserve1, reserve1Fee)
        assertEq(knownReserve, reserve0, "Known reserve should be reserve0");
        assertEq(knownReserveFee, reserve0Fee, "Known reserve fee should be reserve0Fee");
        assertEq(unknownReserve, reserve1, "Unknown reserve should be reserve1");
        assertEq(unknownReserveFee, reserve1Fee, "Unknown reserve fee should be reserve1Fee");
    }

    function test_sortReserves_6Param_knownTokenIsToken1() public view {
        // Test when knownToken is token1
        address knownToken = address(camelotBalancedTokenB);
        address token0 = address(camelotBalancedTokenA);
        uint256 reserve0 = 1000e18;
        uint256 reserve0Fee = 300;
        uint256 reserve1 = 2000e18;
        uint256 reserve1Fee = 500;

        (uint256 knownReserve, uint256 knownReserveFee, uint256 unknownReserve, uint256 unknownReserveFee) =
            ConstProdUtils._sortReserves(knownToken, token0, reserve0, reserve0Fee, reserve1, reserve1Fee);

        // When knownToken != token0, should return (reserve1, reserve1Fee, reserve0, reserve0Fee)
        assertEq(knownReserve, reserve1, "Known reserve should be reserve1");
        assertEq(knownReserveFee, reserve1Fee, "Known reserve fee should be reserve1Fee");
        assertEq(unknownReserve, reserve0, "Unknown reserve should be reserve0");
        assertEq(unknownReserveFee, reserve0Fee, "Unknown reserve fee should be reserve0Fee");
    }

    function test_sortReserves_6Param_sameToken() public view {
        // Test when knownToken is the same as token0
        address knownToken = address(camelotBalancedTokenA);
        address token0 = address(camelotBalancedTokenA);
        uint256 reserve0 = 5000e18;
        uint256 reserve0Fee = 250;
        uint256 reserve1 = 3000e18;
        uint256 reserve1Fee = 400;

        (uint256 knownReserve, uint256 knownReserveFee, uint256 unknownReserve, uint256 unknownReserveFee) =
            ConstProdUtils._sortReserves(knownToken, token0, reserve0, reserve0Fee, reserve1, reserve1Fee);

        // Should return (reserve0, reserve0Fee, reserve1, reserve1Fee)
        assertEq(knownReserve, reserve0, "Known reserve should be reserve0");
        assertEq(knownReserveFee, reserve0Fee, "Known reserve fee should be reserve0Fee");
        assertEq(unknownReserve, reserve1, "Unknown reserve should be reserve1");
        assertEq(unknownReserveFee, reserve1Fee, "Unknown reserve fee should be reserve1Fee");
    }

    function test_sortReserves_6Param_differentToken() public view {
        // Test when knownToken is different from token0
        address knownToken = address(camelotBalancedTokenB);
        address token0 = address(camelotBalancedTokenA);
        uint256 reserve0 = 7000e18;
        uint256 reserve0Fee = 350;
        uint256 reserve1 = 4000e18;
        uint256 reserve1Fee = 450;

        (uint256 knownReserve, uint256 knownReserveFee, uint256 unknownReserve, uint256 unknownReserveFee) =
            ConstProdUtils._sortReserves(knownToken, token0, reserve0, reserve0Fee, reserve1, reserve1Fee);

        // Should return (reserve1, reserve1Fee, reserve0, reserve0Fee)
        assertEq(knownReserve, reserve1, "Known reserve should be reserve1");
        assertEq(knownReserveFee, reserve1Fee, "Known reserve fee should be reserve1Fee");
        assertEq(unknownReserve, reserve0, "Unknown reserve should be reserve0");
        assertEq(unknownReserveFee, reserve0Fee, "Unknown reserve fee should be reserve0Fee");
    }

    function test_sortReserves_6Param_zeroReserves() public view {
        // Test with zero reserves
        address knownToken = address(camelotBalancedTokenA);
        address token0 = address(camelotBalancedTokenA);
        uint256 reserve0 = 0;
        uint256 reserve0Fee = 0;
        uint256 reserve1 = 0;
        uint256 reserve1Fee = 0;

        (uint256 knownReserve, uint256 knownReserveFee, uint256 unknownReserve, uint256 unknownReserveFee) =
            ConstProdUtils._sortReserves(knownToken, token0, reserve0, reserve0Fee, reserve1, reserve1Fee);

        // Should return (reserve0, reserve0Fee, reserve1, reserve1Fee)
        assertEq(knownReserve, reserve0, "Known reserve should be reserve0");
        assertEq(knownReserveFee, reserve0Fee, "Known reserve fee should be reserve0Fee");
        assertEq(unknownReserve, reserve1, "Unknown reserve should be reserve1");
        assertEq(unknownReserveFee, reserve1Fee, "Unknown reserve fee should be reserve1Fee");
    }

    function test_sortReserves_6Param_largeReserves() public view {
        // Test with large reserve values
        address knownToken = address(camelotBalancedTokenB);
        address token0 = address(camelotBalancedTokenA);
        uint256 reserve0 = 1e30; // Very large number
        uint256 reserve0Fee = 1000;
        uint256 reserve1 = 2e30; // Very large number
        uint256 reserve1Fee = 2000;

        (uint256 knownReserve, uint256 knownReserveFee, uint256 unknownReserve, uint256 unknownReserveFee) =
            ConstProdUtils._sortReserves(knownToken, token0, reserve0, reserve0Fee, reserve1, reserve1Fee);

        // Should return (reserve1, reserve1Fee, reserve0, reserve0Fee)
        assertEq(knownReserve, reserve1, "Known reserve should be reserve1");
        assertEq(knownReserveFee, reserve1Fee, "Known reserve fee should be reserve1Fee");
        assertEq(unknownReserve, reserve0, "Unknown reserve should be reserve0");
        assertEq(unknownReserveFee, reserve0Fee, "Unknown reserve fee should be reserve0Fee");
    }

    function test_sortReserves_6Param_differentFees() public view {
        // Test with different fee values
        address knownToken = address(camelotBalancedTokenA);
        address token0 = address(camelotBalancedTokenA);
        uint256 reserve0 = 1000e18;
        uint256 reserve0Fee = 100;
        uint256 reserve1 = 2000e18;
        uint256 reserve1Fee = 200;

        (uint256 knownReserve, uint256 knownReserveFee, uint256 unknownReserve, uint256 unknownReserveFee) =
            ConstProdUtils._sortReserves(knownToken, token0, reserve0, reserve0Fee, reserve1, reserve1Fee);

        // Should return (reserve0, reserve0Fee, reserve1, reserve1Fee)
        assertEq(knownReserve, reserve0, "Known reserve should be reserve0");
        assertEq(knownReserveFee, reserve0Fee, "Known reserve fee should be reserve0Fee");
        assertEq(unknownReserve, reserve1, "Unknown reserve should be reserve1");
        assertEq(unknownReserveFee, reserve1Fee, "Unknown reserve fee should be reserve1Fee");
    }

    function test_sortReserves_6Param_highFees() public view {
        // Test with high fee values
        address knownToken = address(camelotBalancedTokenB);
        address token0 = address(camelotBalancedTokenA);
        uint256 reserve0 = 1000e18;
        uint256 reserve0Fee = 50000; // 50% fee
        uint256 reserve1 = 2000e18;
        uint256 reserve1Fee = 75000; // 75% fee

        (uint256 knownReserve, uint256 knownReserveFee, uint256 unknownReserve, uint256 unknownReserveFee) =
            ConstProdUtils._sortReserves(knownToken, token0, reserve0, reserve0Fee, reserve1, reserve1Fee);

        // Should return (reserve1, reserve1Fee, reserve0, reserve0Fee)
        assertEq(knownReserve, reserve1, "Known reserve should be reserve1");
        assertEq(knownReserveFee, reserve1Fee, "Known reserve fee should be reserve1Fee");
        assertEq(unknownReserve, reserve0, "Unknown reserve should be reserve0");
        assertEq(unknownReserveFee, reserve0Fee, "Unknown reserve fee should be reserve0Fee");
    }
}
