// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {OwnableTarget} from "../../ownable/targets/OwnableTarget.sol";
import {IFacet} from "../../../factories/create2/callback/diamondPkg/interfaces/IFacet.sol";
import {IOperableManager} from "../interfaces/IOperableManager.sol";
import {OperableManagerTarget} from "../targets/OperableManagerTarget.sol";

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