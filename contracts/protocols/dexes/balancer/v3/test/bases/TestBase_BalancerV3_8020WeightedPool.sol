// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {

    // HookFlags,
    // FEE_SCALING_FACTOR,
    PoolRoleAccounts,

    // Rounding,
    TokenConfig,
    TokenType
} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/VaultTypes.sol";
import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IVault} from "@crane/contracts/interfaces/protocols/dexes/balancer/v3/IVault.sol";
import {IRateProvider} from "@crane/contracts/interfaces/protocols/dexes/balancer/v3/IRateProvider.sol";
import {BetterAddress} from "@crane/contracts/utils/BetterAddress.sol";
import {WeightedPool8020Factory} from "@crane/contracts/external/balancer/v3/pool-weighted/contracts/WeightedPool8020Factory.sol";
import {WeightedPool} from "@crane/contracts/external/balancer/v3/pool-weighted/contracts/WeightedPool.sol";
import {TestBase_BalancerV3Vault} from "@crane/contracts/protocols/dexes/balancer/v3/test/bases/TestBase_BalancerV3Vault.sol";
import {WeightedPoolContractsDeployer} from "@crane/contracts/protocols/dexes/balancer/v3/test/utils/WeightedPoolContractsDeployer.sol";

contract TestBase_BalancerV3_8020WeightedPool is TestBase_BalancerV3Vault, WeightedPoolContractsDeployer {

    uint256 private constant DEFAULT_SWAP_FEE = 1e16;

    WeightedPool8020Factory weighted8020Factory;

    address[] daiUsdc8020WeightedPoolTokens;
    uint256 daiIndexInDaiUsdc8020Pool;
    uint256 usdcIndexInDaiUsdc8020Pool;
    uint256[] daiUsdc8020WeightedPoolTokenAmounts;
    uint256 daiUsdc8020WeightedPoolBptAmountOut;
    WeightedPool daiUsdc8020WeightedPool;

    function setUp() public virtual override {
        TestBase_BalancerV3Vault.setUp();
        poolFactory = createPoolFactory();
        (pool, poolArguments) = createPool();
        if (pool != address(0)) {
            approveForPool(IERC20(pool));
        }
    }

    function createPoolFactory()
        internal
        virtual
        returns (
            address newPoolFactory
        )
    {
        weighted8020Factory =
            deployWeightedPool8020Factory(IVault(address(vault)), 365 days, "Factory v1", "8020Pool v1");
        return address(weighted8020Factory);
    }

    function createPool() internal virtual override returns (address newPool, bytes memory poolArgs) {
        (newPool, poolArgs) = createDaiUsdc8020WeightedPool();
        return (newPool, poolArgs);
    }

    function createDaiUsdc8020WeightedPool() internal virtual returns (address newPool, bytes memory poolArgs) {
        daiUsdc8020WeightedPoolTokens = new address[](2);
        daiUsdc8020WeightedPoolTokens[0] = address(dai);
        daiUsdc8020WeightedPoolTokens[1] = address(usdc);
        daiUsdc8020WeightedPoolTokens = BetterAddress._sort(daiUsdc8020WeightedPoolTokens);
        daiUsdc8020WeightedPoolTokenAmounts = new uint256[](2);
        for (uint256 i = 0; i < daiUsdc8020WeightedPoolTokens.length; i++) {
            if (daiUsdc8020WeightedPoolTokens[i] == address(dai)) {
                daiUsdc8020WeightedPoolTokenAmounts[i] = (800e18);
                daiIndexInDaiUsdc8020Pool = i;
            } else {
                daiUsdc8020WeightedPoolTokenAmounts[i] = (200e18);
                usdcIndexInDaiUsdc8020Pool = i;
            }
        }
        TokenConfig memory daiConfig = standardTokenConfig(dai);
        TokenConfig memory usdcConfig = standardTokenConfig(usdc);
        PoolRoleAccounts memory roleAccounts;
        daiUsdc8020WeightedPool = WeightedPool(
            weighted8020Factory.create(daiConfig, usdcConfig, roleAccounts, DEFAULT_SWAP_FEE)
        );
        _approveForAllUsers(IERC20(address(daiUsdc8020WeightedPool)));
        _approveSpenderForAllUsers(address(router), IERC20(address(daiUsdc8020WeightedPool)));
        _approveSpenderForAllUsers(address(vault), IERC20(address(daiUsdc8020WeightedPool)));
        // _approveSpenderForAllUsers(address(seBatchRouter), IERC20(address(daiUsdc8020WeightedPool)));
        // _approveSpenderForAllUsers(address(seStandardRouter), IERC20(address(daiUsdc8020WeightedPool)));
        newPool = address(daiUsdc8020WeightedPool);
        poolArgs = abi.encode(daiConfig, usdcConfig, roleAccounts, DEFAULT_SWAP_FEE);
    }

    function initPool() internal virtual override {
        // initDaiUsdc8020WeightedPool();
    }

    function initDaiUsdc8020WeightedPool() public returns (uint256 lpAmount) {
        // console.log("TestBase_BalancerV38020WeightedPoolMath.initDaiUsdc8020WeightedPool():: Entering function.");
        vm.startPrank(lp);
        mintPoolTokens(daiUsdc8020WeightedPoolTokens, daiUsdc8020WeightedPoolTokenAmounts);
        daiUsdc8020WeightedPoolBptAmountOut = _initPool(
            address(daiUsdc8020WeightedPool),
            daiUsdc8020WeightedPoolTokenAmounts,
            // Account for the precision loss
            // expectedAddLiquidityBptAmountOut - DELTA
            0
        );
        vm.stopPrank();
        lpAmount = daiUsdc8020WeightedPoolBptAmountOut;
        // console.log("TestBase_BalancerV38020WeightedPoolMath.initDaiUsdc8020WeightedPool():: Exiting function.");
    }

}