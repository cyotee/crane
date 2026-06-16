// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {OperableRepo} from "@crane/contracts/access/operable/OperableRepo.sol";

// tag::OperableModifiers[]
/**
 * @title OperableModifiers - Modifiers for restricting access based on operator roles.
 * @author cyotee doge <not_cyotee@proton.me>
 * @notice Provides `onlyOperator` and `onlyOwnerOrOperator` modifiers to restrict access based on IOperable operator roles (global or function-specific) or owner-or-operator.
 * @dev Declared abstract to indicate this should be inherited, not deployed directly.
 *      Compiler will inline the modifiers used in the inheriting contract.
 *      Thin wrapper that delegates to OperableRepo guard functions (_onlyOperator, _onlyOwnerOrOperator) per AGENTS.md Modifiers pattern (see ReentrancyLockModifiers, MultiStepOwnableModifiers).
 */
abstract contract OperableModifiers {
    // tag::onlyOperator[]
    /**
     * @notice Reverts if msg.sender is NOT an operator (global or per-function via IOperable).
     * @dev Delegates directly to the guard in OperableRepo.
     */
    modifier onlyOperator() {
        OperableRepo._onlyOperator();
        _;
    }
    // end::onlyOperator[]

    // tag::onlyOwnerOrOperator[]
    /**
     * @notice Reverts if msg.sender is NOT the owner or an operator.
     * @dev Delegates directly to the guard in OperableRepo (owner check via MultiStepOwnableRepo).
     */
    modifier onlyOwnerOrOperator() {
        OperableRepo._onlyOwnerOrOperator();
        _;
    }
    // end::onlyOwnerOrOperator[]
}
// end::OperableModifiers[]
