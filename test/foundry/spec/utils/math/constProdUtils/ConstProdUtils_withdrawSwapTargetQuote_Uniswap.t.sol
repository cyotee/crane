// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {TestBase_ConstProdUtils_Uniswap} from "./TestBase_ConstProdUtils_Uniswap.sol";
import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";

contract ConstProdUtils_withdrawSwapTargetQuote_Uniswap is TestBase_ConstProdUtils_Uniswap {
    function setUp() public override {
        super.setUp();
    }

    function test_withdrawSwapTargetQuote_Uniswap_balancedPool_executionValidation() public {
        _initializeUniswapBalancedPools();
        (uint112 reserveA, uint112 reserveB,) = uniswapBalancedPair.getReserves();
        uint256 totalSupply = uniswapBalancedPair.totalSupply();

        // Test with desired amount out
        uint256 desiredAmountOut = reserveA / 10; // 10% of reserve A

        // Calculate expected LP amount to burn using ConstProdUtils
        uint256 calculatedLpAmount = ConstProdUtils._withdrawSwapTargetQuote(
            desiredAmountOut, reserveA, reserveB, totalSupply, 3
        );

        // Execute actual operations to validate

        // 1. Burn the calculated LP amount
        uniswapBalancedPair.transfer(address(uniswapBalancedPair), calculatedLpAmount);
        (uint256 amountA, uint256 amountB) = uniswapBalancedPair.burn(address(this));

        // 2. Swap TokenB for TokenA to reach target
        uint256 tokenAFromSwap = 0;
        if (amountB > 0) {
            uniswapBalancedTokenB.approve(address(uniswapV2Router), amountB);
            address[] memory path = new address[](2);
            path[0] = address(uniswapBalancedTokenB);
            path[1] = address(uniswapBalancedTokenA);

            uint256 tokenABeforeSwap = uniswapBalancedTokenA.balanceOf(address(this));

            uniswapV2Router
                .swapExactTokensForTokensSupportingFeeOnTransferTokens(amountB, 1, path, address(this), block.timestamp);

            tokenAFromSwap = uniswapBalancedTokenA.balanceOf(address(this)) - tokenABeforeSwap;
        }

        // 3. Calculate total TokenA received
        uint256 totalTokenAReceived = amountA + tokenAFromSwap;

        // 4. Validate exact equality
        assertEq(totalTokenAReceived, desiredAmountOut, "Actual TokenA received should equal desired amount exactly");
    }

    function test_withdrawSwapTargetQuote_Uniswap_unbalancedPool_executionValidation() public {
        _initializeUniswapUnbalancedPools();
        (uint112 reserveA, uint112 reserveB,) = uniswapUnbalancedPair.getReserves();
        uint256 totalSupply = uniswapUnbalancedPair.totalSupply();

        // Test with desired amount out
        uint256 desiredAmountOut = reserveA / 20; // 5% of reserve A

        // Calculate expected LP amount to burn using ConstProdUtils
        uint256 calculatedLpAmount = ConstProdUtils._withdrawSwapTargetQuote(
            desiredAmountOut, reserveA, reserveB, totalSupply, 3
        );

        // Execute actual operations to validate

        // 1. Burn the calculated LP amount
        uniswapUnbalancedPair.transfer(address(uniswapUnbalancedPair), calculatedLpAmount);
        (uint256 amountA, uint256 amountB) = uniswapUnbalancedPair.burn(address(this));

        // 2. Swap only what is needed to reach target
        uint256 tokenAFromSwap = 0;
        if (amountB > 0) {
            uniswapUnbalancedTokenB.approve(address(uniswapV2Router), amountB);
            address[] memory path = new address[](2);
            path[0] = address(uniswapUnbalancedTokenB);
            path[1] = address(uniswapUnbalancedTokenA);
            uint256 neededOut = desiredAmountOut - amountA;
            uint256 beforeA = uniswapUnbalancedTokenA.balanceOf(address(this));
            uniswapV2Router.swapTokensForExactTokens(neededOut, amountB, path, address(this), block.timestamp);
            tokenAFromSwap = uniswapUnbalancedTokenA.balanceOf(address(this)) - beforeA;
        }

        // 3. Calculate total TokenA received
        uint256 totalTokenAReceived = amountA + tokenAFromSwap;

        // 4. Validate exact equality
        assertEq(totalTokenAReceived, desiredAmountOut, "Actual TokenA received should equal desired amount exactly");
    }

    function test_withdrawSwapTargetQuote_Uniswap_extremeUnbalancedPool_executionValidation() public {
        _initializeUniswapExtremeUnbalancedPools();
        (uint112 reserveA, uint112 reserveB,) = uniswapExtremeUnbalancedPair.getReserves();
        uint256 totalSupply = uniswapExtremeUnbalancedPair.totalSupply();

        // Test with desired amount out
        uint256 desiredAmountOut = reserveA / 1000; // 0.1% of reserve A

        // Calculate expected LP amount to burn using ConstProdUtils
        uint256 calculatedLpAmount = ConstProdUtils._withdrawSwapTargetQuote(
            desiredAmountOut, reserveA, reserveB, totalSupply, 3
        );

        // Execute actual operations to validate

        // 1. Burn the calculated LP amount
        uniswapExtremeUnbalancedPair.transfer(address(uniswapExtremeUnbalancedPair), calculatedLpAmount);
        (uint256 amountA, uint256 amountB) = uniswapExtremeUnbalancedPair.burn(address(this));

        // 2. Swap only what is needed to reach target
        uint256 tokenAFromSwap = 0;
        if (amountB > 0) {
            uniswapExtremeTokenB.approve(address(uniswapV2Router), amountB);
            address[] memory path = new address[](2);
            path[0] = address(uniswapExtremeTokenB);
            path[1] = address(uniswapExtremeTokenA);
            uint256 neededOut = desiredAmountOut - amountA;
            uint256 beforeA = uniswapExtremeTokenA.balanceOf(address(this));
            uniswapV2Router.swapTokensForExactTokens(neededOut, amountB, path, address(this), block.timestamp);
            tokenAFromSwap = uniswapExtremeTokenA.balanceOf(address(this)) - beforeA;
        }

        // 3. Calculate total TokenA received
        uint256 totalTokenAReceived = amountA + tokenAFromSwap;

        // 4. Validate exact equality
        assertEq(totalTokenAReceived, desiredAmountOut, "Actual TokenA received should equal desired amount exactly");
    }
}
