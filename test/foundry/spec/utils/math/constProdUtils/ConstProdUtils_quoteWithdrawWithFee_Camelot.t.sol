// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";
import {TestBase_ConstProdUtils_Camelot} from "./TestBase_ConstProdUtils_Camelot.sol";
import {ICamelotPair} from "contracts/interfaces/protocols/dexes/camelot/v2/ICamelotPair.sol";

contract ConstProdUtils_quoteWithdrawWithFee_Camelot is TestBase_ConstProdUtils_Camelot {
    function setUp() public override {
        super.setUp();
    }

    function _quotedWithdrawForPair(ICamelotPair pair, address tokenA) internal view returns (uint256 quotedA, uint256 quotedB) {
        uint256 lpReceived = pair.balanceOf(address(this));
        if (lpReceived == 0) return (0, 0);
        (uint112 r0, uint112 r1, uint16 f0, uint16 f1) = pair.getReserves();
        uint256 totalSupply = pair.totalSupply();
        (uint256 reserveA, , uint256 reserveB, ) = ConstProdUtils._sortReserves(
            tokenA,
            pair.token0(),
            r0,
            f0,
            r1,
            f1
        );
        uint256 kLast = pair.kLast();
        (uint256 ownerFeeShare, ) = camelotV2Factory.feeInfo();
        return ConstProdUtils._quoteWithdrawWithFee(lpReceived, totalSupply, reserveA, reserveB, kLast, ownerFeeShare, false);
    }

    function test_quoteWithdrawWithFee_Camelot_balanced_simple() public {
        _initializeCamelotBalancedPools();
        ICamelotPair pair = camelotBalancedPair;

        uint256 lpReceived = pair.balanceOf(address(this));
        assertTrue(lpReceived > 0, "got lp");

        (uint256 quotedA, uint256 quotedB) = _quotedWithdrawForPair(pair, address(camelotBalancedTokenA));

        // Execute withdrawal
        uint256 beforeA = camelotBalancedTokenA.balanceOf(address(this));
        uint256 beforeB = camelotBalancedTokenB.balanceOf(address(this));
        pair.transfer(address(pair), lpReceived);
        (uint256 a0, uint256 a1) = pair.burn(address(this));
        uint256 afterA = camelotBalancedTokenA.balanceOf(address(this));
        uint256 afterB = camelotBalancedTokenB.balanceOf(address(this));

        uint256 actualA = afterA - beforeA;
        uint256 actualB = afterB - beforeB;

        assertEq(quotedA, actualA, "quotedA == actualA");
        assertEq(quotedB, actualB, "quotedB == actualB");
    }

    function test_quoteWithdrawWithFee_Camelot_unbalanced_simple() public {
        _initializeCamelotUnbalancedPools();
        ICamelotPair pair = camelotUnbalancedPair;

        uint256 lpReceived = pair.balanceOf(address(this));

        (uint256 quotedA, uint256 quotedB) = _quotedWithdrawForPair(pair, address(camelotUnbalancedTokenA));

        // Execute withdrawal
        uint256 beforeA = camelotUnbalancedTokenA.balanceOf(address(this));
        uint256 beforeB = camelotUnbalancedTokenB.balanceOf(address(this));
        pair.transfer(address(pair), lpReceived);
        (uint256 a0, uint256 a1) = pair.burn(address(this));
        uint256 afterA = camelotUnbalancedTokenA.balanceOf(address(this));
        uint256 afterB = camelotUnbalancedTokenB.balanceOf(address(this));

        uint256 actualA = afterA - beforeA;
        uint256 actualB = afterB - beforeB;

        assertEq(quotedA, actualA, "quotedA == actualA");
        assertEq(quotedB, actualB, "quotedB == actualB");
    }

    function test_quoteWithdrawWithFee_Camelot_extreme_unbalanced_simple() public {
        _initializeCamelotExtremeUnbalancedPools();
        ICamelotPair pair = camelotExtremeUnbalancedPair;

        uint256 lpReceived = pair.balanceOf(address(this));

        (uint256 quotedA, uint256 quotedB) = _quotedWithdrawForPair(pair, address(camelotExtremeTokenA));

        // Execute withdrawal
        uint256 beforeA = camelotExtremeTokenA.balanceOf(address(this));
        uint256 beforeB = camelotExtremeTokenB.balanceOf(address(this));
        pair.transfer(address(pair), lpReceived);
        (uint256 a0, uint256 a1) = pair.burn(address(this));
        uint256 afterA = camelotExtremeTokenA.balanceOf(address(this));
        uint256 afterB = camelotExtremeTokenB.balanceOf(address(this));

        uint256 actualA = afterA - beforeA;
        uint256 actualB = afterB - beforeB;

        assertEq(quotedA, actualA, "quotedA == actualA");
        assertEq(quotedB, actualB, "quotedB == actualB");
    }
}
