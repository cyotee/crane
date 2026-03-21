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
const hardhat_1 = require("hardhat");
const chai_1 = require("chai");
const sharedBeforeEach_1 = require("@balancer-labs/v3-common/sharedBeforeEach");
const numbers_1 = require("@balancer-labs/v3-helpers/src/numbers");
const VaultDeployer = __importStar(require("@balancer-labs/v3-helpers/src/models/vault/VaultDeployer"));
const ERC20TokenList_1 = __importDefault(require("@balancer-labs/v3-helpers/src/models/tokens/ERC20TokenList"));
const TypesConverter_1 = __importDefault(require("@balancer-labs/v3-helpers/src/models/types/TypesConverter"));
const contract_1 = require("@balancer-labs/v3-helpers/src/contract");
const time_1 = require("@balancer-labs/v3-helpers/src/time");
const constants_1 = require("@balancer-labs/v3-helpers/src/constants");
const expectEvent = __importStar(require("@balancer-labs/v3-helpers/src/test/expectEvent"));
const relativeError_1 = require("@balancer-labs/v3-helpers/src/test/relativeError");
const actions_1 = require("@balancer-labs/v3-helpers/src/models/misc/actions");
describe('StablePoolAmplification', () => {
    const TOKEN_AMOUNT = (0, numbers_1.fp)(1000);
    const MIN_AMP = 1n;
    const MAX_AMP = 50000n;
    const AMP_PRECISION = 1000n;
    const INITIAL_AMPLIFICATION_PARAMETER = 200n;
    let vault;
    let admin;
    let alice;
    let other;
    let tokens;
    let pool;
    (0, sharedBeforeEach_1.sharedBeforeEach)('setup signers', async () => {
        [, admin, alice, other] = await hardhat_1.ethers.getSigners();
    });
    (0, sharedBeforeEach_1.sharedBeforeEach)('deploy vault', async () => {
        vault = await TypesConverter_1.default.toIVaultMock(await VaultDeployer.deployMock());
        tokens = await ERC20TokenList_1.default.create(4, { sorted: true });
        // mint and approve tokens
        await tokens.asyncEach(async (token) => {
            await token.mint(alice, TOKEN_AMOUNT);
            await token.connect(alice).approve(vault, constants_1.MAX_UINT256);
        });
    });
    async function grantPermission() {
        const startAmpUpdateAction = await (0, actions_1.actionId)(pool, 'startAmplificationParameterUpdate');
        const stopAmpUpdateAction = await (0, actions_1.actionId)(pool, 'stopAmplificationParameterUpdate');
        const authorizerAddress = await vault.getAuthorizer();
        const authorizer = await (0, contract_1.deployedAt)('v3-vault/BasicAuthorizerMock', authorizerAddress);
        await authorizer.grantRole(startAmpUpdateAction, admin.address);
        await authorizer.grantRole(stopAmpUpdateAction, admin.address);
    }
    async function deployPool(amp) {
        pool = await (0, contract_1.deploy)('StablePool', {
            args: [
                { name: 'Stable Pool', symbol: 'STABLE', amplificationParameter: amp, version: 'Stable Pool v1' },
                await vault.getAddress(),
            ],
        });
        await vault.manualRegisterPoolWithSwapFee(pool, await tokens.addresses, (0, numbers_1.fp)(0.01));
        await grantPermission();
    }
    describe('constructor', () => {
        context('when passing a valid initial amplification parameter value', () => {
            (0, sharedBeforeEach_1.sharedBeforeEach)('deploy pool', async () => {
                await deployPool(INITIAL_AMPLIFICATION_PARAMETER);
            });
            it('sets the expected amplification parameter', async () => {
                const { value, isUpdating, precision } = await pool.getAmplificationParameter();
                (0, chai_1.expect)(value).to.be.equal(INITIAL_AMPLIFICATION_PARAMETER * AMP_PRECISION);
                (0, chai_1.expect)(isUpdating).to.be.false;
                (0, chai_1.expect)(precision).to.be.equal(AMP_PRECISION);
            });
        });
        context('when passing an initial amplification parameter less than MIN_AMP', () => {
            it('reverts', async () => {
                await (0, chai_1.expect)(deployPool(MIN_AMP - 1n)).to.be.revertedWithCustomError(pool, 'AmplificationFactorTooLow');
            });
        });
        context('when passing an initial amplification parameter greater than MAX_AMP', () => {
            it('reverts', async () => {
                await (0, chai_1.expect)(deployPool(MAX_AMP + 1n)).to.be.revertedWithCustomError(pool, 'AmplificationFactorTooHigh');
            });
        });
    });
    describe('startAmplificationParameterUpdate', () => {
        let caller;
        function itStartsAnAmpUpdateCorrectly() {
            context('when requesting a reasonable change duration', () => {
                const duration = BigInt(time_1.DAY * 2);
                let endTime;
                (0, sharedBeforeEach_1.sharedBeforeEach)('set end time', async () => {
                    const startTime = (await (0, time_1.currentTimestamp)()) + 100n;
                    await (0, time_1.setNextBlockTimestamp)(startTime);
                    endTime = startTime + duration;
                });
                context('when requesting a valid amp', () => {
                    const itUpdatesAmpCorrectly = (newAmp) => {
                        const increasing = INITIAL_AMPLIFICATION_PARAMETER < newAmp;
                        context('when there is no ongoing update', () => {
                            it('starts changing the amp', async () => {
                                await pool.connect(caller).startAmplificationParameterUpdate(newAmp, endTime);
                                await (0, time_1.advanceTime)(duration / 3n);
                                const { value, isUpdating } = await pool.getAmplificationParameter();
                                (0, chai_1.expect)(isUpdating).to.be.true;
                                if (increasing) {
                                    const diff = (newAmp - INITIAL_AMPLIFICATION_PARAMETER) * AMP_PRECISION;
                                    (0, relativeError_1.expectEqualWithError)(value, INITIAL_AMPLIFICATION_PARAMETER * AMP_PRECISION + diff / 3n, 0.00001);
                                }
                                else {
                                    const diff = (INITIAL_AMPLIFICATION_PARAMETER - newAmp) * AMP_PRECISION;
                                    (0, relativeError_1.expectEqualWithError)(value, INITIAL_AMPLIFICATION_PARAMETER * AMP_PRECISION - diff / 3n, 0.00001);
                                }
                            });
                            it('stops updating after duration', async () => {
                                await pool.connect(caller).startAmplificationParameterUpdate(newAmp, endTime);
                                await (0, time_1.advanceTime)(duration + 1n);
                                const { value, isUpdating } = await pool.getAmplificationParameter();
                                (0, chai_1.expect)(value).to.be.equal(newAmp * AMP_PRECISION);
                                (0, chai_1.expect)(isUpdating).to.be.false;
                            });
                            it('emits an AmpUpdateStarted event', async () => {
                                const receipt = await pool.connect(caller).startAmplificationParameterUpdate(newAmp, endTime);
                                expectEvent.inReceipt(await receipt.wait(), 'AmpUpdateStarted', {
                                    startValue: INITIAL_AMPLIFICATION_PARAMETER * AMP_PRECISION,
                                    endValue: newAmp * AMP_PRECISION,
                                    endTime,
                                });
                            });
                            it('does not emit an AmpUpdateStopped event', async () => {
                                const receipt = await pool.connect(caller).startAmplificationParameterUpdate(newAmp, endTime);
                                expectEvent.notEmitted(await receipt.wait(), 'AmpUpdateStopped');
                            });
                        });
                        context('when there is an ongoing update', () => {
                            (0, sharedBeforeEach_1.sharedBeforeEach)('start change', async () => {
                                await pool.connect(caller).startAmplificationParameterUpdate(newAmp, endTime);
                                await (0, time_1.advanceTime)(duration / 3n);
                                const beforeStop = await pool.getAmplificationParameter();
                                (0, chai_1.expect)(beforeStop.isUpdating).to.be.true;
                            });
                            it('trying to start another update reverts', async () => {
                                await (0, chai_1.expect)(pool.connect(caller).startAmplificationParameterUpdate(newAmp, endTime)).to.be.revertedWithCustomError(pool, 'AmpUpdateAlreadyStarted');
                            });
                            context('after the ongoing update is stopped', () => {
                                let ampValueAfterStop;
                                (0, sharedBeforeEach_1.sharedBeforeEach)('stop change', async () => {
                                    await pool.connect(caller).stopAmplificationParameterUpdate();
                                    const ampState = await pool.getAmplificationParameter();
                                    ampValueAfterStop = ampState.value;
                                });
                                it('the new update can be started', async () => {
                                    const newEndTime = (await (0, time_1.currentTimestamp)()) + BigInt(time_1.DAY * 2);
                                    const startReceipt = await pool.connect(caller).startAmplificationParameterUpdate(newAmp, newEndTime);
                                    const now = await (0, time_1.currentTimestamp)();
                                    expectEvent.inReceipt(await startReceipt.wait(), 'AmpUpdateStarted', {
                                        endValue: newAmp * AMP_PRECISION,
                                        startTime: now,
                                        endTime: newEndTime,
                                    });
                                    await (0, time_1.advanceTime)(duration / 3n);
                                    const afterStart = await pool.getAmplificationParameter();
                                    (0, chai_1.expect)(afterStart.isUpdating).to.be.true;
                                    (0, chai_1.expect)(afterStart.value).to.be[increasing ? 'gt' : 'lt'](ampValueAfterStop);
                                });
                            });
                        });
                    };
                    context('when increasing the amp', () => {
                        context('when increasing the amp by 2x', () => {
                            const newAmp = INITIAL_AMPLIFICATION_PARAMETER * 2n;
                            itUpdatesAmpCorrectly(newAmp);
                        });
                    });
                    context('when decreasing the amp', () => {
                        context('when decreasing the amp by 2x', () => {
                            const newAmp = INITIAL_AMPLIFICATION_PARAMETER / 2n;
                            itUpdatesAmpCorrectly(newAmp);
                        });
                    });
                });
                context('when requesting an invalid amp', () => {
                    it('reverts when requesting below the min', async () => {
                        const lowAmp = (0, numbers_1.bn)(0);
                        await (0, chai_1.expect)(pool.connect(caller).startAmplificationParameterUpdate(lowAmp, endTime)).to.be.revertedWithCustomError(pool, 'AmplificationFactorTooLow');
                    });
                    it('reverts when requesting above the max', async () => {
                        const highAmp = (0, numbers_1.bn)(MAX_AMP + 1n);
                        await (0, chai_1.expect)(pool.connect(caller).startAmplificationParameterUpdate(highAmp, endTime)).to.be.revertedWithCustomError(pool, 'AmplificationFactorTooHigh');
                    });
                    describe('rate limits', () => {
                        let startTime;
                        beforeEach('set start time', async () => {
                            startTime = (await (0, time_1.currentTimestamp)()) + 100n;
                            await (0, time_1.setNextBlockTimestamp)(startTime);
                        });
                        it('reverts when increasing the amp by more than 2x in a single day', async () => {
                            const newAmp = INITIAL_AMPLIFICATION_PARAMETER * 2n + 1n;
                            const endTime = startTime + BigInt(time_1.DAY);
                            await (0, chai_1.expect)(pool.connect(caller).startAmplificationParameterUpdate(newAmp, endTime)).to.be.revertedWithCustomError(pool, 'AmpUpdateRateTooFast');
                        });
                        it('reverts when increasing the amp by more than 2x daily over multiple days', async () => {
                            const newAmp = INITIAL_AMPLIFICATION_PARAMETER * 5n + 1n;
                            const endTime = startTime + BigInt(time_1.DAY * 2);
                            await (0, chai_1.expect)(pool.connect(caller).startAmplificationParameterUpdate(newAmp, endTime)).to.be.revertedWithCustomError(pool, 'AmpUpdateRateTooFast');
                        });
                        it('reverts when decreasing the amp by more than 2x in a single day', async () => {
                            const newAmp = INITIAL_AMPLIFICATION_PARAMETER / 2n - 1n;
                            const endTime = startTime + BigInt(time_1.DAY);
                            await (0, chai_1.expect)(pool.connect(caller).startAmplificationParameterUpdate(newAmp, endTime)).to.be.revertedWithCustomError(pool, 'AmpUpdateRateTooFast');
                        });
                        it('reverts when decreasing the amp by more than 2x daily over multiple days', async () => {
                            const newAmp = INITIAL_AMPLIFICATION_PARAMETER / 5n + 1n;
                            const endTime = startTime + BigInt(time_1.DAY * 2);
                            await (0, chai_1.expect)(pool.connect(caller).startAmplificationParameterUpdate(newAmp, endTime)).to.be.revertedWithCustomError(pool, 'AmpUpdateRateTooFast');
                        });
                    });
                });
            });
            context('when requesting a short duration change', () => {
                let endTime;
                it('reverts', async () => {
                    endTime = (await (0, time_1.currentTimestamp)()) + BigInt(time_1.DAY - 1);
                    await (0, chai_1.expect)(pool.connect(caller).startAmplificationParameterUpdate(INITIAL_AMPLIFICATION_PARAMETER, endTime)).to.be.revertedWithCustomError(pool, 'AmpUpdateDurationTooShort');
                });
            });
        }
        function itReverts() {
            it('reverts', async () => {
                await (0, chai_1.expect)(pool.connect(other).startAmplificationParameterUpdate(INITIAL_AMPLIFICATION_PARAMETER, time_1.DAY)).to.be.revertedWithCustomError(vault, 'SenderNotAllowed');
            });
        }
        context('with permission', () => {
            (0, sharedBeforeEach_1.sharedBeforeEach)('deploy pool', async () => {
                await deployPool(INITIAL_AMPLIFICATION_PARAMETER);
                caller = admin;
            });
            context('when the sender is allowed', () => {
                itStartsAnAmpUpdateCorrectly();
            });
            context('when the sender is not allowed', () => {
                itReverts();
            });
        });
    });
    describe('stopAmplificationParameterUpdate', () => {
        let caller;
        function itStopsAnAmpUpdateCorrectly() {
            context('when there is an ongoing update', () => {
                (0, sharedBeforeEach_1.sharedBeforeEach)('start change', async () => {
                    const newAmp = INITIAL_AMPLIFICATION_PARAMETER * 2n;
                    const duration = BigInt(time_1.DAY * 2);
                    const startTime = (await (0, time_1.currentTimestamp)()) + 100n;
                    await (0, time_1.setNextBlockTimestamp)(startTime);
                    const endTime = startTime + duration;
                    await pool.connect(caller).startAmplificationParameterUpdate(newAmp, endTime);
                    await (0, time_1.advanceTime)(duration / 3n);
                    const beforeStop = await pool.getAmplificationParameter();
                    (0, chai_1.expect)(beforeStop.isUpdating).to.be.true;
                });
                it('stops the amp factor from updating', async () => {
                    const beforeStop = await pool.getAmplificationParameter();
                    await pool.connect(caller).stopAmplificationParameterUpdate();
                    const afterStop = await pool.getAmplificationParameter();
                    (0, relativeError_1.expectEqualWithError)(afterStop.value, beforeStop.value, 0.001);
                    (0, chai_1.expect)(afterStop.isUpdating).to.be.false;
                    await (0, time_1.advanceTime)(30 * time_1.DAY);
                    const muchLaterAfterStop = await pool.getAmplificationParameter();
                    (0, chai_1.expect)(muchLaterAfterStop.value).to.be.equal(afterStop.value);
                    (0, chai_1.expect)(muchLaterAfterStop.isUpdating).to.be.false;
                });
                it('emits an AmpUpdateStopped event', async () => {
                    const receipt = await pool.connect(caller).stopAmplificationParameterUpdate();
                    expectEvent.inReceipt(await receipt.wait(), 'AmpUpdateStopped');
                });
                it('does not emit an AmpUpdateStarted event', async () => {
                    const receipt = await pool.connect(caller).stopAmplificationParameterUpdate();
                    expectEvent.notEmitted(await receipt.wait(), 'AmpUpdateStarted');
                });
            });
            context('when there is no ongoing update', () => {
                it('reverts', async () => {
                    await (0, chai_1.expect)(pool.connect(caller).stopAmplificationParameterUpdate()).to.be.revertedWithCustomError(pool, 'AmpUpdateNotStarted');
                });
            });
        }
        function itReverts() {
            it('reverts', async () => {
                await (0, chai_1.expect)(pool.connect(other).stopAmplificationParameterUpdate()).to.be.revertedWithCustomError(vault, 'SenderNotAllowed');
            });
        }
        context('with permission', () => {
            (0, sharedBeforeEach_1.sharedBeforeEach)('deploy pool', async () => {
                await deployPool(INITIAL_AMPLIFICATION_PARAMETER);
                caller = admin;
            });
            context('when the sender is allowed', () => {
                itStopsAnAmpUpdateCorrectly();
            });
            context('when the sender is not allowed', () => {
                itReverts();
            });
        });
    });
});
