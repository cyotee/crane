// SPDX-License-Identifier: ISC
pragma solidity ^0.8.35;

/// @notice Edge cases from `fraxswap-twamm-test.js` "Edge cases" describe block.

import {TestBase_FraxswapTWAMM} from "./TestBase_FraxswapTWAMM.sol";
import {FraxswapPair} from "@crane/contracts/protocols/tokens/stable/frax/Fraxswap/core/FraxswapPair.sol";

contract Fraxswap_TWAMM_Edge_Test is TestBase_FraxswapTWAMM {
    uint256 internal constant LIQ0_BASE = 8379829307706602317717;
    uint256 internal constant LIQ1_BASE = 10991961728915299510446;

    function setUp() public {
        _twammSetUp();
    }

    function test_computeVirtualBalances_withLiquidity_divisor1() public {
        _addLiquidity(fraxOwner, LIQ0_BASE, LIQ1_BASE);
        _alignTimestamp(4);

        _fund(fraxUser1, 1e18);
        _fund(user2, MAX_UINT112 / 2);

        _longTermSwap1To0(fraxUser1, 1, 0);
        _longTermSwap0To1(user2, MAX_UINT112 / 2, 0);

        _mineTimeIntervals(2);
        _executeVirtualOrdersAtNow();
    }

    function test_computeVirtualBalances_withLiquidity_divisor8() public {
        _addLiquidity(fraxOwner, LIQ0_BASE / 8, LIQ1_BASE / 8);
        _alignTimestamp(4);

        _fund(fraxUser1, 1e18);
        _fund(user2, MAX_UINT112 / 16);

        _longTermSwap1To0(fraxUser1, 1, 0);
        _longTermSwap0To1(user2, MAX_UINT112 / 16, 0);

        _mineTimeIntervals(2);
        _executeVirtualOrdersAtNow();
    }

    function test_computeVirtualBalances_noLiquidity_swap1To0Only() public {
        _alignTimestamp(4);
        _fund(fraxUser1, 2);
        _longTermSwap1To0(fraxUser1, 1, 0);
        _mineTimeIntervals(2);
        _executeVirtualOrdersAtNow();
    }

    function test_computeVirtualBalances_noLiquidity_swap0To1Only() public {
        _alignTimestamp(4);
        _fund(user2, 2);
        _longTermSwap0To1(user2, 1, 0);
        _mineTimeIntervals(2);
        _executeVirtualOrdersAtNow();
    }

    function test_computeVirtualBalances_noLiquidity_bothOrdersSize1() public {
        _alignTimestamp(0);
        _fund(fraxUser1, 2);
        _fund(user2, 2);
        _longTermSwap1To0(fraxUser1, 1, 0);
        _longTermSwap0To1(user2, 1, 0);
        _mineTimeIntervals(2);
        _executeVirtualOrdersAtNow();
    }

    function test_computeVirtualBalances_noLiquidity_smallAndLarge() public {
        _alignTimestamp(0);
        _fund(fraxUser1, MAX_UINT112 / 2 + 1);
        _fund(user2, MAX_UINT112 / 2 + 1);
        _longTermSwap1To0(fraxUser1, 1, 0);
        _longTermSwap0To1(user2, MAX_UINT112 / 2, 0);
        _mineTimeIntervals(2);
        _executeVirtualOrdersAtNow();
    }

    function test_exceedsUint112_secondMintReverts() public {
        _addLiquidity(fraxOwner, MAX_UINT112, MAX_UINT112);
        _fund(fraxUser1, 2);
        vm.startPrank(fraxUser1);
        token0.transfer(address(pair), 1);
        token1.transfer(address(pair), 1);
        vm.expectRevert(FraxswapPair.Uint112Overflow.selector);
        pair.mint(fraxUser1);
        vm.stopPrank();
    }

    function test_exceedsUint112_twammOrderFromToken0() public {
        uint256 half = MAX_UINT112 / 2;
        _addLiquidity(fraxOwner, half, half);

        (uint112 r0, uint112 r1,,,,) = pair.getTwammReserves();
        uint256 swapIn = MAX_UINT112 / 3;
        uint256 amountOut = _getAmountOut(r0, r1, 9970, swapIn);
        _fund(user2, swapIn);
        _swapToken0(user2, swapIn, amountOut);

        (r0,,,,,) = pair.getTwammReserves();
        uint256 tooMuch = uint256(r0) > MAX_UINT112 - 10 ? MAX_UINT112 : MAX_UINT112 - uint256(r0) + 10;

        _fund(fraxUser1, tooMuch);
        vm.startPrank(fraxUser1);
        token0.approve(address(pair), tooMuch);
        vm.expectRevert();
        pair.longTermSwapFrom0To1(tooMuch, 20);
        vm.stopPrank();
    }

    function test_asyncDepositExceedsUint112_skimThenSync() public {
        uint256 half = MAX_UINT112 / 2;
        _addLiquidity(fraxOwner, half, half);

        address depositor = makeAddr("asyncDepositor");
        _fund(depositor, half);

        vm.startPrank(depositor);
        token0.transfer(address(pair), half);
        token1.transfer(address(pair), half);
        vm.stopPrank();

        (uint112 r0,,, uint112 tw0,,) = pair.getTwammReserves();
        assertEq(r0, half);
        assertEq(tw0, 0);

        uint256 orderSize = MAX_UINT112 - uint256(r0);
        _fund(user2, orderSize);
        _longTermSwap0To1(user2, orderSize, 100);

        (r0,,, tw0,,) = pair.getTwammReserves();
        assertEq(uint256(r0) + uint256(tw0), MAX_UINT112);

        vm.expectRevert(FraxswapPair.Uint112Overflow.selector);
        pair.sync();

        address skimTo = makeAddr("skimRecipient");
        vm.prank(skimTo);
        pair.skim(skimTo);
        assertEq(token0.balanceOf(skimTo), half);

        pair.sync();
    }
}