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
const tokenConfig_1 = require("@balancer-labs/v3-helpers/src/models/tokens/tokenConfig");
const Permit2Deployer_1 = require("@balancer-labs/v3-vault/test/Permit2Deployer");
describe('StablePool', () => {
    const FACTORY_VERSION = 'Stable Factory v1';
    const POOL_VERSION = 'Stable Pool v1';
    const ROUTER_VERSION = 'Router v9';
    const MAX_STABLE_TOKENS = 5;
    const TOKEN_AMOUNT = (0, numbers_1.fp)(1000);
    const MIN_SWAP_FEE = 1e12;
    let permit2;
    let vault;
    let router;
    let alice;
    let tokens;
    let factory;
    let pool;
    let poolTokens;
    before('setup signers', async () => {
        [, alice] = await hardhat_1.ethers.getSigners();
    });
    (0, sharedBeforeEach_1.sharedBeforeEach)('deploy vault, router, factory, and tokens', async function () {
        vault = await TypesConverter_1.default.toIVaultMock(await VaultDeployer.deployMock());
        const WETH = await (0, contract_1.deploy)('v3-solidity-utils/WETHTestToken');
        permit2 = await (0, Permit2Deployer_1.deployPermit2)();
        router = await (0, contract_1.deploy)('v3-vault/Router', { args: [vault, WETH, permit2, ROUTER_VERSION] });
        factory = await (0, contract_1.deploy)('StablePoolFactory', {
            args: [await vault.getAddress(), time_1.MONTH * 12, FACTORY_VERSION, POOL_VERSION],
        });
        tokens = await ERC20TokenList_1.default.create(MAX_STABLE_TOKENS, { sorted: true });
        poolTokens = await tokens.addresses;
        // mint and approve tokens
        for (const token of tokens.tokens) {
            await token.mint(alice, TOKEN_AMOUNT);
            await token.connect(alice).approve(permit2, constants_1.MAX_UINT256);
            await permit2.connect(alice).approve(token, router, constants_1.MAX_UINT160, constants_1.MAX_UINT48);
        }
    });
    for (let i = 2; i <= MAX_STABLE_TOKENS; i++) {
        itDeploysAStablePool(i);
    }
    async function deployPool(numTokens) {
        const tokenConfig = (0, tokenConfig_1.buildTokenConfig)(poolTokens.slice(0, numTokens));
        const tx = await factory.create('Stable Pool', `STABLE-${numTokens}`, tokenConfig, 200n, { pauseManager: constants_1.ZERO_ADDRESS, swapFeeManager: constants_1.ZERO_ADDRESS, poolCreator: constants_1.ZERO_ADDRESS }, MIN_SWAP_FEE, constants_1.ZERO_ADDRESS, false, // no donations
        false, // keep support to unbalanced add/remove liquidity
        TypesConverter_1.default.toBytes32((0, numbers_1.bn)(numTokens)));
        const receipt = await tx.wait();
        const event = expectEvent.inReceipt(receipt, 'PoolCreated');
        const poolAddress = event.args.pool;
        pool = await (0, contract_1.deployedAt)('StablePool', poolAddress);
        await pool.connect(alice).approve(router, constants_1.MAX_UINT256);
    }
    function itDeploysAStablePool(numTokens) {
        it(`${numTokens} token pool was deployed correctly`, async () => {
            await deployPool(numTokens);
            (0, chai_1.expect)(await pool.name()).to.equal('Stable Pool');
            (0, chai_1.expect)(await pool.symbol()).to.equal(`STABLE-${numTokens}`);
        });
        it('should have correct versions', async () => {
            (0, chai_1.expect)(await factory.version()).to.eq(FACTORY_VERSION);
            (0, chai_1.expect)(await factory.getPoolVersion()).to.eq(POOL_VERSION);
            await deployPool(numTokens);
            (0, chai_1.expect)(await pool.version()).to.eq(POOL_VERSION);
        });
        describe(`initialization with ${numTokens} tokens`, () => {
            let initialBalances;
            context('uninitialized', () => {
                it('is registered, but not initialized on deployment', async () => {
                    await deployPool(numTokens);
                    const poolConfig = await vault.getPoolConfig(pool);
                    (0, chai_1.expect)(poolConfig.isPoolRegistered).to.be.true;
                    (0, chai_1.expect)(poolConfig.isPoolInitialized).to.be.false;
                });
            });
            context('initialized', () => {
                (0, sharedBeforeEach_1.sharedBeforeEach)('initialize pool', async () => {
                    await deployPool(numTokens);
                    initialBalances = Array(numTokens).fill(TOKEN_AMOUNT);
                    (0, chai_1.expect)(await router
                        .connect(alice)
                        .initialize(pool, poolTokens.slice(0, numTokens), initialBalances, numbers_1.FP_ZERO, false, '0x'))
                        .to.emit(vault, 'PoolInitialized')
                        .withArgs(pool);
                });
                it('is registered and initialized', async () => {
                    const poolConfig = await vault.getPoolConfig(pool);
                    (0, chai_1.expect)(poolConfig.isPoolRegistered).to.be.true;
                    (0, chai_1.expect)(poolConfig.isPoolInitialized).to.be.true;
                    (0, chai_1.expect)(poolConfig.isPoolPaused).to.be.false;
                });
                it('has the correct pool tokens and balances', async () => {
                    const tokensFromPool = await pool.getTokens();
                    (0, chai_1.expect)(tokensFromPool).to.deep.equal(poolTokens.slice(0, numTokens));
                    const [tokensFromVault, , balancesFromVault] = await vault.getPoolTokenInfo(pool);
                    (0, chai_1.expect)(tokensFromVault).to.deep.equal(tokensFromPool);
                    (0, chai_1.expect)(balancesFromVault).to.deep.equal(initialBalances);
                });
                it('cannot be initialized twice', async () => {
                    await (0, chai_1.expect)(router.connect(alice).initialize(pool, poolTokens, initialBalances, numbers_1.FP_ZERO, false, '0x'))
                        .to.be.revertedWithCustomError(vault, 'PoolAlreadyInitialized')
                        .withArgs(await pool.getAddress());
                });
                it('is registered in the factory', async () => {
                    (0, chai_1.expect)(await factory.getPoolCount()).to.be.eq(1);
                    (0, chai_1.expect)(await factory.getPools()).to.be.deep.eq([await pool.getAddress()]);
                });
            });
        });
    }
});
