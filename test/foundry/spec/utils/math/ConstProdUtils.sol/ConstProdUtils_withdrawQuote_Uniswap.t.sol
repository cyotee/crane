// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {betterconsole as console} from "contracts/utils/vm/foundry/tools/betterconsole.sol";
import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";
import {UniswapV2Service} from "contracts/protocols/dexes/uniswap/v2/UniswapV2Service.sol";
import {TestBase_ConstProdUtils_Uniswap} from "@crane/test/foundry/spec/utils/math/ConstProdUtils.sol/TestBase_ConstProdUtils_Uniswap.sol";

contract ConstProdUtils_withdrawQuote_Uniswap_Test is TestBase_ConstProdUtils_Uniswap {
    function setUp() public override {
        TestBase_ConstProdUtils_Uniswap.setUp();
        _initializeUniswapBalancedPools();
        _initializeUniswapUnbalancedPools();
        _initializeUniswapExtremeUnbalancedPools();
    }

    function test_withdrawQuote_Uniswap_BalancedPool() public {
        (uint112 reserve0, uint112 reserve1,) = uniswapBalancedPair.getReserves();
        uint256 totalSupply = uniswapBalancedPair.totalSupply();

        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
            address(uniswapBalancedTokenA), uniswapBalancedPair.token0(), reserve0, reserve1
        );

        uint256 lpBalance = uniswapBalancedPair.balanceOf(address(this));
        uint256 lpTokensToWithdraw = lpBalance / 2;

        (uint256 expectedAmountA, uint256 expectedAmountB) =
            ConstProdUtils._withdrawQuote(lpTokensToWithdraw, totalSupply, reserveA, reserveB);

        uint256 initialBalanceA = uniswapBalancedTokenA.balanceOf(address(this));
        uint256 initialBalanceB = uniswapBalancedTokenB.balanceOf(address(this));

        (uint256 amount0, uint256 amount1) = UniswapV2Service._withdrawDirect(uniswapBalancedPair, lpTokensToWithdraw);

        uint256 actualAmountA = address(uniswapBalancedTokenA) == uniswapBalancedPair.token0() ? amount0 : amount1;
        uint256 actualAmountB = address(uniswapBalancedTokenA) == uniswapBalancedPair.token0() ? amount1 : amount0;

        assertEq(actualAmountA, expectedAmountA, "TokenA amounts should match");
        assertEq(actualAmountB, expectedAmountB, "TokenB amounts should match");

        assertEq(
            uniswapBalancedTokenA.balanceOf(address(this)) - initialBalanceA,
            actualAmountA,
            "TokenA balance change should match withdrawal"
        );
        assertEq(
            uniswapBalancedTokenB.balanceOf(address(this)) - initialBalanceB,
            actualAmountB,
            "TokenB balance change should match withdrawal"
        );

        console.log("_withdrawQuote Uniswap balanced pool test passed:");
    }

    function test_withdrawQuote_Uniswap_UnbalancedPool() public {
        (uint112 reserve0, uint112 reserve1,) = uniswapUnbalancedPair.getReserves();
        uint256 totalSupply = uniswapUnbalancedPair.totalSupply();

        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
            address(uniswapUnbalancedTokenA), uniswapUnbalancedPair.token0(), reserve0, reserve1
        );

        uint256 lpBalance = uniswapUnbalancedPair.balanceOf(address(this));
        uint256 lpTokensToWithdraw = lpBalance / 2;

        (uint256 expectedAmountA, uint256 expectedAmountB) =
            ConstProdUtils._withdrawQuote(lpTokensToWithdraw, totalSupply, reserveA, reserveB);

        uint256 initialBalanceA = uniswapUnbalancedTokenA.balanceOf(address(this));
        uint256 initialBalanceB = uniswapUnbalancedTokenB.balanceOf(address(this));

        (uint256 amount0, uint256 amount1) = UniswapV2Service._withdrawDirect(uniswapUnbalancedPair, lpTokensToWithdraw);

        uint256 actualAmountA = address(uniswapUnbalancedTokenA) == uniswapUnbalancedPair.token0() ? amount0 : amount1;
        uint256 actualAmountB = address(uniswapUnbalancedTokenA) == uniswapUnbalancedPair.token0() ? amount1 : amount0;

        assertEq(actualAmountA, expectedAmountA, "TokenA amounts should match");
        assertEq(actualAmountB, expectedAmountB, "TokenB amounts should match");

        assertEq(
            uniswapUnbalancedTokenA.balanceOf(address(this)) - initialBalanceA,
            actualAmountA,
            "TokenA balance change should match withdrawal"
        );
        assertEq(
            uniswapUnbalancedTokenB.balanceOf(address(this)) - initialBalanceB,
            actualAmountB,
            "TokenB balance change should match withdrawal"
        );

        console.log("_withdrawQuote Uniswap unbalanced pool test passed:");
    }

    function test_withdrawQuote_Uniswap_ExtremeUnbalancedPool() public {
        (uint112 reserve0, uint112 reserve1,) = uniswapExtremeUnbalancedPair.getReserves();
        uint256 totalSupply = uniswapExtremeUnbalancedPair.totalSupply();

        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
            address(uniswapExtremeTokenA), uniswapExtremeUnbalancedPair.token0(), reserve0, reserve1
        );

        uint256 lpBalance = uniswapExtremeUnbalancedPair.balanceOf(address(this));
        uint256 lpTokensToWithdraw = lpBalance / 2;

        (uint256 expectedAmountA, uint256 expectedAmountB) =
            ConstProdUtils._withdrawQuote(lpTokensToWithdraw, totalSupply, reserveA, reserveB);

        uint256 initialBalanceA = uniswapExtremeTokenA.balanceOf(address(this));
        uint256 initialBalanceB = uniswapExtremeTokenB.balanceOf(address(this));

        (uint256 amount0, uint256 amount1) = UniswapV2Service._withdrawDirect(uniswapExtremeUnbalancedPair, lpTokensToWithdraw);

        uint256 actualAmountA = address(uniswapExtremeTokenA) == uniswapExtremeUnbalancedPair.token0() ? amount0 : amount1;
        uint256 actualAmountB = address(uniswapExtremeTokenA) == uniswapExtremeUnbalancedPair.token0() ? amount1 : amount0;

        assertEq(actualAmountA, expectedAmountA, "TokenA amounts should match");
        assertEq(actualAmountB, expectedAmountB, "TokenB amounts should match");

        assertEq(
            uniswapExtremeTokenA.balanceOf(address(this)) - initialBalanceA,
            actualAmountA,
            "TokenA balance change should match withdrawal"
        );
        assertEq(
            uniswapExtremeTokenB.balanceOf(address(this)) - initialBalanceB,
            actualAmountB,
            "TokenB balance change should match withdrawal"
        );

        console.log("_withdrawQuote Uniswap extreme unbalanced pool test passed:");
    }
}
