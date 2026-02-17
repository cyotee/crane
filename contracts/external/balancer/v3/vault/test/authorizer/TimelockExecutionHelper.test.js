"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const chai_1 = require("chai");
const hardhat_1 = require("hardhat");
const numbers_1 = require("@balancer-labs/v3-helpers/src/numbers");
const contract_1 = require("@balancer-labs/v3-helpers/src/contract");
const constants_1 = require("@balancer-labs/v3-helpers/src/constants");
const sharedBeforeEach_1 = require("@balancer-labs/v3-common/sharedBeforeEach");
describe('TimelockExecutionHelper', () => {
    let executionHelper, token;
    let authorizer, other;
    before('setup signers', async () => {
        [, authorizer, other] = await hardhat_1.ethers.getSigners();
    });
    (0, sharedBeforeEach_1.sharedBeforeEach)('deploy contracts', async () => {
        token = await (0, contract_1.deploy)('v3-solidity-utils/ERC20TestToken', { args: ['Token', 'TKN', 18] });
        executionHelper = await (0, contract_1.deploy)('TimelockExecutionHelper', { from: authorizer });
    });
    describe('execute', () => {
        context('when the sender is the authorizer', () => {
            it('forwards the given call', async () => {
                const previousAmount = await token.balanceOf(other.address);
                const mintAmount = (0, numbers_1.fp)(1);
                await executionHelper
                    .connect(authorizer)
                    .execute(token, token.interface.encodeFunctionData('mint', [other.address, mintAmount]));
                (0, chai_1.expect)(await token.balanceOf(other.address)).to.be.equal(previousAmount + mintAmount);
            });
            it('reverts if the call is reentrant', async () => {
                await (0, chai_1.expect)(executionHelper
                    .connect(authorizer)
                    .execute(executionHelper, executionHelper.interface.encodeFunctionData('execute', [constants_1.ZERO_ADDRESS, '0x']))).to.be.revertedWithCustomError(executionHelper, 'ReentrancyGuardReentrantCall');
            });
        });
        context('when the sender is not the authorizer', () => {
            it('reverts', async () => {
                await (0, chai_1.expect)(executionHelper.connect(other).execute(token, '0x')).to.be.revertedWith('SENDER_IS_NOT_AUTHORIZER');
            });
        });
    });
});
