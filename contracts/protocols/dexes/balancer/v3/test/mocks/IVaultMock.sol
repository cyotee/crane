// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.24;

import {IERC20Errors} from "@crane/contracts/interfaces/IERC20Errors.sol";

import {IVaultExtensionMock} from "@crane/contracts/protocols/dexes/balancer/v3/test/mocks/interfaces/IVaultExtensionMock.sol";
import {IVaultStorageMock} from "@crane/contracts/protocols/dexes/balancer/v3/test/mocks/interfaces/IVaultStorageMock.sol";
import {IVaultAdminMock} from "@crane/contracts/protocols/dexes/balancer/v3/test/mocks/interfaces/IVaultAdminMock.sol";
import {IVaultMainMock} from "@crane/contracts/protocols/dexes/balancer/v3/test/mocks/interfaces/IVaultMainMock.sol";
import {IVault} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IVault.sol";

/// @dev One-fits-all solution for hardhat tests. Use the typechain type for errors, events and functions.
interface IVaultMock is IVault, IVaultMainMock, IVaultExtensionMock, IVaultAdminMock, IVaultStorageMock, IERC20Errors {
    // solhint-disable-previous-line no-empty-blocks
}
