"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const numbers_1 = require("@balancer-labs/v3-helpers/src/numbers");
const constants_1 = require("@balancer-labs/v3-helpers/src/constants");
const contract_1 = require("@balancer-labs/v3-helpers/src/contract");
const relativeError_1 = require("@balancer-labs/v3-helpers/src/test/relativeError");
const sharedBeforeEach_1 = require("@balancer-labs/v3-common/sharedBeforeEach");
require("@balancer-labs/v3-common/setupTests");
const chai_1 = require("chai");
const base_1 = require("@balancer-labs/v3-helpers/src/math/base");
const SWAP_FEE = (0, numbers_1.fp)(0.01);
describe('BasePoolMath', function () {
    let math;
    (0, sharedBeforeEach_1.sharedBeforeEach)('deploy', async function () {
        math = await (0, contract_1.deploy)('LinearBasePoolMathMock');
    });
    it('test computeProportionalAmountsIn', async () => {
        const balances = [(0, numbers_1.fp)(100), (0, numbers_1.fp)(200)];
        const bptTotalSupply = (0, numbers_1.fp)(300);
        const bptAmountOut = (0, numbers_1.fp)(30);
        const expected = (0, base_1.computeProportionalAmountsIn)(balances, bptTotalSupply, bptAmountOut);
        const result = await math.computeProportionalAmountsIn(balances.map((balance) => (0, numbers_1.bn)((0, numbers_1.toFp)(balance))), (0, numbers_1.bn)((0, numbers_1.toFp)(bptTotalSupply)), (0, numbers_1.bn)((0, numbers_1.toFp)(bptAmountOut)));
        result.forEach((res, index) => {
            (0, chai_1.expect)(res).not.to.be.equal(0n, 'result is 0');
            (0, relativeError_1.expectEqualWithError)(res, (0, numbers_1.bn)((0, numbers_1.toFp)(expected[index])), constants_1.MAX_RELATIVE_ERROR, 'unexpected result');
        });
    });
    it('test computeProportionalAmountsOut', async () => {
        const balances = [(0, numbers_1.fp)(100), (0, numbers_1.fp)(200)];
        const bptTotalSupply = (0, numbers_1.fp)(300);
        const bptAmountIn = (0, numbers_1.fp)(30);
        const expected = (0, base_1.computeProportionalAmountsOut)(balances, bptTotalSupply, bptAmountIn);
        const result = await math.computeProportionalAmountsOut(balances.map((balance) => (0, numbers_1.bn)((0, numbers_1.toFp)(balance))), (0, numbers_1.bn)((0, numbers_1.toFp)(bptTotalSupply)), (0, numbers_1.bn)((0, numbers_1.toFp)(bptAmountIn)));
        result.forEach((res, index) => {
            (0, chai_1.expect)(res).not.to.be.equal(0n, 'result is 0');
            (0, relativeError_1.expectEqualWithError)(res, (0, numbers_1.bn)((0, numbers_1.toFp)(expected[index])), constants_1.MAX_RELATIVE_ERROR, 'unexpected result');
        });
    });
    it('test computeAddLiquidityUnbalanced', async () => {
        const currentBalances = [(0, numbers_1.fp)(100), (0, numbers_1.fp)(200)];
        const exactAmounts = [(0, numbers_1.fp)(10), (0, numbers_1.fp)(20)];
        const totalSupply = (0, numbers_1.fp)(300);
        const { bptAmountOut: expectedBptAmountOut, swapFeeAmounts: expectedSwapFeeAmounts } = (0, base_1.computeAddLiquidityUnbalanced)(currentBalances, exactAmounts, totalSupply, SWAP_FEE);
        const result = await math.computeAddLiquidityUnbalanced(currentBalances, exactAmounts, totalSupply, SWAP_FEE);
        (0, chai_1.expect)(result.bptAmountOut).not.to.be.equal(0n, 'bptAmountOut is 0');
        (0, relativeError_1.expectEqualWithError)(result.bptAmountOut, expectedBptAmountOut, constants_1.MAX_RELATIVE_ERROR, 'unexpected bptAmountOut');
        result.swapFeeAmounts.forEach((res, i) => {
            (0, relativeError_1.expectEqualWithError)(result.swapFeeAmounts[i], expectedSwapFeeAmounts[i], constants_1.MAX_RELATIVE_ERROR, 'unexpected swapFeeAmounts');
        });
    });
    it('test computeAddLiquiditySingleTokenExactOut', async () => {
        const currentBalances = [(0, numbers_1.fp)(100), (0, numbers_1.fp)(200)];
        const tokenInIndex = 0;
        const exactBptAmountOut = (0, numbers_1.fp)(30);
        const totalSupply = (0, numbers_1.fp)(300);
        const { amountInWithFee: expectedAmountInWithFee, swapFeeAmounts: expectedSwapFeeAmounts } = (0, base_1.computeAddLiquiditySingleTokenExactOut)(currentBalances, tokenInIndex, exactBptAmountOut, totalSupply, SWAP_FEE);
        const result = await math.computeAddLiquiditySingleTokenExactOut(currentBalances, tokenInIndex, exactBptAmountOut, totalSupply, SWAP_FEE);
        (0, chai_1.expect)(result.amountInWithFee).not.to.be.equal(0n, 'amountInWithFee is 0');
        (0, relativeError_1.expectEqualWithError)(result.amountInWithFee, expectedAmountInWithFee, constants_1.MAX_RELATIVE_ERROR, 'unexpected amountInWithFee');
        result.swapFeeAmounts.forEach((res, i) => {
            (0, relativeError_1.expectEqualWithError)(result.swapFeeAmounts[i], expectedSwapFeeAmounts[i], constants_1.MAX_RELATIVE_ERROR, 'unexpected swapFeeAmounts');
        });
    });
    it('test computeRemoveLiquiditySingleTokenExactOut', async () => {
        const currentBalances = [(0, numbers_1.fp)(100), (0, numbers_1.fp)(200)];
        const tokenOutIndex = 0;
        const exactAmountOut = (0, numbers_1.fp)(10);
        const totalSupply = (0, numbers_1.fp)(300);
        const { bptAmountIn: expectedBptAmountIn, swapFeeAmounts: expectedSwapFeeAmounts } = (0, base_1.computeRemoveLiquiditySingleTokenExactOut)(currentBalances, tokenOutIndex, exactAmountOut, totalSupply, SWAP_FEE);
        const result = await math.computeRemoveLiquiditySingleTokenExactOut(currentBalances, tokenOutIndex, exactAmountOut, totalSupply, SWAP_FEE);
        (0, chai_1.expect)(result.bptAmountIn).not.to.be.equal(0n, 'bptAmountIn is 0');
        (0, relativeError_1.expectEqualWithError)(result.bptAmountIn, expectedBptAmountIn, constants_1.MAX_RELATIVE_ERROR, 'unexpected bptAmountIn');
        result.swapFeeAmounts.forEach((res, i) => {
            (0, relativeError_1.expectEqualWithError)(result.swapFeeAmounts[i], expectedSwapFeeAmounts[i], constants_1.MAX_RELATIVE_ERROR, 'unexpected swapFeeAmounts');
        });
    });
    it('test computeRemoveLiquiditySingleTokenExactIn', async () => {
        const currentBalances = [(0, numbers_1.fp)(100), (0, numbers_1.fp)(200)];
        const tokenOutIndex = 0;
        const exactBptAmountIn = (0, numbers_1.fp)(30);
        const totalSupply = (0, numbers_1.fp)(300);
        const { amountOutWithFee: expectedAmountOutWithFee, swapFeeAmounts: expectedSwapFeeAmounts } = (0, base_1.computeRemoveLiquiditySingleTokenExactIn)(currentBalances, tokenOutIndex, exactBptAmountIn, totalSupply, SWAP_FEE);
        const result = await math.computeRemoveLiquiditySingleTokenExactIn(currentBalances, tokenOutIndex, exactBptAmountIn, totalSupply, SWAP_FEE);
        (0, chai_1.expect)(result.amountOutWithFee).not.to.be.equal(0n, 'amountOutWithFee is 0');
        (0, relativeError_1.expectEqualWithError)(result.amountOutWithFee, expectedAmountOutWithFee, constants_1.MAX_RELATIVE_ERROR, 'unexpected amountOutWithFee');
        result.swapFeeAmounts.forEach((res, i) => {
            (0, relativeError_1.expectEqualWithError)(result.swapFeeAmounts[i], expectedSwapFeeAmounts[i], constants_1.MAX_RELATIVE_ERROR, 'unexpected swapFeeAmounts');
        });
    });
});
