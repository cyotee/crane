// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                   Foundry                                  */
/* -------------------------------------------------------------------------- */

/// forge-lint: disable-next-line(unaliased-plain-import)
import "forge-std/Test.sol";

/* -------------------------------------------------------------------------- */
/*                                Open Zeppelin                               */
/* -------------------------------------------------------------------------- */

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {InitDevService} from "contracts/InitDevService.sol";
import {Create3Factory} from "contracts/factories/create3/Create3Factory.sol";
import {ICreate3Factory} from "contracts/interfaces/ICreate3Factory.sol";
import {DiamondPackageCallBackFactory} from "contracts/factories/diamondPkg/DiamondPackageCallBackFactory.sol";
import {IDiamondPackageCallBackFactory} from "contracts/interfaces/IDiamondPackageCallBackFactory.sol";
import {TestBase_IDiamondLoupe} from "contracts/introspection/ERC2535/TestBase_IDiamondLoupe.sol";
import {TestBase_IERC165} from "contracts/introspection/ERC165/TestBase_IERC165.sol";
import "contracts/tokens/ERC20/TestBase_ERC20.sol";
import {IERC20DFPkg, ERC20DFPkg} from "contracts/tokens/ERC20/ERC20DFPkg.sol";
import {BetterEfficientHashLib} from "contracts/utils/BetterEfficientHashLib.sol";
import {ERC20Facet} from "contracts/tokens/ERC20/ERC20Facet.sol";
import {IDiamondLoupe} from "contracts/interfaces/IDiamondLoupe.sol";
import {IFacet} from "contracts/interfaces/IFacet.sol";
import {FacetRegistry} from "contracts/registries/facet/FacetRegistry.sol";
import {DiamondFactoryPackageRegistry} from "contracts/registries/package/DiamondFactoryPackageRegistry.sol";
import {IFacet} from "contracts/interfaces/IFacet.sol";
import {IDiamondFactoryPackage} from "contracts/interfaces/IDiamondFactoryPackage.sol";

// contract ERC20DFPkg_IDiamondLoupe_Test is TestBase_IDiamondLoupe {

//     using BetterEfficientHashLib for bytes;

//     ICreate3Factory factory;

//     IDiamondPackageCallBackFactory diamondFactory;
//     // FacetRegistry public facetRegistry;
//     // DiamondFactoryPackageRegistry public packageRegistry;

//     IFacet erc20Facet;

//     IERC20DFPkg erc20DFPKG;

//     IERC20 testSubject;

//     function setUp() public virtual
//     override(
//         TestBase_IDiamondLoupe
//     ) {
//         // factory = new Create3Factory(address(this));
//         // vm.label(address(factory), "Create3Factory");
//         // diamondFactory = IDiamondPackageCallBackFactory(factory.diamondPackageFactory());
//         // vm.label(address(diamondFactory), "DiamondPackageCallBackFactory");
//         (factory, diamondFactory) = InitDevService.initEnv(address(this));
//         // facetRegistry = factory.facetRegistry();
//         // vm.label(address(facetRegistry), "FacetRegistry");
//         // packageRegistry = factory.packageRegistry();
//         // vm.label(address(packageRegistry), "DiamondFactoryPackageRegistry");
//         erc20Facet = factory.deployFacet(
//             type(ERC20Facet).creationCode,
//             abi.encode(type(ERC20Facet).name)._hash()
//         );
//         vm.label(address(erc20Facet), "ERC20Facet");
//         erc20DFPKG = IERC20DFPkg(
//             address(
//                 factory.deployPackageWithArgs(
//                     type(ERC20DFPkg).creationCode,
//                     abi.encode(
//                         IERC20DFPkg.PkgInit({
//                             erc20Facet: erc20Facet
//                         })
//                     ),
//                     abi.encode(type(ERC20DFPkg).name)._hash()
//                 )
//             )
//         );
//         vm.label(address(erc20DFPKG), "ERC20DFPkg");
//         testSubject = erc20DFPKG.deploy(
//             diamondFactory,
//             "Test Token",
//             "TT",
//             18,
//             1_000_000e18,
//             address(this),
//             bytes32(0)
//         );
//         vm.label(address(testSubject), IERC20Metadata(address(testSubject)).name());
//         TestBase_IDiamondLoupe.setUp();
//     }

//     /// forge-lint: disable-next-line(mixed-case-function)
//     function diamondLoupe_subject() public virtual override returns (IDiamondLoupe subject_) {
//         return IDiamondLoupe(address(testSubject));
//     }

//     /// forge-lint: disable-next-line(mixed-case-function)
//     function expected_IDiamondLoupe_facets() public virtual override returns (IDiamondLoupe.Facet[] memory expectedFacets_) {

//         expectedFacets_ = new IDiamondLoupe.Facet[](3);

//         expectedFacets_[0] = IDiamondLoupe.Facet({
//             facetAddress: address(diamondFactory.ERC165_FACET()),
//             functionSelectors: diamondFactory.ERC165_FACET().facetFuncs()
//             // functionSelectors: erc165Funcs()
//         });

//         expectedFacets_[1] = IDiamondLoupe.Facet({
//             facetAddress: address(diamondFactory.DIAMOND_LOUPE_FACET()),
//             functionSelectors: diamondFactory.DIAMOND_LOUPE_FACET().facetFuncs()
//             // functionSelectors: diamondLoupeFuncs()
//         });

//         expectedFacets_[2] = IDiamondLoupe.Facet({
//             facetAddress: address(erc20Facet),
//             functionSelectors: erc20Facet.facetFuncs()
//             // functionSelectors: erc20Funcs()
//         });
//     }

//     function erc20Funcs() public pure returns (bytes4[] memory funcs) {
//         funcs = new bytes4[](9);

//         funcs[0] = IERC20Metadata.name.selector;
//         funcs[1] = IERC20Metadata.symbol.selector;
//         funcs[2] = IERC20Metadata.decimals.selector;
//         funcs[3] = IERC20.totalSupply.selector;
//         funcs[4] = IERC20.balanceOf.selector;
//         funcs[5] = IERC20.allowance.selector;
//         funcs[6] = IERC20.approve.selector;
//         funcs[7] = IERC20.transfer.selector;
//         funcs[8] = IERC20.transferFrom.selector;
//     }

// }
