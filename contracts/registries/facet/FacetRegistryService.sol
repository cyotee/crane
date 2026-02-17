// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {FacetRegistryRepo} from "@crane/contracts/registries/facet/FacetRegistryRepo.sol";
import {Create3FactoryService} from "@crane/contracts/factories/create3/Create3FactoryService.sol";

library FacetRegistryService {
    function _registerFacet(IFacet facet) internal {
        (string memory name, bytes4[] memory interfaces, bytes4[] memory functions) = facet.facetMetadata();
        FacetRegistryRepo._registerFacet(facet, name, interfaces, functions);
    }

    function _deployFacet(bytes memory initCode, bytes memory initArgs, bytes32 salt) internal returns (IFacet facet) {
        facet = IFacet(Create3FactoryService._create3WithArgs(initCode, initArgs, salt));
        _registerFacet(facet);
        return facet;
    }

    function _deployFacet(bytes memory initCode, bytes32 salt) internal returns (IFacet facet) {
        facet = IFacet(Create3FactoryService._create3(initCode, salt));
        _registerFacet(facet);
        return facet;
    }
}
