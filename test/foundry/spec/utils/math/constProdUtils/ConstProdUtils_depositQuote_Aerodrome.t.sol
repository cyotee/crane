// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {TestBase_ConstProdUtils_Aerodrome} from "test/foundry/spec/utils/math/constProdUtils/TestBase_ConstProdUtils_Aerodrome.sol";
import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";

contract ConstProdUtils_depositQuote_Aerodrome_Test is TestBase_ConstProdUtils_Aerodrome {
    function setUp() public override {
        TestBase_ConstProdUtils_Aerodrome.setUp();
    }

    function test_depositQuote_Aerodrome_First_Deposit_balancedPool() public {
        uint256 amountA = 1000e18;
        uint256 amountB = 1000e18;

        (uint256 reserve0, uint256 reserve1,) = aeroBalancedPool.getReserves();
        uint256 totalSupply = aeroBalancedPool.totalSupply();

        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
            address(aeroBalancedTokenA), aeroBalancedPool.token0(), reserve0, reserve1
        );

        uint256 expectedLPTokens = ConstProdUtils._depositQuote(amountA, amountB, totalSupply, reserveA, reserveB);

        aeroBalancedTokenA.mint(address(this), amountA);
        aeroBalancedTokenB.mint(address(this), amountB);
        aeroBalancedTokenA.approve(address(aerodromeRouter), amountA);
        aeroBalancedTokenB.approve(address(aerodromeRouter), amountB);

        uint256 initialLPBalance = aeroBalancedPool.balanceOf(address(this));

        aerodromeRouter.addLiquidity(address(aeroBalancedTokenA), address(aeroBalancedTokenB), false, amountA, amountB, 1, 1, address(this), block.timestamp);

        uint256 finalLPBalance = aeroBalancedPool.balanceOf(address(this));
        uint256 actualLPTokens = finalLPBalance - initialLPBalance;

        assertEq(actualLPTokens, expectedLPTokens, "Expected LP tokens should match actual deposit result");

        uint256 finalLPBalanceCheck = aeroBalancedPool.balanceOf(address(this));
        assertEq(finalLPBalanceCheck - initialLPBalance, actualLPTokens, "LP tokens should be minted correctly");
    }

    function test_depositQuote_Aerodrome_Second_Deposit_balancedPool() public {
        // First, create initial liquidity so this is a second deposit scenario
        uint256 initialA = 1000e18;
        uint256 initialB = 1000e18;

        aeroBalancedTokenA.mint(address(this), initialA);
        aeroBalancedTokenB.mint(address(this), initialB);
        aeroBalancedTokenA.approve(address(aerodromeRouter), initialA);
        aeroBalancedTokenB.approve(address(aerodromeRouter), initialB);

        // add initial liquidity
        aerodromeRouter.addLiquidity(address(aeroBalancedTokenA), address(aeroBalancedTokenB), false, initialA, initialB, 1, 1, address(this), block.timestamp);

        // Now perform the second deposit and compare quoted vs actual LP tokens
        uint256 amountA = 100e18;
        uint256 amountB = 100e18;

        (uint256 reserve0, uint256 reserve1,) = aeroBalancedPool.getReserves();
        uint256 totalSupply = aeroBalancedPool.totalSupply();

        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
            address(aeroBalancedTokenA), aeroBalancedPool.token0(), reserve0, reserve1
        );

        uint256 expectedLPTokens = ConstProdUtils._depositQuote(amountA, amountB, totalSupply, reserveA, reserveB);

        aeroBalancedTokenA.mint(address(this), amountA);
        aeroBalancedTokenB.mint(address(this), amountB);
        aeroBalancedTokenA.approve(address(aerodromeRouter), amountA);
        aeroBalancedTokenB.approve(address(aerodromeRouter), amountB);

        uint256 initialLPBalance = aeroBalancedPool.balanceOf(address(this));

        aerodromeRouter.addLiquidity(address(aeroBalancedTokenA), address(aeroBalancedTokenB), false, amountA, amountB, 1, 1, address(this), block.timestamp);

        uint256 finalLPBalance = aeroBalancedPool.balanceOf(address(this));
        uint256 actualLPTokens = finalLPBalance - initialLPBalance;

        assertEq(actualLPTokens, expectedLPTokens, "Expected LP tokens should match actual deposit result");
    }
}
