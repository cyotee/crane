// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {Create3Factory} from "@crane/contracts/factories/create3/Create3Factory.sol";
import {ERC165Facet} from "@crane/contracts/introspection/ERC165/ERC165Facet.sol";
import {DiamondLoupeFacet} from "@crane/contracts/introspection/ERC2535/DiamondLoupeFacet.sol";
import {PostDeployAccountHookFacet} from "@crane/contracts/factories/diamondPkg/PostDeployAccountHookFacet.sol";
// import "contracts/factories/diamondPkg/DiamondPackageCallBackFactory.sol";

// library FactoriesService {

//     function deployFactories(address owner) internal
//     returns (
//         Create3Factory create3Factory
//     ) {
//         create3Factory = new Create3Factory(owner);
//     }

// }
