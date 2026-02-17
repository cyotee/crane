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
const ethers_1 = require("ethers");
const chai_1 = require("chai");
const hardhat_1 = require("hardhat");
const expectEvent = __importStar(require("@balancer-labs/v3-helpers/src/test/expectEvent"));
const contract_1 = require("@balancer-labs/v3-helpers/src/contract");
const sharedBeforeEach_1 = require("@balancer-labs/v3-common/sharedBeforeEach");
const constants_1 = require("@balancer-labs/v3-helpers/src/constants");
const hardhat_network_helpers_1 = require("@nomicfoundation/hardhat-network-helpers");
describe('BasePoolCodeFactory', function () {
    let factory;
    let admin;
    const INVALID_ID = '0x0000000000000000000000000000000000000000000000000000000000000000';
    const id = '0x0123456789012345678901234567890123456789012345678901234567890123';
    before('setup signers', async () => {
        [, admin] = await hardhat_1.ethers.getSigners();
    });
    (0, sharedBeforeEach_1.sharedBeforeEach)(async () => {
        factory = await (0, contract_1.deploy)('MockSplitCodeFactory', { args: [] });
    });
    function itReproducesTheCreationCode() {
        it('returns the contract creation code storage addresses', async () => {
            const { contractA, contractB } = await factory.getCreationCodeContracts();
            const codeA = await hardhat_1.ethers.provider.getCode(contractA);
            const codeB = await hardhat_1.ethers.provider.getCode(contractB);
            const artifact = (0, contract_1.getArtifact)('MockFactoryCreatedContract');
            // Slice to remove the '0x' prefix and inserted invalid opcode on code B.
            (0, chai_1.expect)(codeA.concat(codeB.slice(4))).to.equal(artifact.bytecode);
            // Code B should have a pre-pending invalid opcode.
            (0, chai_1.expect)(codeB.slice(0, 4)).to.eq('0xfe');
        });
    }
    itReproducesTheCreationCode();
    it('returns the contract creation code', async () => {
        const artifact = (0, contract_1.getArtifact)('MockFactoryCreatedContract');
        const poolCreationCode = await factory.getCreationCode();
        (0, chai_1.expect)(poolCreationCode).to.equal(artifact.bytecode);
    });
    it('creates a contract', async () => {
        const receipt = await (await factory.create(id, constants_1.ZERO_BYTES32)).wait();
        expectEvent.inReceipt(receipt, 'ContractCreated');
    });
    context('half contracts', () => {
        it('cannot execute the contract halves', async () => {
            const { contractA, contractB } = await factory.getCreationCodeContracts();
            const txA = {
                to: contractA,
                value: hardhat_1.ethers.parseEther('0.001'),
            };
            const txB = {
                to: contractB,
                value: hardhat_1.ethers.parseEther('0.001'),
            };
            await (0, chai_1.expect)(admin.sendTransaction(txA)).to.be.reverted;
            await (0, chai_1.expect)(admin.sendTransaction(txB)).to.be.reverted;
        });
        // And the code is still there after trying
        itReproducesTheCreationCode();
    });
    context('when the creation reverts', () => {
        it('reverts and bubbles up revert reasons', async () => {
            await (0, chai_1.expect)(factory.create(INVALID_ID, constants_1.ZERO_BYTES32)).to.be.revertedWith('NON_ZERO_ID');
        });
    });
    context('with a created pool', () => {
        let contract;
        (0, sharedBeforeEach_1.sharedBeforeEach)('create contract', async () => {
            const receipt = await (await factory.create(id, constants_1.ZERO_BYTES32)).wait();
            const event = expectEvent.inReceipt(receipt, 'ContractCreated');
            contract = event.args.destination;
        });
        it('deploys correct bytecode', async () => {
            const code = await hardhat_1.ethers.provider.getCode(contract);
            const artifact = (0, contract_1.getArtifact)('MockFactoryCreatedContract');
            (0, chai_1.expect)(code).to.equal(artifact.deployedBytecode);
        });
        it('cannot deploy twice with the same salt', async () => {
            await (0, chai_1.expect)(factory.create(id, constants_1.ZERO_BYTES32)).to.be.reverted;
        });
        it('can deploy with a different salt', async () => {
            await (0, chai_1.expect)(factory.create(id, constants_1.ONES_BYTES32)).to.not.be.reverted;
        });
        it('passes constructor arguments correctly', async () => {
            const contractObject = await (0, contract_1.deployedAt)('MockFactoryCreatedContract', contract);
            (0, chai_1.expect)(await contractObject.getId()).to.equal(id);
        });
        it('generates the same address with the same salt and a different nonce', async () => {
            // We need to deploy with a reference salt, then "rollback" to before this deployment,
            // so that the address no longer has code (which would cause deployment to revert).
            // Take a snapshot we can roll back to.
            const snapshot = await (0, hardhat_network_helpers_1.takeSnapshot)();
            // Deploy with the reference salt and record the address.
            let receipt = await (await factory.create(id, constants_1.ONES_BYTES32)).wait();
            let event = expectEvent.inReceipt(receipt, 'ContractCreated');
            const targetAddress = event.args.destination;
            // Roll back to before the deployment
            await snapshot.restore();
            // Deploy the same factory with random salts, to increase the nonce
            receipt = await (await factory.create(id, (0, ethers_1.randomBytes)(32))).wait();
            event = expectEvent.inReceipt(receipt, 'ContractCreated');
            (0, chai_1.expect)(event.args.destination).to.not.equal(targetAddress);
            receipt = await (await factory.create(id, (0, ethers_1.randomBytes)(32))).wait();
            event = expectEvent.inReceipt(receipt, 'ContractCreated');
            (0, chai_1.expect)(event.args.destination).to.not.equal(targetAddress);
            // Use the same salt again; it should generate the same address
            receipt = await (await factory.create(id, constants_1.ONES_BYTES32)).wait();
            event = expectEvent.inReceipt(receipt, 'ContractCreated');
            (0, chai_1.expect)(event.args.destination).to.equal(targetAddress);
        });
    });
});
