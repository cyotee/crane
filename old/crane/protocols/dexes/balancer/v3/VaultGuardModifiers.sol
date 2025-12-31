// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                Open Zeppelin                               */
/* -------------------------------------------------------------------------- */

import {Context} from "@openzeppelin/contracts/utils/Context.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {BalancerV3VaultAwareStorage} from "./utils/BalancerV3VaultAwareStorage.sol";

contract VaultGuardModifiers is Context, BalancerV3VaultAwareStorage {
    error OnlyVault();

    modifier onlyVault() {
        if (_msgSender() != address(_balV3Vault())) {
            revert OnlyVault();
        }
        _;
    }
}
