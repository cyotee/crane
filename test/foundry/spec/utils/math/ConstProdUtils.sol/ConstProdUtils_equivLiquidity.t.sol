// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {betterconsole as console} from "contracts/utils/vm/foundry/tools/betterconsole.sol";
import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";
import {TestBase_ConstProdUtils} from "@crane/test/foundry/spec/utils/math/ConstProdUtils.sol/TestBase_ConstProdUtils.sol";

contract ConstProdUtils_equivLiquidity_Test is TestBase_ConstProdUtils {
    function setUp() public override {
        TestBase_ConstProdUtils.setUp();
    }

    function test_equivLiquidity_Camelot_balancedPool() public {
        _initializeCamelotBalancedPools();
        // Get balanced pool reserves
        (uint112 reserve0, uint112 reserve1, uint16 token0Fee, uint16 token1Fee) = camelotBalancedPair.getReserves();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
            address(camelotBalancedTokenA), camelotBalancedPair.token0(), reserve0, reserve1
        );

        // Use full reserve amount as input
        uint256 amountA = reserveA;

        // Calculate expected equivalent liquidity
        uint256 expectedAmountB = ConstProdUtils._equivLiquidity(amountA, reserveA, reserveB);

        // Validate against actual pool state
        assertEq(expectedAmountB, reserveB, "Calculated equivalent liquidity should match actual pool reserve");
    }

    function test_equivLiquidity_Camelot_unbalancedPool() public {
        _initializeCamelotUnbalancedPools();
        // Get unbalanced pool reserves
        (uint112 reserve0, uint112 reserve1, uint16 token0Fee, uint16 token1Fee) = camelotUnbalancedPair.getReserves();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
            address(camelotUnbalancedTokenA), camelotUnbalancedPair.token0(), reserve0, reserve1
        );

        // Use full reserve amount as input
        uint256 amountA = reserveA;

        // Calculate expected equivalent liquidity
        uint256 expectedAmountB = ConstProdUtils._equivLiquidity(amountA, reserveA, reserveB);

        // Validate against actual pool state
        assertEq(expectedAmountB, reserveB, "Calculated equivalent liquidity should match actual pool reserve");
    }

    function test_equivLiquidity_Camelot_extremeUnbalancedPool() public {
        _initializeCamelotExtremeUnbalancedPools();
        // Get extreme unbalanced pool reserves
        (uint112 reserve0, uint112 reserve1, uint16 token0Fee, uint16 token1Fee) =
            camelotExtremeUnbalancedPair.getReserves();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
            address(camelotExtremeTokenA), camelotExtremeUnbalancedPair.token0(), reserve0, reserve1
        );

        // Use full reserve amount as input
        uint256 amountA = reserveA;

        // Calculate expected equivalent liquidity
        uint256 expectedAmountB = ConstProdUtils._equivLiquidity(amountA, reserveA, reserveB);

        // Validate against actual pool state
        assertEq(expectedAmountB, reserveB, "Calculated equivalent liquidity should match actual pool reserve");
    }

    function test_equivLiquidity_Uniswap_BalancedPool() public {
        _initializeUniswapBalancedPools();
        // Get balanced Uniswap pool reserves
        (uint112 reserve0, uint112 reserve1,) = uniswapBalancedPair.getReserves();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
            address(uniswapBalancedTokenA), uniswapBalancedPair.token0(), reserve0, reserve1
        );

        // Use full reserve amount as input
        uint256 amountA = reserveA;

        // Calculate expected equivalent liquidity
        uint256 expectedAmountB = ConstProdUtils._equivLiquidity(amountA, reserveA, reserveB);

        // Validate against actual pool state
        assertEq(expectedAmountB, reserveB, "Calculated equivalent liquidity should match actual pool reserve");
    }

    function test_equivLiquidity_Uniswap_UnbalancedPool() public {
        _initializeUniswapUnbalancedPools();
        // Get unbalanced Uniswap pool reserves
        (uint112 reserve0, uint112 reserve1,) = uniswapUnbalancedPair.getReserves();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
            address(uniswapUnbalancedTokenA), uniswapUnbalancedPair.token0(), reserve0, reserve1
        );

        // Use full reserve amount as input
        uint256 amountA = reserveA;

        // Calculate expected equivalent liquidity
        uint256 expectedAmountB = ConstProdUtils._equivLiquidity(amountA, reserveA, reserveB);

        // Validate against actual pool state
        assertEq(expectedAmountB, reserveB, "Calculated equivalent liquidity should match actual pool reserve");
    }

    function test_equivLiquidity_Uniswap_ExtremeUnbalancedPool() public {
        _initializeUniswapExtremeUnbalancedPools();
        // Get extreme unbalanced Uniswap pool reserves
        (uint112 reserve0, uint112 reserve1,) = uniswapExtremeUnbalancedPair.getReserves();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
            address(uniswapExtremeTokenA), uniswapExtremeUnbalancedPair.token0(), reserve0, reserve1
        );

        // Use full reserve amount as input
        uint256 amountA = reserveA;

        // Calculate expected equivalent liquidity
        uint256 expectedAmountB = ConstProdUtils._equivLiquidity(amountA, reserveA, reserveB);

        // Validate against actual pool state
        assertEq(expectedAmountB, reserveB, "Calculated equivalent liquidity should match actual pool reserve");
    }
}
