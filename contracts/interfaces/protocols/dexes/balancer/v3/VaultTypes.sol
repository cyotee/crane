// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                 Balancer V3                                */
/* -------------------------------------------------------------------------- */

import {
    LiquidityManagement,
    PoolConfigBits,
    PoolConfig,
    HookFlags,
    HooksConfig,
    SwapState,
    VaultState,
    PoolRoleAccounts,
    TokenType,
    TokenConfig,
    TokenInfo,
    PoolData,
    Rounding,
    SwapKind,
    VaultSwapParams,
    PoolSwapParams,
    AfterSwapParams,
    AddLiquidityKind,
    AddLiquidityParams,
    RemoveLiquidityKind,
    RemoveLiquidityParams,
    WrappingDirection,
    BufferWrapOrUnwrapParams,
    FEE_BITLENGTH,
    FEE_SCALING_FACTOR,
    MAX_FEE_PERCENTAGE
} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";