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
const ethers_1 = require("ethers");
const contract_1 = require("@balancer-labs/v3-helpers/src/contract");
const sharedBeforeEach_1 = require("@balancer-labs/v3-common/sharedBeforeEach");
const VaultDeployer = __importStar(require("@balancer-labs/v3-helpers/src/models/vault/VaultDeployer"));
const TypesConverter_1 = __importDefault(require("@balancer-labs/v3-helpers/src/models/types/TypesConverter"));
const time_1 = require("@balancer-labs/v3-helpers/src/time");
const constants_1 = require("@balancer-labs/v3-helpers/src/constants");
const numbers_1 = require("@balancer-labs/v3-helpers/src/numbers");
const types_1 = require("@balancer-labs/v3-helpers/src/models/types/types");
const Permit2Deployer_1 = require("./Permit2Deployer");
require("@balancer-labs/v3-common/setupTests");
const poolSetup_1 = require("./poolSetup");
const sortingHelper_1 = require("@balancer-labs/v3-helpers/src/models/tokens/sortingHelper");
describe('ERC4626VaultPrimitive', function () {
    const BATCH_ROUTER_VERSION = 'BatchRouter v9';
    const ROUTER_VERSION = 'Router v9';
    const TOKEN_AMOUNT = (0, numbers_1.fp)(1000);
    const SWAP_AMOUNT = (0, numbers_1.fp)(100);
    const MIN_BPT = (0, numbers_1.bn)(1e6);
    // Donate to wrapped tokens to generate different rates.
    const daiToDonate = (0, numbers_1.fp)((Math.random() * 1000 + 10).toFixed(0));
    const usdcToDonate = (0, numbers_1.fp)((Math.random() * 1000 + 10).toFixed(0));
    let permit2;
    let vault;
    let router;
    let bufferRouter;
    let batchRouter;
    let factory;
    let pool;
    let wDAI;
    let DAI;
    let wUSDC;
    let USDC;
    let yieldBearingPoolTokens;
    let lp;
    let alice;
    let zero;
    before('setup signers', async () => {
        zero = new ethers_1.VoidSigner('0x0000000000000000000000000000000000000000', hardhat_1.ethers.provider);
        [, lp, alice] = await hardhat_1.ethers.getSigners();
    });
    (0, sharedBeforeEach_1.sharedBeforeEach)('deploy vault, router, tokens, and pool factory', async function () {
        const vaultMock = await VaultDeployer.deployMock();
        vault = await TypesConverter_1.default.toIVaultMock(vaultMock);
        permit2 = await (0, Permit2Deployer_1.deployPermit2)();
        const WETH = await (0, contract_1.deploy)('v3-solidity-utils/WETHTestToken');
        batchRouter = await (0, contract_1.deploy)('v3-vault/BatchRouter', {
            args: [vault, await WETH.getAddress(), permit2, BATCH_ROUTER_VERSION],
        });
        router = await (0, contract_1.deploy)('v3-vault/Router', {
            args: [vault, await WETH.getAddress(), permit2, ROUTER_VERSION],
        });
        bufferRouter = await (0, contract_1.deploy)('v3-vault/BufferRouter', {
            args: [vault, await WETH.getAddress(), permit2, ROUTER_VERSION],
        });
        DAI = await (0, contract_1.deploy)('v3-solidity-utils/ERC20TestToken', { args: ['DAI', 'DAI', 18] });
        wDAI = await (0, contract_1.deploy)('v3-solidity-utils/ERC4626TestToken', {
            args: [DAI, 'Wrapped DAI', 'wDAI', 18],
        });
        // Using USDC as 18 decimals for simplicity.
        USDC = await (0, contract_1.deploy)('v3-solidity-utils/ERC20TestToken', { args: ['USDC', 'USDC', 18] });
        wUSDC = await (0, contract_1.deploy)('v3-solidity-utils/ERC4626TestToken', {
            args: [USDC, 'Wrapped USDC', 'wUSDC', 18],
        });
        await DAI.mint(alice, TOKEN_AMOUNT);
        await DAI.connect(alice).approve(permit2, constants_1.MAX_UINT256);
        await permit2.connect(alice).approve(DAI, batchRouter, constants_1.MAX_UINT160, constants_1.MAX_UINT48);
        yieldBearingPoolTokens = (0, sortingHelper_1.sortAddresses)([await wDAI.getAddress(), await wUSDC.getAddress()]);
        factory = await (0, contract_1.deploy)('v3-vault/PoolFactoryMock', { args: [vault, 12 * time_1.MONTH] });
    });
    async function createYieldBearingPool() {
        // Initialize assets and supply.
        await DAI.mint(lp, TOKEN_AMOUNT);
        await DAI.connect(lp).approve(wDAI, TOKEN_AMOUNT);
        await wDAI.connect(lp).deposit(TOKEN_AMOUNT, lp);
        await USDC.mint(lp, TOKEN_AMOUNT);
        await USDC.connect(lp).approve(wUSDC, TOKEN_AMOUNT);
        await wUSDC.connect(lp).deposit(TOKEN_AMOUNT, lp);
        pool = await (0, contract_1.deploy)('v3-vault/PoolMock', {
            args: [await vault.getAddress(), 'Yield-bearing Pool DAI-USDC', 'BP-DAI_USDC'],
        });
        const rpwDAI = await (0, contract_1.deploy)('v3-vault/ERC4626RateProvider', {
            args: [await wDAI.getAddress()],
        });
        const rpwUSDC = await (0, contract_1.deploy)('v3-vault/ERC4626RateProvider', {
            args: [await wUSDC.getAddress()],
        });
        const rateProviders = [];
        rateProviders[yieldBearingPoolTokens.indexOf(await wDAI.getAddress())] = await rpwDAI.getAddress();
        rateProviders[yieldBearingPoolTokens.indexOf(await wUSDC.getAddress())] = await rpwUSDC.getAddress();
        await factory.connect(lp).registerTestPool(pool, (0, poolSetup_1.buildTokenConfig)(yieldBearingPoolTokens, rateProviders));
        return (await (0, contract_1.deployedAt)('PoolMock', await pool.getAddress()));
    }
    async function createAndInitializeYieldBearingPool() {
        pool = await createYieldBearingPool();
        await pool.connect(lp).approve(router, constants_1.MAX_UINT256);
        await setupTokenApprovals(lp);
        await router
            .connect(lp)
            .initialize(pool, yieldBearingPoolTokens, [TOKEN_AMOUNT, TOKEN_AMOUNT], numbers_1.FP_ZERO, false, '0x');
        return pool;
    }
    async function setupTokenApprovals(signer) {
        for (const token of [wDAI, wUSDC, DAI, USDC]) {
            await token.connect(signer).approve(permit2, constants_1.MAX_UINT256);
            await permit2.connect(signer).approve(token, router, constants_1.MAX_UINT160, constants_1.MAX_UINT48);
            await permit2.connect(signer).approve(token, bufferRouter, constants_1.MAX_UINT160, constants_1.MAX_UINT48);
            await permit2.connect(signer).approve(token, batchRouter, constants_1.MAX_UINT160, constants_1.MAX_UINT48);
        }
    }
    describe('registration', () => {
        (0, sharedBeforeEach_1.sharedBeforeEach)('register factory and create pool', async () => {
            pool = await createYieldBearingPool();
        });
        it('pool has correct metadata', async () => {
            (0, chai_1.expect)(await pool.name()).to.eq('Yield-bearing Pool DAI-USDC');
            (0, chai_1.expect)(await pool.symbol()).to.eq('BP-DAI_USDC');
        });
        it('registers the pool', async () => {
            const poolConfig = await vault.getPoolConfig(pool);
            (0, chai_1.expect)(poolConfig.isPoolRegistered).to.be.true;
            (0, chai_1.expect)(poolConfig.isPoolInitialized).to.be.false;
        });
        it('has the correct tokens', async () => {
            const actualTokens = await vault.getPoolTokens(pool);
            (0, chai_1.expect)(actualTokens).to.deep.equal(yieldBearingPoolTokens);
        });
        it('configures the pool correctly', async () => {
            const currentTime = await (0, time_1.currentTimestamp)();
            const poolConfig = await vault.getPoolConfig(pool);
            const [paused] = await vault.getPoolPausedState(pool);
            (0, chai_1.expect)(paused).to.be.false;
            (0, chai_1.expect)(poolConfig.pauseWindowEndTime).to.gt(currentTime);
            (0, chai_1.expect)(poolConfig.liquidityManagement.disableUnbalancedLiquidity).to.be.false;
            (0, chai_1.expect)(poolConfig.liquidityManagement.enableAddLiquidityCustom).to.be.true;
            (0, chai_1.expect)(poolConfig.liquidityManagement.enableRemoveLiquidityCustom).to.be.true;
            const hooksConfig = await vault.getHooksConfig(pool);
            (0, chai_1.expect)(hooksConfig.shouldCallBeforeInitialize).to.be.false;
            (0, chai_1.expect)(hooksConfig.shouldCallAfterInitialize).to.be.false;
            (0, chai_1.expect)(hooksConfig.shouldCallBeforeAddLiquidity).to.be.false;
            (0, chai_1.expect)(hooksConfig.shouldCallAfterAddLiquidity).to.be.false;
            (0, chai_1.expect)(hooksConfig.shouldCallBeforeRemoveLiquidity).to.be.false;
            (0, chai_1.expect)(hooksConfig.shouldCallAfterRemoveLiquidity).to.be.false;
            (0, chai_1.expect)(hooksConfig.shouldCallBeforeSwap).to.be.false;
            (0, chai_1.expect)(hooksConfig.shouldCallAfterSwap).to.be.false;
        });
    });
    describe('initialization', () => {
        (0, sharedBeforeEach_1.sharedBeforeEach)('create pool', async () => {
            pool = await createYieldBearingPool();
            await pool.connect(lp).approve(router, constants_1.MAX_UINT256);
            for (const token of [wDAI, wUSDC]) {
                await token.connect(lp).approve(permit2, constants_1.MAX_UINT256);
                await permit2.connect(lp).approve(token, router, constants_1.MAX_UINT160, constants_1.MAX_UINT48);
            }
        });
        it('satisfies preconditions', async () => {
            (0, chai_1.expect)(await wDAI.balanceOf(lp)).to.eq(TOKEN_AMOUNT);
            (0, chai_1.expect)(await wUSDC.balanceOf(lp)).to.eq(TOKEN_AMOUNT);
        });
        it('emits an event', async () => {
            (0, chai_1.expect)(await router
                .connect(lp)
                .initialize(pool, yieldBearingPoolTokens, [TOKEN_AMOUNT, TOKEN_AMOUNT], numbers_1.FP_ZERO, false, '0x'))
                .to.emit(vault, 'PoolInitialized')
                .withArgs(pool);
        });
        it('updates the state', async () => {
            await router
                .connect(lp)
                .initialize(pool, yieldBearingPoolTokens, [TOKEN_AMOUNT, TOKEN_AMOUNT], numbers_1.FP_ZERO, false, '0x');
            const poolConfig = await vault.getPoolConfig(pool);
            (0, chai_1.expect)(poolConfig.isPoolRegistered).to.be.true;
            (0, chai_1.expect)(poolConfig.isPoolInitialized).to.be.true;
            (0, chai_1.expect)(await pool.balanceOf(lp)).to.eq(TOKEN_AMOUNT * 2n - MIN_BPT);
            (0, chai_1.expect)(await wDAI.balanceOf(lp)).to.eq(0);
            (0, chai_1.expect)(await wUSDC.balanceOf(lp)).to.eq(0);
            const [, tokenInfo, balances] = await vault.getPoolTokenInfo(pool);
            const tokenTypes = tokenInfo.map((config) => config.tokenType);
            const expectedTokenTypes = yieldBearingPoolTokens.map(() => types_1.TokenType.WITH_RATE);
            (0, chai_1.expect)(tokenTypes).to.deep.equal(expectedTokenTypes);
            (0, chai_1.expect)(balances).to.deep.equal([TOKEN_AMOUNT, TOKEN_AMOUNT]);
        });
        it('cannot be initialized twice', async () => {
            await router
                .connect(lp)
                .initialize(pool, yieldBearingPoolTokens, [TOKEN_AMOUNT, TOKEN_AMOUNT], numbers_1.FP_ZERO, false, '0x');
            await (0, chai_1.expect)(router.connect(lp).initialize(pool, yieldBearingPoolTokens, [TOKEN_AMOUNT, TOKEN_AMOUNT], numbers_1.FP_ZERO, false, '0x')).to.be.revertedWithCustomError(vault, 'PoolAlreadyInitialized');
        });
    });
    describe('queries', () => {
        const bufferInitAmount = (0, numbers_1.fp)(1);
        (0, sharedBeforeEach_1.sharedBeforeEach)('create and initialize pool', async () => {
            pool = await createAndInitializeYieldBearingPool();
            // Donate to wrapped tokens to generate different rates.
            await DAI.mint(lp, daiToDonate);
            await DAI.connect(lp).transfer(await wDAI.getAddress(), daiToDonate);
            await USDC.mint(lp, usdcToDonate);
            await USDC.connect(lp).transfer(await wUSDC.getAddress(), usdcToDonate);
            await DAI.mint(lp, bufferInitAmount);
            await USDC.mint(lp, bufferInitAmount);
            await bufferRouter.connect(lp).initializeBuffer(wDAI, bufferInitAmount, 0, 0);
            await bufferRouter.connect(lp).initializeBuffer(wUSDC, bufferInitAmount, 0, 0);
        });
        it('should not require tokens in advance to querySwapExactIn using buffer', async () => {
            // Check that vault does not have tokenIn balance (DAI).
            const reservesBefore = await vault.getReservesOf(await DAI.getAddress());
            (0, chai_1.expect)(reservesBefore).to.be.eq(bufferInitAmount, 'DAI balance is wrong');
            const paths = [
                {
                    tokenIn: DAI,
                    steps: [
                        { pool: wDAI, tokenOut: wDAI, isBuffer: true },
                        { pool: pool, tokenOut: wUSDC, isBuffer: false },
                        { pool: wUSDC, tokenOut: USDC, isBuffer: true },
                    ],
                    exactAmountIn: SWAP_AMOUNT,
                    minAmountOut: 0,
                },
            ];
            const queryOutput = await batchRouter.connect(zero).querySwapExactIn.staticCall(paths, zero.address, '0x');
            (0, chai_1.expect)(queryOutput.pathAmountsOut).to.have.length(1, 'Wrong query pathAmountsOut length');
            (0, chai_1.expect)(queryOutput.amountsOut).to.have.length(1, 'Wrong query amountsOut length');
            (0, chai_1.expect)(queryOutput.tokensOut).to.have.length(1, 'Wrong query tokensOut length');
            (0, chai_1.expect)(queryOutput.tokensOut[0]).to.be.equal(await USDC.getAddress(), 'Wrong query tokensOut value');
            // Connect Alice since the real transaction requires user to have tokens.
            const staticActualOutput = await batchRouter
                .connect(alice)
                .swapExactIn.staticCall(paths, constants_1.MAX_UINT256, false, '0x');
            (0, chai_1.expect)(staticActualOutput.pathAmountsOut).to.have.length(1, 'Wrong actual pathAmountsOut length');
            (0, chai_1.expect)(staticActualOutput.amountsOut).to.have.length(1, 'Wrong actual amountsOut length');
            (0, chai_1.expect)(staticActualOutput.tokensOut).to.have.length(1, 'Wrong actual tokensOut length');
            (0, chai_1.expect)(staticActualOutput.tokensOut[0]).to.be.equal(await USDC.getAddress(), 'Wrong actual tokensOut value');
            // Check if real transaction and query transaction are approx the same (tolerates an error when token is
            // wrapped/unwrapped and rate changes in the real operation).
            (0, chai_1.expect)(staticActualOutput.pathAmountsOut[0]).to.be.almostEqual(queryOutput.pathAmountsOut[0], 1e-10, 'Wrong actual pathAmountsOut value');
            (0, chai_1.expect)(staticActualOutput.amountsOut[0]).to.be.almostEqual(queryOutput.amountsOut[0], 1e-10, 'Wrong actual amountsOut value');
            // Connect Alice since the real transaction requires user to have tokens.
            const actualOutput = await batchRouter.connect(alice).swapExactIn(paths, constants_1.MAX_UINT256, false, '0x');
            (0, chai_1.expect)(actualOutput)
                .to.emit(await DAI.getAddress(), 'Transfer')
                .withArgs(await alice.getAddress(), await vault.getAddress(), SWAP_AMOUNT);
            (0, chai_1.expect)(actualOutput)
                .to.emit(await USDC.getAddress(), 'Transfer')
                .withArgs(await vault.getAddress(), await alice.getAddress(), queryOutput.amountsOut[0]);
        });
        it('should not require tokens in advance to querySwapExactOut using buffer', async () => {
            // Check that vault does not have tokenIn balance (DAI).
            const reservesBefore = await vault.getReservesOf(await DAI.getAddress());
            (0, chai_1.expect)(reservesBefore).to.be.eq(bufferInitAmount, 'DAI balance is wrong');
            const paths = [
                {
                    tokenIn: DAI,
                    steps: [
                        { pool: wDAI, tokenOut: wDAI, isBuffer: true },
                        { pool: pool, tokenOut: wUSDC, isBuffer: false },
                        { pool: wUSDC, tokenOut: USDC, isBuffer: true },
                    ],
                    exactAmountOut: SWAP_AMOUNT,
                    // max amount is twice the SWAP_AMOUNT.
                    maxAmountIn: (0, numbers_1.pct)(SWAP_AMOUNT, 2),
                },
            ];
            const queryOutput = await batchRouter.connect(zero).querySwapExactOut.staticCall(paths, zero.address, '0x');
            (0, chai_1.expect)(queryOutput.pathAmountsIn).to.have.length(1, 'Wrong query pathAmountsIn length');
            (0, chai_1.expect)(queryOutput.amountsIn).to.have.length(1, 'Wrong query amountsIn length');
            (0, chai_1.expect)(queryOutput.tokensIn).to.have.length(1, 'Wrong query tokensIn length');
            (0, chai_1.expect)(queryOutput.tokensIn[0]).to.be.equal(await DAI.getAddress(), 'Wrong query tokensIn value');
            // Connect Alice since the real transaction requires user to have tokens.
            const staticActualOutput = await batchRouter
                .connect(alice)
                .swapExactOut.staticCall(paths, constants_1.MAX_UINT256, false, '0x');
            (0, chai_1.expect)(staticActualOutput.pathAmountsIn).to.have.length(1, 'Wrong actual pathAmountsIn length');
            (0, chai_1.expect)(staticActualOutput.amountsIn).to.have.length(1, 'Wrong actual amountsIn length');
            (0, chai_1.expect)(staticActualOutput.tokensIn).to.have.length(1, 'Wrong actual tokensIn length');
            (0, chai_1.expect)(staticActualOutput.tokensIn[0]).to.be.equal(await DAI.getAddress(), 'Wrong actual tokensIn value');
            // Check if real transaction and query transaction are approx the same (tolerates an error when token is
            // wrapped/unwrapped and rate changes in the real operation).
            (0, chai_1.expect)(staticActualOutput.pathAmountsIn[0]).to.be.almostEqual(queryOutput.pathAmountsIn[0], 1e-10, 'Wrong actual pathAmountsIn value');
            (0, chai_1.expect)(staticActualOutput.amountsIn[0]).to.be.almostEqual(queryOutput.amountsIn[0], 1e-10, 'Wrong actual amountsIn value');
            // Connect Alice since the real transaction requires user to have tokens.
            const actualOutput = await batchRouter.connect(alice).swapExactOut(paths, constants_1.MAX_UINT256, false, '0x');
            (0, chai_1.expect)(actualOutput)
                .to.emit(await DAI.getAddress(), 'Transfer')
                .withArgs(await alice.getAddress(), await vault.getAddress(), queryOutput.amountsIn[0]);
            (0, chai_1.expect)(actualOutput)
                .to.emit(await USDC.getAddress(), 'Transfer')
                .withArgs(await vault.getAddress(), await alice.getAddress(), SWAP_AMOUNT);
        });
    });
});
