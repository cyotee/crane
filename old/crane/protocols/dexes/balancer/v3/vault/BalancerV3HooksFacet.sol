// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                 Balancer V3                                */
/* -------------------------------------------------------------------------- */

// import { IBasePool } from "@balancer-labs/v3-interfaces/contracts/vault/IBasePool.sol";
import {PoolSwapParams, Rounding, SwapKind} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";
import {IHooks} from "@balancer-labs/v3-interfaces/contracts/vault/IHooks.sol";
import {BaseHooks} from "@balancer-labs/v3-vault/contracts/BaseHooks.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {Create3AwareContract} from "contracts/crane/factories/create2/aware/Create3AwareContract.sol";
import {IFacet} from "contracts/crane/interfaces/IFacet.sol";
import {
    BetterBalancerV3PoolTokenStorage
} from "contracts/crane/protocols/dexes/balancer/v3/vault/utils/BetterBalancerV3PoolTokenStorage.sol";
import {IBalancerV3Pool} from "contracts/crane/interfaces/protocols/dexes/balancer/v3/IBalancerV3Pool.sol";
import {VaultGuardModifiers} from "contracts/crane/protocols/dexes/balancer/v3/VaultGuardModifiers.sol";

abstract contract BalancerV3HooksFacet is
    Create3AwareContract,
    BetterBalancerV3PoolTokenStorage,
    BaseHooks,
    VaultGuardModifiers,
    IFacet
{
    function facetInterfaces() public pure virtual returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](1);
        interfaces[0] = type(IHooks).interfaceId;
    }

    function facetFuncs() public pure virtual returns (bytes4[] memory funcs) {
        funcs = new bytes4[](11);
        funcs[0] = IHooks.onRegister.selector;
        funcs[1] = IHooks.getHookFlags.selector;
        funcs[2] = IHooks.onBeforeInitialize.selector;
        funcs[3] = IHooks.onAfterInitialize.selector;
        funcs[4] = IHooks.onBeforeAddLiquidity.selector;
        funcs[5] = IHooks.onAfterAddLiquidity.selector;
        funcs[6] = IHooks.onBeforeRemoveLiquidity.selector;
        funcs[7] = IHooks.onAfterRemoveLiquidity.selector;
        funcs[8] = IHooks.onBeforeSwap.selector;
        funcs[9] = IHooks.onAfterSwap.selector;
        funcs[10] = IHooks.onComputeDynamicSwapFeePercentage.selector;
    }
}
