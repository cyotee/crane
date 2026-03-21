"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const chai_1 = require("chai");
const contract_1 = require("@balancer-labs/v3-helpers/src/contract");
const surgeMedianMath_1 = require("@balancer-labs/v3-helpers/src/math/surgeMedianMath");
describe('StableSurgeMedianMath', function () {
    const MIN_TOKENS = 2;
    const MAX_TOKENS = 8;
    const TEST_ITERATIONS = 100;
    const MAX_VALUE = 100000;
    let surgeMath;
    function getRandomInt(min, max) {
        return Math.floor(Math.random() * (max - min + 1)) + min;
    }
    before('deploy mock', async () => {
        surgeMath = await (0, contract_1.deploy)('v3-pool-hooks/test/StableSurgeMedianMathMock');
    });
    it('absSub', async () => {
        for (let i = 0; i < TEST_ITERATIONS; i++) {
            const a = getRandomInt(0, MAX_VALUE);
            const b = getRandomInt(0, MAX_VALUE);
            const expectedResult = Math.abs(a - b);
            (0, chai_1.expect)(await surgeMath.absSub(a, b)).to.eq(expectedResult);
            (0, chai_1.expect)(await surgeMath.absSub(b, a)).to.eq(expectedResult);
        }
    });
    it('findMedian', async () => {
        const worthCaseOne = [800, 700, 600, 500, 400, 300, 200, 100];
        const worthCaseTwo = worthCaseOne.reverse();
        (0, chai_1.expect)(Number(await surgeMath.findMedian(worthCaseOne))).to.eq(450);
        (0, chai_1.expect)(Number(await surgeMath.findMedian(worthCaseTwo))).to.eq(450);
        for (let i = 0; i < TEST_ITERATIONS; i++) {
            const randomCase = new Array(getRandomInt(MIN_TOKENS, MAX_TOKENS)).fill(0).map(() => getRandomInt(0, MAX_VALUE));
            (0, chai_1.expect)(Number(await surgeMath.findMedian(randomCase))).to.eq((0, surgeMedianMath_1.findMedian)(randomCase));
        }
    });
    it('calculateImbalance', async () => {
        for (let i = 0; i < TEST_ITERATIONS; i++) {
            const randomBalances = new Array(getRandomInt(MIN_TOKENS, MAX_TOKENS))
                .fill(0)
                .map(() => getRandomInt(0, MAX_VALUE));
            const median = (0, surgeMedianMath_1.findMedian)(randomBalances);
            let totalDiff = 0;
            let totalBalance = 0;
            for (let i = 0; i < randomBalances.length; i++) {
                totalBalance += randomBalances[i];
                totalDiff += Math.abs(randomBalances[i] - median);
            }
            const expectedResult = (BigInt(totalDiff) * BigInt(1e18)) / BigInt(totalBalance);
            (0, chai_1.expect)(Number(await surgeMath.calculateImbalance(randomBalances))).to.eq(Number(expectedResult));
        }
    });
});
