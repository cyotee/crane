// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {betterconsole as console} from "../../../../../contracts/utils/vm/foundry/tools/betterconsole.sol";
import {Test} from "forge-std/Test.sol";
import {TestBase_ConstProdUtils} from "./TestBase_ConstProdUtils.sol";
import {ConstProdUtils} from "../../../../../contracts/utils/math/ConstProdUtils.sol";
import {CamelotV2Service} from "../../../../../contracts/protocols/dexes/camelot/v2/utils/CamelotV2Service.sol";
import {UniswapV2Service} from "../../../../../contracts/protocols/dexes/uniswap/v2/utils/UniswapV2Service.sol";
import {IUniswapV2Router} from "../../../../../contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Router.sol";

/**
 * @title ConstProdUtils_swapQuoteTest  
 * @dev Tests ConstProdUtils swap calculations against actual DEX swap operations
 */
contract Test_ConstProdUtils_swapQuote is TestBase_ConstProdUtils {
    
    function setUp() public override {
        super.setUp();
        _initializePools();
    }

    function run() public override {
        // super.run();
        // _initializePools();
    }

    function test_saleQuote_camelot_swap() public {
        uint256 swapAmount = 1000e18;
        
        // Get current reserves and fee
        (uint112 reserveA, uint112 reserveB, uint16 feeA,) = camelotPair.getReserves();
        
        // Determine token order and get correct reserves/fee
        uint256 reserveIn;
        uint256 reserveOut; 
        uint256 feePercent;
        
        if (address(camelotTokenA) == camelotPair.token0()) {
            reserveIn = uint256(reserveA);
            reserveOut = uint256(reserveB);
            feePercent = uint256(feeA);
        } else {
            reserveIn = uint256(reserveB);
            reserveOut = uint256(reserveA);
            feePercent = uint256(feeA);
        }
        
        // Calculate expected output using ConstProdUtils
        uint256 expectedAmountOut = ConstProdUtils._saleQuote(
            swapAmount,
            reserveIn,
            reserveOut,
            feePercent
        );
        
        // Mint tokens and perform actual swap
        camelotTokenA.mint(address(this), swapAmount);
        
        uint256 initialBalanceB = camelotTokenB.balanceOf(address(this));
        
        // Perform actual swap via CamelotV2Service
        uint256 actualAmountOut = CamelotV2Service._swap(
            camV2Router(),
            camelotPair,
            swapAmount,
            camelotTokenA,
            camelotTokenB,
            address(0) // referrer
        );
        
        uint256 finalBalanceB = camelotTokenB.balanceOf(address(this));
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
        (uint112 reserveA, uint112 reserveB,) = uniswapPair.getReserves();
        uint256 feePercent = 300; // 0.3% standard Uniswap fee
        
        // Determine token order and get correct reserves
        uint256 reserveIn;
        uint256 reserveOut;
        
        if (address(uniswapTokenA) == uniswapPair.token0()) {
            reserveIn = uint256(reserveA);
            reserveOut = uint256(reserveB);
        } else {
            reserveIn = uint256(reserveB);
            reserveOut = uint256(reserveA);
        }
        
        // Calculate expected output using ConstProdUtils
        uint256 expectedAmountOut = ConstProdUtils._saleQuote(
            swapAmount,
            reserveIn,
            reserveOut,
            feePercent
        );
        
        // Mint tokens and perform actual swap
        uniswapTokenA.mint(address(this), swapAmount);
        
        uint256 initialBalanceB = uniswapTokenB.balanceOf(address(this));
        
        // Perform actual swap via UniswapV2Service
        uint256 actualAmountOut = UniswapV2Service._swap(
            IUniswapV2Router(address(uniswapV2Router())),
            uniswapPair,
            swapAmount,
            uniswapTokenA,
            uniswapTokenB
        );
        
        uint256 finalBalanceB = uniswapTokenB.balanceOf(address(this));
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
        (uint112 reserveA, uint112 reserveB, uint16 feeA,) = camelotPair.getReserves();
        
        // Determine token order and get correct reserves/fee
        uint256 reserveIn;
        uint256 reserveOut; 
        uint256 feePercent;
        
        if (address(camelotTokenA) == camelotPair.token0()) {
            reserveIn = uint256(reserveA);
            reserveOut = uint256(reserveB);
            feePercent = uint256(feeA);
        } else {
            reserveIn = uint256(reserveB);
            reserveOut = uint256(reserveA);
            feePercent = uint256(feeA);
        }
        
        // Calculate required input using ConstProdUtils
        uint256 expectedAmountIn = ConstProdUtils._purchaseQuote(
            desiredAmountOut,
            reserveIn,
            reserveOut,
            feePercent
        );
        
        // Now verify by performing actual swap with calculated input
        camelotTokenA.mint(address(this), expectedAmountIn);
        
        uint256 initialBalanceB = camelotTokenB.balanceOf(address(this));
        
        // Perform actual swap
        uint256 actualAmountOut = CamelotV2Service._swap(
            camV2Router(),
            camelotPair,
            expectedAmountIn,
            camelotTokenA,
            camelotTokenB,
            address(0)
        );
        
        uint256 finalBalanceB = camelotTokenB.balanceOf(address(this));
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
        
        for (uint i = 0; i < amounts.length; i++) {
            // Get current reserves before each swap (accounts for pool state changes)
            (uint112 reserveA, uint112 reserveB, uint16 feeA,) = camelotPair.getReserves();
            
            uint256 reserveIn = address(camelotTokenA) == camelotPair.token0() ? uint256(reserveA) : uint256(reserveB);
            uint256 reserveOut = address(camelotTokenA) == camelotPair.token0() ? uint256(reserveB) : uint256(reserveA);
            uint256 feePercent = uint256(feeA);
            
            // Calculate expected output using ConstProdUtils with CURRENT reserves
            uint256 expectedOut = ConstProdUtils._saleQuote(
                amounts[i],
                reserveIn,
                reserveOut,
                feePercent
            );
            
            // Mint tokens and execute actual swap
            camelotTokenA.mint(address(this), amounts[i]);
            uint256 initialBalance = camelotTokenB.balanceOf(address(this));
            
            uint256 actualOut = CamelotV2Service._swap(
                camV2Router(),
                camelotPair,
                amounts[i],
                camelotTokenA,
                camelotTokenB,
                address(0)
            );
            
            uint256 finalBalance = camelotTokenB.balanceOf(address(this));
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
        
        uint256 amountOut = ConstProdUtils._saleQuote(
            amountIn,
            reserveIn,
            reserveOut,
            feePercent
        );
        
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