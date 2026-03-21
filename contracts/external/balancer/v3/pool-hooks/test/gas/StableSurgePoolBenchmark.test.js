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
const contract_1 = require("@balancer-labs/v3-helpers/src/contract");
const numbers_1 = require("@balancer-labs/v3-helpers/src/numbers");
const constants_1 = require("@balancer-labs/v3-helpers/src/constants");
const time_1 = require("@balancer-labs/v3-helpers/src/time");
const expectEvent = __importStar(require("@balancer-labs/v3-helpers/src/test/expectEvent"));
const tokenConfig_1 = require("@balancer-labs/v3-helpers/src/models/tokens/tokenConfig");
const PoolBenchmark_behavior_1 = require("@balancer-labs/v3-benchmarks/src/PoolBenchmark.behavior");
class StableSurgePoolBenchmark extends PoolBenchmark_behavior_1.Benchmark {
    constructor(dirname) {
        super(dirname, 'StableSurgePool', {
            disableNestedPoolTests: true,
            disableUnbalancedLiquidityTests: true, // Reverts if the pool surges
        });
        this.AMPLIFICATION_PARAMETER = 200n;
    }
    async deployPool(tag, poolTokens, withRate) {
        const stableSurgeHook = (await (0, contract_1.deploy)('v3-pool-hooks/StableSurgeHook', {
            args: [await this.vault.getAddress(), (0, numbers_1.fp)(0.9), (0, numbers_1.fp)(0), ''],
        }));
        const factory = (await (0, contract_1.deploy)('v3-pool-hooks/StableSurgePoolFactory', {
            args: [await stableSurgeHook.getAddress(), time_1.MONTH * 12, '', ''],
        }));
        const poolRoleAccounts = {
            pauseManager: constants_1.ZERO_ADDRESS,
            swapFeeManager: constants_1.ZERO_ADDRESS,
            poolCreator: constants_1.ZERO_ADDRESS,
        };
        const enableDonation = true;
        const tx = await factory.create('StablePool', 'Test', (0, tokenConfig_1.buildTokenConfig)(poolTokens, withRate), this.AMPLIFICATION_PARAMETER, poolRoleAccounts, (0, numbers_1.fp)(0.1), enableDonation, constants_1.ZERO_BYTES32);
        const receipt = await tx.wait();
        const event = expectEvent.inReceipt(receipt, 'PoolCreated');
        const pool = (await (0, contract_1.deployedAt)('v3-pool-stable/StablePool', event.args.pool));
        return {
            pool: pool,
            poolTokens: poolTokens,
        };
    }
}
describe('StableSurgePool Gas Benchmark', function () {
    new StableSurgePoolBenchmark(__dirname).itBenchmarks();
});
