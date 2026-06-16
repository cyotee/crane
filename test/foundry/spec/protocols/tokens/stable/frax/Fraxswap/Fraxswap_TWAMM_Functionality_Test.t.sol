// SPDX-License-Identifier: ISC
pragma solidity ^0.8.35;

/// @notice Port of `fraxswap-twamm-test.js` "TWAMM Functionality" (multiplier=1, fee=30).

import {TestBase_FraxswapTWAMM} from "./TestBase_FraxswapTWAMM.sol";
import {TwammTestMath} from "./TwammTestMath.sol";
import {LongTermOrdersLib} from "@crane/contracts/protocols/tokens/stable/frax/Fraxswap/twamm/LongTermOrders.sol";
import {FraxswapPair} from "@crane/contracts/protocols/tokens/stable/frax/Fraxswap/core/FraxswapPair.sol";
import {IERC20} from "@crane/contracts/external/openzeppelin-contracts/token/ERC20/IERC20.sol";

contract Fraxswap_TWAMM_Functionality_Test is TestBase_FraxswapTWAMM {
    function setUp() public {
        _twammSetUp();
        _seedLiquidity(TWAMM_INITIAL_LIQ);
        _fundUser3(1_000_000e18, 1_000_000e18);
    }

    /* ---------- Twamm execution frequency ---------- */

    function test_highFrequency_executeEachInterval_withdraw() public {
        uint256 amountIn = TWAMM_AMOUNT_IN;
        _fundToken0(fraxUser1, amountIn);
        _alignTimestamp(0);
        _longTermSwap0To1(fraxUser1, amountIn, 100);

        _executeVirtualOrdersEveryInterval(101);

        uint256 bal1Before = token1.balanceOf(fraxUser1);
        _withdrawProceeds(fraxUser1, 0);
        assertGt(token1.balanceOf(fraxUser1), bal1Before);
        assertTrue(_orderAt(fraxUser1, 0).isComplete);
    }

    function test_lowFrequency_executeOnceAfterIntervals_withdraw() public {
        uint256 amountIn = TWAMM_AMOUNT_IN;
        _fundToken0(fraxUser1, amountIn);
        _longTermSwap0To1(fraxUser1, amountIn, 100);

        _mineAndExecuteVirtualOrders(101);

        uint256 bal1Before = token1.balanceOf(fraxUser1);
        _withdrawProceeds(fraxUser1, 0);
        assertGt(token1.balanceOf(fraxUser1), bal1Before);
    }

    /* ---------- Fee update ---------- */

    function test_normalSwap_feeChangeMidWay() public {
        uint256 amountIn = TWAMM_AMOUNT_IN;

        (uint112 r0, uint112 r1,,,,) = pair.getTwammReserves();
        uint256 expectedOut = TwammTestMath.expectedSwapOut(amountIn, r0, r1, TWAMM_FEE_MULT);

        _fundToken0(fraxUser1, amountIn);
        uint256 t1Before = token1.balanceOf(fraxUser1);
        _swapToken0(fraxUser1, amountIn, expectedOut);
        assertEq(token1.balanceOf(fraxUser1) - t1Before, expectedOut);

        vm.prank(fraxUser1);
        vm.expectRevert();
        pair.setFee(88);

        vm.prank(fraxOwner);
        pair.setFee(88);

        uint256 feeMult88 = 10_000 - 88;
        (r0, r1,,,,) = pair.getTwammReserves();
        uint256 expectedOut2 = TwammTestMath.expectedSwapOut(amountIn, r0, r1, feeMult88);

        _fundToken0(user2, amountIn);
        t1Before = token1.balanceOf(user2);
        _swapToken0(user2, amountIn, expectedOut2);
        assertEq(token1.balanceOf(user2) - t1Before, expectedOut2);
    }

    /* ---------- Long term swaps ---------- */

    function test_singleSidedOrder_matchesReserveAfterTwamm() public {
        _fund(fraxUser1, TWAMM_AMOUNT_IN);
        _alignTimestamp(0);
        _longTermSwap0To1(fraxUser1, TWAMM_AMOUNT_IN, 2);
        _assertReserveAfterTwammMatchesExecution(3);
        _assertSingleSidedWithdrawNearInstantSwap(TWAMM_AMOUNT_IN);
    }

    function _assertReserveAfterTwammMatchesExecution(uint256 intervalsMoved) internal {
        _mineTimeIntervals(intervalsMoved);
        uint256 ts = block.timestamp;
        (uint112 viewR0, uint112 viewR1, uint256 lastVirtualTs, uint112 viewTw0, uint112 viewTw1) =
            pair.getReserveAfterTwamm(ts);
        pair.executeVirtualOrders(ts);
        (uint112 r0, uint112 r1,, uint112 tw0, uint112 tw1,) = pair.getTwammReserves();
        assertGe(block.timestamp, lastVirtualTs + intervalsMoved * ORDER_TIME_INTERVAL);
        assertEq(r0, viewR0);
        assertEq(r1, viewR1);
        assertEq(tw0, viewTw0);
        assertEq(tw1, viewTw1);
    }

    function _assertSingleSidedWithdrawNearInstantSwap(uint256 amountIn) internal {
        uint256 expectedOut =
            TwammTestMath.expectedSwapOut(amountIn, TWAMM_INITIAL_LIQ, TWAMM_INITIAL_LIQ, TWAMM_FEE_MULT);
        uint256 bal1Before = token1.balanceOf(fraxUser1);
        _withdrawProceeds(fraxUser1, 0);
        assertApproxEqAbs(token1.balanceOf(fraxUser1) - bal1Before, expectedOut, amountIn / 10_000_000);
    }

    function test_singleSidedOrder_amountTooSmall_reverts() public {
        uint256 amountIn = 15;
        _fund(fraxUser1, amountIn);
        vm.startPrank(fraxUser1);
        token0.approve(address(pair), amountIn);
        vm.expectRevert();
        pair.longTermSwapFrom0To1(amountIn, 20_000);
        vm.stopPrank();
    }

    function test_ordersInBothPools_skimAndMintGuards() public {
        uint256 amountIn = TWAMM_AMOUNT_IN;
        _fundToken0(fraxUser1, amountIn);
        _fundToken1(user2, amountIn);

        _longTermSwap0To1(fraxUser1, amountIn, 2);
        _longTermSwap1To0(user2, amountIn, 2);

        uint256 t0Before = token0.balanceOf(user3);
        uint256 t1Before = token1.balanceOf(user3);
        vm.prank(user3);
        pair.skim(user3);
        assertEq(token0.balanceOf(user3), t0Before);
        assertEq(token1.balanceOf(user3), t1Before);

        uint256 lpBefore = pair.balanceOf(user3);
        vm.prank(user3);
        vm.expectRevert();
        pair.mint(user3);
        assertEq(pair.balanceOf(user3), lpBefore);

        _mineAndExecuteVirtualOrders(3);
        _withdrawProceeds(fraxUser1, 0);
        _withdrawProceeds(user2, 1);

        _assertBalancedCrossPoolOutput(amountIn);
    }

    function test_swapAmounts_consistentWithTwammFormula() public {
        uint256 token0In = TWAMM_AMOUNT_IN;
        uint256 token1In = 2e18;

        (uint112 r0, uint112 r1,) = pair.getReserves();
        (uint256 expR0, uint256 expR1, uint256 exp0Out, uint256 exp1Out) =
            TwammTestMath.calculateTwammExpectedFraxswap(token0In, token1In, r0, r1, TWAMM_FEE_MULT);

        _fundToken0(fraxUser1, token0In);
        _fundToken1(user2, token1In);
        _longTermSwap0To1(fraxUser1, token0In, 10);
        _longTermSwap1To0(user2, token1In, 10);

        _mineAndExecuteVirtualOrders(22);
        _withdrawProceeds(fraxUser1, 0);
        _withdrawProceeds(user2, 1);

        assertTrue(_orderAt(fraxUser1, 0).isComplete);

        assertApproxEqRel(token0.balanceOf(user2), exp0Out, 0.05e18);
        assertApproxEqRel(token1.balanceOf(fraxUser1), exp1Out, 0.05e18);
        (r0, r1,) = pair.getReserves();
        assertApproxEqRel(r0, expR0, 0.05e18);
        assertApproxEqRel(r1, expR1, 0.05e18);
    }

    function test_multipleOrders_bothPools_normal() public {
        uint256 amountIn = TWAMM_AMOUNT_IN;
        _fundToken0(fraxUser1, amountIn);
        _fundToken1(user2, amountIn);

        _longTermSwap0To1(fraxUser1, amountIn / 2, 2);
        _longTermSwap1To0(user2, amountIn / 2, 3);
        _longTermSwap0To1(fraxUser1, amountIn / 2, 4);
        _longTermSwap1To0(user2, amountIn / 2, 5);

        LongTermOrdersLib.Order[] memory full = pair.getDetailedOrdersForUser(fraxUser1, 0, 99999);
        assertEq(full.length, 2);
        LongTermOrdersLib.Order[] memory offset = pair.getDetailedOrdersForUser(fraxUser1, 1, 99999);
        assertEq(offset.length, 1);
        LongTermOrdersLib.Order[] memory limited = pair.getDetailedOrdersForUser(fraxUser1, 0, 1);
        assertEq(limited.length, 1);

        _mineAndExecuteVirtualOrders(6);
        _withdrawProceeds(fraxUser1, 0);
        _withdrawProceeds(user2, 1);
        _withdrawProceeds(fraxUser1, 2);
        _withdrawProceeds(user2, 3);

        _assertBalancedCrossPoolOutput(amountIn);
    }

    function test_multipleOrders_midPeriod_skimSwapLiquidity() public {
        _placeFourCrossOrders(TWAMM_AMOUNT_IN);
        _midPeriodSkimSwapAndLiquidity();
        _finishFourCrossOrdersAndAssert(TWAMM_AMOUNT_IN);
    }

    function _placeFourCrossOrders(uint256 amountIn) internal {
        _fundToken0(fraxUser1, amountIn);
        _fundToken1(user2, amountIn);
        _longTermSwap0To1(fraxUser1, amountIn / 2, 2);
        _longTermSwap1To0(user2, amountIn / 2, 3);
        _longTermSwap0To1(fraxUser1, amountIn / 2, 4);
        _longTermSwap1To0(user2, amountIn / 2, 5);
    }

    function _midPeriodSkimSwapAndLiquidity() internal {
        _mineAndExecuteVirtualOrders(3);
        vm.prank(user3);
        pair.skim(user3);
        pair.sync();

        uint256 swapIn = 1_000_000e18 / 10_000;
        (uint112 r0, uint112 r1,,,,) = pair.getTwammReserves();
        _fundUser3(swapIn, 0);
        _swapToken0(user3, swapIn, TwammTestMath.expectedSwapOut(swapIn, r0, r1, TWAMM_FEE_MULT));

        vm.prank(user3);
        pair.skim(user3);
        pair.sync();

        uint256 lpAmt = 1_000_000e18 / 10;
        _fundUser3(lpAmt, lpAmt);
        vm.startPrank(user3);
        token0.transfer(address(pair), lpAmt);
        token1.transfer(address(pair), lpAmt);
        uint256 lpMinted = pair.mint(user3);
        vm.stopPrank();
        assertGt(lpMinted, 0);

        _mineAndExecuteVirtualOrders(2);
        vm.startPrank(user3);
        pair.transfer(address(pair), lpMinted / 3);
        pair.burn(user3);
        vm.stopPrank();
        _mineAndExecuteVirtualOrders(1);
    }

    function _finishFourCrossOrdersAndAssert(uint256 amountIn) internal {
        _withdrawProceeds(fraxUser1, 0);
        _withdrawProceeds(user2, 1);
        _withdrawProceeds(fraxUser1, 2);
        _withdrawProceeds(user2, 3);
        _assertBalancedCrossPoolOutput(amountIn);
    }

    function _assertBalancedCrossPoolOutput(uint256 amountIn) internal view {
        uint256 bought0 = token0.balanceOf(user2);
        uint256 bought1 = token1.balanceOf(fraxUser1);
        uint256 avg = (bought0 + bought1) / 2;
        uint256 expected = amountIn * TWAMM_FEE_MULT / 10_000;
        assertApproxEqAbs(avg, expected, amountIn * 20 / 1000);
        assertGt(bought0, 0);
        assertGt(bought1, 0);
    }

    function test_normalSwap_whileOppositeLongTermOrdersActive() public {
        uint256 amountIn = 20e18;
        _fundToken0(fraxUser1, amountIn);
        _fundToken1(user2, amountIn);

        _longTermSwap0To1(fraxUser1, amountIn, 10);
        _longTermSwap1To0(user2, amountIn, 10);

        _mineAndExecuteVirtualOrders(3);
        _withdrawProceeds(fraxUser1, 0);
        _withdrawProceeds(user2, 1);

        assertApproxEqAbs(token0.balanceOf(user2), token1.balanceOf(fraxUser1), amountIn / 80);
    }

    /* ---------- Cancelling / partial withdrawal ---------- */

    function test_cancelOrder_marksComplete_andFillsPartially() public {
        uint256 amountIn = TWAMM_AMOUNT_IN;
        _fund(fraxUser1, amountIn);

        uint256 t0Before = token0.balanceOf(fraxUser1);
        uint256 t1Before = token1.balanceOf(fraxUser1);

        _longTermSwap0To1(fraxUser1, amountIn, 10);
        _mineAndExecuteVirtualOrders(3);

        vm.prank(fraxUser1);
        pair.cancelLongTermSwap(0);

        LongTermOrdersLib.Order[] memory orders = pair.getDetailedOrdersForUser(fraxUser1, 0, 1);
        assertTrue(orders[0].isComplete);
        assertLt(token0.balanceOf(fraxUser1), t0Before);
        assertGt(token1.balanceOf(fraxUser1), t1Before);
    }

    function test_proceedsWithdrawnWhileActive_instantSwapStillWorks() public {
        uint256 amountIn = TWAMM_AMOUNT_IN;
        _fund(fraxUser1, amountIn);
        _fund(user2, amountIn * 2);

        _longTermSwap0To1(fraxUser1, amountIn, 10);
        _mineAndExecuteVirtualOrders(3);

        (uint112 r0, uint112 r1,,,,) = pair.getTwammReserves();
        uint256 amountOut = TwammTestMath.expectedSwapOut(amountIn, r1, r0, TWAMM_FEE_MULT);

        uint256 t0Before = token0.balanceOf(user2);
        uint256 t1Before = token1.balanceOf(user2);
        _swapToken1(user2, amountIn, amountOut);
        assertGt(token0.balanceOf(user2), t0Before);
        assertLt(token1.balanceOf(user2), t1Before);
    }
}
