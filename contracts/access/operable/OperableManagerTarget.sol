// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {OwnableModifiers} from "../ownable/OwnableModifiers.sol";
import {OwnableTarget} from "../ownable/OwnableTarget.sol";
import {IOperable} from "../../interfaces/IOperable.sol";
import {IOperableManager} from "../../interfaces/IOperableManager.sol";

/**
 * @title OperatableManagerFacet - Facet for Diamond proxies to expose IOperatableManager.
 * @author cyotee doge <doge.cyotee>
 */
contract OperableManagerTarget
is
OwnableModifiers,
IOperableManager
{

    /**
     * @inheritdoc IOperableManager
     */
    function setOperator(
        IOperable subject,
        address newOperator,
        bool approval
    ) public onlyOwner() returns(bool) {
        return subject.setOperator(newOperator, approval);
    }

    function setOperatorFor(
        IOperable subject,
        bytes4 func, 
        address newOperator,
        bool approval
    ) public onlyOwner() returns(bool) {
        return subject.setOperatorFor(func, newOperator, approval);
    }

}