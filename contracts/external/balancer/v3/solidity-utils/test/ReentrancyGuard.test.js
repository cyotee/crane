"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const chai_1 = require("chai");
const contract_1 = require("@balancer-labs/v3-helpers/src/contract");
const sharedBeforeEach_1 = require("@balancer-labs/v3-common/sharedBeforeEach");
describe('ReentrancyGuard', () => {
    let reentrancyMock;
    (0, sharedBeforeEach_1.sharedBeforeEach)(async function () {
        reentrancyMock = await (0, contract_1.deploy)('ReentrancyMock');
        (0, chai_1.expect)(await reentrancyMock.counter()).to.equal(0);
    });
    it('nonReentrant function can be called', async function () {
        (0, chai_1.expect)(await reentrancyMock.counter()).to.equal(0);
        await reentrancyMock.callback();
        (0, chai_1.expect)(await reentrancyMock.counter()).to.equal(1);
    });
    it('does not allow remote callback', async function () {
        const attacker = await (0, contract_1.deploy)('ReentrancyAttack');
        await (0, chai_1.expect)(reentrancyMock.countAndCall(await attacker.getAddress())).to.be.revertedWith('ReentrancyAttack: failed call');
    });
    it('_reentrancyGuardEntered should be true when guarded', async function () {
        await (0, chai_1.expect)(reentrancyMock.guardedCheckEntered()).not.to.be.reverted;
    });
    it('_reentrancyGuardEntered should be false when unguarded', async function () {
        await (0, chai_1.expect)(reentrancyMock.unguardedCheckNotEntered()).not.to.be.reverted;
    });
    // The following are more side-effects than intended behavior:
    // I put them here as documentation, and to monitor any changes
    // in the side-effects.
    it('does not allow local recursion', async function () {
        await (0, chai_1.expect)(reentrancyMock.countLocalRecursive(10)).to.be.revertedWithCustomError(reentrancyMock, 'ReentrancyGuardReentrantCall');
    });
    it('does not allow indirect local recursion', async function () {
        await (0, chai_1.expect)(reentrancyMock.countThisRecursive(10)).to.be.revertedWith('ReentrancyMock: failed call');
    });
});
