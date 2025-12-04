// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IGreeter} from "@crane/contracts/test/stubs/greeter/IGreeter.sol";
import {GreeterTarget} from "@crane/contracts/test/stubs/greeter/GreeterTarget.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";

contract GreeterFacet is GreeterTarget, IFacet {
    function facetName() public pure returns (string memory name) {
        return type(GreeterFacet).name;
    }

    function facetInterfaces() public pure virtual returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](1);
        interfaces[0] = type(IGreeter).interfaceId;
    }

    function facetFuncs() public pure virtual returns (bytes4[] memory funcs) {
        funcs = new bytes4[](2);
        funcs[0] = IGreeter.getMessage.selector;
        funcs[1] = IGreeter.setMessage.selector;
    }

    function facetMetadata()
        external
        pure
        virtual
        returns (string memory name, bytes4[] memory interfaces, bytes4[] memory functions)
    {
        name = facetName();
        interfaces = facetInterfaces();
        functions = facetFuncs();
    }
}
