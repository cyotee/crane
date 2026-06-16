// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {MultiStepOwnableRepo} from "@crane/contracts/access/ERC8023/MultiStepOwnableRepo.sol";

// tag::MultiStepOwnableModifiers[]
/**
 * @title MultiStepOwnableModifiers - Modifiers for MultiStepOwnable functionality.
 * @author cyotee doge <not_cyotee@proton.me>
 * @notice Provides `onlyOwner` and `onlyProposedOwner` modifiers to restrict access based on EIP-8023 owner and pending owner roles.
 * @dev Declared abstract to indicate this should be inherited, not deployed directly.
 *      Compiler will inline the modifiers used in the inheriting contract.
 *      Thin wrapper that delegates to MultiStepOwnableRepo guard functions (_onlyOwner, _onlyPendingOwner) per AGENTS.md Modifiers pattern (see OperableModifiers, ReentrancyLockModifiers).
 */
abstract contract MultiStepOwnableModifiers {
    // tag::onlyOwner[]
    /**
     * @notice Restricts function access to the current contract owner.
     * @dev Delegates directly to the guard in MultiStepOwnableRepo.
     */
    modifier onlyOwner() {
        MultiStepOwnableRepo._onlyOwner();
        _;
    }
    // end::onlyOwner[]

    // tag::onlyProposedOwner[]
    /**
     * @notice Restricts function access to the proposed new owner.
     * @dev Delegates directly to the guard in MultiStepOwnableRepo.
     */
    modifier onlyProposedOwner() {
        MultiStepOwnableRepo._onlyPendingOwner();
        _;
    }
    // end::onlyProposedOwner[]
}
// end::MultiStepOwnableModifiers[]
