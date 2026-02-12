// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {IBasePoolFactory} from "@crane/contracts/interfaces/protocols/dexes/balancer/v3/IBasePoolFactory.sol";
import {TokenConfig} from "@crane/contracts/interfaces/protocols/dexes/balancer/v3/VaultTypes.sol";

interface IBalancerV3BasePoolFactory is IBasePoolFactory {
    function tokenConfigs(address pool) external view returns (TokenConfig[] memory);
}
