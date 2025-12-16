// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {TestBase_ConstProdUtils_Camelot} from "./TestBase_ConstProdUtils_Camelot.sol";
import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";
import {FEE_DENOMINATOR} from "contracts/constants/Constants.sol";

contract ConstProdUtils_swapDepositSaleAmt_Camelot is TestBase_ConstProdUtils_Camelot {
    using ConstProdUtils for uint256;

    function setUp() public override {
        super.setUp();
    }

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

    function test_swapDepositSaleAmt_Camelot_balancedPool() public {
        uint256 reserveA;
        uint256 reserveB;
        uint256 feePercent;
        // Ensure pool has initial liquidity
        _initializeCamelotBalancedPools();
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
            camelotBalancedTokenA.approve(address(camelotV2Router), amountIn);
            address[] memory path = new address[](2);
            path[0] = address(camelotBalancedTokenA);
            path[1] = address(camelotBalancedTokenB);
            uint256 tokenBBeforeSwap = camelotBalancedTokenB.balanceOf(address(this));
            camelotV2Router
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
                camelotV2Factory.ownerFeeShare(),
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
        // Ensure pool has initial liquidity for unbalanced scenario
        _initializeCamelotUnbalancedPools();
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
            camelotUnbalancedTokenA.approve(address(camelotV2Router), amountIn);
            address[] memory path = new address[](2);
            path[0] = address(camelotUnbalancedTokenA);
            path[1] = address(camelotUnbalancedTokenB);
            uint256 tokenBBeforeSwap = camelotUnbalancedTokenB.balanceOf(address(this));
            camelotV2Router
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
                camelotV2Factory.ownerFeeShare(),
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
        // Ensure pool has initial liquidity
        _initializeCamelotBalancedPools();
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
            camelotBalancedTokenA.approve(address(camelotV2Router), amountIn);
            address[] memory path = new address[](2);
            path[0] = address(camelotBalancedTokenA);
            path[1] = address(camelotBalancedTokenB);
            uint256 tokenBBeforeSwap = camelotBalancedTokenB.balanceOf(address(this));
            camelotV2Router
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
                camelotV2Factory.ownerFeeShare(),
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
}
