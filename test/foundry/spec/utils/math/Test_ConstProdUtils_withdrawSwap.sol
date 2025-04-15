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
 * @title ConstProdUtils_withdrawSwapTest
 * @dev Tests ConstProdUtils._withdrawSwapQuote against actual DEX withdraw+swap operations
 */
contract Test_ConstProdUtils_withdrawSwap is TestBase_ConstProdUtils {
    
    function setUp() public override {
        super.setUp();
        _initializePools();
    }

    function run() public override {
        // super.run();
        // _initializePools();
    }

    function test_withdrawSwapQuote_camelot() public {
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
        
        // Test withdraw+swap with partial LP tokens
        uint256 liquidityToWithdraw = liquidityGained / 2;
        
        // Get current reserves and total supply
        (uint112 reserveA, uint112 reserveB, uint16 feeA,) = camelotPair.getReserves();
        uint256 totalSupply = camelotPair.totalSupply();
        uint256 feePercent = uint256(feeA);
        
        // Calculate expected output using ConstProdUtils
        uint256 expectedAmountOut = ConstProdUtils._withdrawSwapQuote(
            liquidityToWithdraw,
            totalSupply,
            uint256(reserveA),
            uint256(reserveB),
            feePercent
        );
        
        // Record initial balance of target token
        uint256 initialBalanceA = camelotTokenA.balanceOf(address(this));
        
        // Perform actual withdraw+swap via CamelotV2Service
        uint256 actualAmountOut = CamelotV2Service._withdrawSwapDirect(
            camelotPair,
            camV2Router(),
            liquidityToWithdraw,
            camelotTokenA,
            camelotTokenB,
            address(0) // referrer
        );
        
        uint256 finalBalanceA = camelotTokenA.balanceOf(address(this));
        uint256 receivedAmount = finalBalanceA - initialBalanceA;
        
        // Verify calculations match actual results
        assert(actualAmountOut == expectedAmountOut);
        assert(receivedAmount == actualAmountOut);
        
        console.log("Camelot withdraw+swap test passed:");
        console.log("  Liquidity withdrawn: ", liquidityToWithdraw);
        console.log("  Expected token A:    ", expectedAmountOut);
        console.log("  Actual token A:      ", actualAmountOut);
        console.log("  Received amount:     ", receivedAmount);
        console.log("  Fee percent:         ", feePercent);
    }

    function test_withdrawSwapQuote_uniswap() public {
        // First, get some LP tokens by depositing
        uint256 depositAmountA = 3000e18;
        uint256 depositAmountB = 3000e18;
        
        uniswapTokenA.mint(address(this), depositAmountA);
        uniswapTokenB.mint(address(this), depositAmountB);
        
        uint256 liquidityGained = UniswapV2Service._deposit(
            IUniswapV2Router(address(uniswapV2Router())),
            uniswapTokenA,
            uniswapTokenB,
            depositAmountA,
            depositAmountB
        );
        
        // Test withdraw+swap with partial LP tokens
        uint256 liquidityToWithdraw = liquidityGained / 2;
        
        // Get current reserves and total supply
        (uint112 reserveA, uint112 reserveB,) = uniswapPair.getReserves();
        uint256 totalSupply = uniswapPair.totalSupply();
        uint256 feePercent = 300; // 0.3% standard Uniswap fee
        
        // Calculate expected output using ConstProdUtils
        uint256 expectedAmountOut = ConstProdUtils._withdrawSwapQuote(
            liquidityToWithdraw,
            totalSupply,
            uint256(reserveA),
            uint256(reserveB),
            feePercent
        );
        
        // Record initial balance of target token
        uint256 initialBalanceA = uniswapTokenA.balanceOf(address(this));
        
        // Perform actual withdraw+swap via UniswapV2Service
        uint256 actualAmountOut = UniswapV2Service._withdrawSwapDirect(
            uniswapPair,
            IUniswapV2Router(address(uniswapV2Router())),
            liquidityToWithdraw,
            uniswapTokenA,
            uniswapTokenB
        );
        
        uint256 finalBalanceA = uniswapTokenA.balanceOf(address(this));
        uint256 receivedAmount = finalBalanceA - initialBalanceA;
        
        // Verify calculations match actual results
        assert(actualAmountOut == expectedAmountOut);
        assert(receivedAmount == actualAmountOut);
        
        console.log("Uniswap withdraw+swap test passed:");
        console.log("  Liquidity withdrawn: ", liquidityToWithdraw);
        console.log("  Expected token A:    ", expectedAmountOut);
        console.log("  Actual token A:      ", actualAmountOut);
        console.log("  Received amount:     ", receivedAmount);
        console.log("  Fee percent:         ", feePercent);
    }

    function test_withdrawSwapQuote_differentAmounts() public {
        // First deposit to get LP tokens
        uint256 depositAmountA = 5000e18;
        uint256 depositAmountB = 5000e18;
        
        camelotTokenA.mint(address(this), depositAmountA);
        camelotTokenB.mint(address(this), depositAmountB);
        
        uint256 liquidityGained = CamelotV2Service._deposit(
            camV2Router(),
            camelotTokenA,
            camelotTokenB,
            depositAmountA,
            depositAmountB
        );
        
        // Test different withdrawal amounts
        uint256[] memory withdrawAmounts = new uint256[](4);
        withdrawAmounts[0] = liquidityGained / 10; // 10%
        withdrawAmounts[1] = liquidityGained / 4;  // 25%
        withdrawAmounts[2] = liquidityGained / 2;  // 50%
        withdrawAmounts[3] = liquidityGained * 3 / 4; // 75%
        
        (uint112 reserveA, uint112 reserveB, uint16 feeA,) = camelotPair.getReserves();
        uint256 totalSupply = camelotPair.totalSupply();
        uint256 feePercent = uint256(feeA);
        
        console.log("Testing different withdraw+swap amounts:");
        
        for (uint i = 0; i < withdrawAmounts.length; i++) {
            uint256 expectedOut = ConstProdUtils._withdrawSwapQuote(
                withdrawAmounts[i],
                totalSupply,
                uint256(reserveA),
                uint256(reserveB),
                feePercent
            );
            
            // Verify output is reasonable
            assert(expectedOut > 0);
            
            console.log("  Liquidity amount:", withdrawAmounts[i]);
            console.log("  Token A out:     ", expectedOut);
        }
    }

    function test_withdrawSwapQuote_fullWithdraw() public {
        // First deposit to get LP tokens
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
        
        // Test full withdrawal and swap
        uint256 liquidityToWithdraw = liquidityGained;
        
        // Get current reserves and total supply
        (uint112 reserveA, uint112 reserveB, uint16 feeA,) = camelotPair.getReserves();
        uint256 totalSupply = camelotPair.totalSupply();
        uint256 feePercent = uint256(feeA);
        
        // Calculate expected output using ConstProdUtils
        uint256 expectedAmountOut = ConstProdUtils._withdrawSwapQuote(
            liquidityToWithdraw,
            totalSupply,
            uint256(reserveA),
            uint256(reserveB),
            feePercent
        );
        
        // Record initial balance
        uint256 initialBalanceA = camelotTokenA.balanceOf(address(this));
        
        // Perform actual withdraw+swap
        uint256 actualAmountOut = CamelotV2Service._withdrawSwapDirect(
            camelotPair,
            camV2Router(),
            liquidityToWithdraw,
            camelotTokenA,
            camelotTokenB,
            address(0) // referrer
        );
        
        uint256 finalBalanceA = camelotTokenA.balanceOf(address(this));
        uint256 receivedAmount = finalBalanceA - initialBalanceA;
        
        // Verify calculations match actual results
        assert(actualAmountOut == expectedAmountOut);
        assert(receivedAmount == actualAmountOut);
        
        console.log("Full withdraw+swap test passed:");
        console.log("  Liquidity withdrawn: ", liquidityToWithdraw);
        console.log("  Expected token A:    ", expectedAmountOut);
        console.log("  Actual token A:      ", actualAmountOut);
        console.log("  Received amount:     ", receivedAmount);
    }
} 