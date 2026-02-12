// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";
import {AerodromeUtils} from "contracts/utils/math/AerodromeUtils.sol";
import {TestBase_ConstProdUtils_Aerodrome} from "./TestBase_ConstProdUtils_Aerodrome.sol";
import {IRouter} from "@crane/contracts/protocols/dexes/aerodrome/v1/interfaces/IRouter.sol";
import {Pool} from "@crane/contracts/protocols/dexes/aerodrome/v1/stubs/Pool.sol";
import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";

contract ConstProdUtils_quoteWithdrawSwapWithFee_Aerodrome is TestBase_ConstProdUtils_Aerodrome {
    using ConstProdUtils for uint256;

    uint256 constant LOW_PERCENTAGE = 10;
    uint256 constant MEDIUM_PERCENTAGE = 50;
    uint256 constant HIGH_PERCENTAGE = 90;

    struct TestData {
        uint256 totalLP;
        uint256 lpAmount;
        uint256 reserveA;
        uint256 reserveB;
        address tokenA;
        address tokenB;
        uint256 ownerFeeShare;
        uint256 feePercent;
        uint256 quote;
        uint256 actualAmount;
    }

    function setUp() public override {
        super.setUp();
    }

    function _calculateLPAmount(uint256 totalLP, uint256 percentage) internal pure returns (uint256) {
        return (totalLP * percentage) / 100;
    }

    function _getPoolReserves(address pool)
        internal
        view
        returns (uint256 reserveA, uint256 reserveB, address tokenA, address tokenB)
    {
        Pool p = Pool(pool);
        reserveA = p.reserve0();
        reserveB = p.reserve1();
        tokenA = p.token0();
        tokenB = p.token1();
    }

    // simple trading activity generator for Aerodrome pools to accrue fees
    function _generateTradingActivity(
        Pool pair,
        address tokenA,
        address tokenB,
        uint256 swapPercentage // basis points of reserves (e.g., 100 = 1%)
    ) internal {
        (uint256 reserveA, uint256 reserveB,,) = _getPoolReserves(address(pair));

        uint256 swapAmountA = (uint256(reserveA) * swapPercentage) / 10000;
        uint256 swapAmountB = (uint256(reserveB) * swapPercentage) / 10000;

        // allocate balances for trading
        deal(tokenA, address(this), swapAmountA, true);
        deal(tokenB, address(this), swapAmountB, true);

        IERC20(tokenA).approve(address(aerodromeRouter), swapAmountA);
        IRouter.Route[] memory routesAB = new IRouter.Route[](1);
        routesAB[0] = IRouter.Route({from: tokenA, to: tokenB, stable: false, factory: address(aerodromePoolFactory)});

        aerodromeRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            swapAmountA,
            1,
            routesAB,
            address(this),
            block.timestamp
        );

        uint256 receivedB = IERC20(tokenB).balanceOf(address(this));
        if (receivedB > 0) {
            IERC20(tokenB).approve(address(aerodromeRouter), receivedB);
            IRouter.Route[] memory routesBA = new IRouter.Route[](1);
            routesBA[0] = IRouter.Route({from: tokenB, to: tokenA, stable: false, factory: address(aerodromePoolFactory)});
            aerodromeRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                receivedB,
                1,
                routesBA,
                address(this),
                block.timestamp
            );
        }
    }

    function _performActualWithdrawSwap(address pool, uint256 lpAmount, address tokenA, address tokenB, uint256 /* feePercent */)
        internal
        returns (uint256 actualTokenAAmount)
    {
        Pool pair = Pool(pool);
        IRouter r = IRouter(address(aerodromeRouter));

        uint256 balABefore = IERC20(tokenA).balanceOf(address(this));
        uint256 balBBefore = IERC20(tokenB).balanceOf(address(this));

        pair.transfer(pool, lpAmount);
        (uint256 a0, uint256 a1) = pair.burn(address(this));

        address t0 = pair.token0();
        uint256 actualA = (tokenA == t0) ? a0 : a1;
        uint256 actualB = (tokenB == t0) ? a0 : a1;

        if (actualB > 0) {
            IERC20(tokenB).approve(address(r), actualB);
            IRouter.Route[] memory routes = new IRouter.Route[](1);
            routes[0] = IRouter.Route({from: tokenB, to: tokenA, stable: false, factory: address(aerodromePoolFactory)});

            uint256 beforeA = IERC20(tokenA).balanceOf(address(this));
            r.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                actualB,
                0,
                routes,
                address(this),
                block.timestamp + 300
            );
            uint256 afterA = IERC20(tokenA).balanceOf(address(this));
            uint256 receivedA = afterA - beforeA;
            actualTokenAAmount = actualA + receivedA;
        } else {
            actualTokenAAmount = actualA;
        }
    }

    function _testWithdrawSwapWithFee(Pool pair, uint256 percentage, bool feesEnabled) internal {
        TestData memory data;
        data.totalLP = pair.totalSupply();
        data.lpAmount = _calculateLPAmount(data.totalLP, percentage);

        (data.reserveA, data.reserveB, data.tokenA, data.tokenB) = _getPoolReserves(address(pair));

        if (feesEnabled) {
            _generateTradingActivity(pair, data.tokenA, data.tokenB, 100);
            (data.reserveA, data.reserveB, data.tokenA, data.tokenB) = _getPoolReserves(address(pair));
            data.totalLP = pair.totalSupply();
        }

        data.feePercent = aerodromePoolFactory.getFee(address(pair), pair.stable());

        data.quote = AerodromeUtils._quoteWithdrawSwapWithFee(
            data.lpAmount,
            data.totalLP,
            data.reserveA,
            data.reserveB,
            data.feePercent
        );

        data.actualAmount = _performActualWithdrawSwap(address(pair), data.lpAmount, data.tokenA, data.tokenB, data.feePercent);

        assertEq(data.quote, data.actualAmount, "Quote should match actual execution");
    }

    function test_quoteWithdrawSwapWithFee_Aerodrome_balancedPool_lowPercentage_feesDisabled_extractTokenA() public {
        _initializeAerodromeBalancedPools();
        _testWithdrawSwapWithFee(aeroBalancedPool, LOW_PERCENTAGE, false);
    }

    function test_quoteWithdrawSwapWithFee_Aerodrome_balancedPool_mediumPercentage_feesDisabled_extractTokenA() public {
        _initializeAerodromeBalancedPools();
        _testWithdrawSwapWithFee(aeroBalancedPool, MEDIUM_PERCENTAGE, false);
    }

    function test_quoteWithdrawSwapWithFee_Aerodrome_balancedPool_highPercentage_feesDisabled_extractTokenA() public {
        _initializeAerodromeBalancedPools();
        _testWithdrawSwapWithFee(aeroBalancedPool, HIGH_PERCENTAGE, false);
    }

    function test_quoteWithdrawSwapWithFee_Aerodrome_balancedPool_lowPercentage_feesEnabled_extractTokenA() public {
        _initializeAerodromeBalancedPools();
        _testWithdrawSwapWithFee(aeroBalancedPool, LOW_PERCENTAGE, true);
    }

    function test_quoteWithdrawSwapWithFee_Aerodrome_balancedPool_mediumPercentage_feesEnabled_extractTokenA() public {
        _initializeAerodromeBalancedPools();
        _testWithdrawSwapWithFee(aeroBalancedPool, MEDIUM_PERCENTAGE, true);
    }

    function test_quoteWithdrawSwapWithFee_Aerodrome_balancedPool_highPercentage_feesEnabled_extractTokenA() public {
        _initializeAerodromeBalancedPools();
        _testWithdrawSwapWithFee(aeroBalancedPool, HIGH_PERCENTAGE, true);
    }

    // unbalanced variants
    function test_quoteWithdrawSwapWithFee_Aerodrome_balancedPool() public {
        _initializeAerodromeBalancedPools();
        (uint256 reserve0, uint256 reserve1,) = aeroBalancedPool.getReserves();
        (uint256 reserveA, uint256 reserveB) = (reserve0, reserve1);
        uint256 lpTotalSupply = aeroBalancedPool.totalSupply();

        uint256 lpBalance = aeroBalancedPool.balanceOf(address(this));
        uint256 ownedLPAmount = lpBalance / 2;

        uint256 expectedTotalTokenA = AerodromeUtils._quoteWithdrawSwapWithFee(
            ownedLPAmount, lpTotalSupply, reserveA, reserveB, aerodromePoolFactory.getFee(address(aeroBalancedPool), aeroBalancedPool.stable())
        );

        uint256 initialTokenABalance = IERC20(aeroBalancedPool.token0()).balanceOf(address(this));

        aeroBalancedPool.transfer(address(aeroBalancedPool), ownedLPAmount);
        (uint256 amountA, uint256 amountB) = aeroBalancedPool.burn(address(this));

        uint256 actualAmountA = amountA;
        uint256 actualAmountB = amountB;

        if (actualAmountB > 0) {
            IERC20(aeroBalancedPool.token1()).approve(address(aerodromeRouter), actualAmountB);
            IRouter.Route[] memory path = new IRouter.Route[](1);
            path[0] = IRouter.Route({from: aeroBalancedPool.token1(), to: aeroBalancedPool.token0(), stable: false, factory: address(aerodromePoolFactory)});

            aerodromeRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                actualAmountB,
                1,
                path,
                address(this),
                block.timestamp
            );
        }

        uint256 finalTokenABalance = IERC20(aeroBalancedPool.token0()).balanceOf(address(this));
        uint256 actualTotalTokenA = finalTokenABalance - initialTokenABalance;

        assertEq(actualTotalTokenA, expectedTotalTokenA, "Should receive exactly the expected total TokenA amount");
    }

    function test_quoteWithdrawSwapWithFee_Aerodrome_unbalancedPool() public {
        _initializeAerodromeUnbalancedPools();
        (uint256 reserve0, uint256 reserve1,) = aeroUnbalancedPool.getReserves();
        (uint256 reserveA, uint256 reserveB) = (reserve0, reserve1);
        uint256 lpTotalSupply = aeroUnbalancedPool.totalSupply();

        uint256 lpBalance = aeroUnbalancedPool.balanceOf(address(this));
        uint256 ownedLPAmount = lpBalance / 2;

        uint256 expectedTotalTokenA = AerodromeUtils._quoteWithdrawSwapWithFee(
            ownedLPAmount, lpTotalSupply, reserveA, reserveB, aerodromePoolFactory.getFee(address(aeroUnbalancedPool), aeroUnbalancedPool.stable())
        );

        uint256 initialTokenABalance = IERC20(aeroUnbalancedPool.token0()).balanceOf(address(this));

        aeroUnbalancedPool.transfer(address(aeroUnbalancedPool), ownedLPAmount);
        (uint256 amountA, uint256 amountB) = aeroUnbalancedPool.burn(address(this));

        uint256 actualAmountA = amountA;
        uint256 actualAmountB = amountB;

        if (actualAmountB > 0) {
            IERC20(aeroUnbalancedPool.token1()).approve(address(aerodromeRouter), actualAmountB);
            IRouter.Route[] memory path = new IRouter.Route[](1);
            path[0] = IRouter.Route({from: aeroUnbalancedPool.token1(), to: aeroUnbalancedPool.token0(), stable: false, factory: address(aerodromePoolFactory)});

            aerodromeRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                actualAmountB,
                1,
                path,
                address(this),
                block.timestamp
            );
        }

        uint256 finalTokenABalance = IERC20(aeroUnbalancedPool.token0()).balanceOf(address(this));
        uint256 actualTotalTokenA = finalTokenABalance - initialTokenABalance;

        assertEq(actualTotalTokenA, expectedTotalTokenA, "Should receive exactly the expected total TokenA amount");
    }

    function test_quoteWithdrawSwapWithFee_Aerodrome_extremeUnbalancedPool() public {
        _initializeAerodromeExtremeUnbalancedPools();
        (uint256 reserve0, uint256 reserve1,) = aeroExtremeUnbalancedPool.getReserves();
        (uint256 reserveA, uint256 reserveB) = (reserve0, reserve1);
        uint256 lpTotalSupply = aeroExtremeUnbalancedPool.totalSupply();

        uint256 lpBalance = aeroExtremeUnbalancedPool.balanceOf(address(this));
        uint256 ownedLPAmount = lpBalance / 2;

        uint256 expectedTotalTokenA = AerodromeUtils._quoteWithdrawSwapWithFee(
            ownedLPAmount, lpTotalSupply, reserveA, reserveB, aerodromePoolFactory.getFee(address(aeroExtremeUnbalancedPool), aeroExtremeUnbalancedPool.stable())
        );

        uint256 initialTokenABalance = IERC20(aeroExtremeUnbalancedPool.token0()).balanceOf(address(this));

        aeroExtremeUnbalancedPool.transfer(address(aeroExtremeUnbalancedPool), ownedLPAmount);
        (uint256 amountA, uint256 amountB) = aeroExtremeUnbalancedPool.burn(address(this));

        uint256 actualAmountA = amountA;
        uint256 actualAmountB = amountB;

        if (actualAmountB > 0) {
            IERC20(aeroExtremeUnbalancedPool.token1()).approve(address(aerodromeRouter), actualAmountB);
            IRouter.Route[] memory path = new IRouter.Route[](1);
            path[0] = IRouter.Route({from: aeroExtremeUnbalancedPool.token1(), to: aeroExtremeUnbalancedPool.token0(), stable: false, factory: address(aerodromePoolFactory)});

            aerodromeRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                actualAmountB,
                1,
                path,
                address(this),
                block.timestamp
            );
        }

        uint256 finalTokenABalance = IERC20(aeroExtremeUnbalancedPool.token0()).balanceOf(address(this));
        uint256 actualTotalTokenA = finalTokenABalance - initialTokenABalance;

        assertEq(actualTotalTokenA, expectedTotalTokenA, "Should receive exactly the expected total TokenA amount");
    }
}
