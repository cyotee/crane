// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";
import {TestBase_ConstProdUtils_Camelot} from "./TestBase_ConstProdUtils_Camelot.sol";
import {FEE_DENOMINATOR} from "contracts/constants/Constants.sol";

import {IERC20MintBurn} from "contracts/interfaces/IERC20MintBurn.sol";
import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {ICamelotPair} from "contracts/interfaces/protocols/dexes/camelot/v2/ICamelotPair.sol";
import {ICamelotV2Router} from "contracts/interfaces/protocols/dexes/camelot/v2/ICamelotV2Router.sol";

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

            if (feePercent > 0) {
                data.remainingReserveA = data.remainingReserveA * (FEE_DENOMINATOR - feePercent) / FEE_DENOMINATOR;
            }

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

            if (feePercent > 0) {
                data.remainingReserveB = data.remainingReserveB * (FEE_DENOMINATOR - feePercent) / FEE_DENOMINATOR;
            }

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

        data.quote = ConstProdUtils._quoteWithdrawSwapWithFee(
            data.lpAmount,
            data.totalLP,
            data.reserveA,
            data.reserveB,
            CAMELOT_FEE_PERCENT,
            FEE_DENOMINATOR,
            data.kLast,
            ownerFeeShare,
            feesEnabled
        );

        data.actualAmount = _performActualWithdrawSwap(data.pool, data.lpAmount, CAMELOT_FEE_PERCENT);

        assertEq(data.quote, data.actualAmount, "Quote should match actual execution");
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

}