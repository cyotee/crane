// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";
import {TestBase_ConstProdUtils_Aerodrome} from "./TestBase_ConstProdUtils_Aerodrome.sol";
import {Pool} from "@crane/contracts/protocols/dexes/aerodrome/v1/Pool.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ConstProdUtils_swapQuote_Aerodrome is TestBase_ConstProdUtils_Aerodrome {
    using ConstProdUtils for uint256;

    uint256 constant AERO_FEE_PERCENT = 30; // 30/10000

    function setUp() public override {
        TestBase_ConstProdUtils_Aerodrome.setUp();
    }

    function test_saleQuote_aerodrome_swap() public {
        uint256 swapAmount = 1000e18;

        _initializeAerodromeBalancedPools();

        Pool p = Pool(aeroBalancedPool);
        (uint256 reserve0, uint256 reserve1,) = p.getReserves();

        // Determine token ordering and map reserves accordingly
        address token0 = p.token0();
        address token1 = p.token1();

        // we'll sell `aeroBalancedTokenA` (test token A) for the counterpart
        address sellToken = address(aeroBalancedTokenA);
        address buyToken;
        uint256 reserveIn;
        uint256 reserveOut;
        uint256 amount0Out;
        uint256 amount1Out;
        uint256 initialBalanceOut;

        if (sellToken == token0) {
            // selling token0 -> token1
            buyToken = token1;
            reserveIn = reserve0;
            reserveOut = reserve1;
            amount0Out = 0;
            amount1Out = ConstProdUtils._saleQuote(swapAmount, reserveIn, reserveOut, AERO_FEE_PERCENT, 10000);

            aeroBalancedTokenA.mint(address(this), swapAmount);
            initialBalanceOut = IERC20(buyToken).balanceOf(address(this));
            aeroBalancedTokenA.transfer(address(p), swapAmount);
            p.swap(amount0Out, amount1Out, address(this), new bytes(0));
        } else {
            // selling token1 -> token0 (sellToken is token1)
            buyToken = token0;
            reserveIn = reserve1;
            reserveOut = reserve0;
            amount1Out = 0;
            amount0Out = ConstProdUtils._saleQuote(swapAmount, reserveIn, reserveOut, AERO_FEE_PERCENT, 10000);

            aeroBalancedTokenA.mint(address(this), swapAmount);
            initialBalanceOut = IERC20(buyToken).balanceOf(address(this));
            aeroBalancedTokenA.transfer(address(p), swapAmount);
            p.swap(amount0Out, amount1Out, address(this), new bytes(0));
        }

        uint256 finalBalanceOut = IERC20(buyToken).balanceOf(address(this));
        uint256 received = finalBalanceOut - initialBalanceOut;
        uint256 expectedAmountOut = (amount0Out == 0) ? amount1Out : amount0Out;

        assertEq(received, expectedAmountOut, "received should equal expectedAmountOut");
    }
}
