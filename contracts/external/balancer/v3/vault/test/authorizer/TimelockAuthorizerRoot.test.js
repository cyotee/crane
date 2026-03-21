"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (k !== "default" && Object.prototype.hasOwnProperty.call(mod, k)) __createBinding(result, mod, k);
    __setModuleDefault(result, mod);
    return result;
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const chai_1 = require("chai");
const hardhat_1 = require("hardhat");
const expectEvent = __importStar(require("@balancer-labs/v3-helpers/src/test/expectEvent"));
const VaultDeployer = __importStar(require("@balancer-labs/v3-helpers/src/models/vault/VaultDeployer"));
const TimelockAuthorizerHelper_1 = __importDefault(require("@balancer-labs/v3-helpers/src/models/authorizer/TimelockAuthorizerHelper"));
const constants_1 = require("@balancer-labs/v3-helpers/src/constants");
const time_1 = require("@balancer-labs/v3-helpers/src/time");
const sharedBeforeEach_1 = require("@balancer-labs/v3-common/sharedBeforeEach");
const contract_1 = require("@balancer-labs/v3-helpers/src/contract");
const numbers_1 = require("@balancer-labs/v3-helpers/src/numbers");
describe('TimelockAuthorizer root', () => {
    let authorizer;
    let root, nextRoot, user, other;
    const MINIMUM_EXECUTION_DELAY = 5 * time_1.DAY;
    before('setup signers', async () => {
        [, root, nextRoot, user, other] = await hardhat_1.ethers.getSigners();
    });
    (0, sharedBeforeEach_1.sharedBeforeEach)('deploy authorizer', async () => {
        const vault = await VaultDeployer.deploy();
        const authorizerContract = (await (0, contract_1.deploy)('TimelockAuthorizer', {
            args: [root, nextRoot, vault, MINIMUM_EXECUTION_DELAY],
        }));
        authorizer = new TimelockAuthorizerHelper_1.default(authorizerContract, root);
    });
    describe('root', () => {
        describe('setPendingRoot', () => {
            let ROOT_CHANGE_DELAY;
            beforeEach('fetch root change delay', async () => {
                ROOT_CHANGE_DELAY = await authorizer.instance.getRootTransferDelay();
            });
            it('sets the nextRoot as the pending root during construction', async () => {
                (0, chai_1.expect)(await authorizer.instance.getPendingRoot()).to.equal(nextRoot.address);
            });
            context('when scheduling root change', async () => {
                function itSetsThePendingRootCorrectly(getNewPendingRoot) {
                    it('schedules a root change', async () => {
                        const newPendingRoot = getNewPendingRoot();
                        const expectedData = authorizer.instance.interface.encodeFunctionData('setPendingRoot', [
                            newPendingRoot.address,
                        ]);
                        const id = await authorizer.scheduleRootChange(newPendingRoot, [], { from: root });
                        const scheduledExecution = await authorizer.getScheduledExecution(id);
                        (0, chai_1.expect)(scheduledExecution.executed).to.be.false;
                        (0, chai_1.expect)(scheduledExecution.data).to.be.equal(expectedData);
                        (0, chai_1.expect)(scheduledExecution.where).to.be.equal(await authorizer.address());
                        (0, chai_1.expect)(scheduledExecution.protected).to.be.false;
                        (0, chai_1.expect)(scheduledExecution.executableAt).to.be.at.almostEqual((await (0, time_1.currentTimestamp)()) + (0, numbers_1.bn)(ROOT_CHANGE_DELAY));
                    });
                    it('can be executed after the delay', async () => {
                        const newPendingRoot = getNewPendingRoot();
                        const id = await authorizer.scheduleRootChange(newPendingRoot, [], { from: root });
                        await (0, chai_1.expect)(authorizer.execute(id)).to.be.revertedWith('EXECUTION_NOT_YET_EXECUTABLE');
                        await (0, time_1.advanceTime)(ROOT_CHANGE_DELAY);
                        await authorizer.execute(id);
                        (0, chai_1.expect)(await authorizer.isRoot(root)).to.be.true;
                        (0, chai_1.expect)(await authorizer.isPendingRoot(newPendingRoot)).to.be.true;
                    });
                    it('emits an event', async () => {
                        const newPendingRoot = getNewPendingRoot();
                        let receipt = await authorizer.instance.connect(root).scheduleRootChange(newPendingRoot.address, []);
                        const event = expectEvent.inReceipt(await receipt.wait(), 'RootChangeScheduled', {
                            newRoot: newPendingRoot.address,
                        });
                        await (0, time_1.advanceTime)(ROOT_CHANGE_DELAY);
                        receipt = await authorizer.execute(event.args.scheduledExecutionId);
                        expectEvent.inReceipt(await receipt.wait(), 'PendingRootSet', { pendingRoot: newPendingRoot.address });
                    });
                }
                itSetsThePendingRootCorrectly(() => user);
                context('starting a new root transfer while pending root is set', () => {
                    // We test this to ensure that executing an action which sets the pending root to an address which cannot
                    // call `claimRoot` won't result in the Authorizer being unable to transfer root power to a different address.
                    (0, sharedBeforeEach_1.sharedBeforeEach)('initiate a root transfer', async () => {
                        const id = await authorizer.scheduleRootChange(user, [], { from: root });
                        await (0, time_1.advanceTime)(ROOT_CHANGE_DELAY);
                        await authorizer.execute(id);
                    });
                    itSetsThePendingRootCorrectly(() => other);
                });
            });
            it('reverts if trying to execute it directly', async () => {
                await (0, chai_1.expect)(authorizer.instance.setPendingRoot(user.address)).to.be.revertedWith('CAN_ONLY_BE_SCHEDULED');
            });
            it('reverts if the sender is not the root', async () => {
                await (0, chai_1.expect)(authorizer.scheduleRootChange(user, [], { from: user })).to.be.revertedWith('SENDER_IS_NOT_ROOT');
            });
        });
        describe('claimRoot', () => {
            let ROOT_CHANGE_DELAY;
            beforeEach('fetch root change delay', async () => {
                ROOT_CHANGE_DELAY = await authorizer.instance.getRootTransferDelay();
            });
            (0, sharedBeforeEach_1.sharedBeforeEach)('initiate a root transfer', async () => {
                const id = await authorizer.scheduleRootChange(user, [], { from: root });
                await (0, time_1.advanceTime)(ROOT_CHANGE_DELAY);
                await authorizer.execute(id);
            });
            it('transfers root powers from the current to the pending root', async () => {
                await authorizer.claimRoot({ from: user });
                (0, chai_1.expect)(await authorizer.isRoot(root)).to.be.false;
                (0, chai_1.expect)(await authorizer.isRoot(user)).to.be.true;
                (0, chai_1.expect)(await authorizer.instance.getRoot()).to.be.eq(user.address);
            });
            it('resets the pending root address to the zero address', async () => {
                await authorizer.claimRoot({ from: user });
                (0, chai_1.expect)(await authorizer.isPendingRoot(root)).to.be.false;
                (0, chai_1.expect)(await authorizer.isPendingRoot(user)).to.be.false;
                (0, chai_1.expect)(await authorizer.isPendingRoot(constants_1.ZERO_ADDRESS)).to.be.true;
                (0, chai_1.expect)(await authorizer.instance.getPendingRoot()).to.be.eq(constants_1.ZERO_ADDRESS);
            });
            it('emits an event', async () => {
                const receipt = await authorizer.claimRoot({ from: user });
                expectEvent.inReceipt(await receipt.wait(), 'RootSet', { root: user.address });
                expectEvent.inReceipt(await receipt.wait(), 'PendingRootSet', { pendingRoot: constants_1.ZERO_ADDRESS });
            });
            it('reverts if the sender is not the pending root', async () => {
                await (0, chai_1.expect)(authorizer.claimRoot({ from: other })).to.be.revertedWith('SENDER_IS_NOT_PENDING_ROOT');
            });
        });
    });
});
