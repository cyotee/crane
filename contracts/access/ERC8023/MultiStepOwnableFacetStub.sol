// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {MultiStepOwnableRepo} from "@crane/contracts/access/ERC8023/MultiStepOwnableRepo.sol";
import {MultiStepOwnableFacet} from "@crane/contracts/access/ERC8023/MultiStepOwnableFacet.sol";

contract MultiStepOwnableFacetStub is MultiStepOwnableFacet {
    constructor(address initialOwner, uint256 ownershipBufferPeriod) {
        MultiStepOwnableRepo._initialize(initialOwner, ownershipBufferPeriod);
    }
}
