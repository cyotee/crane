// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import { OwnableModifiers } from "contracts/access/ownable/OwnableModifiers.sol";
import { IOperable } from "contracts/interfaces/IOperable.sol";
import { OperableStorage } from "contracts/access/operable/OperableStorage.sol";

// import {
//     OperableTarget
// } from "./OperableTarget.sol";

import {
    IFacet
} from "contracts/interfaces/IFacet.sol";

import {
    Create3AwareContract
} from "contracts/factories/create2/aware/Create3AwareContract.sol";
import {
    ICreate3Aware
} from "contracts/interfaces/ICreate3Aware.sol";


/**
 * @title OperatableFacet - Facet for Diamond proxies to expose IOwnable and IOperatable.
 * @author cyotee doge <doge.cyotee>
 */
contract OperableFacet
is
// OperableTarget,
// Some functions are restricted to Owner.
OwnableModifiers,
// Uses Operable diamond storage.
OperableStorage,
Create3AwareContract,
// Exposes IOperable interface
IOperable,
IFacet
{

    constructor(ICreate3Aware.CREATE3InitData memory create3InitData) Create3AwareContract(create3InitData) {
        // No additional initialization needed for facets
    }

    /* ---------------------------------------------------------------------- */
    /*                                 IFacet                                 */
    /* ---------------------------------------------------------------------- */

    /**
     * @inheritdoc IFacet
     */
    function facetInterfaces()
    public view virtual override returns(bytes4[] memory interfaces) {
        interfaces =  new bytes4[](1);
        interfaces[0] = type(IOperable).interfaceId;
    }

    /**
     * @inheritdoc IFacet
     */
    function facetFuncs()
    public view virtual override returns(bytes4[] memory funcs) {
        funcs = new bytes4[](4);
        funcs[0] = IOperable.isOperator.selector;
        funcs[1] = IOperable.isOperatorFor.selector;
        funcs[2] = IOperable.setOperator.selector;
        funcs[3] = IOperable.setOperatorFor.selector;
    }

    /* ---------------------------------------------------------------------- */
    /*                                  Logic                                 */
    /* ---------------------------------------------------------------------- */

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
