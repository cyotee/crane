// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IGreeter} from "@crane/contracts/test/stubs/greeter/IGreeter.sol";
import {GreeterLayout, GreeterRepo} from "@crane/contracts/test/stubs/greeter/GreeterRepo.sol";

contract GreeterTarget is IGreeter {
    function getMessage() public view virtual returns (string memory) {
        return GreeterRepo._getMessage();
    }

    function setMessage(string memory message) public virtual returns (bool) {
        GreeterLayout storage layoutStruct = GreeterRepo._layoutStruct();
        emit NewMessage(GreeterRepo._getMessage(layoutStruct), message);
        GreeterRepo._setMessage(layoutStruct, message);
        return true;
    }
}
