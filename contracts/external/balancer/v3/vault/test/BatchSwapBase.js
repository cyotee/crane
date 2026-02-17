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
exports.BatchSwapBaseTest = exports.WRAPPED_TOKEN_AMOUNT = void 0;
const hardhat_1 = require("hardhat");
const ethers_1 = require("ethers");
const chai_1 = require("chai");
const contract_1 = require("@balancer-labs/v3-helpers/src/contract");
const constants_1 = require("@balancer-labs/v3-helpers/src/constants");
const numbers_1 = require("@balancer-labs/v3-helpers/src/numbers");
const ERC20TokenList_1 = __importDefault(require("@balancer-labs/v3-helpers/src/models/tokens/ERC20TokenList"));
const typechain_types_1 = require("../typechain-types");
const VaultDeployer = __importStar(require("@balancer-labs/v3-helpers/src/models/vault/VaultDeployer"));
const poolSetup_1 = require("./poolSetup");
const time_1 = require("@balancer-labs/v3-helpers/src/time");
const sortingHelper_1 = require("@balancer-labs/v3-helpers/src/models/tokens/sortingHelper");
const Permit2Deployer_1 = require("./Permit2Deployer");
const typechain_types_2 = require("@balancer-labs/v3-solidity-utils/typechain-types");
const tokenBalance_1 = require("@balancer-labs/v3-helpers/src/test/tokenBalance");
const BATCH_ROUTER_VERSION = 'BatchRouter v9';
const AGGREGATOR_BATCH_ROUTER_VERSION = 'AggregatorBatchRouter v9';
const ROUTER_VERSION = 'Router v9';
const TOKEN_AMOUNT = (0, numbers_1.fp)(1e12);
exports.WRAPPED_TOKEN_AMOUNT = (0, numbers_1.fp)(1e6);
class BatchSwapBaseTest {
    constructor(isPrepaid) {
        // Setup config (can be overridden in tests)
        this.pathExactAmountIn = (0, numbers_1.fp)(1);
        this.pathExactAmountOut = (0, numbers_1.fp)(1);
        this.pathMinAmountOut = (0, numbers_1.fp)(1);
        this.pathMaxAmountIn = (0, numbers_1.fp)(1);
        this.roundingError = 2n;
        this.isPrepaid = isPrepaid;
    }
    async setUpSigners() {
        this.zero = new ethers_1.VoidSigner('0x0000000000000000000000000000000000000000', hardhat_1.ethers.provider);
        [, this.lp, this.sender] = await hardhat_1.ethers.getSigners();
    }
    async deployContracts() {
        const WETH = await (0, contract_1.deploy)('v3-solidity-utils/WETHTestToken');
        this.vault = await VaultDeployer.deploy();
        this.vaultAddress = await this.vault.getAddress();
        this.permit2 = await (0, Permit2Deployer_1.deployPermit2)();
        this.bufferRouter = await (0, contract_1.deploy)('v3-vault/BufferRouter', {
            args: [this.vaultAddress, await WETH, this.permit2, ROUTER_VERSION],
        });
        this.basicRouter = await (0, contract_1.deploy)('Router', {
            args: [this.vaultAddress, WETH, this.permit2, ROUTER_VERSION],
        });
        this.router = await (0, contract_1.deploy)('BatchRouter', {
            args: [this.vaultAddress, WETH, this.permit2, BATCH_ROUTER_VERSION],
        });
        this.aggregatorRouter = await (0, contract_1.deploy)('BatchRouter', {
            args: [this.vaultAddress, WETH, hardhat_1.ethers.ZeroAddress, AGGREGATOR_BATCH_ROUTER_VERSION],
        });
        this.factory = await (0, contract_1.deploy)('PoolFactoryMock', { args: [this.vaultAddress, 12 * time_1.MONTH] });
        this.tokens = await ERC20TokenList_1.default.create(3, { sorted: true });
        this.token0 = await this.tokens.get(0).getAddress();
        this.token1 = await this.tokens.get(1).getAddress();
        this.token2 = await this.tokens.get(2).getAddress();
        this.wToken0 = await (0, contract_1.deploy)('v3-solidity-utils/ERC4626TestToken', {
            args: [this.token0, 'Wrapped TK0', 'wTK0', 18],
        });
        this.wToken2 = await (0, contract_1.deploy)('v3-solidity-utils/ERC4626TestToken', {
            args: [this.token2, 'Wrapped TK2', 'wTK2', 18],
        });
        this.wToken0Address = await this.wToken0.getAddress();
        this.wToken2Address = await this.wToken2.getAddress();
        this.poolATokens = (0, sortingHelper_1.sortAddresses)([this.token0, this.token1]);
        this.poolBTokens = (0, sortingHelper_1.sortAddresses)([this.token1, this.token2]);
        this.poolCTokens = (0, sortingHelper_1.sortAddresses)([this.token0, this.token2]);
        this.poolWATokens = (0, sortingHelper_1.sortAddresses)([this.wToken0Address, this.token1]);
        this.poolWBTokens = (0, sortingHelper_1.sortAddresses)([this.token1, this.wToken2Address]);
        // Pool A has tokens 0 and 1.
        this.poolA = await (0, contract_1.deploy)('v3-vault/PoolMock', {
            args: [this.vaultAddress, 'Pool A', 'POOL-A'],
        });
        // Pool A has tokens 1 and 2.
        this.poolB = await (0, contract_1.deploy)('v3-vault/PoolMock', {
            args: [this.vaultAddress, 'Pool B', 'POOL-B'],
        });
        // Pool C has tokens 0 and 2.
        this.poolC = await (0, contract_1.deploy)('v3-vault/PoolMock', {
            args: [this.vaultAddress, 'Pool C', 'POOL-C'],
        });
        // Pool A has wrapped token 0 and token 1.
        this.poolWA = await (0, contract_1.deploy)('v3-vault/PoolMock', {
            args: [this.vaultAddress, 'Wrapped Token 0 - Pool A', 'WPOOL-A'],
        });
        // Pool B has wrapped token 2 and token 1.
        this.poolWB = await (0, contract_1.deploy)('v3-vault/PoolMock', {
            args: [this.vaultAddress, 'Wrapped Token 2 - Pool B', 'WPOOL-B'],
        });
        await this.factory.registerTestPool(this.poolA, (0, poolSetup_1.buildTokenConfig)(this.poolATokens));
        await this.factory.registerTestPool(this.poolB, (0, poolSetup_1.buildTokenConfig)(this.poolBTokens));
        await this.factory.registerTestPool(this.poolC, (0, poolSetup_1.buildTokenConfig)(this.poolCTokens));
        await this.factory.registerTestPool(this.poolWA, (0, poolSetup_1.buildTokenConfig)(this.poolWATokens));
        await this.factory.registerTestPool(this.poolWB, (0, poolSetup_1.buildTokenConfig)(this.poolWBTokens));
    }
    async setUpNestedPools() {
        this.poolABTokens = (0, sortingHelper_1.sortAddresses)([await this.poolA.getAddress(), await this.poolB.getAddress()]);
        this.poolAB = await (0, contract_1.deploy)('v3-vault/PoolMock', {
            args: [this.vaultAddress, 'Pool A-B', 'POOL-AB'],
        });
        this.poolACTokens = (0, sortingHelper_1.sortAddresses)([await this.poolA.getAddress(), await this.poolC.getAddress()]);
        this.poolAC = await (0, contract_1.deploy)('v3-vault/PoolMock', {
            args: [this.vaultAddress, 'Pool A-C', 'POOL-AC'],
        });
        this.poolBCTokens = (0, sortingHelper_1.sortAddresses)([await this.poolB.getAddress(), await this.poolC.getAddress()]);
        this.poolBC = await (0, contract_1.deploy)('v3-vault/PoolMock', {
            args: [this.vaultAddress, 'Pool B-C', 'POOL-BC'],
        });
        await this.factory.registerTestPool(this.poolAB, (0, poolSetup_1.buildTokenConfig)(this.poolABTokens));
        await this.factory.registerTestPool(this.poolAC, (0, poolSetup_1.buildTokenConfig)(this.poolACTokens));
        await this.factory.registerTestPool(this.poolBC, (0, poolSetup_1.buildTokenConfig)(this.poolBCTokens));
    }
    async setUpAllowances() {
        this.pools = [this.poolA, this.poolB, this.poolC, this.poolAB, this.poolAC, this.poolBC, this.poolWA, this.poolWB];
        for (const user of [this.lp, this.sender]) {
            await this.tokens.mint({ to: user, amount: TOKEN_AMOUNT });
            await this.tokens
                .get(0)
                .connect(this.lp)
                .mint(user, exports.WRAPPED_TOKEN_AMOUNT * 2n);
            await this.tokens.get(0).connect(user).approve(this.wToken0, exports.WRAPPED_TOKEN_AMOUNT);
            await this.wToken0.connect(user).deposit(exports.WRAPPED_TOKEN_AMOUNT, user);
            await this.tokens
                .get(2)
                .connect(user)
                .mint(user, exports.WRAPPED_TOKEN_AMOUNT * 2n);
            await this.tokens.get(2).connect(user).approve(this.wToken2, exports.WRAPPED_TOKEN_AMOUNT);
            await this.wToken2.connect(user).deposit(exports.WRAPPED_TOKEN_AMOUNT, user);
        }
        await this.tokens.push(typechain_types_2.ERC20TestToken__factory.connect(this.wToken0Address, this.sender));
        await this.tokens.push(typechain_types_2.ERC20TestToken__factory.connect(this.wToken2Address, this.sender));
        for (const pool of this.pools) {
            await pool.connect(this.lp).approve(this.router, constants_1.MAX_UINT256);
            await pool.connect(this.lp).approve(this.basicRouter, constants_1.MAX_UINT256);
        }
        for (const token of [...this.tokens.tokens, ...this.pools]) {
            for (const from of [this.lp, this.sender]) {
                await token.connect(from).approve(this.permit2, constants_1.MAX_UINT256);
                for (const to of [this.router, this.basicRouter, this.bufferRouter]) {
                    await this.permit2.connect(from).approve(token, to, constants_1.MAX_UINT160, constants_1.MAX_UINT48);
                }
            }
        }
        await this.bufferRouter.connect(this.lp).initializeBuffer(this.wToken0, exports.WRAPPED_TOKEN_AMOUNT, 0, 0);
        await this.bufferRouter.connect(this.lp).initializeBuffer(this.wToken2, exports.WRAPPED_TOKEN_AMOUNT, 0, 0);
    }
    async initPools() {
        await this.basicRouter
            .connect(this.lp)
            .initialize(this.poolA, this.poolATokens, Array(this.poolATokens.length).fill((0, numbers_1.fp)(10000)), 0, false, '0x');
        await this.basicRouter
            .connect(this.lp)
            .initialize(this.poolB, this.poolBTokens, Array(this.poolBTokens.length).fill((0, numbers_1.fp)(10000)), 0, false, '0x');
        await this.basicRouter
            .connect(this.lp)
            .initialize(this.poolC, this.poolCTokens, Array(this.poolCTokens.length).fill((0, numbers_1.fp)(10000)), 0, false, '0x');
        await this.basicRouter
            .connect(this.lp)
            .initialize(this.poolAB, this.poolABTokens, Array(this.poolABTokens.length).fill((0, numbers_1.fp)(1000)), 0, false, '0x');
        await this.basicRouter
            .connect(this.lp)
            .initialize(this.poolAC, this.poolACTokens, Array(this.poolACTokens.length).fill((0, numbers_1.fp)(1000)), 0, false, '0x');
        await this.basicRouter
            .connect(this.lp)
            .initialize(this.poolBC, this.poolBCTokens, Array(this.poolBCTokens.length).fill((0, numbers_1.fp)(1000)), 0, false, '0x');
        await this.basicRouter
            .connect(this.lp)
            .initialize(this.poolWA, this.poolWATokens, Array(this.poolWATokens.length).fill((0, numbers_1.fp)(10000)), 0, false, '0x');
        await this.basicRouter
            .connect(this.lp)
            .initialize(this.poolWB, this.poolWBTokens, Array(this.poolWBTokens.length).fill((0, numbers_1.fp)(10000)), 0, false, '0x');
        await this.poolA.connect(this.lp).transfer(this.sender, (0, numbers_1.fp)(100));
        await this.poolB.connect(this.lp).transfer(this.sender, (0, numbers_1.fp)(100));
        await this.poolC.connect(this.lp).transfer(this.sender, (0, numbers_1.fp)(100));
    }
    cleanVariables() {
        this.tokensIn = [];
        this.tokensOut = [];
        this.totalAmountIn = 0n;
        this.totalAmountOut = 0n;
        this.pathAmountsIn = [];
        this.pathAmountsOut = [];
        this.amountsIn = [];
        this.amountsOut = [];
        this.balanceChange = [];
        this.pathsExactIn = [];
        this.pathAmountsOut = [];
    }
    async doSwapExactIn() {
        return this._doSwapExactIn(false);
    }
    async doSwapExactInStatic() {
        return this._doSwapExactIn(true);
    }
    async _doSwapExactIn(isStatic, deadline = constants_1.MAX_UINT256) {
        if (this.isPrepaid) {
            return (isStatic
                ? this.aggregatorRouter.connect(this.sender).swapExactIn.staticCall
                : this.aggregatorRouter.connect(this.sender).swapExactIn)(this.pathsExactIn, deadline, false, '0x');
        }
        else {
            return (isStatic
                ? this.router.connect(this.sender).swapExactIn.staticCall
                : this.router.connect(this.sender).swapExactIn)(this.pathsExactIn, deadline, false, '0x');
        }
    }
    async runQueryExactIn() {
        if (this.isPrepaid) {
            return this.aggregatorRouter
                .connect(this.zero)
                .querySwapExactIn.staticCall(this.pathsExactIn, this.zero.address, '0x');
        }
        else {
            return this.router.connect(this.zero).querySwapExactIn.staticCall(this.pathsExactIn, this.zero.address, '0x');
        }
    }
    itCommonTests() {
        it('reverts doSwapExactIn if deadline is in the past', async () => {
            this.pathsExactIn = [];
            const block = await hardhat_1.ethers.provider.getBlock('latest');
            if (!block)
                throw new Error('Block not found');
            const deadline = BigInt(block.timestamp - 1);
            await (0, chai_1.expect)(this._doSwapExactIn(false, deadline)).to.be.revertedWithCustomError({
                interface: typechain_types_1.ISenderGuard__factory.createInterface(),
            }, 'SwapDeadline');
        });
        it('reverts doSwapExactOut if deadline is in the past', async () => {
            this.pathsExactOut = [];
            const block = await hardhat_1.ethers.provider.getBlock('latest');
            if (!block)
                throw new Error('Block not found');
            const deadline = BigInt(block.timestamp - 1);
            await (0, chai_1.expect)(this._doSwapExactOut(false, deadline)).to.be.revertedWithCustomError({
                interface: typechain_types_1.ISenderGuard__factory.createInterface(),
            }, 'SwapDeadline');
        });
        it('reverts doSwapExactIn if amount out < min amount out', async () => {
            this.pathsExactIn = [
                {
                    tokenIn: this.token0,
                    steps: [{ pool: this.poolA, tokenOut: this.token1, isBuffer: false }],
                    exactAmountIn: this.pathExactAmountIn,
                    minAmountOut: constants_1.MAX_UINT256,
                },
            ];
            if (this.isPrepaid) {
                await (await typechain_types_2.ERC20TestToken__factory.connect(this.token0, this.sender).transfer(this.vault, this.pathExactAmountIn)).wait();
            }
            await (0, chai_1.expect)(this._doSwapExactIn(false)).to.be.revertedWithCustomError({
                interface: typechain_types_1.IVaultErrors__factory.createInterface(),
            }, 'SwapLimit');
        });
        it('reverts doSwapExactOut if amount in > max amount in', async () => {
            this.pathsExactOut = [
                {
                    tokenIn: this.token0,
                    steps: [{ pool: this.poolA, tokenOut: this.token1, isBuffer: false }],
                    exactAmountOut: this.pathExactAmountOut,
                    maxAmountIn: 0n,
                },
            ];
            await (0, chai_1.expect)(this._doSwapExactOut(false)).to.be.revertedWithCustomError({
                interface: typechain_types_1.IVaultErrors__factory.createInterface(),
            }, 'SwapLimit');
        });
    }
    itTestsBatchSwapExactIn(singleTransferIn = true, singleTransferOut = true) {
        it('performs swap, transfers tokens', async () => {
            await (0, tokenBalance_1.expectBalanceChange)(this.doSwapExactIn.bind(this), this.tokens, this.balanceChange);
        });
        if (singleTransferIn) {
            it('performs single transfer for token in', async () => {
                await (0, chai_1.expect)(this.doSwapExactIn())
                    .to.emit(this.tokensIn[0], 'Transfer')
                    .withArgs(this.sender.address, this.vaultAddress, this.totalAmountIn);
            });
        }
        if (singleTransferOut) {
            it('performs single transfer for token out', async () => {
                // Some operations have rounding error, and event arguments are precise. So we get the result from
                // the query to check the event arguments.
                const { amountsOut } = await this.runQueryExactIn();
                await (0, chai_1.expect)(this.doSwapExactIn())
                    .to.emit(this.tokensOut[0], 'Transfer')
                    .withArgs(this.vaultAddress, this.sender.address, amountsOut[0]);
            });
        }
        it('returns path amounts out', async () => {
            const calculatedPathAmountsOut = (await this.doSwapExactInStatic()).pathAmountsOut;
            calculatedPathAmountsOut.map((pathAmountOut, i) => (0, chai_1.expect)(pathAmountOut).to.be.almostEqual(this.pathAmountsOut[i], 1e-8));
        });
        it('returns tokens out', async () => {
            const calculatedTokensOut = (await this.doSwapExactInStatic()).tokensOut;
            (0, chai_1.expect)(calculatedTokensOut).to.be.deep.eq(await Promise.all(this.tokensOut.map(async (tokenOut) => await tokenOut.getAddress())));
        });
        it('returns token amounts out', async () => {
            const calculatedAmountsOut = (await this.doSwapExactInStatic()).amountsOut;
            calculatedAmountsOut.map((amountOut, i) => (0, chai_1.expect)(amountOut).to.be.almostEqual(this.amountsOut[i], 1e-8));
        });
        it('returns same outputs as query', async () => {
            const realOutputs = await this.doSwapExactInStatic();
            const queryOutputs = await this.runQueryExactIn();
            (0, chai_1.expect)(realOutputs.pathAmountsOut).to.be.deep.eq(queryOutputs.pathAmountsOut);
            (0, chai_1.expect)(realOutputs.amountsOut).to.be.deep.eq(queryOutputs.amountsOut);
            (0, chai_1.expect)(realOutputs.tokensOut).to.be.deep.eq(queryOutputs.tokensOut);
        });
    }
    async doSwapExactOut() {
        return this._doSwapExactOut(false);
    }
    async doSwapExactOutStatic() {
        return this._doSwapExactOut(true);
    }
    async runQueryExactOut() {
        if (this.isPrepaid) {
            return this.aggregatorRouter
                .connect(this.zero)
                .querySwapExactOut.staticCall(this.pathsExactOut, this.zero.address, '0x');
        }
        else
            return this.router.connect(this.zero).querySwapExactOut.staticCall(this.pathsExactOut, this.zero.address, '0x');
    }
    async _doSwapExactOut(isStatic, deadline = constants_1.MAX_UINT256) {
        if (this.isPrepaid) {
            return (isStatic
                ? this.aggregatorRouter.connect(this.sender).swapExactOut.staticCall
                : this.aggregatorRouter.connect(this.sender).swapExactOut)(this.pathsExactOut, deadline, false, '0x');
        }
        else {
            return (isStatic
                ? this.router.connect(this.sender).swapExactOut.staticCall
                : this.router.connect(this.sender).swapExactOut)(this.pathsExactOut, deadline, false, '0x');
        }
    }
    itTestsBatchSwapExactOut(singleTransferIn = true, singleTransferOut = true) {
        it('performs swap, transfers tokens', async () => {
            await (0, tokenBalance_1.expectBalanceChange)(this.doSwapExactOut.bind(this), this.tokens, this.balanceChange);
        });
        if (singleTransferIn) {
            it('performs single transfer for token in', async () => {
                // Some operations have rounding error, and event arguments are precise. So we get the result from
                // the query to check the event arguments.
                const { amountsIn } = await this.runQueryExactOut();
                await (0, chai_1.expect)(this.doSwapExactOut())
                    .to.emit(this.tokensIn[0], 'Transfer')
                    .withArgs(this.sender.address, this.vaultAddress, amountsIn[0]);
            });
        }
        if (singleTransferOut) {
            it('performs single transfer for token out', async () => {
                await (0, chai_1.expect)(this.doSwapExactOut())
                    .to.emit(this.tokensOut[0], 'Transfer')
                    .withArgs(this.vaultAddress, this.sender.address, this.totalAmountOut);
            });
        }
        it('returns path amounts in', async () => {
            const calculatedPathAmountsIn = (await this.doSwapExactOutStatic()).pathAmountsIn;
            calculatedPathAmountsIn.map((pathAmountIn, i) => (0, chai_1.expect)(pathAmountIn).to.be.almostEqual(this.pathAmountsIn[i], 1e-8));
        });
        it('returns tokens in', async () => {
            const calculatedTokensIn = (await this.doSwapExactOutStatic()).tokensIn;
            (0, chai_1.expect)(calculatedTokensIn).to.be.deep.eq(await Promise.all(this.tokensIn.map(async (tokenIn) => await tokenIn.getAddress())));
        });
        it('returns token amounts in', async () => {
            const calculatedAmountsIn = (await this.doSwapExactOutStatic()).amountsIn;
            calculatedAmountsIn.map((amountIn, i) => (0, chai_1.expect)(amountIn).to.be.almostEqual(this.amountsIn[i], 1e-8));
        });
        it('returns same outputs as query', async () => {
            const realOutputs = await this.doSwapExactOutStatic();
            const queryOutputs = await this.runQueryExactOut();
            (0, chai_1.expect)(realOutputs.pathAmountsIn).to.be.deep.eq(queryOutputs.pathAmountsIn);
            (0, chai_1.expect)(realOutputs.amountsIn).to.be.deep.eq(queryOutputs.amountsIn);
            (0, chai_1.expect)(realOutputs.tokensIn).to.be.deep.eq(queryOutputs.tokensIn);
        });
    }
}
exports.BatchSwapBaseTest = BatchSwapBaseTest;
