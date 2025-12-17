// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";
import {TestBase_ConstProdUtils_Camelot} from "./TestBase_ConstProdUtils_Camelot.sol";
import {FEE_DENOMINATOR} from "contracts/constants/Constants.sol";
import "forge-std/console.sol";

contract ConstProdUtils_swapDepositSaleAmt_Camelot is TestBase_ConstProdUtils_Camelot {
    using ConstProdUtils for uint256;

    function setUp() public override {
        super.setUp();
    }


    function test_swapDepositSaleAmt_Camelot_balancedPool() public {
        _initializeCamelotBalancedPools();
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

        // Mint tokens and execute the swap
        uint256 tokenBReceived;
        {
            camelotBalancedTokenA.mint(address(this), amountIn);
            camelotBalancedTokenA.approve(address(camelotV2Router), amountIn);
            address[] memory path = new address[](2);
            path[0] = address(camelotBalancedTokenA);
            path[1] = address(camelotBalancedTokenB);
            console.log("Camelot balanced swap path0", uint256(uint160(path[0])));
            console.log("Camelot balanced swap path1", uint256(uint160(path[1])));
            console.log("Camelot balanced factory pair", uint256(uint160(address(camelotV2Factory.getPair(path[0], path[1])))));
            uint256 tokenBBeforeSwap = camelotBalancedTokenB.balanceOf(address(this));
            camelotV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
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
        _initializeCamelotUnbalancedPools();
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
            camelotUnbalancedTokenA.approve(address(camelotV2Router), amountIn);
            address[] memory path = new address[](2);
            path[0] = address(camelotUnbalancedTokenA);
            path[1] = address(camelotUnbalancedTokenB);
            uint256 tokenBBeforeSwap = camelotUnbalancedTokenB.balanceOf(address(this));
            camelotV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
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
        _initializeCamelotExtremeUnbalancedPools();
        uint256 reserveA;
        uint256 reserveB;
        uint256 feePercent;
        {
            (uint112 r0, uint112 r1, uint16 f0, uint16 f1) = camelotExtremeUnbalancedPair.getReserves();
            (reserveA, feePercent, reserveB,) = ConstProdUtils._sortReserves(
                address(camelotExtremeTokenA), camelotExtremeUnbalancedPair.token0(), r0, uint256(f0), r1, uint256(f1)
            );
        }
        uint256 amountIn = 10e18; // Very small input for extreme unbalanced pool

        // Calculate sale amount using ConstProdUtils (use small-denom parity when fee is small)
        uint256 denom = feePercent <= 10 ? 1000 : FEE_DENOMINATOR;
        uint256 saleAmt = ConstProdUtils._swapDepositSaleAmt(amountIn, reserveA, feePercent, denom);

        uint256 tokenBReceived;
        {
            camelotExtremeTokenA.mint(address(this), amountIn);
            camelotExtremeTokenA.approve(address(camelotV2Router), amountIn);
            address[] memory path = new address[](2);
            path[0] = address(camelotExtremeTokenA);
            path[1] = address(camelotExtremeTokenB);
            console.log("Camelot extreme swap path0", uint256(uint160(path[0])));
            console.log("Camelot extreme swap path1", uint256(uint160(path[1])));
            console.log("Camelot extreme factory pair", uint256(uint160(address(camelotV2Factory.getPair(path[0], path[1])))));
            uint256 tokenBBeforeSwap = camelotExtremeTokenB.balanceOf(address(this));
            camelotV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                saleAmt, 0, path, address(this), address(0), block.timestamp + 300
            );
            tokenBReceived = camelotExtremeTokenB.balanceOf(address(this)) - tokenBBeforeSwap;
        }

        // Calculate expected LP tokens using _depositQuote
        uint256 remainingTokenA = amountIn - saleAmt;
        uint256 expectedLPTokens;
        {
            (uint112 ur0, uint112 ur1,,) = camelotExtremeUnbalancedPair.getReserves();
            uint256 updatedReserveA =
                (address(camelotExtremeTokenA) == camelotExtremeUnbalancedPair.token0()) ? uint256(ur0) : uint256(ur1);
            uint256 updatedReserveB =
                (address(camelotExtremeTokenA) == camelotExtremeUnbalancedPair.token0()) ? uint256(ur1) : uint256(ur0);
            expectedLPTokens = ConstProdUtils._quoteDepositWithFee(
                remainingTokenA,
                tokenBReceived,
                camelotExtremeUnbalancedPair.totalSupply(),
                updatedReserveA,
                updatedReserveB,
                camelotExtremeUnbalancedPair.kLast(),
                camelotV2Factory.ownerFeeShare(),
                true
            );
        }

        // Execute the deposit by direct mint to avoid router rounding
        camelotExtremeTokenA.transfer(address(camelotExtremeUnbalancedPair), remainingTokenA);
        camelotExtremeTokenB.transfer(address(camelotExtremeUnbalancedPair), tokenBReceived);
        uint256 actualLPTokens = camelotExtremeUnbalancedPair.mint(address(this));

        // Validate exact equality
        assertEq(actualLPTokens, expectedLPTokens, "Actual LP tokens should equal expected LP tokens exactly");
    }

}
