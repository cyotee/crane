// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";
import {TestBase_ConstProdUtils_Aerodrome} from "./TestBase_ConstProdUtils_Aerodrome.sol";
import {Pool} from "contracts/protocols/dexes/aerodrome/v1/Pool.sol";

contract ConstProdUtils_quoteZapOutAmount_Aerodrome is TestBase_ConstProdUtils_Aerodrome {
    using ConstProdUtils for uint256;

    uint256 constant FEE_PERCENT = 300; // 0.3%
    uint256 constant FEE_DENOMINATOR = 100000;

    function setUp() public override {
        super.setUp();
    }

    function test_quoteZapOutAmount_Aerodrome_BalancedPool() public {
        _initializeAerodromeBalancedPools();
        _testQuoteZapOutAmount(aeroBalancedPool);
    }

    function test_quoteZapOutAmount_Aerodrome_UnbalancedPool() public {
        _initializeAerodromeUnbalancedPools();
        _testQuoteZapOutAmount(aeroUnbalancedPool);
    }

    function test_quoteZapOutAmount_Aerodrome_ExtremeUnbalancedPool() public {
        _initializeAerodromeExtremeUnbalancedPools();
        _testQuoteZapOutAmount(aeroExtremeUnbalancedPool);
    }

    function _testQuoteZapOutAmount(Pool pair) internal {
        uint256 r0 = pair.reserve0();
        uint256 r1 = pair.reserve1();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(address(0), pair.token0(), r0, r1);
        uint256 totalSupply = pair.totalSupply();

        // Choose a reasonable desiredOut: small fraction of reserveA
        uint256 desiredOut = reserveA / 1000;

        uint256 lpNeeded = ConstProdUtils._quoteZapOutToTargetWithFee(
            desiredOut,
            totalSupply,
            reserveA,
            reserveB,
            FEE_PERCENT,
            FEE_DENOMINATOR,
            /*kLast*/ 0,
            /*ownerFeeShare*/ 0,
            /*feeOn*/ false
        );

        // Basic invariants
        assertTrue(lpNeeded <= totalSupply, "lpNeeded should not exceed total supply");
        // zero-case handled
        if (desiredOut > 0) {
            assertTrue(lpNeeded > 0, "lpNeeded should be positive for non-zero desiredOut");
        }
    }
}
