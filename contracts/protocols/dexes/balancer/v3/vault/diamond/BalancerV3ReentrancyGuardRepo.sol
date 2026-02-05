// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {StorageSlotExtension} from "@crane/contracts/external/balancer/v3/solidity-utils/contracts/openzeppelin/StorageSlotExtension.sol";

/* -------------------------------------------------------------------------- */
/*                        BalancerV3ReentrancyGuardRepo                       */
/* -------------------------------------------------------------------------- */

/**
 * @title BalancerV3ReentrancyGuardRepo
 * @notice Diamond-compatible reentrancy guard using transient storage.
 * @dev This library provides reentrancy protection matching Balancer's ReentrancyGuardTransient.
 *
 * Uses EIP-1153 transient storage (TLOAD/TSTORE) which:
 * - Is automatically cleared at the end of each transaction
 * - Is cheaper than persistent storage
 * - Requires post-Cancun EVM
 *
 * The slot is computed using the same algorithm as OpenZeppelin/Balancer:
 * keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.ReentrancyGuard")) - 1)) & ~bytes32(uint256(0xff))
 */
library BalancerV3ReentrancyGuardRepo {
    using StorageSlotExtension for *;

    /* ------ Constants ------ */

    /// @dev Transient storage slot for reentrancy guard flag.
    /// Matches OpenZeppelin's ReentrancyGuardTransient slot.
    bytes32 internal constant REENTRANCY_GUARD_SLOT =
        0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00;

    /* ------ Errors ------ */

    /// @notice Unauthorized reentrant call.
    error ReentrancyGuardReentrantCall();

    /* ------ Storage Struct (unused but required for pattern) ------ */

    struct Storage {
        // Placeholder - transient storage doesn't need persistent slot
        uint256 _placeholder;
    }

    /* ------ Reentrancy Guard Functions ------ */

    /**
     * @dev Called at the start of a nonReentrant function.
     * Reverts if already in a nonReentrant context.
     */
    function _nonReentrantBefore() internal {
        if (_reentrancyGuardEntered()) {
            revert ReentrancyGuardReentrantCall();
        }
        REENTRANCY_GUARD_SLOT.asBoolean().tstore(true);
    }

    /**
     * @dev Called at the end of a nonReentrant function.
     * Resets the reentrancy flag.
     */
    function _nonReentrantAfter() internal {
        REENTRANCY_GUARD_SLOT.asBoolean().tstore(false);
    }

    /**
     * @dev Returns true if currently in a nonReentrant function.
     * @return entered True if reentrancy guard is active.
     */
    function _reentrancyGuardEntered() internal view returns (bool entered) {
        return REENTRANCY_GUARD_SLOT.asBoolean().tload();
    }
}
