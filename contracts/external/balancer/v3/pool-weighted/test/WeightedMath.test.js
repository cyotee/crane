"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const chai_1 = require("chai");
const numbers_1 = require("@balancer-labs/v3-helpers/src/numbers");
const constants_1 = require("@balancer-labs/v3-helpers/src/constants");
const contract_1 = require("@balancer-labs/v3-helpers/src/contract");
const relativeError_1 = require("@balancer-labs/v3-helpers/src/test/relativeError");
const sharedBeforeEach_1 = require("@balancer-labs/v3-common/sharedBeforeEach");
require("@balancer-labs/v3-common/setupTests");
const weighted_1 = require("@balancer-labs/v3-helpers/src/math/weighted");
var Rounding;
(function (Rounding) {
    Rounding[Rounding["ROUND_UP"] = 0] = "ROUND_UP";
    Rounding[Rounding["ROUND_DOWN"] = 1] = "ROUND_DOWN";
})(Rounding || (Rounding = {}));
describe('WeightedMath', function () {
    let math;
    (0, sharedBeforeEach_1.sharedBeforeEach)('deploy', async function () {
        math = await (0, contract_1.deploy)('WeightedMathMock');
    });
    context('computeInvariant', () => {
        it('reverts if zero invariant', async () => {
            await (0, chai_1.expect)(math.computeInvariant([(0, numbers_1.bn)(1)], [0], Rounding.ROUND_DOWN)).to.be.revertedWithCustomError(math, 'ZeroInvariant');
        });
        it('computes invariant for two tokens', async () => {
            const normalizedWeights = [(0, numbers_1.bn)(0.3e18), (0, numbers_1.bn)(0.7e18)];
            const balances = [(0, numbers_1.bn)(10e18), (0, numbers_1.bn)(12e18)];
            const result = await math.computeInvariant(normalizedWeights, balances, Rounding.ROUND_DOWN);
            const expected = (0, weighted_1.computeInvariant)(balances, normalizedWeights);
            (0, relativeError_1.expectEqualWithError)(result, (0, numbers_1.bn)(expected), constants_1.MAX_RELATIVE_ERROR);
        });
        it('computes invariant for three tokens', async () => {
            const normalizedWeights = [(0, numbers_1.bn)(0.3e18), (0, numbers_1.bn)(0.2e18), (0, numbers_1.bn)(0.5e18)];
            const balances = [(0, numbers_1.bn)(10e18), (0, numbers_1.bn)(12e18), (0, numbers_1.bn)(14e18)];
            const result = await math.computeInvariant(normalizedWeights, balances, Rounding.ROUND_DOWN);
            const expected = (0, weighted_1.computeInvariant)(balances, normalizedWeights);
            (0, relativeError_1.expectEqualWithError)(result, (0, numbers_1.bn)(expected), constants_1.MAX_RELATIVE_ERROR);
        });
    });
    describe('computeOutGivenExactIn', () => {
        it('computes correct outAmountPool', async () => {
            const tokenWeightIn = (0, numbers_1.bn)(50e18);
            const tokenWeightOut = (0, numbers_1.bn)(40e18);
            const tokenBalanceIn = (0, numbers_1.bn)(100e18);
            const roundedUpBalanceIn = (0, numbers_1.bn)(100.1e18);
            const roundedDownBalanceIn = (0, numbers_1.bn)(99.9e18);
            const tokenBalanceOut = (0, numbers_1.bn)(100e18);
            const roundedUpBalanceOut = (0, numbers_1.bn)(100.1e18);
            const roundedDownBalanceOut = (0, numbers_1.bn)(99.9e18);
            const tokenAmountIn = (0, numbers_1.bn)(15e18);
            const roundedUpAmountGiven = (0, numbers_1.bn)(15.01e18);
            const roundedDownAmountGiven = (0, numbers_1.bn)(14.99e18);
            const expected = (0, weighted_1.computeOutGivenExactIn)(tokenBalanceIn, tokenWeightIn, tokenBalanceOut, tokenWeightOut, tokenAmountIn);
            const result = await math.computeOutGivenExactIn(tokenBalanceIn, tokenWeightIn, tokenBalanceOut, tokenWeightOut, tokenAmountIn);
            (0, relativeError_1.expectEqualWithError)(result, expected, constants_1.MAX_RELATIVE_ERROR);
            const amountOutWithRoundedUpBalances = await math.computeOutGivenExactIn(roundedUpBalanceIn, tokenWeightIn, roundedUpBalanceOut, tokenWeightOut, tokenAmountIn);
            const amountOutWithRoundedDownBalances = await math.computeOutGivenExactIn(roundedDownBalanceIn, tokenWeightIn, roundedDownBalanceOut, tokenWeightOut, tokenAmountIn);
            // Ensure "rounding" the balances moves the amountOut in the expected direction.
            (0, chai_1.expect)(amountOutWithRoundedUpBalances).gt(result);
            (0, chai_1.expect)(amountOutWithRoundedDownBalances).lt(result);
            const amountOutWithRoundedUpAmountGiven = await math.computeOutGivenExactIn(tokenBalanceIn, tokenWeightIn, tokenBalanceOut, tokenWeightOut, roundedUpAmountGiven);
            const amountOutWithRoundedDownAmountGiven = await math.computeOutGivenExactIn(tokenBalanceIn, tokenWeightIn, tokenBalanceOut, tokenWeightOut, roundedDownAmountGiven);
            // Ensure "rounding" the amountIn moves the amountOut in the expected direction.
            (0, chai_1.expect)(amountOutWithRoundedUpAmountGiven).gt(result);
            (0, chai_1.expect)(amountOutWithRoundedDownAmountGiven).lt(result);
        });
        it('computes correct outAmountPool when tokenAmountIn is extremely small', async () => {
            const tokenBalanceIn = (0, numbers_1.bn)(100e18);
            const tokenWeightIn = (0, numbers_1.bn)(50e18);
            const tokenBalanceOut = (0, numbers_1.bn)(100e18);
            const tokenWeightOut = (0, numbers_1.bn)(40e18);
            const tokenAmountIn = (0, numbers_1.bn)(10e6); // (MIN AMOUNT = 0.00000000001)
            const expected = (0, weighted_1.computeOutGivenExactIn)(tokenBalanceIn, tokenWeightIn, tokenBalanceOut, tokenWeightOut, tokenAmountIn);
            const result = await math.computeOutGivenExactIn(tokenBalanceIn, tokenWeightIn, tokenBalanceOut, tokenWeightOut, tokenAmountIn);
            //TODO: review high rel error for small amount
            (0, relativeError_1.expectEqualWithError)(result, expected, 0.1);
        });
        it('computes correct outAmountPool when tokenWeightIn is extremely big', async () => {
            //Weight relation = 130.07
            const tokenBalanceIn = (0, numbers_1.bn)(100e18);
            const tokenWeightIn = (0, numbers_1.bn)(130.7e18);
            const tokenBalanceOut = (0, numbers_1.bn)(100e18);
            const tokenWeightOut = (0, numbers_1.bn)(1e18);
            const tokenAmountIn = (0, numbers_1.bn)(15e18);
            const expected = (0, weighted_1.computeOutGivenExactIn)(tokenBalanceIn, tokenWeightIn, tokenBalanceOut, tokenWeightOut, tokenAmountIn);
            const result = await math.computeOutGivenExactIn(tokenBalanceIn, tokenWeightIn, tokenBalanceOut, tokenWeightOut, tokenAmountIn);
            (0, relativeError_1.expectEqualWithError)(result, expected, constants_1.MAX_RELATIVE_ERROR);
        });
        it('computes correct outAmountPool when tokenWeightIn is extremely small', async () => {
            //Weight relation = 0.00769
            const tokenBalanceIn = (0, numbers_1.bn)(100e18);
            const tokenWeightIn = (0, numbers_1.bn)(0.00769e18);
            const tokenBalanceOut = (0, numbers_1.bn)(100e18);
            const tokenWeightOut = (0, numbers_1.bn)(1e18);
            const tokenAmountIn = (0, numbers_1.bn)(15e18);
            const expected = (0, weighted_1.computeOutGivenExactIn)(tokenBalanceIn, tokenWeightIn, tokenBalanceOut, tokenWeightOut, tokenAmountIn);
            const result = await math.computeOutGivenExactIn(tokenBalanceIn, tokenWeightIn, tokenBalanceOut, tokenWeightOut, tokenAmountIn);
            (0, relativeError_1.expectEqualWithError)(result, expected, constants_1.MAX_RELATIVE_ERROR);
        });
        it('throws MaxInRatio error when tokenAmountIn exceeds maximum allowed', async () => {
            const tokenBalanceIn = (0, numbers_1.bn)(100e18);
            const tokenWeightIn = (0, numbers_1.bn)(50e18);
            const tokenBalanceOut = (0, numbers_1.bn)(100e18);
            const tokenWeightOut = (0, numbers_1.bn)(40e18);
            // The amount in exceeds the maximum in ratio (i.e. tokenBalanceIn * MAX_IN_RATIO)
            const tokenAmountIn = tokenBalanceIn * constants_1.MAX_IN_RATIO + 1n; // Just slightly greater than maximum allowed
            await (0, chai_1.expect)(math.computeOutGivenExactIn(tokenBalanceIn, tokenWeightIn, tokenBalanceOut, tokenWeightOut, tokenAmountIn)).to.be.revertedWithCustomError(math, 'MaxInRatio');
        });
    });
    describe('computeInGivenExactOut', () => {
        it('computes correct result', async () => {
            const tokenWeightIn = (0, numbers_1.bn)(50e18);
            const tokenWeightOut = (0, numbers_1.bn)(40e18);
            const tokenBalanceIn = (0, numbers_1.bn)(100e18);
            const roundedUpBalanceIn = (0, numbers_1.bn)(100.1e18);
            const roundedDownBalanceIn = (0, numbers_1.bn)(99.9e18);
            const tokenBalanceOut = (0, numbers_1.bn)(100e18);
            const roundedUpBalanceOut = (0, numbers_1.bn)(100.1e18);
            const roundedDownBalanceOut = (0, numbers_1.bn)(99.9e18);
            const tokenAmountOut = (0, numbers_1.bn)(15e18);
            const roundedUpAmountGiven = (0, numbers_1.bn)(15.01e18);
            const roundedDownAmountGiven = (0, numbers_1.bn)(14.99e18);
            const expected = (0, weighted_1.computeInGivenExactOut)(tokenBalanceIn, tokenWeightIn, tokenBalanceOut, tokenWeightOut, tokenAmountOut);
            const result = await math.computeInGivenExactOut(tokenBalanceIn, tokenWeightIn, tokenBalanceOut, tokenWeightOut, tokenAmountOut);
            (0, relativeError_1.expectEqualWithError)(result, expected, constants_1.MAX_RELATIVE_ERROR);
            const amountInWithRoundedUpBalances = await math.computeInGivenExactOut(roundedUpBalanceIn, tokenWeightIn, roundedUpBalanceOut, tokenWeightOut, tokenAmountOut);
            const amountInWithRoundedDownBalances = await math.computeInGivenExactOut(roundedDownBalanceIn, tokenWeightIn, roundedDownBalanceOut, tokenWeightOut, tokenAmountOut);
            // Ensure "rounding" the balances moves the amountIn in the expected direction.
            (0, chai_1.expect)(amountInWithRoundedUpBalances).lt(result);
            (0, chai_1.expect)(amountInWithRoundedDownBalances).gt(result);
            const amountInWithRoundedUpAmountGiven = await math.computeInGivenExactOut(tokenBalanceIn, tokenWeightIn, tokenBalanceOut, tokenWeightOut, roundedUpAmountGiven);
            const amountInWithRoundedDownAmountGiven = await math.computeInGivenExactOut(tokenBalanceIn, tokenWeightIn, tokenBalanceOut, tokenWeightOut, roundedDownAmountGiven);
            // Ensure "rounding" the amountGiven moves the amountOut in the expected direction.
            (0, chai_1.expect)(amountInWithRoundedUpAmountGiven).gt(result);
            (0, chai_1.expect)(amountInWithRoundedDownAmountGiven).lt(result);
        });
        it('computes correct inAmountPool when tokenAmountOut is extremely small', async () => {
            const tokenBalanceIn = (0, numbers_1.bn)(100e18);
            const tokenWeightIn = (0, numbers_1.bn)(50e18);
            const tokenBalanceOut = (0, numbers_1.bn)(100e18);
            const tokenWeightOut = (0, numbers_1.bn)(40e18);
            const tokenAmountOut = (0, numbers_1.bn)(10e6); // (MIN AMOUNT = 0.00000000001)
            const expected = (0, weighted_1.computeInGivenExactOut)(tokenBalanceIn, tokenWeightIn, tokenBalanceOut, tokenWeightOut, tokenAmountOut);
            const result = await math.computeInGivenExactOut(tokenBalanceIn, tokenWeightIn, tokenBalanceOut, tokenWeightOut, tokenAmountOut);
            //TODO: review high rel error for small amount
            (0, relativeError_1.expectEqualWithError)(result, expected, 0.5);
        });
        it('throws MaxOutRatio error when amountOut exceeds maximum allowed', async () => {
            const tokenBalanceIn = (0, numbers_1.bn)(100e18);
            const tokenWeightIn = (0, numbers_1.bn)(50e18);
            const tokenBalanceOut = (0, numbers_1.bn)(100e18);
            const tokenWeightOut = (0, numbers_1.bn)(40e18);
            // The amount in exceeds the maximum in ratio (i.e. tokenBalanceIn * MAX_IN_RATIO)
            const tokenAmountOut = tokenBalanceOut * constants_1.MAX_OUT_RATIO + 1n; // Just slightly greater than maximum allowed
            await (0, chai_1.expect)(math.computeInGivenExactOut(tokenBalanceIn, tokenWeightIn, tokenBalanceOut, tokenWeightOut, tokenAmountOut)).to.be.revertedWithCustomError(math, 'MaxOutRatio');
        });
    });
});
