// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.24;

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";

import {
    TokenConfig,
    PoolRoleAccounts,
    LiquidityManagement
} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/VaultTypes.sol";
import {IVaultAdmin} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IVaultAdmin.sol";
import {IVault} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IVault.sol";

import {PoolConfigLib, PoolConfigBits} from "@crane/contracts/external/balancer/v3/vault/contracts/lib/PoolConfigLib.sol";
import {VaultExtension} from "@crane/contracts/external/balancer/v3/vault/contracts/VaultExtension.sol";

import {IVaultExtensionMock} from "@crane/contracts/protocols/dexes/balancer/v3/test/mocks/interfaces/IVaultExtensionMock.sol";
import {BetterEfficientHashLib} from "@crane/contracts/utils/BetterEfficientHashLib.sol";

/// @notice Crane-local port of Balancer's VaultExtensionMock for testing purposes.
/// @dev This enables Crane to test without importing from upstream Balancer test contracts.
contract VaultExtensionMock is IVaultExtensionMock, VaultExtension {
    using PoolConfigLib for PoolConfigBits;
    using BetterEfficientHashLib for bytes;

    constructor(IVault vault, IVaultAdmin vaultAdmin) VaultExtension(vault, vaultAdmin) {}

    function mockExtensionHash(bytes calldata input) external payable returns (bytes32) {
        return input._hash();
    }

    function manualRegisterPoolReentrancy(
        address pool,
        TokenConfig[] memory tokenConfig,
        uint256 swapFeePercentage,
        uint32 pauseWindowEndTime,
        bool protocolFeeExempt,
        PoolRoleAccounts calldata roleAccounts,
        address poolHooksContract,
        LiquidityManagement calldata liquidityManagement
    ) external nonReentrant {
        IVault(address(this)).registerPool(
            pool,
            tokenConfig,
            swapFeePercentage,
            pauseWindowEndTime,
            protocolFeeExempt,
            roleAccounts,
            poolHooksContract,
            liquidityManagement
        );
    }

    function manualInitializePoolReentrancy(
        address pool,
        address to,
        IERC20[] memory tokens,
        uint256[] memory exactAmountsIn,
        uint256 minBptAmountOut,
        bytes memory userData
    ) external nonReentrant {
        IVault(address(this)).initialize(pool, to, tokens, exactAmountsIn, minBptAmountOut, userData);
    }
}
