"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const chai_1 = require("chai");
const numbers_1 = require("@balancer-labs/v3-helpers/src/numbers");
const relativeError_1 = require("@balancer-labs/v3-helpers/src/test/relativeError");
const sharedBeforeEach_1 = require("@balancer-labs/v3-common/sharedBeforeEach");
const contract_1 = require("@balancer-labs/v3-helpers/src/contract");
describe('ExpLog', () => {
    let lib;
    const MAX_X = 2n ** 255n - 1n;
    const MAX_Y = 2n ** 254n / 10n ** 20n - 1n;
    const LN_36_LOWER_BOUND = numbers_1.FP_ONE - (0, numbers_1.fp)(0.1);
    const LN_36_UPPER_BOUND = numbers_1.FP_ONE + (0, numbers_1.fp)(0.1);
    const MIN_NATURAL_EXPONENT = (0, numbers_1.fp)(-41);
    const MAX_NATURAL_EXPONENT = (0, numbers_1.fp)(130);
    const EXPECTED_RELATIVE_ERROR = 1e-14;
    (0, sharedBeforeEach_1.sharedBeforeEach)('deploy lib', async () => {
        lib = await (0, contract_1.deploy)('LogExpMathMock', { args: [] });
    });
    describe('pow', () => {
        describe('exponent zero', () => {
            const exponent = 0;
            it('handles base zero', async () => {
                const base = 0;
                (0, chai_1.expect)(await lib.pow(base, exponent)).to.be.equal(numbers_1.FP_ONE);
            });
            it('handles base one', async () => {
                const base = 1;
                (0, chai_1.expect)(await lib.pow(base, exponent)).to.be.equal(numbers_1.FP_ONE);
            });
            it('handles base greater than one', async () => {
                const base = 10;
                (0, chai_1.expect)(await lib.pow(base, exponent)).to.be.equal(numbers_1.FP_ONE);
            });
        });
        describe('base zero', () => {
            const base = 0;
            it('handles exponent zero', async () => {
                const exponent = 0;
                (0, chai_1.expect)(await lib.pow(base, exponent)).to.be.equal(numbers_1.FP_ONE);
            });
            it('handles exponent one', async () => {
                const exponent = 1;
                const expectedResult = 0;
                (0, chai_1.expect)(await lib.pow(base, exponent)).to.be.equal(expectedResult);
            });
            it('handles exponent greater than one', async () => {
                const exponent = 10;
                const expectedResult = 0;
                (0, chai_1.expect)(await lib.pow(base, exponent)).to.be.equal(expectedResult);
            });
        });
        describe('base one', () => {
            const base = 1;
            it('handles exponent zero', async () => {
                const exponent = 0;
                (0, chai_1.expect)(await lib.pow(base, exponent)).to.be.equal(numbers_1.FP_ONE);
            });
            it('handles exponent one', async () => {
                const exponent = 1;
                (0, relativeError_1.expectEqualWithError)(await lib.pow(base, exponent), numbers_1.FP_ONE, EXPECTED_RELATIVE_ERROR);
            });
            it('handles exponent greater than one', async () => {
                const exponent = 10;
                (0, relativeError_1.expectEqualWithError)(await lib.pow(base, exponent), numbers_1.FP_ONE, EXPECTED_RELATIVE_ERROR);
            });
        });
        describe('base and exponent greater than one', () => {
            it('handles base and exponent greater than one', async () => {
                const base = (0, numbers_1.fp)(2);
                const exponent = (0, numbers_1.fp)(2);
                const expectedResult = (0, numbers_1.fp)(4);
                (0, relativeError_1.expectEqualWithError)(await lib.pow(base, exponent), expectedResult, EXPECTED_RELATIVE_ERROR);
            });
        });
        describe('x between LN_36_LOWER_BOUND and LN_36_UPPER_BOUND', () => {
            it('handles x in the specific range properly', async () => {
                const base = (LN_36_LOWER_BOUND + LN_36_UPPER_BOUND) / 2n;
                // Choose an arbitrary exponent, like 2
                const exponent = 2;
                // 1^2 == 1
                (0, chai_1.expect)(await lib.pow(base, exponent)).to.be.equal(numbers_1.FP_ONE);
            });
        });
        describe('exponent as decimal', () => {
            it('handles decimals properly', async () => {
                const base = (0, numbers_1.fp)(2);
                const exponent = (0, numbers_1.fp)(0.5);
                const expectedResult = (0, numbers_1.fp)(Math.sqrt(2));
                const result = await lib.pow(base, exponent);
                (0, relativeError_1.expectEqualWithError)(result, expectedResult, EXPECTED_RELATIVE_ERROR);
            });
        });
        describe('decimals', () => {
            it('handles decimals properly', async () => {
                const base = (0, numbers_1.fp)(2);
                const exponent = (0, numbers_1.fp)(4);
                const expectedResult = (0, numbers_1.fp)(Math.pow(2, 4));
                const result = await lib.pow(base, exponent);
                (0, relativeError_1.expectEqualWithError)(result, expectedResult, EXPECTED_RELATIVE_ERROR);
            });
        });
        describe('max values', () => {
            it('cannot handle a product when logx_times_y > MAX_NATURAL_EXPONENT', async () => {
                const base = 2n ** 254n;
                const exponent = 10n ** 20n;
                await (0, chai_1.expect)(lib.pow(base, exponent)).to.be.revertedWithCustomError(lib, 'ProductOutOfBounds');
            });
            it('cannot handle a product when logx_times_y < MIN_NATURAL_EXPONENT', async () => {
                const base = 1;
                const exponent = 10n ** 20n;
                await (0, chai_1.expect)(lib.pow(base, exponent)).to.be.revertedWithCustomError(lib, 'ProductOutOfBounds');
            });
            it('cannot handle a base greater than 2^255 - 1', async () => {
                const base = MAX_X + 1n;
                const exponent = 1;
                await (0, chai_1.expect)(lib.pow(base, exponent)).to.be.revertedWithCustomError(lib, 'BaseOutOfBounds');
            });
            it('cannot handle an exponent greater than (2^254/1e20) - 1', async () => {
                const base = 1;
                const exponent = MAX_Y + 1n;
                await (0, chai_1.expect)(lib.pow(base, exponent)).to.be.revertedWithCustomError(lib, 'ExponentOutOfBounds');
            });
        });
    });
    describe('exp', () => {
        it('handles zero', async () => {
            const x = 0;
            (0, chai_1.expect)(await lib.exp(x)).to.be.equal(numbers_1.FP_ONE);
        });
        it('handles one', async () => {
            const x = (0, numbers_1.fp)(1);
            const expectedResult = (0, numbers_1.fp)(Math.E); // Since e^1 = e
            (0, relativeError_1.expectEqualWithError)(await lib.exp(x), expectedResult, EXPECTED_RELATIVE_ERROR);
        });
        it('handles negative input', async () => {
            const x = (0, numbers_1.fp)(-1);
            const expectedResult = (0, numbers_1.fp)(1 / Math.E); // Since e^-1 = 1/e
            (0, relativeError_1.expectEqualWithError)(await lib.exp(x), expectedResult, EXPECTED_RELATIVE_ERROR);
        });
        it('handles large positive input within the defined bounds', async () => {
            (0, relativeError_1.expectEqualWithError)(await lib.exp(MAX_NATURAL_EXPONENT), (0, numbers_1.fp)(Math.exp(Number(MAX_NATURAL_EXPONENT / numbers_1.FP_ONE))), EXPECTED_RELATIVE_ERROR);
        });
        it('handles large negative input within the defined bounds', async () => {
            (0, relativeError_1.expectEqualWithError)(await lib.exp(MIN_NATURAL_EXPONENT), (0, numbers_1.fp)(Math.exp(Number(MIN_NATURAL_EXPONENT / numbers_1.FP_ONE))), EXPECTED_RELATIVE_ERROR);
        });
        it('cannot handle input larger than MAX_NATURAL_EXPONENT', async () => {
            const x = MAX_NATURAL_EXPONENT + 1n;
            await (0, chai_1.expect)(lib.exp(x)).to.be.revertedWithCustomError(lib, 'InvalidExponent');
        });
        it('cannot handle input smaller than MIN_NATURAL_EXPONENT', async () => {
            const x = MIN_NATURAL_EXPONENT - 1n;
            await (0, chai_1.expect)(lib.exp(x)).to.be.revertedWithCustomError(lib, 'InvalidExponent');
        });
    });
    describe('log', () => {
        it('handles log base e (ln)', async () => {
            const arg = (0, numbers_1.fp)(10);
            const base = (0, numbers_1.fp)(Math.E);
            const expectedResult = (0, numbers_1.fp)(Math.log(10));
            (0, relativeError_1.expectEqualWithError)(await lib.log(arg, base), expectedResult, EXPECTED_RELATIVE_ERROR);
        });
        it('handles log base 10', async () => {
            const arg = (0, numbers_1.fp)(100);
            const base = (0, numbers_1.fp)(10);
            const expectedResult = (0, numbers_1.fp)(Math.log10(100));
            (0, relativeError_1.expectEqualWithError)(await lib.log(arg, base), expectedResult, EXPECTED_RELATIVE_ERROR);
        });
        it('handles arg within LN_36_LOWER_BOUND bounds', async () => {
            const arg = LN_36_LOWER_BOUND + 1n;
            const base = (0, numbers_1.fp)(10);
            (0, relativeError_1.expectEqualWithError)(await lib.log(arg, base), (0, numbers_1.fp)(Math.log10(0.9)), EXPECTED_RELATIVE_ERROR);
        });
        it('handles base within LN_36_LOWER_BOUND bounds', async () => {
            const arg = (0, numbers_1.fp)(100);
            const base = LN_36_LOWER_BOUND + 1n;
            (0, relativeError_1.expectEqualWithError)(await lib.log(arg, base), (0, numbers_1.fp)(Math.log(100) / Math.log(0.9)), EXPECTED_RELATIVE_ERROR);
        });
        it('handles arg larger than LN_36_UPPER_BOUND', async () => {
            const arg = LN_36_UPPER_BOUND + 1n;
            const base = (0, numbers_1.fp)(10);
            (0, relativeError_1.expectEqualWithError)(await lib.log(arg, base), (0, numbers_1.fp)(Math.log10(1.1)), EXPECTED_RELATIVE_ERROR);
        });
        it('handles base larger than LN_36_UPPER_BOUND', async () => {
            const arg = (0, numbers_1.fp)(100);
            const base = LN_36_UPPER_BOUND + 1n;
            (0, relativeError_1.expectEqualWithError)(await lib.log(arg, base), (0, numbers_1.fp)(Math.log(100) / Math.log(1.1)), EXPECTED_RELATIVE_ERROR);
        });
    });
    describe('ln', () => {
        it('handles ln of e', async () => {
            const a = (0, numbers_1.fp)(Math.E);
            const expectedResult = (0, numbers_1.fp)(Math.log(Math.E));
            (0, relativeError_1.expectEqualWithError)(await lib.ln(a), expectedResult, EXPECTED_RELATIVE_ERROR);
        });
        it('handles ln of 1', async () => {
            const a = numbers_1.FP_ONE;
            const expectedResult = 0; // ln(1) is 0
            (0, relativeError_1.expectEqualWithError)(await lib.ln(a), expectedResult, EXPECTED_RELATIVE_ERROR);
        });
        it('handles input within LN_36 bounds', async () => {
            const a = LN_36_LOWER_BOUND + 1n;
            (0, relativeError_1.expectEqualWithError)(await lib.ln(a), (0, numbers_1.fp)(Math.log(0.9)), EXPECTED_RELATIVE_ERROR);
        });
        it('handles input larger than LN_36_UPPER_BOUND', async () => {
            const a = LN_36_UPPER_BOUND + 1n;
            (0, relativeError_1.expectEqualWithError)(await lib.ln(a), (0, numbers_1.fp)(Math.log(1.1)), EXPECTED_RELATIVE_ERROR);
        });
        it('handles input equal to a3 * ONE_18', async () => {
            // eslint-disable-next-line @typescript-eslint/no-loss-of-precision
            const a3 = 888611052050787263676000000;
            const a = (0, numbers_1.fp)(a3);
            (0, relativeError_1.expectEqualWithError)(await lib.ln(a), (0, numbers_1.fp)(Math.log(a3)), EXPECTED_RELATIVE_ERROR);
        });
        it('handles input equal to a1 * ONE_18', async () => {
            // eslint-disable-next-line @typescript-eslint/no-loss-of-precision
            const a1 = 6235149080811616882910000000;
            const a = (0, numbers_1.fp)(a1);
            (0, relativeError_1.expectEqualWithError)(await lib.ln(a), (0, numbers_1.fp)(Math.log(a1)), EXPECTED_RELATIVE_ERROR);
        });
        it('throws OutOfBounds error for zero', async () => {
            const a = 0;
            await (0, chai_1.expect)(lib.ln(a)).to.be.revertedWithCustomError(lib, 'OutOfBounds');
        });
        it('throws OutOfBounds error for negative number', async () => {
            const a = -1;
            await (0, chai_1.expect)(lib.ln(a)).to.be.revertedWithCustomError(lib, 'OutOfBounds');
        });
    });
});
