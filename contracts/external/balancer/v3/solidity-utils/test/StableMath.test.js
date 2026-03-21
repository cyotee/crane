"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const contract_1 = require("@balancer-labs/v3-helpers/src/contract");
const numbers_1 = require("@balancer-labs/v3-helpers/src/numbers");
const relativeError_1 = require("@balancer-labs/v3-helpers/src/test/relativeError");
const lodash_1 = require("lodash");
const stable_1 = require("@balancer-labs/v3-helpers/src/math/stable");
const MAX_RELATIVE_ERROR = 0.0001; // Max relative error
// TODO: Test this math by checking extremes values for the amplification field (0 and infinite)
// to verify that it equals constant sum and constant product (weighted) invariants.
describe('StableMath', function () {
    let mock;
    const AMP_PRECISION = (0, numbers_1.bn)(1e3);
    const MAX_TOKENS = 5;
    before(async function () {
        mock = await (0, contract_1.deploy)('StableMathMock');
    });
    context('invariant', () => {
        async function checkInvariant(balances, amp) {
            const ampParameter = (0, numbers_1.bn)(amp) * AMP_PRECISION;
            const actualInvariant = await mock.computeInvariant(ampParameter, balances, stable_1.Rounding.ROUND_DOWN);
            const expectedInvariant = (0, stable_1.calculateInvariant)(balances, amp, stable_1.Rounding.ROUND_DOWN);
            (0, relativeError_1.expectEqualWithError)(actualInvariant, expectedInvariant, MAX_RELATIVE_ERROR);
        }
        context('check over a range of inputs', () => {
            for (let numTokens = 2; numTokens <= MAX_TOKENS; numTokens++) {
                const balances = Array.from({ length: numTokens }, () => (0, lodash_1.random)(250, 350)).map(numbers_1.fp);
                it(`computes the invariant for ${numTokens} tokens`, async () => {
                    for (let amp = 100; amp <= 5000; amp += 100) {
                        await checkInvariant(balances, amp);
                    }
                });
            }
        });
        context('two tokens', () => {
            it('invariant equals analytical solution', async () => {
                const amp = (0, numbers_1.bn)(100);
                const balances = [(0, numbers_1.fp)(10), (0, numbers_1.fp)(12)];
                const result = await mock.computeInvariant(amp * AMP_PRECISION, balances, stable_1.Rounding.ROUND_DOWN);
                const expectedInvariant = (0, stable_1.calculateAnalyticalInvariantForTwoTokens)(balances, amp);
                (0, relativeError_1.expectEqualWithError)(result, expectedInvariant, MAX_RELATIVE_ERROR);
            });
        });
        it('still converges at extreme values', async () => {
            const amp = (0, numbers_1.bn)(1);
            const balances = [(0, numbers_1.fp)(0.00000001), (0, numbers_1.fp)(1200000000), (0, numbers_1.fp)(300)];
            const result = await mock.computeInvariant(amp * AMP_PRECISION, balances, stable_1.Rounding.ROUND_DOWN);
            const expectedInvariant = (0, stable_1.calculateInvariant)(balances, amp, stable_1.Rounding.ROUND_DOWN);
            (0, relativeError_1.expectEqualWithError)(result, expectedInvariant, MAX_RELATIVE_ERROR);
        });
    });
    context('token balance given invariant and other balances', () => {
        async function checkTokenBalanceGivenInvariant(balances, invariant, amp, tokenIndex) {
            const ampParameter = (0, numbers_1.bn)(amp) * AMP_PRECISION;
            const actualTokenBalance = await mock.computeBalance(ampParameter, balances, invariant, tokenIndex);
            // Note this function takes the decimal amp (unadjusted).
            const expectedTokenBalance = (0, stable_1.getTokenBalanceGivenInvariantAndAllOtherBalances)(amp, balances, invariant, tokenIndex);
            (0, relativeError_1.expectEqualWithError)(actualTokenBalance, expectedTokenBalance, MAX_RELATIVE_ERROR);
        }
        context('check over a range of inputs', () => {
            for (let numTokens = 2; numTokens <= MAX_TOKENS; numTokens++) {
                const balances = Array.from({ length: numTokens }, () => (0, lodash_1.random)(250, 350)).map(numbers_1.fp);
                it(`computes the token balance for ${numTokens} tokens`, async () => {
                    for (let amp = 100; amp <= 5000; amp += 100) {
                        const currentInvariant = (0, stable_1.calculateInvariant)(balances, amp, stable_1.Rounding.ROUND_DOWN);
                        // mutate the balances
                        for (let tokenIndex = 0; tokenIndex < numTokens; tokenIndex++) {
                            const newBalances = Object.assign([], balances);
                            newBalances[tokenIndex] = newBalances[tokenIndex] + (0, numbers_1.fp)(100);
                            await checkTokenBalanceGivenInvariant(newBalances, currentInvariant, amp, tokenIndex);
                        }
                    }
                });
            }
        });
    });
    context('in given exact out', () => {
        context('two tokens', () => {
            it('returns in given exact out', async () => {
                const amp = (0, numbers_1.bn)(100);
                const balances = Array.from({ length: 2 }, () => (0, lodash_1.random)(8, 12)).map(numbers_1.fp);
                const tokenIndexIn = 0;
                const tokenIndexOut = 1;
                const amountOut = (0, numbers_1.fp)(1);
                const invariant = (0, stable_1.calculateInvariant)(balances, amp, stable_1.Rounding.ROUND_DOWN);
                const result = await mock.computeInGivenExactOut(amp * AMP_PRECISION, balances, tokenIndexIn, tokenIndexOut, amountOut, invariant);
                const expectedAmountIn = (0, stable_1.calcInGivenExactOut)(balances, amp, tokenIndexIn, tokenIndexOut, amountOut);
                (0, relativeError_1.expectEqualWithError)(result, (0, numbers_1.bn)(expectedAmountIn.toFixed(0)), MAX_RELATIVE_ERROR);
            });
        });
        context('three tokens', () => {
            it('returns in given exact out', async () => {
                const amp = (0, numbers_1.bn)(100);
                const balances = Array.from({ length: 3 }, () => (0, lodash_1.random)(10, 14)).map(numbers_1.fp);
                const tokenIndexIn = 0;
                const tokenIndexOut = 1;
                const amountOut = (0, numbers_1.fp)(1);
                const invariant = (0, stable_1.calculateInvariant)(balances, amp, stable_1.Rounding.ROUND_DOWN);
                const result = await mock.computeInGivenExactOut(amp * AMP_PRECISION, balances, tokenIndexIn, tokenIndexOut, amountOut, invariant);
                const expectedAmountIn = (0, stable_1.calcInGivenExactOut)(balances, amp, tokenIndexIn, tokenIndexOut, amountOut);
                (0, relativeError_1.expectEqualWithError)(result, (0, numbers_1.bn)(expectedAmountIn.toFixed(0)), MAX_RELATIVE_ERROR);
            });
        });
    });
    context('out given exact in', () => {
        context('two tokens', () => {
            it('returns out given exact in', async () => {
                const amp = (0, numbers_1.bn)(10);
                const balances = Array.from({ length: 2 }, () => (0, lodash_1.random)(10, 12)).map(numbers_1.fp);
                const tokenIndexIn = 0;
                const tokenIndexOut = 1;
                const amountIn = (0, numbers_1.fp)(1);
                const invariant = (0, stable_1.calculateInvariant)(balances, amp, stable_1.Rounding.ROUND_DOWN);
                const result = await mock.computeOutGivenExactIn(amp * AMP_PRECISION, balances, tokenIndexIn, tokenIndexOut, amountIn, invariant);
                const expectedAmountOut = (0, stable_1.calcOutGivenExactIn)(balances, amp, tokenIndexIn, tokenIndexOut, amountIn);
                (0, relativeError_1.expectEqualWithError)(result, (0, numbers_1.bn)(expectedAmountOut.toFixed(0)), MAX_RELATIVE_ERROR);
            });
        });
        context('three tokens', () => {
            it('returns out given exact in', async () => {
                const amp = (0, numbers_1.bn)(10);
                const balances = Array.from({ length: 3 }, () => (0, lodash_1.random)(10, 14)).map(numbers_1.fp);
                const tokenIndexIn = 0;
                const tokenIndexOut = 1;
                const amountIn = (0, numbers_1.fp)(1);
                const invariant = (0, stable_1.calculateInvariant)(balances, amp, stable_1.Rounding.ROUND_DOWN);
                const result = await mock.computeOutGivenExactIn(amp * AMP_PRECISION, balances, tokenIndexIn, tokenIndexOut, amountIn, invariant);
                const expectedAmountOut = (0, stable_1.calcOutGivenExactIn)(balances, amp, tokenIndexIn, tokenIndexOut, amountIn);
                (0, relativeError_1.expectEqualWithError)(result, (0, numbers_1.bn)(expectedAmountOut.toFixed(0)), MAX_RELATIVE_ERROR);
            });
        });
    });
});
