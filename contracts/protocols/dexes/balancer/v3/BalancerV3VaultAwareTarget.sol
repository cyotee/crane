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

import {IBalancerV3VaultAware} from "contracts/interfaces/IBalancerV3VaultAware.sol";
import { BalancerV3VaultAwareStorage } from "contracts/protocols/dexes/balancer/v3/utils/BalancerV3VaultAwareStorage.sol";

contract BalancerV3VaultAwareTarget is BalancerV3VaultAwareStorage, IBalancerV3VaultAware {

    function balV3Vault() external view returns (IVault) {
        return _balV3Vault();
    }

    function getVault() external view returns (IVault) {
        return _balV3Vault();
    }

    function getAuthorizer() external view returns (IAuthorizer) {
        return _balV3Vault().getAuthorizer();
    }
}