"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const contract_1 = require("@balancer-labs/v3-helpers/src/contract");
const time_1 = require("@balancer-labs/v3-helpers/src/time");
const tokenConfig_1 = require("@balancer-labs/v3-helpers/src/models/tokens/tokenConfig");
const PoolBenchmark_behavior_1 = require("@balancer-labs/v3-benchmarks/src/PoolBenchmark.behavior");
const constants_1 = require("@balancer-labs/v3-helpers/src/constants");
class PoolMockWithHooksBenchmark extends PoolBenchmark_behavior_1.Benchmark {
    constructor(dirname) {
        super(dirname, 'PoolMockWithHooks');
    }
    async deployPool(tag, poolTokens, withRate) {
        const factory = (await (0, contract_1.deploy)('PoolFactoryMock', {
            args: [await this.vault.getAddress(), time_1.MONTH * 12],
        }));
        const hooks = (await (0, contract_1.deploy)('MinimalHooksPoolMock'));
        await hooks.setHookFlags({
            enableHookAdjustedAmounts: false,
            shouldCallBeforeInitialize: true,
            shouldCallAfterInitialize: true,
            shouldCallComputeDynamicSwapFee: true,
            shouldCallBeforeSwap: true,
            shouldCallAfterSwap: true,
            shouldCallBeforeAddLiquidity: true,
            shouldCallAfterAddLiquidity: true,
            shouldCallBeforeRemoveLiquidity: true,
            shouldCallAfterRemoveLiquidity: true,
        });
        const pool = await (0, contract_1.deploy)('PoolMock', { args: [this.vault, 'Pool Mock', 'MOCK'] });
        const roleAccounts = {
            poolCreator: constants_1.ZERO_ADDRESS,
            pauseManager: constants_1.ZERO_ADDRESS,
            swapFeeManager: constants_1.ZERO_ADDRESS,
        };
        const liquidityManagement = {
            disableUnbalancedLiquidity: false,
            enableAddLiquidityCustom: true,
            enableRemoveLiquidityCustom: true,
            enableDonation: true,
        };
        await factory.registerPool(pool, (0, tokenConfig_1.buildTokenConfig)(poolTokens, withRate), roleAccounts, hooks, liquidityManagement);
        return {
            pool: pool,
            poolTokens: poolTokens,
        };
    }
}
describe('PoolMock with Hooks Gas Benchmark', function () {
    new PoolMockWithHooksBenchmark(__dirname).itBenchmarks();
});
