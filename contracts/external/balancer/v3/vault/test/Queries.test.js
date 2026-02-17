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
Object.defineProperty(exports, "__esModule", { value: true });
const hardhat_1 = require("hardhat");
const chai_1 = require("chai");
const contract_1 = require("@balancer-labs/v3-helpers/src/contract");
const constants_1 = require("@balancer-labs/v3-helpers/src/constants");
const ethers_1 = require("ethers");
const sharedBeforeEach_1 = require("@balancer-labs/v3-common/sharedBeforeEach");
const numbers_1 = require("@balancer-labs/v3-helpers/src/numbers");
const VaultDeployer = __importStar(require("@balancer-labs/v3-helpers/src/models/vault/VaultDeployer"));
const poolSetup_1 = require("./poolSetup");
const time_1 = require("@balancer-labs/v3-helpers/src/time");
const sortingHelper_1 = require("@balancer-labs/v3-helpers/src/models/tokens/sortingHelper");
const Permit2Deployer_1 = require("./Permit2Deployer");
describe('Queries', function () {
    const ROUTER_VERSION = 'Router v9';
    const DAI_AMOUNT_IN = (0, numbers_1.fp)(1000);
    const USDC_AMOUNT_IN = (0, numbers_1.fp)(1000);
    const BPT_AMOUNT = (0, numbers_1.fp)(2000);
    let permit2;
    let vault;
    let router;
    let factory;
    let pool;
    let DAI;
    let USDC;
    let WETH;
    let zero;
    let alice;
    before('setup signers', async () => {
        zero = new ethers_1.VoidSigner('0x0000000000000000000000000000000000000000', hardhat_1.ethers.provider);
        [, alice] = await hardhat_1.ethers.getSigners();
    });
    (0, sharedBeforeEach_1.sharedBeforeEach)('deploy vault, tokens, and pools', async function () {
        vault = await VaultDeployer.deploy();
        const vaultAddress = await vault.getAddress();
        WETH = await (0, contract_1.deploy)('v3-solidity-utils/WETHTestToken');
        permit2 = await (0, Permit2Deployer_1.deployPermit2)();
        router = await (0, contract_1.deploy)('Router', { args: [vaultAddress, WETH, permit2, ROUTER_VERSION] });
        DAI = await (0, contract_1.deploy)('v3-solidity-utils/ERC20TestToken', { args: ['DAI', 'Token A', 18] });
        USDC = await (0, contract_1.deploy)('v3-solidity-utils/ERC20TestToken', { args: ['USDC', 'USDC', 18] });
        const tokenAddresses = (0, sortingHelper_1.sortAddresses)([await DAI.getAddress(), await USDC.getAddress()]);
        pool = await (0, contract_1.deploy)('v3-vault/PoolMock', {
            args: [vaultAddress, 'Pool', 'POOL'],
        });
        factory = await (0, contract_1.deploy)('PoolFactoryMock', { args: [vaultAddress, 12 * time_1.MONTH] });
        await factory.registerTestPool(pool, (0, poolSetup_1.buildTokenConfig)([await DAI.getAddress(), await USDC.getAddress()].sort()));
        await USDC.mint(alice, 2n * USDC_AMOUNT_IN);
        await DAI.mint(alice, 2n * DAI_AMOUNT_IN);
        await pool.connect(alice).approve(router, constants_1.MAX_UINT256);
        for (const token of [USDC, DAI]) {
            await token.connect(alice).approve(permit2, constants_1.MAX_UINT256);
            await permit2.connect(alice).approve(token, router, constants_1.MAX_UINT160, constants_1.MAX_UINT48);
        }
        // The mock pool can be initialized with no liquidity; it mints some BPT to the initializer
        // to comply with the Vault's required minimum.
        // Also need to sort the amounts, or initialization would break if we made DAI_AMOUNT_IN != USDC_AMOUNT_IN.
        const tokenAmounts = tokenAddresses[0] == (await DAI.getAddress())
            ? [2n * DAI_AMOUNT_IN, 2n * USDC_AMOUNT_IN]
            : [2n * USDC_AMOUNT_IN, 2n * DAI_AMOUNT_IN];
        await router.connect(alice).initialize(pool, tokenAddresses, tokenAmounts, 0, false, '0x');
    });
    // TODO: query a pool that has an actual invariant (introduced in #145).
    describe('swap', () => {
        const DAI_AMOUNT_OUT = (0, numbers_1.fp)(250);
        it('queries a swap exact in correctly', async () => {
            const amountCalculated = await router
                .connect(zero)
                .querySwapSingleTokenExactIn.staticCall(pool, USDC, DAI, USDC_AMOUNT_IN, zero.address, '0x');
            (0, chai_1.expect)(amountCalculated).to.be.eq(DAI_AMOUNT_IN);
        });
        it('queries a swap exact out correctly', async () => {
            const amountCalculated = await router
                .connect(zero)
                .querySwapSingleTokenExactOut.staticCall(pool, USDC, DAI, DAI_AMOUNT_OUT, zero.address, '0x');
            (0, chai_1.expect)(amountCalculated).to.be.eq(DAI_AMOUNT_OUT);
        });
        it('reverts if not a static call (exact in)', async () => {
            await (0, chai_1.expect)(router.querySwapSingleTokenExactIn.staticCall(pool, USDC, DAI, USDC_AMOUNT_IN, zero.address, '0x')).to.be.revertedWithCustomError(vault, 'NotStaticCall');
        });
        it('reverts if not a static call (exact out)', async () => {
            await (0, chai_1.expect)(router.querySwapSingleTokenExactOut.staticCall(pool, USDC, DAI, DAI_AMOUNT_OUT, zero.address, '0x')).to.be.revertedWithCustomError(vault, 'NotStaticCall');
        });
    });
    describe('addLiquidityProportional', () => {
        it('queries addLiquidityProportional correctly', async () => {
            const amountsIn = await router
                .connect(zero)
                .queryAddLiquidityProportional.staticCall(pool, BPT_AMOUNT, zero.address, '0x');
            (0, chai_1.expect)(amountsIn).to.be.deep.eq([DAI_AMOUNT_IN, USDC_AMOUNT_IN]);
        });
        it('reverts if not a static call', async () => {
            await (0, chai_1.expect)(router.queryAddLiquidityProportional.staticCall(pool, BPT_AMOUNT, zero.address, '0x')).to.be.revertedWithCustomError(vault, 'NotStaticCall');
        });
    });
    describe('addLiquidityUnbalanced', () => {
        it('queries addLiquidityUnbalanced correctly', async () => {
            const bptAmountOut = await router
                .connect(zero)
                .queryAddLiquidityUnbalanced.staticCall(pool, [DAI_AMOUNT_IN, USDC_AMOUNT_IN], zero.address, '0x');
            (0, chai_1.expect)(bptAmountOut).to.be.eq(BPT_AMOUNT - 2n); // addLiquidity unbalanced has rounding error favoring the Vault.
        });
        it('reverts if not a static call', async () => {
            await (0, chai_1.expect)(router.queryAddLiquidityUnbalanced.staticCall(pool, [DAI_AMOUNT_IN, USDC_AMOUNT_IN], zero.address, '0x')).to.be.revertedWithCustomError(vault, 'NotStaticCall');
        });
    });
    describe('addLiquiditySingleTokenExactOut', () => {
        it('queries addLiquiditySingleTokenExactOut correctly', async () => {
            const amountsIn = await router
                .connect(zero)
                .queryAddLiquiditySingleTokenExactOut.staticCall(pool, DAI, DAI_AMOUNT_IN * 2n, zero.address, '0x');
            (0, chai_1.expect)(amountsIn).to.be.eq(DAI_AMOUNT_IN * 2n);
        });
        it('reverts if not a static call', async () => {
            await (0, chai_1.expect)(router.queryAddLiquiditySingleTokenExactOut.staticCall(pool, DAI, DAI_AMOUNT_IN * 2n, zero.address, '0x')).to.be.revertedWithCustomError(vault, 'NotStaticCall');
        });
    });
    describe('addLiquidityCustom', () => {
        it('queries addLiquidityCustom correctly', async () => {
            const { amountsIn, bptAmountOut, returnData } = await router
                .connect(zero)
                .queryAddLiquidityCustom.staticCall(pool, [DAI_AMOUNT_IN, USDC_AMOUNT_IN], BPT_AMOUNT, zero.address, '0xbeef');
            (0, chai_1.expect)(amountsIn).to.be.deep.eq([DAI_AMOUNT_IN, USDC_AMOUNT_IN]);
            (0, chai_1.expect)(bptAmountOut).to.be.eq(BPT_AMOUNT);
            (0, chai_1.expect)(returnData).to.be.eq('0xbeef');
        });
        it('reverts if not a static call', async () => {
            await (0, chai_1.expect)(router.queryAddLiquidityCustom.staticCall(pool, [DAI_AMOUNT_IN, USDC_AMOUNT_IN], BPT_AMOUNT, zero.address, '0xbeef')).to.be.revertedWithCustomError(vault, 'NotStaticCall');
        });
    });
    describe('removeLiquidityProportional', () => {
        it('queries removeLiquidityProportional correctly', async () => {
            const amountsOut = await router
                .connect(zero)
                .queryRemoveLiquidityProportional.staticCall(pool, BPT_AMOUNT, zero.address, '0x');
            (0, chai_1.expect)(amountsOut[0]).to.be.eq(DAI_AMOUNT_IN);
            (0, chai_1.expect)(amountsOut[1]).to.be.eq(USDC_AMOUNT_IN);
        });
        it('reverts if not a static call', async () => {
            await (0, chai_1.expect)(router.queryRemoveLiquidityProportional.staticCall(pool, BPT_AMOUNT, zero.address, '0x')).to.be.revertedWithCustomError(vault, 'NotStaticCall');
        });
    });
    describe('removeLiquiditySingleTokenExactIn', () => {
        it('queries removeLiquiditySingleTokenExactIn correctly', async () => {
            const amountOut = await router
                .connect(zero)
                .queryRemoveLiquiditySingleTokenExactIn.staticCall(pool, BPT_AMOUNT, DAI, zero.address, '0x');
            (0, chai_1.expect)(amountOut).to.be.eq(DAI_AMOUNT_IN * 2n);
        });
        it('reverts if not a static call', async () => {
            await (0, chai_1.expect)(router.queryRemoveLiquiditySingleTokenExactIn.staticCall(pool, BPT_AMOUNT, DAI, zero.address, '0x')).to.be.revertedWithCustomError(vault, 'NotStaticCall');
        });
    });
    describe('removeLiquiditySingleTokenExactOut', () => {
        it('queries removeLiquiditySingleTokenExactOut correctly', async () => {
            const amountIn = await router
                .connect(zero)
                .queryRemoveLiquiditySingleTokenExactOut.staticCall(pool, DAI, DAI_AMOUNT_IN, zero.address, '0x');
            (0, chai_1.expect)(amountIn).to.be.eq(BPT_AMOUNT / 2n + 2n); // Has rounding error favoring the Vault.
        });
        it('reverts if not a static call', async () => {
            await (0, chai_1.expect)(router.queryRemoveLiquiditySingleTokenExactOut.staticCall(pool, DAI, DAI_AMOUNT_IN, zero.address, '0x')).to.be.revertedWithCustomError(vault, 'NotStaticCall');
        });
    });
    describe('removeLiquidityCustom', () => {
        it('queries removeLiquidityCustom correctly', async () => {
            const { bptAmountIn, amountsOut, returnData } = await router
                .connect(zero)
                .queryRemoveLiquidityCustom.staticCall(pool, BPT_AMOUNT, [DAI_AMOUNT_IN, USDC_AMOUNT_IN], zero.address, '0xbeef');
            (0, chai_1.expect)(bptAmountIn).to.be.eq(BPT_AMOUNT);
            (0, chai_1.expect)(amountsOut).to.be.deep.eq([DAI_AMOUNT_IN, USDC_AMOUNT_IN]);
            (0, chai_1.expect)(returnData).to.be.eq('0xbeef');
        });
        it('reverts if not a static call', async () => {
            await (0, chai_1.expect)(router.queryRemoveLiquidityCustom.staticCall(pool, BPT_AMOUNT, [DAI_AMOUNT_IN, USDC_AMOUNT_IN], zero.address, '0xbeef')).to.be.revertedWithCustomError(vault, 'NotStaticCall');
        });
    });
    describe('query and revert', () => {
        let router;
        (0, sharedBeforeEach_1.sharedBeforeEach)('deploy mock router', async () => {
            router = await (0, contract_1.deploy)('RouterMock', { args: [vault, WETH, permit2] });
        });
        describe('swap', () => {
            it('queries a swap exact in correctly', async () => {
                const amountCalculated = await router
                    .connect(zero)
                    .querySwapSingleTokenExactInAndRevert.staticCall(pool, USDC, DAI, USDC_AMOUNT_IN, '0x');
                (0, chai_1.expect)(amountCalculated).to.be.eq(DAI_AMOUNT_IN);
            });
            it('reverts if not a static call (exact in)', async () => {
                await (0, chai_1.expect)(router.querySwapSingleTokenExactInAndRevert.staticCall(pool, USDC, DAI, USDC_AMOUNT_IN, '0x')).to.be.revertedWithCustomError(vault, 'NotStaticCall');
            });
            it('handles query spoofs', async () => {
                await (0, chai_1.expect)(router.connect(zero).querySpoof.staticCall()).to.be.revertedWithCustomError(vault, 'QuoteResultSpoofed');
            });
            it('handles custom error codes', async () => {
                await (0, chai_1.expect)(router.connect(zero).queryRevertErrorCode.staticCall()).to.be.revertedWithCustomError(router, 'MockErrorCode');
            });
            it('handles legacy errors', async () => {
                await (0, chai_1.expect)(router.connect(zero).queryRevertLegacy.staticCall()).to.be.revertedWith('Legacy revert reason');
            });
            it('handles revert with no reason', async () => {
                await (0, chai_1.expect)(router.connect(zero).queryRevertNoReason.staticCall()).to.be.revertedWithCustomError(router, 'ErrorSelectorNotFound');
            });
            it('handles panic', async () => {
                await (0, chai_1.expect)(router.connect(zero).queryRevertPanic.staticCall()).to.be.revertedWithPanic();
            });
        });
    });
});
