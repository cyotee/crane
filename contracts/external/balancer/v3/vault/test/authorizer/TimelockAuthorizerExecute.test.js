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
const contract_1 = require("@balancer-labs/v3-helpers/src/contract");
const actions_1 = require("@balancer-labs/v3-helpers/src/models/misc/actions");
const time_1 = require("@balancer-labs/v3-helpers/src/time");
const sharedBeforeEach_1 = require("@balancer-labs/v3-common/sharedBeforeEach");
const constants_1 = require("@balancer-labs/v3-helpers/src/constants");
const typechain_types_1 = require("../../typechain-types");
const TimelockAuthorizerHelper_1 = __importDefault(require("@balancer-labs/v3-helpers/src/models/authorizer/TimelockAuthorizerHelper"));
const TypesConverter_1 = __importDefault(require("@balancer-labs/v3-helpers/src/models/types/TypesConverter"));
const numbers_1 = require("@balancer-labs/v3-helpers/src/numbers");
describe('TimelockAuthorizer execute', () => {
    let authorizer, vault, iVault;
    let authenticatedContract;
    let root, nextRoot, user, executor, canceler, other, account;
    const EVERYWHERE = TimelockAuthorizerHelper_1.default.EVERYWHERE;
    const GLOBAL_CANCELER_SCHEDULED_EXECUTION_ID = constants_1.MAX_UINT256;
    const MINIMUM_EXECUTION_DELAY = 5 * time_1.DAY;
    before('setup signers', async () => {
        [, root, nextRoot, executor, canceler, account, user, other] = await hardhat_1.ethers.getSigners();
    });
    (0, sharedBeforeEach_1.sharedBeforeEach)('deploy authorizer', async () => {
        vault = await VaultDeployer.deploy();
        iVault = await TypesConverter_1.default.toIVault(vault);
        const authorizerContract = (await (0, contract_1.deploy)('TimelockAuthorizer', {
            args: [root, nextRoot, vault, MINIMUM_EXECUTION_DELAY],
        }));
        const basicAuthorizer = typechain_types_1.BasicAuthorizerMock__factory.connect(await iVault.getAuthorizer(), iVault.runner);
        const setAuthorizerAction = await (0, actions_1.actionId)(iVault, 'setAuthorizer');
        // The root of the basic authorizer is the default signer.
        await basicAuthorizer.grantRole(setAuthorizerAction, root.address);
        await iVault.connect(root).setAuthorizer(authorizerContract);
        authenticatedContract = await (0, contract_1.deploy)('AuthenticatedContractMock', { args: [vault] });
        authorizer = new TimelockAuthorizerHelper_1.default(authorizerContract, root);
    });
    describe('schedule', () => {
        const delay = time_1.DAY * 5;
        const functionData = '0x0123456789abcdef';
        let action, data;
        let anotherAuthenticatedContract;
        (0, sharedBeforeEach_1.sharedBeforeEach)('deploy sample instances', async () => {
            anotherAuthenticatedContract = await (0, contract_1.deploy)('AuthenticatedContractMock', { args: [vault] });
        });
        (0, sharedBeforeEach_1.sharedBeforeEach)('set authorizer permission delay', async () => {
            // We must set a delay for the `setAuthorizer` function as well to be able to give one to `protectedFunction`,
            // which it must have in order to be able to schedule calls to it.
            const setAuthorizerAction = await (0, actions_1.actionId)(iVault, 'setAuthorizer');
            await authorizer.scheduleAndExecuteDelayChange(setAuthorizerAction, 2 * delay, { from: root });
        });
        (0, sharedBeforeEach_1.sharedBeforeEach)('set action', async () => {
            action = await (0, actions_1.actionId)(authenticatedContract, 'protectedFunction');
            console.log('action');
        });
        (0, sharedBeforeEach_1.sharedBeforeEach)('grant permission', async () => {
            await authorizer.grantPermission(action, user, await authenticatedContract.getAddress(), { from: root });
            console.log('grant permission');
        });
        (0, sharedBeforeEach_1.sharedBeforeEach)('set delay for action', async () => {
            await authorizer.scheduleAndExecuteDelayChange(action, delay, { from: root });
            console.log('scheduled delay');
        });
        const schedule = async (where, executors = undefined) => {
            data = authenticatedContract.interface.encodeFunctionData('protectedFunction', [functionData]);
            return authorizer.schedule(where, data, executors || [], { from: user });
        };
        it('increases the scheduled execution count', async () => {
            const countBefore = await authorizer.instance.getScheduledExecutionsCount();
            await schedule(await authenticatedContract.getAddress());
            const countAfter = await authorizer.instance.getScheduledExecutionsCount();
            (0, chai_1.expect)(countAfter).to.equal(countBefore + 1n);
        });
        it('stores scheduler information', async () => {
            const id = await schedule(await authenticatedContract.getAddress());
            const scheduledExecution = await authorizer.getScheduledExecution(id);
            (0, chai_1.expect)(scheduledExecution.scheduledBy).to.equal(user.address);
            (0, chai_1.expect)(scheduledExecution.scheduledAt).to.equal(await (0, time_1.currentTimestamp)());
        });
        it('stores empty executor and canceler information', async () => {
            const id = await schedule(await authenticatedContract.getAddress());
            const scheduledExecution = await authorizer.getScheduledExecution(id);
            (0, chai_1.expect)(scheduledExecution.executedBy).to.equal(constants_1.ZERO_ADDRESS);
            (0, chai_1.expect)(scheduledExecution.executedAt).to.equal(0);
            (0, chai_1.expect)(scheduledExecution.canceledBy).to.equal(constants_1.ZERO_ADDRESS);
            (0, chai_1.expect)(scheduledExecution.canceledAt).to.equal(0);
        });
        it('schedules a non-protected execution', async () => {
            const id = await schedule(await authenticatedContract.getAddress());
            const scheduledExecution = await authorizer.getScheduledExecution(id);
            (0, chai_1.expect)(scheduledExecution.executed).to.be.false;
            (0, chai_1.expect)(scheduledExecution.data).to.be.equal(data);
            (0, chai_1.expect)(scheduledExecution.where).to.be.equal(await authenticatedContract.getAddress());
            (0, chai_1.expect)(scheduledExecution.protected).to.be.false;
            (0, chai_1.expect)(scheduledExecution.executableAt).to.be.at.eq((await (0, time_1.currentTimestamp)()) + (0, numbers_1.bn)(delay));
        });
        it('can schedule with a global permission', async () => {
            await authorizer.revokePermission(action, user, await authenticatedContract.getAddress(), { from: root });
            await authorizer.grantPermission(action, user, EVERYWHERE, { from: root });
            const id = await schedule(await authenticatedContract.getAddress());
            const scheduledExecution = await authorizer.getScheduledExecution(id);
            (0, chai_1.expect)(scheduledExecution.executed).to.be.false;
            (0, chai_1.expect)(scheduledExecution.data).to.be.equal(data);
            (0, chai_1.expect)(scheduledExecution.where).to.be.equal(await authenticatedContract.getAddress());
            (0, chai_1.expect)(scheduledExecution.protected).to.be.false;
            (0, chai_1.expect)(scheduledExecution.executableAt).to.be.at.eq((await (0, time_1.currentTimestamp)()) + (0, numbers_1.bn)(delay));
        });
        it('receives canceler status', async () => {
            const id = await schedule(await authenticatedContract.getAddress());
            (0, chai_1.expect)(await authorizer.isCanceler(id, user)).to.be.true;
        });
        it('can cancel the action immediately', async () => {
            const id = await schedule(await authenticatedContract.getAddress());
            // should not revert
            const receipt = await authorizer.cancel(id, { from: user });
            expectEvent.inReceipt(await receipt.wait(), 'ExecutionCanceled', { scheduledExecutionId: id });
        });
        it('schedules the protected execution', async () => {
            const id = await schedule(await authenticatedContract.getAddress(), [executor]);
            const scheduledExecution = await authorizer.getScheduledExecution(id);
            (0, chai_1.expect)(scheduledExecution.executed).to.be.false;
            (0, chai_1.expect)(scheduledExecution.data).to.be.equal(data);
            (0, chai_1.expect)(scheduledExecution.where).to.be.equal(await authenticatedContract.getAddress());
            (0, chai_1.expect)(scheduledExecution.protected).to.be.true;
            (0, chai_1.expect)(scheduledExecution.executableAt).to.be.at.eq((await (0, time_1.currentTimestamp)()) + (0, numbers_1.bn)(delay));
        });
        it('emits ExecutorAdded events', async () => {
            const executors = [executor];
            // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
            const receipt = await authorizer.instance.connect(user).schedule(await authenticatedContract.getAddress(), data, executors.map((e) => e.address));
            for (const executor of executors) {
                expectEvent.inReceipt(await receipt.wait(), 'ExecutorAdded', { executor: executor.address });
            }
        });
        it('emits ExecutionScheduled event', async () => {
            const receipt = await authorizer.instance
                .connect(user)
                .schedule(await authenticatedContract.getAddress(), data, []);
            // There is no getter to fetch _scheduledExecutions.length so we don't know what the next scheduledExecutionId is
            // that is why we hardcore value `2`
            expectEvent.inReceipt(await receipt.wait(), 'ExecutionScheduled', { scheduledExecutionId: 2 });
        });
        it('reverts if an executor is specified twice', async () => {
            await (0, chai_1.expect)(schedule(await authenticatedContract.getAddress(), [executor, executor])).to.be.revertedWith('DUPLICATE_EXECUTORS');
        });
        it('reverts if there is no delay set', async () => {
            action = await (0, actions_1.actionId)(authenticatedContract, 'secondProtectedFunction');
            await authorizer.grantPermission(action, user, await authenticatedContract.getAddress(), { from: root });
            await (0, chai_1.expect)(authorizer.instance
                .connect(user)
                .schedule(await authenticatedContract.getAddress(), authenticatedContract.interface.encodeFunctionData('secondProtectedFunction', [functionData]), [])).to.be.revertedWith('DELAY_IS_NOT_SET');
        });
        it('reverts if the sender has permissions for another contract', async () => {
            await (0, chai_1.expect)(schedule(await anotherAuthenticatedContract.getAddress())).to.be.revertedWith('SENDER_DOES_NOT_HAVE_PERMISSION');
        });
        it('reverts if the sender has permissions for another action', async () => {
            action = await (0, actions_1.actionId)(authenticatedContract, 'secondProtectedFunction');
            await authorizer.scheduleAndExecuteDelayChange(action, delay, { from: root });
            await (0, chai_1.expect)(authorizer.instance
                .connect(user)
                .schedule(await authenticatedContract.getAddress(), authenticatedContract.interface.encodeFunctionData('secondProtectedFunction', [functionData]), [])).to.be.revertedWith('SENDER_DOES_NOT_HAVE_PERMISSION');
        });
        it('reverts if the sender does not have permission', async () => {
            await (0, chai_1.expect)(authorizer.instance
                .connect(other)
                .schedule(await authenticatedContract.getAddress(), authenticatedContract.interface.encodeFunctionData('protectedFunction', [functionData]), [])).to.be.revertedWith('SENDER_DOES_NOT_HAVE_PERMISSION');
        });
        it('reverts if the target is the authorizer', async () => {
            const where = await authorizer.instance.getAddress();
            await (0, chai_1.expect)(schedule(where)).to.be.revertedWith('CANNOT_SCHEDULE_AUTHORIZER_ACTIONS');
        });
        it('reverts the target is the execution helper', async () => {
            const where = await authorizer.instance.getTimelockExecutionHelper();
            await (0, chai_1.expect)(schedule(where)).to.be.revertedWith('ATTEMPTING_EXECUTION_HELPER_REENTRANCY');
        });
        it('reverts if schedule for EOA', async () => {
            // we do not specify reason here because call to an EOA results in the following error:
            // Transaction reverted without a reason
            await (0, chai_1.expect)(authorizer.schedule(other.address, functionData, [], { from: user })).to.be.reverted;
        });
        it('reverts if data is less than 4 bytes', async () => {
            await (0, chai_1.expect)(authorizer.schedule(await authenticatedContract.getAddress(), '0x00', [], { from: user })).to.be.revertedWith('DATA_TOO_SHORT');
        });
    });
    describe('execute', () => {
        const delay = time_1.DAY;
        const functionData = '0x0123456789abcdef';
        (0, sharedBeforeEach_1.sharedBeforeEach)('grant protected function permission with delay', async () => {
            // We must set a delay for the `setAuthorizer` function as well to be able to give one to `protectedFunction`,
            // which it must have in order to be able to schedule calls to it.
            const setAuthorizerAction = await (0, actions_1.actionId)(iVault, 'setAuthorizer');
            await authorizer.scheduleAndExecuteDelayChange(setAuthorizerAction, delay, { from: root });
            const protectedFunctionAction = await (0, actions_1.actionId)(authenticatedContract, 'protectedFunction');
            await authorizer.scheduleAndExecuteDelayChange(protectedFunctionAction, delay, { from: root });
            await authorizer.grantPermission(protectedFunctionAction, user, await authenticatedContract.getAddress(), {
                from: root,
            });
        });
        const schedule = async (executors = undefined) => {
            const data = authenticatedContract.interface.encodeFunctionData('protectedFunction', [functionData]);
            return authorizer.schedule(await authenticatedContract.getAddress(), data, executors || [], { from: user });
        };
        it('can execute an action', async () => {
            const id = await schedule();
            await (0, time_1.advanceTime)(delay);
            await (0, chai_1.expect)(authorizer.execute(id, { from: executor }))
                .to.emit(authenticatedContract, 'ProtectedFunctionCalled')
                .withArgs(functionData);
        });
        it('action is marked as executed', async () => {
            const id = await schedule();
            await (0, time_1.advanceTime)(delay);
            await authorizer.execute(id, { from: executor });
            const scheduledExecution = await authorizer.getScheduledExecution(id);
            (0, chai_1.expect)(scheduledExecution.executed).to.be.true;
        });
        it('stores executor information', async () => {
            const id = await schedule();
            await (0, time_1.advanceTime)(delay);
            await authorizer.execute(id, { from: executor });
            const scheduledExecution = await authorizer.getScheduledExecution(id);
            (0, chai_1.expect)(scheduledExecution.executedBy).to.equal(executor.address);
            (0, chai_1.expect)(scheduledExecution.executedAt).to.equal(await (0, time_1.currentTimestamp)());
        });
        it('stores empty canceler information', async () => {
            const id = await schedule();
            await (0, time_1.advanceTime)(delay);
            await authorizer.execute(id, { from: executor });
            const scheduledExecution = await authorizer.getScheduledExecution(id);
            (0, chai_1.expect)(scheduledExecution.canceledBy).to.equal(constants_1.ZERO_ADDRESS);
            (0, chai_1.expect)(scheduledExecution.canceledAt).to.equal(0);
        });
        it('execute returns a correct result', async () => {
            const id = await schedule();
            await (0, time_1.advanceTime)(delay);
            const ret = await authorizer.instance.connect(executor).execute.staticCall(id);
            // we have to slice first 4 selector bytes from the input data to get the return data
            (0, chai_1.expect)(ret).to.be.eq('0x' + authenticatedContract.interface.encodeFunctionData('protectedFunction', [functionData]).slice(10));
        });
        context('when the action is protected', () => {
            it('all executors can execute', async () => {
                const id = await schedule([executor, account]);
                await (0, time_1.advanceTime)(delay);
                (0, chai_1.expect)(await authorizer.isExecutor(id, executor)).to.be.true;
                (0, chai_1.expect)(await authorizer.isExecutor(id, account)).to.be.true;
                await (0, chai_1.expect)(authorizer.execute(id, { from: account }))
                    .to.emit(authenticatedContract, 'ProtectedFunctionCalled')
                    .withArgs(functionData);
            });
            it('other cannot execute', async () => {
                const id = await schedule([executor]);
                await (0, time_1.advanceTime)(delay);
                await (0, chai_1.expect)(authorizer.execute(id, { from: other })).to.be.revertedWith('SENDER_IS_NOT_EXECUTOR');
            });
        });
        it('can be executed by anyone if not protected', async () => {
            const id = await schedule();
            await (0, time_1.advanceTime)(delay);
            await (0, chai_1.expect)(authorizer.execute(id))
                .to.emit(authenticatedContract, 'ProtectedFunctionCalled')
                .withArgs(functionData);
            const scheduledExecution = await authorizer.getScheduledExecution(id);
            (0, chai_1.expect)(scheduledExecution.executed).to.be.true;
        });
        it('emits an event', async () => {
            const id = await schedule();
            await (0, time_1.advanceTime)(delay);
            const receipt = await authorizer.execute(id, { from: executor });
            expectEvent.inReceipt(await receipt.wait(), 'ExecutionExecuted', {
                scheduledExecutionId: id,
            });
        });
        it('cannot be executed twice', async () => {
            const id = await schedule();
            await (0, time_1.advanceTime)(delay);
            await authorizer.execute(id, { from: executor });
            await (0, chai_1.expect)(authorizer.execute(id, { from: executor })).to.be.revertedWith('EXECUTION_ALREADY_EXECUTED');
        });
        it('reverts if action was canceled', async () => {
            const id = await schedule();
            await (0, time_1.advanceTime)(delay);
            await authorizer.cancel(id, { from: user });
            await (0, chai_1.expect)(authorizer.execute(id, { from: executor })).to.be.revertedWith('EXECUTION_ALREADY_CANCELED');
        });
        it('reverts if the delay has not passed', async () => {
            const id = await schedule();
            await (0, chai_1.expect)(authorizer.execute(id, { from: executor })).to.be.revertedWith('EXECUTION_NOT_YET_EXECUTABLE');
        });
        it('reverts if the scheduled id is invalid', async () => {
            await (0, chai_1.expect)(authorizer.execute(100)).to.be.revertedWith('EXECUTION_DOES_NOT_EXIST');
        });
    });
    describe('cancel', () => {
        const delay = time_1.DAY;
        (0, sharedBeforeEach_1.sharedBeforeEach)('grant protected function permission with delay', async () => {
            // We must set a delay for the `setAuthorizer` function as well to be able to give one to `protectedFunction`,
            // which it must have in order to be able to schedule calls to it.
            const setAuthorizerAction = await (0, actions_1.actionId)(iVault, 'setAuthorizer');
            await authorizer.scheduleAndExecuteDelayChange(setAuthorizerAction, delay, { from: root });
            const protectedFunctionAction = await (0, actions_1.actionId)(authenticatedContract, 'protectedFunction');
            await authorizer.scheduleAndExecuteDelayChange(protectedFunctionAction, delay, { from: root });
            await authorizer.grantPermission(protectedFunctionAction, user, await authenticatedContract.getAddress(), {
                from: root,
            });
        });
        const schedule = async () => {
            const data = authenticatedContract.interface.encodeFunctionData('protectedFunction', ['0x']);
            const id = await authorizer.schedule(await authenticatedContract.getAddress(), data, [], { from: user });
            await authorizer.addCanceler(id, canceler, { from: root });
            return id;
        };
        it('stores canceler information', async () => {
            const id = await schedule();
            await (0, time_1.advanceTime)(delay);
            await authorizer.cancel(id, { from: canceler });
            const scheduledExecution = await authorizer.getScheduledExecution(id);
            (0, chai_1.expect)(scheduledExecution.canceledBy).to.equal(canceler.address);
            (0, chai_1.expect)(scheduledExecution.canceledAt).to.equal(await (0, time_1.currentTimestamp)());
        });
        it('stores empty executor information', async () => {
            const id = await schedule();
            await (0, time_1.advanceTime)(delay);
            await authorizer.cancel(id, { from: canceler });
            const scheduledExecution = await authorizer.getScheduledExecution(id);
            (0, chai_1.expect)(scheduledExecution.executedBy).to.equal(constants_1.ZERO_ADDRESS);
            (0, chai_1.expect)(scheduledExecution.executedAt).to.equal(0);
        });
        it('specific canceler can cancel the action', async () => {
            const id = await schedule();
            await authorizer.cancel(id, { from: canceler });
            const scheduledExecution = await authorizer.getScheduledExecution(id);
            (0, chai_1.expect)(scheduledExecution.canceled).to.be.true;
        });
        it('global canceler can cancel the action', async () => {
            await authorizer.addCanceler(GLOBAL_CANCELER_SCHEDULED_EXECUTION_ID, canceler, { from: root });
            const id = await authorizer.schedule(await authenticatedContract.getAddress(), authenticatedContract.interface.encodeFunctionData('protectedFunction', ['0x']), [], { from: user });
            await authorizer.cancel(id, { from: canceler });
            const scheduledExecution = await authorizer.getScheduledExecution(id);
            (0, chai_1.expect)(scheduledExecution.canceled).to.be.true;
        });
        it('root canceler can cancel the action', async () => {
            const id = await schedule();
            await authorizer.cancel(id, { from: root });
            const scheduledExecution = await authorizer.getScheduledExecution(id);
            (0, chai_1.expect)(scheduledExecution.canceled).to.be.true;
        });
        it('emits an event', async () => {
            const id = await schedule();
            const receipt = await authorizer.cancel(id, { from: canceler });
            expectEvent.inReceipt(await receipt.wait(), 'ExecutionCanceled', { scheduledExecutionId: id });
        });
        it('cannot be canceled twice', async () => {
            const id = await schedule();
            await authorizer.cancel(id, { from: canceler });
            await (0, chai_1.expect)(authorizer.cancel(id, { from: canceler })).to.be.revertedWith('EXECUTION_ALREADY_CANCELED');
        });
        it('reverts if the scheduled id is invalid', async () => {
            await (0, chai_1.expect)(authorizer.cancel(100)).to.be.revertedWith('EXECUTION_DOES_NOT_EXIST');
        });
        it('reverts if action was executed', async () => {
            const id = await schedule();
            await (0, time_1.advanceTime)(delay);
            await authorizer.execute(id);
            await (0, chai_1.expect)(authorizer.cancel(id, { from: canceler })).to.be.revertedWith('EXECUTION_ALREADY_EXECUTED');
        });
        it('reverts if sender is not canceler', async () => {
            const id = await schedule();
            await (0, chai_1.expect)(authorizer.cancel(id, { from: other })).to.be.revertedWith('SENDER_IS_NOT_CANCELER');
        });
    });
    describe('getScheduledExecutions', () => {
        const delay = time_1.DAY * 5;
        (0, sharedBeforeEach_1.sharedBeforeEach)('set authorizer permission delay', async () => {
            // We must set a delay for the `setAuthorizer` function as well to be able to give one to `protectedFunction`,
            // which it must have in order to be able to schedule calls to it.
            const setAuthorizerAction = await (0, actions_1.actionId)(iVault, 'setAuthorizer');
            await authorizer.scheduleAndExecuteDelayChange(setAuthorizerAction, 2 * delay, { from: root });
        });
        (0, sharedBeforeEach_1.sharedBeforeEach)('grant permission', async () => {
            const action = await (0, actions_1.actionId)(authenticatedContract, 'protectedFunction');
            await authorizer.grantPermission(action, user, await authenticatedContract.getAddress(), { from: root });
            await authorizer.scheduleAndExecuteDelayChange(action, delay, { from: root });
        });
        const schedule = async (functionData) => {
            return authorizer.schedule(await authenticatedContract.getAddress(), authenticatedContract.interface.encodeFunctionData('protectedFunction', [functionData]), [], { from: user });
        };
        // We will schedule 5 calls to `protectedFunction`, with data 0x00, 0x01, 0x02, etc.
        const SCHEDULED_ENTRIES = 5;
        // There'll be two extra entries: the one used to set the delay for setAuthorizer, and the one used to set the delay
        // for `protectedFunction`.
        const TOTAL_ENTRIES = SCHEDULED_ENTRIES + 2;
        const LARGE_MAX_SIZE = 10; // This is more than there are total entries, so it won't affect the result
        (0, sharedBeforeEach_1.sharedBeforeEach)('schedule multiple entries', async () => {
            for (let i = 0; i < SCHEDULED_ENTRIES; ++i) {
                await schedule(`0x0${i}`);
            }
        });
        it('returns the number of total entries', async () => {
            (0, chai_1.expect)(await authorizer.instance.getScheduledExecutionsCount()).to.equal(TOTAL_ENTRIES);
        });
        it('reverts if the skip value is too large', async () => {
            await (0, chai_1.expect)(authorizer.instance.getScheduledExecutions(TOTAL_ENTRIES, LARGE_MAX_SIZE, false)).to.be.revertedWith('SKIP_VALUE_TOO_LARGE');
        });
        it('reverts if the maxSize value is zero', async () => {
            await (0, chai_1.expect)(authorizer.instance.getScheduledExecutions(0, 0, false)).to.be.revertedWith('ZERO_MAX_SIZE_VALUE');
        });
        context('in chronological order', () => {
            const reverseOrder = false;
            it('returns entries in chronological order', async () => {
                const entries = await authorizer.instance.getScheduledExecutions(0, LARGE_MAX_SIZE, reverseOrder);
                (0, chai_1.expect)(entries.length).to.equal(TOTAL_ENTRIES);
                // The first entry is the one that sets the setAuthorizer delay
                (0, chai_1.expect)(entries[0].where).to.equal(await authorizer.address());
                (0, chai_1.expect)(entries[0].data).to.equal(authorizer.interface.encodeFunctionData('setDelay', [await (0, actions_1.actionId)(iVault, 'setAuthorizer'), 2 * delay]));
                // The last entry is the one that we scheduled
                (0, chai_1.expect)(entries[entries.length - 1].where).to.equal(await authenticatedContract.getAddress());
                (0, chai_1.expect)(entries[entries.length - 1].data).to.equal(authenticatedContract.interface.encodeFunctionData('protectedFunction', [`0x04`]));
            });
            it('skips older entries', async () => {
                // We skip the initial two entries (setDelay for setAuthorizer and setDelay for protectedFunction)
                const entries = await authorizer.instance.getScheduledExecutions(2, LARGE_MAX_SIZE, reverseOrder);
                (0, chai_1.expect)(entries.length).to.equal(SCHEDULED_ENTRIES);
                (0, chai_1.expect)(entries[0].where).to.equal(await authenticatedContract.getAddress());
                (0, chai_1.expect)(entries[0].data).to.equal(authenticatedContract.interface.encodeFunctionData('protectedFunction', [`0x00`]));
                // The last entry is the one that we scheduled
                (0, chai_1.expect)(entries[entries.length - 1].where).to.equal(await authenticatedContract.getAddress());
                (0, chai_1.expect)(entries[entries.length - 1].data).to.equal(authenticatedContract.interface.encodeFunctionData('protectedFunction', [`0x04`]));
            });
            it('trims newer entries with lower maxSize', async () => {
                // This skips the initial two entries, but only returns 3 of the `protectedFunction` calls
                const entries = await authorizer.instance.getScheduledExecutions(2, 3, reverseOrder);
                (0, chai_1.expect)(entries.length).to.equal(3);
                (0, chai_1.expect)(entries[0].where).to.equal(await authenticatedContract.getAddress());
                (0, chai_1.expect)(entries[0].data).to.equal(authenticatedContract.interface.encodeFunctionData('protectedFunction', [`0x00`]));
                (0, chai_1.expect)(entries[2].where).to.equal(await authenticatedContract.getAddress());
                (0, chai_1.expect)(entries[2].data).to.equal(authenticatedContract.interface.encodeFunctionData('protectedFunction', [`0x02`]));
            });
        });
        context('in reverse chronological order', () => {
            const reverseOrder = true;
            it('returns entries in reverse chronological order', async () => {
                const entries = await authorizer.instance.getScheduledExecutions(0, LARGE_MAX_SIZE, reverseOrder);
                (0, chai_1.expect)(entries.length).to.equal(TOTAL_ENTRIES);
                // The first entry is the last one that we scheduled
                (0, chai_1.expect)(entries[0].where).to.equal(await authenticatedContract.getAddress());
                (0, chai_1.expect)(entries[0].data).to.equal(authenticatedContract.interface.encodeFunctionData('protectedFunction', [`0x04`]));
                // The last entry is the one that sets the setAuthorizer delay
                (0, chai_1.expect)(entries[entries.length - 1].where).to.equal(await authorizer.address());
                (0, chai_1.expect)(entries[entries.length - 1].data).to.equal(authorizer.interface.encodeFunctionData('setDelay', [await (0, actions_1.actionId)(iVault, 'setAuthorizer'), 2 * delay]));
            });
            it('skips newer entries', async () => {
                // We skip the last two entries (the last two calls to `protectedFunction`)
                const entries = await authorizer.instance.getScheduledExecutions(2, LARGE_MAX_SIZE, reverseOrder);
                (0, chai_1.expect)(entries.length).to.equal(TOTAL_ENTRIES - 2);
                // The first entry is the third to last that we scheduled
                (0, chai_1.expect)(entries[0].where).to.equal(await authenticatedContract.getAddress());
                (0, chai_1.expect)(entries[0].data).to.equal(authenticatedContract.interface.encodeFunctionData('protectedFunction', [`0x02`]));
                // The last entry is the one that sets the setAuthorizer delay
                (0, chai_1.expect)(entries[entries.length - 1].where).to.equal(await authorizer.address());
                (0, chai_1.expect)(entries[entries.length - 1].data).to.equal(authorizer.interface.encodeFunctionData('setDelay', [await (0, actions_1.actionId)(iVault, 'setAuthorizer'), 2 * delay]));
            });
            it('trims newer entries with lower maxSize', async () => {
                // This skips the last two calls to `protectedFunction`, but only returns 3 of the `protectedFunction` calls
                // (trimming the two initial setup actions).
                const entries = await authorizer.instance.getScheduledExecutions(2, 3, reverseOrder);
                (0, chai_1.expect)(entries.length).to.equal(3);
                // This is the third to last scheduled call to `protectedFunction`
                (0, chai_1.expect)(entries[0].where).to.equal(await authenticatedContract.getAddress());
                (0, chai_1.expect)(entries[0].data).to.equal(authenticatedContract.interface.encodeFunctionData('protectedFunction', [`0x02`]));
                // This is the first scheduled call to `protectedFunction`
                (0, chai_1.expect)(entries[2].where).to.equal(await authenticatedContract.getAddress());
                (0, chai_1.expect)(entries[2].data).to.equal(authenticatedContract.interface.encodeFunctionData('protectedFunction', [`0x00`]));
            });
        });
    });
});
