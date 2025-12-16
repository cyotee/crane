// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";
import {TestBase_ConstProdUtils_Uniswap} from "./TestBase_ConstProdUtils_Uniswap.sol";
import {IUniswapV2Pair} from "contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Pair.sol";
import {UniswapV2Service} from "contracts/protocols/dexes/uniswap/v2/UniswapV2Service.sol";

contract ConstProdUtils_withdrawTargetQuote_Uniswap is TestBase_ConstProdUtils_Uniswap {
    function setUp() public override {
        super.setUp();
    }

    function test_withdrawTargetQuote_Uniswap_BalancedPool() public {
        _initializeUniswapBalancedPools();

        IUniswapV2Pair pair = uniswapBalancedPair;
        (uint112 reserveA, uint112 reserveB,) = pair.getReserves();
        uint256 totalSupply = pair.totalSupply();

        uint256 targetAmount = uint256(reserveA) / 10;
        uint256 expectedLPTokens = ConstProdUtils._withdrawTargetQuote(targetAmount, totalSupply, uint256(reserveA));

        uint256 lpBalance = pair.balanceOf(address(this));
        assertGe(lpBalance, expectedLPTokens, "Must have enough LP tokens for withdrawal");

        uint256 initialBalanceA = uniswapBalancedTokenA.balanceOf(address(this));

        (uint256 amount0, uint256 amount1) = UniswapV2Service._withdrawDirect(pair, expectedLPTokens);

        uint256 actualAmountA = address(uniswapBalancedTokenA) == pair.token0() ? amount0 : amount1;

        assertGe(actualAmountA, targetAmount, "Actual withdrawal should be at least target amount");
        assertEq(uniswapBalancedTokenA.balanceOf(address(this)) - initialBalanceA, actualAmountA, "TokenA balance change should match withdrawal");
    }

    function test_withdrawTargetQuote_Uniswap_UnbalancedPool() public {
        _initializeUniswapUnbalancedPools();

        IUniswapV2Pair pair = uniswapUnbalancedPair;
        (uint112 reserveA, uint112 reserveB,) = pair.getReserves();
        uint256 totalSupply = pair.totalSupply();

        uint256 targetAmount = uint256(reserveA) / 10;
        uint256 expectedLPTokens = ConstProdUtils._withdrawTargetQuote(targetAmount, totalSupply, uint256(reserveA));

        uint256 lpBalance = pair.balanceOf(address(this));
        assertGe(lpBalance, expectedLPTokens, "Must have enough LP tokens for withdrawal");

        uint256 initialBalanceA = uniswapUnbalancedTokenA.balanceOf(address(this));

        (uint256 amount0, uint256 amount1) = UniswapV2Service._withdrawDirect(pair, expectedLPTokens);

        uint256 actualAmountA = address(uniswapUnbalancedTokenA) == pair.token0() ? amount0 : amount1;

        assertGe(actualAmountA, targetAmount, "Actual withdrawal should be at least target amount");
        assertEq(uniswapUnbalancedTokenA.balanceOf(address(this)) - initialBalanceA, actualAmountA, "TokenA balance change should match withdrawal");
    }

    function test_withdrawTargetQuote_Uniswap_ExtremeUnbalancedPool() public {
        _initializeUniswapExtremeUnbalancedPools();

        IUniswapV2Pair pair = uniswapExtremeUnbalancedPair;
        (uint112 reserveA, uint112 reserveB,) = pair.getReserves();
        uint256 totalSupply = pair.totalSupply();

        uint256 targetAmount = uint256(reserveA) / 10;
        uint256 expectedLPTokens = ConstProdUtils._withdrawTargetQuote(targetAmount, totalSupply, uint256(reserveA));

        uint256 lpBalance = pair.balanceOf(address(this));
        assertGe(lpBalance, expectedLPTokens, "Must have enough LP tokens for withdrawal");

        uint256 initialBalanceA = uniswapExtremeTokenA.balanceOf(address(this));

        (uint256 amount0, uint256 amount1) = UniswapV2Service._withdrawDirect(pair, expectedLPTokens);

        uint256 actualAmountA = address(uniswapExtremeTokenA) == pair.token0() ? amount0 : amount1;

        assertGe(actualAmountA, targetAmount, "Actual withdrawal should be at least target amount");
        assertEq(uniswapExtremeTokenA.balanceOf(address(this)) - initialBalanceA, actualAmountA, "TokenA balance change should match withdrawal");
    }

    function test_withdrawTargetQuote_edgeCases() public pure {
        uint256 lpTotalSupply = 1000e18;
        uint256 outRes = 2000e18;

        assertEq(ConstProdUtils._withdrawTargetQuote(0, lpTotalSupply, outRes), 0, "Zero target should return zero LP");
        assertEq(ConstProdUtils._withdrawTargetQuote(100e18, 0, outRes), 0, "Zero LP supply should return zero");
        assertEq(ConstProdUtils._withdrawTargetQuote(100e18, lpTotalSupply, 0), 0, "Zero reserves should return zero");
        assertEq(ConstProdUtils._withdrawTargetQuote(3000e18, lpTotalSupply, outRes), 0, "Target exceeding reserves should return zero");
    }
}
