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
const actions_1 = require("@balancer-labs/v3-helpers/src/models/misc/actions");
const time_1 = require("@balancer-labs/v3-helpers/src/time");
const sharedBeforeEach_1 = require("@balancer-labs/v3-common/sharedBeforeEach");
const constants_1 = require("@balancer-labs/v3-helpers/src/constants");
const lodash_1 = require("lodash");
const contract_1 = require("@balancer-labs/v3-helpers/src/contract");
const TypesConverter_1 = __importDefault(require("@balancer-labs/v3-helpers/src/models/types/TypesConverter"));
const numbers_1 = require("@balancer-labs/v3-helpers/src/numbers");
describe('TimelockAuthorizer permissions', () => {
    let authorizer, vault;
    let root, nextRoot, revoker, granter, user, other;
    before('setup signers', async () => {
        [, root, nextRoot, granter, revoker, user, other] = await hardhat_1.ethers.getSigners();
    });
    const ACTION_1 = '0x0000000000000000000000000000000000000000000000000000000000000001';
    const ACTION_2 = '0x0000000000000000000000000000000000000000000000000000000000000002';
    const ACTION_3 = '0x0000000000000000000000000000000000000000000000000000000000000003';
    const WHERE_1 = hardhat_1.ethers.Wallet.createRandom().address;
    const WHERE_2 = hardhat_1.ethers.Wallet.createRandom().address;
    const WHERE_3 = hardhat_1.ethers.Wallet.createRandom().address;
    const EVERYWHERE = TimelockAuthorizerHelper_1.default.EVERYWHERE;
    const NOT_WHERE = hardhat_1.ethers.Wallet.createRandom().address;
    const MINIMUM_EXECUTION_DELAY = 5 * time_1.DAY;
    (0, sharedBeforeEach_1.sharedBeforeEach)('deploy authorizer', async () => {
        vault = await VaultDeployer.deploy();
        const authorizerContract = (await (0, contract_1.deploy)('TimelockAuthorizer', {
            args: [root, nextRoot, vault, MINIMUM_EXECUTION_DELAY],
        }));
        authorizer = new TimelockAuthorizerHelper_1.default(authorizerContract, root);
    });
    describe('grantPermission', () => {
        context('when there is a delay set to grant permissions', () => {
            const delay = time_1.DAY;
            (0, sharedBeforeEach_1.sharedBeforeEach)('set delay', async () => {
                const iVault = await TypesConverter_1.default.toIVault(vault);
                const setAuthorizerAction = await (0, actions_1.actionId)(iVault, 'setAuthorizer');
                await authorizer.scheduleAndExecuteDelayChange(setAuthorizerAction, delay * 2, { from: root });
                await authorizer.scheduleAndExecuteGrantDelayChange(ACTION_1, delay, { from: root });
            });
            it('reverts if requires a schedule', async () => {
                await (0, chai_1.expect)(authorizer.grantPermission(ACTION_1, user, WHERE_1, { from: root })).to.be.revertedWith('GRANT_MUST_BE_SCHEDULED');
            });
        });
        context('when there is a no delay set to grant permissions', () => {
            function itGrantsPermissionCorrectly(getSender) {
                it('reverts if the sender is not the granter', async () => {
                    await (0, chai_1.expect)(authorizer.grantPermission(ACTION_1, user, WHERE_1, { from: other })).to.be.revertedWith('SENDER_IS_NOT_GRANTER');
                });
                context('when the target does not have the permission', () => {
                    context('when granting the permission for a contract', () => {
                        it('grants permission to perform the requested action for the requested contract', async () => {
                            await authorizer.grantPermission(ACTION_1, user, WHERE_1, { from: getSender() });
                            (0, chai_1.expect)(await authorizer.canPerform(ACTION_1, user, WHERE_1)).to.be.true;
                        });
                        it('does not grant permission to perform the requested action everywhere', async () => {
                            await authorizer.grantPermission(ACTION_1, user, WHERE_1, { from: getSender() });
                            (0, chai_1.expect)(await authorizer.canPerform(ACTION_1, user, EVERYWHERE)).to.be.false;
                        });
                        it('does not grant permission to perform the requested actions for other contracts', async () => {
                            await authorizer.grantPermission(ACTION_1, user, WHERE_1, { from: getSender() });
                            (0, chai_1.expect)(await authorizer.canPerform(ACTION_1, user, NOT_WHERE)).to.be.false;
                        });
                        it('emits an event', async () => {
                            const receipt = await (await authorizer.grantPermission(ACTION_1, user, WHERE_1, { from: getSender() })).wait();
                            expectEvent.inReceipt(receipt, 'PermissionGranted', {
                                actionId: ACTION_1,
                                account: user.address,
                                where: WHERE_1,
                            });
                        });
                    });
                    context('when granting the permission for everywhere', () => {
                        it('grants the permission to perform the requested action everywhere', async () => {
                            await authorizer.grantPermissionGlobally(ACTION_1, user, { from: getSender() });
                            (0, chai_1.expect)(await authorizer.canPerform(ACTION_1, user, EVERYWHERE)).to.be.true;
                            (0, chai_1.expect)(await authorizer.canPerform(ACTION_2, user, EVERYWHERE)).to.be.false;
                        });
                        it('grants permission to perform the requested action in any specific contract', async () => {
                            await authorizer.grantPermissionGlobally(ACTION_1, user, { from: getSender() });
                            (0, chai_1.expect)(await authorizer.canPerform(ACTION_1, user, NOT_WHERE)).to.be.true;
                            (0, chai_1.expect)(await authorizer.canPerform(ACTION_1, user, WHERE_2)).to.be.true;
                        });
                        it('emits an event', async () => {
                            const receipt = await (await authorizer.grantPermissionGlobally(ACTION_1, user, { from: getSender() })).wait();
                            expectEvent.inReceipt(receipt, 'PermissionGranted', {
                                actionId: ACTION_1,
                                account: user.address,
                                where: TimelockAuthorizerHelper_1.default.EVERYWHERE,
                            });
                        });
                    });
                });
                context('when the target has the permission for a contract', () => {
                    (0, sharedBeforeEach_1.sharedBeforeEach)('grant a permission', async () => {
                        await authorizer.grantPermission(ACTION_1, user, WHERE_1, { from: getSender() });
                    });
                    it('cannot grant the permission twice', async () => {
                        await (0, chai_1.expect)(authorizer.grantPermission(ACTION_1, user, WHERE_1, { from: getSender() })).to.be.revertedWith('PERMISSION_ALREADY_GRANTED');
                    });
                    context('when granting the permission for everywhere', () => {
                        it('grants permission to perform the requested action everywhere', async () => {
                            await authorizer.grantPermissionGlobally(ACTION_1, user, { from: getSender() });
                            (0, chai_1.expect)(await authorizer.canPerform(ACTION_1, user, EVERYWHERE)).to.be.true;
                            (0, chai_1.expect)(await authorizer.canPerform(ACTION_1, user, WHERE_2)).to.be.true;
                        });
                        it('emits an event', async () => {
                            const receipt = await (await authorizer.grantPermissionGlobally(ACTION_1, user, { from: getSender() })).wait();
                            expectEvent.inReceipt(receipt, 'PermissionGranted', {
                                actionId: ACTION_1,
                                account: user.address,
                                where: TimelockAuthorizerHelper_1.default.EVERYWHERE,
                            });
                        });
                    });
                });
                context('when the target has the permission for everywhere', () => {
                    (0, sharedBeforeEach_1.sharedBeforeEach)('grant the permission', async () => {
                        await authorizer.grantPermissionGlobally(ACTION_1, user, { from: getSender() });
                    });
                    context('when granting the permission for a contract', () => {
                        it('cannot grant the permission twice', async () => {
                            await (0, chai_1.expect)(authorizer.grantPermission(ACTION_1, user, WHERE_1, { from: getSender() })).to.be.revertedWith('PERMISSION_ALREADY_GRANTED');
                        });
                    });
                    it('cannot grant the permision twice', async () => {
                        await (0, chai_1.expect)(authorizer.grantPermissionGlobally(ACTION_1, user, { from: getSender() })).to.revertedWith('PERMISSION_ALREADY_GRANTED');
                    });
                });
            }
            context('when the sender is root', () => {
                itGrantsPermissionCorrectly(() => root);
            });
            context('when the sender is granter everywhere', () => {
                (0, sharedBeforeEach_1.sharedBeforeEach)('makes a granter', async () => {
                    await authorizer.addGranter(ACTION_1, granter, EVERYWHERE, { from: root });
                    await authorizer.addGranter(ACTION_2, granter, EVERYWHERE, { from: root });
                });
                itGrantsPermissionCorrectly(() => granter);
                it('cannot grant the permission in other actions', async () => {
                    await (0, chai_1.expect)(authorizer.grantPermission(ACTION_3, user, WHERE_1, { from: granter })).to.be.revertedWith('SENDER_IS_NOT_GRANTER');
                });
            });
            context('when the sender is granter at a specific contract', () => {
                (0, sharedBeforeEach_1.sharedBeforeEach)('makes a granter', async () => {
                    await authorizer.addGranter(ACTION_1, granter, WHERE_1, { from: root });
                });
                it('reverts if the sender is not the granter', async () => {
                    await (0, chai_1.expect)(authorizer.grantPermission(ACTION_1, user, WHERE_1, { from: other })).to.be.revertedWith('SENDER_IS_NOT_GRANTER');
                });
                it('cannot grant the permission in other contracts', async () => {
                    await (0, chai_1.expect)(authorizer.grantPermission(ACTION_1, user, WHERE_3, { from: granter })).to.be.revertedWith('SENDER_IS_NOT_GRANTER');
                });
                it('cannot grant the permission for other actions', async () => {
                    await (0, chai_1.expect)(authorizer.grantPermission(ACTION_3, user, WHERE_1, { from: granter })).to.be.revertedWith('SENDER_IS_NOT_GRANTER');
                });
                context('when the target does not have the permission', () => {
                    context('when granting the permission for a contract', () => {
                        it('grants permission to perform the requested action for the requested contract', async () => {
                            await authorizer.grantPermission(ACTION_1, user, WHERE_1, { from: granter });
                            (0, chai_1.expect)(await authorizer.canPerform(ACTION_1, user, WHERE_1)).to.be.true;
                        });
                        it('does not grant permission to perform the requested action everywhere', async () => {
                            await authorizer.grantPermission(ACTION_1, user, WHERE_1, { from: granter });
                            (0, chai_1.expect)(await authorizer.canPerform(ACTION_1, user, EVERYWHERE)).to.be.false;
                        });
                        it('does not grant permission to perform the requested actions for other contracts', async () => {
                            await authorizer.grantPermission(ACTION_1, user, WHERE_1, { from: granter });
                            (0, chai_1.expect)(await authorizer.canPerform(ACTION_1, user, NOT_WHERE)).to.be.false;
                        });
                        it('emits an event', async () => {
                            const receipt = await (await authorizer.grantPermission(ACTION_1, user, WHERE_1, { from: granter })).wait();
                            expectEvent.inReceipt(receipt, 'PermissionGranted', {
                                actionId: ACTION_1,
                                account: user.address,
                                where: WHERE_1,
                            });
                        });
                    });
                });
                context('when the target has the permission for a contract', () => {
                    it('cannot grant the same permission twice', async () => {
                        await authorizer.grantPermission(ACTION_1, user, WHERE_1, { from: granter });
                        await (0, chai_1.expect)(authorizer.grantPermission(ACTION_1, user, WHERE_1, { from: granter })).to.revertedWith('PERMISSION_ALREADY_GRANTED');
                    });
                });
                context('when the target has the permission for everywhere', () => {
                    (0, sharedBeforeEach_1.sharedBeforeEach)('grant the permission', async () => {
                        await authorizer.grantPermissionGlobally(ACTION_1, user, { from: root });
                    });
                    context('when granting the permission for a contract', () => {
                        it('cannot grant the permission twice', async () => {
                            await (0, chai_1.expect)(authorizer.grantPermission(ACTION_1, user, WHERE_1, { from: granter })).to.be.revertedWith('PERMISSION_ALREADY_GRANTED');
                        });
                    });
                });
            });
        });
    });
    describe('scheduleGrantPermission', () => {
        const delay = time_1.DAY;
        (0, sharedBeforeEach_1.sharedBeforeEach)('set delay', async () => {
            const iVault = await TypesConverter_1.default.toIVault(vault);
            const setAuthorizerAction = await (0, actions_1.actionId)(iVault, 'setAuthorizer');
            await authorizer.scheduleAndExecuteDelayChange(setAuthorizerAction, delay * 2, { from: root });
            await authorizer.scheduleAndExecuteGrantDelayChange(ACTION_1, delay, { from: root });
        });
        it('reverts if action has no grant delay', async () => {
            await (0, chai_1.expect)(authorizer.scheduleGrantPermission(ACTION_2, user, WHERE_1, [], { from: root })).to.be.revertedWith('ACTION_HAS_NO_GRANT_DELAY');
        });
        it('reverts if sender is not granter', async () => {
            await (0, chai_1.expect)(authorizer.scheduleGrantPermission(ACTION_1, user, WHERE_1, [], { from: other })).to.be.revertedWith('SENDER_IS_NOT_GRANTER');
        });
        function itScheduleGrantPermissionCorrectly(getSender) {
            it('schedules a grant permission', async () => {
                const id = await authorizer.scheduleGrantPermission(ACTION_1, user, WHERE_1, [], { from: getSender() });
                const { executed, data, where, executableAt } = await authorizer.getScheduledExecution(id);
                (0, chai_1.expect)(executed).to.be.false;
                (0, chai_1.expect)(data).to.be.equal(authorizer.instance.interface.encodeFunctionData('grantPermission', [ACTION_1, user.address, WHERE_1]));
                (0, chai_1.expect)(where).to.be.equal(await authorizer.address());
                (0, chai_1.expect)(executableAt).to.equal((await (0, time_1.currentTimestamp)()) + (0, numbers_1.bn)(delay));
            });
            it('increases the scheduled execution count', async () => {
                const countBefore = await authorizer.instance.getScheduledExecutionsCount();
                await authorizer.scheduleGrantPermission(ACTION_1, user, WHERE_1, [], { from: getSender() });
                const countAfter = await authorizer.instance.getScheduledExecutionsCount();
                (0, chai_1.expect)(countAfter).to.equal(countBefore + 1n);
            });
            it('stores scheduler information', async () => {
                const id = await authorizer.scheduleGrantPermission(ACTION_1, user, WHERE_1, [], { from: getSender() });
                const scheduledExecution = await authorizer.getScheduledExecution(id);
                (0, chai_1.expect)(scheduledExecution.scheduledBy).to.equal(getSender().address);
                (0, chai_1.expect)(scheduledExecution.scheduledAt).to.equal(await (0, time_1.currentTimestamp)());
            });
            it('stores empty executor and canceler information', async () => {
                const id = await authorizer.scheduleGrantPermission(ACTION_1, user, WHERE_1, [], { from: getSender() });
                const scheduledExecution = await authorizer.getScheduledExecution(id);
                (0, chai_1.expect)(scheduledExecution.executedBy).to.equal(constants_1.ZERO_ADDRESS);
                (0, chai_1.expect)(scheduledExecution.executedAt).to.equal(0);
                (0, chai_1.expect)(scheduledExecution.canceledBy).to.equal(constants_1.ZERO_ADDRESS);
                (0, chai_1.expect)(scheduledExecution.canceledAt).to.equal(0);
            });
            it('execution can be unprotected', async () => {
                const id = await authorizer.scheduleGrantPermission(ACTION_1, user, WHERE_1, [], { from: getSender() });
                const execution = await authorizer.getScheduledExecution(id);
                (0, chai_1.expect)(execution.protected).to.be.false;
            });
            it('execution can be protected', async () => {
                const executors = (0, lodash_1.range)(4).map(constants_1.randomAddress);
                const id = await authorizer.scheduleGrantPermission(ACTION_1, user, WHERE_1, executors, { from: getSender() });
                const execution = await authorizer.getScheduledExecution(id);
                (0, chai_1.expect)(execution.protected).to.be.true;
                await Promise.all(executors.map(async (executor) => (0, chai_1.expect)(await authorizer.isExecutor(id, executor)).to.be.true));
            });
            it('granter can cancel the execution', async () => {
                const id = await authorizer.scheduleGrantPermission(ACTION_1, user, WHERE_1, [], { from: getSender() });
                (0, chai_1.expect)(await authorizer.isCanceler(id, getSender())).to.be.true;
                const receipt = await authorizer.cancel(id, { from: getSender() });
                expectEvent.inReceipt(await receipt.wait(), 'ExecutionCanceled', { scheduledExecutionId: id });
            });
            it('can be executed after the expected delay', async () => {
                const id = await authorizer.scheduleGrantPermission(ACTION_1, user, WHERE_1, [], { from: getSender() });
                await (0, time_1.advanceTime)(delay);
                const receipt = await authorizer.execute(id);
                expectEvent.inReceipt(await receipt.wait(), 'ExecutionExecuted', { scheduledExecutionId: id });
            });
            it('grants the permission when executed', async () => {
                const id = await authorizer.scheduleGrantPermission(ACTION_1, user, WHERE_1, [], { from: getSender() });
                await (0, time_1.advanceTime)(delay);
                await authorizer.execute(id);
                (0, chai_1.expect)(await authorizer.hasPermission(ACTION_1, user, WHERE_1)).to.be.equal(true);
            });
            it('does not grant any other permissions when executed', async () => {
                const id = await authorizer.scheduleGrantPermission(ACTION_1, user, WHERE_1, [], { from: getSender() });
                await (0, time_1.advanceTime)(delay);
                const receipt = await authorizer.execute(id);
                expectEvent.inReceipt(await receipt.wait(), 'PermissionGranted', {
                    actionId: ACTION_1,
                    account: user.address,
                    where: WHERE_1,
                });
                (0, chai_1.expect)(await authorizer.hasPermission(ACTION_3, user, WHERE_1)).to.be.equal(false);
                (0, chai_1.expect)(await authorizer.hasPermission(ACTION_2, user, WHERE_2)).to.be.equal(false);
            });
            it('emits an event', async () => {
                const receipt = await authorizer.instance
                    .connect(getSender())
                    .scheduleGrantPermission(ACTION_1, user.address, WHERE_1, []);
                expectEvent.inReceipt(await receipt.wait(), 'GrantPermissionScheduled', {
                    actionId: ACTION_1,
                    account: user.address,
                    where: WHERE_1,
                });
            });
        }
        context('when the sender is root', () => {
            itScheduleGrantPermissionCorrectly(() => root);
        });
        context('when the sender is granter everywhere', () => {
            (0, sharedBeforeEach_1.sharedBeforeEach)('makes a granter', async () => {
                await authorizer.addGranter(ACTION_1, granter, EVERYWHERE, { from: root });
            });
            it('cannot grant the permission for other actions', async () => {
                await (0, chai_1.expect)(authorizer.scheduleGrantPermission(ACTION_3, user, WHERE_1, [], { from: granter })).to.be.revertedWith('SENDER_IS_NOT_GRANTER');
            });
            itScheduleGrantPermissionCorrectly(() => granter);
        });
        context('when the sender is granter for a specific contract', () => {
            (0, sharedBeforeEach_1.sharedBeforeEach)('makes a granter', async () => {
                await authorizer.addGranter(ACTION_1, granter, WHERE_1, { from: root });
            });
            it('cannot grant the permission in other contracts', async () => {
                await (0, chai_1.expect)(authorizer.scheduleGrantPermission(ACTION_1, user, WHERE_3, [], { from: granter })).to.be.revertedWith('SENDER_IS_NOT_GRANTER');
            });
            it('cannot grant the permission for other actions', async () => {
                await (0, chai_1.expect)(authorizer.scheduleGrantPermission(ACTION_3, user, WHERE_1, [], { from: granter })).to.be.revertedWith('SENDER_IS_NOT_GRANTER');
            });
            itScheduleGrantPermissionCorrectly(() => granter);
        });
    });
    describe('revokePermission', () => {
        const delay = time_1.DAY;
        context('when there is a delay set to revoke permissions', () => {
            (0, sharedBeforeEach_1.sharedBeforeEach)('set delay', async () => {
                const iVault = await TypesConverter_1.default.toIVault(vault);
                const setAuthorizerAction = await (0, actions_1.actionId)(iVault, 'setAuthorizer');
                await authorizer.scheduleAndExecuteDelayChange(setAuthorizerAction, delay * 2, { from: root });
                await authorizer.scheduleAndExecuteRevokeDelayChange(ACTION_1, delay, { from: root });
            });
            it('reverts if requires a schedule', async () => {
                await (0, chai_1.expect)(authorizer.revokePermission(ACTION_1, user, WHERE_1, { from: root })).to.be.revertedWith('REVOKE_MUST_BE_SCHEDULED');
            });
        });
        context('when there is a no delay set to revoke permissions', () => {
            it('reverts if the sender is not the revoker', async () => {
                await (0, chai_1.expect)(authorizer.revokePermission(ACTION_1, user, WHERE_1, { from: revoker })).to.be.revertedWith('SENDER_IS_NOT_REVOKER');
            });
            function itRevokesPermissionCorrectly(getSender) {
                context('when the user does not have the permission', () => {
                    it('cannot revoke the permission', async () => {
                        await (0, chai_1.expect)(authorizer.revokePermission(ACTION_1, user, WHERE_1, { from: getSender() })).to.be.revertedWith('PERMISSION_NOT_GRANTED');
                    });
                    it('cannot perform the requested action everywhere', async () => {
                        (0, chai_1.expect)(await authorizer.canPerform(ACTION_1, user, EVERYWHERE)).to.be.false;
                        (0, chai_1.expect)(await authorizer.canPerform(ACTION_2, user, EVERYWHERE)).to.be.false;
                    });
                    it('cannot perform the requested action in any specific contract', async () => {
                        (0, chai_1.expect)(await authorizer.canPerform(ACTION_1, user, NOT_WHERE)).to.be.false;
                        (0, chai_1.expect)(await authorizer.canPerform(ACTION_1, user, WHERE_2)).to.be.false;
                    });
                });
                context('when the user has the permission for a contract', () => {
                    (0, sharedBeforeEach_1.sharedBeforeEach)('grants the permission', async () => {
                        await authorizer.grantPermission(ACTION_1, user, WHERE_1, { from: root });
                    });
                    context('when revoking the permission for a contract', () => {
                        it('revokes the requested permission for the requested contract', async () => {
                            await authorizer.revokePermission(ACTION_1, user, WHERE_1, { from: getSender() });
                            (0, chai_1.expect)(await authorizer.canPerform(ACTION_1, user, WHERE_1)).to.be.false;
                            (0, chai_1.expect)(await authorizer.canPerform(ACTION_2, user, WHERE_1)).to.be.false;
                            (0, chai_1.expect)(await authorizer.canPerform(ACTION_1, user, WHERE_2)).to.be.false;
                            (0, chai_1.expect)(await authorizer.canPerform(ACTION_2, user, WHERE_2)).to.be.false;
                        });
                        it('still cannot perform the requested action everywhere', async () => {
                            await authorizer.revokePermission(ACTION_1, user, WHERE_1, { from: getSender() });
                            (0, chai_1.expect)(await authorizer.canPerform(ACTION_1, user, EVERYWHERE)).to.be.false;
                            (0, chai_1.expect)(await authorizer.canPerform(ACTION_2, user, EVERYWHERE)).to.be.false;
                        });
                        it('emits an event', async () => {
                            const receipt = await (await authorizer.revokePermission(ACTION_1, user, WHERE_1, { from: getSender() })).wait();
                            expectEvent.inReceipt(receipt, 'PermissionRevoked', {
                                actionId: ACTION_1,
                                account: user.address,
                                where: WHERE_1,
                            });
                        });
                    });
                    context('when revoking the permission for a everywhere', () => {
                        it('cannot revoke the permission', async () => {
                            await (0, chai_1.expect)(authorizer.revokePermissionGlobally(ACTION_1, user, { from: getSender() })).to.be.revertedWith('PERMISSION_NOT_GRANTED');
                        });
                    });
                });
                context('when the user has the permission everywhere', () => {
                    (0, sharedBeforeEach_1.sharedBeforeEach)('grants the permissions', async () => {
                        await authorizer.grantPermissionGlobally(ACTION_1, user, { from: root });
                    });
                    context('when revoking the permission for a contract', () => {
                        it('cannot revoke the permission', async () => {
                            await (0, chai_1.expect)(authorizer.revokePermission(ACTION_1, user, WHERE_1, { from: getSender() })).to.be.revertedWith('ACCOUNT_HAS_GLOBAL_PERMISSION');
                        });
                        it('can perform the requested action for the requested contract', async () => {
                            (0, chai_1.expect)(await authorizer.canPerform(ACTION_1, user, WHERE_1)).to.be.true;
                            (0, chai_1.expect)(await authorizer.canPerform(ACTION_1, user, WHERE_2)).to.be.true;
                        });
                        it('can perform the requested action everywhere', async () => {
                            (0, chai_1.expect)(await authorizer.canPerform(ACTION_1, user, EVERYWHERE)).to.be.true;
                        });
                    });
                    context('when revoking the permission for a everywhere', () => {
                        it('revokes the requested global permission and cannot perform the requested action everywhere', async () => {
                            await authorizer.revokePermissionGlobally(ACTION_1, user, { from: getSender() });
                            (0, chai_1.expect)(await authorizer.canPerform(ACTION_1, user, WHERE_1)).to.be.false;
                            (0, chai_1.expect)(await authorizer.canPerform(ACTION_1, user, WHERE_2)).to.be.false;
                        });
                        it('cannot perform the requested action in any specific contract', async () => {
                            await authorizer.revokePermissionGlobally(ACTION_1, user, { from: getSender() });
                            (0, chai_1.expect)(await authorizer.canPerform(ACTION_1, user, NOT_WHERE)).to.be.false;
                            (0, chai_1.expect)(await authorizer.canPerform(ACTION_1, user, WHERE_2)).to.be.false;
                        });
                        it('emits an event', async () => {
                            const receipt = await (await authorizer.revokePermissionGlobally(ACTION_1, user, { from: getSender() })).wait();
                            expectEvent.inReceipt(receipt, 'PermissionRevoked', {
                                actionId: ACTION_1,
                                account: user.address,
                                where: TimelockAuthorizerHelper_1.default.EVERYWHERE,
                            });
                        });
                    });
                });
                context('when the user has the permission in a specific contract and everywhere', () => {
                    (0, sharedBeforeEach_1.sharedBeforeEach)('grants the permissions', async () => {
                        await authorizer.grantPermission(ACTION_1, user, WHERE_1, { from: root });
                        await authorizer.grantPermissionGlobally(ACTION_1, user, { from: root });
                    });
                    context('when revoking the permission for a contract', () => {
                        it('cannot revoke the permission', async () => {
                            await (0, chai_1.expect)(authorizer.revokePermission(ACTION_1, user, WHERE_1, { from: getSender() })).to.be.revertedWith('ACCOUNT_HAS_GLOBAL_PERMISSION');
                        });
                    });
                    context('when revoking the permission for a everywhere', () => {
                        it('revokes the requested global permission', async () => {
                            await authorizer.revokePermissionGlobally(ACTION_1, user, { from: getSender() });
                            (0, chai_1.expect)(await authorizer.canPerform(ACTION_1, user, EVERYWHERE)).to.be.false;
                            (0, chai_1.expect)(await authorizer.canPerform(ACTION_1, user, WHERE_2)).to.be.false;
                        });
                        it('can still perform the requested action in the specific contract', async () => {
                            await authorizer.revokePermissionGlobally(ACTION_1, user, { from: getSender() });
                            (0, chai_1.expect)(await authorizer.canPerform(ACTION_1, user, WHERE_1)).to.be.true;
                        });
                        it('emits an event', async () => {
                            const receipt = await (await authorizer.revokePermissionGlobally(ACTION_1, user, { from: getSender() })).wait();
                            expectEvent.inReceipt(receipt, 'PermissionRevoked', {
                                actionId: ACTION_1,
                                account: user.address,
                                where: TimelockAuthorizerHelper_1.default.EVERYWHERE,
                            });
                        });
                    });
                });
            }
            context('when the sender is root', () => {
                itRevokesPermissionCorrectly(() => root);
            });
            context('when the sender is revoker everywhere', () => {
                (0, sharedBeforeEach_1.sharedBeforeEach)('makes a revoker', async () => {
                    await authorizer.addRevoker(revoker, EVERYWHERE, { from: root });
                });
                itRevokesPermissionCorrectly(() => revoker);
            });
            context('when the sender is revoker for a specific contract', () => {
                (0, sharedBeforeEach_1.sharedBeforeEach)('makes a revoker', async () => {
                    await authorizer.addRevoker(revoker, WHERE_1, { from: root });
                });
                it('cannot revoke the permission in other contracts', async () => {
                    await (0, chai_1.expect)(authorizer.revokePermission(ACTION_1, user, WHERE_3, { from: revoker })).to.be.revertedWith('SENDER_IS_NOT_REVOKER');
                });
                it('cannot revoke the permission if it was not granted', async () => {
                    await (0, chai_1.expect)(authorizer.revokePermission(ACTION_1, user, WHERE_1, { from: root })).to.be.revertedWith('PERMISSION_NOT_GRANTED');
                });
                context('when the user has the permission for a contract', () => {
                    (0, sharedBeforeEach_1.sharedBeforeEach)('grants the permission', async () => {
                        await authorizer.grantPermission(ACTION_1, user, WHERE_1, { from: root });
                    });
                    context('when revoking the permission for a contract', () => {
                        it('revokes the requested permission for the requested contract', async () => {
                            await authorizer.revokePermission(ACTION_1, user, WHERE_1, { from: revoker });
                            (0, chai_1.expect)(await authorizer.canPerform(ACTION_1, user, WHERE_1)).to.be.false;
                            (0, chai_1.expect)(await authorizer.canPerform(ACTION_2, user, WHERE_1)).to.be.false;
                            (0, chai_1.expect)(await authorizer.canPerform(ACTION_1, user, WHERE_2)).to.be.false;
                            (0, chai_1.expect)(await authorizer.canPerform(ACTION_2, user, WHERE_2)).to.be.false;
                        });
                        it('still cannot perform the requested action everywhere', async () => {
                            await authorizer.revokePermission(ACTION_1, user, WHERE_1, { from: revoker });
                            (0, chai_1.expect)(await authorizer.canPerform(ACTION_1, user, EVERYWHERE)).to.be.false;
                            (0, chai_1.expect)(await authorizer.canPerform(ACTION_2, user, EVERYWHERE)).to.be.false;
                        });
                        it('emits an event', async () => {
                            const receipt = await (await authorizer.revokePermission(ACTION_1, user, WHERE_1, { from: revoker })).wait();
                            expectEvent.inReceipt(receipt, 'PermissionRevoked', {
                                actionId: ACTION_1,
                                account: user.address,
                                where: WHERE_1,
                            });
                        });
                    });
                });
                context('when the user has the permission everywhere', () => {
                    (0, sharedBeforeEach_1.sharedBeforeEach)('grants the permissions', async () => {
                        await authorizer.grantPermissionGlobally(ACTION_1, user, { from: root });
                    });
                    context('when revoking the permission for a contract', () => {
                        it('cannot revoke the permission', async () => {
                            await (0, chai_1.expect)(authorizer.revokePermission(ACTION_1, user, WHERE_1, { from: revoker })).to.be.revertedWith('ACCOUNT_HAS_GLOBAL_PERMISSION');
                        });
                    });
                });
            });
        });
    });
    describe('scheduleRevokePermission', () => {
        const delay = time_1.DAY;
        (0, sharedBeforeEach_1.sharedBeforeEach)('set delay', async () => {
            const iVault = await TypesConverter_1.default.toIVault(vault);
            const setAuthorizerAction = await (0, actions_1.actionId)(iVault, 'setAuthorizer');
            await authorizer.scheduleAndExecuteDelayChange(setAuthorizerAction, delay * 2, { from: root });
            await authorizer.scheduleAndExecuteRevokeDelayChange(ACTION_1, delay, { from: root });
        });
        it('reverts if action has no revoke delay', async () => {
            await (0, chai_1.expect)(authorizer.scheduleRevokePermission(ACTION_2, user, WHERE_1, [], { from: root })).to.be.revertedWith('ACTION_HAS_NO_REVOKE_DELAY');
        });
        it('reverts if sender is not revoker', async () => {
            await (0, chai_1.expect)(authorizer.scheduleRevokePermission(ACTION_1, user, WHERE_1, [], { from: other })).to.be.revertedWith('SENDER_IS_NOT_REVOKER');
        });
        function itScheduleRevokePermissionCorrectly(getSender) {
            it('schedules a revoke permission', async () => {
                const id = await authorizer.scheduleRevokePermission(ACTION_1, user, WHERE_1, [], { from: getSender() });
                const { executed, data, where, executableAt } = await authorizer.getScheduledExecution(id);
                (0, chai_1.expect)(executed).to.be.false;
                (0, chai_1.expect)(data).to.be.equal(authorizer.instance.interface.encodeFunctionData('revokePermission', [ACTION_1, user.address, WHERE_1]));
                (0, chai_1.expect)(where).to.be.equal(await authorizer.address());
                (0, chai_1.expect)(executableAt).to.equal((await (0, time_1.currentTimestamp)()) + (0, numbers_1.bn)(delay));
            });
            it('increases the scheduled execution count', async () => {
                const countBefore = await authorizer.instance.getScheduledExecutionsCount();
                await authorizer.scheduleRevokePermission(ACTION_1, user, WHERE_1, [], { from: getSender() });
                const countAfter = await authorizer.instance.getScheduledExecutionsCount();
                (0, chai_1.expect)(countAfter).to.equal(countBefore + 1n);
            });
            it('stores scheduler information', async () => {
                const id = await authorizer.scheduleRevokePermission(ACTION_1, user, WHERE_1, [], { from: getSender() });
                const scheduledExecution = await authorizer.getScheduledExecution(id);
                (0, chai_1.expect)(scheduledExecution.scheduledBy).to.equal(getSender().address);
                (0, chai_1.expect)(scheduledExecution.scheduledAt).to.equal(await (0, time_1.currentTimestamp)());
            });
            it('stores empty executor and canceler information', async () => {
                const id = await authorizer.scheduleRevokePermission(ACTION_1, user, WHERE_1, [], { from: getSender() });
                const scheduledExecution = await authorizer.getScheduledExecution(id);
                (0, chai_1.expect)(scheduledExecution.executedBy).to.equal(constants_1.ZERO_ADDRESS);
                (0, chai_1.expect)(scheduledExecution.executedAt).to.equal(0);
                (0, chai_1.expect)(scheduledExecution.canceledBy).to.equal(constants_1.ZERO_ADDRESS);
                (0, chai_1.expect)(scheduledExecution.canceledAt).to.equal(0);
            });
            it('execution can be unprotected', async () => {
                const id = await authorizer.scheduleRevokePermission(ACTION_1, user, WHERE_1, [], { from: getSender() });
                const execution = await authorizer.getScheduledExecution(id);
                (0, chai_1.expect)(execution.protected).to.be.false;
            });
            it('execution can be protected', async () => {
                const executors = (0, lodash_1.range)(4).map(constants_1.randomAddress);
                const id = await authorizer.scheduleRevokePermission(ACTION_1, user, WHERE_1, executors, { from: getSender() });
                const execution = await authorizer.getScheduledExecution(id);
                (0, chai_1.expect)(execution.protected).to.be.true;
                await Promise.all(executors.map(async (executor) => (0, chai_1.expect)(await authorizer.isExecutor(id, executor)).to.be.true));
            });
            it('revoker can cancel the execution', async () => {
                const id = await authorizer.scheduleRevokePermission(ACTION_1, user, WHERE_1, [], { from: getSender() });
                (0, chai_1.expect)(await authorizer.isCanceler(id, getSender())).to.be.true;
                const receipt = await authorizer.cancel(id, { from: getSender() });
                expectEvent.inReceipt(await receipt.wait(), 'ExecutionCanceled', { scheduledExecutionId: id });
            });
            it('can be executed after the expected delay', async () => {
                // Grant the permission so we can later revoke it
                await authorizer.grantPermission(ACTION_1, user, WHERE_1, { from: root });
                const id = await authorizer.scheduleRevokePermission(ACTION_1, user, WHERE_1, [], { from: getSender() });
                await (0, time_1.advanceTime)(delay);
                const receipt = await authorizer.execute(id);
                expectEvent.inReceipt(await receipt.wait(), 'ExecutionExecuted', { scheduledExecutionId: id });
            });
            it('revokes the permission when executed', async () => {
                // grant the premission first
                await authorizer.grantPermission(ACTION_1, user, WHERE_1, { from: root });
                (0, chai_1.expect)(await authorizer.hasPermission(ACTION_1, user, WHERE_1)).to.be.equal(true);
                const id = await authorizer.scheduleRevokePermission(ACTION_1, user, WHERE_1, [], { from: getSender() });
                await (0, time_1.advanceTime)(delay);
                await authorizer.execute(id);
                (0, chai_1.expect)(await authorizer.hasPermission(ACTION_1, user, WHERE_1)).to.be.equal(false);
            });
            it('does not revoke any other permissions when executed', async () => {
                // Grant the permission so we can later revoke it
                await authorizer.grantPermission(ACTION_1, user, WHERE_1, { from: root });
                const id = await authorizer.scheduleRevokePermission(ACTION_1, user, WHERE_1, [], { from: getSender() });
                await (0, time_1.advanceTime)(delay);
                await authorizer.execute(id);
                (0, chai_1.expect)(await authorizer.hasPermission(ACTION_3, user, WHERE_1)).to.be.equal(false);
                (0, chai_1.expect)(await authorizer.hasPermission(ACTION_2, user, WHERE_2)).to.be.equal(false);
            });
            it('emits an event', async () => {
                const receipt = await authorizer.instance
                    .connect(getSender())
                    .scheduleRevokePermission(ACTION_1, user.address, WHERE_1, []);
                expectEvent.inReceipt(await receipt.wait(), 'RevokePermissionScheduled', {
                    actionId: ACTION_1,
                    account: user.address,
                    where: WHERE_1,
                });
            });
        }
        context('when the sender is root', () => {
            itScheduleRevokePermissionCorrectly(() => root);
        });
        context('when the sender is revoker everywhere', () => {
            (0, sharedBeforeEach_1.sharedBeforeEach)('makes a revoker', async () => {
                await authorizer.addRevoker(revoker, EVERYWHERE, { from: root });
            });
            itScheduleRevokePermissionCorrectly(() => revoker);
        });
        context('when the sender is revoker for a specific contract', () => {
            (0, sharedBeforeEach_1.sharedBeforeEach)('makes a revoker', async () => {
                await authorizer.addRevoker(revoker, WHERE_1, { from: root });
            });
            itScheduleRevokePermissionCorrectly(() => revoker);
            it('cannot schedule revoke the permission in other contracts', async () => {
                await (0, chai_1.expect)(authorizer.scheduleRevokePermission(ACTION_1, user, WHERE_3, [], { from: revoker })).to.be.revertedWith('SENDER_IS_NOT_REVOKER');
            });
        });
    });
    describe('renouncePermission', () => {
        const delay = time_1.DAY;
        context('when the sender does not have the permission', () => {
            context('when renouncing the permission for a specific contract', () => {
                it('cannot renounce the permission if it was not granted', async () => {
                    await (0, chai_1.expect)(authorizer.renouncePermission(ACTION_1, WHERE_1, { from: user })).to.be.revertedWith('PERMISSION_NOT_GRANTED');
                });
                it('cannot perform the requested action everywhere', async () => {
                    (0, chai_1.expect)(await authorizer.canPerform(ACTION_1, user, EVERYWHERE)).to.be.false;
                });
                it('cannot perform the requested action in any specific contract', async () => {
                    (0, chai_1.expect)(await authorizer.canPerform(ACTION_1, user, NOT_WHERE)).to.be.false;
                    (0, chai_1.expect)(await authorizer.canPerform(ACTION_1, user, WHERE_2)).to.be.false;
                });
            });
            context('when renouncing the permission for everywhere', () => {
                it('cannot renounce the permission if it was not granted', async () => {
                    await (0, chai_1.expect)(authorizer.renouncePermissionGlobally(ACTION_1, { from: user })).to.be.revertedWith('PERMISSION_NOT_GRANTED');
                });
                it('cannot perform the requested action everywhere', async () => {
                    (0, chai_1.expect)(await authorizer.canPerform(ACTION_1, user, EVERYWHERE)).to.be.false;
                });
                it('cannot perform the requested action in any specific contract', async () => {
                    (0, chai_1.expect)(await authorizer.canPerform(ACTION_1, user, NOT_WHERE)).to.be.false;
                    (0, chai_1.expect)(await authorizer.canPerform(ACTION_1, user, WHERE_2)).to.be.false;
                });
            });
        });
        context('when the user has the permission for a specific contract', () => {
            (0, sharedBeforeEach_1.sharedBeforeEach)('grants the permission', async () => {
                await authorizer.grantPermission(ACTION_1, user, WHERE_1, { from: root });
            });
            context('when renouncing the permission for a specific contract', () => {
                it('revokes the requested permission for the requested contract', async () => {
                    await authorizer.renouncePermission(ACTION_1, WHERE_1, { from: user });
                    (0, chai_1.expect)(await authorizer.canPerform(ACTION_1, user, WHERE_1)).to.be.false;
                    (0, chai_1.expect)(await authorizer.canPerform(ACTION_2, user, WHERE_1)).to.be.false;
                    (0, chai_1.expect)(await authorizer.canPerform(ACTION_1, user, WHERE_2)).to.be.false;
                    (0, chai_1.expect)(await authorizer.canPerform(ACTION_2, user, WHERE_2)).to.be.false;
                });
                it('cannot perform the requested action everywhere', async () => {
                    await authorizer.renouncePermission(ACTION_1, WHERE_1, { from: user });
                    (0, chai_1.expect)(await authorizer.canPerform(ACTION_1, user, EVERYWHERE)).to.be.false;
                });
                it('can revoke even if the permission has a delay', async () => {
                    const iVault = await TypesConverter_1.default.toIVault(vault);
                    await authorizer.scheduleAndExecuteDelayChange(await (0, actions_1.actionId)(iVault, 'setAuthorizer'), delay, {
                        from: root,
                    });
                    const id = await authorizer.scheduleRevokeDelayChange(ACTION_1, delay, [], { from: root });
                    await (0, time_1.advanceTime)(MINIMUM_EXECUTION_DELAY);
                    await authorizer.execute(id);
                    (0, chai_1.expect)(authorizer.revokePermission(ACTION_1, user, WHERE_1, { from: user })).to.be.revertedWith('REVOKE_MUST_BE_SCHEDULED');
                    await authorizer.renouncePermission(ACTION_1, WHERE_1, { from: user });
                    (0, chai_1.expect)(await authorizer.canPerform(ACTION_1, user, WHERE_1)).to.be.false;
                    (0, chai_1.expect)(await authorizer.canPerform(ACTION_2, user, WHERE_1)).to.be.false;
                    (0, chai_1.expect)(await authorizer.canPerform(ACTION_1, user, WHERE_2)).to.be.false;
                    (0, chai_1.expect)(await authorizer.canPerform(ACTION_2, user, WHERE_2)).to.be.false;
                });
            });
            context('when renouncing the permission for everywhere', () => {
                it('cannot renounce the permission if it was not granted', async () => {
                    await (0, chai_1.expect)(authorizer.renouncePermissionGlobally(ACTION_1, { from: user })).to.be.revertedWith('PERMISSION_NOT_GRANTED');
                });
                it('can perform the requested action for the requested contract', async () => {
                    (0, chai_1.expect)(await authorizer.canPerform(ACTION_1, user, WHERE_1)).to.be.true;
                });
                it('cannot perform the requested action everywhere', async () => {
                    (0, chai_1.expect)(await authorizer.canPerform(ACTION_1, user, EVERYWHERE)).to.be.false;
                    (0, chai_1.expect)(await authorizer.canPerform(ACTION_2, user, EVERYWHERE)).to.be.false;
                });
            });
        });
        context('when the user has the permission for everywhere', () => {
            (0, sharedBeforeEach_1.sharedBeforeEach)('grants the permission', async () => {
                await authorizer.grantPermissionGlobally(ACTION_1, user, { from: root });
            });
            context('when renouncing the permission for a specific contract', () => {
                it('cannot renounce the permission if it was not granted', async () => {
                    await (0, chai_1.expect)(authorizer.renouncePermission(ACTION_1, WHERE_1, { from: user })).to.be.revertedWith('ACCOUNT_HAS_GLOBAL_PERMISSION');
                });
                it('can perform the requested actions for the requested contract', async () => {
                    (0, chai_1.expect)(await authorizer.canPerform(ACTION_1, user, WHERE_1)).to.be.true;
                    (0, chai_1.expect)(await authorizer.canPerform(ACTION_1, user, WHERE_2)).to.be.true;
                });
                it('can perform the requested action everywhere', async () => {
                    (0, chai_1.expect)(await authorizer.canPerform(ACTION_1, user, EVERYWHERE)).to.be.true;
                    (0, chai_1.expect)(await authorizer.canPerform(ACTION_1, user, WHERE_2)).to.be.true;
                });
            });
            context('when renouncing the permission for everywhere', () => {
                it('revokes the requested permissions everywhere', async () => {
                    await authorizer.renouncePermissionGlobally(ACTION_1, { from: user });
                    (0, chai_1.expect)(await authorizer.canPerform(ACTION_1, user, EVERYWHERE)).to.be.false;
                    (0, chai_1.expect)(await authorizer.canPerform(ACTION_1, user, WHERE_2)).to.be.false;
                });
                it('can revoke even if the permission has a delay', async () => {
                    const iVault = await TypesConverter_1.default.toIVault(vault);
                    await authorizer.scheduleAndExecuteDelayChange(await (0, actions_1.actionId)(iVault, 'setAuthorizer'), delay, {
                        from: root,
                    });
                    const id = await authorizer.scheduleRevokeDelayChange(ACTION_1, delay, [], { from: root });
                    await (0, time_1.advanceTime)(MINIMUM_EXECUTION_DELAY);
                    await authorizer.execute(id);
                    (0, chai_1.expect)(authorizer.revokePermissionGlobally(ACTION_1, user, { from: user })).to.be.revertedWith('REVOKE_MUST_BE_SCHEDULED');
                    await authorizer.renouncePermissionGlobally(ACTION_1, { from: user });
                    (0, chai_1.expect)(await authorizer.canPerform(ACTION_1, user, EVERYWHERE)).to.be.false;
                    (0, chai_1.expect)(await authorizer.canPerform(ACTION_1, user, WHERE_2)).to.be.false;
                });
                it('still cannot perform the requested action in any specific contract', async () => {
                    await authorizer.renouncePermissionGlobally(ACTION_1, { from: user });
                    (0, chai_1.expect)(await authorizer.canPerform(ACTION_1, user, NOT_WHERE)).to.be.false;
                    (0, chai_1.expect)(await authorizer.canPerform(ACTION_1, user, WHERE_2)).to.be.false;
                });
            });
        });
        context('when the user has the permission for a specific contract and everywhere', () => {
            (0, sharedBeforeEach_1.sharedBeforeEach)('grants the permission', async () => {
                await authorizer.grantPermission(ACTION_1, user, WHERE_1, { from: root });
                await authorizer.grantPermissionGlobally(ACTION_1, user, { from: root });
            });
            context('when renouncing the permission for a specific contract', () => {
                it('cannot renounce the permission', async () => {
                    await (0, chai_1.expect)(authorizer.renouncePermission(ACTION_1, WHERE_1, { from: user })).to.be.revertedWith('ACCOUNT_HAS_GLOBAL_PERMISSION');
                });
                it('can perform the requested actions for the requested contract', async () => {
                    (0, chai_1.expect)(await authorizer.canPerform(ACTION_1, user, WHERE_1)).to.be.true;
                    (0, chai_1.expect)(await authorizer.canPerform(ACTION_1, user, WHERE_2)).to.be.true;
                });
                it('can perform the requested action everywhere', async () => {
                    (0, chai_1.expect)(await authorizer.canPerform(ACTION_1, user, EVERYWHERE)).to.be.true;
                    (0, chai_1.expect)(await authorizer.canPerform(ACTION_1, user, WHERE_2)).to.be.true;
                });
            });
            context('when renouncing the permission for everywhere', () => {
                it('revokes the requested permissions everywhere', async () => {
                    await authorizer.renouncePermissionGlobally(ACTION_1, { from: user });
                    (0, chai_1.expect)(await authorizer.canPerform(ACTION_1, user, EVERYWHERE)).to.be.false;
                    (0, chai_1.expect)(await authorizer.canPerform(ACTION_1, user, WHERE_2)).to.be.false;
                });
                it('can still perform the requested action in the specific contract', async () => {
                    await authorizer.renouncePermissionGlobally(ACTION_1, { from: user });
                    (0, chai_1.expect)(await authorizer.canPerform(ACTION_1, user, WHERE_1)).to.be.true;
                });
                it('can revoke even if the permission has a delay', async () => {
                    const iVault = await TypesConverter_1.default.toIVault(vault);
                    await authorizer.scheduleAndExecuteDelayChange(await (0, actions_1.actionId)(iVault, 'setAuthorizer'), delay, {
                        from: root,
                    });
                    const id = await authorizer.scheduleRevokeDelayChange(ACTION_1, delay, [], { from: root });
                    await (0, time_1.advanceTime)(MINIMUM_EXECUTION_DELAY);
                    await authorizer.execute(id);
                    (0, chai_1.expect)(authorizer.revokePermissionGlobally(ACTION_1, user, { from: user })).to.be.revertedWith('REVOKE_MUST_BE_SCHEDULED');
                    await authorizer.renouncePermissionGlobally(ACTION_1, { from: user });
                    (0, chai_1.expect)(await authorizer.canPerform(ACTION_1, user, EVERYWHERE)).to.be.false;
                    (0, chai_1.expect)(await authorizer.canPerform(ACTION_1, user, WHERE_2)).to.be.false;
                });
            });
        });
    });
});
