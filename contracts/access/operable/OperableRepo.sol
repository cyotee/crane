// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IOperable} from "@crane/contracts/interfaces/IOperable.sol";
import {MultiStepOwnableRepo} from "@crane/contracts/access/ERC8023/MultiStepOwnableRepo.sol";

// tag::OperableRepo[]
/**
 * @title OperableRepo - Library for managing operator roles and permissions.
 * @author cyotee doge <not_cyotee@proton.me>
 * @dev Storage library (Repo) implementing operator-based access control per IOperable.
 * @dev Provides dual (parameterized + default) functions for all accessors/mutators/guards.
 * @dev Typically used via OperableModifiers and OperableTarget/OperableFacet.
 */
library OperableRepo {
    // tag::STORAGE_SLOT[]
    /**
     * @dev Standardized storage slot for Operable data.
     * Uses ERC1967 derivation: keccak256(...) - 1 .
     */
    bytes32 internal constant STORAGE_SLOT = bytes32(uint256(keccak256(abi.encode("crane.access.operable"))) - 1);

    // end::STORAGE_SLOT[]

    // tag::Storage[]
    /**
     * @dev Standardized storage layout for IOperable operator permissions.
     */
    struct Storage {
        // Mapping of global operators.
        // Global operators may call any function.
        mapping(address => bool) isOperator;
        // Mapping of function level authorization for operators.
        // Operators may call functions only if they are authorized.
        mapping(bytes4 func => mapping(address => bool)) isOperatorFor;
    }

    // end::Storage[]

    // tag::_layoutStruct(bytes32)[]
    /**
     * @dev Argumented version of _layoutStruct to allow for custom storage slot usage.
     * @param storageSlot Storage slot to bind to the Repo's Storage struct.
     * @return layoutStruct The bound Storage struct.
     */
    function _layoutStruct(bytes32 storageSlot) internal pure returns (Storage storage layoutStruct) {
        assembly {
            layoutStruct.slot := storageSlot
        }
    }

    // end::_layoutStruct(bytes32)[]

    // tag::_layoutStruct()[]
    /**
     * @dev Default version of _layoutStruct binding to the standard STORAGE_SLOT.
     * @return layoutStruct The bound Storage struct.
     */
    function _layoutStruct() internal pure returns (Storage storage layoutStruct) {
        return _layoutStruct(STORAGE_SLOT);
    }

    // end::_layoutStruct()[]

    // tag::_setOperatorStatus(Storage-address-bool)[]
    /**
     * @dev Argumented version of _setOperatorStatus to allow direct Storage access.
     * @param layoutStruct The Storage struct to operate on.
     * @param operator The address of the operator.
     * @param approval The operator status to set.
     * @custom:emits IOperable.NewGlobalOperatorStatus
     */
    function _setOperatorStatus(Storage storage layoutStruct, address operator, bool approval) internal {
        // MultiStepOwnableRepo._onlyOwner();
        layoutStruct.isOperator[operator] = approval;
        emit IOperable.NewGlobalOperatorStatus(operator, approval);
    }

    // end::_setOperatorStatus(Storage-address-bool)[]

    // tag::_setOperatorStatus(address-bool)[]
    /**
     * @dev Default version of _setOperatorStatus binding to the standard STORAGE_SLOT.
     * @param operator The address of the operator.
     * @param approval The operator status to set.
     * @custom:emits IOperable.NewGlobalOperatorStatus
     */
    function _setOperatorStatus(address operator, bool approval) internal {
        _setOperatorStatus(_layoutStruct(), operator, approval);
    }

    // end::_setOperatorStatus(address-bool)[]

    // tag::_setFunctionOperatorStatus(Storage-bytes4-address-bool)[]
    /**
     * @dev Argumented version of _setFunctionOperatorStatus to allow direct Storage access.
     * @param layoutStruct The Storage struct to operate on.
     * @param func The function selector the operator status applies to.
     * @param operator The address of the operator.
     * @param approval The operator status to set.
     * @custom:emits IOperable.NewFunctionOperatorStatus
     */
    function _setFunctionOperatorStatus(Storage storage layoutStruct, bytes4 func, address operator, bool approval)
        internal
    {
        MultiStepOwnableRepo._onlyOwner();
        layoutStruct.isOperatorFor[func][operator] = approval;
        emit IOperable.NewFunctionOperatorStatus(operator, func, approval);
    }

    // end::_setFunctionOperatorStatus(Storage-bytes4-address-bool)[]

    // tag::_setFunctionOperatorStatus(bytes4-address-bool)[]
    /**
     * @dev Default version of _setFunctionOperatorStatus binding to the standard STORAGE_SLOT.
     * @param func The function selector the operator status applies to.
     * @param operator The address of the operator.
     * @param approval The operator status to set.
     * @custom:emits IOperable.NewFunctionOperatorStatus
     */
    function _setFunctionOperatorStatus(bytes4 func, address operator, bool approval) internal {
        _setFunctionOperatorStatus(_layoutStruct(), func, operator, approval);
    }

    // end::_setFunctionOperatorStatus(bytes4-address-bool)[]

    // tag::_isOperator(Storage-address)[]
    /**
     * @dev Argumented version of _isOperator to allow direct Storage access.
     * @param layoutStruct The Storage struct to operate on.
     * @param operator The address to check.
     * @return True if the address is a global operator, false otherwise.
     */
    function _isOperator(Storage storage layoutStruct, address operator) internal view returns (bool) {
        return layoutStruct.isOperator[operator];
    }

    // end::_isOperator(Storage-address)[]

    // tag::_isOperator(address)[]
    /**
     * @dev Default version of _isOperator binding to the standard STORAGE_SLOT.
     * @param operator The address to check.
     * @return True if the address is a global operator, false otherwise.
     */
    function _isOperator(address operator) internal view returns (bool) {
        return _isOperator(_layoutStruct(), operator);
    }

    // end::_isOperator(address)[]

    // tag::_isFunctionOperator(Storage-bytes4-address)[]
    /**
     * @dev Argumented version of _isFunctionOperator to allow direct Storage access.
     * @param layoutStruct The Storage struct to operate on.
     * @param func The function selector to check.
     * @param operator The address to check.
     * @return True if the address is an operator for the function, false otherwise.
     */
    function _isFunctionOperator(Storage storage layoutStruct, bytes4 func, address operator)
        internal
        view
        returns (bool)
    {
        return layoutStruct.isOperatorFor[func][operator];
    }

    // end::_isFunctionOperator(Storage-bytes4-address)[]

    // tag::_isFunctionOperator(bytes4-address)[]
    /**
     * @dev Default version of _isFunctionOperator binding to the standard STORAGE_SLOT.
     * @param func The function selector to check.
     * @param operator The address to check.
     * @return True if the address is an operator for the function, false otherwise.
     */
    function _isFunctionOperator(bytes4 func, address operator) internal view returns (bool) {
        return _isFunctionOperator(_layoutStruct(), func, operator);
    }

    // end::_isFunctionOperator(bytes4-address)[]

    // tag::_onlyOperator(Storage)[]
    /**
     * @dev Argumented version of _onlyOperator guard (used by modifiers) allowing direct Storage access.
     * @param layoutStruct The Storage struct to operate on.
     */
    function _onlyOperator(Storage storage layoutStruct) internal view {
        if (!_isOperator(layoutStruct, msg.sender) && !_isFunctionOperator(layoutStruct, msg.sig, msg.sender)) {
            revert IOperable.NotOperator(msg.sender);
        }
    }

    // end::_onlyOperator(Storage)[]

    // tag::_onlyOperator()[]
    /**
     * @dev Default version of _onlyOperator guard binding to the standard STORAGE_SLOT.
     */
    function _onlyOperator() internal view {
        _onlyOperator(_layoutStruct());
    }

    // end::_onlyOperator()[]

    // tag::_onlyOwnerOrOperator(Storage)[]
    /**
     * @dev Argumented version of _onlyOwnerOrOperator guard allowing direct Storage access.
     * @param layoutStruct The Storage struct to operate on.
     */
    function _onlyOwnerOrOperator(Storage storage layoutStruct) internal view {
        if (
            MultiStepOwnableRepo._owner() != msg.sender && !_isOperator(layoutStruct, msg.sender)
                && !_isFunctionOperator(layoutStruct, msg.sig, msg.sender)
        ) {
            revert IOperable.NotOperator(msg.sender);
        }
    }

    // end::_onlyOwnerOrOperator(Storage)[]

    // tag::_onlyOwnerOrOperator()[]
    /**
     * @dev Default version of _onlyOwnerOrOperator guard binding to the standard STORAGE_SLOT.
     */
    function _onlyOwnerOrOperator() internal view {
        _onlyOwnerOrOperator(_layoutStruct());
    }
    // end::_onlyOwnerOrOperator()[]
}
// end::OperableRepo[]
