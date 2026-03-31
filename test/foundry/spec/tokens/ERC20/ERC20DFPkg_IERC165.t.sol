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

import {InitDevService} from "@crane/contracts/InitDevService.sol";
import {InitDevService} from "@crane/contracts/InitDevService.sol";
import {Create3Factory} from "@crane/contracts/factories/create3/Create3Factory.sol";
import {ICreate3FactoryProxy} from "@crane/contracts/interfaces/proxies/ICreate3FactoryProxy.sol";
import {DiamondPackageCallBackFactory} from "@crane/contracts/factories/diamondPkg/DiamondPackageCallBackFactory.sol";
import {IDiamondPackageCallBackFactory} from "@crane/contracts/interfaces/IDiamondPackageCallBackFactory.sol";
import {TestBase_IDiamondLoupe} from "@crane/contracts/introspection/ERC2535/TestBase_IDiamondLoupe.sol";
import {TestBase_IERC165} from "@crane/contracts/introspection/ERC165/TestBase_IERC165.sol";
import "@crane/contracts/tokens/ERC20/TestBase_ERC20.sol";
import {IERC20DFPkg, ERC20DFPkg} from "@crane/contracts/tokens/ERC20/ERC20DFPkg.sol";
import {BetterEfficientHashLib} from "@crane/contracts/utils/BetterEfficientHashLib.sol";
import {ERC20Facet} from "@crane/contracts/tokens/ERC20/ERC20Facet.sol";
import {IDiamondLoupe} from "@crane/contracts/interfaces/IDiamondLoupe.sol";
// import {DiamondFactoryPackageRegistry} from "@crane/contracts/registries/package/DiamondFactoryPackageRegistry.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {IDiamondFactoryPackage} from "@crane/contracts/interfaces/IDiamondFactoryPackage.sol";

contract ERC20DFPkg_IERC165_Test is TestBase_IERC165 {
    using BetterEfficientHashLib for bytes;

    ICreate3FactoryProxy factory;

    IDiamondPackageCallBackFactory diamondFactory;

    IFacet erc20Facet;

    IERC20DFPkg erc20DFPKG;

    IERC20 testSubject;

    function setUp() public virtual override(TestBase_IERC165) {
        (factory, diamondFactory) = InitDevService.initEnv(address(this));
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
        testSubject = erc20DFPKG.deploy(diamondFactory, "Test Token", "TT", 18, 1_000_000e18, address(this), bytes32(0));
        vm.label(address(testSubject), IERC20Metadata(address(testSubject)).name());
        TestBase_IERC165.setUp();
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function erc165_subject() public virtual override returns (IERC165 subject_) {
        return IERC165(address(testSubject));
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function expected_IERC165_interfaces() public virtual override returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](3);

        interfaces[0] = type(IERC20).interfaceId;
        interfaces[1] = type(IERC20Metadata).interfaceId;
        interfaces[2] = type(IERC20Metadata).interfaceId ^ type(IERC20).interfaceId;
    }
}
