// SPDX-License-Identifier: ISC
pragma solidity ^0.8.35;

/// @notice Port of core scenarios from `lib/frax-solidity/src/hardhat/test/Fraxswap/fraxswap-twamm-test.js`.

import {TestBase_FraxswapTWAMM} from "./TestBase_FraxswapTWAMM.sol";
import {FraxswapPair} from "@crane/contracts/protocols/tokens/stable/frax/Fraxswap/core/FraxswapPair.sol";
import {LongTermOrdersLib} from "@crane/contracts/protocols/tokens/stable/frax/Fraxswap/twamm/LongTermOrders.sol";

contract Fraxswap_TWAMM_Test is TestBase_FraxswapTWAMM {
    uint256 internal constant INITIAL_LIQ = 100_000e18;

    function setUp() public {
        _twammSetUp();
        _seedLiquidity(INITIAL_LIQ);
    }

    function test_executeVirtualOrders_anyoneCanCall() public {
        vm.prank(fraxUser1);
        pair.executeVirtualOrders(block.timestamp + 1);
    }

    function test_pause_blocksNewSwaps_allowsWithdraw() public {
        uint256 amountIn = 10e18;

        _fund(fraxUser1, amountIn * 2);
        _longTermSwap0To1(fraxUser1, amountIn, 2);
        _longTermSwap1To0(fraxUser1, amountIn, 2);

        _mineTimeIntervals(3);
        _executeVirtualOrders(block.timestamp);

        factory.toggleGlobalPause();
        pair.togglePauseNewSwaps();

        vm.startPrank(fraxUser1);
        token0.approve(address(pair), amountIn);
        vm.expectRevert();
        pair.longTermSwapFrom0To1(amountIn, 2);

        pair.withdrawProceedsFromLongTermSwap(0);
        pair.withdrawProceedsFromLongTermSwap(1);
        vm.stopPrank();
    }

    function test_cancelLongTermSwap() public {
        uint256 amountIn = 10e18;
        _fund(fraxUser1, amountIn * 2);

        uint256 bal0Before = token0.balanceOf(fraxUser1);
        uint256 bal1Before = token1.balanceOf(fraxUser1);

        _longTermSwap0To1(fraxUser1, amountIn, 10);
        _mineTimeIntervals(3);

        vm.prank(fraxUser1);
        pair.cancelLongTermSwap(0);

        LongTermOrdersLib.Order memory order = _orderAt(fraxUser1, 0);
        assertTrue(order.isComplete);
        assertLt(token0.balanceOf(fraxUser1), bal0Before);
        assertGt(token1.balanceOf(fraxUser1), bal1Before);
    }

    function test_withdrawProceeds_whileOrderActive() public {
        uint256 amountIn = 10e18;
        _fund(fraxUser1, amountIn);
        _fund(user2, amountIn);

        _longTermSwap0To1(fraxUser1, amountIn, 10);
        _mineTimeIntervals(3);
        _executeVirtualOrders(block.timestamp);

        uint256 bal0Before = token0.balanceOf(user2);
        uint256 bal1Before = token1.balanceOf(user2);

        (uint112 r0, uint112 r1,,,) = pair.getReserveAfterTwamm(block.timestamp);
        uint256 amountOut = _getAmountOut(r1, r0, 9970, amountIn);

        vm.startPrank(user2);
        token1.transfer(address(pair), amountIn);
        pair.swap(amountOut, 0, user2, "");
        vm.stopPrank();

        assertGt(token0.balanceOf(user2), bal0Before);
        assertLt(token1.balanceOf(user2), bal1Before);
    }

    function test_longTermSwap_timeIntervalZero_withdraw() public {
        uint256 liquidity = 1e28;
        token0.transfer(address(pair), liquidity);
        token1.transfer(address(pair), liquidity);
        pair.mint(fraxOwner);

        uint256 amountIn = 300e18;
        _fund(fraxUser1, amountIn);
        _alignTimestamp(2);

        uint256 orderId = _longTermSwap0To1(fraxUser1, amountIn, 0);
        LongTermOrdersLib.Order memory order = _orderAt(fraxUser1, orderId);
        assertGt(order.saleRate, 0);
        assertGt(order.expirationTimestamp, order.creationTimestamp);

        _mineTimeIntervals(5);

        vm.prank(fraxUser1);
        pair.withdrawProceedsFromLongTermSwap(orderId);

        (,,, uint112 twamm0, uint112 twamm1,) = pair.getTwammReserves();
        assertLe(twamm0, 2);
        assertLe(twamm1, 2);
    }

    function test_execVirtualOrders_invalidTimestamp() public {
        uint256 ts = block.timestamp;
        pair.executeVirtualOrders(ts);
        _mineTimeIntervals(2);
        pair.executeVirtualOrders(ts - 1);
        pair.executeVirtualOrders(block.timestamp);
    }

    function test_exceedsUint112_addLiquidity() public {
        _createPair(9970);
        token0.transfer(address(pair), MAX_UINT112);
        token1.transfer(address(pair), MAX_UINT112);
        pair.mint(fraxOwner);

        token0.transfer(fraxUser1, 2);
        token1.transfer(fraxUser1, 2);
        vm.startPrank(fraxUser1);
        token0.transfer(address(pair), 1);
        token1.transfer(address(pair), 1);
        vm.expectRevert(FraxswapPair.Uint112Overflow.selector);
        pair.mint(fraxUser1);
        vm.stopPrank();
    }

    function test_brickContract_executeVirtualOrders() public {
        uint256 liquidity = 1e28;
        token0.transfer(address(pair), liquidity);
        token1.transfer(address(pair), liquidity);
        pair.mint(fraxOwner);

        uint256 amountIn = 300e18;
        _fund(fraxUser1, amountIn);
        _alignTimestamp(4);

        uint256 orderId = _longTermSwap0To1(fraxUser1, amountIn, 2);
        LongTermOrdersLib.Order memory order = _orderAt(fraxUser1, orderId);

        _mineTimeIntervals(5);
        pair.executeVirtualOrders(order.expirationTimestamp);

        _mineTimeIntervals(1);
        pair.executeVirtualOrders(block.timestamp);
    }

    function test_longTermSwap_leftOvers_cancel() public {
        uint256 liquidity = 1e28;
        token0.transfer(address(pair), liquidity);
        token1.transfer(address(pair), liquidity);
        pair.mint(fraxOwner);

        uint256 amountIn = 300e18;
        _fund(fraxUser1, amountIn);
        _alignTimestamp(4);

        uint256 orderId = _longTermSwap0To1(fraxUser1, amountIn, 100);
        _mineTimeIntervals(99);

        vm.prank(fraxUser1);
        pair.cancelLongTermSwap(orderId);

        (,,, uint112 twamm0, uint112 twamm1,) = pair.getTwammReserves();
        assertLe(twamm0, 2);
        assertLe(twamm1, 2);
    }
}