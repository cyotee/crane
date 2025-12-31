// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {TestBase_ConstProdUtils_Aerodrome} from "./TestBase_ConstProdUtils_Aerodrome.sol";
import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IRouter} from "@crane/contracts/protocols/dexes/aerodrome/v1/interfaces/IRouter.sol";
import "forge-std/console.sol";

contract ConstProdUtils_calculateZapOutLP_Aerodrome is TestBase_ConstProdUtils_Aerodrome {
    function setUp() public override {
        TestBase_ConstProdUtils_Aerodrome.setUp();
    }

    function test_calculateZapOutLP_Aerodrome_balancedPool() public {
        _initializeAerodromeBalancedPools();

        (uint256 reserve0, uint256 reserve1,) = aeroBalancedPool.getReserves();
        (uint256 reserveA, uint256 reserveB) = (reserve0, reserve1);
        uint256 lpTotalSupply = aeroBalancedPool.totalSupply();

        uint256 desiredOut = reserveA / 10;

        uint256 expectedLpNeeded = ConstProdUtils._quoteZapOutToTargetWithFee(
            desiredOut,
            lpTotalSupply,
            reserveA,
            reserveB,
            30, // Aerodrome fee percent (30/10000)
            10000,
            0,
            0,
            false
        );

        uint256 initialTokenABalance = aeroBalancedTokenA.balanceOf(address(this));

        console.log("=== ZapOut Debug: balancedPool ===");
        console.log("desiredOut"); console.log(desiredOut);
        console.log("reserveA"); console.log(reserveA);
        console.log("reserveB"); console.log(reserveB);
        console.log("lpTotalSupply"); console.log(lpTotalSupply);
        console.log("expectedLpNeeded"); console.log(expectedLpNeeded);

        aeroBalancedPool.transfer(address(aeroBalancedPool), expectedLpNeeded);
        (uint256 amt0, uint256 amt1) = aeroBalancedPool.burn(address(this));

        uint256 amountA = aeroBalancedPool.token0() == address(aeroBalancedTokenA) ? amt0 : amt1;
        uint256 amountB = aeroBalancedPool.token0() == address(aeroBalancedTokenA) ? amt1 : amt0;

        if (amountB > 0) {
            address desiredToken = address(aeroBalancedTokenA);
            address tokenToSwap = aeroBalancedPool.token0() == desiredToken ? aeroBalancedPool.token1() : aeroBalancedPool.token0();
            IERC20(tokenToSwap).approve(address(router), amountB);
            IRouter.Route[] memory routes = new IRouter.Route[](1);
            routes[0] = IRouter.Route({from: tokenToSwap, to: desiredToken, stable: false, factory: address(factory)});

            router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amountB,
                1,
                routes,
                address(this),
                block.timestamp
            );
        }

        uint256 finalTokenABalance = aeroBalancedTokenA.balanceOf(address(this));
        uint256 actualTokenAReceived = finalTokenABalance - initialTokenABalance;

        console.log("actualTokenAReceived"); console.log(actualTokenAReceived);
        console.log("amountA"); console.log(amountA);
        console.log("amountB"); console.log(amountB);

        uint256 diff = actualTokenAReceived > desiredOut ? actualTokenAReceived - desiredOut : desiredOut - actualTokenAReceived;
        assertTrue(diff <= 10, "Should receive approximately the desired TokenA amount within tolerance");
    }

    function test_calculateZapOutLP_Aerodrome_unbalancedPool() public {
        _initializeAerodromeUnbalancedPools();

        (uint256 reserve0, uint256 reserve1,) = aeroUnbalancedPool.getReserves();
        (uint256 reserveA, uint256 reserveB) = (reserve0, reserve1);
        uint256 lpTotalSupply = aeroUnbalancedPool.totalSupply();

        uint256 desiredOut = reserveA / 8;

        uint256 expectedLpNeeded = ConstProdUtils._quoteZapOutToTargetWithFee(
            desiredOut,
            lpTotalSupply,
            reserveA,
            reserveB,
            30,
            10000,
            0,
            0,
            false
        );

        uint256 initialTokenABalance = aeroUnbalancedTokenA.balanceOf(address(this));

        console.log("=== ZapOut Debug: unbalancedPool ===");
        console.log("desiredOut"); console.log(desiredOut);
        console.log("reserveA"); console.log(reserveA);
        console.log("reserveB"); console.log(reserveB);
        console.log("lpTotalSupply"); console.log(lpTotalSupply);
        console.log("expectedLpNeeded"); console.log(expectedLpNeeded);

        aeroUnbalancedPool.transfer(address(aeroUnbalancedPool), expectedLpNeeded);
        (uint256 amt0, uint256 amt1) = aeroUnbalancedPool.burn(address(this));

        uint256 amountA = aeroUnbalancedPool.token0() == address(aeroUnbalancedTokenA) ? amt0 : amt1;
        uint256 amountB = aeroUnbalancedPool.token0() == address(aeroUnbalancedTokenA) ? amt1 : amt0;

        if (amountB > 0) {
            address desiredToken = address(aeroUnbalancedTokenA);
            address tokenToSwap = aeroUnbalancedPool.token0() == desiredToken ? aeroUnbalancedPool.token1() : aeroUnbalancedPool.token0();
            IERC20(tokenToSwap).approve(address(router), amountB);
            IRouter.Route[] memory routes = new IRouter.Route[](1);
            routes[0] = IRouter.Route({from: tokenToSwap, to: desiredToken, stable: false, factory: address(factory)});

            router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amountB,
                1,
                routes,
                address(this),
                block.timestamp
            );
        }

        uint256 finalTokenABalance = aeroUnbalancedTokenA.balanceOf(address(this));
        uint256 actualTokenAReceived = finalTokenABalance - initialTokenABalance;

        console.log("actualTokenAReceived"); console.log(actualTokenAReceived);
        console.log("amountA"); console.log(amountA);
        console.log("amountB"); console.log(amountB);

        uint256 diff = actualTokenAReceived > desiredOut ? actualTokenAReceived - desiredOut : desiredOut - actualTokenAReceived;
        assertTrue(diff <= 10, "Should receive approximately the desired TokenA amount within tolerance");
    }

    function test_calculateZapOutLP_Aerodrome_extremeUnbalancedPool() public {
        _initializeAerodromeExtremeUnbalancedPools();

        (uint256 reserve0, uint256 reserve1,) = aeroExtremeUnbalancedPool.getReserves();
        (uint256 reserveA, uint256 reserveB) = (reserve0, reserve1);
        uint256 lpTotalSupply = aeroExtremeUnbalancedPool.totalSupply();

        uint256 desiredOut = reserveA / 20;

        uint256 expectedLpNeeded = ConstProdUtils._quoteZapOutToTargetWithFee(
            desiredOut,
            lpTotalSupply,
            reserveA,
            reserveB,
            30,
            10000,
            0,
            0,
            false
        );

        uint256 initialTokenABalance = aeroExtremeTokenA.balanceOf(address(this));

        console.log("=== ZapOut Debug: extremeUnbalancedPool ===");
        console.log("desiredOut"); console.log(desiredOut);
        console.log("reserveA"); console.log(reserveA);
        console.log("reserveB"); console.log(reserveB);
        console.log("lpTotalSupply"); console.log(lpTotalSupply);
        console.log("expectedLpNeeded"); console.log(expectedLpNeeded);

        aeroExtremeUnbalancedPool.transfer(address(aeroExtremeUnbalancedPool), expectedLpNeeded);
        (uint256 amt0, uint256 amt1) = aeroExtremeUnbalancedPool.burn(address(this));

        uint256 amountA = aeroExtremeUnbalancedPool.token0() == address(aeroExtremeTokenA) ? amt0 : amt1;
        uint256 amountB = aeroExtremeUnbalancedPool.token0() == address(aeroExtremeTokenA) ? amt1 : amt0;

        if (amountB > 0) {
            address desiredToken = address(aeroExtremeTokenA);
            address tokenToSwap = aeroExtremeUnbalancedPool.token0() == desiredToken ? aeroExtremeUnbalancedPool.token1() : aeroExtremeUnbalancedPool.token0();
            IERC20(tokenToSwap).approve(address(router), amountB);
            IRouter.Route[] memory routes = new IRouter.Route[](1);
            routes[0] = IRouter.Route({from: tokenToSwap, to: desiredToken, stable: false, factory: address(factory)});

            router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amountB,
                1,
                routes,
                address(this),
                block.timestamp
            );
        }

        uint256 finalTokenABalance = aeroExtremeTokenA.balanceOf(address(this));
        uint256 actualTokenAReceived = finalTokenABalance - initialTokenABalance;

        console.log("actualTokenAReceived"); console.log(actualTokenAReceived);
        console.log("amountA"); console.log(amountA);
        console.log("amountB"); console.log(amountB);

        uint256 diff = actualTokenAReceived > desiredOut ? actualTokenAReceived - desiredOut : desiredOut - actualTokenAReceived;
        assertTrue(diff <= 10, "Should receive approximately the desired TokenA amount within tolerance");
    }
}
