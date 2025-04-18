// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {
    IGreeter
} from "../interfaces/IGreeter.sol";
import {
    GreeterStorage
} from "../storage/GreeterStorage.sol";

contract GreeterTarget
is
GreeterStorage
,IGreeter
{

    function getMessage()
    public view returns(string memory) {
        return _greeter().message;
    }

    function setMessage(
        string memory message
    ) public returns(bool) {
        emit NewMessage(_greeter().message, message);
        _greeter().message = message;
        return true;
    }

}
