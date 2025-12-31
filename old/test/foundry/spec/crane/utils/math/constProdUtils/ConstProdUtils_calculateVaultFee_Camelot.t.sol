// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";
import {TestBase_ConstProdUtils_Camelot} from "@crane/test/foundry/spec/utils/math/constProdUtils/TestBase_ConstProdUtils_Camelot.sol";

contract ConstProdUtils_calculateVaultFee_Camelot is TestBase_ConstProdUtils_Camelot {
    function setUp() public override {
        TestBase_ConstProdUtils_Camelot.setUp();
    }

    function test_calculateVaultFee_Camelot_balancedPool() public {
        _initializeCamelotBalancedPools();
        (uint112 r0, uint112 r1, , ) = camelotBalancedPair.getReserves();
        uint256 totalSupply = camelotBalancedPair.totalSupply();

        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
            address(camelotBalancedTokenA),
            camelotBalancedPair.token0(),
            r0,
            r1
        );

        uint256 lastK = (reserveA * reserveB) / 2;
        uint256 vaultFee = 500;
        uint256 feeDenominator = 100000;

        (uint256 expectedFeeAmount, uint256 expectedNewK) = ConstProdUtils._calculateVaultFee(
            reserveA,
            reserveB,
            totalSupply,
            lastK,
            vaultFee,
            feeDenominator
        );

        assertEq(expectedNewK, reserveA * reserveB, "NewK should equal reserveA * reserveB");
        assertGt(expectedFeeAmount, 0, "Fee amount should be greater than 0 when K has grown");
    }

    function test_calculateVaultFeeNoNewK_Camelot_balancedPool() public {
        _initializeCamelotBalancedPools();
        (uint112 r0, uint112 r1, , ) = camelotBalancedPair.getReserves();
        uint256 totalSupply = camelotBalancedPair.totalSupply();

        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
            address(camelotBalancedTokenA),
            camelotBalancedPair.token0(),
            r0,
            r1
        );

        uint256 lastK = (reserveA * reserveB) / 2;
        uint256 vaultFee = 500;
        uint256 feeDenominator = 100000;

        uint256 expectedLpOfYield = ConstProdUtils._calculateVaultFeeNoNewK(
            reserveA,
            reserveB,
            totalSupply,
            lastK,
            vaultFee,
            feeDenominator
        );

        assertGt(expectedLpOfYield, 0, "LP of yield should be greater than 0 when K has grown");
        assertLt(expectedLpOfYield, totalSupply / 10, "LP of yield should be much less than total supply");
    }

    function test_calculateVaultFee_consistency() public {
        _initializeCamelotBalancedPools();
        (uint112 r0, uint112 r1, , ) = camelotBalancedPair.getReserves();
        uint256 totalSupply = camelotBalancedPair.totalSupply();

        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
            address(camelotBalancedTokenA),
            camelotBalancedPair.token0(),
            r0,
            r1
        );

        uint256 lastK = (reserveA * reserveB) / 2;
        uint256 vaultFee = 500;
        uint256 feeDenominator = 100000;

        (uint256 feeAmount, uint256 newK) = ConstProdUtils._calculateVaultFee(
            reserveA,
            reserveB,
            totalSupply,
            lastK,
            vaultFee,
            feeDenominator
        );

        uint256 lpOfYield = ConstProdUtils._calculateVaultFeeNoNewK(
            reserveA,
            reserveB,
            totalSupply,
            lastK,
            vaultFee,
            feeDenominator
        );

        assertEq(feeAmount, lpOfYield, "Both functions should return the same fee amount");
        assertEq(newK, reserveA * reserveB, "NewK should equal reserveA * reserveB");
    }
}
