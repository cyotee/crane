// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";
import {TestBase_ConstProdUtils_Aerodrome} from "./TestBase_ConstProdUtils_Aerodrome.sol";
import {ERC20PermitMintableStub} from "contracts/tokens/ERC20/ERC20PermitMintableStub.sol";
import {Pool} from "contracts/protocols/dexes/aerodrome/v1/stubs/Pool.sol";

contract ConstProdUtils_withdrawQuote_Aerodrome is TestBase_ConstProdUtils_Aerodrome {
    function setUp() public override {
        TestBase_ConstProdUtils_Aerodrome.setUp();
        _initializeAerodromeBalancedPools();
        _initializeAerodromeUnbalancedPools();
        _initializeAerodromeExtremeUnbalancedPools();
    }

    function test_withdrawQuote_Aerodrome_balancedPool() public {
        Pool pair = aeroBalancedPool;
        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        uint256 totalSupply = pair.totalSupply();

        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
            address(aeroBalancedTokenA), pair.token0(), reserve0, reserve1
        );

        uint256 lpBalance = pair.balanceOf(address(this));
        uint256 lpTokensToWithdraw = lpBalance / 2;

        (uint256 expectedAmountA, uint256 expectedAmountB) =
            ConstProdUtils._withdrawQuote(lpTokensToWithdraw, totalSupply, reserveA, reserveB);

        uint256 initialBalanceA = aeroBalancedTokenA.balanceOf(address(this));
        uint256 initialBalanceB = aeroBalancedTokenB.balanceOf(address(this));

        pair.transfer(address(pair), lpTokensToWithdraw);
        (uint256 amount0, uint256 amount1) = pair.burn(address(this));

        uint256 actualAmountA = address(aeroBalancedTokenA) == pair.token0() ? amount0 : amount1;
        uint256 actualAmountB = address(aeroBalancedTokenA) == pair.token0() ? amount1 : amount0;

        assertEq(actualAmountA, expectedAmountA, "TokenA amounts should match");
        assertEq(actualAmountB, expectedAmountB, "TokenB amounts should match");

        assertEq(
            aeroBalancedTokenA.balanceOf(address(this)) - initialBalanceA,
            actualAmountA,
            "TokenA balance change should match withdrawal"
        );
        assertEq(
            aeroBalancedTokenB.balanceOf(address(this)) - initialBalanceB,
            actualAmountB,
            "TokenB balance change should match withdrawal"
        );
    }

    function test_withdrawQuote_Aerodrome_unbalancedPool() public {
        Pool pair = aeroUnbalancedPool;
        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        uint256 totalSupply = pair.totalSupply();

        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
            address(aeroUnbalancedTokenA), pair.token0(), reserve0, reserve1
        );

        uint256 lpBalance = pair.balanceOf(address(this));
        uint256 lpTokensToWithdraw = lpBalance / 2;

        (uint256 expectedAmountA, uint256 expectedAmountB) =
            ConstProdUtils._withdrawQuote(lpTokensToWithdraw, totalSupply, reserveA, reserveB);

        uint256 initialBalanceA = aeroUnbalancedTokenA.balanceOf(address(this));
        uint256 initialBalanceB = aeroUnbalancedTokenB.balanceOf(address(this));

        pair.transfer(address(pair), lpTokensToWithdraw);
        (uint256 amount0, uint256 amount1) = pair.burn(address(this));

        uint256 actualAmountA = address(aeroUnbalancedTokenA) == pair.token0() ? amount0 : amount1;
        uint256 actualAmountB = address(aeroUnbalancedTokenA) == pair.token0() ? amount1 : amount0;

        assertEq(actualAmountA, expectedAmountA, "TokenA amounts should match");
        assertEq(actualAmountB, expectedAmountB, "TokenB amounts should match");

        assertEq(
            aeroUnbalancedTokenA.balanceOf(address(this)) - initialBalanceA,
            actualAmountA,
            "TokenA balance change should match withdrawal"
        );
        assertEq(
            aeroUnbalancedTokenB.balanceOf(address(this)) - initialBalanceB,
            actualAmountB,
            "TokenB balance change should match withdrawal"
        );
    }

    function test_withdrawQuote_Aerodrome_extremePool() public {
        Pool pair = aeroExtremeUnbalancedPool;
        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        uint256 totalSupply = pair.totalSupply();

        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
            address(aeroExtremeTokenA), pair.token0(), reserve0, reserve1
        );

        uint256 lpBalance = pair.balanceOf(address(this));
        uint256 lpTokensToWithdraw = lpBalance / 2;

        (uint256 expectedAmountA, uint256 expectedAmountB) =
            ConstProdUtils._withdrawQuote(lpTokensToWithdraw, totalSupply, reserveA, reserveB);

        uint256 initialBalanceA = aeroExtremeTokenA.balanceOf(address(this));
        uint256 initialBalanceB = aeroExtremeTokenB.balanceOf(address(this));

        pair.transfer(address(pair), lpTokensToWithdraw);
        (uint256 amount0, uint256 amount1) = pair.burn(address(this));

        uint256 actualAmountA = address(aeroExtremeTokenA) == pair.token0() ? amount0 : amount1;
        uint256 actualAmountB = address(aeroExtremeTokenA) == pair.token0() ? amount1 : amount0;

        assertEq(actualAmountA, expectedAmountA, "TokenA amounts should match");
        assertEq(actualAmountB, expectedAmountB, "TokenB amounts should match");

        assertEq(
            aeroExtremeTokenA.balanceOf(address(this)) - initialBalanceA,
            actualAmountA,
            "TokenA balance change should match withdrawal"
        );
        assertEq(
            aeroExtremeTokenB.balanceOf(address(this)) - initialBalanceB,
            actualAmountB,
            "TokenB balance change should match withdrawal"
        );
    }
}
