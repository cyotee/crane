// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {
    IOwnable
} from "../../../access/ownable/interfaces/IOwnable.sol";

import {
    OwnableStorage
} from "../../../access/ownable/storage/OwnableStorage.sol";

import {
    OwnableModifiers
} from "../../../access/ownable/modifiers/OwnableModifiers.sol";

import {
    IOperable
} from "../../../access/operable/interfaces/IOperable.sol";

import {
    OperableStorage
} from "../../../access/operable/storage/OperableStorage.sol";

/**
 * @title OperableModifiers - Inheritable modifiers for Operable validations.
 * @author cyotee doge <doge.cyotee>
 */
contract OperableModifiers
is
OperableStorage
{

    /**
     * @notice Revert if query is NOT authorized as an operator.
     */
    modifier onlyOperator() {
        if(
            // Global approval is acceptable.
            !_isOperator(msg.sender)
            // Function level approval is acceptable.
            && !_operable().isOperatorFor[msg.sig][msg.sender]
        ) {
            // Revert IF neither global NOR function level approved.
            revert IOperable.NotOperator(msg.sender);
        }
        _;
    }
    

    /**
     * @notice Revert if query is NOT authorized as an operator OR ownership has been renounced.
     */
    modifier onlyOperatorOrRenounced() {
        if(
            // No Owner authorizes ALL callers.
            _ownable().owner != address(0)
            // Global approval is acceptable.
            && !_isOperator(msg.sender)
            // Function level approval is acceptable.
            && !_operable().isOperatorFor[msg.sig][msg.sender]
        ) {
            // Revert IF neither global NOR function level approved AND IS owned.
            revert IOperable.NotOperator(msg.sender);
        }
        _;
    }

    /**
     * @notice Revert if query is NOT authorized as an operator NOR owner.
     */
    modifier onlyOwnerOrOperator() {
        if(
            // Global approval is acceptable.
            !_isOperator(msg.sender)
            // Function level approval is acceptable.
            && !_operable().isOperatorFor[msg.sig][msg.sender]
            // Owner status is acceptable.
            && !_isOwner(msg.sender)
        ) {
            // Revert IF neither global NOR function level approved NOR owner.
            revert IOperable.NotOperator(msg.sender);
        }
        _;
    }

    /**
     * @notice Revert if query is NOT authorized as an operator OR owner OR ownership has been renounced.
     */
    modifier onlyOwnerOrOperatorOrRenounced() {
        if(
            // No Owner authorizes ALL callers.
            _ownable().owner != address(0)
            // Global approval is acceptable.
            && !_isOperator(msg.sender)
            // Function level approval is acceptable.
            && !_operable().isOperatorFor[msg.sig][msg.sender]
            // Owner status is acceptable.
            && !_isOwner(msg.sender)
        ) {
            // Revert IF neither global NOR function level approved AND IS owned.
            revert IOperable.NotOperator(msg.sender);
        }
        _;
    }

}