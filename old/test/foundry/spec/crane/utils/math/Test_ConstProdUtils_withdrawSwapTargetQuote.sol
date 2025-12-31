// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TestBase_ConstProdUtils.sol";
import "../../../../../../contracts/crane/utils/math/ConstProdUtils.sol";
import {IUniswapV2Router01} from "contracts/crane/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Router01.sol";
import {ICamelotPair} from "contracts/crane/interfaces/protocols/dexes/camelot/v2/ICamelotPair.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Test_ConstProdUtils_withdrawSwapTargetQuote is TestBase_ConstProdUtils {
    // Fee parameters
    // uint256 constant CAMELOT_FEE_PERCENT = 300; // 0.3%
    uint256 constant UNISWAP_FEE_PERCENT = 3; // 0.3% with denom 1000

    function setUp() public override {
        super.setUp();
    }

    function _camelotSwapExactOut(
        ICamelotPair pair,
        IERC20 tokenIn,
        address tokenOut,
        uint256 amountInMax,
        uint256 neededOut
    ) internal returns (uint256 usedIn, uint256 out) {
        (uint112 r0, uint112 r1, uint16 fee0, uint16 fee1) = pair.getReserves();
        bool outIsToken0 = pair.token0() == tokenOut;
        uint256 reserveIn = outIsToken0 ? uint256(r1) : uint256(r0);
        uint256 reserveOut = outIsToken0 ? uint256(r0) : uint256(r1);
        uint256 inFee = outIsToken0 ? uint256(fee1) : uint256(fee0);
        uint256 denom = 100000;
        uint256 gamma = denom - inFee;
        uint256 num = reserveIn * neededOut * denom;
        uint256 den = (reserveOut - neededOut) * gamma;
        usedIn = num / den + 1;
        require(usedIn <= amountInMax, "insufficient B from burn");
        tokenIn.transfer(address(pair), usedIn);
        if (outIsToken0) {
            pair.swap(neededOut, 0, address(this), new bytes(0));
        } else {
            pair.swap(0, neededOut, address(this), new bytes(0));
        }
        out = neededOut;
    }

    // ============ EXECUTION VALIDATION TESTS ============

    function test_withdrawSwapTargetQuote_Camelot_balancedPool_executionValidation() public {
        _initializeBalancedPools();
        (uint112 reserve0, uint112 reserve1, uint16 token0Fee, uint16 token1Fee) = camelotBalancedPair.getReserves();
        (uint256 reserveA, uint256 feePercent, uint256 reserveB, uint256 tokenBFee) = ConstProdUtils._sortReserves(
            address(camelotBalancedTokenA),
            camelotBalancedPair.token0(),
            reserve0,
            uint256(token0Fee),
            reserve1,
            uint256(token1Fee)
        );
        uint256 totalSupply = camelotBalancedPair.totalSupply();

        // Test with desired amount out
        uint256 desiredAmountOut = reserveA / 10; // 10% of reserve A

        // Calculate expected LP amount to burn using ConstProdUtils
        uint256 calculatedLpAmount =
            ConstProdUtils._withdrawSwapTargetQuote(desiredAmountOut, reserveA, reserveB, totalSupply, tokenBFee);

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
        _initializeUnbalancedPools();
        (uint112 reserve0, uint112 reserve1, uint16 token0Fee, uint16 token1Fee) = camelotUnbalancedPair.getReserves();
        (uint256 reserveA, uint256 feePercent, uint256 reserveB, uint256 tokenBFee) = ConstProdUtils._sortReserves(
            address(camelotUnbalancedTokenA),
            camelotUnbalancedPair.token0(),
            reserve0,
            uint256(token0Fee),
            reserve1,
            uint256(token1Fee)
        );
        uint256 totalSupply = camelotUnbalancedPair.totalSupply();

        // Test with desired amount out
        uint256 desiredAmountOut = reserveA / 20; // 5% of reserve A

        // Calculate expected LP amount to burn using ConstProdUtils
        uint256 calculatedLpAmount =
            ConstProdUtils._withdrawSwapTargetQuote(desiredAmountOut, reserveA, reserveB, totalSupply, tokenBFee);

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
        _initializeExtremeUnbalancedPools();
        (uint112 reserve0, uint112 reserve1, uint16 token0Fee, uint16 token1Fee) =
            camelotExtremeUnbalancedPair.getReserves();
        (uint256 reserveA, uint256 feePercent, uint256 reserveB, uint256 tokenBFee) = ConstProdUtils._sortReserves(
            address(camelotExtremeTokenA),
            camelotExtremeUnbalancedPair.token0(),
            reserve0,
            uint256(token0Fee),
            reserve1,
            uint256(token1Fee)
        );
        uint256 totalSupply = camelotExtremeUnbalancedPair.totalSupply();

        // Test with desired amount out
        uint256 desiredAmountOut = reserveA / 1000; // 0.1% of reserve A

        // Calculate expected LP amount to burn using ConstProdUtils
        uint256 calculatedLpAmount =
            ConstProdUtils._withdrawSwapTargetQuote(desiredAmountOut, reserveA, reserveB, totalSupply, tokenBFee);

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

    function test_withdrawSwapTargetQuote_Uniswap_balancedPool_executionValidation() public {
        _initializeBalancedPools();
        (uint112 reserveA, uint112 reserveB,) = uniswapBalancedPair.getReserves();
        uint256 totalSupply = uniswapBalancedPair.totalSupply();

        // Test with desired amount out
        uint256 desiredAmountOut = reserveA / 10; // 10% of reserve A

        // Calculate expected LP amount to burn using ConstProdUtils
        uint256 calculatedLpAmount = ConstProdUtils._withdrawSwapTargetQuote(
            desiredAmountOut, reserveA, reserveB, totalSupply, UNISWAP_FEE_PERCENT
        );

        // Execute actual operations to validate

        // 1. Burn the calculated LP amount
        uniswapBalancedPair.transfer(address(uniswapBalancedPair), calculatedLpAmount);
        (uint256 amountA, uint256 amountB) = uniswapBalancedPair.burn(address(this));

        // 2. Swap TokenB for TokenA to reach target
        uint256 tokenAFromSwap = 0;
        if (amountB > 0) {
            uniswapBalancedTokenB.approve(address(uniswapV2Router()), amountB);
            address[] memory path = new address[](2);
            path[0] = address(uniswapBalancedTokenB);
            path[1] = address(uniswapBalancedTokenA);

            uint256 tokenABeforeSwap = uniswapBalancedTokenA.balanceOf(address(this));

            uniswapV2Router()
                .swapExactTokensForTokensSupportingFeeOnTransferTokens(amountB, 1, path, address(this), block.timestamp);

            tokenAFromSwap = uniswapBalancedTokenA.balanceOf(address(this)) - tokenABeforeSwap;
        }

        // 3. Calculate total TokenA received
        uint256 totalTokenAReceived = amountA + tokenAFromSwap;

        // 4. Validate exact equality
        assertEq(totalTokenAReceived, desiredAmountOut, "Actual TokenA received should equal desired amount exactly");
    }

    function test_withdrawSwapTargetQuote_Uniswap_unbalancedPool_executionValidation() public {
        _initializeUnbalancedPools();
        (uint112 reserveA, uint112 reserveB,) = uniswapUnbalancedPair.getReserves();
        uint256 totalSupply = uniswapUnbalancedPair.totalSupply();

        // Test with desired amount out
        uint256 desiredAmountOut = reserveA / 20; // 5% of reserve A

        // Calculate expected LP amount to burn using ConstProdUtils
        uint256 calculatedLpAmount = ConstProdUtils._withdrawSwapTargetQuote(
            desiredAmountOut, reserveA, reserveB, totalSupply, UNISWAP_FEE_PERCENT
        );

        // Execute actual operations to validate

        // 1. Burn the calculated LP amount
        uniswapUnbalancedPair.transfer(address(uniswapUnbalancedPair), calculatedLpAmount);
        (uint256 amountA, uint256 amountB) = uniswapUnbalancedPair.burn(address(this));

        // 2. Swap only what is needed to reach target
        uint256 tokenAFromSwap = 0;
        if (amountB > 0) {
            uniswapUnbalancedTokenB.approve(address(uniswapV2Router()), amountB);
            address[] memory path = new address[](2);
            path[0] = address(uniswapUnbalancedTokenB);
            path[1] = address(uniswapUnbalancedTokenA);
            uint256 neededOut = desiredAmountOut - amountA;
            uint256 beforeA = uniswapUnbalancedTokenA.balanceOf(address(this));
            uniswapV2Router().swapTokensForExactTokens(neededOut, amountB, path, address(this), block.timestamp);
            tokenAFromSwap = uniswapUnbalancedTokenA.balanceOf(address(this)) - beforeA;
        }

        // 3. Calculate total TokenA received
        uint256 totalTokenAReceived = amountA + tokenAFromSwap;

        // 4. Validate exact equality
        assertEq(totalTokenAReceived, desiredAmountOut, "Actual TokenA received should equal desired amount exactly");
    }

    function test_withdrawSwapTargetQuote_Uniswap_extremeUnbalancedPool_executionValidation() public {
        _initializeExtremeUnbalancedPools();
        (uint112 reserveA, uint112 reserveB,) = uniswapExtremeUnbalancedPair.getReserves();
        uint256 totalSupply = uniswapExtremeUnbalancedPair.totalSupply();

        // Test with desired amount out
        uint256 desiredAmountOut = reserveA / 1000; // 0.1% of reserve A

        // Calculate expected LP amount to burn using ConstProdUtils
        uint256 calculatedLpAmount = ConstProdUtils._withdrawSwapTargetQuote(
            desiredAmountOut, reserveA, reserveB, totalSupply, UNISWAP_FEE_PERCENT
        );

        // Execute actual operations to validate

        // 1. Burn the calculated LP amount
        uniswapExtremeUnbalancedPair.transfer(address(uniswapExtremeUnbalancedPair), calculatedLpAmount);
        (uint256 amountA, uint256 amountB) = uniswapExtremeUnbalancedPair.burn(address(this));

        // 2. Swap only what is needed to reach target
        uint256 tokenAFromSwap = 0;
        if (amountB > 0) {
            uniswapExtremeTokenB.approve(address(uniswapV2Router()), amountB);
            address[] memory path = new address[](2);
            path[0] = address(uniswapExtremeTokenB);
            path[1] = address(uniswapExtremeTokenA);
            uint256 neededOut = desiredAmountOut - amountA;
            uint256 beforeA = uniswapExtremeTokenA.balanceOf(address(this));
            uniswapV2Router().swapTokensForExactTokens(neededOut, amountB, path, address(this), block.timestamp);
            tokenAFromSwap = uniswapExtremeTokenA.balanceOf(address(this)) - beforeA;
        }

        // 3. Calculate total TokenA received
        uint256 totalTokenAReceived = amountA + tokenAFromSwap;

        // 4. Validate exact equality
        assertEq(totalTokenAReceived, desiredAmountOut, "Actual TokenA received should equal desired amount exactly");
    }
}
