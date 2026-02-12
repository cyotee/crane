// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {betterconsole as console} from "contracts/utils/vm/foundry/tools/betterconsole.sol";
import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";
import {TestBase_ConstProdUtils_Uniswap} from "@crane/test/foundry/spec/utils/math/constProdUtils/TestBase_ConstProdUtils_Uniswap.sol";
import {IUniswapV2Pair} from "contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Pair.sol";
import {ERC20PermitMintableStub} from "contracts/tokens/ERC20/ERC20PermitMintableStub.sol";
import {UniV2Factory} from "contracts/protocols/dexes/uniswap/v2/stubs/UniV2Factory.sol";

contract ConstProdUtils_quoteZapOutToTargetWithFee_Uniswap_Test is TestBase_ConstProdUtils_Uniswap {
    // Fee constants matching legacy tests
    uint256 constant UNISWAP_FEE_PERCENT = 3; // 0.3%
    uint256 constant UNISWAP_FEE_DENOMINATOR = 1000;
    uint256 constant UNISWAP_OWNER_FEE_SHARE = 16666; // ~1/6

    uint256 constant PERCENTAGE_1_PCT = 100; // 1%
    uint256 constant PERCENTAGE_5_PCT = 500; // 5%
    uint256 constant PERCENTAGE_10_PCT = 1000; // 10%
    uint256 constant PERCENTAGE_25_PCT = 2500; // 25%
    uint256 constant PERCENTAGE_50_PCT = 5000; // 50%

    function setUp() public override {
        TestBase_ConstProdUtils_Uniswap.setUp();
    }

    function test_quoteZapOutToTargetWithFee_Uniswap_balancedPool_feesDisabled_targetTokenA_1pct() public {
        _testZapOutToTargetWithFeePercentage(uniswapBalancedPair, uniswapBalancedTokenA, uniswapBalancedTokenB, false, PERCENTAGE_1_PCT);
    }

    function test_quoteZapOutToTargetWithFee_Uniswap_balancedPool_feesEnabled_targetTokenA_5pct() public {
        _testZapOutToTargetWithFeePercentage(uniswapBalancedPair, uniswapBalancedTokenA, uniswapBalancedTokenB, true, PERCENTAGE_5_PCT);
    }

    function test_quoteZapOutToTargetWithFee_Uniswap_balancedPool_feesDisabled_targetTokenB_10pct() public {
        _testZapOutToTargetWithFeePercentage(uniswapBalancedPair, uniswapBalancedTokenB, uniswapBalancedTokenA, false, PERCENTAGE_10_PCT);
    }

    function test_quoteZapOutToTargetWithFee_Uniswap_balancedPool_feesEnabled_targetTokenB_25pct() public {
        _testZapOutToTargetWithFeePercentage(uniswapBalancedPair, uniswapBalancedTokenB, uniswapBalancedTokenA, true, PERCENTAGE_25_PCT);
    }

    function test_quoteZapOutToTargetWithFee_Uniswap_balancedPool_impossible_scenarios() public {
        _testZapOutToTargetWithFeeImpossible(uniswapBalancedPair, uniswapBalancedTokenA, uniswapBalancedTokenB, false);
        _testZapOutToTargetWithFeeImpossible(uniswapBalancedPair, uniswapBalancedTokenA, uniswapBalancedTokenB, true);
    }

    // Internal helper ported from legacy snippet and adapted to TestBase
    struct ZapData {
        uint112 r0;
        uint112 r1;
        uint256 totalSupply;
        uint256 kLast;
        uint256 reserveTarget;
        uint256 reserveSale;
        uint256 maxPossibleOutput;
        uint256 desiredOut;
    }

    struct ExecData {
        uint256 targetBefore;
        uint256 saleBefore;
        uint256 amount0;
        uint256 amount1;
        uint256 targetAmount;
        uint256 saleAmount;
        uint256 proceeds;
        uint256 targetAfter;
        uint256 saleAfter;
        uint256 actualTargetReceived;
    }

    function _testZapOutToTargetWithFeePercentage(
        IUniswapV2Pair pair,
        ERC20PermitMintableStub targetToken,
        ERC20PermitMintableStub saleToken,
        bool feesEnabled,
        uint256 percentage
    ) internal {
        console.log("=== Testing Uniswap V2 zapout-to-target ===");
        console.log("Percentage:", percentage / 100, "% ===");

        _setupUniswapFees(feesEnabled);
        _initializeUniswapBalancedPools();
        // Generate trading activity so protocol fee paths can run and
        // `kLast`/fee mints reflect accrued fees in the pair.
        _executeUniswapTradesToGenerateFees(targetToken, saleToken);

        ZapData memory d;
        (d.r0, d.r1,) = pair.getReserves();
        d.totalSupply = pair.totalSupply();
        d.kLast = pair.kLast();
        (d.reserveTarget, d.reserveSale) = ConstProdUtils._sortReserves(address(targetToken), pair.token0(), d.r0, d.r1);

        d.maxPossibleOutput = _calculateMaxPossibleOutput(d.totalSupply, d.reserveTarget, d.reserveSale, UNISWAP_FEE_PERCENT, UNISWAP_FEE_DENOMINATOR);

        d.desiredOut = (d.reserveTarget * percentage) / 10000;
        if (d.desiredOut > d.maxPossibleOutput) d.desiredOut = d.maxPossibleOutput;
        if (d.desiredOut > d.reserveTarget) d.desiredOut = d.reserveTarget;

        ConstProdUtils.ZapOutToTargetWithFeeArgs memory args = ConstProdUtils.ZapOutToTargetWithFeeArgs({
            desiredOut: d.desiredOut,
            lpTotalSupply: d.totalSupply,
            reserveDesired: d.reserveTarget,
            reserveOther: d.reserveSale,
            feePercent: UNISWAP_FEE_PERCENT,
            feeDenominator: UNISWAP_FEE_DENOMINATOR,
            kLast: d.kLast,
            ownerFeeShare: UNISWAP_OWNER_FEE_SHARE,
            feeOn: feesEnabled,
            protocolFeeDenominator: 100000
        });
        uint256 quotedLpAmt = ConstProdUtils._quoteZapOutToTargetWithFee(args);

        assertTrue(quotedLpAmt > 0, "Quoted LP amount should be positive");
        assertTrue(quotedLpAmt <= d.totalSupply, "Quoted LP amount should not exceed total supply");

        uint256 actualLpAmt = _executeZapOutAndValidate(pair, targetToken, saleToken, quotedLpAmt, d.desiredOut);
        assertEq(quotedLpAmt, actualLpAmt, "Quote should exactly match actual LP amount");
    }

    function _testZapOutToTargetWithFeeImpossible(
        IUniswapV2Pair pair,
        ERC20PermitMintableStub targetToken,
        ERC20PermitMintableStub saleToken,
        bool feesEnabled
    ) internal {
        _setupUniswapFees(feesEnabled);
        _initializeUniswapBalancedPools();

        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
        uint256 totalSupply = pair.totalSupply();
        uint256 kLast = pair.kLast();
        (uint256 reserveTarget, uint256 reserveSale) = ConstProdUtils._sortReserves(address(targetToken), pair.token0(), reserve0, reserve1);

        ConstProdUtils.ZapOutToTargetWithFeeArgs memory args1 = ConstProdUtils.ZapOutToTargetWithFeeArgs({
            desiredOut: reserveTarget + 1,
            lpTotalSupply: totalSupply,
            reserveDesired: reserveTarget,
            reserveOther: reserveSale,
            feePercent: UNISWAP_FEE_PERCENT,
            feeDenominator: UNISWAP_FEE_DENOMINATOR,
            kLast: kLast,
            ownerFeeShare: UNISWAP_OWNER_FEE_SHARE,
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
            feePercent: UNISWAP_FEE_PERCENT,
            feeDenominator: UNISWAP_FEE_DENOMINATOR,
            kLast: kLast,
            ownerFeeShare: UNISWAP_OWNER_FEE_SHARE,
            feeOn: feesEnabled,
            protocolFeeDenominator: 100000
        });
        uint256 quoted2 = ConstProdUtils._quoteZapOutToTargetWithFee(args2);
        assertEq(quoted2, 0, "Should return 0 when desired output is 0");

        uint256 maxPossibleOutput = _calculateMaxPossibleOutput(totalSupply, reserveTarget, reserveSale, UNISWAP_FEE_PERCENT, UNISWAP_FEE_DENOMINATOR);
        if (maxPossibleOutput > 0) {
            ConstProdUtils.ZapOutToTargetWithFeeArgs memory args3 = ConstProdUtils.ZapOutToTargetWithFeeArgs({
                desiredOut: maxPossibleOutput + 1,
                lpTotalSupply: totalSupply,
                reserveDesired: reserveTarget,
                reserveOther: reserveSale,
                feePercent: UNISWAP_FEE_PERCENT,
                feeDenominator: UNISWAP_FEE_DENOMINATOR,
                kLast: kLast,
                ownerFeeShare: UNISWAP_OWNER_FEE_SHARE,
                feeOn: feesEnabled,
                protocolFeeDenominator: 100000
            });
            uint256 quoted3 = ConstProdUtils._quoteZapOutToTargetWithFee(args3);
            assertEq(quoted3, 0, "Should return 0 when desired output exceeds maximum possible");
        }
    }

    function _calculateMaxPossibleOutput(
        uint256 lpTotalSupply,
        uint256 reserveTarget,
        uint256 reserveSale,
        uint256 feePercent,
        uint256 feeDenominator
    ) internal pure returns (uint256 maxOutput) {
        maxOutput = reserveTarget;
    }

    function _executeZapOutAndValidate(
        IUniswapV2Pair pair,
        ERC20PermitMintableStub targetToken,
        ERC20PermitMintableStub saleToken,
        uint256 lpAmount,
        uint256 expectedOut
    ) internal returns (uint256) {
        ExecData memory exec;

        exec.targetBefore = targetToken.balanceOf(address(this));
        exec.saleBefore = saleToken.balanceOf(address(this));

        pair.transfer(address(pair), lpAmount);
        (exec.amount0, exec.amount1) = pair.burn(address(this));

        address token0 = pair.token0();
        if (address(targetToken) == token0) {
            exec.targetAmount = exec.amount0;
            exec.saleAmount = exec.amount1;
        } else {
            exec.targetAmount = exec.amount1;
            exec.saleAmount = exec.amount0;
        }

        if (exec.saleAmount > 0) {
            (uint112 r0, uint112 r1,) = pair.getReserves();
            (uint256 soldReserve, uint256 procReserve) = address(saleToken) == token0 ? (r0, r1) : (r1, r0);
            uint256 feeMultiplier = UNISWAP_FEE_DENOMINATOR - UNISWAP_FEE_PERCENT;
            exec.proceeds = (exec.saleAmount * feeMultiplier * procReserve) / (soldReserve * UNISWAP_FEE_DENOMINATOR + exec.saleAmount * feeMultiplier);
            saleToken.transfer(address(pair), exec.saleAmount);
            (uint256 out0, uint256 out1) = address(saleToken) == token0 ? (uint256(0), exec.proceeds) : (exec.proceeds, uint256(0));
            pair.swap(out0, out1, address(this), new bytes(0));
            exec.targetAmount += exec.proceeds;
        }

        exec.targetAfter = targetToken.balanceOf(address(this));
        exec.saleAfter = saleToken.balanceOf(address(this));

        exec.actualTargetReceived = exec.targetAfter - exec.targetBefore;
        assertGeApproxEqRel(exec.actualTargetReceived, expectedOut, 1e14, "token out");

        return lpAmount;
    }

    function _setupUniswapFees(bool enableProtocolFees) internal {
        address feeSetter = uniswapV2FeeToSetter;
        if (enableProtocolFees) {
            vm.prank(feeSetter);
            UniV2Factory(address(uniswapV2Factory)).setFeeTo(feeSetter);
        } else {
            vm.prank(feeSetter);
            UniV2Factory(address(uniswapV2Factory)).setFeeTo(address(0));
        }
    }

    error AssertGeApproxEqRelFailed(string message, uint256 expected, uint256 actual, uint256 maxDelta, uint256 delta);

    function assertGeApproxEqRel(uint256 actual, uint256 expected, uint256 maxPercentDelta, string memory err) internal pure {
        if (expected == 0) {
            if (actual != 0) revert AssertGeApproxEqRelFailed(string(abi.encodePacked(err, ": expected is zero")), expected, actual, 0, 0);
            return;
        }
        if (actual < expected) revert AssertGeApproxEqRelFailed(string(abi.encodePacked(err, ": actual < expected")), expected, actual, 0, 0);
        uint256 maximumDelta = (expected * maxPercentDelta) / 1e18;
        uint256 delta = actual - expected;
        if (delta > maximumDelta) revert AssertGeApproxEqRelFailed("overage too large", expected, actual, maximumDelta, delta);
    }

}
