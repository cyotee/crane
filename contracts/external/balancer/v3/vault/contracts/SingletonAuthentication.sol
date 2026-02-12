// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.24;

import {IAuthorizer} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IAuthorizer.sol";
import {IVault} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IVault.sol";

import {CommonAuthentication} from "./CommonAuthentication.sol";

/**
 * @notice Base contract suitable for Singleton contracts (e.g., pool factories) that have permissioned functions.
 * @dev Vendored from Balancer V3 Vault.
 */
abstract contract SingletonAuthentication is CommonAuthentication {
    constructor(IVault vault) CommonAuthentication(vault, bytes32(uint256(uint160(address(this))))) {
        // solhint-disable-previous-line no-empty-blocks
    }

    function getVault() public view virtual returns (IVault) {
        return _getVault();
    }

    function getAuthorizer() public view returns (IAuthorizer) {
        return getVault().getAuthorizer();
    }
}
