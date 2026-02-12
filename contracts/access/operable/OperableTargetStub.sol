// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {OperableTarget} from "@crane/contracts/access/operable/OperableTarget.sol";
import {OperableModifiers} from "@crane/contracts/access/operable/OperableModifiers.sol";
import {MultiStepOwnableRepo} from "@crane/contracts/access/ERC8023/MultiStepOwnableRepo.sol";

/**
 * @title OperableTargetStub
 * @notice Test stub for OperableTarget that initializes ownership and has testable functions.
 * @dev Not intended for production use.
 */
contract OperableTargetStub is OperableTarget, OperableModifiers {
    uint256 public lastCalledValue;

    constructor(address initialOwner) {
        MultiStepOwnableRepo._initialize(initialOwner, 1 days);
    }

    function restrictedByOnlyOperator(uint256 value) external onlyOperator returns (uint256) {
        lastCalledValue = value;
        return value;
    }

    function restrictedByOnlyOwnerOrOperator(uint256 value) external onlyOwnerOrOperator returns (uint256) {
        lastCalledValue = value;
        return value;
    }

    function publicFunction(uint256 value) external returns (uint256) {
        lastCalledValue = value;
        return value;
    }

    function restrictedByOnlyOperatorSelector() external pure returns (bytes4) {
        return this.restrictedByOnlyOperator.selector;
    }
}
