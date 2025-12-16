// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";
import {TestBase_ConstProdUtils_Uniswap} from "./TestBase_ConstProdUtils_Uniswap.sol";
import {IUniswapV2Pair} from "contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Pair.sol";
import {IUniswapV2Router} from "contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Router.sol";
import {ERC20PermitMintableStub} from "contracts/tokens/ERC20/ERC20PermitMintableStub.sol";

contract ConstProdUtils_quoteSwapDepositWithFee_Uniswap is TestBase_ConstProdUtils_Uniswap {
    using ConstProdUtils for uint256;

    uint256 constant TEST_AMOUNT_IN = 1000000; // 1M wei input amount
    uint256 constant UNISWAP_FEE_PERCENT = 300; // 0.3% fee
    uint256 constant UNISWAP_OWNER_FEE_SHARE = 16666; // 1/6 for Uniswap V2

    function setUp() public override {
        super.setUp();
    }

    // simple trading activity generator for Uniswap pairs to accrue fees
    function _generateTradingActivity(
        IUniswapV2Pair pair,
        ERC20PermitMintableStub tokenA,
        ERC20PermitMintableStub tokenB,
        uint256 swapPercentage // basis points of reserves (e.g., 100 = 1%)
    ) internal {
        (uint112 reserveA, uint112 reserveB,) = pair.getReserves();

        uint256 swapAmountA = (uint256(reserveA) * swapPercentage) / 10000;
        uint256 swapAmountB = (uint256(reserveB) * swapPercentage) / 10000;

        tokenA.mint(address(this), swapAmountA);
        tokenB.mint(address(this), swapAmountB);

        tokenA.approve(address(uniswapV2Router), swapAmountA);
        address[] memory pathAB = new address[](2);
        pathAB[0] = address(tokenA);
        pathAB[1] = address(tokenB);

        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            swapAmountA,
            1,
            pathAB,
            address(this),
            block.timestamp
        );

        uint256 receivedB = tokenB.balanceOf(address(this));
        tokenB.approve(address(uniswapV2Router), receivedB);
        address[] memory pathBA = new address[](2);
        pathBA[0] = address(tokenB);
        pathBA[1] = address(tokenA);

        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            receivedB,
            1,
            pathBA,
            address(this),
            block.timestamp
        );
    }

    function _setupUniswapFees(bool enable) internal {
        if (enable) {
            vm.prank(uniswapV2FeeToSetter);
            uniswapV2Factory.setFeeTo(uniswapV2FeeToSetter);
        } else {
            vm.prank(uniswapV2FeeToSetter);
            uniswapV2Factory.setFeeTo(address(0));
        }
    }

    function _executeZapInAndValidate(
        IUniswapV2Pair pair,
        ERC20PermitMintableStub tokenA,
        ERC20PermitMintableStub tokenB,
        uint256 amountIn,
        uint256 reserveA,
        uint256 reserveB
    ) internal returns (uint256 actualLpAmt) {
        uint256 lpBalanceBefore = pair.balanceOf(address(this));

        tokenA.mint(address(this), amountIn);
        tokenA.approve(address(uniswapV2Router), amountIn);

        uint256 swapAmount = ConstProdUtils._swapDepositSaleAmt(amountIn, reserveA, UNISWAP_FEE_PERCENT);

        if (swapAmount > 0) {
            address[] memory path = new address[](2);
            path[0] = address(tokenA);
            path[1] = address(tokenB);

            IUniswapV2Router(address(uniswapV2Router)).swapExactTokensForTokens(
                swapAmount,
                1,
                path,
                address(this),
                block.timestamp
            );
        }

        uint256 opTokenAmtIn = swapAmount._saleQuote(reserveA, reserveB, UNISWAP_FEE_PERCENT);
        uint256 remainingAmountA = amountIn - swapAmount;

        tokenA.approve(address(uniswapV2Router), remainingAmountA);
        tokenB.approve(address(uniswapV2Router), opTokenAmtIn);

        IUniswapV2Router(address(uniswapV2Router)).addLiquidity(
            address(tokenA),
            address(tokenB),
            remainingAmountA,
            opTokenAmtIn,
            1,
            1,
            address(this),
            block.timestamp
        );

        uint256 lpBalanceAfter = pair.balanceOf(address(this));
        actualLpAmt = lpBalanceAfter - lpBalanceBefore;
    }

    function _testSwapDepositWithFeeUniswap(
        IUniswapV2Pair pair,
        ERC20PermitMintableStub tokenA,
        ERC20PermitMintableStub tokenB,
        bool feesEnabled
    ) internal {
        // setup protocol fee flag
        _setupUniswapFees(feesEnabled);

        (uint112 r0, uint112 r1,) = pair.getReserves();
        uint256 totalSupply = pair.totalSupply();
        uint256 kLast = pair.kLast();

        if (feesEnabled) {
            _generateTradingActivity(pair, tokenA, tokenB, 100);
            (r0, r1,) = pair.getReserves();
            totalSupply = pair.totalSupply();
            kLast = pair.kLast();
        }

        (uint256 reserveA,, uint256 reserveB,) = ConstProdUtils._sortReserves(
            address(tokenA),
            pair.token0(),
            uint256(r0),
            UNISWAP_FEE_PERCENT,
            uint256(r1),
            UNISWAP_FEE_PERCENT
        );

        uint256 quotedLpAmt = ConstProdUtils._quoteSwapDepositWithFee(
            TEST_AMOUNT_IN,
            totalSupply,
            reserveA,
            reserveB,
            UNISWAP_FEE_PERCENT,
            kLast,
            UNISWAP_OWNER_FEE_SHARE,
            feesEnabled
        );

        uint256 actualLpAmt = _executeZapInAndValidate(pair, tokenA, tokenB, TEST_AMOUNT_IN, reserveA, reserveB);

        // Project prefers exact equality where possible; allow small tolerance for Uniswap rounding
        assertTrue(quotedLpAmt > 0, "quoted > 0");
        assertTrue(actualLpAmt > 0, "actual > 0");
        assertGe(quotedLpAmt, actualLpAmt, "quote >= actual");
        assertLe(quotedLpAmt - actualLpAmt, 10, "quote within 10 wei of actual");
    }

    // Tests
    function test_quoteSwapDepositWithFee_Uniswap_balancedPool_swapsTokenA_feesDisabled() public {
        _initializeUniswapBalancedPools();
        _testSwapDepositWithFeeUniswap(uniswapBalancedPair, uniswapBalancedTokenA, uniswapBalancedTokenB, false);
    }

    function test_quoteSwapDepositWithFee_Uniswap_balancedPool_swapsTokenB_feesDisabled() public {
        _initializeUniswapBalancedPools();
        _testSwapDepositWithFeeUniswap(uniswapBalancedPair, uniswapBalancedTokenB, uniswapBalancedTokenA, false);
    }

    function test_quoteSwapDepositWithFee_Uniswap_unbalancedPool_swapsTokenA_feesDisabled() public {
        _initializeUniswapUnbalancedPools();
        _testSwapDepositWithFeeUniswap(uniswapUnbalancedPair, uniswapUnbalancedTokenA, uniswapUnbalancedTokenB, false);
    }

    function test_quoteSwapDepositWithFee_Uniswap_unbalancedPool_swapsTokenB_feesDisabled() public {
        _initializeUniswapUnbalancedPools();
        _testSwapDepositWithFeeUniswap(uniswapUnbalancedPair, uniswapUnbalancedTokenB, uniswapUnbalancedTokenA, false);
    }

    function test_quoteSwapDepositWithFee_Uniswap_extremeUnbalancedPool_swapsTokenA_feesDisabled() public {
        _initializeUniswapExtremeUnbalancedPools();
        _testSwapDepositWithFeeUniswap(uniswapExtremeUnbalancedPair, uniswapExtremeTokenA, uniswapExtremeTokenB, false);
    }

    function test_quoteSwapDepositWithFee_Uniswap_extremeUnbalancedPool_swapsTokenB_feesDisabled() public {
        _initializeUniswapExtremeUnbalancedPools();
        _testSwapDepositWithFeeUniswap(uniswapExtremeUnbalancedPair, uniswapExtremeTokenB, uniswapExtremeTokenA, false);
    }

    // Fees enabled variants
    function test_quoteSwapDepositWithFee_Uniswap_balancedPool_swapsTokenA_feesEnabled() public {
        _initializeUniswapBalancedPools();
        _testSwapDepositWithFeeUniswap(uniswapBalancedPair, uniswapBalancedTokenA, uniswapBalancedTokenB, true);
    }

    function test_quoteSwapDepositWithFee_Uniswap_balancedPool_swapsTokenB_feesEnabled() public {
        _initializeUniswapBalancedPools();
        _testSwapDepositWithFeeUniswap(uniswapBalancedPair, uniswapBalancedTokenB, uniswapBalancedTokenA, true);
    }

    function test_quoteSwapDepositWithFee_Uniswap_unbalancedPool_swapsTokenA_feesEnabled() public {
        _initializeUniswapUnbalancedPools();
        _testSwapDepositWithFeeUniswap(uniswapUnbalancedPair, uniswapUnbalancedTokenA, uniswapUnbalancedTokenB, true);
    }

    function test_quoteSwapDepositWithFee_Uniswap_unbalancedPool_swapsTokenB_feesEnabled() public {
        _initializeUniswapUnbalancedPools();
        _testSwapDepositWithFeeUniswap(uniswapUnbalancedPair, uniswapUnbalancedTokenB, uniswapUnbalancedTokenA, true);
    }

    function test_quoteSwapDepositWithFee_Uniswap_extremeUnbalancedPool_swapsTokenA_feesEnabled() public {
        _initializeUniswapExtremeUnbalancedPools();
        _testSwapDepositWithFeeUniswap(uniswapExtremeUnbalancedPair, uniswapExtremeTokenA, uniswapExtremeTokenB, true);
    }

    function test_quoteSwapDepositWithFee_Uniswap_extremeUnbalancedPool_swapsTokenB_feesEnabled() public {
        _initializeUniswapExtremeUnbalancedPools();
        _testSwapDepositWithFeeUniswap(uniswapExtremeUnbalancedPair, uniswapExtremeTokenB, uniswapExtremeTokenA, true);
    }
}
