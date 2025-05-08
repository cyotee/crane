// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import "../../OwnableTarget.sol";

contract OwnableTargetStub is OwnableTarget {

    constructor(
        address owner_
    ) {
        _initOwner(owner_);
    }

}