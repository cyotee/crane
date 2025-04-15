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
 * @title ConstProdUtils_withdrawQuoteTest
 * @dev Tests ConstProdUtils._withdrawQuote against actual DEX withdraw operations
 */
contract Test_ConstProdUtils_withdrawQuote is TestBase_ConstProdUtils {
    
    function setUp() public override {
        super.setUp();
        _initializePools();
    }

    function run() public override {
        // super.run();
        // _initializePools();
    }

    function test_withdrawQuote_camelot_partial() public {
        // First, get some LP tokens by depositing
        uint256 depositAmountA = 2000e18;
        uint256 depositAmountB = 2000e18;
        
        camelotTokenA.mint(address(this), depositAmountA);
        camelotTokenB.mint(address(this), depositAmountB);
        
        uint256 liquidityGained = CamelotV2Service._deposit(
            camV2Router(),
            camelotTokenA,
            camelotTokenB,
            depositAmountA,
            depositAmountB
        );
        
        // Now test partial withdrawal (50% of LP tokens)
        uint256 liquidityToWithdraw = liquidityGained / 2;
        
        // Get current reserves and total supply
        (uint112 reserveA, uint112 reserveB,,) = camelotPair.getReserves();
        uint256 totalSupply = camelotPair.totalSupply();
        
        // Calculate expected amounts using ConstProdUtils
        (uint256 expectedAmountA, uint256 expectedAmountB) = ConstProdUtils._withdrawQuote(
            liquidityToWithdraw,
            uint256(reserveA),
            uint256(reserveB),
            totalSupply
        );
        
        // Record token balances before withdrawal
        uint256 initialBalanceA = camelotTokenA.balanceOf(address(this));
        uint256 initialBalanceB = camelotTokenB.balanceOf(address(this));
        
        // Perform actual withdrawal via CamelotV2Service
        (uint256 amount0, uint256 amount1) = CamelotV2Service._withdrawDirect(
            camelotPair,
            liquidityToWithdraw
        );
        
        // Sort amounts based on token order in pair
        uint256 actualAmountA = address(camelotTokenA) == camelotPair.token0() ? amount0 : amount1;
        uint256 actualAmountB = address(camelotTokenA) == camelotPair.token0() ? amount1 : amount0;
        
        // Verify the calculations match actual results
        assert(actualAmountA == expectedAmountA);
        assert(actualAmountB == expectedAmountB);
        
        // Verify tokens were actually transferred
        uint256 finalBalanceA = camelotTokenA.balanceOf(address(this));
        uint256 finalBalanceB = camelotTokenB.balanceOf(address(this));
        
        assert(finalBalanceA - initialBalanceA == actualAmountA);
        assert(finalBalanceB - initialBalanceB == actualAmountB);
        
        console.log("Camelot partial withdraw quote test passed:");
        console.log("  Liquidity withdrawn:", liquidityToWithdraw);
        console.log("  Expected token A:    ", expectedAmountA);
        console.log("  Actual token A:      ", actualAmountA);
        console.log("  Expected token B:    ", expectedAmountB);
        console.log("  Actual token B:      ", actualAmountB);
    }

    function test_withdrawQuote_uniswap_partial() public {
        // First, get some LP tokens by depositing
        uint256 depositAmountA = 2000e18;
        uint256 depositAmountB = 2000e18;
        
        uniswapTokenA.mint(address(this), depositAmountA);
        uniswapTokenB.mint(address(this), depositAmountB);
        
        uint256 liquidityGained = UniswapV2Service._deposit(
            IUniswapV2Router(address(uniswapV2Router())),
            uniswapTokenA,
            uniswapTokenB,
            depositAmountA,
            depositAmountB
        );
        
        // Now test partial withdrawal (50% of LP tokens)
        uint256 liquidityToWithdraw = liquidityGained / 2;
        
        // Get current reserves and total supply
        (uint112 reserveA, uint112 reserveB,) = uniswapPair.getReserves();
        uint256 totalSupply = uniswapPair.totalSupply();
        
        // Calculate expected amounts using ConstProdUtils
        (uint256 expectedAmountA, uint256 expectedAmountB) = ConstProdUtils._withdrawQuote(
            liquidityToWithdraw,
            uint256(reserveA),
            uint256(reserveB),
            totalSupply
        );
        
        // Record token balances before withdrawal
        uint256 initialBalanceA = uniswapTokenA.balanceOf(address(this));
        uint256 initialBalanceB = uniswapTokenB.balanceOf(address(this));
        
        // Perform actual withdrawal via UniswapV2Service
        (uint256 amount0, uint256 amount1) = UniswapV2Service._withdrawDirect(
            uniswapPair,
            liquidityToWithdraw
        );
        
        // Sort amounts based on token order in pair
        uint256 actualAmountA = address(uniswapTokenA) == uniswapPair.token0() ? amount0 : amount1;
        uint256 actualAmountB = address(uniswapTokenA) == uniswapPair.token0() ? amount1 : amount0;
        
        // Verify the calculations match actual results
        assert(actualAmountA == expectedAmountA);
        assert(actualAmountB == expectedAmountB);
        
        // Verify tokens were actually transferred
        uint256 finalBalanceA = uniswapTokenA.balanceOf(address(this));
        uint256 finalBalanceB = uniswapTokenB.balanceOf(address(this));
        
        assert(finalBalanceA - initialBalanceA == actualAmountA);
        assert(finalBalanceB - initialBalanceB == actualAmountB);
        
        console.log("Uniswap partial withdraw quote test passed:");
        console.log("  Liquidity withdrawn:", liquidityToWithdraw);
        console.log("  Expected token A:    ", expectedAmountA);
        console.log("  Actual token A:      ", actualAmountA);
        console.log("  Expected token B:    ", expectedAmountB);
        console.log("  Actual token B:      ", actualAmountB);
    }

    function test_withdrawQuote_camelot_full() public {
        // First, get some LP tokens by depositing
        uint256 depositAmountA = 3000e18;
        uint256 depositAmountB = 3000e18;
        
        camelotTokenA.mint(address(this), depositAmountA);
        camelotTokenB.mint(address(this), depositAmountB);
        
        uint256 liquidityGained = CamelotV2Service._deposit(
            camV2Router(),
            camelotTokenA,
            camelotTokenB,
            depositAmountA,
            depositAmountB
        );
        
        // Test full withdrawal
        uint256 liquidityToWithdraw = liquidityGained;
        
        // Get current reserves and total supply
        (uint112 reserveA, uint112 reserveB,,) = camelotPair.getReserves();
        uint256 totalSupply = camelotPair.totalSupply();
        
        // Calculate expected amounts using ConstProdUtils
        (uint256 expectedAmountA, uint256 expectedAmountB) = ConstProdUtils._withdrawQuote(
            liquidityToWithdraw,
            uint256(reserveA),
            uint256(reserveB),
            totalSupply
        );
        
        // Record token balances before withdrawal
        // uint256 initialBalanceA = camelotTokenA.balanceOf(address(this));
        // uint256 initialBalanceB = camelotTokenB.balanceOf(address(this));
        
        // Perform actual withdrawal via CamelotV2Service
        (uint256 amount0, uint256 amount1) = CamelotV2Service._withdrawDirect(
            camelotPair,
            liquidityToWithdraw
        );
        
        // Sort amounts based on token order in pair
        uint256 actualAmountA = address(camelotTokenA) == camelotPair.token0() ? amount0 : amount1;
        uint256 actualAmountB = address(camelotTokenA) == camelotPair.token0() ? amount1 : amount0;
        
        // Verify the calculations match actual results
        assert(actualAmountA == expectedAmountA);
        assert(actualAmountB == expectedAmountB);
        
        console.log("Camelot full withdraw quote test passed:");
        console.log("  Liquidity withdrawn:", liquidityToWithdraw);
        console.log("  Expected token A:    ", expectedAmountA);
        console.log("  Actual token A:      ", actualAmountA);
        console.log("  Expected token B:    ", expectedAmountB);
        console.log("  Actual token B:      ", actualAmountB);
    }

    function test_withdrawQuoteOneSide_validation() public {
        // First deposit to get LP tokens
        uint256 depositAmountA = 3000e18;
        uint256 depositAmountB = 3000e18;
        
        camelotTokenA.mint(address(this), depositAmountA);
        camelotTokenB.mint(address(this), depositAmountB);
        
        uint256 liquidityGained = CamelotV2Service._deposit(
            camV2Router(),
            camelotTokenA,
            camelotTokenB,
            depositAmountA,
            depositAmountB
        );
        
        // Test withdrawing 50% of LP tokens for single token output
        uint256 liquidityToWithdraw = liquidityGained / 2;
        
        // Get current state
        (uint112 reserveA, uint112 reserveB, uint16 feeA,) = camelotPair.getReserves();
        uint256 totalSupply = camelotPair.totalSupply();
        
        // Calculate expected single-sided output using ConstProdUtils
        uint256 expectedAmountOut = ConstProdUtils._withdrawQuoteOneSide(
            liquidityToWithdraw,
            totalSupply,
            uint256(reserveA),
            uint256(reserveB),
            uint256(feeA)
        );
        
        // Execute actual withdraw+swap for single token via CamelotV2Service
        uint256 initialBalanceA = camelotTokenA.balanceOf(address(this));
        
        uint256 actualAmountOut = CamelotV2Service._withdrawSwapDirect(
            camelotPair,
            camV2Router(),
            liquidityToWithdraw,
            camelotTokenA,
            camelotTokenB,
            address(0)
        );
        
        uint256 finalBalanceA = camelotTokenA.balanceOf(address(this));
        uint256 receivedAmount = finalBalanceA - initialBalanceA;
        
        // THE KEY ASSERTION: ConstProdUtils calculation must match actual single-sided withdraw result
        assertEq(expectedAmountOut, actualAmountOut, "ConstProdUtils _withdrawQuoteOneSide must match actual withdraw+swap output");
        assertEq(receivedAmount, actualAmountOut, "Balance change must match returned amount");
    }
} 