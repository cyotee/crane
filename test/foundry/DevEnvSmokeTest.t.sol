// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {betterconsole as console} from "@crane/contracts/utils/vm/foundry/tools/betterconsole.sol";
import {CONTRACT_INIT_SIZE_LIMIT, CONTRACT_SIZE_LIMIT} from "@crane/contracts/constants/Constants.sol";
import {IERC165} from "@crane/contracts/interfaces/IERC165.sol";
import {IDiamondLoupe} from "@crane/contracts/interfaces/IDiamondLoupe.sol";
import {ICreate3Factory} from "@crane/contracts/interfaces/ICreate3Factory.sol";
import {IDiamondPackageCallBackFactory} from "@crane/contracts/interfaces/IDiamondPackageCallBackFactory.sol";
import {IOperable} from "@crane/contracts/interfaces/IOperable.sol";
import {InitDevService} from "@crane/contracts/InitDevService.sol";
import {BetterTest} from "@crane/contracts/test/BetterTest.sol";
import {CraneTest} from "@crane/contracts/test/CraneTest.sol";
import {Create3Factory} from "@crane/contracts/factories/create3/Create3Factory.sol";
import {
    IDiamondPackageCallBackFactoryInit,
    DiamondPackageCallBackFactory
} from "@crane/contracts/factories/diamondPkg/DiamondPackageCallBackFactory.sol";
import {BetterEfficientHashLib} from "@crane/contracts/utils/BetterEfficientHashLib.sol";
import {GreeterFacet} from "@crane/contracts/test/stubs/greeter/GreeterFacet.sol";
import {IGreeterDFPkg, GreeterDFPkg} from "@crane/contracts/test/stubs/greeter/GreeterDFPkg.sol";
import {IGreeter} from "@crane/contracts/test/stubs/greeter/IGreeter.sol";
import {Handler_IFacetRegistry} from "@crane/contracts/registries/facet/Handler_IFacetRegistry.sol";
import {IFacetRegistry} from "@crane/contracts/interfaces/IFacetRegistry.sol";
import {
    Handler_IDiamondFactoryPackageRegistry
} from "@crane/contracts/registries/package/Handler_IDiamondFactoryPackageRegistry.sol";
import {IDiamondFactoryPackageRegistry} from "@crane/contracts/interfaces/IDiamondFactoryPackageRegistry.sol";
import {Handler_ERC165} from "@crane/contracts/introspection/ERC165/Handler_ERC165.sol";
import {Hanlder_IDiamondLoupe} from "@crane/contracts/introspection/ERC2535/Hanlder_IDiamondLoupe.sol";

import {ICreate3FactoryProxy} from "@crane/contracts/interfaces/proxies/ICreate3FactoryProxy.sol";

// contract InitDevServiceGasReporter {
//     function initEnv(address owner)
//         external
//         returns (ICreate3FactoryProxy factory, IDiamondPackageCallBackFactory diamondFactory)
//     {
//         return InitDevService.initEnv(owner);
//     }

//     function initFactory(address owner, bytes32 salt) external returns (ICreate3FactoryProxy factory) {
//         return InitDevService.initFactory(owner, salt);
//     }

//     function initDiamondFactory(ICreate3FactoryProxy factory)
//         external
//         returns (IDiamondPackageCallBackFactory diamondFactory)
//     {
//         return InitDevService.initDiamondFactory(factory);
//     }
// }

contract DevEnvSmokeTest is CraneTest {
    using BetterEfficientHashLib for bytes;

    event TestEvent(string message);

    bytes32 eventSelector;
        
    // InitDevServiceGasReporter initDevServiceGasReporter;

    Handler_ERC165 erc165Handler;
    // Hanlder_IDiamondLoupe erc2535Handler;
    Handler_IFacetRegistry facetRegistryHandler;
    Handler_IDiamondFactoryPackageRegistry dfpkgRegistryHandler;

    GreeterFacet greeterFacet;
    GreeterDFPkg greaterDFPkg;
    IGreeter greeter;
    string initMessage = "Hello, World!";
    string controlMessage = "Hello again, World!";

    function setUp() public virtual override {

        eventSelector = DevEnvSmokeTest.TestEvent.selector;
        BetterTest.setUp();
        erc165Handler = new Handler_ERC165();
        // erc2535Handler= new Hanlder_IDiamondLoupe();
        facetRegistryHandler = new Handler_IFacetRegistry();
        dfpkgRegistryHandler = new Handler_IDiamondFactoryPackageRegistry();
        // initDevServiceGasReporter = new InitDevServiceGasReporter();
        // create3Factory = InitDevService.initFactory(address(this), keccak256(abi.encode(address(this))));
        // erc165Handler.recInvariant_supportsInterface(
        //     IERC165(address(create3Factory)),
        //     type(IERC165).interfaceId
        // );
        // erc2535Handler.recInvariant_IDiamondLoupe(IDiamondLoupe(address(create3Factory)));
        // IOperable(address(create3Factory)).setOperator(address(initDevServiceGasReporter), true);
        // diamondFactory = InitDevService.initDiamondFactory(create3Factory);
        (create3Factory, diamondFactory) = InitDevService.initEnv(address(this));
        greeterFacet = GreeterFacet(
            address(
                create3Factory.deployFacet(type(GreeterFacet).creationCode, abi.encode(type(GreeterFacet).name)._hash())
            )
        );
        facetRegistryHandler.recInvariant_IFacet(IFacetRegistry(address(create3Factory)), greeterFacet);
        IGreeterDFPkg.PkgInit memory pkgInit =
            IGreeterDFPkg.PkgInit({diamondPackageFactory: diamondFactory, greeterFacet: greeterFacet});
        greaterDFPkg = GreeterDFPkg(
            address(
                create3Factory.deployPackageWithArgs(
                    type(GreeterDFPkg).creationCode, abi.encode(pkgInit), abi.encode(type(GreeterDFPkg).name)._hash()
                )
            )
        );
        dfpkgRegistryHandler.recInvariant_IDiamondFactoryPackage(
            IDiamondFactoryPackageRegistry(address(create3Factory)), greaterDFPkg
        );
        greeter = greaterDFPkg.deployGreeter(initMessage);
        vm.label(address(greeter), "Greeter");
        erc165Handler.recInvariant_supportsInterface(IERC165(address(greeter)), greaterDFPkg.facetInterfaces());
        // erc2535Handler.recInvariant_IDiamondLoupe(IDiamondLoupe(address(greeter)));
    }

    function testSizes() public {
        assertLe(
            type(Create3Factory).creationCode.length,
            CONTRACT_INIT_SIZE_LIMIT,
            "CREATE3 Factory exceeds init code size limit."
        );
        ICreate3FactoryProxy create3FactoryTemp =
            InitDevService.initFactory(address(this), keccak256(abi.encode(address(0))));
        assertLe(
            address(create3FactoryTemp).code.length,
            CONTRACT_SIZE_LIMIT,
            "CREATE3 Factory exceeds init code size limit."
        );
        console.log("CREATE3 Factory init size: ", type(Create3Factory).creationCode.length);
        console.log("CREATE3 Factory deployed size: ", address(create3FactoryTemp).code.length);
        assertLe(
            type(DiamondPackageCallBackFactory).creationCode.length,
            CONTRACT_INIT_SIZE_LIMIT,
            "Diamond Package CallBack Factory exceeds init code size limit."
        );
        IDiamondPackageCallBackFactory diamondFactoryTemp = InitDevService.initDiamondFactory(create3FactoryTemp);
        assertLe(
            address(diamondFactoryTemp).code.length,
            CONTRACT_SIZE_LIMIT,
            "Diamond Package CallBack Factory exceeds init code size limit."
        );
        console.log(
            "Diamond Package CallBack Factory init size: ", type(DiamondPackageCallBackFactory).creationCode.length
        );
        console.log("Diamond Package CallBack Factory deployed size: ", address(diamondFactoryTemp).code.length);
    }

    function testGreeter() public {
        assertEq(greeter.getMessage(), initMessage);
        greeter.setMessage(controlMessage);
        assertEq(greeter.getMessage(), controlMessage);
    }

    function test_greeter_IERC165() public view {
        erc165Handler.assert_IERC165(IERC165(address(greeter)));
    }

    // function test_greeter_IDiamondLoupe() public {
    //     erc2535Handler.assert_IDiamondLoupe(IDiamondLoupe(address(greeter)));
    // }

    // function test_facetRegistry_IERC165() public view {
    //     erc165Handler.assert_IERC165(IERC165(address(create3Factory)));
    // }

    // function test_greeter_IDiamondLoupe() public {
    //     erc2535Handler.assert_IDiamondLoupe(IDiamondLoupe(address(create3Factory)));
    // }

    function testIFacetRegistry() public {
        facetRegistryHandler.assert_IFacetRegistry(IFacetRegistry(address(create3Factory)));
    }

    function testIDiamondFactoryPackageRegistry() public {
        dfpkgRegistryHandler.assert_IDiamondFactoryPackageRegistry(
            IDiamondFactoryPackageRegistry(address(create3Factory))
        );
    }
}
