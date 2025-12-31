// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {
    TestBase_UniswapV2Utils
} from "test/foundry/spec/crane/protocols/dexes/uniswap/v2/utils/TestBase_UniswapV2Utils.sol";
import {UniswapV2Utils} from "contracts/crane/protocols/dexes/uniswap/v2/utils/UniswapV2Utils.sol";

contract Test_UniswapV2Utils_sortReserves is TestBase_UniswapV2Utils {
    function setUp() public override {
        super.setUp();
        _initializePools();
    }

    // Test 4-parameter _sortReserves function using Uniswap pools

    function test_sortReserves_4Param_balancedPool_knownTokenIsToken0() public view {
        // Test when knownToken is token0 in balanced pool
        (uint112 reserve0, uint112 reserve1,) = uniswapBalancedPair.getReserves();
        address token0 = uniswapBalancedPair.token0();
        address knownToken = token0;

        (uint256 knownReserve, uint256 unknownReserve) =
            UniswapV2Utils._sortReserves(knownToken, token0, reserve0, reserve1);

        // When knownToken == token0, should return (reserve0, reserve1)
        assertEq(knownReserve, reserve0, "Known reserve should be reserve0");
        assertEq(unknownReserve, reserve1, "Unknown reserve should be reserve1");
    }

    function test_sortReserves_4Param_balancedPool_knownTokenIsToken1() public view {
        // Test when knownToken is token1 in balanced pool
        (uint112 reserve0, uint112 reserve1,) = uniswapBalancedPair.getReserves();
        address token0 = uniswapBalancedPair.token0();
        address token1 = uniswapBalancedPair.token1();
        address knownToken = token1;

        (uint256 knownReserve, uint256 unknownReserve) =
            UniswapV2Utils._sortReserves(knownToken, token0, reserve0, reserve1);

        // When knownToken != token0, should return (reserve1, reserve0)
        assertEq(knownReserve, reserve1, "Known reserve should be reserve1");
        assertEq(unknownReserve, reserve0, "Unknown reserve should be reserve0");
    }

    function test_sortReserves_4Param_unbalancedPool_knownTokenIsToken0() public view {
        // Test when knownToken is token0 in unbalanced pool
        (uint112 reserve0, uint112 reserve1,) = uniswapUnbalancedPair.getReserves();
        address token0 = uniswapUnbalancedPair.token0();
        address knownToken = token0;

        (uint256 knownReserve, uint256 unknownReserve) =
            UniswapV2Utils._sortReserves(knownToken, token0, reserve0, reserve1);

        // When knownToken == token0, should return (reserve0, reserve1)
        assertEq(knownReserve, reserve0, "Known reserve should be reserve0");
        assertEq(unknownReserve, reserve1, "Unknown reserve should be reserve1");
    }

    function test_sortReserves_4Param_unbalancedPool_knownTokenIsToken1() public view {
        // Test when knownToken is token1 in unbalanced pool
        (uint112 reserve0, uint112 reserve1,) = uniswapUnbalancedPair.getReserves();
        address token0 = uniswapUnbalancedPair.token0();
        address token1 = uniswapUnbalancedPair.token1();
        address knownToken = token1;

        (uint256 knownReserve, uint256 unknownReserve) =
            UniswapV2Utils._sortReserves(knownToken, token0, reserve0, reserve1);

        // When knownToken != token0, should return (reserve1, reserve0)
        assertEq(knownReserve, reserve1, "Known reserve should be reserve1");
        assertEq(unknownReserve, reserve0, "Unknown reserve should be reserve0");
    }

    function test_sortReserves_4Param_extremeUnbalancedPool_knownTokenIsToken0() public view {
        // Test when knownToken is token0 in extreme unbalanced pool
        (uint112 reserve0, uint112 reserve1,) = uniswapExtremeUnbalancedPair.getReserves();
        address token0 = uniswapExtremeUnbalancedPair.token0();
        address knownToken = token0;

        (uint256 knownReserve, uint256 unknownReserve) =
            UniswapV2Utils._sortReserves(knownToken, token0, reserve0, reserve1);

        // When knownToken == token0, should return (reserve0, reserve1)
        assertEq(knownReserve, reserve0, "Known reserve should be reserve0");
        assertEq(unknownReserve, reserve1, "Unknown reserve should be reserve1");
    }

    function test_sortReserves_4Param_extremeUnbalancedPool_knownTokenIsToken1() public view {
        // Test when knownToken is token1 in extreme unbalanced pool
        (uint112 reserve0, uint112 reserve1,) = uniswapExtremeUnbalancedPair.getReserves();
        address token0 = uniswapExtremeUnbalancedPair.token0();
        address token1 = uniswapExtremeUnbalancedPair.token1();
        address knownToken = token1;

        (uint256 knownReserve, uint256 unknownReserve) =
            UniswapV2Utils._sortReserves(knownToken, token0, reserve0, reserve1);

        // When knownToken != token0, should return (reserve1, reserve0)
        assertEq(knownReserve, reserve1, "Known reserve should be reserve1");
        assertEq(unknownReserve, reserve0, "Unknown reserve should be reserve0");
    }
}
