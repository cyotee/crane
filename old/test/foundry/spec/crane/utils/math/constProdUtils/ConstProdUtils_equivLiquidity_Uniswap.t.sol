// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {betterconsole as console} from "contracts/utils/vm/foundry/tools/betterconsole.sol";
import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";
import {TestBase_ConstProdUtils_Uniswap} from "@crane/test/foundry/spec/utils/math/constProdUtils/TestBase_ConstProdUtils_Uniswap.sol";

contract ConstProdUtils_equivLiquidity_Uniswap_Test is TestBase_ConstProdUtils_Uniswap {
    function setUp() public override {
        TestBase_ConstProdUtils_Uniswap.setUp();
    }

    function test_equivLiquidity_Uniswap_BalancedPool() public {
        _initializeUniswapBalancedPools();
        (uint112 reserve0, uint112 reserve1,) = uniswapBalancedPair.getReserves();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
            address(uniswapBalancedTokenA), uniswapBalancedPair.token0(), reserve0, reserve1
        );

        uint256 amountA = reserveA;
        uint256 expectedAmountB = ConstProdUtils._equivLiquidity(amountA, reserveA, reserveB);
        assertEq(expectedAmountB, reserveB, "Calculated equivalent liquidity should match actual pool reserve");
    }

    function test_equivLiquidity_Uniswap_UnbalancedPool() public {
        _initializeUniswapUnbalancedPools();
        (uint112 reserve0, uint112 reserve1,) = uniswapUnbalancedPair.getReserves();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
            address(uniswapUnbalancedTokenA), uniswapUnbalancedPair.token0(), reserve0, reserve1
        );

        uint256 amountA = reserveA;
        uint256 expectedAmountB = ConstProdUtils._equivLiquidity(amountA, reserveA, reserveB);
        assertEq(expectedAmountB, reserveB, "Calculated equivalent liquidity should match actual pool reserve");
    }

    function test_equivLiquidity_Uniswap_ExtremeUnbalancedPool() public {
        _initializeUniswapExtremeUnbalancedPools();
        (uint112 reserve0, uint112 reserve1,) = uniswapExtremeUnbalancedPair.getReserves();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
            address(uniswapExtremeTokenA), uniswapExtremeUnbalancedPair.token0(), reserve0, reserve1
        );

        uint256 amountA = reserveA;
        uint256 expectedAmountB = ConstProdUtils._equivLiquidity(amountA, reserveA, reserveB);
        assertEq(expectedAmountB, reserveB, "Calculated equivalent liquidity should match actual pool reserve");
    }
}
