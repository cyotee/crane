// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IOperable} from "@crane/contracts/interfaces/IOperable.sol";
import {MultiStepOwnableRepo} from "@crane/contracts/access/ERC8023/MultiStepOwnableRepo.sol";

library OperableRepo {
    bytes32 internal constant STORAGE_SLOT = keccak256(abi.encode("crane.access.operable"));

    /**
     * @title Storage - Diamond storage layout for IOperable.
     * @author cyotee doge <doge.cyotee>
     */
    struct Storage {
        // Mapping of global operators.
        // Global operators may call any function.
        mapping(address => bool) isOperator;
        // Mapping of function level authorization for operators.
        // Operators may call functions only if they are authorized.
        mapping(bytes4 func => mapping(address => bool)) isOperatorFor;
    }

    function _layout(bytes32 storageSlot) internal pure returns (Storage storage layout) {
        assembly {
            layout.slot := storageSlot
        }
    }

    function _layout() internal pure returns (Storage storage) {
        return _layout(STORAGE_SLOT);
    }

    function _setOperatorStatus(Storage storage layout, address operator, bool approval) internal {
        MultiStepOwnableRepo._onlyOwner();
        layout.isOperator[operator] = approval;
        emit IOperable.NewGlobalOperatorStatus(operator, approval);
    }

    function _setOperatorStatus(address operator, bool approval) internal {
        _setOperatorStatus(_layout(), operator, approval);
    }

    function _setFunctionOperatorStatus(Storage storage layout, bytes4 func, address operator, bool approval)
        internal
    {
        MultiStepOwnableRepo._onlyOwner();
        layout.isOperatorFor[func][operator] = approval;
        emit IOperable.NewFunctionOperatorStatus(operator, func, approval);
    }

    function _setFunctionOperatorStatus(bytes4 func, address operator, bool approval) internal {
        _setFunctionOperatorStatus(_layout(), func, operator, approval);
    }

    function _isOperator(Storage storage layout, address operator) internal view returns (bool) {
        return layout.isOperator[operator];
    }

    function _isOperator(address operator) internal view returns (bool) {
        return _isOperator(_layout(), operator);
    }

    function _isFunctionOperator(Storage storage layout, bytes4 func, address operator)
        internal
        view
        returns (bool)
    {
        return layout.isOperatorFor[func][operator];
    }

    function _isFunctionOperator(bytes4 func, address operator) internal view returns (bool) {
        return _isFunctionOperator(_layout(), func, operator);
    }

    function _onlyOperator(Storage storage layout) internal view {
        if (!_isOperator(layout, msg.sender) && !_isFunctionOperator(layout, msg.sig, msg.sender)) {
            revert IOperable.NotOperator(msg.sender);
        }
    }

    function _onlyOperator() internal view {
        _onlyOperator(_layout());
    }

    function _onlyOwnerOrOperator(Storage storage layout) internal view {
        if (
            MultiStepOwnableRepo._owner() != msg.sender && !_isOperator(layout, msg.sender)
                && !_isFunctionOperator(layout, msg.sig, msg.sender)
        ) {
            revert IOperable.NotOperator(msg.sender);
        }
    }

    function _onlyOwnerOrOperator() internal view {
        _onlyOwnerOrOperator(_layout());
    }
}
