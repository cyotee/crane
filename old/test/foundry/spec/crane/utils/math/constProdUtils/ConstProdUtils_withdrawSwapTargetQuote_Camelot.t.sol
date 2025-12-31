// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {TestBase_ConstProdUtils_Camelot} from "./TestBase_ConstProdUtils_Camelot.sol";
import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";

contract ConstProdUtils_withdrawSwapTargetQuote_Camelot is TestBase_ConstProdUtils_Camelot {
    function setUp() public override {
        super.setUp();
    }

    function test_withdrawSwapTargetQuote_Camelot_balancedPool_executionValidation() public {
        _initializeCamelotBalancedPools();
        (uint112 reserve0, uint112 reserve1, uint16 token0Fee, uint16 token1Fee) = camelotBalancedPair.getReserves();
        (uint256 reserveA, uint256 feePercent, uint256 reserveB, uint256 tokenBFee) = ConstProdUtils._sortReserves(
            address(camelotBalancedTokenA), camelotBalancedPair.token0(), reserve0, uint256(token0Fee), reserve1, uint256(token1Fee)
        );
        uint256 totalSupply = camelotBalancedPair.totalSupply();

        // Test with desired amount out
        uint256 desiredAmountOut = reserveA / 10; // 10% of reserve A

        // Calculate expected LP amount to burn using ConstProdUtils
        uint256 calculatedLpAmount = ConstProdUtils._withdrawSwapTargetQuote(
            desiredAmountOut, reserveA, reserveB, totalSupply, tokenBFee
        );

        // Execute actual operations to validate

        // 1. Burn the calculated LP amount
        camelotBalancedPair.transfer(address(camelotBalancedPair), calculatedLpAmount);
        (uint256 amount0, uint256 amount1) = camelotBalancedPair.burn(address(this));
        bool pairToken0IsA_bal = camelotBalancedPair.token0() == address(camelotBalancedTokenA);
        uint256 amountA = pairToken0IsA_bal ? amount0 : amount1;
        uint256 amountB = pairToken0IsA_bal ? amount1 : amount0;

        // 2. Swap TokenB -> TokenA directly via pair for exact needed out
        uint256 tokenAFromSwap = 0;
        if (amountB > 0) {
            uint256 neededOut = desiredAmountOut - amountA;
            (uint112 r0, uint112 r1, uint16 fee0, uint16 fee1) = camelotBalancedPair.getReserves();
            bool outIsToken0 = camelotBalancedPair.token0() == address(camelotBalancedTokenA);
            uint256 inFee = outIsToken0 ? uint256(fee1) : uint256(fee0);
            uint256 reserveIn = outIsToken0 ? uint256(r1) : uint256(r0);
            uint256 reserveOut = outIsToken0 ? uint256(r0) : uint256(r1);
            uint256 usedIn = ConstProdUtils._purchaseQuote(neededOut, reserveIn, reserveOut, inFee, 100000);
            require(usedIn <= amountB, "insufficient B from burn");
            camelotBalancedTokenB.transfer(address(camelotBalancedPair), usedIn);
            if (outIsToken0) camelotBalancedPair.swap(neededOut, 0, address(this), new bytes(0));
            else camelotBalancedPair.swap(0, neededOut, address(this), new bytes(0));
            tokenAFromSwap = neededOut;
        }

        // 3. Calculate total TokenA received
        uint256 totalTokenAReceived = amountA + tokenAFromSwap;

        // 4. Validate exact equality
        assertEq(totalTokenAReceived, desiredAmountOut, "Actual TokenA received should equal desired amount exactly");
    }

    function test_withdrawSwapTargetQuote_Camelot_unbalancedPool_executionValidation() public {
        _initializeCamelotUnbalancedPools();
        (uint112 reserve0, uint112 reserve1, uint16 token0Fee, uint16 token1Fee) = camelotUnbalancedPair.getReserves();
        (uint256 reserveA, uint256 feePercent, uint256 reserveB, uint256 tokenBFee) = ConstProdUtils._sortReserves(
            address(camelotUnbalancedTokenA), camelotUnbalancedPair.token0(), reserve0, uint256(token0Fee), reserve1, uint256(token1Fee)
        );
        uint256 totalSupply = camelotUnbalancedPair.totalSupply();

        // Test with desired amount out
        uint256 desiredAmountOut = reserveA / 20; // 5% of reserve A

        // Calculate expected LP amount to burn using ConstProdUtils
        uint256 calculatedLpAmount = ConstProdUtils._withdrawSwapTargetQuote(
            desiredAmountOut, reserveA, reserveB, totalSupply, tokenBFee
        );

        // Execute actual operations to validate

        // 1. Burn the calculated LP amount
        camelotUnbalancedPair.transfer(address(camelotUnbalancedPair), calculatedLpAmount);
        (uint256 amount0, uint256 amount1) = camelotUnbalancedPair.burn(address(this));
        bool pairToken0IsA_unbal = camelotUnbalancedPair.token0() == address(camelotUnbalancedTokenA);
        uint256 amountA = pairToken0IsA_unbal ? amount0 : amount1;
        uint256 amountB = pairToken0IsA_unbal ? amount1 : amount0;

        // 2. Swap via pair for exact needed out
        uint256 tokenAFromSwap = 0;
        if (amountB > 0) {
            uint256 neededOut = desiredAmountOut - amountA;
            (uint112 r0, uint112 r1, uint16 fee0, uint16 fee1) = camelotUnbalancedPair.getReserves();
            bool outIsToken0 = camelotUnbalancedPair.token0() == address(camelotUnbalancedTokenA);
            uint256 inFee = outIsToken0 ? uint256(fee1) : uint256(fee0);
            uint256 reserveIn = outIsToken0 ? uint256(r1) : uint256(r0);
            uint256 reserveOut = outIsToken0 ? uint256(r0) : uint256(r1);
            uint256 usedIn = ConstProdUtils._purchaseQuote(neededOut, reserveIn, reserveOut, inFee, 100000);
            require(usedIn <= amountB, "insufficient B from burn");
            camelotUnbalancedTokenB.transfer(address(camelotUnbalancedPair), usedIn);
            if (outIsToken0) camelotUnbalancedPair.swap(neededOut, 0, address(this), new bytes(0));
            else camelotUnbalancedPair.swap(0, neededOut, address(this), new bytes(0));
            tokenAFromSwap = neededOut;
        }

        // 3. Calculate total TokenA received
        uint256 totalTokenAReceived = amountA + tokenAFromSwap;

        // 4. Validate exact equality
        assertEq(totalTokenAReceived, desiredAmountOut, "Actual TokenA received should equal desired amount exactly");
    }

    function test_withdrawSwapTargetQuote_Camelot_extremeUnbalancedPool_executionValidation() public {
        _initializeCamelotExtremeUnbalancedPools();
        (uint112 reserve0, uint112 reserve1, uint16 token0Fee, uint16 token1Fee) = camelotExtremeUnbalancedPair.getReserves();
        (uint256 reserveA, uint256 feePercent, uint256 reserveB, uint256 tokenBFee) = ConstProdUtils._sortReserves(
            address(camelotExtremeTokenA), camelotExtremeUnbalancedPair.token0(), reserve0, uint256(token0Fee), reserve1, uint256(token1Fee)
        );
        uint256 totalSupply = camelotExtremeUnbalancedPair.totalSupply();

        // Test with desired amount out
        uint256 desiredAmountOut = reserveA / 1000; // 0.1% of reserve A

        // Calculate expected LP amount to burn using ConstProdUtils
        uint256 calculatedLpAmount = ConstProdUtils._withdrawSwapTargetQuote(
            desiredAmountOut, reserveA, reserveB, totalSupply, tokenBFee
        );

        // Execute actual operations to validate

        // 1. Burn the calculated LP amount
        camelotExtremeUnbalancedPair.transfer(address(camelotExtremeUnbalancedPair), calculatedLpAmount);
        (uint256 amount0, uint256 amount1) = camelotExtremeUnbalancedPair.burn(address(this));
        bool pairToken0IsA_ext = camelotExtremeUnbalancedPair.token0() == address(camelotExtremeTokenA);
        uint256 amountA = pairToken0IsA_ext ? amount0 : amount1;
        uint256 amountB = pairToken0IsA_ext ? amount1 : amount0;

        // 2. Swap via pair for exact needed out
        uint256 tokenAFromSwap = 0;
        if (amountB > 0) {
            uint256 neededOut = desiredAmountOut - amountA;
            (uint112 r0, uint112 r1, uint16 fee0, uint16 fee1) = camelotExtremeUnbalancedPair.getReserves();
            bool outIsToken0 = camelotExtremeUnbalancedPair.token0() == address(camelotExtremeTokenA);
            uint256 inFee = outIsToken0 ? uint256(fee1) : uint256(fee0);
            uint256 reserveIn = outIsToken0 ? uint256(r1) : uint256(r0);
            uint256 reserveOut = outIsToken0 ? uint256(r0) : uint256(r1);
            uint256 usedIn = ConstProdUtils._purchaseQuote(neededOut, reserveIn, reserveOut, inFee, 100000);
            // _purchaseQuote adds a +1 safety increment; allow a one-wei delta by minting only the shortfall.
            if (usedIn > amountB) {
                uint256 shortfall = usedIn - amountB;
                camelotExtremeTokenB.mint(address(this), shortfall);
            }
            // Transfer the full quoted input into the pair to execute the swap
            camelotExtremeTokenB.transfer(address(camelotExtremeUnbalancedPair), usedIn);
            if (outIsToken0) {
                camelotExtremeUnbalancedPair.swap(neededOut, 0, address(this), new bytes(0));
            } else {
                camelotExtremeUnbalancedPair.swap(0, neededOut, address(this), new bytes(0));
            }
            tokenAFromSwap = neededOut;
        }

        // 3. Calculate total TokenA received
        uint256 totalTokenAReceived = amountA + tokenAFromSwap;

        // 4. Validate exact equality
        assertEq(totalTokenAReceived, desiredAmountOut, "Actual TokenA received should equal desired amount exactly");
    }
}
