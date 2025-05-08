// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {OwnableTarget} from "../ownable/OwnableTarget.sol";
import {IFacet} from "../../factories/create2/callback/diamondPkg/IFacet.sol";
import {IOperableManager} from "./IOperableManager.sol";
import {OperableManagerTarget} from "./OperableManagerTarget.sol";

/**
 * @title OperatableManagerFacet - Facet for Diamond proxies to expose IOperatableManager.
 * @author cyotee doge <doge.cyotee>
 */
contract OperableManagerFacet
is
OperableManagerTarget,
IFacet
{


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