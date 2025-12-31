// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {betterconsole as console} from "contracts/crane/utils/vm/foundry/tools/betterconsole.sol";
// import {Test} from "forge-std/Test.sol";
import {TestBase_ConstProdUtils} from "./TestBase_ConstProdUtils.sol";
import {ConstProdUtils} from "contracts/crane/utils/math/ConstProdUtils.sol";
import {CamelotV2Service} from "contracts/crane/protocols/dexes/camelot/v2/utils/CamelotV2Service.sol";
import {UniswapV2Service} from "contracts/crane/protocols/dexes/uniswap/v2/utils/UniswapV2Service.sol";
import {IUniswapV2Router} from "contracts/crane/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Router.sol";

/**
 * @title ConstProdUtils_swapQuoteTest
 * @dev Tests ConstProdUtils swap calculations against actual DEX swap operations
 */
contract Test_ConstProdUtils_saleQuote is TestBase_ConstProdUtils {
    function setUp() public override {
        super.setUp();
    }

    function run() public override {
        // super.run();
        // _initializePools();
    }

    function test_saleQuote_camelot_swap() public {
        uint256 swapAmount = 1000e18;

        // Get current reserves and fee
        (uint112 reserve0, uint112 reserve1, uint16 token0Fee, uint16 token1Fee) = camelotBalancedPair.getReserves();
        (uint256 reserveIn, uint256 feePercent, uint256 reserveOut, uint256 tokenBFee) = ConstProdUtils._sortReserves(
            address(camelotBalancedTokenA),
            camelotBalancedPair.token0(),
            reserve0,
            uint256(token0Fee),
            reserve1,
            uint256(token1Fee)
        );

        // Calculate expected output using ConstProdUtils
        uint256 expectedAmountOut = ConstProdUtils._saleQuote(swapAmount, reserveIn, reserveOut, feePercent);

        // Mint tokens and perform actual swap
        camelotBalancedTokenA.mint(address(this), swapAmount);

        uint256 initialBalanceB = camelotBalancedTokenB.balanceOf(address(this));

        // Perform actual swap via CamelotV2Service
        uint256 actualAmountOut = CamelotV2Service._swap(
            camV2Router(),
            camelotBalancedPair,
            swapAmount,
            camelotBalancedTokenA,
            camelotBalancedTokenB,
            address(0) // referrer
        );

        uint256 finalBalanceB = camelotBalancedTokenB.balanceOf(address(this));
        uint256 receivedAmount = finalBalanceB - initialBalanceB;

        // Verify calculations match actual results
        assert(actualAmountOut == expectedAmountOut);
        assert(receivedAmount == actualAmountOut);

        console.log("Camelot swap test passed:");
        console.log("  Amount in:       ", swapAmount);
        console.log("  Expected out:    ", expectedAmountOut);
        console.log("  Actual out:      ", actualAmountOut);
        console.log("  Received amount: ", receivedAmount);
        console.log("  Fee percent:     ", feePercent);
    }

    function test_saleQuote_uniswap_swap() public {
        uint256 swapAmount = 1000e18;

        // Get current reserves (Uniswap has fixed 0.3% fee = 300)
        (uint112 reserve0, uint112 reserve1,) = uniswapBalancedPair.getReserves();
        (uint256 reserveIn, uint256 reserveOut) = ConstProdUtils._sortReserves(
            address(uniswapBalancedTokenA), uniswapBalancedPair.token0(), reserve0, reserve1
        );
        uint256 feePercent = 300; // 0.3% standard Uniswap fee

        // Calculate expected output using ConstProdUtils
        uint256 expectedAmountOut = ConstProdUtils._saleQuote(swapAmount, reserveIn, reserveOut, feePercent);

        // Mint tokens and perform actual swap
        uniswapBalancedTokenA.mint(address(this), swapAmount);

        uint256 initialBalanceB = uniswapBalancedTokenB.balanceOf(address(this));

        // Perform actual swap via UniswapV2Service
        uint256 actualAmountOut = UniswapV2Service._swap(
            IUniswapV2Router(address(uniswapV2Router())),
            uniswapBalancedPair,
            swapAmount,
            uniswapBalancedTokenA,
            uniswapBalancedTokenB
        );

        uint256 finalBalanceB = uniswapBalancedTokenB.balanceOf(address(this));
        uint256 receivedAmount = finalBalanceB - initialBalanceB;

        // Verify calculations match actual results
        assert(actualAmountOut == expectedAmountOut);
        assert(receivedAmount == actualAmountOut);

        console.log("Uniswap swap test passed:");
        console.log("  Amount in:       ", swapAmount);
        console.log("  Expected out:    ", expectedAmountOut);
        console.log("  Actual out:      ", actualAmountOut);
        console.log("  Received amount: ", receivedAmount);
        console.log("  Fee percent:     ", feePercent);
    }

    function test_purchaseQuote_camelot() public {
        uint256 desiredAmountOut = 500e18;

        // Get current reserves and fee
        (uint112 reserve0, uint112 reserve1, uint16 token0Fee, uint16 token1Fee) = camelotBalancedPair.getReserves();
        (uint256 reserveIn, uint256 feePercent, uint256 reserveOut, uint256 tokenBFee) = ConstProdUtils._sortReserves(
            address(camelotBalancedTokenA),
            camelotBalancedPair.token0(),
            reserve0,
            uint256(token0Fee),
            reserve1,
            uint256(token1Fee)
        );

        // Calculate required input using ConstProdUtils
        uint256 expectedAmountIn = ConstProdUtils._purchaseQuote(desiredAmountOut, reserveIn, reserveOut, feePercent);

        // Now verify by performing actual swap with calculated input
        camelotBalancedTokenA.mint(address(this), expectedAmountIn);

        uint256 initialBalanceB = camelotBalancedTokenB.balanceOf(address(this));

        // Perform actual swap
        uint256 actualAmountOut = CamelotV2Service._swap(
            camV2Router(),
            camelotBalancedPair,
            expectedAmountIn,
            camelotBalancedTokenA,
            camelotBalancedTokenB,
            address(0)
        );

        uint256 finalBalanceB = camelotBalancedTokenB.balanceOf(address(this));
        uint256 receivedAmount = finalBalanceB - initialBalanceB;

        // The actual output should be at least the desired amount
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

        for (uint256 i = 0; i < amounts.length; i++) {
            // Get current reserves before each swap (accounts for pool state changes)
            (uint112 reserve0, uint112 reserve1, uint16 token0Fee, uint16 token1Fee) = camelotBalancedPair.getReserves();
            (uint256 reserveIn, uint256 feePercent, uint256 reserveOut, uint256 tokenBFee) = ConstProdUtils._sortReserves(
                address(camelotBalancedTokenA),
                camelotBalancedPair.token0(),
                reserve0,
                uint256(token0Fee),
                reserve1,
                uint256(token1Fee)
            );

            // Calculate expected output using ConstProdUtils with CURRENT reserves
            uint256 expectedOut = ConstProdUtils._saleQuote(amounts[i], reserveIn, reserveOut, feePercent);

            // Mint tokens and execute actual swap
            camelotBalancedTokenA.mint(address(this), amounts[i]);
            uint256 initialBalance = camelotBalancedTokenB.balanceOf(address(this));

            uint256 actualOut = CamelotV2Service._swap(
                camV2Router(), camelotBalancedPair, amounts[i], camelotBalancedTokenA, camelotBalancedTokenB, address(0)
            );

            uint256 finalBalance = camelotBalancedTokenB.balanceOf(address(this));
            uint256 receivedAmount = finalBalance - initialBalance;

            // THE KEY ASSERTION: ConstProdUtils calculation must match actual DEX result
            assertEq(expectedOut, actualOut, "ConstProdUtils calculation must match actual swap output");
            assertEq(receivedAmount, actualOut, "Balance change must match returned amount");
        }
    }

    function test_saleQuote_staticCalculation() public pure {
        // Keep one static test for reference
        uint256 amountIn = 1000e18;
        uint256 reserveIn = 10000e18;
        uint256 reserveOut = 10000e18;
        uint256 feePercent = 300; // 0.3%

        uint256 amountOut = ConstProdUtils._saleQuote(amountIn, reserveIn, reserveOut, feePercent);

        // Expected calculation verified manually:
        // amountInWithFee = 1000 * (100000 - 300) / 100000 = 997
        // numerator = 997 * 10000 = 9,970,000
        // denominator = 10000 + 997 = 10,997
        // amountOut = 9,970,000 / 10,997 ≈ 906.63

        assert(amountOut > 900e18 && amountOut < 910e18); // Reasonable range

        console.log("Static calculation test passed:");
        console.log("  Amount out: ", amountOut);
    }
}
