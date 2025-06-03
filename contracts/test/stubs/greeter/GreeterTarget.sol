// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {
    IGreeter
} from "./IGreeter.sol";
import {
    GreeterStorage
} from "./utils/GreeterStorage.sol";

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
    ) public virtual returns(bool) {
        emit NewMessage(_greeter().message, message);
        _greeter().message = message;
        return true;
    }

}
