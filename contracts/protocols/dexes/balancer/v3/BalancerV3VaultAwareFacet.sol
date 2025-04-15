// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {IFacet} from "../../../../interfaces/IFacet.sol";
import {IBalancerV3VaultAware} from "../../../../interfaces/IBalancerV3VaultAware.sol";
import {BalancerV3VaultAwareTarget} from "./BalancerV3VaultAwareTarget.sol";
import { Create3AwareContract } from "../../../../factories/create2/aware/Create3AwareContract.sol";

contract BalancerV3VaultAwareFacet is BalancerV3VaultAwareTarget, Create3AwareContract, IFacet {

    constructor(CREATE3InitData memory initData_)
    Create3AwareContract(initData_) {}

    function facetInterfaces() external pure returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](1);
        interfaces[0] = type(IBalancerV3VaultAware).interfaceId;
    }

    function facetFuncs()
    public pure virtual returns(bytes4[] memory funcs) {
        funcs = new bytes4[](3);
        funcs[0] = IBalancerV3VaultAware.balV3Vault.selector;
        funcs[1] = IBalancerV3VaultAware.getVault.selector;
        funcs[2] = IBalancerV3VaultAware.getAuthorizer.selector;
    }

}