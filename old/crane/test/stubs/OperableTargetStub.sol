// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {OperableTarget} from "contracts/crane/access/operable/OperableTarget.sol";

contract OperableTargetStub is OperableTarget {
    constructor(address owner_) {
        _initOwner(owner_);
    }
}
