"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const hardhat_1 = require("hardhat");
const chai_1 = require("chai");
const sharedBeforeEach_1 = require("@balancer-labs/v3-common/sharedBeforeEach");
const constants_1 = require("@balancer-labs/v3-helpers/src/constants");
const numbers_1 = require("@balancer-labs/v3-helpers/src/numbers");
const signers_1 = require("@balancer-labs/v3-helpers/src/signers");
const poolSetup_1 = require("./poolSetup");
require("@balancer-labs/v3-common/setupTests");
const time_1 = require("@balancer-labs/v3-helpers/src/time");
describe('BalancerPoolToken', function () {
    const PAUSE_WINDOW_DURATION = time_1.MONTH * 9;
    let vault;
    let poolA;
    let poolB;
    let user;
    let other;
    let relayer;
    let poolASigner;
    let poolAAddress;
    let poolBAddress;
    before('setup signers', async () => {
        [, user, other, relayer] = await hardhat_1.ethers.getSigners();
    });
    (0, sharedBeforeEach_1.sharedBeforeEach)('deploy vault, tokens, and pools', async function () {
        // eslint-disable-next-line @typescript-eslint/no-unused-vars
        const { vault: vaultMock, pools } = await (0, poolSetup_1.setupEnvironment)(PAUSE_WINDOW_DURATION);
        vault = vaultMock;
        poolA = pools[0]; // This pool is registered
        poolB = pools[1]; // This pool is unregistered
        poolAAddress = await poolA.getAddress();
        poolBAddress = await poolB.getAddress();
        (0, chai_1.expect)(await poolA.name()).to.equal('Pool A');
        (0, chai_1.expect)(await poolA.symbol()).to.equal('POOL-A');
        (0, chai_1.expect)(await poolA.decimals()).to.equal(18);
        (0, chai_1.expect)(await poolB.name()).to.equal('Pool B');
        (0, chai_1.expect)(await poolB.symbol()).to.equal('POOL-B');
        (0, chai_1.expect)(await poolB.decimals()).to.equal(18);
    });
    (0, sharedBeforeEach_1.sharedBeforeEach)('', async () => {
        // Simulate a call from the real Pool by "casting" it as a Signer,
        // so it can be used with `connect` like an EOA.
        poolASigner = await (0, signers_1.impersonate)(poolAAddress);
    });
    describe('minting', async () => {
        const bptAmount = (0, numbers_1.fp)(100);
        it('vault can mint BPT', async () => {
            await vault.mintERC20(poolAAddress, user.address, bptAmount);
            // balanceOf directly on pool token.
            (0, chai_1.expect)(await poolA.balanceOf(user.address)).to.equal(bptAmount);
            (0, chai_1.expect)(await poolB.balanceOf(user.address)).to.equal(0);
            // balanceOf indirectly, through the Vault.
            (0, chai_1.expect)(await vault.balanceOf(poolAAddress, user.address)).to.equal(bptAmount);
            (0, chai_1.expect)(await vault.balanceOf(poolBAddress, user.address)).to.equal(0);
            // User has the total supply (directly on pool token).
            (0, chai_1.expect)(await poolA.totalSupply()).to.equal(bptAmount);
            (0, chai_1.expect)(await poolB.totalSupply()).to.equal(0);
            // User has the total supply (indirectly, through the Vault).
            (0, chai_1.expect)(await vault.totalSupply(poolAAddress)).to.equal(bptAmount);
            (0, chai_1.expect)(await vault.totalSupply(poolBAddress)).to.equal(0);
        });
        it('minting ERC20 BPT emits a transfer event on the token', async () => {
            await (0, chai_1.expect)(await vault.mintERC20(poolAAddress, user.address, bptAmount))
                .to.emit(poolA, 'Transfer')
                .withArgs(constants_1.ZERO_ADDRESS, user.address, bptAmount);
        });
        it('cannot mint ERC20 BPT to zero address', async () => {
            await (0, chai_1.expect)(vault.mintERC20(poolBAddress, constants_1.ZERO_ADDRESS, bptAmount))
                .to.be.revertedWithCustomError(vault, 'ERC20InvalidReceiver')
                .withArgs(constants_1.ZERO_ADDRESS);
        });
    });
    describe('burning', async () => {
        const totalSupply = (0, numbers_1.fp)(100);
        const bptAmount = (0, numbers_1.fp)(32.5);
        (0, sharedBeforeEach_1.sharedBeforeEach)('Mint initial ERC20 BPT supply of pool A', async () => {
            await vault.mintERC20(poolAAddress, user.address, totalSupply);
        });
        it('vault can burn ERC20 BPT', async () => {
            await vault.burnERC20(poolAAddress, user.address, bptAmount);
            const remainingBalance = totalSupply - bptAmount;
            // balanceOf directly on pool token.
            (0, chai_1.expect)(await poolA.balanceOf(user.address)).to.equal(remainingBalance);
            // balanceOf indirectly, through the Vault.
            (0, chai_1.expect)(await vault.balanceOf(poolAAddress, user.address)).to.equal(remainingBalance);
            // User has the total supply (directly on pool token).
            (0, chai_1.expect)(await poolA.totalSupply()).to.equal(remainingBalance);
            // User has the total supply (indirectly, through the Vault).
            (0, chai_1.expect)(await vault.totalSupply(poolAAddress)).to.equal(remainingBalance);
        });
        it('burning ERC20 BPT emits a transfer event on the token', async () => {
            await (0, chai_1.expect)(await vault.burnERC20(poolAAddress, user.address, bptAmount))
                .to.emit(poolA, 'Transfer')
                .withArgs(user.address, constants_1.ZERO_ADDRESS, bptAmount);
        });
        it('cannot burn ERC20 BPT from the zero address', async () => {
            await (0, chai_1.expect)(vault.burnERC20(poolBAddress, constants_1.ZERO_ADDRESS, bptAmount))
                .to.be.revertedWithCustomError(vault, 'ERC20InvalidSender')
                .withArgs(constants_1.ZERO_ADDRESS);
        });
        it('cannot burn more than the ERC20 BPT balance', async () => {
            // User has zero balance of PoolB.
            await (0, chai_1.expect)(vault.burnERC20(poolBAddress, user.address, bptAmount))
                .to.be.revertedWithCustomError(vault, 'ERC20InsufficientBalance')
                .withArgs(user.address, 0, bptAmount);
        });
    });
    describe('transfer', () => {
        const totalSupply = (0, numbers_1.fp)(50);
        const bptAmount = (0, numbers_1.fp)(18);
        const remainingBalance = totalSupply - bptAmount;
        (0, sharedBeforeEach_1.sharedBeforeEach)('Mint initial ERC20 BPT supply of pool A', async () => {
            await vault.mintERC20(poolAAddress, user.address, totalSupply);
        });
        function itTransfersBPTCorrectly() {
            it('transfers BPT between users', async () => {
                (0, chai_1.expect)(await poolA.balanceOf(user.address)).to.equal(remainingBalance);
                (0, chai_1.expect)(await poolA.balanceOf(other.address)).to.equal(bptAmount);
                // Supply doesn't change.
                (0, chai_1.expect)(await poolA.totalSupply()).to.equal(totalSupply);
            });
            it('direct ERC20 BPT transfer emits a transfer event on the token', async () => {
                await (0, chai_1.expect)(await poolA.connect(user).transfer(other.address, bptAmount))
                    .to.emit(poolA, 'Transfer')
                    .withArgs(user.address, other.address, bptAmount);
            });
            it('indirect ERC20 BPT transfer emits a transfer event on the token', async () => {
                await (0, chai_1.expect)(await vault.connect(poolASigner).transfer(user.address, other.address, bptAmount))
                    .to.emit(poolA, 'Transfer')
                    .withArgs(user.address, other.address, bptAmount);
            });
        }
        it('transfers ERC20 BPT directly', async () => {
            await poolA.connect(user).transfer(other.address, bptAmount);
            itTransfersBPTCorrectly();
        });
        it('transfers ERC20 BPT through the Vault', async () => {
            await vault.connect(poolASigner).transfer(user.address, other.address, bptAmount);
            itTransfersBPTCorrectly();
        });
        it('cannot transfer ERC20 BPT from zero address', async () => {
            await (0, chai_1.expect)(vault.connect(poolASigner).transfer(constants_1.ZERO_ADDRESS, other.address, bptAmount))
                .to.be.revertedWithCustomError(vault, 'ERC20InvalidSender')
                .withArgs(constants_1.ZERO_ADDRESS);
        });
        it('cannot transfer ERC20 BPT to zero address', async () => {
            await (0, chai_1.expect)(vault.connect(poolASigner).transfer(user.address, constants_1.ZERO_ADDRESS, bptAmount))
                .to.be.revertedWithCustomError(vault, 'ERC20InvalidReceiver')
                .withArgs(constants_1.ZERO_ADDRESS);
        });
        it('cannot transfer more than balance', async () => {
            await (0, chai_1.expect)(vault.connect(poolASigner).transfer(user.address, other.address, totalSupply + 1n))
                .to.be.revertedWithCustomError(vault, 'ERC20InsufficientBalance')
                .withArgs(user.address, totalSupply, totalSupply + 1n);
        });
        it('cannot emit transfer event except through the Vault', async () => {
            await (0, chai_1.expect)(poolA.connect(user).emitTransfer(user.address, other.address, totalSupply))
                .to.be.revertedWithCustomError(poolA, 'SenderIsNotVault')
                .withArgs(user.address);
        });
        it('cannot emit approval event except through the Vault', async () => {
            await (0, chai_1.expect)(poolA.connect(user).emitApproval(user.address, other.address, totalSupply))
                .to.be.revertedWithCustomError(poolA, 'SenderIsNotVault')
                .withArgs(user.address);
        });
    });
    describe('allowance', () => {
        const bptAmount = (0, numbers_1.fp)(72);
        function itSetsApprovalsCorrectly() {
            it('sets approval', async () => {
                (0, chai_1.expect)(await poolA.allowance(user.address, relayer.address)).to.equal(bptAmount);
                (0, chai_1.expect)(await poolA.allowance(user.address, other.address)).to.equal(0);
                (0, chai_1.expect)(await vault.allowance(poolAAddress, user.address, relayer.address)).to.equal(bptAmount);
                (0, chai_1.expect)(await vault.allowance(poolAAddress, user.address, other.address)).to.equal(0);
            });
            it('direct ERC20 approval emits an event on the token', async () => {
                await (0, chai_1.expect)(await poolA.connect(user).approve(relayer.address, bptAmount))
                    .to.emit(poolA, 'Approval')
                    .withArgs(user.address, relayer.address, bptAmount);
            });
            it('indirect ERC20 approval emits an event on the token', async () => {
                await (0, chai_1.expect)(await vault.connect(poolASigner).approve(user, relayer, bptAmount))
                    .to.emit(poolA, 'Approval')
                    .withArgs(user.address, relayer.address, bptAmount);
            });
        }
        context('sets approval directly', async () => {
            (0, sharedBeforeEach_1.sharedBeforeEach)('set approval', async () => {
                await poolA.connect(user).approve(relayer.address, bptAmount);
            });
            itSetsApprovalsCorrectly();
        });
        context('sets approval through the Vault', async () => {
            (0, sharedBeforeEach_1.sharedBeforeEach)('set approval', async () => {
                await vault.connect(poolASigner).approve(user, relayer, bptAmount);
            });
            itSetsApprovalsCorrectly();
        });
        it('cannot approve to zero address', async () => {
            await (0, chai_1.expect)(vault.connect(poolASigner).approve(user, constants_1.ZERO_ADDRESS, bptAmount))
                .to.be.revertedWithCustomError(vault, 'ERC20InvalidSpender')
                .withArgs(constants_1.ZERO_ADDRESS);
        });
    });
    describe('transferFrom', () => {
        const totalSupply = (0, numbers_1.fp)(50);
        const bptAmount = (0, numbers_1.fp)(18);
        const remainingBalance = totalSupply - bptAmount;
        (0, sharedBeforeEach_1.sharedBeforeEach)('Mint initial ERC20 BPT supply of pool A, and approve transfer', async () => {
            await vault.mintERC20(poolAAddress, user.address, totalSupply);
            await poolA.connect(user).approve(relayer.address, bptAmount);
        });
        function itTransfersBPTCorrectly() {
            it('relayer can transfer ERC20 BPT', async () => {
                (0, chai_1.expect)(await poolA.balanceOf(user.address)).to.equal(remainingBalance);
                (0, chai_1.expect)(await poolA.balanceOf(relayer.address)).to.equal(bptAmount);
                // Supply doesn't change.
                (0, chai_1.expect)(await poolA.totalSupply()).to.equal(totalSupply);
            });
        }
        context('transfers ERC20 BPT directly', async () => {
            (0, sharedBeforeEach_1.sharedBeforeEach)('direct transferFrom', async () => {
                await poolA.connect(relayer).transferFrom(user.address, relayer.address, bptAmount);
            });
            itTransfersBPTCorrectly();
        });
        context('transfers ERC20 BPT through the Vault', async () => {
            (0, sharedBeforeEach_1.sharedBeforeEach)('indirect transferFrom', async () => {
                await vault.connect(poolASigner).transfer(user.address, relayer.address, bptAmount);
            });
            itTransfersBPTCorrectly();
        });
        it('direct transfer emits a transfer event on the token', async () => {
            await (0, chai_1.expect)(await poolA.connect(relayer).transferFrom(user.address, relayer.address, bptAmount))
                .to.emit(poolA, 'Transfer')
                .withArgs(user.address, relayer.address, bptAmount);
        });
        it('indirect transfer emits a transfer event on the ERC20 BPT token', async () => {
            await (0, chai_1.expect)(await vault.connect(poolASigner).transferFrom(relayer.address, user.address, relayer.address, bptAmount))
                .to.emit(poolA, 'Transfer')
                .withArgs(user.address, relayer.address, bptAmount);
        });
        it('cannot transfer ERC20 BPT to zero address', async () => {
            await (0, chai_1.expect)(vault.connect(poolASigner).transferFrom(relayer.address, user.address, constants_1.ZERO_ADDRESS, bptAmount))
                .to.be.revertedWithCustomError(vault, 'ERC20InvalidReceiver')
                .withArgs(constants_1.ZERO_ADDRESS);
        });
        it('cannot transfer more than ERC20 BPT balance', async () => {
            // Give infinite allowance.
            await poolA.connect(user).approve(relayer.address, constants_1.MAX_UINT256);
            await (0, chai_1.expect)(vault.connect(poolASigner).transferFrom(relayer.address, user.address, other.address, totalSupply + 1n))
                .to.be.revertedWithCustomError(vault, 'ERC20InsufficientBalance')
                .withArgs(user.address, totalSupply, totalSupply + 1n);
        });
        it('cannot transfer more than ERC20 BPT allowance', async () => {
            const allowance = await vault.connect(user).allowance(poolA, user, relayer);
            await (0, chai_1.expect)(vault.connect(poolASigner).transferFrom(relayer, user, other, allowance + 1n))
                .to.be.revertedWithCustomError(vault, 'ERC20InsufficientAllowance')
                .withArgs(relayer.address, bptAmount, allowance + 1n);
        });
    });
});
