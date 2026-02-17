"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const contract_1 = require("@balancer-labs/v3-helpers/src/contract");
const contract_size_1 = require("@balancer-labs/v3-helpers/src/contract-size");
describe('ContractSizes', function () {
    it('calculates and stores contract sizes', async () => {
        // List of contracts to monitor
        for (const contractName of [
            'Vault',
            'VaultExtension',
            'VaultAdmin',
            'Router',
            'BatchRouter',
            'CompositeLiquidityRouter',
            'BufferRouter',
        ]) {
            const artifact = (0, contract_1.getArtifact)(`v3-vault/${contractName}`);
            // Match calculations performed by `yarn hardhat size-contracts`
            // See https://github.com/ItsNickBarry/hardhat-contract-sizer/blob/master/tasks/size_contracts.js
            const deploySize = Buffer.from(artifact.deployedBytecode.replace(/__\$\w*\$__/g, '0'.repeat(40)).slice(2), 'hex').length;
            const initSize = Buffer.from(artifact.bytecode.replace(/__\$\w*\$__/g, '0'.repeat(40)).slice(2), 'hex').length;
            // Write output - both bytecode and initcode, with a "*" if it's over the limit.
            await (0, contract_size_1.saveSizeSnap)(__dirname, contractName, deploySize, initSize);
        }
    });
});
