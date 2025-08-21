// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import { OwnableStorage } from "contracts/access/ownable/utils/OwnableStorage.sol";
import { IOperable } from "contracts/interfaces/IOperable.sol";
// import { IOperableStorage } from "contracts/interfaces/IOperableStorage.sol";

/**
 * @title OperableLayout - Diamond storage layout for IOperable.
 * @author cyotee doge <doge.cyotee>
 */
struct OperableLayout {
    // Mapping of global operators.
    // Global operators may call any function.
    mapping(address => bool) isOperator;
    // Mapping of function level authorization for operators.
    // Operators may call functions only if they are authorized.
    mapping(bytes4 func => mapping(address => bool)) isOperatorFor;
}

/**
 * @title OperableRepo - Repository library for OperableLayout;
 * @author cyotee doge <doge.cyotee>
 */
library OperableRepo {

    // tag::_slot[]
    /**
     * @dev Provides the storage pointer bound to a Struct instance.
     * @param layout Implicit "layout" of storage slots defined as this Struct.
     * @return slot_ The storage slot bound to the provided Struct.
     */
    function _slot(
        OperableLayout storage layout
    ) internal pure returns(bytes32 slot_) {
        // solhint-disable-next-line no-inline-assembly
        assembly{slot_ := layout.slot}
    }
    // end::_slot[]

    // tag::_layout[]
    /**
     * @dev "Binds" this struct to a storage slot.
     * @param slot_ The first slot to use in the range of slots used by the struct.
     * @return layout_ A struct from a Layout library bound to the provided slot.
     */
    function _layout(
        bytes32 slot_
    ) internal pure returns(OperableLayout storage layout_) {
        // solhint-disable-next-line no-inline-assembly
        assembly{layout_.slot := slot_}
    }
    // end::_layout[]

}

/**
 * @title IOperableStorage - Inheritable structs for 
 */
interface IOperableStorage
{

    struct OperatorConfig {
        address operator;
        bytes4[] funcs;
    }

    struct OperableAccountInit {
        address[] globalOperators;
        OperatorConfig[] operatorConfigs;
    }

}

/**
 * @title OperableStorage - Inheritable storage logic for IOperable.
 * @author cyotee doge <doge.cyotee>
 * @dev Operator is defined as an address authorized to call a functions.
 * @dev Operator MAY be GLOBAL AND/OR function level.
 * @dev Can be improved with RBAC implementation.
 * @dev Defines CRUD operations to promote consistency with validation logic.
 */
abstract contract OperableStorage is OwnableStorage, IOperableStorage {

    using OperableRepo for bytes32;

    /**
     * @dev 
     */
    bytes32 private constant LAYOUT_ID
        = keccak256(abi.encode(type(OperableRepo).name));
    bytes32 private constant STORAGE_RANGE_OFFSET
        = bytes32(uint256(keccak256(abi.encode(LAYOUT_ID))) - 1);
    bytes32 private constant STORAGE_RANGE
        = type(IOperable).interfaceId;
    bytes32 private constant STORAGE_SLOT
        = keccak256(abi.encode(STORAGE_RANGE, STORAGE_RANGE_OFFSET));

    /**
     * @return Diamond storage struct bound to the declared "service" slot.
     */
    function _operable()
    internal pure virtual returns(OperableLayout storage) {
        return STORAGE_SLOT._layout();
    }

    /**
     * @dev Initializes a single global operator.
     * @dev Initialization presumes a desire to change from default initialization.
     * @dev Default boolean value is false.
     * @dev Thus, providing an operator implies a desire for authorization.
     * @dev Thus, there is no need to pass a boolean indicating desired authorization change.
     */
    function _initOperable(
        address operator
    ) internal {
        _isOperator(operator, true);
    }

    /**
     * @dev Initializes multiple global operators.
     * @dev Makes iterative calles to the single global operator initializer.
     * @dev Initialization presumes a desire to change from default initialization.
     * @dev Default boolean value is false.
     * @dev Thus, providing an operator implies a desire for authorization.
     * @dev Thus, there is no need to pass a boolean indicating desired authorization change.
     */
    function _initOperable(
        address[] memory operators
    ) internal {
        for(uint256 cursor = 0; cursor < operators.length; cursor++) {
            _initOperable(operators[cursor]);
        }
    }

    /**
     * @dev Initializes a single function operator.
     * @dev Initialization presumes a desire to change from default initialization.
     * @dev Default boolean value is false.
     * @dev Thus, providing an operator implies a desire for authorization.
     * @dev Thus, there is no need to pass a boolean indicating desired authorization change.
     */
    function _initOperable(
        address operator,
        bytes4 func
    ) internal {
        _isOperatorFor(func, operator, true);
    }

    /**
     * @dev Initializes multiple function operators.
     * @dev Makes iterative calles to the single function operator initializer.
     * @dev Initialization presumes a desire to change from default initialization.
     * @dev Default boolean value is false.
     * @dev Thus, providing an operator implies a desire for authorization.
     * @dev Thus, there is no need to pass a boolean indicating desired authorization change.
     */
    function _initOperable(
        address operator,
        bytes4[] memory funcs
    ) internal {
        for(uint256 cursor = 0; cursor < funcs.length; cursor++) {
            _initOperable(operator, funcs[cursor]);
        }
    }

    /**
     * @dev Initializes multiple function operators.
     * @dev Makes iterative calles to the single function operator initializer.
     * @dev Initialization presumes a desire to change from default initialization.
     * @dev Default boolean value is false.
     * @dev Thus, providing an operator implies a desire for authorization.
     * @dev Thus, there is no need to pass a boolean indicating desired authorization change.
     */
    function _initOperable(
        address[] memory operators,
        bytes4[] memory funcs
    ) internal {
        for(uint256 cursor = 0; cursor < operators.length; cursor++) {
            _initOperable(operators[cursor], funcs);
        }
    }


    function _initOperable(
        IOperableStorage.OperatorConfig memory config
    ) internal {
        _initOperable(config.operator, config.funcs);
    }

    function _initOperable(
        IOperableStorage.OperatorConfig[] memory configs
    ) internal {
        for(uint256 cursor = 0; cursor < configs.length; cursor++) {
            _initOperable(configs[cursor]);
        }
    }

    function _initOperable(
        IOperableStorage.OperableAccountInit memory operableAccountInit
    ) internal {
        _initOperable(operableAccountInit.globalOperators);
        _initOperable(operableAccountInit.operatorConfigs);
    }

    /**
     * @param query Address for which to query operator authorization.
     * @return Boolean indicating authorization as an operator.
     */
    function _isOperator(address query)
    internal view virtual returns(bool) {
        return _operable().isOperator[query];
    }

    /**
     * @param operator Subject of operator authorization change.
     * @param approval Desired authorization status.
     */
    function _isOperator(
        address operator,
        bool approval
    ) internal {
        _operable().isOperator[operator] = approval;
        emit IOperable.NewGlobalOperator(operator);
    }

    /**
     * @param func Function selector for which to query authorization of `newOperator`.
     * @param query Address for which to query operator authorization.
     * @return isAuthed Boolean indicating authorization as an operator.
     */
    function _isOperatorFor(
        bytes4 func,
        address query
    ) internal view virtual returns(bool isAuthed) {
        isAuthed = _operable().isOperator[query];
        if(!isAuthed) {
            isAuthed = _operable().isOperatorFor[func][query];
        }
        return isAuthed;
    }

    /**
     * @param func Function selector for which to update authorization of `newOperator`.
     * @param newOperator Account for which to update authorization to call `func`.
     * @param approval Call authorization change.
     */
    function _isOperatorFor(
        bytes4 func,
        address newOperator,
        bool approval
    ) internal {
        _operable().isOperatorFor[func][newOperator] = approval;
        emit IOperable.NewFunctionOperator(newOperator, func);
    }

}