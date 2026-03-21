"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const contract_1 = require("@balancer-labs/v3-helpers/src/contract");
const time_1 = require("@balancer-labs/v3-helpers/src/time");
const tokenConfig_1 = require("@balancer-labs/v3-helpers/src/models/tokens/tokenConfig");
const PoolBenchmark_behavior_1 = require("@balancer-labs/v3-benchmarks/src/PoolBenchmark.behavior");
const constants_1 = require("@balancer-labs/v3-helpers/src/constants");
class PoolMockBenchmark extends PoolBenchmark_behavior_1.Benchmark {
    constructor(dirname) {
        super(dirname, 'PoolMock');
    }
    async deployPool(tag, poolTokens, withRate) {
        const factory = (await (0, contract_1.deploy)('PoolFactoryMock', {
            args: [await this.vault.getAddress(), time_1.MONTH * 12],
        }));
        const pool = await (0, contract_1.deploy)('PoolMock', { args: [this.vault, 'Pool Mock', 'MOCK'] });
        const roleAccounts = {
            poolCreator: constants_1.ZERO_ADDRESS,
            pauseManager: constants_1.ZERO_ADDRESS,
            swapFeeManager: constants_1.ZERO_ADDRESS,
        };
        const liquidityManagement = {
            disableUnbalancedLiquidity: false,
            enableAddLiquidityCustom: false,
            enableRemoveLiquidityCustom: false,
            enableDonation: true,
        };
        await factory.registerPool(pool, (0, tokenConfig_1.buildTokenConfig)(poolTokens, withRate), roleAccounts, constants_1.ZERO_ADDRESS, liquidityManagement);
        return {
            pool: pool,
            poolTokens: poolTokens,
        };
    }
}
describe('PoolMock Gas Benchmark', function () {
    new PoolMockBenchmark(__dirname).itBenchmarks();
});
