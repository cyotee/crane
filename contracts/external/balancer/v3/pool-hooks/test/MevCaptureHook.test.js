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
const contract_1 = require("@balancer-labs/v3-helpers/src/contract");
const numbers_1 = require("@balancer-labs/v3-helpers/src/numbers");
const hardhat_network_helpers_1 = require("@nomicfoundation/hardhat-network-helpers");
const sharedBeforeEach_1 = require("@balancer-labs/v3-common/sharedBeforeEach");
const VaultDeployer = __importStar(require("@balancer-labs/v3-helpers/src/models/vault/VaultDeployer"));
const tokenConfig_1 = require("@balancer-labs/v3-helpers/src/models/tokens/tokenConfig");
const Permit2Deployer_1 = require("@balancer-labs/v3-vault/test/Permit2Deployer");
const time_1 = require("@balancer-labs/v3-helpers/src/time");
const ERC20TokenList_1 = __importDefault(require("@balancer-labs/v3-helpers/src/models/tokens/ERC20TokenList"));
const sortingHelper_1 = require("@balancer-labs/v3-helpers/src/models/tokens/sortingHelper");
const constants_1 = require("@balancer-labs/v3-helpers/src/constants");
const actions_1 = require("@balancer-labs/v3-helpers/src/models/misc/actions");
const TypesConverter_1 = __importDefault(require("@balancer-labs/v3-helpers/src/models/types/TypesConverter"));
const chai_1 = require("chai");
var RegistryContractType;
(function (RegistryContractType) {
    RegistryContractType[RegistryContractType["OTHER"] = 0] = "OTHER";
    RegistryContractType[RegistryContractType["POOL_FACTORY"] = 1] = "POOL_FACTORY";
    RegistryContractType[RegistryContractType["ROUTER"] = 2] = "ROUTER";
    RegistryContractType[RegistryContractType["HOOK"] = 3] = "HOOK";
    RegistryContractType[RegistryContractType["ERC4626"] = 4] = "ERC4626";
})(RegistryContractType || (RegistryContractType = {}));
describe('MevCaptureHook', () => {
    const ROUTER_VERSION = 'Router V1';
    const PRIORITY_GAS_THRESHOLD = 3000000n;
    const MEV_MULTIPLIER = (0, numbers_1.fp)(10000000000);
    const STATIC_SWAP_FEE_PERCENTAGE = (0, numbers_1.fp)(0.01); // 1% swap fee
    let permit2;
    let vault;
    let iVault;
    let factory;
    let pool;
    let poolTokens;
    let router;
    let untrustedRouter;
    let hook;
    let registry;
    let admin, lp, sender;
    let tokens;
    let token0, token1, WETH;
    let vaultAddress;
    before('setup signers', async () => {
        [admin, lp, sender] = await hardhat_1.ethers.getSigners();
    });
    (0, sharedBeforeEach_1.sharedBeforeEach)('deploy vault, tokens, and pools', async function () {
        vault = await VaultDeployer.deploy();
        iVault = await TypesConverter_1.default.toIVault(vault);
        vaultAddress = await vault.getAddress();
        WETH = await (0, contract_1.deploy)('v3-solidity-utils/WETHTestToken');
        permit2 = await (0, Permit2Deployer_1.deployPermit2)();
        router = await (0, contract_1.deploy)('v3-vault/Router', { args: [vaultAddress, WETH, permit2, ROUTER_VERSION] });
        untrustedRouter = await (0, contract_1.deploy)('v3-vault/Router', {
            args: [vaultAddress, WETH, permit2, 'UNTRUSTED_VERSION'],
        });
        factory = await (0, contract_1.deploy)('v3-vault/PoolFactoryMock', { args: [vaultAddress, 12 * time_1.MONTH] });
        registry = await (0, contract_1.deploy)('v3-standalone-utils/BalancerContractRegistry', { args: [vaultAddress] });
        tokens = await ERC20TokenList_1.default.create(2, { sorted: true });
        token0 = (await tokens.get(0));
        token1 = (await tokens.get(1));
        poolTokens = (0, sortingHelper_1.sortAddresses)([await token0.getAddress(), await token1.getAddress()]);
        pool = await (0, contract_1.deploy)('v3-vault/PoolMock', {
            args: [vaultAddress, 'Pool with MEV Hook', 'POOL-MEV'],
        });
        const defaultMevTaxMultiplier = 0;
        const defaultMevTaxThreshold = 0;
        hook = await (0, contract_1.deploy)('MevCaptureHook', {
            args: [vaultAddress, registry, defaultMevTaxMultiplier, defaultMevTaxThreshold],
        });
        await factory.registerPoolWithHook(pool, (0, tokenConfig_1.buildTokenConfig)(poolTokens), hook);
    });
    (0, sharedBeforeEach_1.sharedBeforeEach)('permissions', async () => {
        const authorizerAddress = await iVault.getAuthorizer();
        const authorizer = await (0, contract_1.deployedAt)('v3-vault/BasicAuthorizerMock', authorizerAddress);
        const actions = [];
        // Vault Actions
        actions.push(await (0, actions_1.actionId)(iVault, 'setStaticSwapFeePercentage'));
        // Registry Actions
        actions.push(await (0, actions_1.actionId)(registry, 'registerBalancerContract'));
        // MEV Hook Actions
        actions.push(await (0, actions_1.actionId)(hook, 'addMevTaxExemptSenders'));
        actions.push(await (0, actions_1.actionId)(hook, 'disableMevTax'));
        actions.push(await (0, actions_1.actionId)(hook, 'enableMevTax'));
        actions.push(await (0, actions_1.actionId)(hook, 'setDefaultMevTaxMultiplier'));
        actions.push(await (0, actions_1.actionId)(hook, 'setDefaultMevTaxThreshold'));
        actions.push(await (0, actions_1.actionId)(hook, 'setMaxMevSwapFeePercentage'));
        actions.push(await (0, actions_1.actionId)(hook, 'setPoolMevTaxMultiplier'));
        actions.push(await (0, actions_1.actionId)(hook, 'setPoolMevTaxThreshold'));
        await Promise.all(actions.map(async (action) => authorizer.grantRole(action, admin.address)));
    });
    (0, sharedBeforeEach_1.sharedBeforeEach)('registry configuration', async () => {
        await registry.connect(admin).registerBalancerContract(RegistryContractType.ROUTER, 'Router', router);
    });
    (0, sharedBeforeEach_1.sharedBeforeEach)('fees configuration', async () => {
        await iVault.connect(admin).setStaticSwapFeePercentage(pool, STATIC_SWAP_FEE_PERCENTAGE);
    });
    (0, sharedBeforeEach_1.sharedBeforeEach)('hook configuration', async () => {
        await hook.connect(admin).setDefaultMevTaxMultiplier(MEV_MULTIPLIER);
        await hook.connect(admin).setDefaultMevTaxThreshold(PRIORITY_GAS_THRESHOLD);
        await hook.connect(admin).setPoolMevTaxMultiplier(pool, MEV_MULTIPLIER);
        await hook.connect(admin).setPoolMevTaxThreshold(pool, PRIORITY_GAS_THRESHOLD);
        await hook.connect(admin).enableMevTax();
    });
    (0, sharedBeforeEach_1.sharedBeforeEach)('token allowances', async () => {
        await WETH.connect(lp).deposit({ value: (0, numbers_1.fp)(1000) });
        await WETH.connect(sender).deposit({ value: (0, numbers_1.fp)(1000) });
        await tokens.mint({ to: lp, amount: (0, numbers_1.fp)(1e12) });
        await tokens.mint({ to: sender, amount: (0, numbers_1.fp)(1e12) });
        await pool.connect(lp).approve(router, constants_1.MAX_UINT256);
        await pool.connect(lp).approve(untrustedRouter, constants_1.MAX_UINT256);
        for (const token of [...tokens.tokens, WETH, pool]) {
            for (const from of [lp, sender]) {
                await token.connect(from).approve(permit2, constants_1.MAX_UINT256);
                await permit2.connect(from).approve(token, router, constants_1.MAX_UINT160, constants_1.MAX_UINT48);
                await permit2.connect(from).approve(token, untrustedRouter, constants_1.MAX_UINT160, constants_1.MAX_UINT48);
            }
        }
    });
    (0, sharedBeforeEach_1.sharedBeforeEach)('initialize pools', async () => {
        await router.connect(lp).initialize(pool, poolTokens, Array(poolTokens.length).fill((0, numbers_1.fp)(1000)), 0, false, '0x');
        await pool.connect(lp).transfer(sender, (0, numbers_1.fp)(100));
    });
    describe('when there is no MEV tax', async () => {
        it('MEV hook disabled', async () => {
            await hook.connect(admin).disableMevTax();
            (0, chai_1.expect)(await hook.isMevTaxEnabled()).to.be.false;
            const amountIn = (0, numbers_1.fp)(10);
            const baseFee = await getNextBlockBaseFee();
            // "BaseFee + 2 * PriorityGasThreshold" should trigger MEV Tax, but static swap fee will be charged because MEV tax is
            // disabled.
            const txGasPrice = baseFee + 2n * PRIORITY_GAS_THRESHOLD;
            const balancesBefore = await getBalances();
            await router.connect(sender).swapSingleTokenExactIn(pool, token0, token1, amountIn, 0, constants_1.MAX_UINT256, false, '0x', {
                gasPrice: txGasPrice,
            });
            const balancesAfter = await getBalances();
            await checkSwapFeeExactInWithoutMevTax(balancesBefore, balancesAfter, amountIn);
        });
        it('low priority gas price', async () => {
            const amountIn = (0, numbers_1.fp)(10);
            // To trigger MEV tax, `txGasPrice` > `BaseFee + PriorityGasThreshold`.
            const txGasPrice = PRIORITY_GAS_THRESHOLD;
            const balancesBefore = await getBalances();
            await router.connect(sender).swapSingleTokenExactIn(pool, token0, token1, amountIn, 0, constants_1.MAX_UINT256, false, '0x', {
                gasPrice: txGasPrice,
            });
            const balancesAfter = await getBalances();
            await checkSwapFeeExactInWithoutMevTax(balancesBefore, balancesAfter, amountIn);
        });
        it('MEV multiplier is 0', async () => {
            // 0 multiplier. Should return static fee.
            await hook.setPoolMevTaxMultiplier(pool, 0);
            const amountIn = (0, numbers_1.fp)(10);
            const baseFee = await getNextBlockBaseFee();
            // "BaseFee + PriorityGas + 1" should trigger MEV Tax.
            const txGasPrice = baseFee + PRIORITY_GAS_THRESHOLD + 1n;
            const balancesBefore = await getBalances();
            await router.connect(sender).swapSingleTokenExactIn(pool, token0, token1, amountIn, 0, constants_1.MAX_UINT256, false, '0x', {
                gasPrice: txGasPrice,
            });
            const balancesAfter = await getBalances();
            await checkSwapFeeExactInWithoutMevTax(balancesBefore, balancesAfter, amountIn);
        });
        it('Address is MEV tax-exempt', async () => {
            await hook.connect(admin).addMevTaxExemptSenders([sender]);
            await hook.setPoolMevTaxMultiplier(pool, MEV_MULTIPLIER);
            const amountIn = (0, numbers_1.fp)(10);
            const baseFee = await getNextBlockBaseFee();
            // `BaseFee + 10 * PRIORITY_GAS_THRESHOLD` should trigger MEV Tax and pay MEV tax over
            // `9 * PRIORITY_GAS_THRESHOLD` (static fee is charged up to `baseFee + PRIORITY_GAS_THRESHOLD`). However, since
            // "sender" is exempt, he will pay only static fee.
            const txGasPrice = baseFee + 10n * PRIORITY_GAS_THRESHOLD;
            const balancesBefore = await getBalances();
            await router.connect(sender).swapSingleTokenExactIn(pool, token0, token1, amountIn, 0, constants_1.MAX_UINT256, false, '0x', {
                gasPrice: txGasPrice,
            });
            const balancesAfter = await getBalances();
            await checkSwapFeeExactInWithoutMevTax(balancesBefore, balancesAfter, amountIn);
        });
    });
    describe('when there is MEV tax', async () => {
        it('MEV fee percentage bigger than default max value', async () => {
            await hook.connect(admin).setMaxMevSwapFeePercentage((0, numbers_1.fp)(0.2));
            // Big multiplier, the MEV fee percentage should be more than 20%. Since the Max fee is set to 20%, that's what
            // will be charged.
            await hook.setPoolMevTaxMultiplier(pool, (0, numbers_1.fpMulDown)(MEV_MULTIPLIER, (0, numbers_1.fp)(100000000n)));
            const amountIn = (0, numbers_1.fp)(10);
            const baseFee = await getNextBlockBaseFee();
            // "BaseFee + PriorityGas + 1" should trigger MEV Tax.
            const txGasPrice = baseFee + PRIORITY_GAS_THRESHOLD + 1n;
            const balancesBefore = await getBalances();
            await router.connect(sender).swapSingleTokenExactIn(pool, token0, token1, amountIn, 0, constants_1.MAX_UINT256, false, '0x', {
                gasPrice: txGasPrice,
            });
            const balancesAfter = await getBalances();
            await checkSwapFeeExactInChargingMevTax(balancesBefore, balancesAfter, txGasPrice, amountIn);
        });
        it('Address is MEV tax-exempt but router is not trusted', async () => {
            await hook.connect(admin).addMevTaxExemptSenders([sender]);
            await hook.setPoolMevTaxMultiplier(pool, MEV_MULTIPLIER);
            const amountIn = (0, numbers_1.fp)(10);
            const baseFee = await getNextBlockBaseFee();
            // `BaseFee + 10 * PRIORITY_GAS_THRESHOLD` should trigger MEV Tax and pay MEV tax over
            // `9 * PRIORITY_GAS_THRESHOLD` (static fee is charged up to `baseFee + PRIORITY_GAS_THRESHOLD`). However, since
            // "sender" is exempt, he will pay only static fee.
            const txGasPrice = baseFee + 10n * PRIORITY_GAS_THRESHOLD;
            const balancesBefore = await getBalances();
            await untrustedRouter
                .connect(sender)
                .swapSingleTokenExactIn(pool, token0, token1, amountIn, 0, constants_1.MAX_UINT256, false, '0x', {
                gasPrice: txGasPrice,
            });
            const balancesAfter = await getBalances();
            await checkSwapFeeExactInChargingMevTax(balancesBefore, balancesAfter, txGasPrice, amountIn);
        });
        it('charge MEV tax proportional to priority gas price', async () => {
            await hook.setPoolMevTaxMultiplier(pool, MEV_MULTIPLIER);
            const amountIn = (0, numbers_1.fp)(10);
            const baseFee = await getNextBlockBaseFee();
            // `BaseFee + 10 * PRIORITY_GAS_THRESHOLD` should trigger MEV Tax and pay MEV tax over
            // `9 * PRIORITY_GAS_THRESHOLD` (static fee is charged up to `baseFee + PRIORITY_GAS_THRESHOLD`).
            const txGasPrice = baseFee + 10n * PRIORITY_GAS_THRESHOLD;
            const balancesBefore = await getBalances();
            await router.connect(sender).swapSingleTokenExactIn(pool, token0, token1, amountIn, 0, constants_1.MAX_UINT256, false, '0x', {
                gasPrice: txGasPrice,
            });
            const balancesAfter = await getBalances();
            await checkSwapFeeExactInChargingMevTax(balancesBefore, balancesAfter, txGasPrice, amountIn);
        });
    });
    describe('add liquidity', async () => {
        context('when there is no MEV tax', () => {
            it('allows proportional for any gas price', async () => {
                const baseFee = await getNextBlockBaseFee();
                const txGasPrice = (baseFee + PRIORITY_GAS_THRESHOLD) * 100n;
                await (0, chai_1.expect)(router
                    .connect(sender)
                    .addLiquidityProportional(pool, Array(poolTokens.length).fill((0, numbers_1.fp)(1000)), (0, numbers_1.fp)(1), false, '0x', {
                    gasPrice: txGasPrice,
                })).to.not.be.reverted;
            });
            it('allows unbalanced for gas price below threshold', async () => {
                const baseFee = await getNextBlockBaseFee();
                const txGasPrice = baseFee + PRIORITY_GAS_THRESHOLD;
                await (0, chai_1.expect)(router
                    .connect(sender)
                    .addLiquidityUnbalanced(pool, Array(poolTokens.length).fill((0, numbers_1.fp)(100)), (0, numbers_1.fp)(0), false, '0x', {
                    gasPrice: txGasPrice,
                })).to.not.be.reverted;
            });
        });
        context('when MEV tax has to be applied', () => {
            it('allows unbalanced for any gas price if the hook is disabled', async () => {
                await hook.connect(admin).disableMevTax();
                const baseFee = await getNextBlockBaseFee();
                const txGasPrice = (baseFee + PRIORITY_GAS_THRESHOLD) * 100n;
                await (0, chai_1.expect)(router
                    .connect(sender)
                    .addLiquidityUnbalanced(pool, Array(poolTokens.length).fill((0, numbers_1.fp)(100)), (0, numbers_1.fp)(0), false, '0x', {
                    gasPrice: txGasPrice,
                })).to.not.be.reverted;
            });
            it('blocks unbalanced for gas price above threshold', async () => {
                const baseFee = await getNextBlockBaseFee();
                const txGasPrice = baseFee + PRIORITY_GAS_THRESHOLD + 1n;
                await (0, chai_1.expect)(router
                    .connect(sender)
                    .addLiquidityUnbalanced(pool, Array(poolTokens.length).fill((0, numbers_1.fp)(1000)), (0, numbers_1.fp)(0), false, '0x', {
                    gasPrice: txGasPrice,
                })).to.be.revertedWithCustomError(vault, 'BeforeAddLiquidityHookFailed');
            });
        });
    });
    describe('remove liquidity', async () => {
        context('when there is no MEV tax', () => {
            it('allows proportional for any gas price', async () => {
                const baseFee = await getNextBlockBaseFee();
                const txGasPrice = (baseFee + PRIORITY_GAS_THRESHOLD) * 100n;
                await (0, chai_1.expect)(router.connect(lp).removeLiquidityProportional(pool, (0, numbers_1.fp)(1), Array(poolTokens.length).fill(0n), false, '0x', {
                    gasPrice: txGasPrice,
                })).to.not.be.reverted;
            });
            it('allows unbalanced for gas price below threshold', async () => {
                const baseFee = await getNextBlockBaseFee();
                const txGasPrice = baseFee + PRIORITY_GAS_THRESHOLD;
                await (0, chai_1.expect)(router.connect(lp).removeLiquiditySingleTokenExactIn(pool, (0, numbers_1.fp)(1), token0, 1n, false, '0x', {
                    gasPrice: txGasPrice,
                })).to.not.be.reverted;
            });
        });
        context('when MEV tax has to be applied', () => {
            it('allows unbalanced for any gas price if the hook is disabled', async () => {
                await hook.connect(admin).disableMevTax();
                const baseFee = await getNextBlockBaseFee();
                const txGasPrice = (baseFee + PRIORITY_GAS_THRESHOLD) * 100n;
                await (0, chai_1.expect)(router.connect(lp).removeLiquiditySingleTokenExactIn(pool, (0, numbers_1.fp)(1), token0, 1n, false, '0x', {
                    gasPrice: txGasPrice,
                })).to.not.be.reverted;
            });
            it('blocks unbalanced for gas price above threshold', async () => {
                const baseFee = await getNextBlockBaseFee();
                const txGasPrice = baseFee + PRIORITY_GAS_THRESHOLD + 1n;
                await (0, chai_1.expect)(router.connect(lp).removeLiquiditySingleTokenExactIn(pool, (0, numbers_1.fp)(1), token0, 1n, false, '0x', {
                    gasPrice: txGasPrice,
                })).to.be.revertedWithCustomError(vault, 'BeforeRemoveLiquidityHookFailed');
            });
        });
    });
    async function getBalances() {
        return {
            token0: await token0.connect(sender).balanceOf(sender),
            token1: await token1.connect(sender).balanceOf(sender),
        };
    }
    async function checkSwapFeeExactInChargingMevTax(balancesBefore, balancesAfter, txGasPrice, amountIn) {
        const mevMultiplier = await hook.getPoolMevTaxMultiplier(pool);
        const filter = vault.filters.Swap;
        const events = await vault.queryFilter(filter, -1);
        const swapEvent = events[0];
        const baseFee = await getNextBlockBaseFee();
        const priorityGasPrice = txGasPrice - baseFee;
        let mevSwapFeePercentage = STATIC_SWAP_FEE_PERCENTAGE + (0, numbers_1.fpMulDown)(priorityGasPrice - PRIORITY_GAS_THRESHOLD, mevMultiplier);
        const maxMevSwapFeePercentage = await hook.getMaxMevSwapFeePercentage();
        if (mevSwapFeePercentage >= maxMevSwapFeePercentage) {
            // If mevSwapFeePercentage > max fee percentage, charge the max value.
            mevSwapFeePercentage = maxMevSwapFeePercentage;
        }
        const mevSwapFee = (0, numbers_1.fpMulDown)(mevSwapFeePercentage, amountIn);
        (0, chai_1.expect)(swapEvent.args.swapFeePercentage).to.be.eq(mevSwapFeePercentage, 'Incorrect Swap Fee Percentage');
        (0, chai_1.expect)(swapEvent.args.swapFeePercentage).to.be.gte(STATIC_SWAP_FEE_PERCENTAGE, 'MEV fee percentage lower than static fee percentage');
        (0, chai_1.expect)(swapEvent.args.swapFeeAmount).to.be.eq(mevSwapFee, 'Incorrect Swap Fee');
        (0, chai_1.expect)(balancesAfter.token0).to.be.eq(balancesBefore.token0 - amountIn);
        (0, chai_1.expect)(balancesAfter.token1).to.be.eq(balancesBefore.token1 + amountIn - mevSwapFee);
    }
    async function checkSwapFeeExactInWithoutMevTax(balancesBefore, balancesAfter, amountIn) {
        const filter = vault.filters.Swap;
        const events = await vault.queryFilter(filter, -1);
        const swapEvent = events[0];
        const staticSwapFee = (0, numbers_1.fpMulDown)(STATIC_SWAP_FEE_PERCENTAGE, amountIn);
        (0, chai_1.expect)(swapEvent.args.swapFeePercentage).to.be.eq(STATIC_SWAP_FEE_PERCENTAGE, 'Incorrect Swap Fee Percentage');
        (0, chai_1.expect)(swapEvent.args.swapFeeAmount).to.be.eq(staticSwapFee, 'Incorrect Swap Fee');
        (0, chai_1.expect)(balancesAfter.token0).to.be.eq(balancesBefore.token0 - amountIn);
        (0, chai_1.expect)(balancesAfter.token1).to.be.eq(balancesBefore.token1 + amountIn - staticSwapFee);
    }
    async function getNextBlockBaseFee() {
        const provider = hardhat_1.ethers.provider;
        const block = await provider.getBlock('latest'); // Get the latest block
        const latestBlockBaseFee = block?.baseFeePerGas || 0n;
        await (0, hardhat_network_helpers_1.setNextBlockBaseFeePerGas)(latestBlockBaseFee);
        return latestBlockBaseFee;
    }
});
