// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";
import {TestBase_ConstProdUtils_Aerodrome} from "./TestBase_ConstProdUtils_Aerodrome.sol";
import {Pool} from "@crane/contracts/protocols/dexes/aerodrome/v1/Pool.sol";

contract ConstProdUtils_saleQuote_Aerodrome is TestBase_ConstProdUtils_Aerodrome {
    using ConstProdUtils for uint256;

    uint256 constant AERO_FEE_PERCENT = 30; // 30/10000

    function test_saleQuote_matchesPool_smallAmounts() public {
        _initializeAerodromeBalancedPools();
        Pool p = Pool(aeroBalancedPool);
        (uint256 r0, uint256 r1,) = p.getReserves();

        uint256[] memory samples = new uint256[](5);
        samples[0] = 1;
        samples[1] = 10;
        samples[2] = 1e6;
        samples[3] = r0 / 1000;
        samples[4] = r0 / 100;

        address tokenIn = p.token1(); // we'll sell tokenB -> tokenA (match tests elsewhere)

        for (uint256 i = 0; i < samples.length; i++) {
            uint256 amt = samples[i];
            // pool removes fee by /10000 internally
            uint256 poolOut = p.getAmountOut(amt, tokenIn);
            uint256 saleQuote = ConstProdUtils._saleQuote(amt, r1, r0, AERO_FEE_PERCENT, 10000);
            assertEq(poolOut, saleQuote, "saleQuote should match Pool.getAmountOut");
        }
    }

    function test_saleQuote_smallTolerance() public {
        _initializeAerodromeBalancedPools();
        Pool p = Pool(aeroBalancedPool);
        (uint256 r0, uint256 r1,) = p.getReserves();

        // tiny, medium and large amounts that previously caused off-by errors
        uint256[] memory samples = new uint256[](6);
        samples[0] = 1;
        samples[1] = 2;
        samples[2] = 3;
        samples[3] = 100;
        samples[4] = r1 / 100000; // very small relative
        samples[5] = r1 / 1000;

        address tokenIn = p.token1();
        for (uint256 i = 0; i < samples.length; i++) {
            uint256 amt = samples[i];
            uint256 poolOut = p.getAmountOut(amt, tokenIn);
            uint256 saleQuote = ConstProdUtils._saleQuote(amt, r1, r0, AERO_FEE_PERCENT, 10000);
            // allow a tolerance of 1 unit due to integer rounding ordering differences
            if (poolOut > saleQuote) {
                assertTrue(poolOut - saleQuote <= 1, "poolOut - saleQuote <= 1");
            } else {
                assertTrue(saleQuote - poolOut <= 1, "saleQuote - poolOut <= 1");
            }
        }
    }
}
