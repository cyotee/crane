// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {betterconsole as console} from "contracts/utils/vm/foundry/tools/betterconsole.sol";
import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";
import {CamelotV2Service} from "@crane/contracts/protocols/dexes/camelot/v2/CamelotV2Service.sol";
import {TestBase_ConstProdUtils_Camelot} from "@crane/test/foundry/spec/utils/math/ConstProdUtils.sol/TestBase_ConstProdUtils_Camelot.sol";

contract ConstProdUtils_swapQuote_Camelot_Test is TestBase_ConstProdUtils_Camelot {
    function setUp() public override {
        TestBase_ConstProdUtils_Camelot.setUp();
    }

    function test_saleQuote_camelot_swap() public {
        uint256 swapAmount = 1000e18;

        _initializeCamelotBalancedPools();

        (uint112 reserve0, uint112 reserve1, uint16 token0Fee, uint16 token1Fee) = camelotBalancedPair.getReserves();
        (uint256 reserveIn, uint256 feePercent, uint256 reserveOut, uint256 tokenBFee) = ConstProdUtils._sortReserves(
            address(camelotBalancedTokenA),
            camelotBalancedPair.token0(),
            reserve0,
            uint256(token0Fee),
            reserve1,
            uint256(token1Fee)
        );

        uint256 expectedAmountOut = ConstProdUtils._saleQuote(swapAmount, reserveIn, reserveOut, feePercent);

        camelotBalancedTokenA.mint(address(this), swapAmount);
        uint256 initialBalanceB = camelotBalancedTokenB.balanceOf(address(this));

        uint256 actualAmountOut = CamelotV2Service._swap(
            camelotV2Router,
            camelotBalancedPair,
            swapAmount,
            camelotBalancedTokenA,
            camelotBalancedTokenB,
            address(0)
        );

        uint256 finalBalanceB = camelotBalancedTokenB.balanceOf(address(this));
        uint256 receivedAmount = finalBalanceB - initialBalanceB;

        assert(actualAmountOut == expectedAmountOut);
        assert(receivedAmount == actualAmountOut);

        console.log("Camelot swap test passed:");
        console.log("  Amount in:       ", swapAmount);
        console.log("  Expected out:    ", expectedAmountOut);
        console.log("  Actual out:      ", actualAmountOut);
        console.log("  Received amount: ", receivedAmount);
        console.log("  Fee percent:     ", feePercent);
    }

    function test_purchaseQuote_camelot() public {
        uint256 desiredAmountOut = 500e18;
        _initializeCamelotBalancedPools();

        (uint112 reserve0, uint112 reserve1, uint16 token0Fee, uint16 token1Fee) = camelotBalancedPair.getReserves();
        (uint256 reserveIn, uint256 feePercent, uint256 reserveOut, uint256 tokenBFee) = ConstProdUtils._sortReserves(
            address(camelotBalancedTokenA),
            camelotBalancedPair.token0(),
            reserve0,
            uint256(token0Fee),
            reserve1,
            uint256(token1Fee)
        );

        uint256 expectedAmountIn = ConstProdUtils._purchaseQuote(desiredAmountOut, reserveIn, reserveOut, feePercent);

        camelotBalancedTokenA.mint(address(this), expectedAmountIn);

        uint256 initialBalanceB = camelotBalancedTokenB.balanceOf(address(this));

        uint256 actualAmountOut = CamelotV2Service._swap(
            camelotV2Router,
            camelotBalancedPair,
            expectedAmountIn,
            camelotBalancedTokenA,
            camelotBalancedTokenB,
            address(0)
        );

        uint256 finalBalanceB = camelotBalancedTokenB.balanceOf(address(this));
        uint256 receivedAmount = finalBalanceB - initialBalanceB;

        assert(actualAmountOut >= desiredAmountOut);
        assert(receivedAmount >= desiredAmountOut);

        console.log("Camelot purchase quote test passed:");
        console.log("  Desired out:     ", desiredAmountOut);
        console.log("  Calculated in:   ", expectedAmountIn);
        console.log("  Actual out:      ", actualAmountOut);
        console.log("  Received amount: ", receivedAmount);
    }

    function test_saleQuote_differentAmounts() public {
        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 100e18;
        amounts[1] = 1000e18;
        amounts[2] = 5000e18;

        _initializeCamelotBalancedPools();

        for (uint256 i = 0; i < amounts.length; i++) {
            (uint112 reserve0, uint112 reserve1, uint16 token0Fee, uint16 token1Fee) = camelotBalancedPair.getReserves();
            (uint256 reserveIn, uint256 feePercent, uint256 reserveOut, uint256 tokenBFee) = ConstProdUtils._sortReserves(
                address(camelotBalancedTokenA),
                camelotBalancedPair.token0(),
                reserve0,
                uint256(token0Fee),
                reserve1,
                uint256(token1Fee)
            );

            uint256 expectedOut = ConstProdUtils._saleQuote(amounts[i], reserveIn, reserveOut, feePercent);

            camelotBalancedTokenA.mint(address(this), amounts[i]);
            uint256 initialBalance = camelotBalancedTokenB.balanceOf(address(this));

            uint256 actualOut = CamelotV2Service._swap(
                camelotV2Router, camelotBalancedPair, amounts[i], camelotBalancedTokenA, camelotBalancedTokenB, address(0)
            );

            uint256 finalBalance = camelotBalancedTokenB.balanceOf(address(this));
            uint256 receivedAmount = finalBalance - initialBalance;

            assertEq(expectedOut, actualOut, "ConstProdUtils calculation must match actual swap output");
            assertEq(receivedAmount, actualOut, "Balance change must match returned amount");
        }
    }
}
