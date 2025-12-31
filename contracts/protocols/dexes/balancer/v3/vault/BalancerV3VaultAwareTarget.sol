// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                 Balancer V3                                */
/* -------------------------------------------------------------------------- */

import {IAuthorizer} from "@balancer-labs/v3-interfaces/contracts/vault/IAuthorizer.sol";
import {IVault} from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {IBalancerV3VaultAware} from "@crane/contracts/interfaces/IBalancerV3VaultAware.sol";
// import {
//     BalancerV3VaultAwareStorage
// } from "@crane/contracts/protocols/dexes/balancer/v3/utils/BalancerV3VaultAwareStorage.sol";
import {BalancerV3VaultAwareRepo} from "@crane/contracts/protocols/dexes/balancer/v3/vault/BalancerV3VaultAwareRepo.sol";

contract BalancerV3VaultAwareTarget is IBalancerV3VaultAware {
    function balV3Vault() external view returns (IVault) {
        return BalancerV3VaultAwareRepo._balancerV3Vault();
    }

    function getVault() external view returns (IVault) {
        return BalancerV3VaultAwareRepo._balancerV3Vault();
    }

    function getAuthorizer() external view returns (IAuthorizer) {
        return BalancerV3VaultAwareRepo._balancerV3Vault().getAuthorizer();
    }
}
