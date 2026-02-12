// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {MultiStepOwnableRepo} from "@crane/contracts/access/ERC8023/MultiStepOwnableRepo.sol";

// tag::MultiStepOwnableModifiers[]
/**
 * @title MultiStepOwnableModifiers - Modifiers for MultiStepOwnable functionality.
 * @author cyotee doge <not_cyotee@proton.me>
 * @dev Declared abstract to indicate this should be inherited, not deployed directly.
 * @dev Compiler will inline on the modifiers used in the inheriting contract.
 */
abstract contract MultiStepOwnableModifiers {

    /**
     * @notice Restricts function access to the current contract owner.
     */
    modifier onlyOwner() {
        MultiStepOwnableRepo._onlyOwner();
        _;
    }

    /**
     * @notice Restricts function access to the proposed new owner.
     */
    modifier onlyProposedOwner() {
        MultiStepOwnableRepo._onlyPendingOwner();
        _;
    }
}
// end::MultiStepOwnableModifiers[]