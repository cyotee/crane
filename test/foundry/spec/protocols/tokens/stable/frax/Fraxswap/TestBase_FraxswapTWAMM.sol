// SPDX-License-Identifier: ISC
pragma solidity ^0.8.35;

/// @notice TWAMM helpers for Fraxswap pair tests.

import {TestBase_FraxBAMM} from "../BAMM/TestBase_FraxBAMM.sol";
import {FraxswapFactory} from "@crane/contracts/protocols/tokens/stable/frax/Fraxswap/core/FraxswapFactory.sol";
import {LongTermOrdersLib} from "@crane/contracts/protocols/tokens/stable/frax/Fraxswap/twamm/LongTermOrders.sol";
import {IERC20} from "@crane/contracts/external/openzeppelin-contracts/token/ERC20/IERC20.sol";

abstract contract TestBase_FraxswapTWAMM is TestBase_FraxBAMM {
    uint256 internal constant ORDER_TIME_INTERVAL = 3600;
    uint256 internal constant MAX_UINT112 = type(uint112).max;

    address internal user2;
    address internal user3;

    FraxswapFactory internal factory;

    uint256 internal constant TWAMM_INITIAL_LIQ = 100_000e18;
    uint256 internal constant TWAMM_AMOUNT_IN = 10e18;
    uint256 internal constant TWAMM_FEE_BPS = 30;
    uint256 internal constant TWAMM_FEE_MULT = 10_000 - TWAMM_FEE_BPS;

    function _twammSetUp() internal {
        _fraxBammSetUp();
        user2 = makeAddr("twammUser2");
        user3 = makeAddr("twammUser3");
        _createPair(9970);
        factory = FraxswapFactory(pair.factory());
    }

    function _seedLiquidity(uint256 amount) internal {
        _mintPairLiquidity(amount, amount);
    }

    function _fund(address user, uint256 amount) internal {
        token0.transfer(user, amount);
        token1.transfer(user, amount);
    }

    function _fundToken0(address user, uint256 amount) internal {
        token0.transfer(user, amount);
    }

    function _fundToken1(address user, uint256 amount) internal {
        token1.transfer(user, amount);
    }

    function _alignTimestamp(uint256 offset) internal {
        uint256 t = block.timestamp;
        uint256 target = t - (t % ORDER_TIME_INTERVAL) + (2 * ORDER_TIME_INTERVAL) - offset;
        vm.warp(target);
    }

    function _mineTimeIntervals(uint256 intervals) internal {
        vm.warp(block.timestamp + intervals * ORDER_TIME_INTERVAL + 1);
    }

    function _executeVirtualOrders(uint256 timestamp) internal {
        pair.executeVirtualOrders(timestamp);
    }

    function _longTermSwap0To1(address user, uint256 amountIn, uint256 intervals) internal returns (uint256 orderId) {
        vm.startPrank(user);
        IERC20(address(token0)).approve(address(pair), amountIn);
        orderId = pair.longTermSwapFrom0To1(amountIn, intervals);
        vm.stopPrank();
    }

    function _longTermSwap1To0(address user, uint256 amountIn, uint256 intervals) internal returns (uint256 orderId) {
        vm.startPrank(user);
        IERC20(address(token1)).approve(address(pair), amountIn);
        orderId = pair.longTermSwapFrom1To0(amountIn, intervals);
        vm.stopPrank();
    }

    function _orderAt(address user, uint256 orderId) internal view returns (LongTermOrdersLib.Order memory o) {
        LongTermOrdersLib.Order[] memory orders = pair.getDetailedOrdersForUser(user, 0, 10);
        for (uint256 i = 0; i < orders.length; i++) {
            if (orders[i].id == orderId) return orders[i];
        }
        revert("order not found");
    }

    function _addLiquidity(address to, uint256 amount0, uint256 amount1) internal {
        token0.transfer(address(pair), amount0);
        token1.transfer(address(pair), amount1);
        pair.mint(to);
    }

    function _swapToken0(address user, uint256 amountIn, uint256 amountOut) internal {
        vm.startPrank(user);
        token0.transfer(address(pair), amountIn);
        pair.swap(0, amountOut, user, "");
        vm.stopPrank();
    }

    function _swapToken1(address user, uint256 amountIn, uint256 amountOut) internal {
        vm.startPrank(user);
        token1.transfer(address(pair), amountIn);
        pair.swap(amountOut, 0, user, "");
        vm.stopPrank();
    }

    function _executeVirtualOrdersAtNow() internal {
        pair.executeVirtualOrders(block.timestamp + 1);
    }

    function _withdrawProceeds(address user, uint256 orderId) internal {
        vm.prank(user);
        pair.withdrawProceedsFromLongTermSwap(orderId);
    }

    function _fundUser3(uint256 amount0, uint256 amount1) internal {
        token0.transfer(user3, amount0);
        token1.transfer(user3, amount1);
    }

    function _mineAndExecuteVirtualOrders(uint256 intervals) internal {
        _mineTimeIntervals(intervals);
        _executeVirtualOrdersAtNow();
    }

    function _executeVirtualOrdersEveryInterval(uint256 intervals) internal {
        for (uint256 i = 0; i <= intervals; i++) {
            _mineTimeIntervals(1);
            pair.executeVirtualOrders(block.timestamp);
        }
    }
}
