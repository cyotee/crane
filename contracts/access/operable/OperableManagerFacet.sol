// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {OwnableTarget} from "../ownable/OwnableTarget.sol";
import {IFacet} from "../../interfaces/IFacet.sol";
import {IOperableManager} from "../../interfaces/IOperableManager.sol";
import {OperableManagerTarget} from "./OperableManagerTarget.sol";
import {Create3AwareContract} from "../../factories/create2/aware/Create3AwareContract.sol";

/**
 * @title OperatableManagerFacet - Facet for Diamond proxies to expose IOperatableManager.
 * @author cyotee doge <doge.cyotee>
 */
contract OperableManagerFacet is Create3AwareContract, OperableManagerTarget, IFacet {

    constructor(CREATE3InitData memory initData_)
    Create3AwareContract(initData_) {}

    /**
     * @inheritdoc IFacet
     */    function facetInterfaces()
    public view virtual override returns(bytes4[] memory interfaces) {
        interfaces =  new bytes4[](1);
        interfaces[0] = type(IOperableManager).interfaceId;
    }

    /**
     * @inheritdoc IFacet
     */
    function facetFuncs()
    public view virtual override returns(bytes4[] memory funcs) {
        funcs = new bytes4[](2);
        funcs[0] = IOperableManager.setOperator.selector;
        funcs[1] = IOperableManager.setOperatorFor.selector;
    }

}