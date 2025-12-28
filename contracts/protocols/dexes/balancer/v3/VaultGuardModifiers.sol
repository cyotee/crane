// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {BalancerV3VaultAwareRepo} from "@crane/contracts/protocols/dexes/balancer/v3/BalancerV3VaultAwareRepo.sol";

// abstract contract VaultGuardModifiers {
//     error OnlyVault();
//     /// @dev Reverts unless the caller is the Vault.
//     modifier onlyVault() {
//         _onlyVault();
//         _;
//     }

//     function _onlyVault() internal view {
//         if (msg.sender != address(BalancerV3VaultAwareRepo._balancerV3Vault())) {
//             revert OnlyVault();
//         }
//     }
// }