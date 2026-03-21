"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const chai_1 = require("chai");
const ethers_1 = require("ethers");
const numbers_1 = require("@balancer-labs/v3-helpers/src/numbers");
const lodash_1 = require("lodash");
const contract_1 = require("@balancer-labs/v3-helpers/src/contract");
const constants_1 = require("@balancer-labs/v3-helpers/src/constants");
describe('WordCodec', () => {
    let lib;
    before('deploy lib', async () => {
        lib = await (0, contract_1.deploy)('WordCodecMock');
    });
    function getMaxUnsigned(bits) {
        return (constants_1.ONE << BigInt(bits)) - constants_1.ONE;
    }
    function getMaxSigned(bits) {
        return (constants_1.ONE << BigInt(bits - 1)) - constants_1.ONE;
    }
    function getMinSigned(bits) {
        return (constants_1.ONE << BigInt(bits - 1)) * BigInt(-constants_1.ONE);
    }
    describe('encode', () => {
        describe('unsigned', () => {
            it('reverts with zero bit length', async () => {
                await (0, chai_1.expect)(lib.encodeUint(0, 0, 0)).to.be.revertedWithCustomError(lib, 'OutOfBounds');
            });
            it('reverts with 256 bit length', async () => {
                await (0, chai_1.expect)(lib.encodeUint(0, 0, 256)).to.be.revertedWithCustomError(lib, 'OutOfBounds');
            });
            it('reverts with large offset', async () => {
                await (0, chai_1.expect)(lib.encodeUint(0, 256, 0)).to.be.revertedWithCustomError(lib, 'OutOfBounds');
            });
            async function assertUnsignedEncoding(value, offset, bits) {
                const result = await lib.encodeUint(value, offset, bits);
                // We must be able to restore the original value.
                (0, chai_1.expect)(await lib.decodeUint(result, offset, bits)).to.equal(value);
                // All other bits should be clear
                (0, chai_1.expect)((0, numbers_1.negate)(((constants_1.ONE << BigInt(bits)) - constants_1.ONE) << BigInt(offset)) & BigInt(result)).to.equal(0);
            }
            // We want to be able to use 2 bit values, so we can only go up to offset 254. We only cover part of the offset
            // range to keep test duration reasonable.
            for (const offset of [0, 50, 150, 254]) {
                const MAX_BITS = Math.min(256 - offset, 255);
                context(`with offset ${offset}`, () => {
                    it('encodes small values of all bit sizes', async () => {
                        for (let bits = 2; bits <= MAX_BITS; bits++) {
                            await assertUnsignedEncoding(constants_1.ONE, offset, bits);
                        }
                    });
                    it('encodes max values of all bit sizes', async () => {
                        for (let bits = 2; bits <= MAX_BITS; bits++) {
                            await assertUnsignedEncoding(getMaxUnsigned(bits), offset, bits);
                        }
                    });
                    it('reverts with large values', async () => {
                        for (let bits = 2; bits <= MAX_BITS; bits++) {
                            await (0, chai_1.expect)(assertUnsignedEncoding(getMaxUnsigned(bits) + constants_1.ONE, offset, bits)).to.be.revertedWithCustomError(lib, 'CodecOverflow');
                        }
                    });
                    it('reverts with large bitsize', async () => {
                        await (0, chai_1.expect)(assertUnsignedEncoding(constants_1.ZERO, offset, MAX_BITS + 1)).to.be.revertedWithCustomError(lib, 'OutOfBounds');
                    });
                });
            }
        });
        describe('signed', () => {
            it('reverts with zero bit length', async () => {
                await (0, chai_1.expect)(lib.encodeInt(0, 0, 0)).to.be.revertedWithCustomError(lib, 'OutOfBounds');
            });
            it('reverts with 256 bit length', async () => {
                await (0, chai_1.expect)(lib.encodeInt(0, 0, 256)).to.be.revertedWithCustomError(lib, 'OutOfBounds');
            });
            it('reverts with large offset', async () => {
                await (0, chai_1.expect)(lib.encodeInt(0, 256, 0)).to.be.revertedWithCustomError(lib, 'OutOfBounds');
            });
            async function assertSignedEncoding(value, offset, bits) {
                const result = await lib.encodeInt(value, offset, bits);
                // We must be able to restore the original value.
                (0, chai_1.expect)(await lib.decodeInt(result, offset, bits)).to.equal(value);
                // All other bits should be clear.
                (0, chai_1.expect)((0, numbers_1.negate)(((constants_1.ONE << BigInt(bits)) - constants_1.ONE) << BigInt(offset)) & BigInt(result)).to.equal(0);
            }
            // We want to be able to use 2 bit values, so we can only go up to offset 254. We only cover part of the offset
            // range to keep test duration reasonable.
            for (const offset of [0, 50, 150, 254]) {
                const MAX_BITS = Math.min(256 - offset, 255);
                context(`with offset ${offset}`, () => {
                    it('encodes small positive values of all bit sizes', async () => {
                        for (let bits = 2; bits <= MAX_BITS; bits++) {
                            await assertSignedEncoding(constants_1.ONE, offset, bits);
                        }
                    });
                    it('encodes small negative values of all bit sizes', async () => {
                        for (let bits = 2; bits <= MAX_BITS; bits++) {
                            await assertSignedEncoding(BigInt(-constants_1.ONE), offset, bits);
                        }
                    });
                    it('encodes max values of all bit sizes', async () => {
                        for (let bits = 2; bits <= MAX_BITS; bits++) {
                            await assertSignedEncoding(getMaxSigned(bits), offset, bits);
                        }
                    });
                    it('encodes min values of all bit sizes', async () => {
                        for (let bits = 2; bits <= MAX_BITS; bits++) {
                            await assertSignedEncoding(getMinSigned(bits), offset, bits);
                        }
                    });
                    it('reverts with large positive values', async () => {
                        for (let bits = 2; bits <= MAX_BITS; bits++) {
                            await (0, chai_1.expect)(assertSignedEncoding(getMaxSigned(bits) + constants_1.ONE, offset, bits)).to.be.revertedWithCustomError(lib, 'CodecOverflow');
                        }
                    });
                    it('reverts with large negative values', async () => {
                        for (let bits = 2; bits <= MAX_BITS; bits++) {
                            await (0, chai_1.expect)(assertSignedEncoding(getMinSigned(bits) - constants_1.ONE, offset, bits)).to.be.revertedWithCustomError(lib, 'CodecOverflow');
                        }
                    });
                    it('reverts with large bitsize', async () => {
                        await (0, chai_1.expect)(assertSignedEncoding(constants_1.ZERO, offset, MAX_BITS + 1)).to.be.revertedWithCustomError(lib, 'OutOfBounds');
                    });
                });
            }
        });
    });
    describe('insert', () => {
        const word = (0, ethers_1.zeroPadValue)((0, ethers_1.toBeHex)((0, numbers_1.bn)((0, lodash_1.random)(2 ** 255))), 32);
        describe('unsigned', () => {
            it('reverts with zero bit length', async () => {
                await (0, chai_1.expect)(lib.insertUint(word, 0, 0, 0)).to.be.revertedWithCustomError(lib, 'OutOfBounds');
            });
            it('reverts with 256 bit length', async () => {
                await (0, chai_1.expect)(lib.insertUint(word, 0, 0, 256)).to.be.revertedWithCustomError(lib, 'OutOfBounds');
            });
            it('reverts with large offset', async () => {
                await (0, chai_1.expect)(lib.insertUint(word, 256, 0, 256)).to.be.revertedWithCustomError(lib, 'OutOfBounds');
            });
            async function assertUnsignedInsertion(value, offset, bits) {
                const result = await lib.insertUint(word, value, offset, bits);
                // We must be able to restore the original value.
                (0, chai_1.expect)(await lib.decodeUint(result, offset, bits)).to.equal(value);
                // All other bits should match the original word.
                const mask = (0, numbers_1.negate)(((constants_1.ONE << BigInt(bits)) - constants_1.ONE) << BigInt(offset));
                const clearedResult = BigInt(mask) & BigInt(result);
                const clearedWord = BigInt(mask) & BigInt(word);
                (0, chai_1.expect)(clearedResult).to.equal(clearedWord);
            }
            // We want to be able to use 2 bit values, so we can only go up to offset 254. We only cover part of the offset
            // range to keep test duration reasonable.
            for (const offset of [0, 50, 150, 254]) {
                const MAX_BITS = Math.min(256 - offset, 255);
                context(`with offset ${offset}`, () => {
                    it('inserts small values of all bit sizes', async () => {
                        for (let bits = 2; bits <= MAX_BITS; bits++) {
                            await assertUnsignedInsertion(1, offset, bits);
                        }
                    });
                    it('inserts max values of all bit sizes', async () => {
                        for (let bits = 2; bits <= MAX_BITS; bits++) {
                            await assertUnsignedInsertion(getMaxUnsigned(bits), offset, bits);
                        }
                    });
                    it('reverts with large values', async () => {
                        for (let bits = 2; bits <= MAX_BITS; bits++) {
                            await (0, chai_1.expect)(assertUnsignedInsertion(getMaxUnsigned(bits) + constants_1.ONE, offset, bits)).to.be.revertedWithCustomError(lib, 'CodecOverflow');
                        }
                    });
                    it('reverts with large bitsize', async () => {
                        await (0, chai_1.expect)(assertUnsignedInsertion(constants_1.ZERO, offset, MAX_BITS + 1)).to.be.revertedWithCustomError(lib, 'OutOfBounds');
                    });
                });
            }
        });
        describe('signed', () => {
            it('reverts with zero bit length', async () => {
                await (0, chai_1.expect)(lib.insertInt(word, 0, 0, 0)).to.be.revertedWithCustomError(lib, 'OutOfBounds');
            });
            it('reverts with 256 bit length', async () => {
                await (0, chai_1.expect)(lib.insertInt(word, 0, 0, 256)).to.be.revertedWithCustomError(lib, 'OutOfBounds');
            });
            it('reverts with large offset', async () => {
                await (0, chai_1.expect)(lib.insertInt(word, 256, 0, 256)).to.be.revertedWithCustomError(lib, 'OutOfBounds');
            });
            async function assertSignedInsertion(value, offset, bits) {
                const result = await lib.insertInt(word, value, offset, bits);
                // We must be able to restore the original value.
                (0, chai_1.expect)(await lib.decodeInt(result, offset, bits)).to.equal(value);
                // All other bits should match the original word.
                const mask = (0, numbers_1.negate)(((constants_1.ONE << BigInt(bits)) - constants_1.ONE) << BigInt(offset));
                const clearedResult = BigInt(mask) & BigInt(result);
                const clearedWord = BigInt(mask) & BigInt(word);
                (0, chai_1.expect)(clearedResult).to.equal(clearedWord);
            }
            // We want to be able to use 2 bit values, so we can only go up to offset 254. We only cover part of the offset
            // range to keep test duration reasonable.
            for (const offset of [0, 50, 150, 254]) {
                const MAX_BITS = Math.min(256 - offset, 255);
                context(`with offset ${offset}`, () => {
                    it('inserts small positive values of all bit sizes', async () => {
                        for (let bits = 2; bits <= MAX_BITS; bits++) {
                            await assertSignedInsertion(constants_1.ONE, offset, bits);
                        }
                    });
                    it('inserts small negative values of all bit sizes', async () => {
                        for (let bits = 2; bits <= MAX_BITS; bits++) {
                            await assertSignedInsertion(BigInt(-1), offset, bits);
                        }
                    });
                    it('inserts max values of all bit sizes', async () => {
                        for (let bits = 2; bits <= MAX_BITS; bits++) {
                            await assertSignedInsertion(getMaxSigned(bits), offset, bits);
                        }
                    });
                    it('inserts min values of all bit sizes', async () => {
                        for (let bits = 2; bits <= MAX_BITS; bits++) {
                            await assertSignedInsertion(getMinSigned(bits), offset, bits);
                        }
                    });
                    it('reverts with large positive values', async () => {
                        for (let bits = 2; bits <= MAX_BITS; bits++) {
                            await (0, chai_1.expect)(assertSignedInsertion(getMaxSigned(bits) + constants_1.ONE, offset, bits)).to.be.revertedWithCustomError(lib, 'CodecOverflow');
                        }
                    });
                    it('reverts with large negative values', async () => {
                        for (let bits = 2; bits <= MAX_BITS; bits++) {
                            await (0, chai_1.expect)(assertSignedInsertion(getMinSigned(bits) - constants_1.ONE, offset, bits)).to.be.revertedWithCustomError(lib, 'CodecOverflow');
                        }
                    });
                    it('reverts with large bitsize', async () => {
                        await (0, chai_1.expect)(assertSignedInsertion(constants_1.ZERO, offset, MAX_BITS + 1)).to.be.revertedWithCustomError(lib, 'OutOfBounds');
                    });
                });
            }
        });
        describe('bool', () => {
            async function assertBoolInsertion(value, offset) {
                const result = await lib.insertBool(word, value, offset);
                // We must be able to restore the original value.
                (0, chai_1.expect)(await lib.decodeBool(result, offset)).to.equal(value);
                // All other bits should match the original word.
                const mask = (0, numbers_1.negate)(constants_1.ONE << BigInt(offset));
                const clearedResult = BigInt(mask) & BigInt(result);
                const clearedWord = BigInt(mask) & BigInt(word);
                (0, chai_1.expect)(clearedResult).to.equal(clearedWord);
            }
            for (const offset of [0, 50, 150, 254]) {
                context(`with offset ${offset}`, () => {
                    it('inserts true', async () => {
                        await assertBoolInsertion(true, offset);
                    });
                    it('inserts false', async () => {
                        await assertBoolInsertion(false, offset);
                    });
                });
            }
        });
    });
    describe('helpers', () => {
        it('clears word at position', async () => {
            // Starting with all 1's, inserting a 128-bit value of 0 should be the same as clearing 128 bits.
            (0, chai_1.expect)(await lib.clearWordAtPosition(constants_1.ONES_BYTES32, 128, 128)).to.equal(await lib.insertUint(constants_1.ONES_BYTES32, 0, 128, 128));
            // Should fail when the values are different.
            (0, chai_1.expect)(await lib.clearWordAtPosition(constants_1.ONES_BYTES32, 128, 128)).to.not.equal(await lib.insertUint(constants_1.ONES_BYTES32, 0, 128, 64));
        });
        it('ensures surrounding state unchanged', async () => {
            // Should be true if you pass in the same value.
            (0, chai_1.expect)(await lib.isOtherStateUnchanged(constants_1.ONES_BYTES32, constants_1.ONES_BYTES32, 0, 255)).to.be.true;
            // Should be false if you pass in different values.
            (0, chai_1.expect)(await lib.isOtherStateUnchanged(constants_1.ONES_BYTES32, constants_1.ZERO_BYTES32, 0, 255)).to.be.false;
            // Realistic example. Insert a value, *other* bits should be unchanged.
            const changedValue = await lib.insertUint(constants_1.ONES_BYTES32, 0, 192, 32);
            (0, chai_1.expect)(await lib.isOtherStateUnchanged(constants_1.ONES_BYTES32, changedValue, 192, 32)).to.be.true;
        });
    });
});
