// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {betterconsole as console} from "contracts/crane/utils/vm/foundry/tools/betterconsole.sol";
import {TestBase_ConstProdUtils} from "./TestBase_ConstProdUtils.sol";
import {ConstProdUtils} from "contracts/crane/utils/math/ConstProdUtils.sol";
import {CamelotV2Service} from "contracts/crane/protocols/dexes/camelot/v2/utils/CamelotV2Service.sol";
import {UniswapV2Service} from "contracts/crane/protocols/dexes/uniswap/v2/utils/UniswapV2Service.sol";
import {IUniswapV2Router} from "contracts/crane/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Router.sol";

/**
 * @title Test_ConstProdUtils_depositQuote
 * @dev Tests ConstProdUtils._depositQuote against actual DEX deposit operations
 */
contract Test_ConstProdUtils_depositQuote is TestBase_ConstProdUtils {
    function setUp() public override {
        super.setUp();
        _initializePools();
    }

    function run() public override {
        super.run();
    }

    function test_depositQuote_Camelot_balancedPool() public {
        // Test with balanced pool (1:1 ratio)
        uint256 amountA = 1000e18;
        uint256 amountB = 1000e18;

        // Get current pool state
        (uint112 reserve0, uint112 reserve1,,) = camelotBalancedPair.getReserves();
        uint256 totalSupply = camelotBalancedPair.totalSupply();

        // Sort reserves to match token order
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
            address(camelotBalancedTokenA), camelotBalancedPair.token0(), reserve0, reserve1
        );

        // Calculate expected LP tokens using ConstProdUtils
        uint256 expectedLPTokens = ConstProdUtils._depositQuote(amountA, amountB, totalSupply, reserveA, reserveB);

        // Mint tokens for actual deposit
        camelotBalancedTokenA.mint(address(this), amountA);
        camelotBalancedTokenB.mint(address(this), amountB);

        // Record initial LP balance
        uint256 initialLPBalance = camelotBalancedPair.balanceOf(address(this));

        // Perform actual deposit via CamelotV2Service
        uint256 actualLPTokens =
            CamelotV2Service._deposit(camV2Router(), camelotBalancedTokenA, camelotBalancedTokenB, amountA, amountB);

        // Verify the calculation matches actual result
        assertEq(actualLPTokens, expectedLPTokens, "Expected LP tokens should match actual deposit result");

        // Verify LP tokens were actually minted
        uint256 finalLPBalance = camelotBalancedPair.balanceOf(address(this));
        assertEq(finalLPBalance - initialLPBalance, actualLPTokens, "LP tokens should be minted correctly");

        console.log("_depositQuote Camelot balanced pool test passed:");
        console.log("  ReserveA:", reserveA);
        console.log("  ReserveB:", reserveB);
        console.log("  TotalSupply:", totalSupply);
        console.log("  Deposit amountA:", amountA);
        console.log("  Deposit amountB:", amountB);
        console.log("  Expected LP tokens:", expectedLPTokens);
        console.log("  Actual LP tokens:", actualLPTokens);
    }

    function test_depositQuote_Camelot_unbalancedPool() public {
        // Test with unbalanced pool (10:1 ratio)
        uint256 amountA = 1000e18; // 10% of initial 10,000e18
        uint256 amountB = 100e18; // 10% of initial 1,000e18

        // Get current pool state
        (uint112 reserve0, uint112 reserve1,,) = camelotUnbalancedPair.getReserves();
        uint256 totalSupply = camelotUnbalancedPair.totalSupply();

        // Sort reserves to match token order
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
            address(camelotUnbalancedTokenA), camelotUnbalancedPair.token0(), reserve0, reserve1
        );

        // Calculate expected LP tokens using ConstProdUtils
        uint256 expectedLPTokens = ConstProdUtils._depositQuote(amountA, amountB, totalSupply, reserveA, reserveB);

        // Mint tokens for actual deposit
        camelotUnbalancedTokenA.mint(address(this), amountA);
        camelotUnbalancedTokenB.mint(address(this), amountB);

        // Record initial LP balance
        uint256 initialLPBalance = camelotUnbalancedPair.balanceOf(address(this));

        // Perform actual deposit via CamelotV2Service
        uint256 actualLPTokens = CamelotV2Service._deposit(
            camV2Router(), camelotUnbalancedTokenA, camelotUnbalancedTokenB, amountA, amountB
        );

        // Verify the calculation matches actual result
        assertEq(actualLPTokens, expectedLPTokens, "Expected LP tokens should match actual deposit result");

        // Verify LP tokens were actually minted
        uint256 finalLPBalance = camelotUnbalancedPair.balanceOf(address(this));
        assertEq(finalLPBalance - initialLPBalance, actualLPTokens, "LP tokens should be minted correctly");

        console.log("_depositQuote Camelot unbalanced pool test passed:");
        console.log("  ReserveA:", reserveA);
        console.log("  ReserveB:", reserveB);
        console.log("  TotalSupply:", totalSupply);
        console.log("  Deposit amountA:", amountA);
        console.log("  Deposit amountB:", amountB);
        console.log("  Expected LP tokens:", expectedLPTokens);
        console.log("  Actual LP tokens:", actualLPTokens);
    }

    function test_depositQuote_Camelot_extremeUnbalancedPool() public {
        // Test with extreme unbalanced pool (100:1 ratio)
        uint256 amountA = 10e18;
        uint256 amountB = 0.1e18;

        // Get current pool state
        (uint112 reserve0, uint112 reserve1,,) = camelotExtremeUnbalancedPair.getReserves();
        uint256 totalSupply = camelotExtremeUnbalancedPair.totalSupply();

        // Sort reserves to match token order
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
            address(camelotExtremeTokenA), camelotExtremeUnbalancedPair.token0(), reserve0, reserve1
        );

        // Calculate expected LP tokens using ConstProdUtils
        uint256 expectedLPTokens = ConstProdUtils._depositQuote(amountA, amountB, totalSupply, reserveA, reserveB);

        // Mint tokens for actual deposit
        camelotExtremeTokenA.mint(address(this), amountA);
        camelotExtremeTokenB.mint(address(this), amountB);

        // Record initial LP balance
        uint256 initialLPBalance = camelotExtremeUnbalancedPair.balanceOf(address(this));

        // Perform actual deposit via CamelotV2Service
        uint256 actualLPTokens =
            CamelotV2Service._deposit(camV2Router(), camelotExtremeTokenA, camelotExtremeTokenB, amountA, amountB);

        // Verify the calculation matches actual result
        assertEq(actualLPTokens, expectedLPTokens, "Expected LP tokens should match actual deposit result");

        // Verify LP tokens were actually minted
        uint256 finalLPBalance = camelotExtremeUnbalancedPair.balanceOf(address(this));
        assertEq(finalLPBalance - initialLPBalance, actualLPTokens, "LP tokens should be minted correctly");

        console.log("_depositQuote Camelot extreme unbalanced pool test passed:");
        console.log("  ReserveA:", reserveA);
        console.log("  ReserveB:", reserveB);
        console.log("  TotalSupply:", totalSupply);
        console.log("  Deposit amountA:", amountA);
        console.log("  Deposit amountB:", amountB);
        console.log("  Expected LP tokens:", expectedLPTokens);
        console.log("  Actual LP tokens:", actualLPTokens);
    }

    function test_depositQuote_Uniswap_BalancedPool() public {
        // Test with balanced Uniswap pool (1:1 ratio)
        uint256 amountA = 1000e18;
        uint256 amountB = 1000e18;

        // Get current pool state
        (uint112 reserve0, uint112 reserve1,) = uniswapBalancedPair.getReserves();
        uint256 totalSupply = uniswapBalancedPair.totalSupply();

        // Sort reserves to match token order
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
            address(uniswapBalancedTokenA), uniswapBalancedPair.token0(), reserve0, reserve1
        );

        // Calculate expected LP tokens using ConstProdUtils
        uint256 expectedLPTokens = ConstProdUtils._depositQuote(amountA, amountB, totalSupply, reserveA, reserveB);

        // Mint tokens for actual deposit
        uniswapBalancedTokenA.mint(address(this), amountA);
        uniswapBalancedTokenB.mint(address(this), amountB);

        // Record initial LP balance
        uint256 initialLPBalance = uniswapBalancedPair.balanceOf(address(this));

        // Perform actual deposit via UniswapV2Service
        uint256 actualLPTokens = UniswapV2Service._deposit(
            IUniswapV2Router(address(uniswapV2Router())), uniswapBalancedTokenA, uniswapBalancedTokenB, amountA, amountB
        );

        // Verify the calculation matches actual result
        assertEq(actualLPTokens, expectedLPTokens, "Expected LP tokens should match actual deposit result");

        // Verify LP tokens were actually minted
        uint256 finalLPBalance = uniswapBalancedPair.balanceOf(address(this));
        assertEq(finalLPBalance - initialLPBalance, actualLPTokens, "LP tokens should be minted correctly");

        console.log("_depositQuote Uniswap balanced pool test passed:");
        console.log("  ReserveA:", reserveA);
        console.log("  ReserveB:", reserveB);
        console.log("  TotalSupply:", totalSupply);
        console.log("  Deposit amountA:", amountA);
        console.log("  Deposit amountB:", amountB);
        console.log("  Expected LP tokens:", expectedLPTokens);
        console.log("  Actual LP tokens:", actualLPTokens);
    }

    function test_depositQuote_Uniswap_UnbalancedPool() public {
        // Test with unbalanced Uniswap pool (10:1 ratio)
        uint256 amountA = 100e18;
        uint256 amountB = 10e18;

        // Get current pool state
        (uint112 reserve0, uint112 reserve1,) = uniswapUnbalancedPair.getReserves();
        uint256 totalSupply = uniswapUnbalancedPair.totalSupply();

        // Sort reserves to match token order
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
            address(uniswapUnbalancedTokenA), uniswapUnbalancedPair.token0(), reserve0, reserve1
        );

        // Calculate expected LP tokens using ConstProdUtils
        uint256 expectedLPTokens = ConstProdUtils._depositQuote(amountA, amountB, totalSupply, reserveA, reserveB);

        // Mint tokens for actual deposit
        uniswapUnbalancedTokenA.mint(address(this), amountA);
        uniswapUnbalancedTokenB.mint(address(this), amountB);

        // Record initial LP balance
        uint256 initialLPBalance = uniswapUnbalancedPair.balanceOf(address(this));

        // Perform actual deposit via UniswapV2Service
        uint256 actualLPTokens = UniswapV2Service._deposit(
            IUniswapV2Router(address(uniswapV2Router())),
            uniswapUnbalancedTokenA,
            uniswapUnbalancedTokenB,
            amountA,
            amountB
        );

        // Verify the calculation matches actual result
        assertEq(actualLPTokens, expectedLPTokens, "Expected LP tokens should match actual deposit result");

        // Verify LP tokens were actually minted
        uint256 finalLPBalance = uniswapUnbalancedPair.balanceOf(address(this));
        assertEq(finalLPBalance - initialLPBalance, actualLPTokens, "LP tokens should be minted correctly");

        console.log("_depositQuote Uniswap unbalanced pool test passed:");
        console.log("  ReserveA:", reserveA);
        console.log("  ReserveB:", reserveB);
        console.log("  TotalSupply:", totalSupply);
        console.log("  Deposit amountA:", amountA);
        console.log("  Deposit amountB:", amountB);
        console.log("  Expected LP tokens:", expectedLPTokens);
        console.log("  Actual LP tokens:", actualLPTokens);
    }

    function test_depositQuote_Uniswap_ExtremeUnbalancedPool() public {
        // Test with extreme unbalanced Uniswap pool (100:1 ratio)
        uint256 amountA = 10e18;
        uint256 amountB = 0.1e18;

        // Get current pool state
        (uint112 reserve0, uint112 reserve1,) = uniswapExtremeUnbalancedPair.getReserves();
        uint256 totalSupply = uniswapExtremeUnbalancedPair.totalSupply();

        // Sort reserves to match token order
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
            address(uniswapExtremeTokenA), uniswapExtremeUnbalancedPair.token0(), reserve0, reserve1
        );

        // Calculate expected LP tokens using ConstProdUtils
        uint256 expectedLPTokens = ConstProdUtils._depositQuote(amountA, amountB, totalSupply, reserveA, reserveB);

        // Mint tokens for actual deposit
        uniswapExtremeTokenA.mint(address(this), amountA);
        uniswapExtremeTokenB.mint(address(this), amountB);

        // Record initial LP balance
        uint256 initialLPBalance = uniswapExtremeUnbalancedPair.balanceOf(address(this));

        // Perform actual deposit via UniswapV2Service
        uint256 actualLPTokens = UniswapV2Service._deposit(
            IUniswapV2Router(address(uniswapV2Router())), uniswapExtremeTokenA, uniswapExtremeTokenB, amountA, amountB
        );

        // Verify the calculation matches actual result
        assertEq(actualLPTokens, expectedLPTokens, "Expected LP tokens should match actual deposit result");

        // Verify LP tokens were actually minted
        uint256 finalLPBalance = uniswapExtremeUnbalancedPair.balanceOf(address(this));
        assertEq(finalLPBalance - initialLPBalance, actualLPTokens, "LP tokens should be minted correctly");

        console.log("_depositQuote Uniswap extreme unbalanced pool test passed:");
        console.log("  ReserveA:", reserveA);
        console.log("  ReserveB:", reserveB);
        console.log("  TotalSupply:", totalSupply);
        console.log("  Deposit amountA:", amountA);
        console.log("  Deposit amountB:", amountB);
        console.log("  Expected LP tokens:", expectedLPTokens);
        console.log("  Actual LP tokens:", actualLPTokens);
    }
}
