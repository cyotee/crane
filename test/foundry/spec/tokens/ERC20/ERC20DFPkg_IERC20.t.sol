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

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IERC20Metadata} from "@crane/contracts/interfaces/IERC20Metadata.sol";
import {IERC165} from "@crane/contracts/interfaces/IERC165.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {InitDevService} from "contracts/InitDevService.sol";
import {Create3Factory} from "contracts/factories/create3/Create3Factory.sol";
import {ICreate3Factory} from "@crane/contracts/interfaces/ICreate3Factory.sol";
import {DiamondPackageCallBackFactory} from "contracts/factories/diamondPkg/DiamondPackageCallBackFactory.sol";
import {IDiamondPackageCallBackFactory} from "contracts/interfaces/IDiamondPackageCallBackFactory.sol";
import {TestBase_IDiamondLoupe} from "contracts/introspection/ERC2535/TestBase_IDiamondLoupe.sol";
import {TestBase_IERC165} from "contracts/introspection/ERC165/TestBase_IERC165.sol";
import "contracts/tokens/ERC20/TestBase_ERC20.sol";
import {IERC20DFPkg, ERC20DFPkg} from "contracts/tokens/ERC20/ERC20DFPkg.sol";
import {BetterEfficientHashLib} from "contracts/utils/BetterEfficientHashLib.sol";
import {ERC20Facet} from "contracts/tokens/ERC20/ERC20Facet.sol";
import {IDiamondLoupe} from "contracts/interfaces/IDiamondLoupe.sol";
import {FacetRegistry} from "contracts/registries/facet/FacetRegistry.sol";
import {DiamondFactoryPackageRegistry} from "contracts/registries/package/DiamondFactoryPackageRegistry.sol";
import {IFacet} from "contracts/interfaces/IFacet.sol";
import {IDiamondFactoryPackage} from "contracts/interfaces/IDiamondFactoryPackage.sol";

contract ERC20DFPkg_IERC20_Test is TestBase_ERC20 {
    using BetterEfficientHashLib for bytes;

    ICreate3Factory factory;

    IDiamondPackageCallBackFactory diamondFactory;
    // FacetRegistry public facetRegistry;
    // DiamondFactoryPackageRegistry public packageRegistry;

    IFacet erc20Facet;

    IERC20DFPkg erc20DFPKG;

    function setUp() public virtual override(TestBase_ERC20) {
        // factory = new Create3Factory(address(this), IDiamondPackageCallBackFactory(address(0)));
        // vm.label(address(factory), "Create3Factory");
        // diamondFactory = IDiamondPackageCallBackFactory(factory.diamondPackageFactory());
        // vm.label(address(diamondFactory), "DiamondPackageCallBackFactory");
        (factory, diamondFactory) = InitDevService.initEnv(address(this));
        // facetRegistry = factory.facetRegistry();
        // vm.label(address(facetRegistry), "FacetRegistry");
        // packageRegistry = factory.packageRegistry();
        // vm.label(address(packageRegistry), "DiamondFactoryPackageRegistry");
        erc20Facet = factory.deployFacet(type(ERC20Facet).creationCode, abi.encode(type(ERC20Facet).name)._hash());
        vm.label(address(erc20Facet), "ERC20Facet");
        erc20DFPKG = IERC20DFPkg(
            address(
                factory.deployPackageWithArgs(
                    type(ERC20DFPkg).creationCode,
                    abi.encode(IERC20DFPkg.PkgInit({erc20Facet: erc20Facet})),
                    abi.encode(type(ERC20DFPkg).name)._hash()
                )
            )
        );
        vm.label(address(erc20DFPKG), "ERC20DFPkg");
        TestBase_ERC20.setUp();
    }

    function _deployToken(ERC20TargetStubHandler handler_) internal virtual override returns (IERC20 token_) {
        token_ = erc20DFPKG.deploy(diamondFactory, "Test Token", "TT", 18, 1_000_000e18, address(handler_), bytes32(0));
    }
}
