// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {betterconsole as console} from "contracts/crane/utils/vm/foundry/tools/betterconsole.sol";
import {TestBase_ConstProdUtils} from "./TestBase_ConstProdUtils.sol";
import {ConstProdUtils} from "contracts/crane/utils/math/ConstProdUtils.sol";
import {CamelotV2Service} from "contracts/crane/protocols/dexes/camelot/v2/utils/CamelotV2Service.sol";
import {UniswapV2Service} from "contracts/crane/protocols/dexes/uniswap/v2/utils/UniswapV2Service.sol";
import {IUniswapV2Router} from "contracts/crane/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Router.sol";
import {IUniswapV2Pair} from "contracts/crane/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Pair.sol";
import {FEE_DENOMINATOR} from "@crane/src/constants/Constants.sol";

contract Test_ConstProdUtils_swapDepositSaleAmt is TestBase_ConstProdUtils {
    using ConstProdUtils for uint256;

    function setUp() public override {
        super.setUp();
    }

    /* ---------------------------------------------------------------------- */
    /*                        BASIC FUNCTIONALITY TESTS                       */
    /* ---------------------------------------------------------------------- */

    function _expectedLpAfterSwap(
        uint256 remainingTokenA,
        uint256 tokenBReceived,
        uint256 lpTotalSupply,
        uint256 reserveA,
        uint256 reserveB,
        uint256 saleAmt,
        uint256 feePercent
    ) internal pure returns (uint256) {
        uint256 amountInAfterFee = (saleAmt * (FEE_DENOMINATOR - feePercent)) / FEE_DENOMINATOR;
        return ConstProdUtils._depositQuote(
            remainingTokenA,
            tokenBReceived,
            lpTotalSupply,
            // Camelot-style: reserveIn increases by post-fee input
            reserveA + amountInAfterFee,
            reserveB - tokenBReceived
        );
    }

    // Helper: assert that router-returned liquidity equals depositQuote for router-selected integers
    function _assertRouterLiquidityMatchesDepositQuote(
        uint256 amountAUsed,
        uint256 amountBUsed,
        uint256 lpTotalBefore,
        uint256 reserveA,
        uint256 reserveB,
        uint256 saleAmt,
        uint256 tokenBReceived,
        uint256 actualLPTokens
    ) internal {
        uint256 expected = ConstProdUtils._depositQuote(
            amountAUsed,
            amountBUsed,
            lpTotalBefore,
            reserveA + saleAmt,
            reserveB - tokenBReceived
        );
        assertEq(actualLPTokens, expected);
    }

    // Helper to run router.addLiquidity and assert returned liquidity matches depositQuote
    function _runUniswapAddLiquidityAndAssert(
        uint256 reserveA,
        uint256 reserveB,
        uint256 saleAmt,
        uint256 remainingTokenA,
        uint256 tokenBReceived
    ) internal {
        uint256 lpTotalBefore = uniswapBalancedPair.totalSupply();
        (uint256 amountAUsed, uint256 amountBUsed, uint256 actualLPTokens) = uniswapV2Router()
            .addLiquidity(
                address(uniswapBalancedTokenA),
                address(uniswapBalancedTokenB),
                remainingTokenA,
                tokenBReceived,
                1,
                1,
                address(this),
                block.timestamp + 300
            );
        uint256 expected = ConstProdUtils._depositQuote(
            amountAUsed,
            amountBUsed,
            lpTotalBefore,
            reserveA + saleAmt,
            reserveB - tokenBReceived
        );
        assertEq(actualLPTokens, expected);
    }

    function test_swapDepositSaleAmt_Camelot_balancedPool() public {
        uint256 reserveA;
        uint256 reserveB;
        uint256 feePercent;
        {
            (uint112 r0, uint112 r1, uint16 f0, uint16 f1) = camelotBalancedPair.getReserves();
            (reserveA, feePercent, reserveB,) = ConstProdUtils._sortReserves(
                address(camelotBalancedTokenA), camelotBalancedPair.token0(), r0, uint256(f0), r1, uint256(f1)
            );
        }
        uint256 amountIn = 1000e18; // Input amount

        // Calculate sale amount using ConstProdUtils (use small-denom parity when fee is small)
        uint256 denom = feePercent <= 10 ? 1000 : FEE_DENOMINATOR;
        uint256 saleAmt = ConstProdUtils._swapDepositSaleAmt(amountIn, reserveA, feePercent, denom);

        // Mint tokens and execute the swap in a scoped block
        uint256 tokenBReceived;
        {
            camelotBalancedTokenA.mint(address(this), amountIn);
            camelotBalancedTokenA.approve(address(camV2Router()), amountIn);
            address[] memory path = new address[](2);
            path[0] = address(camelotBalancedTokenA);
            path[1] = address(camelotBalancedTokenB);
            uint256 tokenBBeforeSwap = camelotBalancedTokenB.balanceOf(address(this));
            camV2Router()
                .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    saleAmt, 0, path, address(this), address(0), block.timestamp + 300
                );
            tokenBReceived = camelotBalancedTokenB.balanceOf(address(this)) - tokenBBeforeSwap;
        }

        uint256 remainingTokenA = amountIn - saleAmt;
        uint256 expectedLPTokens;
        {
            (uint112 ur0, uint112 ur1,,) = camelotBalancedPair.getReserves();
            uint256 updatedReserveA =
                (address(camelotBalancedTokenA) == camelotBalancedPair.token0()) ? uint256(ur0) : uint256(ur1);
            uint256 updatedReserveB =
                (address(camelotBalancedTokenA) == camelotBalancedPair.token0()) ? uint256(ur1) : uint256(ur0);
            expectedLPTokens = ConstProdUtils._quoteDepositWithFee(
                remainingTokenA,
                tokenBReceived,
                camelotBalancedPair.totalSupply(),
                updatedReserveA,
                updatedReserveB,
                camelotBalancedPair.kLast(),
                camV2Factory().ownerFeeShare(),
                true
            );
        }

        // Execute the deposit by direct mint to avoid router rounding
        camelotBalancedTokenA.transfer(address(camelotBalancedPair), remainingTokenA);
        camelotBalancedTokenB.transfer(address(camelotBalancedPair), tokenBReceived);
        uint256 actualLPTokens = camelotBalancedPair.mint(address(this));

        // Validate exact equality
        assertEq(actualLPTokens, expectedLPTokens, "Actual LP tokens should equal expected LP tokens exactly");
    }

    function test_swapDepositSaleAmt_Camelot_unbalancedPool() public {
        uint256 reserveA;
        uint256 reserveB;
        uint256 feePercent;
        {
            (uint112 r0, uint112 r1, uint16 f0, uint16 f1) = camelotUnbalancedPair.getReserves();
            (reserveA, feePercent, reserveB,) = ConstProdUtils._sortReserves(
                address(camelotUnbalancedTokenA), camelotUnbalancedPair.token0(), r0, uint256(f0), r1, uint256(f1)
            );
        }
        uint256 amountIn = 100e18; // Smaller input for unbalanced pool

        // Calculate sale amount using ConstProdUtils (use small-denom parity when fee is small)
        uint256 denom = feePercent <= 10 ? 1000 : FEE_DENOMINATOR;
        uint256 saleAmt = ConstProdUtils._swapDepositSaleAmt(amountIn, reserveA, feePercent, denom);

        uint256 tokenBReceived;
        {
            camelotUnbalancedTokenA.mint(address(this), amountIn);
            camelotUnbalancedTokenA.approve(address(camV2Router()), amountIn);
            address[] memory path = new address[](2);
            path[0] = address(camelotUnbalancedTokenA);
            path[1] = address(camelotUnbalancedTokenB);
            uint256 tokenBBeforeSwap = camelotUnbalancedTokenB.balanceOf(address(this));
            camV2Router()
                .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    saleAmt, 0, path, address(this), address(0), block.timestamp + 300
                );
            tokenBReceived = camelotUnbalancedTokenB.balanceOf(address(this)) - tokenBBeforeSwap;
        }

        // Calculate expected LP tokens using _depositQuote
        uint256 remainingTokenA = amountIn - saleAmt;
        uint256 expectedLPTokens;
        {
            (uint112 ur0, uint112 ur1,,) = camelotUnbalancedPair.getReserves();
            uint256 updatedReserveA =
                (address(camelotUnbalancedTokenA) == camelotUnbalancedPair.token0()) ? uint256(ur0) : uint256(ur1);
            uint256 updatedReserveB =
                (address(camelotUnbalancedTokenA) == camelotUnbalancedPair.token0()) ? uint256(ur1) : uint256(ur0);
            expectedLPTokens = ConstProdUtils._quoteDepositWithFee(
                remainingTokenA,
                tokenBReceived,
                camelotUnbalancedPair.totalSupply(),
                updatedReserveA,
                updatedReserveB,
                camelotUnbalancedPair.kLast(),
                camV2Factory().ownerFeeShare(),
                true
            );
        }

        // Execute the deposit by direct mint to avoid router rounding
        camelotUnbalancedTokenA.transfer(address(camelotUnbalancedPair), remainingTokenA);
        camelotUnbalancedTokenB.transfer(address(camelotUnbalancedPair), tokenBReceived);
        uint256 actualLPTokens = camelotUnbalancedPair.mint(address(this));

        // Validate exact equality
        assertEq(actualLPTokens, expectedLPTokens, "Actual LP tokens should equal expected LP tokens exactly");
    }

    function test_swapDepositSaleAmt_Camelot_extremeUnbalancedPool() public {
        uint256 reserveA;
        uint256 reserveB;
        uint256 feePercent;
        {
            (uint112 r0, uint112 r1, uint16 f0, uint16 f1) = camelotBalancedPair.getReserves();
            (reserveA, feePercent, reserveB,) = ConstProdUtils._sortReserves(
                address(camelotBalancedTokenA), camelotBalancedPair.token0(), r0, uint256(f0), r1, uint256(f1)
            );
        }
        uint256 amountIn = 10e18; // Very small input for extreme unbalanced pool

        // Calculate sale amount using ConstProdUtils (use small-denom parity when fee is small)
        uint256 denom = feePercent <= 10 ? 1000 : FEE_DENOMINATOR;
        uint256 saleAmt = ConstProdUtils._swapDepositSaleAmt(amountIn, reserveA, feePercent, denom);

        uint256 tokenBReceived;
        {
            camelotBalancedTokenA.mint(address(this), amountIn);
            camelotBalancedTokenA.approve(address(camV2Router()), amountIn);
            address[] memory path = new address[](2);
            path[0] = address(camelotBalancedTokenA);
            path[1] = address(camelotBalancedTokenB);
            uint256 tokenBBeforeSwap = camelotBalancedTokenB.balanceOf(address(this));
            camV2Router()
                .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    saleAmt, 0, path, address(this), address(0), block.timestamp + 300
                );
            tokenBReceived = camelotBalancedTokenB.balanceOf(address(this)) - tokenBBeforeSwap;
        }

        // Calculate expected LP tokens using _depositQuote
        uint256 remainingTokenA = amountIn - saleAmt;
        uint256 expectedLPTokens;
        {
            (uint112 ur0, uint112 ur1,,) = camelotBalancedPair.getReserves();
            uint256 updatedReserveA =
                (address(camelotBalancedTokenA) == camelotBalancedPair.token0()) ? uint256(ur0) : uint256(ur1);
            uint256 updatedReserveB =
                (address(camelotBalancedTokenA) == camelotBalancedPair.token0()) ? uint256(ur1) : uint256(ur0);
            expectedLPTokens = ConstProdUtils._quoteDepositWithFee(
                remainingTokenA,
                tokenBReceived,
                camelotBalancedPair.totalSupply(),
                updatedReserveA,
                updatedReserveB,
                camelotBalancedPair.kLast(),
                camV2Factory().ownerFeeShare(),
                true
            );
        }

        // Execute the deposit by direct mint to avoid router rounding
        camelotBalancedTokenA.transfer(address(camelotBalancedPair), remainingTokenA);
        camelotBalancedTokenB.transfer(address(camelotBalancedPair), tokenBReceived);
        uint256 actualLPTokens = camelotBalancedPair.mint(address(this));

        // Validate exact equality
        assertEq(actualLPTokens, expectedLPTokens, "Actual LP tokens should equal expected LP tokens exactly");
    }

    function test_swapDepositSaleAmt_Uniswap_balancedPool() public {
        (uint112 reserveA, uint112 reserveB,) = uniswapBalancedPair.getReserves();
        (,, uint32 feeA) = uniswapBalancedPair.getReserves();
        uint256 feePercent = uint256(feeA);
        uint256 amountIn = 1000e18; // Input amount

        // Calculate sale amount using ConstProdUtils
        uint256 saleAmt = ConstProdUtils._swapDepositSaleAmt(amountIn, reserveA, feePercent);

        // Mint tokens for the test
        uniswapBalancedTokenA.mint(address(this), amountIn);
        uniswapBalancedTokenA.approve(address(uniswapV2Router()), amountIn);

        // Execute the swap
        address[] memory path = new address[](2);
        path[0] = address(uniswapBalancedTokenA);
        path[1] = address(uniswapBalancedTokenB);

        uint256 tokenBBeforeSwap = uniswapBalancedTokenB.balanceOf(address(this));
        uniswapV2Router()
            .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                saleAmt, 0, path, address(this), block.timestamp + 300
            );
        uint256 tokenBReceived = uniswapBalancedTokenB.balanceOf(address(this)) - tokenBBeforeSwap;

        // Calculate remaining token A after swap
        uint256 remainingTokenA = amountIn - saleAmt;
        // Calculate expected LP tokens using _depositQuote
        uint256 expectedLPTokens = ConstProdUtils._depositQuote(
            remainingTokenA,
            tokenBReceived,
            uniswapBalancedPair.totalSupply(),
            reserveA + saleAmt, // New reserveA after swap
            reserveB - tokenBReceived // New reserveB after swap
        );

        // Execute the deposit directly to the pair and mint to avoid router rounding
        uniswapBalancedTokenA.transfer(address(uniswapBalancedPair), remainingTokenA);
        uniswapBalancedTokenB.transfer(address(uniswapBalancedPair), tokenBReceived);
        uint256 actualLPTokens = IUniswapV2Pair(address(uniswapBalancedPair)).mint(address(this));

        // Validate exact equality
        assertEq(actualLPTokens, expectedLPTokens, "Actual LP tokens should equal expected LP tokens exactly");
    }

    function test_swapDepositSaleAmt_Uniswap_unbalancedPool() public {
        (uint112 reserveA, uint112 reserveB,) = uniswapBalancedPair.getReserves();
        (,, uint32 feeA) = uniswapBalancedPair.getReserves();
        uint256 feePercent = uint256(feeA);
        uint256 amountIn = 100e18; // Smaller input for unbalanced pool

        // Calculate sale amount using ConstProdUtils
        uint256 saleAmt = ConstProdUtils._swapDepositSaleAmt(amountIn, reserveA, feePercent);

        // Mint tokens for the test
        uniswapBalancedTokenA.mint(address(this), amountIn);
        uniswapBalancedTokenA.approve(address(uniswapV2Router()), amountIn);

        // Execute the swap
        address[] memory path = new address[](2);
        path[0] = address(uniswapBalancedTokenA);
        path[1] = address(uniswapBalancedTokenB);

        uint256 tokenBBeforeSwap = uniswapBalancedTokenB.balanceOf(address(this));
        uniswapV2Router()
            .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                saleAmt, 0, path, address(this), block.timestamp + 300
            );
        uint256 tokenBReceived = uniswapBalancedTokenB.balanceOf(address(this)) - tokenBBeforeSwap;

        // Calculate expected LP tokens using _depositQuote
        uint256 remainingTokenA = amountIn - saleAmt;
        uint256 expectedLPTokens = ConstProdUtils._depositQuote(
            remainingTokenA,
            tokenBReceived,
            uniswapBalancedPair.totalSupply(),
            reserveA + saleAmt, // New reserveA after swap
            reserveB - tokenBReceived // New reserveB after swap
        );

        // Execute the deposit
        uniswapBalancedTokenA.approve(address(uniswapV2Router()), remainingTokenA);
        uniswapBalancedTokenB.approve(address(uniswapV2Router()), tokenBReceived);

        _runUniswapAddLiquidityAndAssert(reserveA, reserveB, saleAmt, remainingTokenA, tokenBReceived);
    }

    function test_swapDepositSaleAmt_Uniswap_extremeUnbalancedPool() public {
        (uint112 reserveA, uint112 reserveB,) = uniswapBalancedPair.getReserves();
        (,, uint32 feeA) = uniswapBalancedPair.getReserves();
        uint256 feePercent = uint256(feeA);
        uint256 amountIn = 10e18; // Very small input for extreme unbalanced pool

        // Calculate sale amount using ConstProdUtils
        uint256 saleAmt = ConstProdUtils._swapDepositSaleAmt(amountIn, reserveA, feePercent);

        // Mint tokens for the test
        uniswapBalancedTokenA.mint(address(this), amountIn);
        uniswapBalancedTokenA.approve(address(uniswapV2Router()), amountIn);

        // Execute the swap
        address[] memory path = new address[](2);
        path[0] = address(uniswapBalancedTokenA);
        path[1] = address(uniswapBalancedTokenB);

        uint256 tokenBBeforeSwap = uniswapBalancedTokenB.balanceOf(address(this));
        uniswapV2Router()
            .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                saleAmt, 0, path, address(this), block.timestamp + 300
            );
        uint256 tokenBReceived = uniswapBalancedTokenB.balanceOf(address(this)) - tokenBBeforeSwap;

        // Calculate expected LP tokens using _depositQuote
        uint256 remainingTokenA = amountIn - saleAmt;
        uint256 expectedLPTokens = ConstProdUtils._depositQuote(
            remainingTokenA,
            tokenBReceived,
            uniswapBalancedPair.totalSupply(),
            reserveA + saleAmt, // New reserveA after swap
            reserveB - tokenBReceived // New reserveB after swap
        );

        // Execute the deposit
        uniswapBalancedTokenA.approve(address(uniswapV2Router()), remainingTokenA);
        uniswapBalancedTokenB.approve(address(uniswapV2Router()), tokenBReceived);

        _runUniswapAddLiquidityAndAssert(reserveA, reserveB, saleAmt, remainingTokenA, tokenBReceived);
    }
}
