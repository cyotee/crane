// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";
import "forge-std/console.sol";
import {TestBase_ConstProdUtils_Aerodrome} from "test/foundry/spec/utils/math/constProdUtils/TestBase_ConstProdUtils_Aerodrome.sol";
import {ERC20PermitMintableStub} from "contracts/tokens/ERC20/ERC20PermitMintableStub.sol";
import {Pool} from "contracts/protocols/dexes/aerodrome/v1/stubs/Pool.sol";
import {IRouter} from "contracts/protocols/dexes/aerodrome/v1/interfaces/IRouter.sol";
import {AerodromeUtils} from "contracts/utils/math/AerodromeUtils.sol";
import {Uint512, BetterMath as Math} from "@crane/contracts/utils/math/BetterMath.sol";

contract ConstProdUtils_quoteSwapDepositWithFee_Aerodrome is TestBase_ConstProdUtils_Aerodrome {
    using ConstProdUtils for uint256;

    uint256 constant TEST_AMOUNT_IN = 1000000; // 1M wei input amount
    uint256 constant AERO_FEE_DENOM = 10000;

    function setUp() public override {
        TestBase_ConstProdUtils_Aerodrome.setUp();
    }

    function _executeAerodromeZapInAndValidate(
        Pool pair,
        ERC20PermitMintableStub tokenA,
        ERC20PermitMintableStub tokenB,
        uint256 amountIn,
        uint256 reserveA,
        uint256 reserveB
    ) internal returns (uint256 actualLpAmt) {
        uint256 lpBalanceBefore = pair.balanceOf(address(this));

        tokenA.mint(address(this), amountIn);
        tokenA.approve(address(aerodromeRouter), amountIn);

        uint256 inputTokenFee = aerodromePoolFactory.getFee(address(pair), false);
        uint256 swapAmount = ConstProdUtils._swapDepositSaleAmt(amountIn, reserveA, inputTokenFee, AERO_FEE_DENOM);

        // Diagnostic logs to help track tiny integer mismatches
        console.log("[DIAG] amountIn", amountIn);
        console.log("[DIAG] reserveA", reserveA);
        console.log("[DIAG] reserveB", reserveB);
        console.log("[DIAG] inputTokenFee", inputTokenFee);
        console.log("[DIAG] computed swapAmount", swapAmount);

        if (swapAmount > 0) {
            // Approve and swap via aerodromeRouter
            tokenA.approve(address(aerodromeRouter), swapAmount);
            IRouter.Route[] memory routes = new IRouter.Route[](1);
            routes[0] = IRouter.Route({from: address(tokenA), to: address(tokenB), stable: false, factory: address(aerodromePoolFactory)});

            aerodromeRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                swapAmount,
                1,
                routes,
                address(this),
                block.timestamp
            );
        }

        uint256 opTokenAmtIn = tokenB.balanceOf(address(this));
        console.log("[DIAG] opTokenAmtIn (post-swap)", opTokenAmtIn);
        uint256 remainingAmountA = amountIn - swapAmount;
        console.log("[DIAG] remainingAmountA", remainingAmountA);

        tokenA.approve(address(aerodromeRouter), remainingAmountA);
        tokenB.approve(address(aerodromeRouter), opTokenAmtIn);

        ( , , uint256 liquidity) = aerodromeRouter.addLiquidity(address(tokenA), address(tokenB), false, remainingAmountA, opTokenAmtIn, 1, 1, address(this), block.timestamp);

        uint256 lpBalanceAfter = pair.balanceOf(address(this));
        actualLpAmt = lpBalanceAfter - lpBalanceBefore;
        // liquidity returned by aerodromeRouter should equal actualLpAmt
        console.log("[DIAG] aerodromeRouter returned liquidity", liquidity);
        console.log("[DIAG] actualLpAmt", actualLpAmt);
        console.log("[DIAG] pair.totalSupply", pair.totalSupply());
        (uint256 r0After, uint256 r1After, ) = pair.getReserves();
        console.log("[DIAG] reserves post-mint", r0After, r1After);
        return actualLpAmt;
    }

    function _testSwapDepositWithFeeAerodrome(
        Pool pair,
        ERC20PermitMintableStub tokenA,
        ERC20PermitMintableStub tokenB
    ) internal {
        (uint256 r0, uint256 r1,) = pair.getReserves();
        uint256 totalSupply = pair.totalSupply();

        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
            address(tokenA),
            pair.token0(),
            r0,
            r1
        );

        uint256 inputTokenFee = aerodromePoolFactory.getFee(address(pair), false);

        // Compute expected LP locally using integer intermediates that mirror on-chain mint math
        uint256 quotedLpAmt = AerodromeUtils._quoteSwapDepositWithFee(TEST_AMOUNT_IN, totalSupply, reserveA, reserveB, inputTokenFee);

        uint256 actualLpAmt = _executeAerodromeZapInAndValidate(pair, tokenA, tokenB, TEST_AMOUNT_IN, reserveA, reserveB);

        assertTrue(quotedLpAmt > 0, "quoted > 0");
        assertTrue(actualLpAmt > 0, "actual > 0");
        if (quotedLpAmt != actualLpAmt) {
            console.log("[DIAG] quotedLpAmt", quotedLpAmt);
            console.log("[DIAG] actualLpAmt", actualLpAmt);
            console.log("[DIAG] totalSupply", totalSupply);
            console.log("[DIAG] reserveA", reserveA);
            console.log("[DIAG] reserveB", reserveB);
            _computeQuoteIntermediates(TEST_AMOUNT_IN, totalSupply, reserveA, reserveB, inputTokenFee);
        }
        assertEq(quotedLpAmt, actualLpAmt, "Aerodrome quote should exactly match actual LP amount");
    }

    // function _quoteSwapDepositLocal(
    //     uint256 amountIn,
    //     uint256 lpTotalSupply,
    //     uint256 reserveIn,
    //     uint256 reserveOut,
    //     uint256 feePercent
    // ) internal view returns (uint256 lpAmtLocal) {
    //     uint256 feeDenom = (feePercent <= 10) ? 1000 : AERO_FEE_DENOM;
    //     uint256 amtInSaleAmt = ConstProdUtils._swapDepositSaleAmt(amountIn, reserveIn, feePercent, feeDenom);
    //     uint256 amountInWithFee = amtInSaleAmt - ((amtInSaleAmt * feePercent) / feeDenom);
    //     uint256 opTokenAmtIn = (amountInWithFee * reserveOut) / (reserveIn + amountInWithFee);

    //     uint256 remaining = amountIn - amtInSaleAmt;
    //     uint256 newReserveIn = reserveIn + amtInSaleAmt;
    //     uint256 newReserveOut = reserveOut - opTokenAmtIn;

    //     uint256 amountBOptimal = (remaining * newReserveOut) / newReserveIn;
    //     uint256 amountA;
    //     uint256 amountB;
    //     if (amountBOptimal <= opTokenAmtIn) {
    //         amountA = remaining;
    //         amountB = amountBOptimal;
    //     } else {
    //         uint256 amountAOptimal = (opTokenAmtIn * newReserveIn) / newReserveOut;
    //         amountA = amountAOptimal;
    //         amountB = opTokenAmtIn;
    //     }

    //     if (lpTotalSupply == 0) {
    //         uint256 product = amountA * amountB;
    //         uint256 sqrtProduct = Math._sqrt(product);
    //         lpAmtLocal = sqrtProduct - 10 ** 3;
    //     } else {
    //         uint256 amountA_ratio = (amountA * lpTotalSupply) / newReserveIn;
    //         uint256 amountB_ratio = (amountB * lpTotalSupply) / newReserveOut;
    //         lpAmtLocal = amountA_ratio < amountB_ratio ? amountA_ratio : amountB_ratio;
    //     }
    // }

    function _computeQuoteIntermediates(
        uint256 amountIn,
        uint256 lpTotalSupply,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 feePercent
    ) internal view {
        uint256 feeDenom = (feePercent <= 10) ? 1000 : AERO_FEE_DENOM;
        uint256 amtInSaleAmt = ConstProdUtils._swapDepositSaleAmt(amountIn, reserveIn, feePercent, feeDenom);
        uint256 amountInWithFee = amtInSaleAmt - ((amtInSaleAmt * feePercent) / feeDenom);
        uint256 opTokenAmtIn = (amountInWithFee * reserveOut) / (reserveIn + amountInWithFee);

        uint256 remaining = amountIn - amtInSaleAmt;
        uint256 newReserveIn = reserveIn + amtInSaleAmt;
        uint256 newReserveOut = reserveOut - opTokenAmtIn;

        uint256 amountBOptimal = (remaining * newReserveOut) / newReserveIn;
        uint256 amountA;
        uint256 amountB;
        if (amountBOptimal <= opTokenAmtIn) {
            amountA = remaining;
            amountB = amountBOptimal;
        } else {
            uint256 amountAOptimal = (opTokenAmtIn * newReserveIn) / newReserveOut;
            amountA = amountAOptimal;
            amountB = opTokenAmtIn;
        }

        uint256 lpAmtLocal;
        if (lpTotalSupply == 0) {
            uint256 product = amountA * amountB;
            uint256 sqrtProduct = Math._sqrt(product);
            lpAmtLocal = sqrtProduct - 10 ** 3;
        } else {
            uint256 amountA_ratio = (amountA * lpTotalSupply) / newReserveIn;
            uint256 amountB_ratio = (amountB * lpTotalSupply) / newReserveOut;
            lpAmtLocal = amountA_ratio < amountB_ratio ? amountA_ratio : amountB_ratio;
        }

        console.log("[DIAG-INT] amtInSaleAmt", amtInSaleAmt);
        console.log("[DIAG-INT] amountInWithFee (scaled)", amountInWithFee);
        console.log("[DIAG-INT] opTokenAmtIn (computed)", opTokenAmtIn);
        console.log("[DIAG-INT] remaining", remaining);
        console.log("[DIAG-INT] newReserveIn", newReserveIn);
        console.log("[DIAG-INT] newReserveOut", newReserveOut);
        console.log("[DIAG-INT] amountBOptimal", amountBOptimal);
        console.log("[DIAG-INT] amountA_selected", amountA);
        console.log("[DIAG-INT] amountB_selected", amountB);
        console.log("[DIAG-INT] lpAmtLocal", lpAmtLocal);
    }

    // Tests - swap tokenA -> tokenB
    function test_quoteSwapDepositWithFee_Aerodrome_balancedPool_swapsTokenA() public {
        _initializeAerodromeBalancedPools();
        _testSwapDepositWithFeeAerodrome(aeroBalancedPool, aeroBalancedTokenA, aeroBalancedTokenB);
    }

    function test_quoteSwapDepositWithFee_Aerodrome_unbalancedPool_swapsTokenA() public {
        _initializeAerodromeUnbalancedPools();
        _testSwapDepositWithFeeAerodrome(aeroUnbalancedPool, aeroUnbalancedTokenA, aeroUnbalancedTokenB);
    }

    function test_quoteSwapDepositWithFee_Aerodrome_extremeUnbalancedPool_swapsTokenA() public {
        _initializeAerodromeExtremeUnbalancedPools();
        _testSwapDepositWithFeeAerodrome(aeroExtremeUnbalancedPool, aeroExtremeTokenA, aeroExtremeTokenB);
    }

    // Tests - swap tokenB -> tokenA
    function test_quoteSwapDepositWithFee_Aerodrome_balancedPool_swapsTokenB() public {
        _initializeAerodromeBalancedPools();
        _testSwapDepositWithFeeAerodrome(aeroBalancedPool, aeroBalancedTokenB, aeroBalancedTokenA);
    }

    function test_quoteSwapDepositWithFee_Aerodrome_unbalancedPool_swapsTokenB() public {
        _initializeAerodromeUnbalancedPools();
        _testSwapDepositWithFeeAerodrome(aeroUnbalancedPool, aeroUnbalancedTokenB, aeroUnbalancedTokenA);
    }

    function test_quoteSwapDepositWithFee_Aerodrome_extremeUnbalancedPool_swapsTokenB() public {
        _initializeAerodromeExtremeUnbalancedPools();
        _testSwapDepositWithFeeAerodrome(aeroExtremeUnbalancedPool, aeroExtremeTokenB, aeroExtremeTokenA);
    }
}
