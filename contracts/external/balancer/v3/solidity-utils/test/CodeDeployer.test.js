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
const chai_1 = require("chai");
const hardhat_1 = require("hardhat");
const contract_1 = require("@balancer-labs/v3-helpers/src/contract");
const expectEvent = __importStar(require("@balancer-labs/v3-helpers/src/test/expectEvent"));
const sharedBeforeEach_1 = require("@balancer-labs/v3-common/sharedBeforeEach");
const typechain_types_1 = require("../typechain-types");
describe('CodeDeployer', function () {
    let factory;
    let admin;
    before('setup signers', async () => {
        [, admin] = await hardhat_1.ethers.getSigners();
    });
    (0, sharedBeforeEach_1.sharedBeforeEach)(async () => {
        factory = await (0, contract_1.deploy)('CodeDeployerMock', { args: [] });
    });
    context('with no code', () => {
        itStoresArgumentAsCode('0x');
    });
    context('with some code', () => {
        itStoresArgumentAsCode('0x1234');
    });
    context('with code 24kB long', () => {
        itStoresArgumentAsCode(`0x${'00'.repeat(24 * 1024)}`);
    });
    context('with code over 24kB long', () => {
        before(function () {
            // Skip this test during coverage - instrumentation interferes with size limits.
            if (process.env.COVERAGE) {
                this.skip();
            }
        });
        it('reverts', async () => {
            const data = `0x${'00'.repeat(24 * 1024 + 1)}`;
            await (0, chai_1.expect)(factory.deploy(data, false)).to.be.revertedWithCustomError({
                interface: typechain_types_1.CodeDeployer__factory.createInterface(),
            }, 'CodeDeploymentFailed');
        });
    });
    function itStoresArgumentAsCode(data) {
        it('stores its constructor argument as its code', async () => {
            const receipt = await (await factory.deploy(data, false)).wait();
            const event = expectEvent.inReceipt(receipt, 'CodeDeployed');
            (0, chai_1.expect)(await hardhat_1.ethers.provider.getCode(event.args.destination)).to.equal(data);
        });
    }
    describe('CodeDeployer protection', () => {
        let deployedContract;
        context('protected selfdestruct', () => {
            // INVALID
            // PUSH0
            // SELFDESTRUCT
            // STOP (optional - works without this)
            const code = '0x5fff00';
            const safeCode = '0xfe5fff00';
            (0, sharedBeforeEach_1.sharedBeforeEach)('deploy contract', async () => {
                // Pass it the unmodified code
                const receipt = await (await factory.deploy(code, true)).wait();
                const event = expectEvent.inReceipt(receipt, 'CodeDeployed');
                deployedContract = event.args.destination;
            });
            // It should actually store the safecode
            itStoresArgumentAsCode(safeCode);
            it('does not self destruct', async () => {
                const tx = {
                    to: deployedContract,
                    value: hardhat_1.ethers.parseEther('0.001'),
                };
                await (0, chai_1.expect)(admin.sendTransaction(tx)).to.be.reverted;
                // Should still have the safeCode
                (0, chai_1.expect)(await hardhat_1.ethers.provider.getCode(deployedContract)).to.equal(safeCode);
            });
        });
    });
});
