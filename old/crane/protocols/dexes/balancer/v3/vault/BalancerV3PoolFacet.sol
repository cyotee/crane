// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                 Balancer V3                                */
/* -------------------------------------------------------------------------- */

// import { IBasePool } from "@balancer-labs/v3-interfaces/contracts/vault/IBasePool.sol";
import {PoolSwapParams, Rounding, SwapKind} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";

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

abstract contract BalancerV3PoolFacet is
    Create3AwareContract,
    BetterBalancerV3PoolTokenStorage,
    VaultGuardModifiers,
    IBalancerV3Pool,
    IFacet
{
    function facetInterfaces() public pure virtual returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](1);
        interfaces[0] = type(IBalancerV3Pool).interfaceId;
    }

    function facetFuncs() public pure virtual returns (bytes4[] memory funcs) {
        funcs = new bytes4[](3);
        funcs[0] = IBalancerV3Pool.onSwap.selector;
        funcs[1] = IBalancerV3Pool.computeInvariant.selector;
        funcs[2] = IBalancerV3Pool.computeBalance.selector;
    }

    function computeInvariant(uint256[] memory balancesLiveScaled18, Rounding rounding)
        public
        view
        virtual
        returns (uint256 invariant);

    function computeBalance(uint256[] memory balancesLiveScaled18, uint256 tokenInIndex, uint256 invariantRatio)
        public
        view
        virtual
        returns (uint256 newBalance);

    function onSwap(PoolSwapParams calldata params) public virtual returns (uint256 amountCalculatedScaled18);
}
