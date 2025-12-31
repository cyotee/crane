// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";
import {TestBase_ConstProdUtils_Aerodrome} from "./TestBase_ConstProdUtils_Aerodrome.sol";
import {IRouter} from "@crane/contracts/protocols/dexes/aerodrome/v1/interfaces/IRouter.sol";
import {Pool} from "@crane/contracts/protocols/dexes/aerodrome/v1/Pool.sol";
import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";

contract ConstProdUtils_withdrawSwap_Aerodrome is TestBase_ConstProdUtils_Aerodrome {
    using ConstProdUtils for uint256;

    uint256 constant LOW_PERCENTAGE = 10;
    uint256 constant MEDIUM_PERCENTAGE = 50;
    uint256 constant HIGH_PERCENTAGE = 90;

    uint256 constant AERO_FEE_PERCENT = 30; // 0.3% expressed in 1/10000

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
        (uint256 r0, uint256 r1,) = p.getReserves();
        reserveA = r0;
        reserveB = r1;
        tokenA = p.token0();
        tokenB = p.token1();
    }

    function _performActualWithdrawSwap(address pool, uint256 lpAmount, address tokenA, address tokenB)
        internal
        returns (uint256 actualTokenAAmount)
    {
        Pool pair = Pool(pool);
        IRouter r = IRouter(address(router));

        uint256 balABefore = IERC20(tokenA).balanceOf(address(this));

        pair.transfer(pool, lpAmount);
        (uint256 a0, uint256 a1) = pair.burn(address(this));

        address t0 = pair.token0();
        uint256 actualA = (tokenA == t0) ? a0 : a1;
        uint256 actualB = (tokenB == t0) ? a0 : a1;

        if (actualB > 0) {
            IERC20(tokenB).approve(address(r), actualB);
            IRouter.Route[] memory routes = new IRouter.Route[](1);
            routes[0] = IRouter.Route({from: tokenB, to: tokenA, stable: false, factory: address(factory)});

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
        uint256 totalLP = pair.totalSupply();
        uint256 lpAmount = _calculateLPAmount(totalLP, percentage);

        (uint256 reserveA, uint256 reserveB, address tokenA, address tokenB) = _getPoolReserves(address(pair));

        if (feesEnabled) {
            // generate some trading activity so swap fees are accrued into the pool
            // reuse small swaps via router
            (uint256 r0, uint256 r1,) = pair.getReserves();
            uint256 swapAmountA = (r0 * 100) / 10000; // 1% of reserves
            uint256 swapAmountB = (r1 * 100) / 10000;
            deal(tokenA, address(this), swapAmountA, true);
            deal(tokenB, address(this), swapAmountB, true);
            IERC20(tokenA).approve(address(router), swapAmountA);
            IRouter.Route[] memory rAB = new IRouter.Route[](1);
            rAB[0] = IRouter.Route({from: tokenA, to: tokenB, stable: false, factory: address(factory)});
            router.swapExactTokensForTokensSupportingFeeOnTransferTokens(swapAmountA, 1, rAB, address(this), block.timestamp);
        }

        uint256 quote = ConstProdUtils._quoteWithdrawSwapWithFee(
            lpAmount,
            totalLP,
            reserveA,
            reserveB,
            AERO_FEE_PERCENT,
            10000, // Aerodrome fee denominator
            0,
            0,
            false
        );

        uint256 actualAmount = _performActualWithdrawSwap(address(pair), lpAmount, tokenA, tokenB);

        assertEq(quote, actualAmount, "Quote should match actual execution");
    }

    function test_withdrawSwap_Aerodrome_balancedPool() public {
        _initializeAerodromeBalancedPools();
        _testWithdrawSwapWithFee(aeroBalancedPool, 50, false);
    }

    function test_withdrawSwap_Aerodrome_unbalancedPool() public {
        _initializeAerodromeUnbalancedPools();
        _testWithdrawSwapWithFee(aeroUnbalancedPool, 50, false);
    }

    function test_withdrawSwap_Aerodrome_extremeUnbalancedPool() public {
        _initializeAerodromeExtremeUnbalancedPools();
        _testWithdrawSwapWithFee(aeroExtremeUnbalancedPool, 50, false);
    }
}
