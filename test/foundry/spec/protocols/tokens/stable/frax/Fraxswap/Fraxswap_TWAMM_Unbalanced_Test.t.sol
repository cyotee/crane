// SPDX-License-Identifier: ISC
pragma solidity ^0.8.35;

/// @notice Port of `fraxswap-twamm-test-unbalanced.js` (extreme reserve skew).

import {TestBase_FraxswapTWAMM} from "./TestBase_FraxswapTWAMM.sol";
import {TwammTestMath} from "./TwammTestMath.sol";

contract Fraxswap_TWAMM_Unbalanced_Test is TestBase_FraxswapTWAMM {
    uint256 internal constant LIQ0 = 1_000_000_000e18;
    uint256 internal constant LIQ1 = 1_000_000_000;

    function setUp() public {
        _twammSetUp();
        token0.transfer(address(pair), LIQ0);
        token1.transfer(address(pair), LIQ1);
        pair.mint(fraxOwner);
    }

    /// @dev Mirrors upstream single-sided test; tolerance 1% (order is split across intervals).
    function test_singleSidedOrder_unbalancedLiquidity(uint256 multiplier) public {
        multiplier = bound(multiplier, 1, 3000);

        uint256 amountIn = 10e18 * multiplier;
        _fundToken0(fraxUser1, amountIn);

        (uint112 r0, uint112 r1,) = pair.getReserves();
        uint256 expectedOut = TwammTestMath.expectedSwapOut(amountIn, r0, r1, 9970);

        _longTermSwap0To1(fraxUser1, amountIn, 10);
        _mineAndExecuteVirtualOrders(11);

        uint256 bal1Before = token1.balanceOf(fraxUser1);
        _withdrawProceeds(fraxUser1, 0);
        uint256 actualOut = token1.balanceOf(fraxUser1) - bal1Before;

        uint256 tolerance = expectedOut / 100;
        if (tolerance < 3) tolerance = 3;
        assertApproxEqAbs(actualOut, expectedOut, tolerance);
    }
}
