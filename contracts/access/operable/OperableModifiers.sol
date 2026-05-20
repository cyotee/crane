// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {OperableRepo} from "@crane/contracts/access/operable/OperableRepo.sol";

// tag::OperableModifiers[]
/**
 * @title OperableModifiers - Modifiers for to restrict access based on operator roles.
 * @author cyotee doge <not_cyotee@proton.me>
 */
abstract contract OperableModifiers {
    // tag::onlyOperator[]
    /**
     * @notice Reverts if msg.sender is NOT an operator.
     */
    modifier onlyOperator() {
        OperableRepo._onlyOperator();
        _;
    }
    // end::onlyOperator[]

    // tag::onlyOwnerOrOperator[]
    /**
     * @notice Reverts if msg.sender is NOT the owner or an operator.
     */
    modifier onlyOwnerOrOperator() {
        OperableRepo._onlyOwnerOrOperator();
        _;
    }
    // end::onlyOwnerOrOperator[]
}
// end::OperableModifiers[]
