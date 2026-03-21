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
const contract_1 = require("@balancer-labs/v3-helpers/src/contract");
const time_1 = require("@balancer-labs/v3-helpers/src/time");
const sharedBeforeEach_1 = require("@balancer-labs/v3-common/sharedBeforeEach");
const constants_1 = require("@balancer-labs/v3-helpers/src/constants");
const numbers_1 = require("@balancer-labs/v3-helpers/src/numbers");
const poolSetup_1 = require("./poolSetup");
const actions_1 = require("@balancer-labs/v3-helpers/src/models/misc/actions");
const ERC20TokenList_1 = __importDefault(require("@balancer-labs/v3-helpers/src/models/tokens/ERC20TokenList"));
const VaultDeployer = __importStar(require("@balancer-labs/v3-helpers/src/models/vault/VaultDeployer"));
const expectEvent = __importStar(require("@balancer-labs/v3-helpers/src/test/expectEvent"));
const TypesConverter_1 = __importDefault(require("@balancer-labs/v3-helpers/src/models/types/TypesConverter"));
const types_1 = require("@balancer-labs/v3-helpers/src/models/types/types");
const sortingHelper_1 = require("@balancer-labs/v3-helpers/src/models/tokens/sortingHelper");
describe('Vault', function () {
    const PAUSE_WINDOW_DURATION = time_1.MONTH * 3;
    const BUFFER_PERIOD_DURATION = time_1.MONTH;
    const POOL_SWAP_FEE = (0, numbers_1.fp)(0.01);
    const MAX_TOKENS = 8;
    let vault;
    let vaultExtension;
    let factory;
    let poolA;
    let poolB;
    let tokenA;
    let tokenB;
    let tokenC;
    let alice;
    let tokenAAddress;
    let tokenBAddress;
    let poolBAddress;
    let poolATokens;
    let poolBTokens;
    let invalidTokens;
    let duplicateTokens;
    let unsortedTokens;
    before('setup signers', async () => {
        [, alice] = await hardhat_1.ethers.getSigners();
    });
    (0, sharedBeforeEach_1.sharedBeforeEach)('deploy vault, tokens, and pools', async function () {
        const { vault: vaultMock, tokens, pools } = await (0, poolSetup_1.setupEnvironment)(PAUSE_WINDOW_DURATION);
        vault = vaultMock;
        vaultExtension = (await (0, contract_1.deployedAt)('VaultExtensionMock', await vault.getVaultExtension()));
        factory = await (0, contract_1.deploy)('PoolFactoryMock', { args: [vault, 12 * time_1.MONTH] });
        tokenA = tokens[0];
        tokenB = tokens[1];
        tokenC = tokens[2];
        poolA = pools[0]; // This pool is registered
        poolB = pools[1]; // This pool is unregistered
        tokenAAddress = await tokenA.getAddress();
        tokenBAddress = await tokenB.getAddress();
        poolBAddress = await poolB.getAddress();
        const tokenCAddress = await tokenC.getAddress();
        poolATokens = (0, sortingHelper_1.sortAddresses)([tokenAAddress, tokenBAddress, tokenCAddress]);
        poolBTokens = (0, sortingHelper_1.sortAddresses)([tokenAAddress, tokenCAddress]);
        invalidTokens = (0, sortingHelper_1.sortAddresses)([tokenAAddress, constants_1.ZERO_ADDRESS, tokenCAddress]);
        duplicateTokens = (0, sortingHelper_1.sortAddresses)([tokenAAddress, tokenBAddress, tokenAAddress]);
        // Copy and reverse A tokens.
        unsortedTokens = Array.from(poolATokens);
        unsortedTokens.reverse();
        (0, chai_1.expect)(await poolA.name()).to.equal('Pool A');
        (0, chai_1.expect)(await poolA.symbol()).to.equal('POOL-A');
        (0, chai_1.expect)(await poolA.decimals()).to.equal(18);
        (0, chai_1.expect)(await poolB.name()).to.equal('Pool B');
        (0, chai_1.expect)(await poolB.symbol()).to.equal('POOL-B');
        (0, chai_1.expect)(await poolB.decimals()).to.equal(18);
    });
    describe('registration', () => {
        it('cannot register a pool with unsorted tokens', async () => {
            await (0, chai_1.expect)(vault.manualRegisterPoolPassThruTokens(poolB, unsortedTokens)).to.be.revertedWithCustomError(vaultExtension, 'TokensNotSorted');
        });
        it('can register a pool', async () => {
            (0, chai_1.expect)(await vault.isPoolRegistered(poolA)).to.be.true;
            (0, chai_1.expect)(await vault.isPoolRegistered(poolB)).to.be.false;
            const [tokens, , balances] = await vault.getPoolTokenInfo(poolA);
            (0, chai_1.expect)(tokens).to.deep.equal(poolATokens);
            (0, chai_1.expect)(balances).to.deep.equal(Array(tokens.length).fill(0));
            await (0, chai_1.expect)(vault.getPoolTokens(poolB))
                .to.be.revertedWithCustomError(vault, 'PoolNotRegistered')
                .withArgs(poolBAddress);
        });
        it('pools are initially not in recovery mode', async () => {
            (0, chai_1.expect)(await vault.isPoolInRecoveryMode(poolA)).to.be.false;
        });
        it('pools are initially unpaused', async () => {
            (0, chai_1.expect)(await vault.isPoolPaused(poolA)).to.equal(false);
        });
        it('registering a pool emits an event', async () => {
            const tokenConfig = Array.from({ length: poolBTokens.length }, (_, i) => [
                poolBTokens[i],
                types_1.TokenType.STANDARD.toString(),
                constants_1.ZERO_ADDRESS,
                false,
            ]);
            const currentTime = await (0, time_1.currentTimestamp)();
            const pauseWindowEndTime = Number(currentTime) + PAUSE_WINDOW_DURATION;
            const expectedArgs = {
                pool: poolBAddress,
                factory: await vault.getPoolFactoryMock(),
                tokenConfig,
                swapFeePercentage: 0,
                pauseWindowEndTime: pauseWindowEndTime.toString(),
                roleAccounts: [constants_1.ANY_ADDRESS, constants_1.ZERO_ADDRESS, constants_1.ANY_ADDRESS],
                hooksConfig: [false, false, false, false, false, false, false, false, false, false, constants_1.ZERO_ADDRESS],
                liquidityManagement: [false, true, true, false],
            };
            const roleAccounts = {
                pauseManager: constants_1.ANY_ADDRESS,
                swapFeeManager: constants_1.ZERO_ADDRESS,
                poolCreator: constants_1.ANY_ADDRESS,
            };
            // Use expectEvent here to prevent errors with structs of arrays with hardhat matchers.
            const tx = await vault.manualRegisterPoolAtTimestamp(poolB, poolBTokens, pauseWindowEndTime, roleAccounts);
            const receipt = await tx.wait();
            expectEvent.inReceipt(receipt, 'PoolRegistered', expectedArgs);
        });
        it('registering a pool with a swap fee emits an event', async () => {
            await (0, chai_1.expect)(vault.manualRegisterPoolWithSwapFee(poolB, poolBTokens, POOL_SWAP_FEE))
                .to.emit(vault, 'SwapFeePercentageChanged')
                .withArgs(poolBAddress, POOL_SWAP_FEE);
        });
        it('cannot register a pool twice', async () => {
            await vault.manualRegisterPool(poolB, poolBTokens);
            await (0, chai_1.expect)(vault.manualRegisterPool(poolB, poolBTokens))
                .to.be.revertedWithCustomError(vaultExtension, 'PoolAlreadyRegistered')
                .withArgs(await poolB.getAddress());
        });
        it('cannot register a pool with an invalid token (zero address)', async () => {
            await (0, chai_1.expect)(vault.manualRegisterPool(poolB, invalidTokens)).to.be.revertedWithCustomError(vaultExtension, 'InvalidToken');
        });
        it('cannot register a pool with an invalid token (pool address)', async () => {
            const poolBTokensWithItself = Array.from(poolBTokens);
            poolBTokensWithItself.push(poolBAddress);
            const finalTokens = (0, sortingHelper_1.sortAddresses)(poolBTokensWithItself);
            await (0, chai_1.expect)(vault.manualRegisterPool(poolB, finalTokens)).to.be.revertedWithCustomError(vaultExtension, 'InvalidToken');
        });
        it('cannot register a pool with duplicate tokens', async () => {
            await (0, chai_1.expect)(vault.manualRegisterPool(poolB, duplicateTokens))
                .to.be.revertedWithCustomError(vaultExtension, 'TokenAlreadyRegistered')
                .withArgs(tokenAAddress);
        });
        it('cannot register a pool when paused', async () => {
            await vault.manualPauseVault();
            await (0, chai_1.expect)(vault.manualRegisterPool(poolB, poolBTokens)).to.be.revertedWithCustomError(vault, 'VaultPaused');
        });
        it('cannot get pool tokens for an invalid pool', async () => {
            await (0, chai_1.expect)(vault.getPoolTokens(constants_1.ANY_ADDRESS))
                .to.be.revertedWithCustomError(vault, 'PoolNotRegistered')
                .withArgs(constants_1.ANY_ADDRESS);
        });
        it('cannot register a pool with too few tokens', async () => {
            await (0, chai_1.expect)(vault.manualRegisterPool(poolB, [poolATokens[0]])).to.be.revertedWithCustomError(vaultExtension, 'MinTokens');
        });
        it('cannot register a pool with too many tokens', async () => {
            const tokens = await ERC20TokenList_1.default.create(MAX_TOKENS + 1, { sorted: true });
            await (0, chai_1.expect)(vault.manualRegisterPool(poolB, await tokens.addresses)).to.be.revertedWithCustomError(vaultExtension, 'MaxTokens');
        });
    });
    describe('initialization', () => {
        let timedVault;
        (0, sharedBeforeEach_1.sharedBeforeEach)('redeploy Vault', async () => {
            const timedVaultMock = await VaultDeployer.deployMock({
                pauseWindowDuration: PAUSE_WINDOW_DURATION,
                bufferPeriodDuration: BUFFER_PERIOD_DURATION,
            });
            timedVault = await TypesConverter_1.default.toIVaultMock(timedVaultMock);
        });
        it('is temporarily pausable', async () => {
            (0, chai_1.expect)(await timedVault.isVaultPaused()).to.equal(false);
            const [paused, pauseWindowEndTime, bufferPeriodEndTime] = await timedVault.getVaultPausedState();
            (0, chai_1.expect)(paused).to.be.false;
            // We subtract 3 because the timestamp is set when the extension is deployed.
            // Each contract deployment pushes the timestamp by 1, and the main Vault is deployed right after the extension,
            // vault admin, and protocol fee controller.
            (0, chai_1.expect)(pauseWindowEndTime).to.equal(await (0, time_1.fromNow)(PAUSE_WINDOW_DURATION - 3));
            (0, chai_1.expect)(bufferPeriodEndTime).to.equal((await (0, time_1.fromNow)(PAUSE_WINDOW_DURATION - 3)) + (0, numbers_1.bn)(BUFFER_PERIOD_DURATION));
            await timedVault.manualPauseVault();
            (0, chai_1.expect)(await timedVault.isVaultPaused()).to.be.true;
            await timedVault.manualUnpauseVault();
            (0, chai_1.expect)(await timedVault.isVaultPaused()).to.be.false;
        });
        it('pausing the Vault emits an event', async () => {
            await (0, chai_1.expect)(await timedVault.manualPauseVault())
                .to.emit(timedVault, 'VaultPausedStateChanged')
                .withArgs(true);
            await (0, chai_1.expect)(await timedVault.manualUnpauseVault())
                .to.emit(timedVault, 'VaultPausedStateChanged')
                .withArgs(false);
        });
        describe('rate providers', () => {
            let poolC;
            let rateProviders;
            let expectedRates;
            let rateProvider;
            (0, sharedBeforeEach_1.sharedBeforeEach)('deploy pool', async () => {
                rateProviders = Array(poolATokens.length).fill(constants_1.ZERO_ADDRESS);
                rateProvider = await (0, contract_1.deploy)('v3-vault/RateProviderMock');
                rateProviders[0] = await rateProvider.getAddress();
                expectedRates = Array(poolATokens.length).fill(numbers_1.FP_ONE);
                poolC = await (0, contract_1.deploy)('v3-vault/PoolMock', {
                    args: [vault, 'Pool C', 'POOL_C'],
                });
                await factory.registerTestPool(poolC, (0, poolSetup_1.buildTokenConfig)(poolATokens, rateProviders));
            });
            it('has rate providers', async () => {
                const [, tokenInfo] = await vault.getPoolTokenInfo(poolC);
                const poolProviders = tokenInfo.map((config) => config.rateProvider);
                const { tokenRates } = await vault.getPoolTokenRates(poolC);
                (0, chai_1.expect)(poolProviders).to.deep.equal(rateProviders);
                (0, chai_1.expect)(tokenRates).to.deep.equal(expectedRates);
            });
            it('rate providers respond to changing rates', async () => {
                const newRate = (0, numbers_1.fp)(0.5);
                await rateProvider.mockRate(newRate);
                expectedRates[0] = newRate;
                const { tokenRates } = await vault.getPoolTokenRates(poolC);
                (0, chai_1.expect)(tokenRates).to.deep.equal(expectedRates);
            });
        });
        describe('pausing pools', () => {
            let pool;
            let poolAddress;
            (0, sharedBeforeEach_1.sharedBeforeEach)('deploy pool', async () => {
                pool = await (0, contract_1.deploy)('v3-vault/PoolMock', {
                    args: [vault, 'Pool X', 'POOL_X'],
                });
                poolAddress = await pool.getAddress();
                await factory.registerTestPool(poolAddress, (0, poolSetup_1.buildTokenConfig)(poolATokens));
            });
            it('Pools are temporarily pausable', async () => {
                (0, chai_1.expect)(await vault.isPoolPaused(poolAddress)).to.equal(false);
                const paused = await vault.isPoolPaused(poolAddress);
                (0, chai_1.expect)(paused).to.be.false;
                await vault.manualPausePool(poolAddress);
                (0, chai_1.expect)(await vault.isPoolPaused(poolAddress)).to.be.true;
                await vault.manualUnpausePool(poolAddress);
                (0, chai_1.expect)(await vault.isPoolPaused(poolAddress)).to.be.false;
            });
            it('pausing a pool emits an event', async () => {
                await (0, chai_1.expect)(await vault.manualPausePool(poolAddress))
                    .to.emit(vault, 'PoolPausedStateChanged')
                    .withArgs(poolAddress, true);
                await (0, chai_1.expect)(await vault.manualUnpausePool(poolAddress))
                    .to.emit(vault, 'PoolPausedStateChanged')
                    .withArgs(poolAddress, false);
            });
        });
    });
    describe('authorizer', () => {
        let oldAuthorizer;
        let newAuthorizer;
        let oldAuthorizerAddress;
        (0, sharedBeforeEach_1.sharedBeforeEach)('get old and deploy new authorizer', async () => {
            oldAuthorizerAddress = await vault.getAuthorizer();
            oldAuthorizer = await (0, contract_1.deployedAt)('BasicAuthorizerMock', oldAuthorizerAddress);
            newAuthorizer = await (0, contract_1.deploy)('NullAuthorizer');
        });
        context('without permission', () => {
            it('cannot change authorizer', async () => {
                await (0, chai_1.expect)(vault.setAuthorizer(newAuthorizer.getAddress())).to.be.revertedWithCustomError(vault, 'SenderNotAllowed');
            });
        });
        context('with permission', () => {
            let newAuthorizerAddress;
            (0, sharedBeforeEach_1.sharedBeforeEach)('grant permission', async () => {
                const setAuthorizerAction = await (0, actions_1.actionId)(vault, 'setAuthorizer');
                await oldAuthorizer.grantRole(setAuthorizerAction, alice.address);
            });
            it('can change authorizer', async () => {
                newAuthorizerAddress = await newAuthorizer.getAddress();
                await (0, chai_1.expect)(await vault.connect(alice).setAuthorizer(newAuthorizerAddress))
                    .to.emit(vault, 'AuthorizerChanged')
                    .withArgs(newAuthorizerAddress);
                (0, chai_1.expect)(await vault.getAuthorizer()).to.equal(newAuthorizerAddress);
            });
            it('the null authorizer allows everything', async () => {
                await vault.connect(alice).setAuthorizer(newAuthorizerAddress);
                await vault.setAuthorizer(oldAuthorizerAddress);
                (0, chai_1.expect)(await vault.getAuthorizer()).to.equal(oldAuthorizerAddress);
            });
        });
    });
    describe('pool tokens', () => {
        const DECIMAL_DIFF_BITS = 5;
        function decodeDecimalDiffs(diff, numTokens) {
            const result = [];
            for (let i = 0; i < numTokens; i++) {
                // Compute the 5-bit mask for each token.
                const mask = (2 ** DECIMAL_DIFF_BITS - 1) << (i * DECIMAL_DIFF_BITS);
                // Logical AND with the input, and shift back down to get the final result.
                result[i] = (diff & mask) >> (i * DECIMAL_DIFF_BITS);
            }
            return result;
        }
        it('returns the min and max pool counts', async () => {
            const minTokens = await vault.getMinimumPoolTokens();
            const maxTokens = await vault.getMaximumPoolTokens();
            (0, chai_1.expect)(minTokens).to.eq(2);
            (0, chai_1.expect)(maxTokens).to.eq(MAX_TOKENS);
        });
        it('stores the decimal differences', async () => {
            const expectedDecimals = await Promise.all(poolATokens.map(async (token) => (await (0, contract_1.deployedAt)('v3-solidity-utils/ERC20TestToken', token)).decimals()));
            const expectedDecimalDiffs = expectedDecimals.map((d) => (0, numbers_1.bn)(18) - d);
            const poolConfig = await vault.getPoolConfig(poolA);
            const actualDecimalDiffs = decodeDecimalDiffs(Number(poolConfig.tokenDecimalDiffs), poolATokens.length);
            (0, chai_1.expect)(actualDecimalDiffs).to.deep.equal(expectedDecimalDiffs);
        });
        it('computes the scaling factors', async () => {
            // Get them from the pool (mock), using ScalingHelpers.
            const poolScalingFactors = await poolA.getDecimalScalingFactors();
            // Get them from the Vault (using PoolConfig).
            const { decimalScalingFactors } = await vault.getPoolTokenRates(poolA);
            (0, chai_1.expect)(decimalScalingFactors).to.deep.equal(poolScalingFactors);
        });
    });
    describe('recovery mode', () => {
        (0, sharedBeforeEach_1.sharedBeforeEach)('register pool', async () => {
            await vault.manualRegisterPool(poolB, poolBTokens);
        });
        it('enable/disable functions are permissioned', async () => {
            await (0, chai_1.expect)(vault.enableRecoveryMode(poolB)).to.be.revertedWithCustomError(vault, 'SenderNotAllowed');
            await (0, chai_1.expect)(vault.disableRecoveryMode(poolB)).to.be.revertedWithCustomError(vault, 'SenderNotAllowed');
        });
        context('in recovery mode', () => {
            (0, sharedBeforeEach_1.sharedBeforeEach)('put pool in recovery mode', async () => {
                await vault.manualEnableRecoveryMode(poolB);
            });
            it('can place pool in recovery mode', async () => {
                (0, chai_1.expect)(await vault.isPoolInRecoveryMode(poolB)).to.be.true;
            });
            it('cannot put in recovery mode twice', async () => {
                await (0, chai_1.expect)(vault.manualEnableRecoveryMode(poolB)).to.be.revertedWithCustomError(vault, 'PoolInRecoveryMode');
            });
            it('can call recovery mode only function', async () => {
                await (0, chai_1.expect)(vault.recoveryModeExit(poolB)).to.not.be.reverted;
            });
            it('can disable recovery mode', async () => {
                await vault.manualDisableRecoveryMode(poolB);
                (0, chai_1.expect)(await vault.isPoolInRecoveryMode(poolB)).to.be.false;
            });
            it('disabling recovery mode emits an event', async () => {
                await (0, chai_1.expect)(vault.manualDisableRecoveryMode(poolB))
                    .to.emit(vault, 'PoolRecoveryModeStateChanged')
                    .withArgs(poolBAddress, false);
            });
        });
        context('not in recovery mode', () => {
            it('is initially not in recovery mode', async () => {
                (0, chai_1.expect)(await vault.isPoolInRecoveryMode(poolB)).to.be.false;
            });
            it('cannot disable when not in recovery mode', async () => {
                await (0, chai_1.expect)(vault.manualDisableRecoveryMode(poolB)).to.be.revertedWithCustomError(vault, 'PoolNotInRecoveryMode');
            });
            it('cannot call recovery mode only function when not in recovery mode', async () => {
                await (0, chai_1.expect)(vault.recoveryModeExit(poolB)).to.be.revertedWithCustomError(vault, 'PoolNotInRecoveryMode');
            });
            it('enabling recovery mode emits an event', async () => {
                await (0, chai_1.expect)(vault.manualEnableRecoveryMode(poolB))
                    .to.emit(vault, 'PoolRecoveryModeStateChanged')
                    .withArgs(poolBAddress, true);
            });
        });
    });
    describe('reentrancy guard state', () => {
        it('reentrancy guard should be false when not in Vault context', async () => {
            (0, chai_1.expect)(await vault.unguardedCheckNotEntered()).to.not.be.reverted;
        });
        it('reentrancy guard should be true when in Vault context', async () => {
            (0, chai_1.expect)(await vault.guardedCheckEntered()).to.not.be.reverted;
        });
    });
});
