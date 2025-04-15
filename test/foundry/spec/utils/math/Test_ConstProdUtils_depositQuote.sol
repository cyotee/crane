// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {betterconsole as console} from "../../../../../contracts/utils/vm/foundry/tools/betterconsole.sol";
// import {Test} from "forge-std/Test.sol";
import {TestBase_ConstProdUtils} from "./TestBase_ConstProdUtils.sol";
import {ConstProdUtils} from "../../../../../contracts/utils/math/ConstProdUtils.sol";
import {CamelotV2Service} from "../../../../../contracts/protocols/dexes/camelot/v2/utils/CamelotV2Service.sol";
import {UniswapV2Service} from "../../../../../contracts/protocols/dexes/uniswap/v2/utils/UniswapV2Service.sol";
import {IUniswapV2Router} from "../../../../../contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Router.sol";

/**
 * @title ConstProdUtils_depositQuoteTest
 * @dev Tests ConstProdUtils._depositQuote against actual DEX deposit operations
 */
contract Test_ConstProdUtils_depositQuote is TestBase_ConstProdUtils {
    
    function setUp() public override {
        super.setUp();
        _initializePools();
    }

    function run() public override {
        super.run();
        // _initializePools();
    }

    function test_depositQuote_camelot_balancedDeposit() public {
        uint256 amountA = 1000e18;
        uint256 amountB = 1000e18;
        
        // Get current reserves
        (uint112 reserveA, uint112 reserveB,,) = camelotPair.getReserves();
        uint256 totalSupply = camelotPair.totalSupply();
        
        // Calculate expected liquidity using ConstProdUtils
        uint256 expectedLiquidity = ConstProdUtils._depositQuote(
            amountA,
            amountB,
            uint256(reserveA),
            uint256(reserveB),
            totalSupply
        );
        
        // Mint tokens for actual deposit
        camelotTokenA.mint(address(this), amountA);
        camelotTokenB.mint(address(this), amountB);
        
        // Record initial LP balance
        uint256 initialLPBalance = camelotPair.balanceOf(address(this));
        
        // Perform actual deposit via CamelotV2Service
        uint256 actualLiquidity = CamelotV2Service._deposit(
            camV2Router(),
            camelotTokenA,
            camelotTokenB,
            amountA,
            amountB
        );
        
        // Verify the calculation matches actual result
        assert(actualLiquidity == expectedLiquidity); // Manual assert since assertEq not available
        
        // Verify LP tokens were actually minted
        uint256 finalLPBalance = camelotPair.balanceOf(address(this));
        assert(finalLPBalance - initialLPBalance == actualLiquidity); // Manual assert
        
        console.log("Camelot deposit quote test passed:");
        console.log("  Expected liquidity:", expectedLiquidity);
        console.log("  Actual liquidity:  ", actualLiquidity);
    }

    function test_depositQuote_uniswap_balancedDeposit() public {
        uint256 amountA = 1000e18;
        uint256 amountB = 1000e18;
        
        // Get current reserves
        (uint112 reserveA, uint112 reserveB,) = uniswapPair.getReserves();
        uint256 totalSupply = uniswapPair.totalSupply();
        
        // Calculate expected liquidity using ConstProdUtils
        uint256 expectedLiquidity = ConstProdUtils._depositQuote(
            amountA,
            amountB,
            uint256(reserveA),
            uint256(reserveB),
            totalSupply
        );
        
        // Mint tokens for actual deposit
        uniswapTokenA.mint(address(this), amountA);
        uniswapTokenB.mint(address(this), amountB);
        
        // Record initial LP balance
        uint256 initialLPBalance = uniswapPair.balanceOf(address(this));
        
        // Perform actual deposit via UniswapV2Service - use the IUniswapV2Router02 directly
        uint256 actualLiquidity = UniswapV2Service._deposit(
            IUniswapV2Router(address(uniswapV2Router())),
            uniswapTokenA,
            uniswapTokenB,
            amountA,
            amountB
        );
        
        // Verify the calculation matches actual result
        assert(actualLiquidity == expectedLiquidity); // Manual assert since assertEq not available
        
        // Verify LP tokens were actually minted
        uint256 finalLPBalance = uniswapPair.balanceOf(address(this));
        assert(finalLPBalance - initialLPBalance == actualLiquidity); // Manual assert
        
        console.log("Uniswap deposit quote test passed:");
        console.log("  Expected liquidity:", expectedLiquidity);
        console.log("  Actual liquidity:  ", actualLiquidity);
    }

    function test_depositQuote_camelot_unbalancedDeposit() public {
        uint256 amountA = 2000e18; // More A than proportional
        uint256 amountB = 500e18;  // Less B than proportional
        
        // Get current reserves
        (uint112 reserveA, uint112 reserveB,,) = camelotPair.getReserves();
        uint256 totalSupply = camelotPair.totalSupply();
        
        // Calculate expected liquidity using ConstProdUtils
        uint256 expectedLiquidity = ConstProdUtils._depositQuote(
            amountA,
            amountB,
            uint256(reserveA),
            uint256(reserveB),
            totalSupply
        );
        
        // Mint tokens for actual deposit
        camelotTokenA.mint(address(this), amountA);
        camelotTokenB.mint(address(this), amountB);
        
        // Record initial LP balance
        // uint256 initialLPBalance = camelotPair.balanceOf(address(this));
        
        // Perform actual deposit via CamelotV2Service
        uint256 actualLiquidity = CamelotV2Service._deposit(
            camV2Router(),
            camelotTokenA,
            camelotTokenB,
            amountA,
            amountB
        );
        
        // Verify the calculation matches actual result
        assert(actualLiquidity == expectedLiquidity); // Manual assert since assertEq not available
        
        console.log("Camelot unbalanced deposit quote test passed:");
        console.log("  Expected liquidity:", expectedLiquidity);
        console.log("  Actual liquidity:  ", actualLiquidity);
    }

    function test_depositQuote_uniswap_unbalancedDeposit() public {
        uint256 amountA = 2000e18; // More A than proportional
        uint256 amountB = 500e18;  // Less B than proportional
        
        // Get current reserves
        (uint112 reserveA, uint112 reserveB,) = uniswapPair.getReserves();
        uint256 totalSupply = uniswapPair.totalSupply();
        
        // Calculate expected liquidity using ConstProdUtils
        uint256 expectedLiquidity = ConstProdUtils._depositQuote(
            amountA,
            amountB,
            uint256(reserveA),
            uint256(reserveB),
            totalSupply
        );
        
        // Mint tokens for actual deposit
        uniswapTokenA.mint(address(this), amountA);
        uniswapTokenB.mint(address(this), amountB);
        
        // Record initial LP balance
        // uint256 initialLPBalance = uniswapPair.balanceOf(address(this));
        
        // Perform actual deposit via UniswapV2Service
        uint256 actualLiquidity = UniswapV2Service._deposit(
            IUniswapV2Router(address(uniswapV2Router())),
            uniswapTokenA,
            uniswapTokenB,
            amountA,
            amountB
        );
        
        // Verify the calculation matches actual result
        assert(actualLiquidity == expectedLiquidity); // Manual assert since assertEq not available
        
        console.log("Uniswap unbalanced deposit quote test passed:");
        console.log("  Expected liquidity:", expectedLiquidity);
        console.log("  Actual liquidity:  ", actualLiquidity);
    }
} 