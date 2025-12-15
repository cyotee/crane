// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {betterconsole as console} from "contracts/utils/vm/foundry/tools/betterconsole.sol";
import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";
import {TestBase_ConstProdUtils_Uniswap} from "@crane/test/foundry/spec/utils/math/ConstProdUtils.sol/TestBase_ConstProdUtils_Uniswap.sol";

contract ConstProdUtils_depositQuote_Uniswap_Test is TestBase_ConstProdUtils_Uniswap {
    function setUp() public override {
        TestBase_ConstProdUtils_Uniswap.setUp();
    }

    function test_depositQuote_Uniswap_First_Deposit_balancedPool() public {
        uint256 amountA = 1000e18;
        uint256 amountB = 1000e18;

        (uint112 reserve0, uint112 reserve1,) = uniswapBalancedPair.getReserves();
        uint256 totalSupply = uniswapBalancedPair.totalSupply();

        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
            address(uniswapBalancedTokenA), uniswapBalancedPair.token0(), reserve0, reserve1
        );

        uint256 expectedLPTokens = ConstProdUtils._depositQuote(amountA, amountB, totalSupply, reserveA, reserveB);

        uniswapBalancedTokenA.mint(address(this), amountA);
        uniswapBalancedTokenB.mint(address(this), amountB);
        uniswapBalancedTokenA.approve(address(uniswapV2Router), amountA);
        uniswapBalancedTokenB.approve(address(uniswapV2Router), amountB);

        // addLiquidity returns (amountA, amountB, liquidity)
        (, , uint256 actualLPTokens) = uniswapV2Router.addLiquidity(
            address(uniswapBalancedTokenA),
            address(uniswapBalancedTokenB),
            amountA,
            amountB,
            1,
            1,
            address(this),
            block.timestamp
        );

        assertEq(actualLPTokens, expectedLPTokens, "Expected LP tokens should match actual deposit result");

        console.log("_depositQuote Uniswap balanced pool test passed:");
        console.log("  ReserveA:", reserveA);
        console.log("  ReserveB:", reserveB);
        console.log("  TotalSupply:", totalSupply);
        console.log("  Deposit amountA:", amountA);
        console.log("  Deposit amountB:", amountB);
        console.log("  Expected LP tokens:", expectedLPTokens);
        console.log("  Actual LP tokens:", actualLPTokens);
    }

    function test_depositQuote_Uniswap_Second_Deposit_balancedPool() public {
        _initializeUniswapBalancedPools();
        uint256 amountA = 1000e18;
        uint256 amountB = 1000e18;

        (uint112 reserve0, uint112 reserve1,) = uniswapBalancedPair.getReserves();
        uint256 totalSupply = uniswapBalancedPair.totalSupply();

        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
            address(uniswapBalancedTokenA), uniswapBalancedPair.token0(), reserve0, reserve1
        );

        uint256 expectedLPTokens = ConstProdUtils._depositQuote(amountA, amountB, totalSupply, reserveA, reserveB);

        uniswapBalancedTokenA.mint(address(this), amountA);
        uniswapBalancedTokenB.mint(address(this), amountB);
        uniswapBalancedTokenA.approve(address(uniswapV2Router), amountA);
        uniswapBalancedTokenB.approve(address(uniswapV2Router), amountB);

        // addLiquidity returns (amountA, amountB, liquidity)
        (, , uint256 actualLPTokens) = uniswapV2Router.addLiquidity(
            address(uniswapBalancedTokenA),
            address(uniswapBalancedTokenB),
            amountA,
            amountB,
            1,
            1,
            address(this),
            block.timestamp
        );

        assertEq(actualLPTokens, expectedLPTokens, "Expected LP tokens should match actual deposit result");

        console.log("_depositQuote Uniswap second-deposit balanced pool test passed:");
        console.log("  ReserveA:", reserveA);
        console.log("  ReserveB:", reserveB);
        console.log("  TotalSupply:", totalSupply);
        console.log("  Deposit amountA:", amountA);
        console.log("  Deposit amountB:", amountB);
        console.log("  Expected LP tokens:", expectedLPTokens);
        console.log("  Actual LP tokens:", actualLPTokens);
    }
}
