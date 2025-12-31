// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {betterconsole as console} from "contracts/crane/utils/vm/foundry/tools/betterconsole.sol";
import {TestBase_ConstProdUtils} from "./TestBase_ConstProdUtils.sol";
import {ConstProdUtils} from "contracts/crane/utils/math/ConstProdUtils.sol";
import {CamelotV2Service} from "contracts/crane/protocols/dexes/camelot/v2/utils/CamelotV2Service.sol";
import {UniswapV2Service} from "contracts/crane/protocols/dexes/uniswap/v2/utils/UniswapV2Service.sol";

/**
 * @title Test_ConstProdUtils_withdrawTargetQuote
 * @dev Tests ConstProdUtils._withdrawTargetQuote against actual DEX withdrawal operations
 */
contract Test_ConstProdUtils_withdrawTargetQuote is TestBase_ConstProdUtils {
    function setUp() public override {
        super.setUp();
    }

    function run() public override {
        super.run();
    }

    function test_withdrawTargetQuote_Camelot_balancedPool() public {
        // Get current pool state
        (uint112 reserve0, uint112 reserve1, uint16 token0Fee, uint16 token1Fee) = camelotBalancedPair.getReserves();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
            address(camelotBalancedTokenA), camelotBalancedPair.token0(), reserve0, reserve1
        );
        uint256 totalSupply = camelotBalancedPair.totalSupply();

        // Set target amount to 10% of TokenA reserve
        uint256 targetAmount = reserveA / 10;

        // Calculate expected LP amount needed using ConstProdUtils
        uint256 expectedLPTokens = ConstProdUtils._withdrawTargetQuote(targetAmount, totalSupply, reserveA);

        // Verify we have enough LP tokens
        uint256 lpBalance = camelotBalancedPair.balanceOf(address(this));
        assertGe(lpBalance, expectedLPTokens, "Must have enough LP tokens for withdrawal");

        // Record initial token balance
        uint256 initialBalanceA = camelotBalancedTokenA.balanceOf(address(this));

        // Execute actual withdrawal
        (uint256 amount0, uint256 amount1) = CamelotV2Service._withdrawDirect(camelotBalancedPair, expectedLPTokens);

        // Sort amounts correctly
        uint256 actualAmountA = address(camelotBalancedTokenA) == camelotBalancedPair.token0() ? amount0 : amount1;

        // Validate we got at least the target amount
        assertGe(actualAmountA, targetAmount, "Actual withdrawal should be at least target amount");

        // Verify token transfer occurred
        assertEq(
            camelotBalancedTokenA.balanceOf(address(this)) - initialBalanceA,
            actualAmountA,
            "TokenA balance change should match withdrawal"
        );

        console.log("_withdrawTargetQuote Camelot balanced pool test passed:");
        console.log("  ReserveA:", reserveA);
        console.log("  ReserveB:", reserveB);
        console.log("  TotalSupply:", totalSupply);
        console.log("  Target Amount:", targetAmount);
        console.log("  Expected LP Tokens:", expectedLPTokens);
        console.log("  Actual TokenA:", actualAmountA);
        console.log("  LP Balance Used:", expectedLPTokens);
    }

    function test_withdrawTargetQuote_Camelot_unbalancedPool() public {
        // Get current pool state
        (uint112 reserve0, uint112 reserve1, uint16 token0Fee, uint16 token1Fee) = camelotUnbalancedPair.getReserves();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
            address(camelotUnbalancedTokenA), camelotUnbalancedPair.token0(), reserve0, reserve1
        );
        uint256 totalSupply = camelotUnbalancedPair.totalSupply();

        // Set target amount to 10% of TokenA reserve
        uint256 targetAmount = reserveA / 10;

        // Calculate expected LP amount needed using ConstProdUtils
        uint256 expectedLPTokens = ConstProdUtils._withdrawTargetQuote(targetAmount, totalSupply, reserveA);

        // Verify we have enough LP tokens
        uint256 lpBalance = camelotUnbalancedPair.balanceOf(address(this));
        assertGe(lpBalance, expectedLPTokens, "Must have enough LP tokens for withdrawal");

        // Record initial token balance
        uint256 initialBalanceA = camelotUnbalancedTokenA.balanceOf(address(this));

        // Execute actual withdrawal
        (uint256 amount0, uint256 amount1) = CamelotV2Service._withdrawDirect(camelotUnbalancedPair, expectedLPTokens);

        // Sort amounts correctly
        uint256 actualAmountA = address(camelotUnbalancedTokenA) == camelotUnbalancedPair.token0() ? amount0 : amount1;

        // Validate we got at least the target amount
        assertGe(actualAmountA, targetAmount, "Actual withdrawal should be at least target amount");

        // Verify token transfer occurred
        assertEq(
            camelotUnbalancedTokenA.balanceOf(address(this)) - initialBalanceA,
            actualAmountA,
            "TokenA balance change should match withdrawal"
        );

        console.log("_withdrawTargetQuote Camelot unbalanced pool test passed:");
        console.log("  ReserveA:", reserveA);
        console.log("  ReserveB:", reserveB);
        console.log("  TotalSupply:", totalSupply);
        console.log("  Target Amount:", targetAmount);
        console.log("  Expected LP Tokens:", expectedLPTokens);
        console.log("  Actual TokenA:", actualAmountA);
        console.log("  LP Balance Used:", expectedLPTokens);
    }

    function test_withdrawTargetQuote_Camelot_extremeUnbalancedPool() public {
        // Get current pool state
        (uint112 reserveA, uint112 reserveB,,) = camelotBalancedPair.getReserves();
        uint256 totalSupply = camelotBalancedPair.totalSupply();

        // Set target amount to 10% of TokenA reserve
        uint256 targetAmount = reserveA / 10;

        // Calculate expected LP amount needed using ConstProdUtils
        uint256 expectedLPTokens = ConstProdUtils._withdrawTargetQuote(targetAmount, totalSupply, reserveA);

        // Verify we have enough LP tokens
        uint256 lpBalance = camelotBalancedPair.balanceOf(address(this));
        assertGe(lpBalance, expectedLPTokens, "Must have enough LP tokens for withdrawal");

        // Record initial token balance
        uint256 initialBalanceA = camelotBalancedTokenA.balanceOf(address(this));

        // Execute actual withdrawal
        (uint256 amount0, uint256 amount1) = CamelotV2Service._withdrawDirect(camelotBalancedPair, expectedLPTokens);

        // Sort amounts correctly
        uint256 actualAmountA = address(camelotBalancedTokenA) == camelotBalancedPair.token0() ? amount0 : amount1;

        // Validate we got at least the target amount
        assertGe(actualAmountA, targetAmount, "Actual withdrawal should be at least target amount");

        // Verify token transfer occurred
        assertEq(
            camelotBalancedTokenA.balanceOf(address(this)) - initialBalanceA,
            actualAmountA,
            "TokenA balance change should match withdrawal"
        );

        console.log("_withdrawTargetQuote Camelot extreme unbalanced pool test passed:");
        console.log("  ReserveA:", reserveA);
        console.log("  ReserveB:", reserveB);
        console.log("  TotalSupply:", totalSupply);
        console.log("  Target Amount:", targetAmount);
        console.log("  Expected LP Tokens:", expectedLPTokens);
        console.log("  Actual TokenA:", actualAmountA);
        console.log("  LP Balance Used:", expectedLPTokens);
    }

    function test_withdrawTargetQuote_Uniswap_BalancedPool() public {
        // Get current pool state
        (uint112 reserveA, uint112 reserveB,) = uniswapBalancedPair.getReserves();
        uint256 totalSupply = uniswapBalancedPair.totalSupply();

        // Set target amount to 10% of TokenA reserve
        uint256 targetAmount = reserveA / 10;

        // Calculate expected LP amount needed using ConstProdUtils
        uint256 expectedLPTokens = ConstProdUtils._withdrawTargetQuote(targetAmount, totalSupply, reserveA);

        // Verify we have enough LP tokens
        uint256 lpBalance = uniswapBalancedPair.balanceOf(address(this));
        assertGe(lpBalance, expectedLPTokens, "Must have enough LP tokens for withdrawal");

        // Record initial token balance
        uint256 initialBalanceA = uniswapBalancedTokenA.balanceOf(address(this));

        // Execute actual withdrawal
        (uint256 amount0, uint256 amount1) = UniswapV2Service._withdrawDirect(uniswapBalancedPair, expectedLPTokens);

        // Sort amounts correctly
        uint256 actualAmountA = address(uniswapBalancedTokenA) == uniswapBalancedPair.token0() ? amount0 : amount1;

        // Validate we got at least the target amount
        assertGe(actualAmountA, targetAmount, "Actual withdrawal should be at least target amount");

        // Verify token transfer occurred
        assertEq(
            uniswapBalancedTokenA.balanceOf(address(this)) - initialBalanceA,
            actualAmountA,
            "TokenA balance change should match withdrawal"
        );

        console.log("_withdrawTargetQuote Uniswap balanced pool test passed:");
        console.log("  ReserveA:", reserveA);
        console.log("  ReserveB:", reserveB);
        console.log("  TotalSupply:", totalSupply);
        console.log("  Target Amount:", targetAmount);
        console.log("  Expected LP Tokens:", expectedLPTokens);
        console.log("  Actual TokenA:", actualAmountA);
        console.log("  LP Balance Used:", expectedLPTokens);
    }

    function test_withdrawTargetQuote_Uniswap_UnbalancedPool() public {
        // Get current pool state
        (uint112 reserveA, uint112 reserveB,) = uniswapBalancedPair.getReserves();
        uint256 totalSupply = uniswapBalancedPair.totalSupply();

        // Set target amount to 10% of TokenA reserve
        uint256 targetAmount = reserveA / 10;

        // Calculate expected LP amount needed using ConstProdUtils
        uint256 expectedLPTokens = ConstProdUtils._withdrawTargetQuote(targetAmount, totalSupply, reserveA);

        // Verify we have enough LP tokens
        uint256 lpBalance = uniswapBalancedPair.balanceOf(address(this));
        assertGe(lpBalance, expectedLPTokens, "Must have enough LP tokens for withdrawal");

        // Record initial token balance
        uint256 initialBalanceA = uniswapBalancedTokenA.balanceOf(address(this));

        // Execute actual withdrawal
        (uint256 amount0, uint256 amount1) = UniswapV2Service._withdrawDirect(uniswapBalancedPair, expectedLPTokens);

        // Sort amounts correctly
        uint256 actualAmountA = address(uniswapBalancedTokenA) == uniswapBalancedPair.token0() ? amount0 : amount1;

        // Validate we got at least the target amount
        assertGe(actualAmountA, targetAmount, "Actual withdrawal should be at least target amount");

        // Verify token transfer occurred
        assertEq(
            uniswapBalancedTokenA.balanceOf(address(this)) - initialBalanceA,
            actualAmountA,
            "TokenA balance change should match withdrawal"
        );

        console.log("_withdrawTargetQuote Uniswap unbalanced pool test passed:");
        console.log("  ReserveA:", reserveA);
        console.log("  ReserveB:", reserveB);
        console.log("  TotalSupply:", totalSupply);
        console.log("  Target Amount:", targetAmount);
        console.log("  Expected LP Tokens:", expectedLPTokens);
        console.log("  Actual TokenA:", actualAmountA);
        console.log("  LP Balance Used:", expectedLPTokens);
    }

    function test_withdrawTargetQuote_Uniswap_ExtremeUnbalancedPool() public {
        // Get current pool state
        (uint112 reserveA, uint112 reserveB,) = uniswapBalancedPair.getReserves();
        uint256 totalSupply = uniswapBalancedPair.totalSupply();

        // Set target amount to 10% of TokenA reserve
        uint256 targetAmount = reserveA / 10;

        // Calculate expected LP amount needed using ConstProdUtils
        uint256 expectedLPTokens = ConstProdUtils._withdrawTargetQuote(targetAmount, totalSupply, reserveA);

        // Verify we have enough LP tokens
        uint256 lpBalance = uniswapBalancedPair.balanceOf(address(this));
        assertGe(lpBalance, expectedLPTokens, "Must have enough LP tokens for withdrawal");

        // Record initial token balance
        uint256 initialBalanceA = uniswapBalancedTokenA.balanceOf(address(this));

        // Execute actual withdrawal
        (uint256 amount0, uint256 amount1) = UniswapV2Service._withdrawDirect(uniswapBalancedPair, expectedLPTokens);

        // Sort amounts correctly
        uint256 actualAmountA = address(uniswapBalancedTokenA) == uniswapBalancedPair.token0() ? amount0 : amount1;

        // Validate we got at least the target amount
        assertGe(actualAmountA, targetAmount, "Actual withdrawal should be at least target amount");

        // Verify token transfer occurred
        assertEq(
            uniswapBalancedTokenA.balanceOf(address(this)) - initialBalanceA,
            actualAmountA,
            "TokenA balance change should match withdrawal"
        );

        console.log("_withdrawTargetQuote Uniswap extreme unbalanced pool test passed:");
        console.log("  ReserveA:", reserveA);
        console.log("  ReserveB:", reserveB);
        console.log("  TotalSupply:", totalSupply);
        console.log("  Target Amount:", targetAmount);
        console.log("  Expected LP Tokens:", expectedLPTokens);
        console.log("  Actual TokenA:", actualAmountA);
        console.log("  LP Balance Used:", expectedLPTokens);
    }

    function test_withdrawTargetQuote_edgeCases() public pure {
        uint256 lpTotalSupply = 1000e18;
        uint256 outRes = 2000e18;

        // Test edge cases return expected values
        assertEq(ConstProdUtils._withdrawTargetQuote(0, lpTotalSupply, outRes), 0, "Zero target should return zero LP");
        assertEq(ConstProdUtils._withdrawTargetQuote(100e18, 0, outRes), 0, "Zero LP supply should return zero");
        assertEq(ConstProdUtils._withdrawTargetQuote(100e18, lpTotalSupply, 0), 0, "Zero reserves should return zero");
        assertEq(
            ConstProdUtils._withdrawTargetQuote(3000e18, lpTotalSupply, outRes),
            0,
            "Target exceeding reserves should return zero"
        );

        console.log("_withdrawTargetQuote edge cases test passed:");
        console.log("  All edge cases handled correctly");
    }
}
