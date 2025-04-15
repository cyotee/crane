// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import { IGreeter } from "./IGreeter.sol";
import {
    GreeterStub
} from "./GreeterStub.sol";
import { ReentrancyLockModifiers } from "../../../access/reentrancy/ReentrancyLockModifiers.sol";
import { ReentrancyLockTarget } from "../../../access/reentrancy/ReentrancyLockTarget.sol";

contract NonReentrantGreeterStub is GreeterStub, ReentrancyLockModifiers, ReentrancyLockTarget {
    bool public shouldReenter;
    
    constructor(
        string memory message_
    ) GreeterStub(message_) {}

    function setMessage(string memory message) public override lock returns (bool) {
        // If reentrancy is enabled, attempt to call back into this contract
        if (shouldReenter) {
            shouldReenter = false; // Disable to prevent infinite recursion
            // This should fail due to the lock modifier blocking reentrancy
            this.setMessage("reentrant call");
        }
        return super.setMessage(message);
    }

    function enableReentrancy() external {
        shouldReenter = true;
    }
}
