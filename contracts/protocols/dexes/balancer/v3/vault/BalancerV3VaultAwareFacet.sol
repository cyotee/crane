// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {IBalancerV3VaultAware} from "@crane/contracts/interfaces/IBalancerV3VaultAware.sol";
import {BalancerV3VaultAwareTarget} from "@crane/contracts/protocols/dexes/balancer/v3/vault/BalancerV3VaultAwareTarget.sol";

contract BalancerV3VaultAwareFacet is BalancerV3VaultAwareTarget, IFacet {
    function facetName() public pure returns (string memory name) {
        return type(BalancerV3VaultAwareFacet).name;
    }

    function facetInterfaces() public pure returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](1);
        interfaces[0] = type(IBalancerV3VaultAware).interfaceId;
    }

    function facetFuncs() public pure virtual returns (bytes4[] memory funcs) {
        funcs = new bytes4[](3);
        funcs[0] = IBalancerV3VaultAware.balV3Vault.selector;
        funcs[1] = IBalancerV3VaultAware.getVault.selector;
        funcs[2] = IBalancerV3VaultAware.getAuthorizer.selector;
    }

    function facetMetadata()
        external
        pure
        returns (string memory name_, bytes4[] memory interfaces, bytes4[] memory functions)
    {
        name_ = facetName();
        interfaces = facetInterfaces();
        functions = facetFuncs();
    }
}
