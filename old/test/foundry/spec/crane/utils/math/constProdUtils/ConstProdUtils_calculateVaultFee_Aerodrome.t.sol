// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";
import {TestBase_ConstProdUtils_Aerodrome} from "@crane/test/foundry/spec/utils/math/constProdUtils/TestBase_ConstProdUtils_Aerodrome.sol";
import {Pool} from "contracts/protocols/dexes/aerodrome/v1/Pool.sol";

contract ConstProdUtils_calculateVaultFee_Aerodrome is TestBase_ConstProdUtils_Aerodrome {
    function setUp() public override {
        TestBase_ConstProdUtils_Aerodrome.setUp();
    }

    function test_calculateVaultFee_Aerodrome_balancedPool() public {
        _initializeAerodromeBalancedPools();
        uint256 r0 = aeroBalancedPool.reserve0();
        uint256 r1 = aeroBalancedPool.reserve1();
        uint256 totalSupply = aeroBalancedPool.totalSupply();

        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
            address(aeroBalancedTokenA),
            aeroBalancedPool.token0(),
            r0,
            r1
        );

        uint256 lastK = (reserveA * reserveB) / 2;
        uint256 vaultFee = 500; // 0.5%
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

    function test_calculateVaultFee_Aerodrome_unbalancedPool() public {
        _initializeAerodromeUnbalancedPools();
        uint256 r0 = aeroUnbalancedPool.reserve0();
        uint256 r1 = aeroUnbalancedPool.reserve1();
        uint256 totalSupply = aeroUnbalancedPool.totalSupply();

        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
            address(aeroUnbalancedTokenA),
            aeroUnbalancedPool.token0(),
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

    function test_calculateVaultFee_Aerodrome_extremeUnbalancedPool() public {
        _initializeAerodromeExtremeUnbalancedPools();
        uint256 r0 = aeroExtremeUnbalancedPool.reserve0();
        uint256 r1 = aeroExtremeUnbalancedPool.reserve1();
        uint256 totalSupply = aeroExtremeUnbalancedPool.totalSupply();

        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
            address(aeroExtremeTokenA),
            aeroExtremeUnbalancedPool.token0(),
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

    // _calculateVaultFeeNoNewK variants
    function test_calculateVaultFeeNoNewK_Aerodrome_balancedPool() public {
        _initializeAerodromeBalancedPools();
        uint256 r0 = aeroBalancedPool.reserve0();
        uint256 r1 = aeroBalancedPool.reserve1();
        uint256 totalSupply = aeroBalancedPool.totalSupply();

        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
            address(aeroBalancedTokenA),
            aeroBalancedPool.token0(),
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
        _initializeAerodromeBalancedPools();
        uint256 r0 = aeroBalancedPool.reserve0();
        uint256 r1 = aeroBalancedPool.reserve1();
        uint256 totalSupply = aeroBalancedPool.totalSupply();

        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
            address(aeroBalancedTokenA),
            aeroBalancedPool.token0(),
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
