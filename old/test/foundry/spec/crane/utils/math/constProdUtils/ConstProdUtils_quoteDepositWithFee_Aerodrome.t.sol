// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";
import {TestBase_ConstProdUtils_Aerodrome} from "test/foundry/spec/utils/math/constProdUtils/TestBase_ConstProdUtils_Aerodrome.sol";
import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {BetterIERC20} from "@crane/contracts/interfaces/BetterIERC20.sol";
import {Pool} from "contracts/protocols/dexes/aerodrome/v1/Pool.sol";

contract ConstProdUtils_quoteDepositWithFee_Aerodrome is TestBase_ConstProdUtils_Aerodrome {
    function setUp() public override {
        TestBase_ConstProdUtils_Aerodrome.setUp();
    }

    function _computeAerodromeQuoted(
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 amountB,
        Pool pool
    ) internal view returns (uint256) {
        (uint256 r0, uint256 r1,) = pool.getReserves();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(tokenA, pool.token0(), r0, r1);

        // Aerodrome has no kLast/owner fee in this test harness; disable fee-on
        return ConstProdUtils._quoteDepositWithFee(amountA, amountB, pool.totalSupply(), reserveA, reserveB, 0, 0, false);
    }

    function test_quoteDepositWithFee_Aerodrome_balancedPool_zeroAmounts() public {
        uint256 quoted = ConstProdUtils._quoteDepositWithFee(0, 0, aeroBalancedPool.totalSupply(), 1e22, 1e22, 0, 0, false);
        assertEq(quoted, 0, "Zero amounts should return zero LP tokens");
    }

    function test_quoteDepositWithFee_Aerodrome_balancedPool_verySmall() public {
        _initializeAerodromeBalancedPools();
        uint256 quoted = _computeAerodromeQuoted(address(aeroBalancedTokenA), address(aeroBalancedTokenB), 1, 1, aeroBalancedPool);
        assertTrue(quoted > 0, "Very small amounts should still produce LP tokens");
    }

    function test_quoteDepositWithFee_Aerodrome_balancedPool_depositMatchesQuoted() public {
        _initializeAerodromeBalancedPools();

        uint256 amountA = 1000e18;
        uint256 amountB = 1000e18;

        uint256 quoted = _computeAerodromeQuoted(address(aeroBalancedTokenA), address(aeroBalancedTokenB), amountA, amountB, aeroBalancedPool);

        aeroBalancedTokenA.mint(address(this), amountA);
        aeroBalancedTokenB.mint(address(this), amountB);
        aeroBalancedTokenA.approve(address(router), amountA);
        aeroBalancedTokenB.approve(address(router), amountB);

        uint256 initialBalance = aeroBalancedPool.balanceOf(address(this));
        router.addLiquidity(address(aeroBalancedTokenA), address(aeroBalancedTokenB), false, amountA, amountB, 1, 1, address(this), block.timestamp);
        uint256 finalBalance = aeroBalancedPool.balanceOf(address(this));
        uint256 actual = finalBalance - initialBalance;

        assertEq(quoted, actual, "quoted == actual LP tokens");
    }
}
