// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";
import {TestBase_ConstProdUtils_Uniswap} from "./TestBase_ConstProdUtils_Uniswap.sol";
import {IUniswapV2Pair} from "contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Pair.sol";
import {ERC20PermitMintableStub} from "contracts/tokens/ERC20/ERC20PermitMintableStub.sol";

contract ConstProdUtils_quoteZapOutLP_Uniswap is TestBase_ConstProdUtils_Uniswap {
    function setUp() public override {
        super.setUp();
    }


    function test_quoteZapOutLP_Uniswap_balancedPool_simple() public {
        _initializeUniswapBalancedPools();

        IUniswapV2Pair pair = uniswapBalancedPair;
        (uint112 r0, uint112 r1,) = pair.getReserves();
        uint256 totalSupply = pair.totalSupply();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(address(uniswapBalancedTokenA), pair.token0(), r0, r1);

        uint256 desiredOut = reserveA / 10; // 10%

        ConstProdUtils.ZapOutToTargetWithFeeArgs memory args = ConstProdUtils.ZapOutToTargetWithFeeArgs({
            desiredOut: desiredOut,
            lpTotalSupply: totalSupply,
            reserveDesired: reserveA,
            reserveOther: reserveB,
            feePercent: 300,
            feeDenominator: 100000,
            kLast: pair.kLast(),
            ownerFeeShare: 16666,
            feeOn: false,
            protocolFeeDenominator: 100000
        });

        uint256 quoted = ConstProdUtils._quoteZapOutToTargetWithFee(args);
        assertTrue(quoted > 0, "quoted > 0");
        assertTrue(quoted <= totalSupply, "quoted <= totalSupply");

        // Execute and validate we receive at least desiredOut
        // Execute zap-out and validate quoted amount produces the expected output
        uint256 actualLp = _executeZapOutAndValidate(pair, uniswapBalancedTokenA, uniswapBalancedTokenB, quoted, desiredOut, 300, 100000);
        assertEq(quoted, actualLp, "quoted == actualLp");
    }

    function test_quoteZapOutLP_Uniswap_unbalancedPool_simple() public {
        _initializeUniswapUnbalancedPools();

        IUniswapV2Pair pair = uniswapUnbalancedPair;
        (uint112 r0, uint112 r1,) = pair.getReserves();
        uint256 totalSupply = pair.totalSupply();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(address(uniswapUnbalancedTokenA), pair.token0(), r0, r1);

        uint256 desiredOut = reserveA / 10; // 10%

        ConstProdUtils.ZapOutToTargetWithFeeArgs memory args = ConstProdUtils.ZapOutToTargetWithFeeArgs({
            desiredOut: desiredOut,
            lpTotalSupply: totalSupply,
            reserveDesired: reserveA,
            reserveOther: reserveB,
            feePercent: 300,
            feeDenominator: 100000,
            kLast: pair.kLast(),
            ownerFeeShare: 16666,
            feeOn: false,
            protocolFeeDenominator: 100000
        });

        uint256 quoted = ConstProdUtils._quoteZapOutToTargetWithFee(args);
        assertTrue(quoted > 0, "quoted > 0");
        assertTrue(quoted <= totalSupply, "quoted <= totalSupply");

        uint256 actualLp = _executeZapOutAndValidate(pair, uniswapUnbalancedTokenA, uniswapUnbalancedTokenB, quoted, desiredOut, 300, 100000);
        assertEq(quoted, actualLp, "quoted == actualLp");
    }

    function test_quoteZapOutLP_Uniswap_extremeUnbalancedPool_simple() public {
        _initializeUniswapExtremeUnbalancedPools();

        IUniswapV2Pair pair = uniswapExtremeUnbalancedPair;
        (uint112 r0, uint112 r1,) = pair.getReserves();
        uint256 totalSupply = pair.totalSupply();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(address(uniswapExtremeTokenA), pair.token0(), r0, r1);

        uint256 desiredOut = reserveA / 10; // 10%

        ConstProdUtils.ZapOutToTargetWithFeeArgs memory args = ConstProdUtils.ZapOutToTargetWithFeeArgs({
            desiredOut: desiredOut,
            lpTotalSupply: totalSupply,
            reserveDesired: reserveA,
            reserveOther: reserveB,
            feePercent: 300,
            feeDenominator: 100000,
            kLast: pair.kLast(),
            ownerFeeShare: 16666,
            feeOn: false,
            protocolFeeDenominator: 100000
        });

        uint256 quoted = ConstProdUtils._quoteZapOutToTargetWithFee(args);
        assertTrue(quoted > 0, "quoted > 0");
        assertTrue(quoted <= totalSupply, "quoted <= totalSupply");

        uint256 actualLp = _executeZapOutAndValidate(pair, uniswapExtremeTokenA, uniswapExtremeTokenB, quoted, desiredOut, 300, 100000);
        assertEq(quoted, actualLp, "quoted == actualLp");
    }

    function _buildPath(address a, address b) internal pure returns (address[] memory path) {
        path = new address[](2);
        path[0] = a;
        path[1] = b;
    }

    function _swapSaleToTarget(
        IUniswapV2Pair pair,
        ERC20PermitMintableStub saleToken,
        address token0,
        uint256 saleAmount,
        uint256 feePercent,
        uint256 feeDenominator
    ) internal returns (uint256 proceeds) {
        (uint112 r0, uint112 r1,) = pair.getReserves();
        (uint256 soldReserve, uint256 procReserve) = address(saleToken) == token0 ? (r0, r1) : (r1, r0);
        uint256 feeMultiplier = feeDenominator - feePercent;
        proceeds = (saleAmount * feeMultiplier * procReserve) / (soldReserve * feeDenominator + saleAmount * feeMultiplier);
        saleToken.transfer(address(pair), saleAmount);
        (uint256 out0, uint256 out1) = address(saleToken) == token0 ? (uint256(0), proceeds) : (proceeds, uint256(0));
        pair.swap(out0, out1, address(this), new bytes(0));
    }

    // Execute zap-out (burn + optional swap) and validate the received target tokens roughly equal expectedOut.
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

    function _executeZapOutAndValidate(
        IUniswapV2Pair pair,
        ERC20PermitMintableStub targetToken,
        ERC20PermitMintableStub saleToken,
        uint256 lpAmount,
        uint256 expectedOut,
        uint256 feePercent,
        uint256 feeDenominator
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
            exec.proceeds = _swapSaleToTarget(pair, saleToken, token0, exec.saleAmount, feePercent, feeDenominator);
            exec.targetAmount += exec.proceeds;
        }

        exec.targetAfter = targetToken.balanceOf(address(this));
        exec.saleAfter = saleToken.balanceOf(address(this));

        exec.actualTargetReceived = exec.targetAfter - exec.targetBefore;
        // allow a small relative tolerance for rounding
        _assertGeApproxEqRel(exec.actualTargetReceived, expectedOut, 1e14, "token out");

        return lpAmount;
    }

    error AssertGeApproxEqRelFailed(string message, uint256 expected, uint256 actual, uint256 maxDelta, uint256 delta);

    function _assertGeApproxEqRel(uint256 actual, uint256 expected, uint256 maxPercentDelta, string memory err) internal pure {
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
