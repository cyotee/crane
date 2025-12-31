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

    struct PoolState {
        uint112 r0;
        uint112 r1;
        uint256 totalSupply;
        uint256 kLast;
        uint256 reserveTarget;
        uint256 reserveSale;
        uint256 desiredOut;
        uint256 ownerFeeShare;
        uint256 feePercent;
        uint256 quotedLpAmt;
    }

    struct BurnAndSwapState {
        uint256 balBefore;
        uint256 a0;
        uint256 a1;
        uint256 saleAmount;
        uint256 balAfter;
        uint256 actualReceived;
    }

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

        PoolState memory poolState;
        uint16 f0;
        uint16 f1;
        (poolState.r0, poolState.r1, f0, f1) = pair.getReserves();
        poolState.totalSupply = pair.totalSupply();
        poolState.kLast = pair.kLast();
        (poolState.reserveTarget, poolState.reserveSale) = ConstProdUtils._sortReserves(address(targetToken), pair.token0(), poolState.r0, poolState.r1);

        poolState.desiredOut = (poolState.reserveTarget * percentage) / 10000;
        if (poolState.desiredOut > poolState.reserveTarget) poolState.desiredOut = poolState.reserveTarget;

        (poolState.ownerFeeShare, ) = camelotV2Factory.feeInfo();

        poolState.feePercent = pair.token0() == address(targetToken) ? uint256(f0) : uint256(f1);

        ConstProdUtils.ZapOutToTargetWithFeeArgs memory args = ConstProdUtils.ZapOutToTargetWithFeeArgs({
            desiredOut: poolState.desiredOut,
            lpTotalSupply: poolState.totalSupply,
            reserveDesired: poolState.reserveTarget,
            reserveOther: poolState.reserveSale,
            feePercent: poolState.feePercent,
            feeDenominator: 100000,
            kLast: poolState.kLast,
            ownerFeeShare: poolState.ownerFeeShare,
            feeOn: feesEnabled,
            protocolFeeDenominator: 100000
        });

        poolState.quotedLpAmt = ConstProdUtils._quoteZapOutToTargetWithFee(args);
        assertTrue(poolState.quotedLpAmt > 0, "Quoted LP amount should be positive");
        assertTrue(poolState.quotedLpAmt <= poolState.totalSupply, "Quoted LP amount should not exceed total supply");

        BurnAndSwapState memory state;
        state.balBefore = targetToken.balanceOf(address(this));
        pair.transfer(address(pair), poolState.quotedLpAmt);
        (state.a0, state.a1) = pair.burn(address(this));
        if (address(targetToken) == pair.token0()) {
            state.saleAmount = state.a1;
        } else {
            state.saleAmount = state.a0;
        }
        if (state.saleAmount > 0) {
            saleToken.approve(address(camelotV2Router), state.saleAmount);
            camelotV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                state.saleAmount, 1, _buildPath(address(saleToken), address(targetToken)), address(this), address(0), block.timestamp
            );
        }
        state.balAfter = targetToken.balanceOf(address(this));
        state.actualReceived = state.balAfter - state.balBefore;
        assertTrue(state.actualReceived >= poolState.desiredOut, "received >= desiredOut");
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
