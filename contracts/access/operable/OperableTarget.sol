// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {IOperable} from "@crane/contracts/interfaces/IOperable.sol";
import {OperableRepo} from "@crane/contracts/access/operable/OperableRepo.sol";
import {MultiStepOwnableModifiers} from "@crane/contracts/access/ERC8023/MultiStepOwnableModifiers.sol";

// tag::OperableTarget[]
/**
 * @title OperableTarget - Exposes IOperable functions.
 * @author cyotee doge <doge.cyotee>
 * @notice Deliberately DOES NOT expose IOwnable.
 * @dev Uses storage CRUD operations to ensure consistency with validations.
 */
contract OperableTarget is

    // Some functions are restricted to Owner.
    MultiStepOwnableModifiers,
    // Exposes IOperable interface
    IOperable
{
    // tag::isOperator(address query)[]
    /**
     * @inheritdoc IOperable
     */
    function isOperator(address query) public view returns (bool) {
        return OperableRepo._isOperator(query);
    }

    // end::isOperator(address query)[]

    // tag::isOperatorFor(bytes4,address)[]
    /**
     * @inheritdoc IOperable
     */
    function isOperatorFor(bytes4 func, address query) public view returns (bool) {
        return OperableRepo._isFunctionOperator(func, query);
    }

    // end::isOperatorFor(bytes4,address)[]

    // tag::setOperator(address,bool)[]
    /**
     * @notice Restricted to owner.
     * @inheritdoc IOperable
     */
    function setOperator(address operator, bool status)
        public
        // Restrict to ONLY calls from Owner.
        onlyOwner
        returns (bool)
    {
        OperableRepo._setOperatorStatus(operator, status);
        return true;
    }

    // end::setOperator(address,bool)[]

    // tag::setOperatorFor(bytes4,address,bool)[]
    /**
     * @notice Restricted to owner.
     * @inheritdoc IOperable
     */
    function setOperatorFor(bytes4 func, address newOperator, bool approval)
        public
        // Restrict to ONLY calls from Owner.
        onlyOwner
        returns (bool)
    {
        OperableRepo._setFunctionOperatorStatus(func, newOperator, approval);
        return true;
    }
    // end::setOperatorFor(bytes4,address,bool)[]
}
// end::OperableTarget[]
