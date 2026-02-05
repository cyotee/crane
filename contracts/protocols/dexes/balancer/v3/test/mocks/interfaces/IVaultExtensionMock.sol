// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.24;

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";

import {LiquidityManagement, PoolRoleAccounts, TokenConfig} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/VaultTypes.sol";

interface IVaultExtensionMock {
    function manualRegisterPoolReentrancy(
        address pool,
        TokenConfig[] memory tokenConfig,
        uint256 swapFeePercentage,
        uint32 pauseWindowEndTime,
        bool protocolFeeExempt,
        PoolRoleAccounts calldata roleAccounts,
        address poolHooksContract,
        LiquidityManagement calldata liquidityManagement
    ) external;

    function manualInitializePoolReentrancy(
        address pool,
        address to,
        IERC20[] memory tokens,
        uint256[] memory exactAmountsIn,
        uint256 minBptAmountOut,
        bytes memory userData
    ) external;
}
