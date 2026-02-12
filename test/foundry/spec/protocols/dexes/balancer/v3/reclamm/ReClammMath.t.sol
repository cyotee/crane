// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.24;

import "forge-std/Test.sol";

import {SafeCast} from "@crane/contracts/utils/SafeCast.sol";
import {Math} from "@crane/contracts/utils/Math.sol";

import { Rounding } from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/VaultTypes.sol";

import { ArrayHelpers } from "@crane/contracts/external/balancer/v3/solidity-utils/contracts/test/ArrayHelpers.sol";
import { FixedPoint } from "@crane/contracts/external/balancer/v3/solidity-utils/contracts/math/FixedPoint.sol";

import { ReClammMathMock } from "contracts/protocols/dexes/balancer/v3/reclamm/test/ReClammMathMock.sol";
import { ReClammMath, a, b } from "contracts/protocols/dexes/balancer/v3/reclamm/lib/ReClammMath.sol";
import { BaseReClammTest } from "./utils/BaseReClammTest.sol";

contract ReClammMathTest is BaseReClammTest {
    using ArrayHelpers for *;
    using FixedPoint for uint256;

    uint256 private constant _MAX_CENTEREDNESS_ERROR_ABS = 5e7;
    uint256 private constant _MAX_PRICE_ERROR_ABS = 3e16;

    ReClammMathMock internal mathContract;

    function setUp() public override {
        super.setUp();
        mathContract = new ReClammMathMock();
    }

    function testParseDailyPriceShiftExponent() public pure {
        uint256 value = 2123e9;
        uint256 dailyPriceShiftBase = ReClammMath.toDailyPriceShiftBase(value);

        assertEq(
            dailyPriceShiftBase,
            FixedPoint.ONE - value / _PRICE_SHIFT_EXPONENT_INTERNAL_ADJUSTMENT,
            "DailyPriceShiftExponent should be parsed correctly"
        );
    }

    function testComputeInGivenOut__Fuzz(
        uint256 balanceA,
        uint256 balanceB,
        uint256 virtualBalanceA,
        uint256 virtualBalanceB,
        uint256 tokenIn,
        uint256 amountGivenScaled18
    ) public pure {
        tokenIn = bound(tokenIn, 0, 1);
        uint256 tokenOut = tokenIn == 0 ? 1 : 0;

        balanceA = bound(balanceA, _MIN_TOKEN_BALANCE, _MAX_TOKEN_BALANCE);
        balanceB = bound(balanceB, _MIN_TOKEN_BALANCE, _MAX_TOKEN_BALANCE);
        virtualBalanceA = bound(virtualBalanceA, _MIN_TOKEN_BALANCE, _MAX_TOKEN_BALANCE);
        virtualBalanceB = bound(virtualBalanceB, _MIN_TOKEN_BALANCE, _MAX_TOKEN_BALANCE);

        uint256 maxAmount = tokenIn == 0 ? balanceB : balanceA;
        amountGivenScaled18 = bound(amountGivenScaled18, 1, maxAmount);

        uint256[] memory balances = [balanceA, balanceB].toMemoryArray();
        uint256[] memory virtualBalances = [virtualBalanceA, virtualBalanceB].toMemoryArray();

        uint256 amountIn = ReClammMath.computeInGivenOut(
            balances,
            virtualBalanceA,
            virtualBalanceB,
            tokenIn,
            tokenOut,
            amountGivenScaled18
        );

        uint256 expected = FixedPoint.mulDivUp(
            balances[tokenIn] + virtualBalances[tokenIn],
            amountGivenScaled18,
            balances[tokenOut] + virtualBalances[tokenOut] - amountGivenScaled18
        );

        assertEq(amountIn, expected, "Amount in should be correct");
    }

    function testComputeInGivenOutBiggerThanBalance() public {
        uint256 balanceA = 1e18;
        uint256 balanceB = 1e18;
        uint256 virtualBalanceA = 1e18;
        uint256 virtualBalanceB = 1e18;

        uint256 amountGivenScaled18 = 1e18 + 1;

        vm.expectRevert(ReClammMath.AmountOutGreaterThanBalance.selector);
        mathContract.computeInGivenOut(
            [balanceA, balanceB].toMemoryArray(),
            [virtualBalanceA, virtualBalanceB].toMemoryArray(),
            0,
            1,
            amountGivenScaled18
        );
    }

    function testComputeOutGivenIn__Fuzz(
        uint256 balanceA,
        uint256 balanceB,
        uint256 virtualBalanceA,
        uint256 virtualBalanceB,
        uint256 tokenIn,
        uint256 amountGivenScaled18
    ) public pure {
        tokenIn = bound(tokenIn, 0, 1);
        uint256 tokenOut = tokenIn == 0 ? 1 : 0;

        balanceA = bound(balanceA, _MIN_TOKEN_BALANCE, _MAX_TOKEN_BALANCE);
        balanceB = bound(balanceB, _MIN_TOKEN_BALANCE, _MAX_TOKEN_BALANCE);
        virtualBalanceA = bound(virtualBalanceA, _MIN_TOKEN_BALANCE, _MAX_TOKEN_BALANCE);
        virtualBalanceB = bound(virtualBalanceB, _MIN_TOKEN_BALANCE, _MAX_TOKEN_BALANCE);

        uint256 maxAmount = tokenIn == 0 ? balanceA : balanceB;
        amountGivenScaled18 = bound(amountGivenScaled18, 1, maxAmount);

        uint256[] memory balances = [balanceA, balanceB].toMemoryArray();
        uint256[] memory virtualBalances = [virtualBalanceA, virtualBalanceB].toMemoryArray();

        uint256 expectedAmountOutScaled18 = _computeOutGivenInAllowError(
            balances,
            virtualBalances,
            tokenIn,
            tokenOut,
            amountGivenScaled18
        );
        vm.assume(expectedAmountOutScaled18 < (tokenOut == 0 ? balanceA : balanceB));

        uint256 amountOut = ReClammMath.computeOutGivenIn(
            balances,
            virtualBalanceA,
            virtualBalanceB,
            tokenIn,
            tokenOut,
            amountGivenScaled18
        );

        uint256 expected = ((balances[tokenOut] + virtualBalances[tokenOut]) * amountGivenScaled18) /
            (balances[tokenIn] + virtualBalances[tokenIn] + amountGivenScaled18);

        assertEq(amountOut, expected, "Amount out should be correct");
    }

    function testComputeOutGivenInBiggerThanBalance() public {
        // Pool heavily unbalanced, token B over valued.
        uint256 balanceA = 4e5 * 1e18;
        uint256 balanceB = 1e18;
        uint256 virtualBalanceA = 7e5 * 1e18;
        uint256 virtualBalanceB = 5e5 * 1e18;

        // This trade will return more tokens B than the real balance of the pool.
        uint256 amountGivenScaled18 = balanceA;

        vm.expectRevert(ReClammMath.AmountOutGreaterThanBalance.selector);
        mathContract.computeOutGivenIn(
            [balanceA, balanceB].toMemoryArray(),
            [virtualBalanceA, virtualBalanceB].toMemoryArray(),
            0,
            1,
            amountGivenScaled18
        );
    }

    function testIsPoolWithinTargetRange__Fuzz(
        uint256 balanceA,
        uint256 balanceB,
        uint256 virtualBalanceA,
        uint256 virtualBalanceB,
        uint256 centerednessMargin
    ) public pure {
        balanceA = bound(balanceA, 0, _MAX_TOKEN_BALANCE);
        balanceB = bound(balanceB, 0, _MAX_TOKEN_BALANCE);
        virtualBalanceA = bound(virtualBalanceA, _MIN_TOKEN_BALANCE, _MAX_TOKEN_BALANCE);
        virtualBalanceB = bound(virtualBalanceB, _MIN_TOKEN_BALANCE, _MAX_TOKEN_BALANCE);
        centerednessMargin = bound(centerednessMargin, 0, 50e16);

        uint256[] memory balancesScaled18 = new uint256[](2);
        balancesScaled18[a] = balanceA;
        balancesScaled18[b] = balanceB;

        uint256[] memory virtualBalances = new uint256[](2);
        virtualBalances[a] = virtualBalanceA;
        virtualBalances[b] = virtualBalanceB;

        bool isInRange = ReClammMath.isPoolWithinTargetRange(
            balancesScaled18,
            virtualBalances[a],
            virtualBalances[b],
            centerednessMargin
        );

        (uint256 centeredness, ) = ReClammMath.computeCenteredness(
            balancesScaled18,
            virtualBalances[a],
            virtualBalances[b]
        );
        assertEq(isInRange, centeredness >= centerednessMargin, "In range flag does not match calculation");
    }

    function testComputeCenteredness__Fuzz(
        uint256 balanceA,
        uint256 balanceB,
        uint256 virtualBalanceA,
        uint256 virtualBalanceB
    ) public pure {
        balanceA = bound(balanceA, _MIN_TOKEN_BALANCE, _MAX_TOKEN_BALANCE);
        balanceB = bound(balanceB, _MIN_TOKEN_BALANCE, _MAX_TOKEN_BALANCE);
        virtualBalanceA = bound(virtualBalanceA, _MIN_TOKEN_BALANCE, _MAX_TOKEN_BALANCE);
        virtualBalanceB = bound(virtualBalanceB, _MIN_TOKEN_BALANCE, _MAX_TOKEN_BALANCE);

        uint256[] memory balancesScaled18 = new uint256[](2);
        balancesScaled18[a] = balanceA;
        balancesScaled18[b] = balanceB;

        uint256[] memory virtualBalances = new uint256[](2);
        virtualBalances[a] = virtualBalanceA;
        virtualBalances[b] = virtualBalanceB;

        (uint256 centeredness, ) = ReClammMath.computeCenteredness(
            balancesScaled18,
            virtualBalances[a],
            virtualBalances[b]
        );

        if (balanceA == 0 || balanceB == 0) {
            assertEq(centeredness, 0);
        } else {
            uint256 expectedCenteredness = (balanceA * virtualBalanceB).divDown(virtualBalanceA * balanceB);
            expectedCenteredness = expectedCenteredness > FixedPoint.ONE
                ? FixedPoint.ONE.divDown(expectedCenteredness)
                : expectedCenteredness;
            assertApproxEqAbs(
                centeredness,
                expectedCenteredness,
                _MAX_CENTEREDNESS_ERROR_ABS,
                "Centeredness does not match"
            );
        }
    }

    function testComputeCenterednessShortCircuit() public pure {
        uint256[] memory balancesScaled18 = new uint256[](2);
        uint256[] memory virtualBalances = new uint256[](2);

        balancesScaled18[b] = 1;
        (uint256 centeredness, ) = ReClammMath.computeCenteredness(
            balancesScaled18,
            virtualBalances[a],
            virtualBalances[b]
        );
        assertEq(centeredness, 0, "(0,1) non-zero centeredness with A=0");

        balancesScaled18[a] = 1;
        balancesScaled18[b] = 0;
        (centeredness, ) = ReClammMath.computeCenteredness(balancesScaled18, virtualBalances[a], virtualBalances[b]);
        assertEq(centeredness, 0, "(1,0) non-zero centeredness with B=0");
    }

    function testPow4__Fuzz(uint256 value) public pure {
        value = bound(value, 10e16, 32e18);

        uint256 mathPow4 = _pow4(value);
        uint256 fpPow4 = FixedPoint.powDown(value, 4e18);

        assertEq(mathPow4, fpPow4, "Pow4 value mismatch");
    }

    function testComputePriceRange__Fuzz(uint256 minPrice, uint256 maxPrice, uint256 targetPrice) public pure {
        minPrice = bound(minPrice, _MIN_PRICE, _MAX_PRICE.divDown(_MIN_PRICE_RATIO));
        maxPrice = bound(maxPrice, minPrice.mulUp(_MIN_PRICE_RATIO), _MAX_PRICE);
        targetPrice = bound(
            targetPrice,
            minPrice + minPrice.mulDown((_MIN_PRICE_RATIO - FixedPoint.ONE) / 2),
            maxPrice - minPrice.mulDown((_MIN_PRICE_RATIO - FixedPoint.ONE) / 2)
        );

        (uint256[] memory realBalances, uint256 virtualBalanceA, uint256 virtualBalanceB, ) = ReClammMath
            .computeTheoreticalPriceRatioAndBalances(minPrice, maxPrice, targetPrice);

        (uint256 computedMinPrice, uint256 computedMaxPrice) = ReClammMath.computePriceRange(
            realBalances,
            virtualBalanceA,
            virtualBalanceB
        );

        // 0.00000001% error tolerance.
        assertApproxEqRel(computedMinPrice, minPrice, 1e8, "Min price does not match");
        assertApproxEqRel(computedMaxPrice, maxPrice, 1e8, "Max price does not match");
    }

    function _computeOutGivenInAllowError(
        uint256[] memory balancesScaled18,
        uint256[] memory virtualBalances,
        uint256 tokenInIndex,
        uint256 tokenOutIndex,
        uint256 amountGivenScaled18
    ) private pure returns (uint256) {
        uint256[] memory totalBalances = new uint256[](balancesScaled18.length);

        totalBalances[a] = balancesScaled18[a] + virtualBalances[a];
        totalBalances[b] = balancesScaled18[b] + virtualBalances[b];

        uint256 invariant = totalBalances[a].mulUp(totalBalances[b]);
        // Total (virtual + real) token out amount that should stay in the pool after the swap.
        uint256 tokenOutPoolAmount = invariant.divUp(totalBalances[tokenInIndex] + amountGivenScaled18);

        vm.assume(tokenOutPoolAmount <= totalBalances[tokenOutIndex]);

        return totalBalances[tokenOutIndex] - tokenOutPoolAmount;
    }
}
