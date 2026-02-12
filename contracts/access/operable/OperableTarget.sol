// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {IOperable} from "@crane/contracts/interfaces/IOperable.sol";
import {OperableRepo} from "@crane/contracts/access/operable/OperableRepo.sol";
import {MultiStepOwnableModifiers} from "@crane/contracts/access/ERC8023/MultiStepOwnableModifiers.sol";

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
    /**
     * @inheritdoc IOperable
     */
    function isOperator(address query) public view virtual returns (bool) {
        return OperableRepo._isOperator(query);
    }

    /**
     * @inheritdoc IOperable
     */
    function isOperatorFor(bytes4 func, address query) public view returns (bool) {
        return OperableRepo._isFunctionOperator(func, query);
    }

    /**
     * @notice Restricted to owner.
     * @inheritdoc IOperable
     */
    function setOperator(address operator, bool status)
        public
        virtual
        // Restrict to ONLY calls from Owner.
        onlyOwner
        returns (bool)
    {
        OperableRepo._setOperatorStatus(operator, status);
        return true;
    }

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
}
