// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {BalancerV3VaultAwareRepo} from "@crane/contracts/protocols/dexes/balancer/v3/BalancerV3VaultAwareRepo.sol";

abstract contract BalancerV3VaultGuardModifiers {
    error NotBalancerV3Vault(address caller);

    modifier onlyBalancerV3Vault() {
        _onlyBalancerV3Vault();
        _;
    }

    function  _onlyBalancerV3Vault() internal view {
        if (msg.sender != address(BalancerV3VaultAwareRepo._balancerV3Vault())) {
            revert NotBalancerV3Vault(msg.sender);
        }
    }
}