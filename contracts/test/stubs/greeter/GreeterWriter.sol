// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IGreeter} from "contracts/test/stubs/greeter/IGreeter.sol";

contract GreeterWriter {
    function writeMessage(address greeter_, string memory message_) public {
        IGreeter(greeter_).setMessage(message_);
    }

    function writeMessages(address greeter_, string[] memory messages_) public {
        IGreeter(greeter_).setMessage(messages_[0]);
        for (uint256 i = 1; i < messages_.length; i++) {
            IGreeter(greeter_).setMessage(string.concat(messages_[i - 1], "/n", messages_[i]));
        }
    }
}
