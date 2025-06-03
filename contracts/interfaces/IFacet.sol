// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

interface IFacet {
       
    function facetInterfaces()
    external view returns(bytes4[] memory interfaces);

    function facetFuncs()
    external view returns(bytes4[] memory funcs);

}