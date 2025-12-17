// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";
import {TestBase_ConstProdUtils_Camelot} from "./TestBase_ConstProdUtils_Camelot.sol";
import {ICamelotPair} from "contracts/interfaces/protocols/dexes/camelot/v2/ICamelotPair.sol";

contract ConstProdUtils_quoteZapOutAmount_Camelot is TestBase_ConstProdUtils_Camelot {
    using ConstProdUtils for uint256;

    uint256 constant FEE_PERCENT = 300; // 0.3%
    uint256 constant FEE_DENOMINATOR = 100000;

    function setUp() public override {
        super.setUp();
    }

    function test_quoteZapOutAmount_Camelot_BalancedPool() public {
        _initializeCamelotBalancedPools();
        _testQuoteZapOutAmount(camelotBalancedPair);
    }

    function test_quoteZapOutAmount_Camelot_UnbalancedPool() public {
        _initializeCamelotUnbalancedPools();
        _testQuoteZapOutAmount(camelotUnbalancedPair);
    }

    function test_quoteZapOutAmount_Camelot_ExtremeUnbalancedPool() public {
        _initializeCamelotExtremeUnbalancedPools();
        _testQuoteZapOutAmount(camelotExtremeUnbalancedPair);
    }

    function _testQuoteZapOutAmount(ICamelotPair pair) internal {
        (uint112 r0, uint112 r1,,) = pair.getReserves();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(address(0), pair.token0(), r0, r1);
        uint256 totalSupply = pair.totalSupply();

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

        assertTrue(lpNeeded <= totalSupply, "lpNeeded should not exceed total supply");
        if (desiredOut > 0) {
            assertTrue(lpNeeded > 0, "lpNeeded should be positive for non-zero desiredOut");
        }
    }
}
