// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {betterconsole as console} from "contracts/utils/vm/foundry/tools/betterconsole.sol";
import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";
import {TestBase_ConstProdUtils_Camelot} from "@crane/test/foundry/spec/utils/math/constProdUtils/TestBase_ConstProdUtils_Camelot.sol";
import {CamelotV2Service} from "@crane/contracts/protocols/dexes/camelot/v2/CamelotV2Service.sol";

contract ConstProdUtils_depositQuote_Camelot_Test is TestBase_ConstProdUtils_Camelot {
    function setUp() public override {
        TestBase_ConstProdUtils_Camelot.setUp();
    }

    function test_depositQuote_Camelot_First_Deposit_balancedPool() public {
        uint256 amountA = 1000e18;
        uint256 amountB = 1000e18;

        (uint112 reserve0, uint112 reserve1,,) = camelotBalancedPair.getReserves();
        uint256 totalSupply = camelotBalancedPair.totalSupply();

        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
            address(camelotBalancedTokenA), camelotBalancedPair.token0(), reserve0, reserve1
        );

        uint256 expectedLPTokens = ConstProdUtils._depositQuote(amountA, amountB, totalSupply, reserveA, reserveB);

        camelotBalancedTokenA.mint(address(this), amountA);
        camelotBalancedTokenB.mint(address(this), amountB);

        uint256 initialLPBalance = camelotBalancedPair.balanceOf(address(this));

        uint256 actualLPTokens =
            CamelotV2Service._deposit(camelotV2Router, camelotBalancedTokenA, camelotBalancedTokenB, amountA, amountB);

        assertEq(actualLPTokens, expectedLPTokens, "Expected LP tokens should match actual deposit result");

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

    function test_depositQuote_Camelot_Second_Deposit_balancedPool() public {
        _initializeCamelotBalancedPools();
        uint256 amountA = 1000e18;
        uint256 amountB = 1000e18;

        (uint112 reserve0, uint112 reserve1,,) = camelotBalancedPair.getReserves();
        uint256 totalSupply = camelotBalancedPair.totalSupply();

        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
            address(camelotBalancedTokenA), camelotBalancedPair.token0(), reserve0, reserve1
        );

        uint256 expectedLPTokens = ConstProdUtils._depositQuote(amountA, amountB, totalSupply, reserveA, reserveB);

        camelotBalancedTokenA.mint(address(this), amountA);
        camelotBalancedTokenB.mint(address(this), amountB);

        uint256 initialLPBalance = camelotBalancedPair.balanceOf(address(this));

        uint256 actualLPTokens =
            CamelotV2Service._deposit(camelotV2Router, camelotBalancedTokenA, camelotBalancedTokenB, amountA, amountB);

        assertEq(actualLPTokens, expectedLPTokens, "Expected LP tokens should match actual deposit result");

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
}
