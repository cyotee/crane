// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IVault} from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";

interface IBalancerV3VaultAware {
    function balV3Vault() external view returns (IVault);
}