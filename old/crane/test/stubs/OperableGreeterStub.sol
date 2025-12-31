// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {OperableTarget} from "contracts/crane/access/operable/OperableTarget.sol";
import {OperableModifiers} from "contracts/crane/access/operable/OperableModifiers.sol";
import {GreeterTarget} from "contracts/crane/test/stubs/greeter/GreeterTarget.sol";

contract OperableGreeterStub is GreeterTarget, OperableTarget, OperableModifiers {
    constructor(string memory message_, address owner_) {
        _initGreeter(message_);
        _initOwner(owner_);
    }

    /**
     * @notice Protected function for testing function-level operator authorization
     * @param newMessage_ New message to set
     */
    function setMessage(string memory newMessage_) public virtual override onlyOwnerOrOperator returns (bool) {
        return super.setMessage(newMessage_);
    }

    /**
     * @notice Another protected function for testing cross-function authorization
     * @param newMessage_ New message to set
     */
    function updateMessage(string memory newMessage_) external onlyOperator returns (bool) {
        return super.setMessage(newMessage_);
    }
}
