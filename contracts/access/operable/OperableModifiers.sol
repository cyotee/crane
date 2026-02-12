// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {OperableRepo} from "@crane/contracts/access/operable/OperableRepo.sol";

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

    modifier onlyOwnerOrOperator() {
        OperableRepo._onlyOwnerOrOperator();
        _;
    }
}
