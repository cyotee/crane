// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IFacet {
       
    function facetInterfaces()
    external view returns(bytes4[] memory interfaces);

    function facetFuncs()
    external view returns(bytes4[] memory funcs);

}