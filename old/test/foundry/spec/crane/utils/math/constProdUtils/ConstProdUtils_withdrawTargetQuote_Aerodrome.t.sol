// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {TestBase_ConstProdUtils_Aerodrome} from "./TestBase_ConstProdUtils_Aerodrome.sol";
import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";
import {Pool} from "@crane/contracts/protocols/dexes/aerodrome/v1/Pool.sol";
import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";

contract ConstProdUtils_withdrawTargetQuote_Aerodrome is TestBase_ConstProdUtils_Aerodrome {
    function setUp() public override {
        super.setUp();
    }

    function test_withdrawTargetQuote_Aerodrome_balancedPool() public {
        _initializeAerodromeBalancedPools();

        Pool pair = aeroBalancedPool;
        (uint256 reserve0, uint256 reserve1,) = pair.getReserves();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(address(aeroBalancedTokenA), pair.token0(), reserve0, reserve1);
        uint256 totalSupply = pair.totalSupply();

        uint256 targetAmount = reserveA / 10; // 10% of reserve A
        uint256 expectedLPTokens = ConstProdUtils._withdrawTargetQuote(targetAmount, totalSupply, reserveA);

        uint256 lpBalance = pair.balanceOf(address(this));
        assertGe(lpBalance, expectedLPTokens, "Must have enough LP tokens for withdrawal");

        uint256 initialBalanceA = aeroBalancedTokenA.balanceOf(address(this));

        pair.transfer(address(pair), expectedLPTokens);
        (uint256 amount0, uint256 amount1) = pair.burn(address(this));
        uint256 actualAmountA = address(aeroBalancedTokenA) == pair.token0() ? amount0 : amount1;

        assertGe(actualAmountA, targetAmount, "Actual withdrawal should be at least target amount");
        assertEq(aeroBalancedTokenA.balanceOf(address(this)) - initialBalanceA, actualAmountA, "TokenA balance change should match withdrawal");
    }

    function test_withdrawTargetQuote_Aerodrome_unbalancedPool() public {
        _initializeAerodromeUnbalancedPools();

        Pool pair = aeroUnbalancedPool;
        (uint256 reserve0, uint256 reserve1,) = pair.getReserves();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(address(aeroUnbalancedTokenA), pair.token0(), reserve0, reserve1);
        uint256 totalSupply = pair.totalSupply();

        uint256 targetAmount = reserveA / 10;
        uint256 expectedLPTokens = ConstProdUtils._withdrawTargetQuote(targetAmount, totalSupply, reserveA);

        uint256 lpBalance = pair.balanceOf(address(this));
        assertGe(lpBalance, expectedLPTokens, "Must have enough LP tokens for withdrawal");

        uint256 initialBalanceA = aeroUnbalancedTokenA.balanceOf(address(this));

        pair.transfer(address(pair), expectedLPTokens);
        (uint256 amount0, uint256 amount1) = pair.burn(address(this));
        uint256 actualAmountA = address(aeroUnbalancedTokenA) == pair.token0() ? amount0 : amount1;

        assertGe(actualAmountA, targetAmount, "Actual withdrawal should be at least target amount");
        assertEq(aeroUnbalancedTokenA.balanceOf(address(this)) - initialBalanceA, actualAmountA, "TokenA balance change should match withdrawal");
    }

    function test_withdrawTargetQuote_Aerodrome_extremeUnbalancedPool() public {
        _initializeAerodromeExtremeUnbalancedPools();

        Pool pair = aeroExtremeUnbalancedPool;
        (uint256 reserve0, uint256 reserve1,) = pair.getReserves();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(address(aeroExtremeTokenA), pair.token0(), reserve0, reserve1);
        uint256 totalSupply = pair.totalSupply();

        uint256 targetAmount = reserveA / 1000; // 0.1%
        uint256 expectedLPTokens = ConstProdUtils._withdrawTargetQuote(targetAmount, totalSupply, reserveA);

        uint256 lpBalance = pair.balanceOf(address(this));
        assertGe(lpBalance, expectedLPTokens, "Must have enough LP tokens for withdrawal");

        uint256 initialBalanceA = aeroExtremeTokenA.balanceOf(address(this));

        pair.transfer(address(pair), expectedLPTokens);
        (uint256 amount0, uint256 amount1) = pair.burn(address(this));
        uint256 actualAmountA = address(aeroExtremeTokenA) == pair.token0() ? amount0 : amount1;

        assertGe(actualAmountA, targetAmount, "Actual withdrawal should be at least target amount");
        assertEq(aeroExtremeTokenA.balanceOf(address(this)) - initialBalanceA, actualAmountA, "TokenA balance change should match withdrawal");
    }
}
