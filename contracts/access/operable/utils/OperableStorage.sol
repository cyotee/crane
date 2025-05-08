// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {OwnableStorage} from "../../../access/ownable/utils/OwnableStorage.sol";

import {
    OperableLayout,
    OperableRepo
} from "../utils/OperableRepo.sol";

import {IOperable} from "../IOperable.sol";

import {OwnableModifiers} from "../../ownable/OwnableModifiers.sol";

import {
    OperableRepo
} from "./OperableRepo.sol";

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
 * @dev Can be improved with RBAC implementation from experimental repo.
 * @dev Defines CRUD operations to promote consistency with validation logic.
 */
abstract contract OperableStorage is OwnableStorage, IOperableStorage {

    using OperableRepo for bytes32;

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
        return STORAGE_SLOT.layout();
    }

    /**
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

    function _initOperable(
        address[] memory operators
    ) internal {
        for(uint256 cursor = 0; cursor < operators.length; cursor++) {
            _initOperable(operators[cursor]);
        }
    }

    function _initOperable(
        address operator,
        bytes4 func
    ) internal {
        _isOperatorFor(func, operator, true);
    }

    function _initOperable(
        address operator,
        bytes4[] memory funcs
    ) internal {
        for(uint256 cursor = 0; cursor < funcs.length; cursor++) {
            _initOperable(operator, funcs[cursor]);
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
     * @return Boolean indicating authorization as an operator.
     */
    function _isOperatorFor(
        bytes4 func,
        address query
    ) internal view virtual returns(bool) {
        return _operable().isOperatorFor[func][query];
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