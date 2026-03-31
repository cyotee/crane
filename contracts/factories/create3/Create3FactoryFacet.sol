// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {ICreate3Factory} from "@crane/contracts/interfaces/ICreate3Factory.sol";
import {Create3FactoryTarget} from "@crane/contracts/factories/create3/Create3FactoryTarget.sol";

contract Create3FactoryFacet is Create3FactoryTarget, IFacet {
    /* ---------------------------------------------------------------------- */
    /*                                 IFacet                                 */
    /* ---------------------------------------------------------------------- */

    function facetName() public pure returns (string memory name) {
        return type(Create3FactoryFacet).name;
    }

    function facetInterfaces() public pure virtual returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](1);
        interfaces[0] = type(ICreate3Factory).interfaceId;
    }

    function facetFuncs() public pure virtual returns (bytes4[] memory funcs) {
        funcs = new bytes4[](4);
        funcs[0] = ICreate3Factory.diamondPackageFactory.selector;
        funcs[1] = ICreate3Factory.setDiamondPackageFactory.selector;
        funcs[2] = ICreate3Factory.create3.selector;
        funcs[3] = ICreate3Factory.create3WithArgs.selector;
    }

    function facetMetadata()
        external
        pure
        returns (string memory name, bytes4[] memory interfaces, bytes4[] memory functions)
    {
        name = facetName();
        interfaces = facetInterfaces();
        functions = facetFuncs();
    }
}
