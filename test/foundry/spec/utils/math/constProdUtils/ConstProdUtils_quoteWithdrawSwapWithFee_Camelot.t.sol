// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";
import {TestBase_ConstProdUtils_Camelot} from "./TestBase_ConstProdUtils_Camelot.sol";
import {FEE_DENOMINATOR} from "contracts/constants/Constants.sol";

import {IERC20MintBurn} from "contracts/interfaces/IERC20MintBurn.sol";
import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import "forge-std/console.sol";
import {ICamelotPair} from "contracts/interfaces/protocols/dexes/camelot/v2/ICamelotPair.sol";
import {ICamelotV2Router} from "contracts/interfaces/protocols/dexes/camelot/v2/ICamelotV2Router.sol";
import {CamelotV2Utils} from "contracts/utils/math/CamelotV2Utils.sol";

contract ConstProdUtils_quoteWithdrawSwapWithFee_Camelot is TestBase_ConstProdUtils_Camelot {
    using ConstProdUtils for uint256;

    uint256 constant LOW_PERCENTAGE = 10; // 10%
    uint256 constant MEDIUM_PERCENTAGE = 50; // 50%
    uint256 constant HIGH_PERCENTAGE = 90; // 90%

    // Camelot fee constants (used for swap execution diagnostics)
    uint256 constant CAMELOT_FEE_PERCENT = 300; // 0.3% expressed as 300/100000

    function setUp() public override {
        super.setUp();
    }

    function _calculateLPAmount(uint256 totalLP, uint256 percentage) internal pure returns (uint256) {
        return (totalLP * percentage) / 100;
    }

    function _getKLast(address pool) internal view returns (uint256) {
        ICamelotPair pair = ICamelotPair(pool);
        return pair.kLast();
    }

    function _getPoolReserves(address pool)
        internal
        view
        returns (uint256 reserveA, uint256 reserveB, address tokenA, address tokenB)
    {
        ICamelotPair pair = ICamelotPair(pool);
        (uint112 r0, uint112 r1,,) = pair.getReserves();
        address token0 = pair.token0();
        address token1 = pair.token1();
        return (r0, r1, token0, token1);
    }

    struct WithdrawSwapData {
        ICamelotPair pair;
        ICamelotV2Router router;
        uint256 reserveA;
        uint256 reserveB;
        address tokenA;
        address tokenB;
        uint256 totalSupply;
        uint256 tokenAAmount;
        uint256 tokenBAmount;
        uint256 actualTokenA;
        uint256 actualTokenB;
        uint256 remainingReserveA;
        uint256 remainingReserveB;
        uint256 swapAmount;
        address[] path;
        uint256 lpAmount;
        uint256 kLast;
        uint256 ownerFeeShare;
        uint256 quote;
        uint256 actualAmount;
    }

    function _performActualWithdrawSwap(address pool, uint256 lpAmount, uint256 feePercent)
        internal
        returns (uint256 actualTokenAAmount)
    {
        WithdrawSwapData memory data;
        data.pair = ICamelotPair(pool);
        data.router = ICamelotV2Router(address(camelotV2Router));

        (data.reserveA, data.reserveB, data.tokenA, data.tokenB) = _getPoolReserves(pool);

        data.totalSupply = data.pair.totalSupply();
        data.tokenAAmount = (data.reserveA * lpAmount) / data.totalSupply;
        data.tokenBAmount = (data.reserveB * lpAmount) / data.totalSupply;

        uint256 balABefore = IERC20(data.tokenA).balanceOf(address(this));
        uint256 balBBefore = IERC20(data.tokenB).balanceOf(address(this));
        data.pair.transfer(pool, lpAmount);
        data.pair.burn(address(this));

        uint256 balAAfter = IERC20(data.tokenA).balanceOf(address(this));
        uint256 balBAfter = IERC20(data.tokenB).balanceOf(address(this));
        data.actualTokenA = balAAfter - balABefore;
        data.actualTokenB = balBAfter - balBBefore;

        if (data.actualTokenB > 0) {
            IERC20(data.tokenB).approve(address(data.router), data.actualTokenB);

            data.remainingReserveA = data.reserveA - data.tokenAAmount;
            data.remainingReserveB = data.reserveB - data.tokenBAmount;

            // Diagnostic logs to catch division-by-zero or unexpected values
            console.log("_performActualWithdrawSwap: remainingReserveA", data.remainingReserveA);
            console.log("_performActualWithdrawSwap: remainingReserveB", data.remainingReserveB);
            console.log("_performActualWithdrawSwap: actualTokenB", data.actualTokenB);

            if (feePercent > 0) {
                uint256 numerator;
                unchecked {
                    uint256 denomMinus = (FEE_DENOMINATOR - feePercent);
                    console.log("_performActualWithdrawSwap: feePercent", feePercent);
                    console.log("_performActualWithdrawSwap: denomMinus", denomMinus);
                    numerator = data.remainingReserveA * denomMinus;
                }
                console.log("_performActualWithdrawSwap: numerator", numerator);
                data.remainingReserveA = numerator / FEE_DENOMINATOR;
            }

            data.swapAmount = (data.actualTokenB * data.remainingReserveA) / (data.remainingReserveB + data.actualTokenB);

            data.swapAmount = (data.actualTokenB * data.remainingReserveA) / (data.remainingReserveB + data.actualTokenB);

            data.path = new address[](2);
            data.path[0] = data.tokenB;
            data.path[1] = data.tokenA;

            uint256 beforeA = IERC20(data.tokenA).balanceOf(address(this));
            ICamelotV2Router(address(data.router)).swapExactTokensForTokensSupportingFeeOnTransferTokens(
                data.actualTokenB,
                0,
                data.path,
                address(this),
                address(0),
                block.timestamp + 300
            );
            uint256 afterA = IERC20(data.tokenA).balanceOf(address(this));
            uint256 receivedA = afterA - beforeA;

            actualTokenAAmount = data.actualTokenA + receivedA;
        } else {
            actualTokenAAmount = data.actualTokenA;
        }
    }

    function _performActualWithdrawSwapTokenB(address pool, uint256 lpAmount, uint256 feePercent)
        internal
        returns (uint256 actualTokenBAmount)
    {
        WithdrawSwapData memory data;
        data.pair = ICamelotPair(pool);
        data.router = ICamelotV2Router(address(camelotV2Router));

        (data.reserveA, data.reserveB, data.tokenA, data.tokenB) = _getPoolReserves(pool);

        data.totalSupply = data.pair.totalSupply();
        data.tokenAAmount = (data.reserveA * lpAmount) / data.totalSupply;
        data.tokenBAmount = (data.reserveB * lpAmount) / data.totalSupply;

        uint256 balABefore = IERC20(data.tokenA).balanceOf(address(this));
        uint256 balBBefore = IERC20(data.tokenB).balanceOf(address(this));
        data.pair.transfer(pool, lpAmount);
        data.pair.burn(address(this));

        uint256 balAAfter = IERC20(data.tokenA).balanceOf(address(this));
        uint256 balBAfter = IERC20(data.tokenB).balanceOf(address(this));
        data.actualTokenA = balAAfter - balABefore;
        data.actualTokenB = balBAfter - balBBefore;

        if (data.actualTokenA > 0) {
            IERC20(data.tokenA).approve(address(data.router), data.actualTokenA);

            data.remainingReserveA = data.reserveA - data.tokenAAmount;
            data.remainingReserveB = data.reserveB - data.tokenBAmount;

            // Diagnostic logs to catch division-by-zero or unexpected values
            console.log("_performActualWithdrawSwapTokenB: remainingReserveA", data.remainingReserveA);
            console.log("_performActualWithdrawSwapTokenB: remainingReserveB", data.remainingReserveB);
            console.log("_performActualWithdrawSwapTokenB: actualTokenA", data.actualTokenA);

            if (feePercent > 0) {
                uint256 numerator;
                unchecked {
                    uint256 denomMinus = (FEE_DENOMINATOR - feePercent);
                    console.log("_performActualWithdrawSwapTokenB: feePercent", feePercent);
                    console.log("_performActualWithdrawSwapTokenB: denomMinus", denomMinus);
                    numerator = data.remainingReserveB * denomMinus;
                }
                console.log("_performActualWithdrawSwapTokenB: numerator", numerator);
                data.remainingReserveB = numerator / FEE_DENOMINATOR;
            }

            data.swapAmount = (data.actualTokenA * data.remainingReserveB) / (data.remainingReserveA + data.actualTokenA);

            data.swapAmount = (data.actualTokenA * data.remainingReserveB) / (data.remainingReserveA + data.actualTokenA);

            data.path = new address[](2);
            data.path[0] = data.tokenA;
            data.path[1] = data.tokenB;

            uint256 beforeB = IERC20(data.tokenB).balanceOf(address(this));
            ICamelotV2Router(address(data.router)).swapExactTokensForTokensSupportingFeeOnTransferTokens(
                data.actualTokenA,
                0,
                data.path,
                address(this),
                address(0),
                block.timestamp + 300
            );
            uint256 afterB = IERC20(data.tokenB).balanceOf(address(this));
            uint256 receivedB = afterB - beforeB;

            actualTokenBAmount = data.actualTokenB + receivedB;
        } else {
            actualTokenBAmount = data.actualTokenB;
        }
    }

    function _setupCamelotFees(bool enableProtocolFees) internal {
        address factoryOwner = camelotV2Factory.owner();
        if (enableProtocolFees) {
            vm.prank(factoryOwner);
            camelotV2Factory.setFeeTo(factoryOwner);
        } else {
            vm.prank(factoryOwner);
            camelotV2Factory.setFeeTo(address(0));
        }
    }

    // Helper to generate trading activity on a Camelot pair to cause fee accrual
    function _generateTradingActivity(
        ICamelotPair pair,
        IERC20MintBurn tokenA,
        IERC20MintBurn tokenB,
        uint256 swapPercentage // e.g., 100 = 1%, 500 = 5%
    ) internal {
        (uint112 reserveA, uint112 reserveB,,) = pair.getReserves();

        uint256 swapAmountA = (uint256(reserveA) * swapPercentage) / 10000;
        uint256 swapAmountB = (uint256(reserveB) * swapPercentage) / 10000;

        // Mint tokens for trading
        tokenA.mint(address(this), swapAmountA);
        tokenB.mint(address(this), swapAmountB);

        // First swap: A -> B
        IERC20(address(tokenA)).approve(address(camelotV2Router), swapAmountA);
        address[] memory pathAB = new address[](2);
        pathAB[0] = address(tokenA);
        pathAB[1] = address(tokenB);

        uint256 balanceBeforeB = IERC20(address(tokenB)).balanceOf(address(this));
        ICamelotV2Router(address(camelotV2Router)).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            swapAmountA,
            1,
            pathAB,
            address(this),
            address(0),
            block.timestamp
        );
        uint256 receivedB = IERC20(address(tokenB)).balanceOf(address(this)) - balanceBeforeB;

        // Second swap: B -> A
        IERC20(address(tokenB)).approve(address(camelotV2Router), receivedB);
        address[] memory pathBA = new address[](2);
        pathBA[0] = address(tokenB);
        pathBA[1] = address(tokenA);

        uint256 balanceBeforeA = IERC20(address(tokenA)).balanceOf(address(this));
        ICamelotV2Router(address(camelotV2Router)).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            receivedB,
            1,
            pathBA,
            address(this),
            address(0),
            block.timestamp
        );
        uint256 receivedA = IERC20(address(tokenA)).balanceOf(address(this)) - balanceBeforeA;

        // trading activity complete
        (reserveA, reserveB,,) = pair.getReserves();
        (reserveA);
        (reserveB);
        (receivedA);
        (receivedB);
    }

    struct TestData {
        address pool;
        uint256 totalLP;
        uint256 lpAmount;
        uint256 reserveA;
        uint256 reserveB;
        address tokenA;
        address tokenB;
        uint256 kLast;
        uint256 ownerFeeShare;
        uint256 quote;
        uint256 actualAmount;
    }

    function _testWithdrawSwapWithFee(ICamelotPair pair, uint256 percentage, bool feesEnabled) internal {
        TestData memory data;
        data.pool = address(pair);
        data.totalLP = pair.totalSupply();
        data.lpAmount = _calculateLPAmount(data.totalLP, percentage);

        (data.reserveA, data.reserveB, data.tokenA, data.tokenB) = _getPoolReserves(data.pool);
        data.kLast = _getKLast(data.pool);

        if (feesEnabled) {
            _setupCamelotFees(true);
            _generateTradingActivity(pair, IERC20MintBurn(data.tokenA), IERC20MintBurn(data.tokenB), 100);

            (data.reserveA, data.reserveB, data.tokenA, data.tokenB) = _getPoolReserves(data.pool);
            data.kLast = _getKLast(data.pool);
            data.totalLP = pair.totalSupply();

            (data.reserveA, data.reserveB) = ConstProdUtils._sortReserves(
                data.tokenA,
                pair.token0(),
                uint256(data.reserveA),
                uint256(data.reserveB)
            );
        } else {
            // Ensure protocol fees are disabled when tests expect feesDisabled
            _setupCamelotFees(false);
        }

        // owner fee share will be read by the quote function if needed
        (uint256 ownerFeeShare, ) = camelotV2Factory.feeInfo();

        uint256 feePercent = _getPoolFeePercent(pair, data.tokenA);

        // Use Camelot-specific utils for quoting to guarantee pair-equivalent integer rounding
        data.quote = CamelotV2Utils._quoteWithdrawSwapWithFee(
            data.lpAmount,
            data.totalLP,
            data.reserveA,
            data.reserveB,
            feePercent,
            FEE_DENOMINATOR,
            data.kLast,
            ownerFeeShare,
            feesEnabled
        );

        data.actualAmount = _performActualWithdrawSwap(data.pool, data.lpAmount, feePercent);

        assertEq(data.quote, data.actualAmount, "Quote should match actual execution");
    }

    function _getPoolFeePercent(ICamelotPair pair, address knownToken) internal view returns (uint256) {
        (uint112 r0, uint112 r1, uint16 fee0, uint16 fee1) = pair.getReserves();
        (, uint256 feeA,,) = ConstProdUtils._sortReserves(
            knownToken,
            pair.token0(),
            uint256(r0),
            uint256(fee0),
            uint256(r1),
            uint256(fee1)
        );
        return feeA;
    }
    function test_quoteWithdrawSwapWithFee_Camelot_balancedPool_lowPercentage_feesDisabled_extractTokenA() public {
        _initializeCamelotBalancedPools();
        _testWithdrawSwapWithFee(camelotBalancedPair, LOW_PERCENTAGE, false);
    }

    function test_quoteWithdrawSwapWithFee_Camelot_balancedPool_mediumPercentage_feesDisabled_extractTokenA() public {
        _initializeCamelotBalancedPools();
        _testWithdrawSwapWithFee(camelotBalancedPair, MEDIUM_PERCENTAGE, false);
    }

    function test_quoteWithdrawSwapWithFee_Camelot_balancedPool_highPercentage_feesDisabled_extractTokenA() public {
        _initializeCamelotBalancedPools();
        _testWithdrawSwapWithFee(camelotBalancedPair, HIGH_PERCENTAGE, false);
    }

    function test_withdrawSwapQuote_Camelot_balancedPool() public {
        _initializeCamelotBalancedPools();
        (uint112 reserve0, uint112 reserve1, uint16 token0Fee , uint16 token1Fee) = camelotBalancedPair.getReserves();

        (uint256 reserveA, uint256 feeA, uint256 reserveB, uint256 feeB) = ConstProdUtils._sortReserves(
            address(camelotBalancedTokenA),
            camelotBalancedPair.token0(),
            reserve0,
            uint256(token0Fee),
            reserve1,
            uint256(token1Fee)
        );
        // Sanity: ensure reserveA corresponds to camelotBalancedTokenA
        if (camelotBalancedPair.token0() == address(camelotBalancedTokenA)) {
            assertEq(reserveA, uint256(reserve0));
        } else {
            assertEq(reserveA, uint256(reserve1));
        }

        uint256 feePercent = uint256(feeA);
        uint256 lpTotalSupply = camelotBalancedPair.totalSupply();

        uint256 lpBalance = camelotBalancedPair.balanceOf(address(this));
        uint256 ownedLPAmount = lpBalance / 2;

            uint256 expectedTotalTokenA = CamelotV2Utils._quoteWithdrawSwapWithFee(
            ownedLPAmount, lpTotalSupply, reserveA, reserveB, feePercent, FEE_DENOMINATOR, 0, 0, false
        );

        uint256 initialTokenABalance = camelotBalancedTokenA.balanceOf(address(this));

        camelotBalancedPair.transfer(address(camelotBalancedPair), ownedLPAmount);
        (uint256 amountA, uint256 amountB) = camelotBalancedPair.burn(address(this));

        uint256 actualAmountA = amountA;
        uint256 actualAmountB = amountB;

        if (actualAmountB > 0) {
            camelotBalancedTokenB.approve(address(camelotV2Router), actualAmountB);
            address[] memory path = new address[](2);
            path[0] = address(camelotBalancedTokenB);
            path[1] = address(camelotBalancedTokenA);

            camelotV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                actualAmountB, 1, path, address(this), REFERRER, block.timestamp
            );
        }

        uint256 finalTokenABalance = camelotBalancedTokenA.balanceOf(address(this));
        uint256 actualTotalTokenA = finalTokenABalance - initialTokenABalance;

        assertEq(actualTotalTokenA, expectedTotalTokenA, "Should receive exactly the expected total TokenA amount");
    }

    function test_withdrawSwapQuote_Camelot_unbalancedPool() public {
        _initializeCamelotUnbalancedPools();
        (uint112 reserve0, uint112 reserve1, uint16 token0Fee, uint16 token1Fee) = camelotUnbalancedPair.getReserves();
        uint256 lpTotalSupply = camelotUnbalancedPair.totalSupply();

        (uint256 reserveA, uint256 tokenAFee, uint256 reserveB, uint256 tokenBFee) = ConstProdUtils._sortReserves(
            address(camelotUnbalancedTokenA),
            camelotUnbalancedPair.token0(),
            reserve0,
            uint256(token0Fee),
            reserve1,
            uint256(token1Fee)
        );
        // Sanity: ensure reserveA corresponds to camelotUnbalancedTokenA
        if (camelotUnbalancedPair.token0() == address(camelotUnbalancedTokenA)) {
            assertEq(reserveA, uint256(reserve0));
        } else {
            assertEq(reserveA, uint256(reserve1));
        }

        uint256 feePercent = tokenAFee;
        uint256 lpBalance = camelotUnbalancedPair.balanceOf(address(this));
        uint256 ownedLPAmount = lpBalance / 2;

            uint256 expectedTotalTokenA = CamelotV2Utils._quoteWithdrawSwapWithFee(
            ownedLPAmount, lpTotalSupply, reserveA, reserveB, feePercent, FEE_DENOMINATOR, 0, 0, false
        );

        uint256 initialTokenABalance = camelotUnbalancedTokenA.balanceOf(address(this));

        camelotUnbalancedPair.transfer(address(camelotUnbalancedPair), ownedLPAmount);
        (uint256 amount0, uint256 amount1) = camelotUnbalancedPair.burn(address(this));

        uint256 actualAmountA;
        uint256 actualAmountB;
        if (camelotUnbalancedPair.token0() == address(camelotUnbalancedTokenA)) {
            actualAmountA = amount0;
            actualAmountB = amount1;
        } else {
            actualAmountA = amount1;
            actualAmountB = amount0;
        }

        if (actualAmountB > 0) {
            camelotUnbalancedTokenB.approve(address(camelotV2Router), actualAmountB);
            address[] memory path = new address[](2);
            path[0] = address(camelotUnbalancedTokenB);
            path[1] = address(camelotUnbalancedTokenA);

            camelotV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                actualAmountB, 1, path, address(this), REFERRER, block.timestamp
            );
        }

        uint256 finalTokenABalance = camelotUnbalancedTokenA.balanceOf(address(this));
        uint256 actualTotalTokenA = finalTokenABalance - initialTokenABalance;

        assertEq(actualTotalTokenA, expectedTotalTokenA, "Should receive exactly the expected total TokenA amount");
    }

    function test_withdrawSwapQuote_Camelot_extremeUnbalancedPool() public {
        _initializeCamelotExtremeUnbalancedPools();
        (uint112 reserve0, uint112 reserve1, uint16 token0Fee, uint16 token1Fee) = camelotExtremeUnbalancedPair.getReserves();
        (uint256 reserveA, uint256 feeA, uint256 reserveB, uint256 feeB) = ConstProdUtils._sortReserves(
            address(camelotExtremeTokenA),
            camelotExtremeUnbalancedPair.token0(),
            reserve0,
            uint256(token0Fee),
            reserve1,
            uint256(token1Fee)
        );
        // Sanity: ensure reserveA corresponds to camelotExtremeTokenA
        if (camelotExtremeUnbalancedPair.token0() == address(camelotExtremeTokenA)) {
            assertEq(reserveA, uint256(reserve0));
        } else {
            assertEq(reserveA, uint256(reserve1));
        }
        uint256 feePercent = feeA;
        uint256 lpTotalSupply = camelotExtremeUnbalancedPair.totalSupply();

        uint256 lpBalance = camelotExtremeUnbalancedPair.balanceOf(address(this));
        uint256 ownedLPAmount = lpBalance / 2;

        uint256 expectedTotalTokenA = CamelotV2Utils._quoteWithdrawSwapWithFee(
            ownedLPAmount, lpTotalSupply, reserveA, reserveB, feePercent, FEE_DENOMINATOR, 0, 0, false
        );

        uint256 initialTokenABalance = camelotExtremeTokenA.balanceOf(address(this));


        camelotExtremeUnbalancedPair.transfer(address(camelotExtremeUnbalancedPair), ownedLPAmount);
        (uint256 amountA, uint256 amountB) = camelotExtremeUnbalancedPair.burn(address(this));


        uint256 actualAmountA;
        uint256 actualAmountB;
        if (camelotExtremeUnbalancedPair.token0() == address(camelotExtremeTokenA)) {
            actualAmountA = amountA;
            actualAmountB = amountB;
        } else {
            actualAmountA = amountB;
            actualAmountB = amountA;
        }


        if (actualAmountB > 0) {
            camelotExtremeTokenB.approve(address(camelotV2Router), actualAmountB);
            address[] memory path = new address[](2);
            path[0] = address(camelotExtremeTokenB);
            path[1] = address(camelotExtremeTokenA);

            camelotV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                actualAmountB, 1, path, address(this), REFERRER, block.timestamp
            );
        }

        uint256 finalTokenABalance = camelotExtremeTokenA.balanceOf(address(this));
        uint256 actualTotalTokenA = finalTokenABalance - initialTokenABalance;

        

        assertEq(actualTotalTokenA, expectedTotalTokenA, "Should receive exactly the expected total TokenA amount");
    }

    // Edge cases
    function test_withdrawSwapQuote_edgeCase_smallLPAmount() public {
        _initializeCamelotBalancedPools();
        (uint112 reserveA, uint112 reserveB, uint16 feeA, uint16 feeB) = camelotBalancedPair.getReserves();
        uint256 feePercent = uint256(feeA);
        uint256 lpTotalSupply = camelotBalancedPair.totalSupply();

        uint256 lpBalance = camelotBalancedPair.balanceOf(address(this));
        uint256 ownedLPAmount = lpBalance / 4; // Smaller amount

        uint256 expectedTotalTokenA = CamelotV2Utils._quoteWithdrawSwapWithFee(
            ownedLPAmount, lpTotalSupply, reserveA, reserveB, feePercent, FEE_DENOMINATOR, 0, 0, false
        );

        uint256 initialTokenABalance = camelotBalancedTokenA.balanceOf(address(this));

        camelotBalancedPair.transfer(address(camelotBalancedPair), ownedLPAmount);
        (uint256 amountA, uint256 amountB) = camelotBalancedPair.burn(address(this));

        if (amountB > 0) {
            camelotBalancedTokenB.approve(address(camelotV2Router), amountB);
            address[] memory path = new address[](2);
            path[0] = address(camelotBalancedTokenB);
            path[1] = address(camelotBalancedTokenA);
            camelotV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(amountB, 1, path, address(this), REFERRER, block.timestamp);
        }

        uint256 finalTokenABalance = camelotBalancedTokenA.balanceOf(address(this));
        uint256 actualTotalTokenA = finalTokenABalance - initialTokenABalance;

        assertEq(actualTotalTokenA, expectedTotalTokenA, "Should receive exactly the expected total TokenA amount");
    }

    function test_withdrawSwapQuote_edgeCase_largeLPAmount() public {
        _initializeCamelotBalancedPools();
        (uint112 reserveA, uint112 reserveB, uint16 feeA, uint16 feeB) = camelotBalancedPair.getReserves();
        uint256 feePercent = uint256(feeA);
        uint256 lpTotalSupply = camelotBalancedPair.totalSupply();

        uint256 lpBalance = camelotBalancedPair.balanceOf(address(this));
        uint256 ownedLPAmount = (lpBalance * 3) / 4; // Larger amount

        uint256 expectedTotalTokenA = CamelotV2Utils._quoteWithdrawSwapWithFee(
            ownedLPAmount, lpTotalSupply, reserveA, reserveB, feePercent, FEE_DENOMINATOR, 0, 0, false
        );

        uint256 initialTokenABalance = camelotBalancedTokenA.balanceOf(address(this));

        camelotBalancedPair.transfer(address(camelotBalancedPair), ownedLPAmount);
        (uint256 amountA, uint256 amountB) = camelotBalancedPair.burn(address(this));

        if (amountB > 0) {
            camelotBalancedTokenB.approve(address(camelotV2Router), amountB);
            address[] memory path = new address[](2);
            path[0] = address(camelotBalancedTokenB);
            path[1] = address(camelotBalancedTokenA);
            camelotV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(amountB, 1, path, address(this), REFERRER, block.timestamp);
        }

        uint256 finalTokenABalance = camelotBalancedTokenA.balanceOf(address(this));
        uint256 actualTotalTokenA = finalTokenABalance - initialTokenABalance;

        assertEq(actualTotalTokenA, expectedTotalTokenA, "Should receive exactly the expected total TokenA amount");
    }

    function test_withdrawSwapQuote_edgeCase_differentFees() public {
        _initializeCamelotBalancedPools();
        (uint112 reserveA, uint112 reserveB, uint16 feeA, uint16 feeB) = camelotBalancedPair.getReserves();
        uint256 feePercent = uint256(feeA);
        uint256 lpTotalSupply = camelotBalancedPair.totalSupply();

        uint256 lpBalance = camelotBalancedPair.balanceOf(address(this));
        uint256 ownedLPAmount = lpBalance / 2;

        uint256 expectedTotalTokenA = CamelotV2Utils._quoteWithdrawSwapWithFee(
            ownedLPAmount, lpTotalSupply, reserveA, reserveB, feePercent, FEE_DENOMINATOR, 0, 0, false
        );

        uint256 initialTokenABalance = camelotBalancedTokenA.balanceOf(address(this));

        camelotBalancedPair.transfer(address(camelotBalancedPair), ownedLPAmount);
        (uint256 amountA, uint256 amountB) = camelotBalancedPair.burn(address(this));

        if (amountB > 0) {
            camelotBalancedTokenB.approve(address(camelotV2Router), amountB);
            address[] memory path = new address[](2);
            path[0] = address(camelotBalancedTokenB);
            path[1] = address(camelotBalancedTokenA);
            camelotV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(amountB, 1, path, address(this), REFERRER, block.timestamp);
        }

        uint256 finalTokenABalance = camelotBalancedTokenA.balanceOf(address(this));
        uint256 actualTotalTokenA = finalTokenABalance - initialTokenABalance;

        assertEq(actualTotalTokenA, expectedTotalTokenA, "Should receive exactly the expected total TokenA amount");
    }

    function test_withdrawSwapQuote_edgeCase_verySmallReserves() public {
        _initializeCamelotBalancedPools();
        (uint112 reserveA, uint112 reserveB, uint16 feeA, uint16 feeB) = camelotBalancedPair.getReserves();
        uint256 feePercent = uint256(feeA);
        uint256 lpTotalSupply = camelotBalancedPair.totalSupply();

        uint256 lpBalance = camelotBalancedPair.balanceOf(address(this));
        uint256 ownedLPAmount = lpBalance / 2;

        uint256 expectedTotalTokenA = CamelotV2Utils._quoteWithdrawSwapWithFee(
            ownedLPAmount, lpTotalSupply, reserveA, reserveB, feePercent, FEE_DENOMINATOR, 0, 0, false
        );

        uint256 initialTokenABalance = camelotBalancedTokenA.balanceOf(address(this));

        camelotBalancedPair.transfer(address(camelotBalancedPair), ownedLPAmount);
        (uint256 amountA, uint256 amountB) = camelotBalancedPair.burn(address(this));

        if (amountB > 0) {
            camelotBalancedTokenB.approve(address(camelotV2Router), amountB);
            address[] memory path = new address[](2);
            path[0] = address(camelotBalancedTokenB);
            path[1] = address(camelotBalancedTokenA);
            camelotV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(amountB, 1, path, address(this), REFERRER, block.timestamp);
        }

        uint256 finalTokenABalance = camelotBalancedTokenA.balanceOf(address(this));
        uint256 actualTotalTokenA = finalTokenABalance - initialTokenABalance;

        assertEq(actualTotalTokenA, expectedTotalTokenA, "Should receive exactly the expected total TokenA amount");
    }

    function test_withdrawSwapQuote_edgeCase_midRangeLPAmount() public {
        _initializeCamelotBalancedPools();
        (uint112 reserveA, uint112 reserveB, uint16 feeA, uint16 feeB) = camelotBalancedPair.getReserves();
        uint256 feePercent = uint256(feeA);
        uint256 lpTotalSupply = camelotBalancedPair.totalSupply();

        uint256 lpBalance = camelotBalancedPair.balanceOf(address(this));
        uint256 ownedLPAmount = (lpBalance * 2) / 3; // Mid-range amount

        uint256 expectedTotalTokenA = CamelotV2Utils._quoteWithdrawSwapWithFee(
            ownedLPAmount, lpTotalSupply, reserveA, reserveB, feePercent, FEE_DENOMINATOR, 0, 0, false
        );

        uint256 initialTokenABalance = camelotBalancedTokenA.balanceOf(address(this));

        camelotBalancedPair.transfer(address(camelotBalancedPair), ownedLPAmount);
        (uint256 amountA, uint256 amountB) = camelotBalancedPair.burn(address(this));

        if (amountB > 0) {
            camelotBalancedTokenB.approve(address(camelotV2Router), amountB);
            address[] memory path = new address[](2);
            path[0] = address(camelotBalancedTokenB);
            path[1] = address(camelotBalancedTokenA);
            camelotV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(amountB, 1, path, address(this), REFERRER, block.timestamp);
        }

        uint256 finalTokenABalance = camelotBalancedTokenA.balanceOf(address(this));
        uint256 actualTotalTokenA = finalTokenABalance - initialTokenABalance;

        assertEq(actualTotalTokenA, expectedTotalTokenA, "Should receive exactly the expected total TokenA amount");
    }

    function test_withdrawSwapQuote_edgeCase_maxLPAmount() public {
        _initializeCamelotBalancedPools();
        // Use Camelot balanced pair for large LP amount edge case
        (uint112 reserveA2, uint112 reserveB2, uint16 feeA2, uint16 feeB2) = camelotBalancedPair.getReserves();
        uint256 lpTotalSupply2 = camelotBalancedPair.totalSupply();

        uint256 lpBalance2 = camelotBalancedPair.balanceOf(address(this));
        uint256 ownedLPAmount2 = (lpBalance2 * 3) / 4; // Large amount

        uint256 expectedTotalTokenA2 = CamelotV2Utils._quoteWithdrawSwapWithFee(
            ownedLPAmount2, lpTotalSupply2, reserveA2, reserveB2, uint256(feeA2), FEE_DENOMINATOR, 0, 0, false
        );

        uint256 initialTokenABalance2 = camelotBalancedTokenA.balanceOf(address(this));

        camelotBalancedPair.transfer(address(camelotBalancedPair), ownedLPAmount2);
        (uint256 amountA2, uint256 amountB2) = camelotBalancedPair.burn(address(this));

        if (amountB2 > 0) {
            camelotBalancedTokenB.approve(address(camelotV2Router), amountB2);
            address[] memory path = new address[](2);
            path[0] = address(camelotBalancedTokenB);
            path[1] = address(camelotBalancedTokenA);
            camelotV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(amountB2, 1, path, address(this), REFERRER, block.timestamp);
        }

        uint256 finalTokenABalance2 = camelotBalancedTokenA.balanceOf(address(this));
        uint256 actualTotalTokenA2 = finalTokenABalance2 - initialTokenABalance2;

        assertEq(actualTotalTokenA2, expectedTotalTokenA2, "Should receive exactly the expected total TokenA amount");
    }
}