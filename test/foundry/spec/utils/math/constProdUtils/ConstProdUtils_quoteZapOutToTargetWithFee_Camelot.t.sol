// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";
import {TestBase_ConstProdUtils_Camelot} from "./TestBase_ConstProdUtils_Camelot.sol";
import {ICamelotPair} from "contracts/interfaces/protocols/dexes/camelot/v2/ICamelotPair.sol";
import {ERC20PermitMintableStub} from "contracts/tokens/ERC20/ERC20PermitMintableStub.sol";

contract ConstProdUtils_quoteZapOutToTargetWithFee_Camelot_Test is TestBase_ConstProdUtils_Camelot {
    uint256 constant PERCENTAGE_1_PCT = 100; // 1%
    uint256 constant PERCENTAGE_5_PCT = 500; // 5%
    uint256 constant PERCENTAGE_10_PCT = 1000; // 10%
    uint256 constant PERCENTAGE_25_PCT = 2500; // 25%

    function setUp() public override {
        super.setUp();
    }

    function test_quoteZapOutToTargetWithFee_Camelot_balancedPool_feesDisabled_targetTokenA_1pct() public {
        _testZapOutToTargetWithFeePercentage(camelotBalancedPair, camelotBalancedTokenA, camelotBalancedTokenB, false, PERCENTAGE_1_PCT);
    }

    function test_quoteZapOutToTargetWithFee_Camelot_balancedPool_feesEnabled_targetTokenA_5pct() public {
        _testZapOutToTargetWithFeePercentage(camelotBalancedPair, camelotBalancedTokenA, camelotBalancedTokenB, true, PERCENTAGE_5_PCT);
    }

    function test_quoteZapOutToTargetWithFee_Camelot_balancedPool_feesDisabled_targetTokenB_10pct() public {
        _testZapOutToTargetWithFeePercentage(camelotBalancedPair, camelotBalancedTokenB, camelotBalancedTokenA, false, PERCENTAGE_10_PCT);
    }

    function test_quoteZapOutToTargetWithFee_Camelot_balancedPool_feesEnabled_targetTokenB_25pct() public {
        _testZapOutToTargetWithFeePercentage(camelotBalancedPair, camelotBalancedTokenB, camelotBalancedTokenA, true, PERCENTAGE_25_PCT);
    }

    function test_quoteZapOutToTargetWithFee_Camelot_balancedPool_impossible_scenarios() public {
        _testZapOutToTargetWithFeeImpossible(camelotBalancedPair, camelotBalancedTokenA, camelotBalancedTokenB, false);
        _testZapOutToTargetWithFeeImpossible(camelotBalancedPair, camelotBalancedTokenA, camelotBalancedTokenB, true);
    }

    function _testZapOutToTargetWithFeePercentage(
        ICamelotPair pair,
        ERC20PermitMintableStub targetToken,
        ERC20PermitMintableStub saleToken,
        bool feesEnabled,
        uint256 percentage
    ) internal {
        _initializeCamelotBalancedPools();
        // Generate trading activity to accrue protocol fees so Camelot's
        // `_mintFee` path will run during `burn` and quoting matches.
        // Only generate fees when the test scenario expects fees enabled.
        if (feesEnabled) {
            _executeCamelotTradesToGenerateFees(targetToken, saleToken);
        }

        (uint112 r0, uint112 r1, uint16 f0, uint16 f1) = pair.getReserves();
        uint256 totalSupply = pair.totalSupply();
        (uint256 reserveTarget, uint256 reserveSale) = ConstProdUtils._sortReserves(address(targetToken), pair.token0(), r0, r1);

        uint256 desiredOut = (reserveTarget * percentage) / 10000;
        if (desiredOut > reserveTarget) desiredOut = reserveTarget;

        (uint256 ownerFeeShare, ) = camelotV2Factory.feeInfo();

        uint256 feePercent = pair.token0() == address(targetToken) ? uint256(f0) : uint256(f1);

        ConstProdUtils.ZapOutToTargetWithFeeArgs memory args = ConstProdUtils.ZapOutToTargetWithFeeArgs({
            desiredOut: desiredOut,
            lpTotalSupply: totalSupply,
            reserveDesired: reserveTarget,
            reserveOther: reserveSale,
            feePercent: feePercent,
            feeDenominator: 100000,
            kLast: pair.kLast(),
            ownerFeeShare: ownerFeeShare,
            feeOn: feesEnabled,
            protocolFeeDenominator: 100000
        });

        uint256 quotedLpAmt = ConstProdUtils._quoteZapOutToTargetWithFee(args);
        assertTrue(quotedLpAmt > 0, "Quoted LP amount should be positive");
        assertTrue(quotedLpAmt <= totalSupply, "Quoted LP amount should not exceed total supply");

        uint256 balBefore = targetToken.balanceOf(address(this));
        pair.transfer(address(pair), quotedLpAmt);
        (uint256 a0, uint256 a1) = pair.burn(address(this));
        uint256 saleAmount;
        if (address(targetToken) == pair.token0()) {
            saleAmount = a1;
        } else {
            saleAmount = a0;
        }
        if (saleAmount > 0) {
            saleToken.approve(address(camelotV2Router), saleAmount);
            camelotV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                saleAmount, 1, _buildPath(address(saleToken), address(targetToken)), address(this), address(0), block.timestamp
            );
        }
        uint256 balAfter = targetToken.balanceOf(address(this));
        uint256 actualReceived = balAfter - balBefore;
        assertTrue(actualReceived >= desiredOut, "received >= desiredOut");
    }

    function _testZapOutToTargetWithFeeImpossible(
        ICamelotPair pair,
        ERC20PermitMintableStub targetToken,
        ERC20PermitMintableStub saleToken,
        bool feesEnabled
    ) internal {
        _initializeCamelotBalancedPools();

        (uint112 r0, uint112 r1, , ) = pair.getReserves();
        uint256 totalSupply = pair.totalSupply();
        uint256 kLast = pair.kLast();
        (uint256 reserveTarget, uint256 reserveSale) = ConstProdUtils._sortReserves(address(targetToken), pair.token0(), r0, r1);

        (uint256 ownerFeeShare, ) = camelotV2Factory.feeInfo();

        ConstProdUtils.ZapOutToTargetWithFeeArgs memory args1 = ConstProdUtils.ZapOutToTargetWithFeeArgs({
            desiredOut: reserveTarget + 1,
            lpTotalSupply: totalSupply,
            reserveDesired: reserveTarget,
            reserveOther: reserveSale,
            feePercent: 500,
            feeDenominator: 100000,
            kLast: kLast,
            ownerFeeShare: ownerFeeShare,
            feeOn: feesEnabled,
            protocolFeeDenominator: 100000
        });
        uint256 quoted1 = ConstProdUtils._quoteZapOutToTargetWithFee(args1);
        assertEq(quoted1, 0, "Should return 0 when desired output exceeds reserves");

        ConstProdUtils.ZapOutToTargetWithFeeArgs memory args2 = ConstProdUtils.ZapOutToTargetWithFeeArgs({
            desiredOut: 0,
            lpTotalSupply: totalSupply,
            reserveDesired: reserveTarget,
            reserveOther: reserveSale,
            feePercent: 500,
            feeDenominator: 100000,
            kLast: kLast,
            ownerFeeShare: ownerFeeShare,
            feeOn: feesEnabled,
            protocolFeeDenominator: 100000
        });
        uint256 quoted2 = ConstProdUtils._quoteZapOutToTargetWithFee(args2);
        assertEq(quoted2, 0, "Should return 0 when desired output is 0");

        uint256 maxPossibleOutput = reserveTarget;
        if (maxPossibleOutput > 0) {
            ConstProdUtils.ZapOutToTargetWithFeeArgs memory args3 = ConstProdUtils.ZapOutToTargetWithFeeArgs({
                desiredOut: maxPossibleOutput + 1,
                lpTotalSupply: totalSupply,
                reserveDesired: reserveTarget,
                reserveOther: reserveSale,
                feePercent: 500,
                feeDenominator: 100000,
                kLast: kLast,
                ownerFeeShare: ownerFeeShare,
                feeOn: feesEnabled,
                protocolFeeDenominator: 100000
            });
            uint256 quoted3 = ConstProdUtils._quoteZapOutToTargetWithFee(args3);
            assertEq(quoted3, 0, "Should return 0 when desired output exceeds maximum possible");
        }
    }

    function _buildPath(address a, address b) internal pure returns (address[] memory path) {
        path = new address[](2);
        path[0] = a;
        path[1] = b;
    }
}
