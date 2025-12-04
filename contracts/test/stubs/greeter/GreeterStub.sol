// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {GreeterTarget} from "@crane/contracts/test/stubs/greeter/GreeterTarget.sol";
import {GreeterLayout, GreeterRepo} from "@crane/contracts/test/stubs/greeter/GreeterRepo.sol";

contract GreeterStub is GreeterTarget {
    constructor(string memory message) {
        GreeterRepo._setMessage(message);
    }
}
