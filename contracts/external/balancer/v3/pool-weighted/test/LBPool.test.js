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
const sharedBeforeEach_1 = require("@balancer-labs/v3-common/sharedBeforeEach");
const numbers_1 = require("@balancer-labs/v3-helpers/src/numbers");
const constants_1 = require("@balancer-labs/v3-helpers/src/constants");
const VaultDeployer = __importStar(require("@balancer-labs/v3-helpers/src/models/vault/VaultDeployer"));
const TypesConverter_1 = __importDefault(require("@balancer-labs/v3-helpers/src/models/types/TypesConverter"));
const actions_1 = require("@balancer-labs/v3-helpers/src/models/misc/actions");
const time_1 = require("@balancer-labs/v3-helpers/src/time");
const expectEvent = __importStar(require("@balancer-labs/v3-helpers/src/test/expectEvent"));
const sortingHelper_1 = require("@balancer-labs/v3-helpers/src/models/tokens/sortingHelper");
const Permit2Deployer_1 = require("@balancer-labs/v3-vault/test/Permit2Deployer");
const hardhat_network_helpers_1 = require("@nomicfoundation/hardhat-network-helpers");
describe('LBPool', function () {
    const POOL_SWAP_FEE = (0, numbers_1.fp)(0.01);
    const TOKEN_AMOUNT = (0, numbers_1.fp)(100);
    let permit2;
    let vault;
    let factory;
    // Most parameters are immutable so we'll need to deploy the pool several times during the test.
    // However, we will run liquidity tests on the global one to save unnecessary initialization steps every time.
    let globalPool;
    let globalPoolStartTime;
    let globalPoolEndTime;
    let router;
    let alice, bob, admin;
    let tokenA;
    let tokenB;
    let poolTokens;
    let tokenAIdx;
    let tokenBIdx;
    let tokenAAddress;
    let tokenBAddress;
    const FACTORY_VERSION = 'LBPool Factory v1';
    const POOL_VERSION = 'LBPool v1';
    const ROUTER_VERSION = 'Router v11';
    const WEIGHTS = [(0, numbers_1.fp)(0.5), (0, numbers_1.fp)(0.5)];
    const INITIAL_BALANCES = [TOKEN_AMOUNT, TOKEN_AMOUNT];
    const SWAP_AMOUNT = (0, numbers_1.fp)(20);
    const SWAP_FEE = (0, numbers_1.fp)(0.01);
    async function deployPool(projectTokenStartWeight, reserveTokenStartWeight, projectTokenEndWeight, reserveTokenEndWeight, startTime, endTime, blockProjectTokenSwapsIn) {
        const tx = await deployPoolTx(projectTokenStartWeight, reserveTokenStartWeight, projectTokenEndWeight, reserveTokenEndWeight, startTime, endTime, blockProjectTokenSwapsIn, (0, numbers_1.bn)(0) // virtual balance
        );
        const receipt = await tx.wait();
        const event = expectEvent.inReceipt(receipt, 'PoolCreated');
        return (await (0, contract_1.deployedAt)('LBPool', event.args.pool));
    }
    async function deployPoolTx(projectTokenStartWeight, reserveTokenStartWeight, projectTokenEndWeight, reserveTokenEndWeight, startTime, endTime, blockProjectTokenSwapsIn, reserveTokenVirtualBalance) {
        const tokens = (0, sortingHelper_1.sortAddresses)([tokenAAddress, tokenBAddress]);
        const lbpCommonParams = {
            name: 'LBPool',
            symbol: 'Test',
            owner: admin.address,
            projectToken: tokens[0],
            reserveToken: tokens[1],
            startTime,
            endTime,
            blockProjectTokenSwapsIn,
        };
        const lbpParams = {
            projectTokenStartWeight,
            reserveTokenStartWeight,
            projectTokenEndWeight,
            reserveTokenEndWeight,
            reserveTokenVirtualBalance,
        };
        return factory.create(lbpCommonParams, lbpParams, SWAP_FEE, constants_1.ONES_BYTES32, constants_1.ZERO_ADDRESS);
    }
    before('setup signers', async () => {
        [, alice, bob, admin] = await hardhat_1.ethers.getSigners();
    });
    (0, sharedBeforeEach_1.sharedBeforeEach)('deploy vault, router, tokens, and pool', async function () {
        vault = await TypesConverter_1.default.toIVaultMock(await VaultDeployer.deployMock());
        const WETH = await (0, contract_1.deploy)('v3-solidity-utils/WETHTestToken');
        permit2 = await (0, Permit2Deployer_1.deployPermit2)();
        router = await (0, contract_1.deploy)('v3-vault/Router', { args: [vault, WETH, permit2, ROUTER_VERSION] });
        tokenA = await (0, contract_1.deploy)('v3-solidity-utils/ERC20TestToken', { args: ['Token A', 'TKNA', 18] });
        tokenB = await (0, contract_1.deploy)('v3-solidity-utils/ERC20TestToken', { args: ['Token B', 'TKNB', 6] });
        tokenAAddress = await tokenA.getAddress();
        tokenBAddress = await tokenB.getAddress();
        tokenAIdx = tokenAAddress < tokenBAddress ? 0 : 1;
        tokenBIdx = tokenAAddress < tokenBAddress ? 1 : 0;
    });
    (0, sharedBeforeEach_1.sharedBeforeEach)('create pool and grant approvals', async () => {
        // Not testing the migration router here; address can't be zero. Just use the regular router address.
        factory = await (0, contract_1.deploy)('LBPoolFactory', {
            args: [await vault.getAddress(), (0, numbers_1.bn)(time_1.MONTH) * 12n, FACTORY_VERSION, POOL_VERSION, router, router],
        });
        poolTokens = (0, sortingHelper_1.sortAddresses)([tokenAAddress, tokenBAddress]);
        // Leave a gap to test operations before start time.
        globalPoolStartTime = (await (0, time_1.currentTimestamp)()) + (0, numbers_1.bn)(time_1.MONTH);
        globalPoolEndTime = globalPoolStartTime + (0, numbers_1.bn)(time_1.MONTH);
        globalPool = await deployPool(WEIGHTS[0], WEIGHTS[1], WEIGHTS[1], WEIGHTS[0], globalPoolStartTime, globalPoolEndTime, false);
        for (const user of [alice, bob, admin]) {
            await tokenA.mint(user, TOKEN_AMOUNT + SWAP_AMOUNT);
            await tokenB.mint(user, TOKEN_AMOUNT);
            await globalPool.connect(user).approve(router, constants_1.MAX_UINT256);
            for (const token of [tokenA, tokenB]) {
                await token.connect(user).approve(permit2, constants_1.MAX_UINT256);
                await permit2.connect(user).approve(token, router, constants_1.MAX_UINT160, constants_1.MAX_UINT48);
            }
        }
    });
    (0, sharedBeforeEach_1.sharedBeforeEach)('grant permission', async () => {
        const setPoolSwapFeeAction = await (0, actions_1.actionId)(vault, 'setStaticSwapFeePercentage');
        const authorizerAddress = await vault.getAuthorizer();
        const authorizer = await (0, contract_1.deployedAt)('v3-vault/BasicAuthorizerMock', authorizerAddress);
        await authorizer.grantRole(setPoolSwapFeeAction, admin.address);
        await vault.connect(admin).setStaticSwapFeePercentage(globalPool, POOL_SWAP_FEE);
    });
    it('should have correct versions', async () => {
        (0, chai_1.expect)(await factory.version()).to.eq(FACTORY_VERSION);
        (0, chai_1.expect)(await factory.getPoolVersion()).to.eq(POOL_VERSION);
        (0, chai_1.expect)(await globalPool.version()).to.eq(POOL_VERSION);
    });
    it('returns starting weights', async () => {
        const weights = await globalPool.getNormalizedWeights();
        (0, chai_1.expect)(weights).to.be.deep.eq(WEIGHTS);
    });
    it('cannot be initialized by non-owners', async () => {
        await (0, chai_1.expect)(router.connect(alice).initialize(globalPool, poolTokens, INITIAL_BALANCES, numbers_1.FP_ZERO, false, '0x')).to.be.revertedWithCustomError(vault, 'BeforeInitializeHookFailed');
    });
    it('can be initialized by the owner', async () => {
        await (0, chai_1.expect)(await router.connect(admin).initialize(globalPool, poolTokens, INITIAL_BALANCES, numbers_1.FP_ZERO, false, '0x'))
            .to.emit(vault, 'PoolInitialized')
            .withArgs(globalPool);
    });
    context('with initialized pool', () => {
        (0, sharedBeforeEach_1.sharedBeforeEach)(async () => {
            await router.connect(admin).initialize(globalPool, poolTokens, INITIAL_BALANCES, numbers_1.FP_ZERO, false, '0x');
        });
        it('pool and protocol fee preconditions', async () => {
            const poolConfig = await vault.getPoolConfig(globalPool);
            (0, chai_1.expect)(poolConfig.isPoolRegistered).to.be.true;
            (0, chai_1.expect)(poolConfig.isPoolInitialized).to.be.true;
            (0, chai_1.expect)(await vault.getStaticSwapFeePercentage(globalPool)).to.eq(POOL_SWAP_FEE);
        });
        it('has the correct pool tokens and balances', async () => {
            const tokensFromPool = await globalPool.getTokens();
            (0, chai_1.expect)(tokensFromPool).to.deep.equal(poolTokens);
            const [tokensFromVault, , balancesFromVault] = await vault.getPoolTokenInfo(globalPool);
            (0, chai_1.expect)(tokensFromVault).to.deep.equal(tokensFromPool);
            (0, chai_1.expect)(balancesFromVault).to.deep.equal(INITIAL_BALANCES);
        });
        it('cannot be initialized twice', async () => {
            await (0, chai_1.expect)(router.connect(alice).initialize(globalPool, poolTokens, INITIAL_BALANCES, numbers_1.FP_ZERO, false, '0x'))
                .to.be.revertedWithCustomError(vault, 'PoolAlreadyInitialized')
                .withArgs(await globalPool.getAddress());
        });
        describe('Owner operations and events', () => {
            it('should emit GradualWeightUpdateScheduled event on deployment', async () => {
                const startTime = (await (0, time_1.currentTimestamp)()) + 100n;
                const endTime = startTime + (0, numbers_1.bn)((0, numbers_1.bn)(time_1.MONTH));
                const endWeights = [(0, numbers_1.fp)(0.7), (0, numbers_1.fp)(0.3)];
                const tx = await deployPoolTx(WEIGHTS[0], WEIGHTS[1], endWeights[0], endWeights[1], startTime, endTime, false, (0, numbers_1.bn)(0));
                const receipt = await tx.wait();
                const event = expectEvent.inReceipt(receipt, 'PoolCreated');
                const pool = (await (0, contract_1.deployedAt)('LBPool', event.args.pool));
                await (0, chai_1.expect)(tx)
                    .to.emit(pool, 'GradualWeightUpdateScheduled')
                    .withArgs(startTime, endTime, WEIGHTS, endWeights);
            });
            it('should only allow owner to be the LP', async () => {
                await (0, time_1.advanceToTimestamp)(globalPoolStartTime - (0, numbers_1.bn)(time_1.MINUTE));
                const amounts = [SWAP_AMOUNT, SWAP_AMOUNT];
                await (0, chai_1.expect)(router.addLiquidityUnbalanced(globalPool, amounts, numbers_1.FP_ZERO, false, '0x')).to.be.revertedWithCustomError(vault, 'BeforeAddLiquidityHookFailed');
                await (0, chai_1.expect)(router.connect(admin).addLiquidityUnbalanced(globalPool, amounts, numbers_1.FP_ZERO, false, '0x')).to.be.revertedWithCustomError(vault, 'DoesNotSupportUnbalancedLiquidity');
                router.connect(admin).addLiquidityProportional(globalPool, amounts, numbers_1.FP_ONE, false, '0x');
            });
        });
        describe('Weight update on deployment', () => {
            it('should update weights gradually', async () => {
                const startTime = await (0, time_1.currentTimestamp)();
                const endTime = startTime + (0, numbers_1.bn)(time_1.MONTH);
                const endWeights = [(0, numbers_1.fp)(0.7), (0, numbers_1.fp)(0.3)];
                const pool = await deployPool(WEIGHTS[0], WEIGHTS[1], endWeights[0], endWeights[1], startTime, endTime, false);
                // Check weights at start
                (0, chai_1.expect)(await pool.getNormalizedWeights()).to.deep.equal(WEIGHTS);
                // Check weights halfway through
                await (0, time_1.advanceToTimestamp)(startTime + (0, numbers_1.bn)(time_1.MONTH) / 2n);
                const midWeights = await pool.getNormalizedWeights();
                (0, chai_1.expect)(midWeights[0]).to.be.closeTo((0, numbers_1.fp)(0.6), (0, numbers_1.fp)(1e-6));
                (0, chai_1.expect)(midWeights[1]).to.be.closeTo((0, numbers_1.fp)(0.4), (0, numbers_1.fp)(1e-6));
                // Check weights at end
                await (0, time_1.advanceToTimestamp)(endTime);
                (0, chai_1.expect)(await pool.getNormalizedWeights()).to.deep.equal(endWeights);
            });
            it('should constrain weights to [1%, 99%]', async () => {
                const startTime = await (0, time_1.currentTimestamp)();
                const endTime = startTime + (0, numbers_1.bn)(time_1.MONTH);
                // Try to set start weight below 1%
                await (0, chai_1.expect)(deployPoolTx((0, numbers_1.fp)(0.009), (0, numbers_1.fp)(0.991), WEIGHTS[0], WEIGHTS[1], startTime, endTime, false, (0, numbers_1.bn)(0))).to.be.revertedWithCustomError(factory, 'MinWeight');
                // Try to set start weight above 99%
                await (0, chai_1.expect)(deployPoolTx((0, numbers_1.fp)(0.991), (0, numbers_1.fp)(0.009), WEIGHTS[0], WEIGHTS[1], startTime, endTime, false, (0, numbers_1.bn)(0))).to.be.revertedWithCustomError(factory, 'MinWeight');
                // Try to set end weight below 1%
                await (0, chai_1.expect)(deployPoolTx(WEIGHTS[0], WEIGHTS[1], (0, numbers_1.fp)(0.009), (0, numbers_1.fp)(0.991), startTime, endTime, false, (0, numbers_1.bn)(0))).to.be.revertedWithCustomError(factory, 'MinWeight');
                // Try to set end weight above 99%
                await (0, chai_1.expect)(deployPoolTx(WEIGHTS[0], WEIGHTS[1], (0, numbers_1.fp)(0.991), (0, numbers_1.fp)(0.009), startTime, endTime, false, (0, numbers_1.bn)(0))).to.be.revertedWithCustomError(factory, 'MinWeight');
                // Valid weight update
                await (0, chai_1.expect)(deployPoolTx(WEIGHTS[0], WEIGHTS[1], (0, numbers_1.fp)(0.99), (0, numbers_1.fp)(0.01), startTime, endTime, false, (0, numbers_1.bn)(0))).to.not
                    .be.reverted;
            });
            it('should not allow endTime before startTime', async () => {
                const startTime = await (0, time_1.currentTimestamp)();
                const endTime = startTime - (0, numbers_1.bn)(time_1.MONTH);
                // Try to set endTime before startTime
                await (0, chai_1.expect)(deployPoolTx(WEIGHTS[0], WEIGHTS[1], (0, numbers_1.fp)(0.99), (0, numbers_1.fp)(0.01), startTime, endTime, false, (0, numbers_1.bn)(0))).to.be.revertedWithCustomError(factory, 'InvalidStartTime');
                // Valid time update
                await (0, chai_1.expect)(deployPoolTx(WEIGHTS[0], WEIGHTS[1], (0, numbers_1.fp)(0.99), (0, numbers_1.fp)(0.01), startTime, startTime + (0, numbers_1.bn)(time_1.MONTH), false, (0, numbers_1.bn)(0))).to.not.be.reverted;
            });
            it('should always sum weights to 1', async () => {
                const currentTime = await (0, time_1.currentTimestamp)();
                const startTime = currentTime + (0, numbers_1.bn)(time_1.MINUTE); // Set startTime 1 min in the future
                const endTime = startTime + (0, numbers_1.bn)(time_1.MONTH);
                const startWeights = [(0, numbers_1.fp)(0.5), (0, numbers_1.fp)(0.5)];
                const endWeights = [(0, numbers_1.fp)(0.7), (0, numbers_1.fp)(0.3)];
                // Move time to just before startTime
                await (0, time_1.advanceToTimestamp)(startTime - 1n);
                // Start at 50/50, schedule gradual shift to 70/30
                const pool = await deployPool(startWeights[0], startWeights[1], endWeights[0], endWeights[1], startTime, endTime, true);
                // Check weights at various points during the transition
                for (let i = 0; i <= 100; i++) {
                    const checkTime = startTime + ((0, numbers_1.bn)(i) * (0, numbers_1.bn)(time_1.MONTH)) / 100n;
                    // Only increase time if it's greater than the current time
                    const currentBlockTime = await hardhat_network_helpers_1.time.latest();
                    if (checkTime > currentBlockTime) {
                        await hardhat_network_helpers_1.time.increaseTo(checkTime);
                    }
                    const weights = await pool.getNormalizedWeights();
                    const sum = (BigInt(weights[0].toString()) + BigInt(weights[1].toString())).toString();
                    // Assert exact equality
                    (0, chai_1.expect)(sum).to.equal((0, numbers_1.fp)(1));
                }
            });
        });
        describe('Setters and Getters', () => {
            it('should get gradual weight update params', async () => {
                const startTime = await (0, time_1.currentTimestamp)();
                const endTime = startTime + (0, numbers_1.bn)(time_1.MONTH);
                const endWeights = [(0, numbers_1.fp)(0.7), (0, numbers_1.fp)(0.3)];
                const pool = await deployPool(WEIGHTS[0], WEIGHTS[1], endWeights[0], endWeights[1], startTime, endTime, false);
                const actualStartTime = await (0, time_1.currentTimestamp)();
                const params = await pool.getGradualWeightUpdateParams();
                (0, chai_1.expect)(params.startTime).to.equal(actualStartTime);
                (0, chai_1.expect)(params.endTime).to.equal(endTime);
                (0, chai_1.expect)(params.endWeights).to.deep.equal(endWeights);
            });
        });
        describe('Swap restrictions', () => {
            context('without project token restrictions', () => {
                it('should allow swaps after init time and before end time', async () => {
                    await (0, time_1.advanceToTimestamp)((globalPoolStartTime + globalPoolEndTime) / 2n);
                    await (0, chai_1.expect)(router
                        .connect(alice)
                        .swapSingleTokenExactIn(globalPool, poolTokens[tokenAIdx], poolTokens[tokenBIdx], SWAP_AMOUNT, 0, constants_1.MAX_UINT256, false, '0x')).to.not.be.reverted;
                });
                it('should not allow swaps before start time', async () => {
                    await (0, time_1.advanceToTimestamp)(globalPoolStartTime - (0, numbers_1.bn)(time_1.MINUTE));
                    await (0, chai_1.expect)(router
                        .connect(bob)
                        .swapSingleTokenExactIn(globalPool, poolTokens[tokenAIdx], poolTokens[tokenBIdx], SWAP_AMOUNT, 0, constants_1.MAX_UINT256, false, '0x')).to.be.revertedWithCustomError(globalPool, 'SwapsDisabled');
                });
                it('should allow swaps after end time', async () => {
                    await (0, time_1.advanceToTimestamp)(globalPoolEndTime + (0, numbers_1.bn)(time_1.DAY));
                    await (0, chai_1.expect)(router
                        .connect(bob)
                        .swapSingleTokenExactIn(globalPool, poolTokens[tokenAIdx], poolTokens[tokenBIdx], SWAP_AMOUNT, 0, constants_1.MAX_UINT256, false, '0x')).to.be.revertedWithCustomError(globalPool, 'SwapsDisabled');
                });
            });
        });
    });
});
