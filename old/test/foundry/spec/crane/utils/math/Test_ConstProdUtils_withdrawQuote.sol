// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {betterconsole as console} from "contracts/crane/utils/vm/foundry/tools/betterconsole.sol";
import {TestBase_ConstProdUtils} from "./TestBase_ConstProdUtils.sol";
import {ConstProdUtils} from "contracts/crane/utils/math/ConstProdUtils.sol";
import {CamelotV2Service} from "contracts/crane/protocols/dexes/camelot/v2/utils/CamelotV2Service.sol";
import {UniswapV2Service} from "contracts/crane/protocols/dexes/uniswap/v2/utils/UniswapV2Service.sol";
import {IUniswapV2Router} from "contracts/crane/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Router.sol";

/**
 * @title Test_ConstProdUtils_withdrawQuote
 * @dev Tests ConstProdUtils._withdrawQuote against actual DEX withdrawal operations
 */
contract Test_ConstProdUtils_withdrawQuote is TestBase_ConstProdUtils {
    function setUp() public override {
        super.setUp();
        _initializePools();
    }

    function run() public override {
        super.run();
    }

    function test_withdrawQuote_Camelot_balancedPool() public {
        // Get current pool state
        (uint112 reserve0, uint112 reserve1,,) = camelotBalancedPair.getReserves();
        uint256 totalSupply = camelotBalancedPair.totalSupply();

        // Sort reserves to match token order
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
            address(camelotBalancedTokenA), camelotBalancedPair.token0(), reserve0, reserve1
        );

        // Get LP balance and withdraw half
        uint256 lpBalance = camelotBalancedPair.balanceOf(address(this));
        uint256 lpTokensToWithdraw = lpBalance / 2;

        // Calculate expected withdrawal using ConstProdUtils
        (uint256 expectedAmountA, uint256 expectedAmountB) =
            ConstProdUtils._withdrawQuote(lpTokensToWithdraw, totalSupply, reserveA, reserveB);

        // Record initial token balances
        uint256 initialBalanceA = camelotBalancedTokenA.balanceOf(address(this));
        uint256 initialBalanceB = camelotBalancedTokenB.balanceOf(address(this));

        // Execute actual withdrawal
        (uint256 amount0, uint256 amount1) = CamelotV2Service._withdrawDirect(camelotBalancedPair, lpTokensToWithdraw);

        // Sort amounts correctly
        uint256 actualAmountA = address(camelotBalancedTokenA) == camelotBalancedPair.token0() ? amount0 : amount1;
        uint256 actualAmountB = address(camelotBalancedTokenA) == camelotBalancedPair.token0() ? amount1 : amount0;

        // Compare expected vs actual
        assertEq(actualAmountA, expectedAmountA, "TokenA amounts should match");
        assertEq(actualAmountB, expectedAmountB, "TokenB amounts should match");

        // Verify token transfers occurred
        assertEq(
            camelotBalancedTokenA.balanceOf(address(this)) - initialBalanceA,
            actualAmountA,
            "TokenA balance change should match withdrawal"
        );
        assertEq(
            camelotBalancedTokenB.balanceOf(address(this)) - initialBalanceB,
            actualAmountB,
            "TokenB balance change should match withdrawal"
        );

        console.log("_withdrawQuote Camelot balanced pool test passed:");
        console.log("  ReserveA:", reserveA);
        console.log("  ReserveB:", reserveB);
        console.log("  TotalSupply:", totalSupply);
        console.log("  LP Balance:", lpBalance);
        console.log("  LP Tokens Withdrawn:", lpTokensToWithdraw);
        console.log("  Expected TokenA:", expectedAmountA);
        console.log("  Actual TokenA:", actualAmountA);
        console.log("  Expected TokenB:", expectedAmountB);
        console.log("  Actual TokenB:", actualAmountB);
    }

    function test_withdrawQuote_Camelot_unbalancedPool() public {
        // Get current pool state
        (uint112 reserve0, uint112 reserve1,,) = camelotUnbalancedPair.getReserves();
        uint256 totalSupply = camelotUnbalancedPair.totalSupply();

        // Sort reserves to match token order
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
            address(camelotUnbalancedTokenA), camelotUnbalancedPair.token0(), reserve0, reserve1
        );

        // Get LP balance and withdraw half
        uint256 lpBalance = camelotUnbalancedPair.balanceOf(address(this));
        uint256 lpTokensToWithdraw = lpBalance / 2;

        // Calculate expected withdrawal using ConstProdUtils
        (uint256 expectedAmountA, uint256 expectedAmountB) =
            ConstProdUtils._withdrawQuote(lpTokensToWithdraw, totalSupply, reserveA, reserveB);

        // Record initial token balances
        uint256 initialBalanceA = camelotUnbalancedTokenA.balanceOf(address(this));
        uint256 initialBalanceB = camelotUnbalancedTokenB.balanceOf(address(this));

        // Execute actual withdrawal
        (uint256 amount0, uint256 amount1) = CamelotV2Service._withdrawDirect(camelotUnbalancedPair, lpTokensToWithdraw);

        // Sort amounts correctly
        uint256 actualAmountA = address(camelotUnbalancedTokenA) == camelotUnbalancedPair.token0() ? amount0 : amount1;
        uint256 actualAmountB = address(camelotUnbalancedTokenA) == camelotUnbalancedPair.token0() ? amount1 : amount0;

        // Compare expected vs actual
        assertEq(actualAmountA, expectedAmountA, "TokenA amounts should match");
        assertEq(actualAmountB, expectedAmountB, "TokenB amounts should match");

        // Verify token transfers occurred
        assertEq(
            camelotUnbalancedTokenA.balanceOf(address(this)) - initialBalanceA,
            actualAmountA,
            "TokenA balance change should match withdrawal"
        );
        assertEq(
            camelotUnbalancedTokenB.balanceOf(address(this)) - initialBalanceB,
            actualAmountB,
            "TokenB balance change should match withdrawal"
        );

        console.log("_withdrawQuote Camelot unbalanced pool test passed:");
        console.log("  ReserveA:", reserveA);
        console.log("  ReserveB:", reserveB);
        console.log("  TotalSupply:", totalSupply);
        console.log("  LP Balance:", lpBalance);
        console.log("  LP Tokens Withdrawn:", lpTokensToWithdraw);
        console.log("  Expected TokenA:", expectedAmountA);
        console.log("  Actual TokenA:", actualAmountA);
        console.log("  Expected TokenB:", expectedAmountB);
        console.log("  Actual TokenB:", actualAmountB);
    }

    function test_withdrawQuote_Camelot_extremeUnbalancedPool() public {
        // Get current pool state
        (uint112 reserve0, uint112 reserve1,,) = camelotExtremeUnbalancedPair.getReserves();
        uint256 totalSupply = camelotExtremeUnbalancedPair.totalSupply();

        // Sort reserves to match token order
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
            address(camelotExtremeTokenA), camelotExtremeUnbalancedPair.token0(), reserve0, reserve1
        );

        // Get LP balance and withdraw half
        uint256 lpBalance = camelotExtremeUnbalancedPair.balanceOf(address(this));
        uint256 lpTokensToWithdraw = lpBalance / 2;

        // Calculate expected withdrawal using ConstProdUtils
        (uint256 expectedAmountA, uint256 expectedAmountB) =
            ConstProdUtils._withdrawQuote(lpTokensToWithdraw, totalSupply, reserveA, reserveB);

        // Record initial token balances
        uint256 initialBalanceA = camelotExtremeTokenA.balanceOf(address(this));
        uint256 initialBalanceB = camelotExtremeTokenB.balanceOf(address(this));

        // Execute actual withdrawal
        (uint256 amount0, uint256 amount1) =
            CamelotV2Service._withdrawDirect(camelotExtremeUnbalancedPair, lpTokensToWithdraw);

        // Sort amounts correctly
        uint256 actualAmountA =
            address(camelotExtremeTokenA) == camelotExtremeUnbalancedPair.token0() ? amount0 : amount1;
        uint256 actualAmountB =
            address(camelotExtremeTokenA) == camelotExtremeUnbalancedPair.token0() ? amount1 : amount0;

        // Compare expected vs actual
        assertEq(actualAmountA, expectedAmountA, "TokenA amounts should match");
        assertEq(actualAmountB, expectedAmountB, "TokenB amounts should match");

        // Verify token transfers occurred
        assertEq(
            camelotExtremeTokenA.balanceOf(address(this)) - initialBalanceA,
            actualAmountA,
            "TokenA balance change should match withdrawal"
        );
        assertEq(
            camelotExtremeTokenB.balanceOf(address(this)) - initialBalanceB,
            actualAmountB,
            "TokenB balance change should match withdrawal"
        );

        console.log("_withdrawQuote Camelot extreme unbalanced pool test passed:");
        console.log("  ReserveA:", reserveA);
        console.log("  ReserveB:", reserveB);
        console.log("  TotalSupply:", totalSupply);
        console.log("  LP Balance:", lpBalance);
        console.log("  LP Tokens Withdrawn:", lpTokensToWithdraw);
        console.log("  Expected TokenA:", expectedAmountA);
        console.log("  Actual TokenA:", actualAmountA);
        console.log("  Expected TokenB:", expectedAmountB);
        console.log("  Actual TokenB:", actualAmountB);
    }

    function test_withdrawQuote_Uniswap_BalancedPool() public {
        // Get current pool state
        (uint112 reserve0, uint112 reserve1,) = uniswapBalancedPair.getReserves();
        uint256 totalSupply = uniswapBalancedPair.totalSupply();

        // Sort reserves to match token order
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
            address(uniswapBalancedTokenA), uniswapBalancedPair.token0(), reserve0, reserve1
        );

        // Get LP balance and withdraw half
        uint256 lpBalance = uniswapBalancedPair.balanceOf(address(this));
        uint256 lpTokensToWithdraw = lpBalance / 2;

        // Calculate expected withdrawal using ConstProdUtils
        (uint256 expectedAmountA, uint256 expectedAmountB) =
            ConstProdUtils._withdrawQuote(lpTokensToWithdraw, totalSupply, reserveA, reserveB);

        // Record initial token balances
        uint256 initialBalanceA = uniswapBalancedTokenA.balanceOf(address(this));
        uint256 initialBalanceB = uniswapBalancedTokenB.balanceOf(address(this));

        // Execute actual withdrawal
        (uint256 amount0, uint256 amount1) = UniswapV2Service._withdrawDirect(uniswapBalancedPair, lpTokensToWithdraw);

        // Sort amounts correctly
        uint256 actualAmountA = address(uniswapBalancedTokenA) == uniswapBalancedPair.token0() ? amount0 : amount1;
        uint256 actualAmountB = address(uniswapBalancedTokenA) == uniswapBalancedPair.token0() ? amount1 : amount0;

        // Compare expected vs actual
        assertEq(actualAmountA, expectedAmountA, "TokenA amounts should match");
        assertEq(actualAmountB, expectedAmountB, "TokenB amounts should match");

        // Verify token transfers occurred
        assertEq(
            uniswapBalancedTokenA.balanceOf(address(this)) - initialBalanceA,
            actualAmountA,
            "TokenA balance change should match withdrawal"
        );
        assertEq(
            uniswapBalancedTokenB.balanceOf(address(this)) - initialBalanceB,
            actualAmountB,
            "TokenB balance change should match withdrawal"
        );

        console.log("_withdrawQuote Uniswap balanced pool test passed:");
        console.log("  ReserveA:", reserveA);
        console.log("  ReserveB:", reserveB);
        console.log("  TotalSupply:", totalSupply);
        console.log("  LP Balance:", lpBalance);
        console.log("  LP Tokens Withdrawn:", lpTokensToWithdraw);
        console.log("  Expected TokenA:", expectedAmountA);
        console.log("  Actual TokenA:", actualAmountA);
        console.log("  Expected TokenB:", expectedAmountB);
        console.log("  Actual TokenB:", actualAmountB);
    }

    function test_withdrawQuote_Uniswap_UnbalancedPool() public {
        // Get current pool state
        (uint112 reserve0, uint112 reserve1,) = uniswapUnbalancedPair.getReserves();
        uint256 totalSupply = uniswapUnbalancedPair.totalSupply();

        // Sort reserves to match token order
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
            address(uniswapUnbalancedTokenA), uniswapUnbalancedPair.token0(), reserve0, reserve1
        );

        // Get LP balance and withdraw half
        uint256 lpBalance = uniswapUnbalancedPair.balanceOf(address(this));
        uint256 lpTokensToWithdraw = lpBalance / 2;

        // Calculate expected withdrawal using ConstProdUtils
        (uint256 expectedAmountA, uint256 expectedAmountB) =
            ConstProdUtils._withdrawQuote(lpTokensToWithdraw, totalSupply, reserveA, reserveB);

        // Record initial token balances
        uint256 initialBalanceA = uniswapUnbalancedTokenA.balanceOf(address(this));
        uint256 initialBalanceB = uniswapUnbalancedTokenB.balanceOf(address(this));

        // Execute actual withdrawal
        (uint256 amount0, uint256 amount1) = UniswapV2Service._withdrawDirect(uniswapUnbalancedPair, lpTokensToWithdraw);

        // Sort amounts correctly
        uint256 actualAmountA = address(uniswapUnbalancedTokenA) == uniswapUnbalancedPair.token0() ? amount0 : amount1;
        uint256 actualAmountB = address(uniswapUnbalancedTokenA) == uniswapUnbalancedPair.token0() ? amount1 : amount0;

        // Compare expected vs actual
        assertEq(actualAmountA, expectedAmountA, "TokenA amounts should match");
        assertEq(actualAmountB, expectedAmountB, "TokenB amounts should match");

        // Verify token transfers occurred
        assertEq(
            uniswapUnbalancedTokenA.balanceOf(address(this)) - initialBalanceA,
            actualAmountA,
            "TokenA balance change should match withdrawal"
        );
        assertEq(
            uniswapUnbalancedTokenB.balanceOf(address(this)) - initialBalanceB,
            actualAmountB,
            "TokenB balance change should match withdrawal"
        );

        console.log("_withdrawQuote Uniswap unbalanced pool test passed:");
        console.log("  ReserveA:", reserveA);
        console.log("  ReserveB:", reserveB);
        console.log("  TotalSupply:", totalSupply);
        console.log("  LP Balance:", lpBalance);
        console.log("  LP Tokens Withdrawn:", lpTokensToWithdraw);
        console.log("  Expected TokenA:", expectedAmountA);
        console.log("  Actual TokenA:", actualAmountA);
        console.log("  Expected TokenB:", expectedAmountB);
        console.log("  Actual TokenB:", actualAmountB);
    }

    function test_withdrawQuote_Uniswap_ExtremeUnbalancedPool() public {
        // Get current pool state
        (uint112 reserve0, uint112 reserve1,) = uniswapExtremeUnbalancedPair.getReserves();
        uint256 totalSupply = uniswapExtremeUnbalancedPair.totalSupply();

        // Sort reserves to match token order
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
            address(uniswapExtremeTokenA), uniswapExtremeUnbalancedPair.token0(), reserve0, reserve1
        );

        // Get LP balance and withdraw half
        uint256 lpBalance = uniswapExtremeUnbalancedPair.balanceOf(address(this));
        uint256 lpTokensToWithdraw = lpBalance / 2;

        // Calculate expected withdrawal using ConstProdUtils
        (uint256 expectedAmountA, uint256 expectedAmountB) =
            ConstProdUtils._withdrawQuote(lpTokensToWithdraw, totalSupply, reserveA, reserveB);

        // Record initial token balances
        uint256 initialBalanceA = uniswapExtremeTokenA.balanceOf(address(this));
        uint256 initialBalanceB = uniswapExtremeTokenB.balanceOf(address(this));

        // Execute actual withdrawal
        (uint256 amount0, uint256 amount1) =
            UniswapV2Service._withdrawDirect(uniswapExtremeUnbalancedPair, lpTokensToWithdraw);

        // Sort amounts correctly
        uint256 actualAmountA =
            address(uniswapExtremeTokenA) == uniswapExtremeUnbalancedPair.token0() ? amount0 : amount1;
        uint256 actualAmountB =
            address(uniswapExtremeTokenA) == uniswapExtremeUnbalancedPair.token0() ? amount1 : amount0;

        // Compare expected vs actual
        assertEq(actualAmountA, expectedAmountA, "TokenA amounts should match");
        assertEq(actualAmountB, expectedAmountB, "TokenB amounts should match");

        // Verify token transfers occurred
        assertEq(
            uniswapExtremeTokenA.balanceOf(address(this)) - initialBalanceA,
            actualAmountA,
            "TokenA balance change should match withdrawal"
        );
        assertEq(
            uniswapExtremeTokenB.balanceOf(address(this)) - initialBalanceB,
            actualAmountB,
            "TokenB balance change should match withdrawal"
        );

        console.log("_withdrawQuote Uniswap extreme unbalanced pool test passed:");
        console.log("  ReserveA:", reserveA);
        console.log("  ReserveB:", reserveB);
        console.log("  TotalSupply:", totalSupply);
        console.log("  LP Balance:", lpBalance);
        console.log("  LP Tokens Withdrawn:", lpTokensToWithdraw);
        console.log("  Expected TokenA:", expectedAmountA);
        console.log("  Actual TokenA:", actualAmountA);
        console.log("  Expected TokenB:", expectedAmountB);
        console.log("  Actual TokenB:", actualAmountB);
    }
}
