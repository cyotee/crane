"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const chai_1 = require("chai");
const contract_1 = require("@balancer-labs/v3-helpers/src/contract");
const numbers_1 = require("@balancer-labs/v3-helpers/src/numbers");
const constants_1 = require("@balancer-labs/v3-helpers/src/constants");
const relativeError_1 = require("@balancer-labs/v3-helpers/src/test/relativeError");
const sharedBeforeEach_1 = require("@balancer-labs/v3-common/sharedBeforeEach");
describe('FixedPoint', () => {
    let lib;
    const ONE = (0, numbers_1.fp)(1);
    const TWO = (0, numbers_1.fp)(2);
    const EXPECTED_RELATIVE_ERROR = 1e-14;
    const valuesPow4 = [
        0.0007, 0.0022, 0.093, 2.9, 13.3, 450.8, 1550.3339, 69039.11, 7834839.432, 83202933.5433, 9983838318.4,
        15831567871.1,
    ];
    const valuesPow2 = [
        8e-9,
        0.0000013,
        0.000043,
        ...valuesPow4,
        8382392893832.1,
        38859321075205.1,
        (0, numbers_1.decimal)('848205610278492.2383'),
        (0, numbers_1.decimal)('371328129389320282.3783289'),
    ];
    const valuesPow1 = [
        1.7e-18,
        1.7e-15,
        1.7e-11,
        ...valuesPow2,
        (0, numbers_1.decimal)('701847104729761867823532.139'),
        (0, numbers_1.decimal)('175915239864219235419349070.947'),
    ];
    (0, sharedBeforeEach_1.sharedBeforeEach)('deploy lib', async () => {
        lib = await (0, contract_1.deploy)('FixedPointMock', { args: [] });
    });
    const checkPow = async (x, pow) => {
        const result = (0, numbers_1.fp)(x.pow(pow));
        (0, relativeError_1.expectEqualWithError)(await lib.powDown((0, numbers_1.fp)(x), (0, numbers_1.fp)(pow)), result, EXPECTED_RELATIVE_ERROR);
        (0, relativeError_1.expectEqualWithError)(await lib.powUp((0, numbers_1.fp)(x), (0, numbers_1.fp)(pow)), result, EXPECTED_RELATIVE_ERROR);
    };
    const checkPows = async (pow, values) => {
        for (const value of values) {
            it(`handles ${value}`, async () => {
                await checkPow((0, numbers_1.decimal)(value), pow);
            });
        }
    };
    describe('powUp/powDown', () => {
        context('non-fractional pow 1', () => {
            checkPows(1, valuesPow1);
        });
        context('non-fractional pow 2', async () => {
            checkPows(2, valuesPow2);
        });
        context('non-fractional pow 4', async () => {
            checkPows(4, valuesPow4);
        });
    });
    describe('mulDown', () => {
        it('multiplies 0 and 0 correctly', async () => {
            (0, chai_1.expect)(await lib.mulDown((0, numbers_1.fp)(0), (0, numbers_1.fp)(0))).to.equal((0, numbers_1.fp)(0));
        });
        it('multiplies 1 and 1 correctly', async () => {
            (0, chai_1.expect)(await lib.mulDown((0, numbers_1.fp)(1), (0, numbers_1.fp)(1))).to.equal((0, numbers_1.fp)(1));
        });
        it('returns product when both factors are not 0', async function () {
            (0, chai_1.expect)(await lib.mulDown(ONE, (0, numbers_1.fp)(42))).to.equal((0, numbers_1.fp)(42));
            (0, chai_1.expect)(await lib.mulDown((0, numbers_1.fp)(42), ONE)).to.equal((0, numbers_1.fp)(42));
        });
        it('reverts on overflow', async function () {
            await (0, chai_1.expect)(lib.mulDown(constants_1.MAX_UINT256, TWO)).to.be.revertedWithPanic(constants_1.ARITHMETIC_FLOW_PANIC);
        });
    });
    describe('mulUp', () => {
        it('multiplies 0 and 0 correctly', async () => {
            (0, chai_1.expect)(await lib.mulUp((0, numbers_1.fp)(0), (0, numbers_1.fp)(0))).to.equal((0, numbers_1.fp)(0));
        });
        it('multiplies 1 and 1 correctly', async () => {
            (0, chai_1.expect)(await lib.mulUp((0, numbers_1.fp)(1), (0, numbers_1.fp)(1))).to.equal((0, numbers_1.fp)(1));
        });
        it('reverts on overflow', async function () {
            await (0, chai_1.expect)(lib.mulUp(constants_1.MAX_UINT256, TWO)).to.be.revertedWithPanic(constants_1.ARITHMETIC_FLOW_PANIC);
        });
        it('returns product when both factors are not 0', async function () {
            (0, chai_1.expect)(await lib.mulUp(ONE, (0, numbers_1.fp)(42))).to.equal((0, numbers_1.fp)(42));
            (0, chai_1.expect)(await lib.mulUp((0, numbers_1.fp)(42), ONE)).to.equal((0, numbers_1.fp)(42));
        });
    });
    describe('divDown', () => {
        it('divides 0 by 1 correctly', async () => {
            (0, chai_1.expect)(await lib.divDown((0, numbers_1.fp)(0), (0, numbers_1.fp)(1))).to.equal((0, numbers_1.fp)(0));
        });
        it('divides 1 by 1 correctly', async () => {
            (0, chai_1.expect)(await lib.divDown((0, numbers_1.fp)(1), (0, numbers_1.fp)(1))).to.equal((0, numbers_1.fp)(1));
        });
        it('divides large number by itself correctly', async () => {
            const largeNumber = (0, numbers_1.decimal)('1e18').mul(Math.random());
            (0, chai_1.expect)(await lib.divDown((0, numbers_1.fp)(largeNumber), (0, numbers_1.fp)(largeNumber))).to.equal((0, numbers_1.fp)(1));
        });
        it('reverts on underflow', async function () {
            await (0, chai_1.expect)(lib.divDown(constants_1.MAX_UINT256, ONE)).to.be.revertedWithPanic(constants_1.ARITHMETIC_FLOW_PANIC);
        });
        it('should revert on division by zero', async () => {
            await (0, chai_1.expect)(lib.divDown((0, numbers_1.fp)(1), (0, numbers_1.fp)(0))).to.be.revertedWithPanic(constants_1.DIVISION_BY_ZERO_PANIC);
        });
    });
    describe('divUp', () => {
        it('divides 0 by 1 correctly', async () => {
            (0, chai_1.expect)(await lib.divUp((0, numbers_1.fp)(0), (0, numbers_1.fp)(1))).to.equal((0, numbers_1.fp)(0));
        });
        it('divides 1 by 1 correctly', async () => {
            (0, chai_1.expect)(await lib.divUp((0, numbers_1.fp)(1), (0, numbers_1.fp)(1))).to.equal((0, numbers_1.fp)(1));
        });
        it('divides large number by itself correctly', async () => {
            const largeNumber = (0, numbers_1.decimal)('1e18');
            (0, chai_1.expect)(await lib.divUp((0, numbers_1.fp)(largeNumber), (0, numbers_1.fp)(largeNumber))).to.equal((0, numbers_1.fp)(1));
        });
        it('returns quotient when divisor is not 0', async function () {
            (0, chai_1.expect)(await lib.divUp((0, numbers_1.fp)(42), ONE)).to.equal((0, numbers_1.fp)(42));
        });
        it('should revert on division by zero', async () => {
            await (0, chai_1.expect)(lib.divUp((0, numbers_1.fp)(1), (0, numbers_1.fp)(0))).to.be.revertedWithCustomError(lib, 'ZeroDivision');
        });
    });
    describe('complement', () => {
        it('returns the correct complement for 0', async () => {
            (0, chai_1.expect)(await lib.complement((0, numbers_1.fp)(0))).to.equal((0, numbers_1.fp)(1));
        });
        it('returns the correct complement for 0.3', async () => {
            (0, chai_1.expect)(await lib.complement((0, numbers_1.fp)(0.3))).to.equal((0, numbers_1.fp)(0.7));
        });
        it('returns the correct complement for 1', async () => {
            (0, chai_1.expect)(await lib.complement((0, numbers_1.fp)(1))).to.equal((0, numbers_1.fp)(0));
        });
        it('returns the correct complement for a number greater than 1', async () => {
            (0, chai_1.expect)(await lib.complement((0, numbers_1.fp)(2))).to.equal((0, numbers_1.fp)(0));
        });
    });
    describe('powDown', () => {
        it('returns the correct power for base 0', async () => {
            (0, chai_1.expect)(await lib.powDown((0, numbers_1.fp)(0), (0, numbers_1.fp)(2))).to.equal((0, numbers_1.fp)(0));
        });
        it('returns the correct power for base 1', async () => {
            (0, chai_1.expect)(await lib.powDown((0, numbers_1.fp)(1), (0, numbers_1.fp)(2))).to.equal((0, numbers_1.fp)(1));
        });
        it('returns the correct power for base 2 power 2', async () => {
            (0, chai_1.expect)(await lib.powDown((0, numbers_1.fp)(2), (0, numbers_1.fp)(2))).to.equal((0, numbers_1.fp)(4));
        });
        it('returns the correct power for base 2 power 4', async () => {
            (0, chai_1.expect)(await lib.powDown((0, numbers_1.fp)(2), (0, numbers_1.fp)(4))).to.equal((0, numbers_1.fp)(16));
        });
        it('returns the correct power for large base and exponent', async () => {
            const base = (0, numbers_1.decimal)('1e18');
            const exponent = 3;
            // TODO: Precision seems to differ for powDow and powUp. Should check this.
            (0, relativeError_1.expectEqualWithError)(await lib.powDown((0, numbers_1.fp)(base), (0, numbers_1.fp)(exponent)), (0, numbers_1.fp)(base.pow(exponent)), 1e-13);
        });
        it('returns 0 when result is less than maxError', async function () {
            // These x and y values need to be found experimentally such that 0 < x^y < MAX_POW_RELATIVE_ERROR
            const x = 0;
            const y = 1;
            (0, chai_1.expect)(await lib.powDown(x, y)).to.equal(0);
        });
    });
    describe('powUp', () => {
        it('returns the correct power for base 0', async () => {
            (0, chai_1.expect)(await lib.powUp((0, numbers_1.fp)(0), (0, numbers_1.fp)(2))).to.equal((0, numbers_1.fp)(0));
        });
        it('returns the correct power for base 1', async () => {
            (0, chai_1.expect)(await lib.powUp((0, numbers_1.fp)(1), (0, numbers_1.fp)(2))).to.equal((0, numbers_1.fp)(1));
        });
        it('returns the correct power for base 2 power 2', async () => {
            (0, relativeError_1.expectEqualWithError)(await lib.powUp((0, numbers_1.fp)(2), (0, numbers_1.fp)(2)), (0, numbers_1.fp)(4), EXPECTED_RELATIVE_ERROR);
        });
        it('returns the correct power for large base and exponent', async () => {
            const base = (0, numbers_1.decimal)('1e18');
            const exponent = 3;
            (0, relativeError_1.expectEqualWithError)(await lib.powUp((0, numbers_1.fp)(base), (0, numbers_1.fp)(exponent)), (0, numbers_1.fp)(base.pow(exponent)), EXPECTED_RELATIVE_ERROR);
        });
    });
});
