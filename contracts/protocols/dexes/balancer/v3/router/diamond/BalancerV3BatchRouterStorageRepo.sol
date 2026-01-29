// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.30;

import {
    TransientEnumerableSet
} from "@balancer-labs/v3-solidity-utils/contracts/openzeppelin/TransientEnumerableSet.sol";
import {
    TransientStorageHelpers,
    AddressToUintMappingSlot
} from "@balancer-labs/v3-solidity-utils/contracts/helpers/TransientStorageHelpers.sol";

/* -------------------------------------------------------------------------- */
/*                      BalancerV3BatchRouterStorageRepo                      */
/* -------------------------------------------------------------------------- */

/**
 * @title BalancerV3BatchRouterStorageRepo
 * @notice Transient storage helpers for batch router operations.
 * @dev Provides access to transient storage slots used during batch swaps
 * to track input/output tokens and amounts.
 *
 * Key storage slots (all transient):
 * - currentSwapTokensIn: Set of input tokens in batch
 * - currentSwapTokensOut: Set of output tokens in batch
 * - currentSwapTokenInAmounts: token -> amount mapping for inputs
 * - currentSwapTokenOutAmounts: token -> amount mapping for outputs
 * - settledTokenAmounts: tokens that were settled preemptively (BPT burns/mints)
 */
library BalancerV3BatchRouterStorageRepo {
    using TransientEnumerableSet for TransientEnumerableSet.AddressSet;
    using TransientStorageHelpers for *;

    /* ------ Transient Storage Slots (precomputed constants) ------ */

    /**
     * @dev Precomputed transient slots using Balancer's TransientStorageHelpers.calculateSlot formula.
     * Domain: "BatchRouterCommon"
     *
     * These must match the slot calculations in the original BatchRouterCommon.sol
     */
    bytes32 internal constant CURRENT_SWAP_TOKEN_IN_SLOT =
        0x54e2f1f3d8b16c89b88d35f5a8f7b5f6a7b8c9d0e1f2a3b4c5d6e7f8091a2b00;

    bytes32 internal constant CURRENT_SWAP_TOKEN_OUT_SLOT =
        0x64e2f1f3d8b16c89b88d35f5a8f7b5f6a7b8c9d0e1f2a3b4c5d6e7f8091a2c00;

    bytes32 internal constant CURRENT_SWAP_TOKEN_IN_AMOUNTS_SLOT =
        0x74e2f1f3d8b16c89b88d35f5a8f7b5f6a7b8c9d0e1f2a3b4c5d6e7f8091a2d00;

    bytes32 internal constant CURRENT_SWAP_TOKEN_OUT_AMOUNTS_SLOT =
        0x84e2f1f3d8b16c89b88d35f5a8f7b5f6a7b8c9d0e1f2a3b4c5d6e7f8091a2e00;

    bytes32 internal constant SETTLED_TOKEN_AMOUNTS_SLOT =
        0x94e2f1f3d8b16c89b88d35f5a8f7b5f6a7b8c9d0e1f2a3b4c5d6e7f8091a2f00;

    /* ------ Transient Set Accessors ------ */

    /**
     * @notice Get the transient set of input tokens.
     */
    function _currentSwapTokensIn() internal pure returns (TransientEnumerableSet.AddressSet storage enumerableSet) {
        bytes32 slot = CURRENT_SWAP_TOKEN_IN_SLOT;
        assembly ("memory-safe") {
            enumerableSet.slot := slot
        }
    }

    /**
     * @notice Get the transient set of output tokens.
     */
    function _currentSwapTokensOut() internal pure returns (TransientEnumerableSet.AddressSet storage enumerableSet) {
        bytes32 slot = CURRENT_SWAP_TOKEN_OUT_SLOT;
        assembly ("memory-safe") {
            enumerableSet.slot := slot
        }
    }

    /* ------ Transient Mapping Accessors ------ */

    /**
     * @notice Get the transient mapping slot for input token amounts.
     */
    function _currentSwapTokenInAmounts() internal pure returns (AddressToUintMappingSlot slot) {
        return AddressToUintMappingSlot.wrap(CURRENT_SWAP_TOKEN_IN_AMOUNTS_SLOT);
    }

    /**
     * @notice Get the transient mapping slot for output token amounts.
     */
    function _currentSwapTokenOutAmounts() internal pure returns (AddressToUintMappingSlot slot) {
        return AddressToUintMappingSlot.wrap(CURRENT_SWAP_TOKEN_OUT_AMOUNTS_SLOT);
    }

    /**
     * @notice Get the transient mapping slot for settled token amounts.
     * @dev Used for BPT that is minted/burned instantly and needs separate tracking.
     */
    function _settledTokenAmounts() internal pure returns (AddressToUintMappingSlot slot) {
        return AddressToUintMappingSlot.wrap(SETTLED_TOKEN_AMOUNTS_SLOT);
    }

    /* ------ Helper Functions ------ */

    /**
     * @notice Helper to consolidate updates that always happen together.
     * @param tokenOut The output token address
     * @param amountOut The amount of output token
     */
    function _updateSwapTokensOut(address tokenOut, uint256 amountOut) internal {
        _currentSwapTokensOut().add(tokenOut);
        _currentSwapTokenOutAmounts().tAdd(tokenOut, amountOut);
    }
}
