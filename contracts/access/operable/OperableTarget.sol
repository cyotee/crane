// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import { IOperable } from "../../interfaces/IOperable.sol";
import { OperableStorage } from "./OperableStorage.sol";
import { OwnableModifiers } from "../ownable/OwnableModifiers.sol";

/**
 * @title OperableTarget - Exposes IOperable functions.
 * @author cyotee doge <doge.cyotee>
 * @notice Deliberately DOES NOT expose IOwnable.
 * @dev Uses storage CRUD operations to ensure consistency with validations.
 */
contract OperableTarget
is
// Some functions are restricted to Owner.
OwnableModifiers
// Uses Operable diamond storage.
,OperableStorage
// Exposes IOperable interface
,IOperable
{

    /**
     * @inheritdoc IOperable
     */
    function isOperator(address query)
    public view virtual returns(bool) {
        return _isOperator(query);
    }

    /**
     * @inheritdoc IOperable
     */
    function isOperatorFor(
        bytes4 func,
        address query
    ) public view returns(bool) {
        return _isOperatorFor(func, query);
    }

    /**
     * @notice Restricted to owner.
     * @inheritdoc IOperable
     */
    function setOperator(
        address operator,
        bool status
    ) public virtual
    // Restrict to ONLY calls from Owner.
    onlyOwner()
    returns(bool) {
        _isOperator(operator, status);
        return true;
    }

    /**
     * @notice Restricted to owner.
     * @inheritdoc IOperable
     */
    function setOperatorFor(
        bytes4 func,
        address newOperator,
        bool approval
    ) public 
    // Restrict to ONLY calls from Owner.
    onlyOwner()
    returns(bool) {
        _isOperatorFor(func, newOperator, approval);
        return true;
    }

}