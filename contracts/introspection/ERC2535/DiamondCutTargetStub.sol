// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {DiamondCutTarget} from "@crane/contracts/introspection/ERC2535/DiamondCutTarget.sol";
import {DiamondLoupeTarget} from "@crane/contracts/introspection/ERC2535/DiamondLoupeTarget.sol";
import {MultiStepOwnableRepo} from "@crane/contracts/access/ERC8023/MultiStepOwnableRepo.sol";

/**
 * @title DiamondCutTargetStub
 * @notice Test stub for DiamondCutTarget that initializes ownership and exposes loupe functions.
 * @dev Not intended for production use.
 */
contract DiamondCutTargetStub is DiamondCutTarget, DiamondLoupeTarget {
    constructor(address initialOwner) {
        MultiStepOwnableRepo._initialize(initialOwner, 1 days);
    }
}
