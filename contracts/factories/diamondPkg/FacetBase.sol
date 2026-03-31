// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IFacet} from '@crane/contracts/interfaces/IFacet.sol';

abstract contract FacetBase is IFacet {
    // tag::facetName()[]
    /**
     * @inheritdoc IFacet
     */
    function facetName() public view virtual returns (string memory name);
    // end::facetName()[]

    // tag::facetInterfaces()[]
    /**
     * @inheritdoc IFacet
     */
    function facetInterfaces() public view virtual returns (bytes4[] memory interfaces);
    // end::facetInterfaces()[]

    // tag::facetFuncs()[]
    /**
     * @inheritdoc IFacet
     */
    function facetFuncs() public view virtual returns (bytes4[] memory funcs);
    // end::facetFuncs()[]

    // tag::facetMetadata()[]
    
    /**
     * @inheritdoc IFacet
     */
    function facetMetadata()
        public
        view
        virtual
        returns (string memory name, bytes4[] memory interfaces, bytes4[] memory functions) {
            name = facetName();
            interfaces = facetInterfaces();
            functions = facetFuncs();
        }
    // end::facetMetadata()[]
}