// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {
    GreeterTarget
} from "../targets/GreeterTarget.sol";

contract GreeterStub
is GreeterTarget
{

    constructor(
        string memory message
    ) {
        _initGreeter(message);
    }


}
