// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {OperableTarget} from "@crane/contracts/access/operable/OperableTarget.sol";
import {OperableModifiers} from "@crane/contracts/access/operable/OperableModifiers.sol";
import {MultiStepOwnableRepo} from "@crane/contracts/access/ERC8023/MultiStepOwnableRepo.sol";

// tag::OperableTargetStub[]
/**
 * @title OperableTargetStub
 * @author cyotee doge <doge.cyotee>
 * @notice Test stub for OperableTarget that initializes ownership and has testable functions.
 * @dev Not intended for production use.
 */
contract OperableTargetStub is OperableTarget, OperableModifiers {
    // A public variable to track the last value passed to a restricted function for testing purposes.
    uint256 public lastCalledValue;

    /**
     * @param initialOwner The initial owner of the contract, set at deployment.
     */
    constructor(address initialOwner) {
        MultiStepOwnableRepo._initialize(initialOwner, 1 days);
    }

    // tag::restrictedByOnlyOperator(uint256)[]
    /**
     * @notice A function restricted by the onlyOperator modifier for testing operator permissions.
     * @param value A uint256 value to be stored in lastCalledValue for testing.
     * @return The input value, returned for testing purposes.
     */
    function restrictedByOnlyOperator(uint256 value) external onlyOperator returns (uint256) {
        lastCalledValue = value;
        return value;
    }

    // end::restrictedByOnlyOperator(uint256)[]

    // tag::restrictedByOnlyOwnerOrOperator(uint256)[]
    /**
     * @notice A function restricted by the onlyOwnerOrOperator modifier for testing owner or operator permissions.
     * @param value A uint256 value to be stored in lastCalledValue for testing.
     * @return The input value, returned for testing purposes.
     */
    function restrictedByOnlyOwnerOrOperator(uint256 value) external onlyOwnerOrOperator returns (uint256) {
        lastCalledValue = value;
        return value;
    }

    // end::restrictedByOnlyOwnerOrOperator(uint256)[]

    // tag::publicFunction(uint256)[]
    /**
     * @notice A public function with no access restrictions for testing purposes.
     * @param value A uint256 value to be stored in lastCalledValue for testing.
     * @return The input value, returned for testing purposes.
     */
    function publicFunction(uint256 value) external returns (uint256) {
        lastCalledValue = value;
        return value;
    }

    // end::publicFunction(uint256)[]

    // tag::restrictedByOnlyOperatorSelector()[]
    function restrictedByOnlyOperatorSelector() external pure returns (bytes4) {
        return this.restrictedByOnlyOperator.selector;
    }
    // end::restrictedByOnlyOperatorSelector()[]
}
// end::OperableTargetStub[]
