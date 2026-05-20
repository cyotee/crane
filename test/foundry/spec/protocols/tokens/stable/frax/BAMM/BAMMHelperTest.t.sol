// SPDX-License-Identifier: ISC
pragma solidity ^0.8.35;

/// @notice Port of `lib/frax-solidity/src/hardhat/test/BAMM/BAMMHelper.js`.

import {TestBase_FraxBAMM} from "./TestBase_FraxBAMM.sol";
import {BAMMHelper} from "@crane/contracts/protocols/tokens/stable/frax/BAMM/BAMMHelper.sol";
import {IERC20} from "@crane/contracts/external/openzeppelin-contracts/token/ERC20/IERC20.sol";

contract BAMMHelperTest is TestBase_FraxBAMM {
    BAMMHelper internal helper;

    function setUp() public {
        _fraxBammSetUp();
        helper = new BAMMHelper();
    }

    function test_setupContracts() public {
        _createPair(9970);
        assertTrue(address(pair) != address(0));
    }

    function test_getSwapAmount_estimateLiquidityUnbalanced_fixed1() public {
        uint256 resA = 50_000_000_000_000;
        uint256 resB = 100_000_000_000_000_000_000_000_000;
        uint256 tknA = 8_000_000_000_000;
        uint256 tknB = 700_000_000_000_000_000_000_000_000_000;
        uint256 fee = 9908;

        _runLiquidityUnbalancedCase(resA, resB, tknA, tknB, fee);
    }

    function test_getSwapAmount_estimateLiquidityUnbalanced_fixed2() public {
        uint256 resA = 800_000_000_000;
        uint256 resB = 4_000_000_000_000_000_000_000_000;
        uint256 tknA = 80_000_000_000_000;
        uint256 tknB = 400_000_000_000_000_000_000_000;
        uint256 fee = 9985;

        _runLiquidityUnbalancedCase(resA, resB, tknA, tknB, fee);
    }

    function test_getSwapAmount_directSwap_deep() public {
        uint256 resA = 800_000_000_000_000_000_000_000_000;
        uint256 resB = 40_000_000_000_000_000_000_000_000;
        uint256 tknA = 1_000_000_000_000_000_000_000_000_000_000_000;
        uint256 tknB = 40_000_000_000_000_000_000;
        uint256 fee = 9906;

        _createPair(fee);
        _mintPairLiquidity(resA, resB);

        int256 swapAmount = helper.getSwapAmount(int256(resA), int256(resB), int256(tknA), int256(tknB), int256(fee));

        if (swapAmount >= 0) {
            uint256 amountOut = _getAmountOut(resA, resB, fee, uint256(swapAmount));
            token0.transfer(address(pair), uint256(swapAmount));
            if (amountOut > 0) pair.swap(0, amountOut, fraxOwner, "");

            (uint112 r0, uint112 r1,) = pair.getReserves();
            uint256 expectedTknB = (tknA - uint256(swapAmount)) * uint256(r1) / uint256(r0);
            uint256 precision = _min5(10_000_000, uint256(r0), uint256(r1), tknA - uint256(swapAmount), tknB + amountOut) / 10;
            int256 diff = (int256(expectedTknB) - int256(tknB + amountOut)) * int256(precision) / int256(expectedTknB);
            assertEq(diff, 0);
        } else {
            uint256 swapAbs = uint256(-swapAmount);
            uint256 amountOut = _getAmountOut(resB, resA, fee, swapAbs);
            token1.transfer(address(pair), swapAbs);
            if (amountOut > 0) pair.swap(amountOut, 0, fraxOwner, "");

            (uint112 r0, uint112 r1,) = pair.getReserves();
            uint256 expectedTknB = (tknA + amountOut) * uint256(r1) / uint256(r0);
            uint256 precision = _min5(10_000_000, uint256(r0), uint256(r1), tknA + amountOut, tknB - swapAbs) / 10;
            int256 diff = (int256(expectedTknB) - int256(tknB - swapAbs)) * int256(precision) / int256(expectedTknB);
            assertEq(diff, 0);
        }
    }



    function test_fuzz_getSwapAmount_loop() public {
        for (uint256 i = 0; i < 100; i++) {
            _fuzzGetSwapAmountCase(i);
        }
    }

    function test_fuzz_estimateLiquidity_loop() public {
        for (uint256 i = 0; i < 100; i++) {
            _fuzzEstimateLiquidityCase(i);
        }
    }

    /// @dev Port of `BAMMHelper.js` estimateGas + getSwapAmountSolve parity (fixed1 constants).
    function test_estimateGas_getSwapAmountSolve_matchesGetSwapAmount() public {
        uint256 resA = 50_000_000_000_000;
        uint256 resB = 100_000_000_000_000_000_000_000_000;
        uint256 tknA = 8_000_000_000_000;
        uint256 tknB = 700_000_000_000_000_000_000_000_000_000;
        uint256 fee = 9908;

        _runLiquidityUnbalancedCase(resA, resB, tknA, tknB, fee);

        int256 swapAmount = helper.getSwapAmount(int256(resA), int256(resB), int256(tknA), int256(tknB), int256(fee));
        int256 swapSolve = helper.getSwapAmountSolve(int256(resA), int256(resB), int256(tknA), int256(tknB), int256(fee));
        assertApproxEqRel(swapAmount, swapSolve, 1e12);
    }

    /// @dev Port of `BAMMHelper.js` getSwapAmount 1 (scaled precision, token0-heavy deposit).
    function test_getSwapAmount_scaled_precision_token0Heavy() public view {
        uint256 precision = 1e6;
        uint256 fee = 9970;
        for (uint256 i = 0; i < 32; i++) {
            if (!_scaledCaseFits(precision)) break;

            uint256 resA = 1000 * precision;
            uint256 resB = 1000 * precision;
            uint256 tknA = 51 * precision;
            uint256 tknB = 50 * precision;

            int256 swapAmount = helper.getSwapAmount(int256(resA), int256(resB), int256(tknA), int256(tknB), int256(fee));
            assertEq(uint256(swapAmount) * 1e5 / precision, 47_679);

            precision *= 10;
        }
    }

    /// @dev Port of `BAMMHelper.js` getSwapAmount 2 (scaled precision, token1-heavy deposit).
    function test_getSwapAmount_scaled_precision_token1Heavy() public view {
        uint256 precision = 1e6;
        uint256 fee = 9970;
        for (uint256 i = 0; i < 32; i++) {
            if (!_scaledCaseFits(precision)) break;

            uint256 resA = 1000 * precision;
            uint256 resB = 1000 * precision;
            uint256 tknA = 50 * precision;
            uint256 tknB = 51 * precision;

            int256 swapAmount = helper.getSwapAmount(int256(resA), int256(resB), int256(tknA), int256(tknB), int256(fee));
            assertEq(uint256(-swapAmount) * 1e5 / precision, 47_679);

            precision *= 10;
        }
    }

    /// @dev Port of `BAMMHelper.js` getSwapAmount 3 (swap path + reserve balance check across scales).
    function test_getSwapAmount_scaled_precision_swapPath() public {
        uint256 precision = 1e6;
        uint256 fee = 9970;
        for (uint256 i = 0; i < 32; i++) {
            if (!_scaledCaseFits(precision)) break;

            uint256 resA = 1000 * precision;
            uint256 resB = 1000 * precision;
            uint256 tknA = 51 * precision;
            uint256 tknB = 50 * precision;

            _createPair(fee);
            _mintPairLiquidity(resA, resB);

            int256 swapAmount = helper.getSwapAmount(int256(resA), int256(resB), int256(tknA), int256(tknB), int256(fee));
            uint256 amountOut = _getAmountOut(resA, resB, fee, uint256(swapAmount));
            token0.transfer(address(pair), uint256(swapAmount));
            if (amountOut > 0) pair.swap(0, amountOut, fraxOwner, "");

            (uint112 r0, uint112 r1,) = pair.getReserves();
            uint256 expectedTknB = (tknA - uint256(swapAmount)) * uint256(r1) / uint256(r0);
            int256 diff = (int256(expectedTknB) - int256(tknB + amountOut)) * int256(10_000_000) / int256(expectedTknB);
            assertEq(diff, 0);

            precision *= 10;
        }
    }

    /// @dev Port of `BAMMHelper.js` addLiquidityUnbalanced 1.
    function test_addLiquidityUnbalanced_scaled_token0Heavy() public {
        uint256 precision = 1e6;
        uint256 fee = 9970;
        for (uint256 i = 0; i < 32; i++) {
            if (!_scaledCaseFits(precision)) break;
            _runLiquidityUnbalancedCase(1000 * precision, 1000 * precision, 51 * precision, 50 * precision, fee);
            precision *= 10;
        }
    }

    /// @dev Port of `BAMMHelper.js` addLiquidityUnbalanced 2.
    function test_addLiquidityUnbalanced_scaled_token1Heavy() public {
        uint256 precision = 1e6;
        uint256 fee = 9970;
        for (uint256 i = 0; i < 32; i++) {
            if (!_scaledCaseFits(precision)) break;
            _runLiquidityUnbalancedCase(1000 * precision, 1000 * precision, 50 * precision, 51 * precision, fee);
            precision *= 10;
        }
    }

    /// @dev Stops scaled loops before Fraxswap uint112 reserve overflow / helper int overflow.
    function _scaledCaseFits(uint256 precision) internal pure returns (bool) {
        uint256 max = uint256(type(uint112).max);
        return 51 * precision <= max && 1000 * precision <= max;
    }

    function _fuzzGetSwapAmountCase(uint256 i) internal {
        uint256 r = uint256(keccak256(abi.encode("getSwapAmount", i)));
        uint256 r2 = uint256(keccak256(abi.encode("getSwapAmountB", i)));
        uint256 resA = ((r % 9) + 1) * _pow10((r >> 8) % 34 + 1);
        uint256 resB = ((r2 % 9) + 1) * _pow10((r2 >> 8) % 34 + 1);
        uint256 tknA = ((uint256(keccak256(abi.encode("tknA", i))) % 9) + 1)
            * _pow10((uint256(keccak256(abi.encode("tknA", i))) >> 8) % 34 + 1);
        uint256 tknB = ((uint256(keccak256(abi.encode("tknB", i))) % 9) + 1)
            * _pow10((uint256(keccak256(abi.encode("tknB", i))) >> 8) % 34 + 1);
        uint256 fee = 9999 - (r % 100);

        if (resA + tknA >= 2_192_300_000_000_000_000_000_000_000) return;
        if (resB + tknB >= 2_192_300_000_000_000_000_000_000_000) return;
        if (resA * resB <= 1_000_000) return;

        _createPair(fee);
        _mintPairLiquidity(resA, resB);

        int256 swapAmount = helper.getSwapAmount(int256(resA), int256(resB), int256(tknA), int256(tknB), int256(fee));
        _assertSwapBalances(resA, resB, tknA, tknB, fee, swapAmount);
    }

    function _fuzzEstimateLiquidityCase(uint256 i) internal {
        uint256 r = uint256(keccak256(abi.encode("estLiq", i)));
        uint256 resA = ((r % 9) + 1) * _pow10((r >> 8) % 34 + 1);
        uint256 resB = ((uint256(keccak256(abi.encode("estLiqB", i))) % 9) + 1)
            * _pow10((uint256(keccak256(abi.encode("estLiqB", i))) >> 8) % 34 + 1);
        uint256 tknA = ((uint256(keccak256(abi.encode("estLiqA", i))) % 9) + 1)
            * _pow10((uint256(keccak256(abi.encode("estLiqA", i))) >> 8) % 34 + 1);
        uint256 tknB = ((uint256(keccak256(abi.encode("estLiqT", i))) % 9) + 1)
            * _pow10((uint256(keccak256(abi.encode("estLiqT", i))) >> 8) % 34 + 1);
        uint256 fee = 9999 - (r % 100);

        if (resA + tknA >= 2_192_300_000_000_000_000_000_000_000) return;
        if (resB + tknB >= 2_192_300_000_000_000_000_000_000_000) return;
        if (resA * resB <= 1_000_000) return;

        _createPair(fee);
        _mintPairLiquidity(resA, resB);
        _fundFraxUser(fraxUser1, tknA + tknB);

        vm.startPrank(fraxUser1);
        IERC20(address(token0)).approve(address(helper), tknA);
        IERC20(address(token1)).approve(address(helper), tknB);
        (uint256 estimateLiquidity,) = helper.estimateLiquidityUnbalanced(tknA, tknB, pair, fee, true);
        helper.addLiquidityUnbalanced(tknA, tknB, 0, pair, fee, true);
        vm.stopPrank();

        assertEq(pair.balanceOf(fraxUser1), estimateLiquidity);
    }

    function _assertSwapBalances(uint256 resA, uint256 resB, uint256 tknA, uint256 tknB, uint256 fee, int256 swapAmount)
        internal
    {
        if (swapAmount >= 0) {
            uint256 amountOut = _getAmountOut(resA, resB, fee, uint256(swapAmount));
            token0.transfer(address(pair), uint256(swapAmount));
            if (amountOut > 0) pair.swap(0, amountOut, fraxOwner, "");
            (uint112 r0, uint112 r1,) = pair.getReserves();
            uint256 expectedTknB = (tknA - uint256(swapAmount)) * uint256(r1) / uint256(r0);
            uint256 precision =
                _min5(10_000_000, uint256(r0), uint256(r1), tknA - uint256(swapAmount), tknB + amountOut) / 10;
            int256 diff = (int256(expectedTknB) - int256(tknB + amountOut)) * int256(precision) / int256(expectedTknB);
            assertEq(diff, 0);
        } else {
            uint256 swapAbs = uint256(-swapAmount);
            uint256 amountOut = _getAmountOut(resB, resA, fee, swapAbs);
            token1.transfer(address(pair), swapAbs);
            if (amountOut > 0) pair.swap(amountOut, 0, fraxOwner, "");
            (uint112 r0, uint112 r1,) = pair.getReserves();
            uint256 expectedTknB = (tknA + amountOut) * uint256(r1) / uint256(r0);
            uint256 precision = _min5(10_000_000, uint256(r0), uint256(r1), tknA + amountOut, tknB - swapAbs) / 10;
            int256 diff = (int256(expectedTknB) - int256(tknB - swapAbs)) * int256(precision) / int256(expectedTknB);
            assertEq(diff, 0);
        }
    }

    function _runLiquidityUnbalancedCase(uint256 resA, uint256 resB, uint256 tknA, uint256 tknB, uint256 fee) internal {
        _createPair(fee);
        _mintPairLiquidity(resA, resB);

        int256 swapAmount = helper.getSwapAmount(int256(resA), int256(resB), int256(tknA), int256(tknB), int256(fee));
        assertTrue(swapAmount != 0);

        _fundFraxUser(fraxUser1, tknA + tknB);
        vm.startPrank(fraxUser1);
        IERC20(address(token0)).approve(address(helper), tknA);
        IERC20(address(token1)).approve(address(helper), tknB);
        (uint256 estimateLiquidity,) = helper.estimateLiquidityUnbalanced(tknA, tknB, pair, fee, true);
        helper.addLiquidityUnbalanced(tknA, tknB, 0, pair, fee, true);
        vm.stopPrank();

        assertEq(pair.balanceOf(fraxUser1), estimateLiquidity);
    }
}