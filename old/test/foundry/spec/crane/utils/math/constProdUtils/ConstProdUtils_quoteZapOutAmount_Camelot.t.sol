// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";
import {TestBase_ConstProdUtils_Camelot} from "./TestBase_ConstProdUtils_Camelot.sol";
import {ICamelotPair} from "contracts/interfaces/protocols/dexes/camelot/v2/ICamelotPair.sol";

contract ConstProdUtils_quoteZapOutAmount_Camelot is TestBase_ConstProdUtils_Camelot {
    function setUp() public override {
        super.setUp();
    }

    function test_quoteZapOutAmount_Camelot_BalancedPool() public {
        _initializeCamelotBalancedPools();
        _testQuoteZapOutAmount(camelotBalancedPair, address(camelotBalancedTokenA));
    }

    function test_quoteZapOutAmount_Camelot_UnbalancedPool() public {
        _initializeCamelotUnbalancedPools();
        _testQuoteZapOutAmount(camelotUnbalancedPair, address(camelotUnbalancedTokenA));
    }

    function test_quoteZapOutAmount_Camelot_ExtremeUnbalancedPool() public {
        _initializeCamelotExtremeUnbalancedPools();
        _testQuoteZapOutAmount(camelotExtremeUnbalancedPair, address(camelotExtremeTokenA));
    }

    function _testQuoteZapOutAmount(ICamelotPair pair, address tokenA) internal {
        (uint112 r0, uint112 r1, , ) = pair.getReserves();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(tokenA, pair.token0(), r0, r1);
        uint256 totalSupply = pair.totalSupply();

        uint256 desiredOut = reserveA / 1000; // small fraction

        (uint256 ownerFeeShare, ) = camelotV2Factory.feeInfo();
        ConstProdUtils.ZapOutToTargetWithFeeArgs memory args = ConstProdUtils.ZapOutToTargetWithFeeArgs({
            desiredOut: desiredOut,
            lpTotalSupply: totalSupply,
            reserveDesired: reserveA,
            reserveOther: reserveB,
            feePercent: 500,
            feeDenominator: 100000,
            kLast: pair.kLast(),
            ownerFeeShare: ownerFeeShare,
            feeOn: false,
            protocolFeeDenominator: 100000
        });

        uint256 lpNeeded = ConstProdUtils._quoteZapOutToTargetWithFee(args);

        assertTrue(lpNeeded <= totalSupply, "lpNeeded should not exceed total supply");
        if (desiredOut > 0) {
            assertTrue(lpNeeded > 0, "lpNeeded should be positive for non-zero desiredOut");
        }
    }
}

