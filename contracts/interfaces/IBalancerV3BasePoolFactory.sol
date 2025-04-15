// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;    

import { TokenConfig } from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";

interface IBalancerV3BasePoolFactory {

    function tokenConfigs(address pool) external view returns (TokenConfig[] memory);
    
}