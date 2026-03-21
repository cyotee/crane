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
const actions_1 = require("@balancer-labs/v3-helpers/src/models/misc/actions");
const time_1 = require("@balancer-labs/v3-helpers/src/time");
const constants_1 = require("@balancer-labs/v3-helpers/src/constants");
const sharedBeforeEach_1 = require("@balancer-labs/v3-common/sharedBeforeEach");
const lodash_1 = require("lodash");
const TimelockAuthorizerHelper_1 = __importDefault(require("@balancer-labs/v3-helpers/src/models/authorizer/TimelockAuthorizerHelper"));
const contract_1 = require("@balancer-labs/v3-helpers/src/contract");
const TypesConverter_1 = __importDefault(require("@balancer-labs/v3-helpers/src/models/types/TypesConverter"));
const numbers_1 = require("@balancer-labs/v3-helpers/src/numbers");
describe('TimelockAuthorizer delays', () => {
    let authorizer, vault;
    let root, other;
    before('setup signers', async () => {
        [, root, other] = await hardhat_1.ethers.getSigners();
    });
    const ACTION_1 = '0x0000000000000000000000000000000000000000000000000000000000000001';
    const ACTION_2 = '0x0000000000000000000000000000000000000000000000000000000000000002';
    const MINIMUM_EXECUTION_DELAY = 5 * time_1.DAY;
    (0, sharedBeforeEach_1.sharedBeforeEach)('deploy authorizer', async () => {
        vault = await VaultDeployer.deploy();
        const authorizerContract = (await (0, contract_1.deploy)('TimelockAuthorizer', {
            args: [root, constants_1.ZERO_ADDRESS, vault, MINIMUM_EXECUTION_DELAY],
        }));
        authorizer = new TimelockAuthorizerHelper_1.default(authorizerContract, root);
    });
    (0, sharedBeforeEach_1.sharedBeforeEach)('set delay to set authorizer', async () => {
        const iVault = await TypesConverter_1.default.toIVault(vault);
        const setAuthorizerAction = await (0, actions_1.actionId)(iVault, 'setAuthorizer');
        // setAuthorizer must have a delay larger or equal than the one we intend to set - it is invalid to set any delays
        // larger than setAuthorizer's.
        // We set a very large setAuthorizer delay so that we have flexibility in choosing both previous and new delay
        // values in the tests.
        await authorizer.scheduleAndExecuteDelayChange(setAuthorizerAction, time_1.DAY * 365, { from: root });
    });
    describe('scheduleDelayChange', () => {
        const ACTION_DELAY = time_1.DAY;
        function itSchedulesTheDelayChangeCorrectly(expectedExecutionDelay) {
            it('schedules a delay change', async () => {
                const id = await authorizer.scheduleDelayChange(ACTION_1, ACTION_DELAY, [], { from: root });
                const { executed, data, where, executableAt } = await authorizer.getScheduledExecution(id);
                (0, chai_1.expect)(executed).to.be.false;
                (0, chai_1.expect)(data).to.be.equal(authorizer.instance.interface.encodeFunctionData('setDelay', [ACTION_1, ACTION_DELAY]));
                (0, chai_1.expect)(where).to.be.equal(await authorizer.address());
                (0, chai_1.expect)(executableAt).to.equal((await (0, time_1.currentTimestamp)()) + (0, numbers_1.bn)(expectedExecutionDelay));
            });
            it('increases the scheduled execution count', async () => {
                const countBefore = await authorizer.instance.getScheduledExecutionsCount();
                await authorizer.scheduleDelayChange(ACTION_1, ACTION_DELAY, [], { from: root });
                const countAfter = await authorizer.instance.getScheduledExecutionsCount();
                (0, chai_1.expect)(countAfter).to.equal(countBefore + 1n);
            });
            it('stores scheduler information', async () => {
                const id = await authorizer.scheduleDelayChange(ACTION_1, ACTION_DELAY, [], { from: root });
                const scheduledExecution = await authorizer.getScheduledExecution(id);
                (0, chai_1.expect)(scheduledExecution.scheduledBy).to.equal(root.address);
                (0, chai_1.expect)(scheduledExecution.scheduledAt).to.equal(await (0, time_1.currentTimestamp)());
            });
            it('stores empty executor and canceler information', async () => {
                const id = await authorizer.scheduleDelayChange(ACTION_1, ACTION_DELAY, [], { from: root });
                const scheduledExecution = await authorizer.getScheduledExecution(id);
                (0, chai_1.expect)(scheduledExecution.executedBy).to.equal(constants_1.ZERO_ADDRESS);
                (0, chai_1.expect)(scheduledExecution.executedAt).to.equal(0);
                (0, chai_1.expect)(scheduledExecution.canceledBy).to.equal(constants_1.ZERO_ADDRESS);
                (0, chai_1.expect)(scheduledExecution.canceledAt).to.equal(0);
            });
            it('execution can be unprotected', async () => {
                const id = await authorizer.scheduleDelayChange(ACTION_1, ACTION_DELAY, [], { from: root });
                const execution = await authorizer.getScheduledExecution(id);
                (0, chai_1.expect)(execution.protected).to.be.false;
            });
            it('execution can be protected', async () => {
                const executors = (0, lodash_1.range)(4).map(constants_1.randomAddress);
                const id = await authorizer.scheduleDelayChange(ACTION_1, ACTION_DELAY, executors, { from: root });
                const execution = await authorizer.getScheduledExecution(id);
                (0, chai_1.expect)(execution.protected).to.be.true;
                await Promise.all(executors.map(async (executor) => (0, chai_1.expect)(await authorizer.isExecutor(id, executor)).to.be.true));
            });
            it('root can cancel the execution', async () => {
                const id = await authorizer.scheduleDelayChange(ACTION_1, ACTION_DELAY, [], { from: root });
                (0, chai_1.expect)(await authorizer.isCanceler(id, root)).to.be.true;
                const receipt = await authorizer.cancel(id, { from: root });
                expectEvent.inReceipt(await receipt.wait(), 'ExecutionCanceled', { scheduledExecutionId: id });
            });
            it('can be executed after the expected delay', async () => {
                const id = await authorizer.scheduleDelayChange(ACTION_1, ACTION_DELAY, [], { from: root });
                await (0, time_1.advanceTime)(expectedExecutionDelay);
                const receipt = await authorizer.execute(id);
                expectEvent.inReceipt(await receipt.wait(), 'ExecutionExecuted', { scheduledExecutionId: id });
            });
            it('sets the new action delay when executed', async () => {
                const id = await authorizer.scheduleDelayChange(ACTION_1, ACTION_DELAY, [], { from: root });
                await (0, time_1.advanceTime)(expectedExecutionDelay);
                await authorizer.execute(id);
                (0, chai_1.expect)(await authorizer.delay(ACTION_1)).to.be.equal(ACTION_DELAY);
            });
            it('does not set any other action delay when executed', async () => {
                const previousAction2Delay = await authorizer.delay(ACTION_2);
                const id = await authorizer.scheduleDelayChange(ACTION_1, ACTION_DELAY, [], { from: root });
                await (0, time_1.advanceTime)(expectedExecutionDelay);
                await authorizer.execute(id);
                (0, chai_1.expect)(await authorizer.delay(ACTION_2)).to.be.equal(previousAction2Delay);
            });
            it('does not set the grant action delay when executed', async () => {
                const previousGrantDelay = await authorizer.getActionIdGrantDelay(ACTION_1);
                const id = await authorizer.scheduleDelayChange(ACTION_1, ACTION_DELAY, [], { from: root });
                await (0, time_1.advanceTime)(expectedExecutionDelay);
                await authorizer.execute(id);
                (0, chai_1.expect)(await authorizer.getActionIdGrantDelay(ACTION_1)).to.be.equal(previousGrantDelay);
            });
            it('does not set the revoke action delay when executed', async () => {
                const previousRevokeDelay = await authorizer.getActionIdRevokeDelay(ACTION_1);
                const id = await authorizer.scheduleDelayChange(ACTION_1, ACTION_DELAY, [], { from: root });
                await (0, time_1.advanceTime)(expectedExecutionDelay);
                await authorizer.execute(id);
                (0, chai_1.expect)(await authorizer.getActionIdRevokeDelay(ACTION_1)).to.be.equal(previousRevokeDelay);
            });
            it('emits an event', async () => {
                const id = await authorizer.scheduleDelayChange(ACTION_1, ACTION_DELAY, [], { from: root });
                await (0, time_1.advanceTime)(expectedExecutionDelay);
                const receipt = await authorizer.execute(id);
                expectEvent.inReceipt(await receipt.wait(), 'ActionDelaySet', { actionId: ACTION_1, delay: ACTION_DELAY });
            });
        }
        context('when the delay is being increased', () => {
            // When increasing the delay, the execution delay should always be the MINIMUM_EXECUTION_DELAY.
            context('when there was no previous delay', () => {
                itSchedulesTheDelayChangeCorrectly(MINIMUM_EXECUTION_DELAY);
            });
            context('when there was a previous delay set', () => {
                (0, sharedBeforeEach_1.sharedBeforeEach)('set a previous smaller delay', async () => {
                    await authorizer.scheduleAndExecuteDelayChange(ACTION_1, ACTION_DELAY / 2, { from: root });
                });
                itSchedulesTheDelayChangeCorrectly(MINIMUM_EXECUTION_DELAY);
            });
        });
        context('when the delay is being decreased', () => {
            // When the delay is decreased, the execution delay should be the larger of the delay difference and
            // MINIMUM_EXECUTION_DELAY.
            context('when the previous delay was close to the new one', () => {
                const previousDelay = ACTION_DELAY + time_1.DAY;
                (0, sharedBeforeEach_1.sharedBeforeEach)(async () => {
                    await authorizer.scheduleAndExecuteDelayChange(ACTION_1, previousDelay, { from: root });
                });
                itSchedulesTheDelayChangeCorrectly(MINIMUM_EXECUTION_DELAY);
            });
            context('when the previous delay was much larger than the new one', () => {
                const previousDelay = ACTION_DELAY + time_1.MONTH;
                (0, sharedBeforeEach_1.sharedBeforeEach)(async () => {
                    await authorizer.scheduleAndExecuteDelayChange(ACTION_1, previousDelay, { from: root });
                });
                itSchedulesTheDelayChangeCorrectly(previousDelay - ACTION_DELAY);
            });
        });
        describe('error scenarios', () => {
            it('reverts if the sender is not root', async () => {
                await (0, chai_1.expect)(authorizer.scheduleDelayChange(ACTION_1, time_1.DAY, [], { from: other })).to.be.revertedWith('SENDER_IS_NOT_ROOT');
            });
            it('reverts if the new delay is more than 2 years', async () => {
                await (0, chai_1.expect)(authorizer.scheduleDelayChange(ACTION_1, time_1.DAY * 365 * 2 + 1, [], { from: root })).to.be.revertedWith('DELAY_TOO_LARGE');
            });
            it('reverts if setDelay is called directly', async () => {
                await (0, chai_1.expect)(authorizer.instance.setDelay(ACTION_1, time_1.DAY)).to.be.revertedWith('CAN_ONLY_BE_SCHEDULED');
            });
            it('reverts if the delay is greater than the setAuthorizer delay', async () => {
                const iVault = await TypesConverter_1.default.toIVault(vault);
                const setAuthorizerDelay = await authorizer.delay(await (0, actions_1.actionId)(iVault, 'setAuthorizer'));
                const id = await authorizer.scheduleDelayChange(ACTION_1, setAuthorizerDelay + 1n, [], { from: root });
                // This condition is only tested at the time the delay is actually set (in case e.g. there was a scheduled action
                // to change setAuthorizer's delay), so we must attempt to execute the action to get the expected revert.
                await (0, time_1.advanceTime)(MINIMUM_EXECUTION_DELAY);
                await (0, chai_1.expect)(authorizer.execute(id)).to.be.revertedWith('DELAY_EXCEEDS_SET_AUTHORIZER');
            });
        });
    });
    describe('scheduleGrantDelayChange', () => {
        const ACTION_GRANT_DELAY = time_1.DAY;
        function itSchedulesTheGrantDelayChangeCorrectly(expectedExecutionDelay) {
            it('schedules a grant delay change', async () => {
                const id = await authorizer.scheduleGrantDelayChange(ACTION_1, ACTION_GRANT_DELAY, [], { from: root });
                const { executed, data, where, executableAt } = await authorizer.getScheduledExecution(id);
                (0, chai_1.expect)(executed).to.be.false;
                (0, chai_1.expect)(data).to.be.equal(authorizer.instance.interface.encodeFunctionData('setGrantDelay', [ACTION_1, ACTION_GRANT_DELAY]));
                (0, chai_1.expect)(where).to.be.equal(await authorizer.address());
                (0, chai_1.expect)(executableAt).to.equal((await (0, time_1.currentTimestamp)()) + (0, numbers_1.bn)(expectedExecutionDelay));
            });
            it('increases the scheduled execution count', async () => {
                const countBefore = await authorizer.instance.getScheduledExecutionsCount();
                await authorizer.scheduleGrantDelayChange(ACTION_1, ACTION_GRANT_DELAY, [], { from: root });
                const countAfter = await authorizer.instance.getScheduledExecutionsCount();
                (0, chai_1.expect)(countAfter).to.equal(countBefore + 1n);
            });
            it('stores scheduler information', async () => {
                const id = await authorizer.scheduleGrantDelayChange(ACTION_1, ACTION_GRANT_DELAY, [], { from: root });
                const scheduledExecution = await authorizer.getScheduledExecution(id);
                (0, chai_1.expect)(scheduledExecution.scheduledBy).to.equal(root.address);
                (0, chai_1.expect)(scheduledExecution.scheduledAt).to.equal(await (0, time_1.currentTimestamp)());
            });
            it('stores empty executor and canceler information', async () => {
                const id = await authorizer.scheduleGrantDelayChange(ACTION_1, ACTION_GRANT_DELAY, [], { from: root });
                const scheduledExecution = await authorizer.getScheduledExecution(id);
                (0, chai_1.expect)(scheduledExecution.executedBy).to.equal(constants_1.ZERO_ADDRESS);
                (0, chai_1.expect)(scheduledExecution.executedAt).to.equal(0);
                (0, chai_1.expect)(scheduledExecution.canceledBy).to.equal(constants_1.ZERO_ADDRESS);
                (0, chai_1.expect)(scheduledExecution.canceledAt).to.equal(0);
            });
            it('execution can be unprotected', async () => {
                const id = await authorizer.scheduleGrantDelayChange(ACTION_1, ACTION_GRANT_DELAY, [], { from: root });
                const execution = await authorizer.getScheduledExecution(id);
                (0, chai_1.expect)(execution.protected).to.be.false;
            });
            it('execution can be protected', async () => {
                const executors = (0, lodash_1.range)(4).map(() => hardhat_1.ethers.Wallet.createRandom().address);
                const id = await authorizer.scheduleGrantDelayChange(ACTION_1, ACTION_GRANT_DELAY, executors, { from: root });
                const execution = await authorizer.getScheduledExecution(id);
                (0, chai_1.expect)(execution.protected).to.be.true;
                await Promise.all(executors.map(async (executor) => (0, chai_1.expect)(await authorizer.isExecutor(id, executor)).to.be.true));
            });
            it('root can cancel the execution', async () => {
                const id = await authorizer.scheduleGrantDelayChange(ACTION_1, ACTION_GRANT_DELAY, [], { from: root });
                (0, chai_1.expect)(await authorizer.isCanceler(id, root)).to.be.true;
                const receipt = await authorizer.cancel(id, { from: root });
                expectEvent.inReceipt(await receipt.wait(), 'ExecutionCanceled', { scheduledExecutionId: id });
            });
            it('can be executed after the expected delay', async () => {
                const id = await authorizer.scheduleGrantDelayChange(ACTION_1, ACTION_GRANT_DELAY, [], { from: root });
                await (0, time_1.advanceTime)(expectedExecutionDelay);
                const receipt = await authorizer.execute(id);
                expectEvent.inReceipt(await receipt.wait(), 'ExecutionExecuted', { scheduledExecutionId: id });
            });
            it('sets the new grant action delay when executed', async () => {
                const id = await authorizer.scheduleGrantDelayChange(ACTION_1, ACTION_GRANT_DELAY, [], { from: root });
                await (0, time_1.advanceTime)(expectedExecutionDelay);
                await authorizer.execute(id);
                (0, chai_1.expect)(await authorizer.getActionIdGrantDelay(ACTION_1)).to.be.equal(ACTION_GRANT_DELAY);
            });
            it('does not set any other action grant delay when executed', async () => {
                const previousAction2GrantDelay = await authorizer.getActionIdGrantDelay(ACTION_2);
                const id = await authorizer.scheduleGrantDelayChange(ACTION_1, ACTION_GRANT_DELAY, [], { from: root });
                await (0, time_1.advanceTime)(expectedExecutionDelay);
                await authorizer.execute(id);
                (0, chai_1.expect)(await authorizer.getActionIdGrantDelay(ACTION_2)).to.be.equal(previousAction2GrantDelay);
            });
            it('does not set the action delay when executed', async () => {
                const previousActionDelay = await authorizer.delay(ACTION_1);
                const id = await authorizer.scheduleGrantDelayChange(ACTION_1, ACTION_GRANT_DELAY, [], { from: root });
                await (0, time_1.advanceTime)(expectedExecutionDelay);
                await authorizer.execute(id);
                (0, chai_1.expect)(await authorizer.delay(ACTION_1)).to.be.equal(previousActionDelay);
            });
            it('does not set the revoke action delay when executed', async () => {
                const previousActionDelay = await authorizer.getActionIdRevokeDelay(ACTION_1);
                const id = await authorizer.scheduleGrantDelayChange(ACTION_1, ACTION_GRANT_DELAY, [], { from: root });
                await (0, time_1.advanceTime)(expectedExecutionDelay);
                await authorizer.execute(id);
                (0, chai_1.expect)(await authorizer.getActionIdRevokeDelay(ACTION_1)).to.be.equal(previousActionDelay);
            });
            it('emits an event', async () => {
                const id = await authorizer.scheduleGrantDelayChange(ACTION_1, ACTION_GRANT_DELAY, [], { from: root });
                await (0, time_1.advanceTime)(expectedExecutionDelay);
                const receipt = await authorizer.execute(id);
                expectEvent.inReceipt(await receipt.wait(), 'GrantDelaySet', {
                    actionId: ACTION_1,
                    delay: ACTION_GRANT_DELAY,
                });
            });
        }
        context('when the delay is being increased', () => {
            // When incrasing the delay, the execution delay should always be the MINIMUM_EXECUTION_DELAY.
            context('when there was no previous delay', () => {
                itSchedulesTheGrantDelayChangeCorrectly(MINIMUM_EXECUTION_DELAY);
            });
            context('when there was a previous delay set', () => {
                (0, sharedBeforeEach_1.sharedBeforeEach)('set a previous smaller delay', async () => {
                    await authorizer.scheduleAndExecuteGrantDelayChange(ACTION_1, ACTION_GRANT_DELAY / 2, { from: root });
                });
                itSchedulesTheGrantDelayChangeCorrectly(MINIMUM_EXECUTION_DELAY);
            });
        });
        context('when the delay is being decreased', () => {
            // When the delay is decreased, the execution delay should be the larger of the delay difference and
            // MINIMUM_EXECUTION_DELAY.
            context('when the previous delay was close to the new one', () => {
                const previousDelay = ACTION_GRANT_DELAY + time_1.DAY;
                (0, sharedBeforeEach_1.sharedBeforeEach)(async () => {
                    await authorizer.scheduleAndExecuteGrantDelayChange(ACTION_1, previousDelay, { from: root });
                });
                itSchedulesTheGrantDelayChangeCorrectly(MINIMUM_EXECUTION_DELAY);
            });
            context('when the previous delay was much larger than the new one', () => {
                const previousDelay = ACTION_GRANT_DELAY + time_1.MONTH;
                (0, sharedBeforeEach_1.sharedBeforeEach)(async () => {
                    await authorizer.scheduleAndExecuteGrantDelayChange(ACTION_1, previousDelay, { from: root });
                });
                itSchedulesTheGrantDelayChangeCorrectly(previousDelay - ACTION_GRANT_DELAY);
            });
        });
        describe('error scenarios', () => {
            it('reverts if the sender is not root', async () => {
                await (0, chai_1.expect)(authorizer.scheduleGrantDelayChange(ACTION_1, time_1.DAY, [], { from: other })).to.be.revertedWith('SENDER_IS_NOT_ROOT');
            });
            it('reverts if the new delay is more than 2 years', async () => {
                await (0, chai_1.expect)(authorizer.scheduleGrantDelayChange(ACTION_1, time_1.DAY * 365 * 2 + 1, [], { from: root })).to.be.revertedWith('DELAY_TOO_LARGE');
            });
            it('reverts if setGrantDelay is called directly', async () => {
                await (0, chai_1.expect)(authorizer.instance.setGrantDelay(ACTION_1, time_1.DAY)).to.be.revertedWith('CAN_ONLY_BE_SCHEDULED');
            });
            it('reverts if the delay is greater than the setAuthorizer delay', async () => {
                const iVault = await TypesConverter_1.default.toIVault(vault);
                const setAuthorizerDelay = await authorizer.delay(await (0, actions_1.actionId)(iVault, 'setAuthorizer'));
                const id = await authorizer.scheduleGrantDelayChange(ACTION_1, setAuthorizerDelay + (0, numbers_1.bn)(1), [], { from: root });
                // This condition is only tested at the time the delay is actually set (in case e.g. there was a scheduled action
                // to change setAuthorizer's delay), so we must attempt to execute the action to get the expected revert.
                await (0, time_1.advanceTime)(MINIMUM_EXECUTION_DELAY);
                await (0, chai_1.expect)(authorizer.execute(id)).to.be.revertedWith('DELAY_EXCEEDS_SET_AUTHORIZER');
            });
        });
    });
    describe('scheduleRevokeDelayChange', () => {
        const ACTION_REVOKE_DELAY = time_1.DAY;
        function itSchedulesTheRevokeDelayChangeCorrectly(expectedExecutionDelay) {
            it('schedules a revoke delay change', async () => {
                const id = await authorizer.scheduleRevokeDelayChange(ACTION_1, ACTION_REVOKE_DELAY, [], { from: root });
                const { executed, data, where, executableAt } = await authorizer.getScheduledExecution(id);
                (0, chai_1.expect)(executed).to.be.false;
                (0, chai_1.expect)(data).to.be.equal(authorizer.instance.interface.encodeFunctionData('setRevokeDelay', [ACTION_1, ACTION_REVOKE_DELAY]));
                (0, chai_1.expect)(where).to.be.equal(await authorizer.address());
                (0, chai_1.expect)(executableAt).to.equal((await (0, time_1.currentTimestamp)()) + (0, numbers_1.bn)(expectedExecutionDelay));
            });
            it('increases the scheduled execution count', async () => {
                const countBefore = await authorizer.instance.getScheduledExecutionsCount();
                await authorizer.scheduleRevokeDelayChange(ACTION_1, ACTION_REVOKE_DELAY, [], { from: root });
                const countAfter = await authorizer.instance.getScheduledExecutionsCount();
                (0, chai_1.expect)(countAfter).to.equal(countBefore + 1n);
            });
            it('stores scheduler information', async () => {
                const id = await authorizer.scheduleRevokeDelayChange(ACTION_1, ACTION_REVOKE_DELAY, [], { from: root });
                const scheduledExecution = await authorizer.getScheduledExecution(id);
                (0, chai_1.expect)(scheduledExecution.scheduledBy).to.equal(root.address);
                (0, chai_1.expect)(scheduledExecution.scheduledAt).to.equal(await (0, time_1.currentTimestamp)());
            });
            it('stores empty executor and canceler information', async () => {
                const id = await authorizer.scheduleRevokeDelayChange(ACTION_1, ACTION_REVOKE_DELAY, [], { from: root });
                const scheduledExecution = await authorizer.getScheduledExecution(id);
                (0, chai_1.expect)(scheduledExecution.executedBy).to.equal(constants_1.ZERO_ADDRESS);
                (0, chai_1.expect)(scheduledExecution.executedAt).to.equal(0);
                (0, chai_1.expect)(scheduledExecution.canceledBy).to.equal(constants_1.ZERO_ADDRESS);
                (0, chai_1.expect)(scheduledExecution.canceledAt).to.equal(0);
            });
            it('execution can be unprotected', async () => {
                const id = await authorizer.scheduleRevokeDelayChange(ACTION_1, ACTION_REVOKE_DELAY, [], { from: root });
                const execution = await authorizer.getScheduledExecution(id);
                (0, chai_1.expect)(execution.protected).to.be.false;
            });
            it('execution can be protected', async () => {
                const executors = (0, lodash_1.range)(4).map(() => hardhat_1.ethers.Wallet.createRandom().address);
                const id = await authorizer.scheduleRevokeDelayChange(ACTION_1, ACTION_REVOKE_DELAY, executors, { from: root });
                const execution = await authorizer.getScheduledExecution(id);
                (0, chai_1.expect)(execution.protected).to.be.true;
                await Promise.all(executors.map(async (executor) => (0, chai_1.expect)(await authorizer.isExecutor(id, executor)).to.be.true));
            });
            it('root can cancel the execution', async () => {
                const id = await authorizer.scheduleRevokeDelayChange(ACTION_1, ACTION_REVOKE_DELAY, [], { from: root });
                (0, chai_1.expect)(await authorizer.isCanceler(id, root)).to.be.true;
                const receipt = await authorizer.cancel(id, { from: root });
                expectEvent.inReceipt(await receipt.wait(), 'ExecutionCanceled', { scheduledExecutionId: id });
            });
            it('can be executed after the expected delay', async () => {
                const id = await authorizer.scheduleRevokeDelayChange(ACTION_1, ACTION_REVOKE_DELAY, [], { from: root });
                await (0, time_1.advanceTime)(expectedExecutionDelay);
                const receipt = await authorizer.execute(id);
                expectEvent.inReceipt(await receipt.wait(), 'ExecutionExecuted', { scheduledExecutionId: id });
            });
            it('sets the new revoke action delay when executed', async () => {
                const id = await authorizer.scheduleRevokeDelayChange(ACTION_1, ACTION_REVOKE_DELAY, [], { from: root });
                await (0, time_1.advanceTime)(expectedExecutionDelay);
                await authorizer.execute(id);
                (0, chai_1.expect)(await authorizer.getActionIdRevokeDelay(ACTION_1)).to.be.equal(ACTION_REVOKE_DELAY);
            });
            it('does not set any other action revoke delay when executed', async () => {
                const previousAction2RevokeDelay = await authorizer.getActionIdRevokeDelay(ACTION_2);
                const id = await authorizer.scheduleRevokeDelayChange(ACTION_1, ACTION_REVOKE_DELAY, [], { from: root });
                await (0, time_1.advanceTime)(expectedExecutionDelay);
                await authorizer.execute(id);
                (0, chai_1.expect)(await authorizer.getActionIdRevokeDelay(ACTION_2)).to.be.equal(previousAction2RevokeDelay);
            });
            it('does not set the action delay when executed', async () => {
                const previousActionDelay = await authorizer.delay(ACTION_1);
                const id = await authorizer.scheduleRevokeDelayChange(ACTION_1, ACTION_REVOKE_DELAY, [], { from: root });
                await (0, time_1.advanceTime)(expectedExecutionDelay);
                await authorizer.execute(id);
                (0, chai_1.expect)(await authorizer.delay(ACTION_1)).to.be.equal(previousActionDelay);
            });
            it('does not set the grant action delay when executed', async () => {
                const previousActionDelay = await authorizer.getActionIdGrantDelay(ACTION_1);
                const id = await authorizer.scheduleRevokeDelayChange(ACTION_1, ACTION_REVOKE_DELAY, [], { from: root });
                await (0, time_1.advanceTime)(expectedExecutionDelay);
                await authorizer.execute(id);
                (0, chai_1.expect)(await authorizer.getActionIdGrantDelay(ACTION_1)).to.be.equal(previousActionDelay);
            });
            it('emits an event', async () => {
                const id = await authorizer.scheduleRevokeDelayChange(ACTION_1, ACTION_REVOKE_DELAY, [], { from: root });
                await (0, time_1.advanceTime)(expectedExecutionDelay);
                const receipt = await authorizer.execute(id);
                expectEvent.inReceipt(await receipt.wait(), 'RevokeDelaySet', {
                    actionId: ACTION_1,
                    delay: ACTION_REVOKE_DELAY,
                });
            });
        }
        context('when the delay is being increased', () => {
            // When incrasing the delay, the execution delay should always be the MINIMUM_EXECUTION_DELAY.
            context('when there was no previous delay', () => {
                itSchedulesTheRevokeDelayChangeCorrectly(MINIMUM_EXECUTION_DELAY);
            });
            context('when there was a previous delay set', () => {
                (0, sharedBeforeEach_1.sharedBeforeEach)('set a previous smaller delay', async () => {
                    await authorizer.scheduleAndExecuteRevokeDelayChange(ACTION_1, ACTION_REVOKE_DELAY / 2, { from: root });
                });
                itSchedulesTheRevokeDelayChangeCorrectly(MINIMUM_EXECUTION_DELAY);
            });
        });
        context('when the delay is being decreased', () => {
            // When the delay is decreased, the execution delay should be the larger of the delay difference and
            // MINIMUM_EXECUTION_DELAY.
            context('when the previous delay was close to the new one', () => {
                const previousDelay = ACTION_REVOKE_DELAY + time_1.DAY;
                (0, sharedBeforeEach_1.sharedBeforeEach)(async () => {
                    await authorizer.scheduleAndExecuteRevokeDelayChange(ACTION_1, previousDelay, { from: root });
                });
                itSchedulesTheRevokeDelayChangeCorrectly(MINIMUM_EXECUTION_DELAY);
            });
            context('when the previous delay was much larger than the new one', () => {
                const previousDelay = ACTION_REVOKE_DELAY + time_1.MONTH;
                (0, sharedBeforeEach_1.sharedBeforeEach)(async () => {
                    await authorizer.scheduleAndExecuteRevokeDelayChange(ACTION_1, previousDelay, { from: root });
                });
                itSchedulesTheRevokeDelayChangeCorrectly(previousDelay - ACTION_REVOKE_DELAY);
            });
        });
        describe('error scenarios', () => {
            it('reverts if the sender is not root', async () => {
                await (0, chai_1.expect)(authorizer.scheduleRevokeDelayChange(ACTION_1, time_1.DAY, [], { from: other })).to.be.revertedWith('SENDER_IS_NOT_ROOT');
            });
            it('reverts if the new delay is more than 2 years', async () => {
                await (0, chai_1.expect)(authorizer.scheduleRevokeDelayChange(ACTION_1, time_1.DAY * 365 * 2 + 1, [], { from: root })).to.be.revertedWith('DELAY_TOO_LARGE');
            });
            it('reverts if setRevokeDelay is called directly', async () => {
                await (0, chai_1.expect)(authorizer.instance.setRevokeDelay(ACTION_1, time_1.DAY)).to.be.revertedWith('CAN_ONLY_BE_SCHEDULED');
            });
            it('reverts if the delay is greater than the setAuthorizer delay', async () => {
                const iVault = await TypesConverter_1.default.toIVault(vault);
                const setAuthorizerDelay = await authorizer.delay(await (0, actions_1.actionId)(iVault, 'setAuthorizer'));
                const id = await authorizer.scheduleRevokeDelayChange(ACTION_1, setAuthorizerDelay + 1n, [], { from: root });
                // This condition is only tested at the time the delay is actually set (in case e.g. there was a scheduled action
                // to change setAuthorizer's delay), so we must attempt to execute the action to get the expected revert.
                await (0, time_1.advanceTime)(MINIMUM_EXECUTION_DELAY);
                await (0, chai_1.expect)(authorizer.execute(id)).to.be.revertedWith('DELAY_EXCEEDS_SET_AUTHORIZER');
            });
        });
    });
});
