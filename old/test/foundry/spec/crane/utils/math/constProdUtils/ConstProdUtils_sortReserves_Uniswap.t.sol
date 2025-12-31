// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";
import {TestBase_ConstProdUtils_Uniswap} from "./TestBase_ConstProdUtils_Uniswap.sol";

contract ConstProdUtils_sortReserves_Uniswap is TestBase_ConstProdUtils_Uniswap {
    function setUp() public override {
        super.setUp();
        _initializeUniswapBalancedPools();
    }

    function test_sortReserves_4Param_knownTokenIsToken0() public view {
        address knownToken = address(uniswapBalancedTokenA);
        address token0 = address(uniswapBalancedTokenA);
        uint256 reserve0 = 1000e18;
        uint256 reserve1 = 2000e18;

        (uint256 knownReserve, uint256 unknownReserve) = ConstProdUtils._sortReserves(knownToken, token0, reserve0, reserve1);

        assertEq(knownReserve, reserve0);
        assertEq(unknownReserve, reserve1);
    }

    function test_sortReserves_4Param_knownTokenIsToken1() public view {
        address knownToken = address(uniswapBalancedTokenB);
        address token0 = address(uniswapBalancedTokenA);
        uint256 reserve0 = 1000e18;
        uint256 reserve1 = 2000e18;

        (uint256 knownReserve, uint256 unknownReserve) = ConstProdUtils._sortReserves(knownToken, token0, reserve0, reserve1);

        assertEq(knownReserve, reserve1);
        assertEq(unknownReserve, reserve0);
    }

    function test_sortReserves_6Param_knownTokenIsToken0() public view {
        address knownToken = address(uniswapBalancedTokenA);
        address token0 = address(uniswapBalancedTokenA);
        uint256 reserve0 = 1000e18;
        uint256 reserve0Fee = 0;
        uint256 reserve1 = 2000e18;
        uint256 reserve1Fee = 0;

        (uint256 knownReserve, uint256 knownReserveFee, uint256 unknownReserve, uint256 unknownReserveFee) =
            ConstProdUtils._sortReserves(knownToken, token0, reserve0, reserve0Fee, reserve1, reserve1Fee);

        assertEq(knownReserve, reserve0);
        assertEq(knownReserveFee, reserve0Fee);
        assertEq(unknownReserve, reserve1);
        assertEq(unknownReserveFee, reserve1Fee);
    }

    function test_sortReserves_6Param_knownTokenIsToken1() public view {
        address knownToken = address(uniswapBalancedTokenB);
        address token0 = address(uniswapBalancedTokenA);
        uint256 reserve0 = 1000e18;
        uint256 reserve0Fee = 0;
        uint256 reserve1 = 2000e18;
        uint256 reserve1Fee = 0;

        (uint256 knownReserve, uint256 knownReserveFee, uint256 unknownReserve, uint256 unknownReserveFee) =
            ConstProdUtils._sortReserves(knownToken, token0, reserve0, reserve0Fee, reserve1, reserve1Fee);

        assertEq(knownReserve, reserve1);
        assertEq(knownReserveFee, reserve1Fee);
        assertEq(unknownReserve, reserve0);
        assertEq(unknownReserveFee, reserve0Fee);
    }
}
