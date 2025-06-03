// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {
    GreeterTarget
} from "./GreeterTarget.sol";

contract GreeterStub
is GreeterTarget
{

    constructor(
        string memory message
    ) {
        _initGreeter(message);
    }


}
