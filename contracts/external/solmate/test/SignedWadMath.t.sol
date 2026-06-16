// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Vm} from "forge-std/Vm.sol";

import {DSTestPlus} from "./utils/DSTestPlus.sol";

import {wadMul, wadDiv} from "../utils/SignedWadMath.sol";

contract SignedWadMathTest is DSTestPlus {
    Vm internal constant vm = Vm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    function testWadMul(uint256 x, uint256 y, bool negX, bool negY) public {
        x = bound(x, 0, 99999999999999e18);
        y = bound(x, 0, 99999999999999e18);

        int256 xPrime = negX ? -int256(x) : int256(x);
        int256 yPrime = negY ? -int256(y) : int256(y);

        assertEq(wadMul(xPrime, yPrime), (xPrime * yPrime) / 1e18);
    }

    function test_RevertWhen_WadMulEdgeCase() public {
        int256 x = -1;
        int256 y = type(int256).min;

        vm.expectRevert();
        wadMul(x, y);
    }

    function test_RevertWhen_WadMulEdgeCase2() public {
        int256 x = type(int256).min;
        int256 y = -1;

        vm.expectRevert();
        wadMul(x, y);
    }

    function test_RevertWhen_WadMulOverflow(uint256 xSeed, uint256 ySeed, bool negX, bool negY) public {
        // Construct x and y whose product overflows int256 (so wadMul must revert),
        // rather than filtering fuzzed inputs and exhausting vm.assume's reject budget.
        // A product overflows when its magnitude exceeds |int256.min| == 2**255, which
        // covers both positive (> max) and negative (< min) overflow.
        uint256 overflowMag = uint256(type(int256).max) + 1; // 2**255 == |int256.min|
        uint256 xMag = bound(xSeed, 2, uint256(type(int256).max));
        uint256 yMag = bound(ySeed, overflowMag / xMag + 1, uint256(type(int256).max));
        int256 x = negX ? -int256(xMag) : int256(xMag);
        int256 y = negY ? -int256(yMag) : int256(yMag);

        vm.expectRevert();
        wadMul(x, y);
    }

    function testWadDiv(uint256 x, uint256 y, bool negX, bool negY) public {
        x = bound(x, 0, 99999999e18);
        y = bound(x, 1, 99999999e18);

        int256 xPrime = negX ? -int256(x) : int256(x);
        int256 yPrime = negY ? -int256(y) : int256(y);

        assertEq(wadDiv(xPrime, yPrime), (xPrime * 1e18) / yPrime);
    }

    function test_RevertWhen_WadDivOverflow(uint256 xSeed, bool negX, int256 y) public {
        // Construct an x whose magnitude guarantees x * WAD overflows int256 (so wadDiv
        // must revert), rather than filtering fuzzed inputs and exhausting vm.assume.
        // x * WAD overflows when its magnitude exceeds |int256.min| == 2**255, covering
        // both positive (> max) and negative (< min) overflow.
        vm.assume(y != 0);
        uint256 overflowMag = uint256(type(int256).max) + 1; // 2**255 == |int256.min|
        uint256 xMag = bound(xSeed, overflowMag / 1e18 + 1, uint256(type(int256).max));
        int256 x = negX ? -int256(xMag) : int256(xMag);

        vm.expectRevert();
        wadDiv(x, y);
    }

    function test_RevertWhen_WadDivZeroDenominator(int256 x) public {
        vm.expectRevert();
        wadDiv(x, 0);
    }
}
