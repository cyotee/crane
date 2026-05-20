// SPDX-License-Identifier: ISC
pragma solidity ^0.8.35;

/// @notice Port of `Fraxswap-FraxswapRange-test.js`.

import {TestBase_FraxswapRange} from "./TestBase_FraxswapRange.sol";
import {RangeTestMath} from "./RangeTestMath.sol";
import {FraxswapRangePair} from "@crane/contracts/protocols/tokens/stable/frax/Fraxswap/range/FraxswapRangePair.sol";

contract Fraxswap_Range_Test is TestBase_FraxswapRange {
    uint256 internal constant LIQ = 100e18;

    function setUp() public {
        _defaultRangeSetUp();
    }

    function test_setupContracts() public view {
        assertTrue(address(rangePair) != address(0));
        assertEq(factory.allPairsLength(), 1);
    }

    function test_initialMint() public {
        _addInitialLiquidity(LIQ, LIQ);
        assertEq(token0.balanceOf(address(rangePair)), LIQ);
        assertEq(token1.balanceOf(address(rangePair)), LIQ);
        assertEq(rangePair.balanceOf(owner), 2 * LIQ - MINIMUM_LIQUIDITY);
    }

    function test_mint_secondLp() public {
        _addInitialLiquidity(LIQ, LIQ);

        token0.transfer(address(rangePair), LIQ);
        token1.transfer(address(rangePair), LIQ);
        vm.prank(user1);
        rangePair.mint(user1);

        assertEq(token0.balanceOf(address(rangePair)), 2 * LIQ);
        assertEq(token1.balanceOf(address(rangePair)), 2 * LIQ);
        assertEq(rangePair.balanceOf(user1), 2 * LIQ);
    }

    function test_burn() public {
        _addInitialLiquidity(LIQ, LIQ);

        uint256 bal0Before = token0.balanceOf(owner);
        uint256 bal1Before = token1.balanceOf(owner);

        rangePair.transfer(address(rangePair), LIQ);
        rangePair.burn(owner);

        assertEq(token0.balanceOf(address(rangePair)), 50e18);
        assertEq(token1.balanceOf(address(rangePair)), 50e18);
        assertEq(rangePair.balanceOf(owner), LIQ - MINIMUM_LIQUIDITY);
        assertEq(token0.balanceOf(owner), bal0Before + 50e18);
        assertEq(token1.balanceOf(owner), bal1Before + 50e18);
    }

    function test_protocolFees() public {
        factory.setFeeTo(user3);
        _addInitialLiquidity(LIQ, LIQ);

        uint256 tradeAmount = 1e16;
        (uint112 r0, uint112 r1,) = rangePair.getReserves();
        uint256 rootKStart = RangeTestMath.sqrt(uint256(r0) * r1);
        uint256 expectedOut = RangeTestMath.expectedOut(r0, r1, tradeAmount, DEFAULT_FEE);

        token0.transfer(address(rangePair), tradeAmount);
        rangePair.swap(0, expectedOut, user1, "");

        assertEq(rangePair.balanceOf(user3), 0);

        rangePair.sync();

        (r0, r1,) = rangePair.getReserves();
        uint256 totalSupply = rangePair.totalSupply();

        _addInitialLiquidity(LIQ, LIQ);

        uint256 rootKEnd = RangeTestMath.sqrt(uint256(r0) * r1);
        uint256 expectedEarned = totalSupply * (rootKEnd - rootKStart) / (rootKEnd * 5 + rootKStart);
        assertEq(rangePair.balanceOf(user3), expectedEarned);

        uint256 approximateFeeValue = expectedEarned * 200e18 / totalSupply;
        uint256 expectedFeeValue = tradeAmount * 5 / 10_000;
        assertApproxEqAbs(approximateFeeValue, expectedFeeValue, 10e10);
    }

    function test_swapAtEdge() public {
        _rangeSetUp(PRECISION, PRECISION * 3, DEFAULT_FEE);
        token1.transfer(address(rangePair), LIQ);
        rangePair.mint(owner);

        uint256 tradeAmount = 1e6;
        (uint112 r0, uint112 r1,) = rangePair.getReserves();
        uint256 expectedOut = RangeTestMath.expectedOut(r0, r1, tradeAmount, DEFAULT_FEE);

        uint256 bal1Before = token1.balanceOf(user1);
        token0.transfer(address(rangePair), tradeAmount);

        vm.expectRevert(bytes("UniswapV2: K"));
        rangePair.swap(0, expectedOut + 1, user1, "");

        rangePair.swap(0, expectedOut, user1, "");
        assertEq(token1.balanceOf(user1) - bal1Before, expectedOut);
    }

    function test_swapOverEdge() public {
        _addInitialLiquidity(LIQ, LIQ);

        uint256 tradeAmount = (200e18 * 1004) / 1000;
        token0.transfer(address(rangePair), tradeAmount);

        vm.expectRevert(bytes("UniswapV2: INSUFFICIENT_LIQUIDITY"));
        rangePair.swap(0, 100e18 + 1, user1, "");

        rangePair.swap(0, 100e18, user1, "");
    }

    function test_swap_token0ToToken1() public {
        _addInitialLiquidity(LIQ, LIQ);
        _assertSwap0To1(1000, DEFAULT_FEE);
    }

    function test_swap_token1ToToken0() public {
        _addInitialLiquidity(LIQ, LIQ);
        _assertSwap1To0(1000, DEFAULT_FEE);
    }

    function test_swapFee_fuzz(uint8 feeBps) public {
        feeBps = uint8(bound(feeBps, 0, 100));
        _rangeSetUp(PRECISION, PRECISION, feeBps);
        _addInitialLiquidity(LIQ, LIQ);
        _assertSwap0To1(1e9, feeBps);
    }

    function test_updateVirtualReserves() public {
        _rangeSetUp(PRECISION, PRECISION, 1);
        _addInitialLiquidity(LIQ, LIQ);

        uint256 initialQ;
        uint256 resetCount;
        uint256 tradeAmount = 10e18;

        for (uint256 i = 0; i < 100; i++) {
            (uint112 r0, uint112 r1,) = rangePair.getReserves();
            uint112 v0 = rangePair.virtualReserve0();
            uint112 v1 = rangePair.virtualReserve1();
            uint256 k = uint256(r0) * r1;
            uint256 q = k * 1_000_000 / (uint256(v0) * v1);
            if (initialQ == 0) initialQ = q;
            else if (q == initialQ) resetCount++;

            uint256 out0 = RangeTestMath.expectedOut(r0, r1, tradeAmount, 1);
            vm.startPrank(user1);
            token0.transfer(address(rangePair), tradeAmount);
            rangePair.swap(0, out0, user1, "");
            vm.stopPrank();

            (r0, r1,) = rangePair.getReserves();
            v0 = rangePair.virtualReserve0();
            v1 = rangePair.virtualReserve1();
            k = uint256(r0) * r1;
            q = k * 1_000_000 / (uint256(v0) * v1);
            if (q == initialQ) resetCount++;

            uint256 out1 = RangeTestMath.expectedOut(r1, r0, tradeAmount, 1);
            vm.startPrank(user1);
            token1.transfer(address(rangePair), tradeAmount);
            rangePair.swap(out1, 0, user1, "");
            vm.stopPrank();
        }
        assertGt(resetCount, 1);
    }

    function test_concentratedLiquidity() public {
        uint256 rangeSize = PRECISION;
        for (uint256 i = 0; i < 20; i++) {
            _rangeSetUp(PRECISION, rangeSize, DEFAULT_FEE);
            token0.transfer(address(rangePair), 200e18);
            token1.transfer(address(rangePair), 200e18);
            rangePair.mint(owner);
            _assertSwap0To1(100e18, DEFAULT_FEE);
            rangeSize = rangeSize / 2;
        }
    }

    function test_virtualReserveDonate() public {
        _rangeSetUp(PRECISION, PRECISION / 2, DEFAULT_FEE);
        _addInitialLiquidity(LIQ, LIQ);

        uint256 donation = 10e10;
        (uint112 r0, uint112 r1,) = rangePair.getReserves();
        uint112 v0 = rangePair.virtualReserve0();
        uint112 v1 = rangePair.virtualReserve1();
        uint256 k = uint256(r0) * r1;
        uint256 q1 = k / (uint256(v1) * v1);

        token1.transfer(address(rangePair), donation);
        rangePair.sync();

        (r0, r1,) = rangePair.getReserves();
        v1 = rangePair.virtualReserve1();
        k = uint256(r0) * r1;
        uint256 q1After = k / (uint256(v1) * v1);
        assertApproxEqAbs(q1, q1After, 1);
    }

    function _assertSwap0To1(uint256 tradeAmount, uint256 feeBps) internal {
        (uint112 r0, uint112 r1,) = rangePair.getReserves();
        uint256 expectedOut = RangeTestMath.expectedOut(r0, r1, tradeAmount, feeBps);
        uint256 bal1Before = token1.balanceOf(user1);

        token0.transfer(address(rangePair), tradeAmount);
        vm.expectRevert(bytes("UniswapV2: K"));
        rangePair.swap(0, expectedOut + 1, user1, "");
        rangePair.swap(0, expectedOut, user1, "");
        assertEq(token1.balanceOf(user1) - bal1Before, expectedOut);
    }

    function _assertSwap1To0(uint256 tradeAmount, uint256 feeBps) internal {
        (uint112 r0, uint112 r1,) = rangePair.getReserves();
        uint256 expectedOut = RangeTestMath.expectedOut(r1, r0, tradeAmount, feeBps);
        uint256 bal0Before = token0.balanceOf(user1);

        token1.transfer(address(rangePair), tradeAmount);
        vm.expectRevert(bytes("UniswapV2: K"));
        rangePair.swap(expectedOut + 1, 0, user1, "");
        rangePair.swap(expectedOut, 0, user1, "");
        assertEq(token0.balanceOf(user1) - bal0Before, expectedOut);
    }
}