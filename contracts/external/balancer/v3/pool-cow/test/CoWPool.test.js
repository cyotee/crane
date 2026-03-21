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
const tokenConfig_1 = require("@balancer-labs/v3-helpers/src/models/tokens/tokenConfig");
const actions_1 = require("@balancer-labs/v3-helpers/src/models/misc/actions");
const time_1 = require("@balancer-labs/v3-helpers/src/time");
const expectEvent = __importStar(require("@balancer-labs/v3-helpers/src/test/expectEvent"));
const sortingHelper_1 = require("@balancer-labs/v3-helpers/src/models/tokens/sortingHelper");
const Permit2Deployer_1 = require("@balancer-labs/v3-vault/test/Permit2Deployer");
describe('CoWPool', function () {
    const FACTORY_VERSION = 'CoW Pool Factory v1';
    const POOL_VERSION = 'CoW Pool v1';
    const ROUTER_VERSION = 'Router v11';
    const POOL_SWAP_FEE = (0, numbers_1.fp)(0.01);
    const TOKEN_AMOUNT = (0, numbers_1.fp)(100);
    const INITIAL_BALANCES = [TOKEN_AMOUNT, TOKEN_AMOUNT];
    const SWAP_AMOUNT = (0, numbers_1.fp)(20);
    const WEIGHTS = [(0, numbers_1.fp)(0.5), (0, numbers_1.fp)(0.5)];
    const COW_ROUTER_FEE_PERCENTAGE = (0, numbers_1.fp)(0.01); // 1% fee percentage on donations.
    const SWAP_FEE = (0, numbers_1.fp)(0.01);
    let permit2;
    let vault;
    let factory;
    let pool;
    let router;
    let cowRouter;
    let alice;
    let bob;
    let feeSweeper;
    let tokenA;
    let tokenB;
    let poolTokens;
    let tokenAAddress;
    let tokenBAddress;
    let tokenConfig;
    before('setup signers', async () => {
        [, alice, bob, feeSweeper] = await hardhat_1.ethers.getSigners();
    });
    (0, sharedBeforeEach_1.sharedBeforeEach)('deploy vault, router, tokens, and pool', async function () {
        vault = await TypesConverter_1.default.toIVaultMock(await VaultDeployer.deployMock());
        const WETH = await (0, contract_1.deploy)('v3-solidity-utils/WETHTestToken');
        permit2 = await (0, Permit2Deployer_1.deployPermit2)();
        router = await (0, contract_1.deploy)('v3-vault/Router', { args: [vault, WETH, permit2, ROUTER_VERSION] });
        cowRouter = await (0, contract_1.deploy)('CowRouter', { args: [vault, COW_ROUTER_FEE_PERCENTAGE, feeSweeper] });
        tokenA = await (0, contract_1.deploy)('v3-solidity-utils/ERC20TestToken', { args: ['Token A', 'TKNA', 18] });
        tokenB = await (0, contract_1.deploy)('v3-solidity-utils/ERC20TestToken', { args: ['Token B', 'TKNB', 6] });
        tokenAAddress = await tokenA.getAddress();
        tokenBAddress = await tokenB.getAddress();
    });
    (0, sharedBeforeEach_1.sharedBeforeEach)('create and initialize pool', async () => {
        factory = await (0, contract_1.deploy)('CowPoolFactory', {
            args: [await vault.getAddress(), time_1.MONTH * 12, FACTORY_VERSION, POOL_VERSION, await cowRouter.getAddress()],
        });
        poolTokens = (0, sortingHelper_1.sortAddresses)([tokenAAddress, tokenBAddress]);
        tokenConfig = (0, tokenConfig_1.buildTokenConfig)(poolTokens);
        const tx = await factory.create('Cow Pool Test', 'CPT', tokenConfig, WEIGHTS, { pauseManager: constants_1.ZERO_ADDRESS, swapFeeManager: constants_1.ZERO_ADDRESS, poolCreator: constants_1.ZERO_ADDRESS }, SWAP_FEE, constants_1.ZERO_BYTES32);
        const receipt = await tx.wait();
        const event = expectEvent.inReceipt(receipt, 'PoolCreated');
        pool = (await (0, contract_1.deployedAt)('CowPool', event.args.pool));
        await tokenA.mint(bob, TOKEN_AMOUNT + SWAP_AMOUNT);
        await tokenB.mint(bob, TOKEN_AMOUNT);
        await pool.connect(bob).approve(router, constants_1.MAX_UINT256);
        for (const token of [tokenA, tokenB]) {
            await token.connect(bob).approve(permit2, constants_1.MAX_UINT256);
            await permit2.connect(bob).approve(token, router, constants_1.MAX_UINT160, constants_1.MAX_UINT48);
        }
        await (0, chai_1.expect)(await router.connect(bob).initialize(pool, poolTokens, INITIAL_BALANCES, numbers_1.FP_ZERO, false, '0x'))
            .to.emit(vault, 'PoolInitialized')
            .withArgs(pool);
    });
    (0, sharedBeforeEach_1.sharedBeforeEach)('grant permission', async () => {
        const setPoolSwapFeeAction = await (0, actions_1.actionId)(vault, 'setStaticSwapFeePercentage');
        const authorizerAddress = await vault.getAuthorizer();
        const authorizer = await (0, contract_1.deployedAt)('v3-vault/BasicAuthorizerMock', authorizerAddress);
        await authorizer.grantRole(setPoolSwapFeeAction, bob.address);
        await vault.connect(bob).setStaticSwapFeePercentage(pool, POOL_SWAP_FEE);
    });
    it('should have correct versions', async () => {
        (0, chai_1.expect)(await factory.version()).to.eq(FACTORY_VERSION);
        (0, chai_1.expect)(await factory.getPoolVersion()).to.eq(POOL_VERSION);
        (0, chai_1.expect)(await pool.version()).to.eq(POOL_VERSION);
    });
    it('pool and protocol fee preconditions', async () => {
        const poolConfig = await vault.getPoolConfig(pool);
        (0, chai_1.expect)(poolConfig.isPoolRegistered).to.be.true;
        (0, chai_1.expect)(poolConfig.isPoolInitialized).to.be.true;
        (0, chai_1.expect)(await vault.getStaticSwapFeePercentage(pool)).to.eq(POOL_SWAP_FEE);
    });
    it('has the correct pool tokens and balances', async () => {
        const tokensFromPool = await pool.getTokens();
        (0, chai_1.expect)(tokensFromPool).to.deep.equal(poolTokens);
        const [tokensFromVault, , balancesFromVault] = await vault.getPoolTokenInfo(pool);
        (0, chai_1.expect)(tokensFromVault).to.deep.equal(tokensFromPool);
        (0, chai_1.expect)(balancesFromVault).to.deep.equal(INITIAL_BALANCES);
    });
    it('cannot be initialized twice', async () => {
        await (0, chai_1.expect)(router.connect(alice).initialize(pool, poolTokens, INITIAL_BALANCES, numbers_1.FP_ZERO, false, '0x'))
            .to.be.revertedWithCustomError(vault, 'PoolAlreadyInitialized')
            .withArgs(await pool.getAddress());
    });
    it('is registered in the factory', async () => {
        (0, chai_1.expect)(await factory.getPoolCount()).to.be.eq(1);
        (0, chai_1.expect)(await factory.getPools()).to.be.deep.eq([await pool.getAddress()]);
    });
    describe('LM flags', () => {
        let newPool;
        // Cow Pool should always allow donations and disable unbalanced liquidity operations, so it's not a parameter of
        // the create function, like other pool types.
        (0, sharedBeforeEach_1.sharedBeforeEach)('create new pool with donation and disabled unbalanced liquidity', async () => {
            const tx = await factory.create('CoWPool', 'Test', tokenConfig, WEIGHTS, { pauseManager: constants_1.ZERO_ADDRESS, swapFeeManager: constants_1.ZERO_ADDRESS, poolCreator: constants_1.ZERO_ADDRESS }, SWAP_FEE, constants_1.ONES_BYTES32);
            const receipt = await tx.wait();
            const event = expectEvent.inReceipt(receipt, 'PoolCreated');
            newPool = (await (0, contract_1.deployedAt)('CowPool', event.args.pool));
        });
        it('allows donation', async () => {
            const { liquidityManagement } = await vault.getPoolConfig(newPool);
            (0, chai_1.expect)(liquidityManagement.enableDonation).to.be.true;
        });
        it('does not allow unbalanced liquidity', async () => {
            const { liquidityManagement } = await vault.getPoolConfig(newPool);
            (0, chai_1.expect)(liquidityManagement.disableUnbalancedLiquidity).to.be.true;
        });
    });
});
