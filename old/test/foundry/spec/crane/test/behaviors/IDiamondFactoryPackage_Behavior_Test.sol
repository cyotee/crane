// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

// import { Test_Crane } from "contracts/crane/test/Test_Crane.sol";

// import "forge-std/Test.sol";
// import "contracts/crane/test/behavior/Behavior.sol";
// import "contracts/crane/factories/create2/callback/diamondPkg/behaviors/Behavior_IDiamondFactoryPackage.sol";
import {IDiamond} from "contracts/crane/interfaces/IDiamond.sol";
import {IDiamondFactoryPackage} from "contracts/crane/interfaces/IDiamondFactoryPackage.sol";
import {TestBase_IDiamondFactoryPackage} from "contracts/crane/test/bases/TestBase_IDiamondFactoryPackage.sol";

// Mock interfaces for testing
interface IDiamondFactoryPackage_Good {
    function func0() external;
    function func1() external;
}

interface IDiamondFactoryPackage_Bad {
    function funcBad() external;
}

// Good implementation stub
contract Behavior_Stub_IDiamondFactoryPackage_Good is IDiamondFactoryPackage_Good, IDiamondFactoryPackage {
    function func0() external {}
    function func1() external {}

    function facetInterfaces() public pure returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](1);
        interfaces[0] = type(IDiamondFactoryPackage_Good).interfaceId;
    }

    function facetCuts() public view returns (IDiamond.FacetCut[] memory cuts) {
        cuts = new IDiamond.FacetCut[](1);
        cuts[0] = IDiamond.FacetCut({
            facetAddress: address(this), action: IDiamond.FacetCutAction.Add, functionSelectors: new bytes4[](2)
        });
        cuts[0].functionSelectors[0] = IDiamondFactoryPackage_Good.func0.selector;
        cuts[0].functionSelectors[1] = IDiamondFactoryPackage_Good.func1.selector;
    }

    function diamondConfig() public view returns (DiamondConfig memory config) {
        config.facetCuts = facetCuts();

        config.interfaces = facetInterfaces();
    }

    function calcSalt(bytes memory pkgArgs) public pure returns (bytes32) {
        return keccak256(pkgArgs);
    }

    function processArgs(bytes memory pkgArgs) public pure returns (bytes memory) {
        return pkgArgs;
    }

    function updatePkg(
        address, // expectedProxy,
        bytes memory // pkgArgs
    )
        public
        virtual
        returns (bool)
    {
        return true;
    }

    function initAccount(bytes memory) public {}

    function postDeploy(address) public pure returns (bytes memory) {
        return "";
    }
}

// Bad implementation stub
contract Behavior_Stub_IDiamondFactoryPackage_Bad is IDiamondFactoryPackage_Bad, IDiamondFactoryPackage {
    function funcBad() external {}

    function facetInterfaces() public pure returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](1);
        interfaces[0] = type(IDiamondFactoryPackage_Bad).interfaceId;
    }

    function facetCuts() public view returns (IDiamond.FacetCut[] memory cuts) {
        cuts = new IDiamond.FacetCut[](1);
        cuts[0] = IDiamond.FacetCut({
            facetAddress: address(this), action: IDiamond.FacetCutAction.Add, functionSelectors: new bytes4[](1)
        });
        cuts[0].functionSelectors[0] = IDiamondFactoryPackage_Bad.funcBad.selector;
    }

    function diamondConfig() public view returns (DiamondConfig memory config) {
        config.facetCuts = facetCuts();

        config.interfaces = facetInterfaces();
    }

    function calcSalt(bytes memory) external pure returns (bytes32) {
        return bytes32(0);
    }

    function processArgs(bytes memory) external pure returns (bytes memory) {
        return "";
    }

    function updatePkg(
        address, // expectedProxy,
        bytes memory // pkgArgs
    )
        public
        virtual
        returns (bool)
    {
        return true;
    }

    function initAccount(bytes memory) external {}

    function postDeploy(address) external pure returns (bytes memory) {
        return "";
    }
}

contract MockDiamondFactoryPackage is IDiamondFactoryPackage {
    bytes4[] private _interfaces;

    constructor(bytes4[] memory interfaces_) {
        _interfaces = interfaces_;
    }

    function facetInterfaces() external view returns (bytes4[] memory) {
        return _interfaces;
    }

    function facetCuts() external pure returns (IDiamond.FacetCut[] memory) {
        return new IDiamond.FacetCut[](0);
    }

    function diamondConfig() external pure returns (DiamondConfig memory) {
        return DiamondConfig({facetCuts: new IDiamond.FacetCut[](0), interfaces: new bytes4[](0)});
    }

    function calcSalt(bytes memory) external pure returns (bytes32) {
        return bytes32(0);
    }

    function processArgs(bytes memory args_) external pure returns (bytes memory) {
        return args_;
    }

    function updatePkg(
        address, // expectedProxy,
        bytes memory // pkgArgs
    )
        public
        virtual
        returns (bool)
    {
        return true;
    }

    function initAccount(bytes memory) external {}

    function postDeploy(address) external pure returns (bytes memory) {
        return "";
    }
}

contract Behavior_IDiamondFactoryPackage_Test is TestBase_IDiamondFactoryPackage {
    // Behavior_IDiamondFactoryPackage private _behavior;

    Behavior_Stub_IDiamondFactoryPackage_Good internal _goodPackage;
    Behavior_Stub_IDiamondFactoryPackage_Bad internal _badPackage;

    function goodPackage() public returns (IDiamondFactoryPackage) {
        if (address(_goodPackage) == address(0)) {
            _goodPackage = new Behavior_Stub_IDiamondFactoryPackage_Good();
            declareAddr(address(_goodPackage), "Behavior_Stub_IDiamondFactoryPackage_Good");
        }
        return _goodPackage;
    }

    function badPackage() public returns (IDiamondFactoryPackage) {
        if (address(_badPackage) == address(0)) {
            _badPackage = new Behavior_Stub_IDiamondFactoryPackage_Bad();
            declareAddr(address(_badPackage), "Behavior_Stub_IDiamondFactoryPackage_Bad");
        }
        return _badPackage;
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function IDiamondFactoryPackage_control_facetInterfaces() public pure virtual returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](1);
        interfaces[0] = type(IDiamondFactoryPackage_Good).interfaceId;
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function IDiamondFactoryPackage_control_facetCuts() public virtual returns (IDiamond.FacetCut[] memory cuts) {
        cuts = new IDiamond.FacetCut[](1);
        cuts[0] = IDiamond.FacetCut({
            facetAddress: address(goodPackage()),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: new bytes4[](2)
        });
        cuts[0].functionSelectors[0] = IDiamondFactoryPackage_Good.func0.selector;
        cuts[0].functionSelectors[1] = IDiamondFactoryPackage_Good.func1.selector;
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function IDiamondFactoryPackage_control_diamondConfig()
        public
        returns (IDiamondFactoryPackage.DiamondConfig memory config)
    {
        config.facetCuts = IDiamondFactoryPackage_control_facetCuts();

        config.interfaces = IDiamondFactoryPackage_control_facetInterfaces();
    }

    /* ---------------------------------------------------------------------- */
    /*                                  SetUp                                 */
    /* ---------------------------------------------------------------------- */

    function setUp() public virtual override {
        goodPackage();
        badPackage();
    }

    /* ---------------------------------------------------------------------- */
    /*                                  Tests                                 */
    /* ---------------------------------------------------------------------- */

    // Test facetInterfaces
    /// forge-lint: disable-next-line(mixed-case-function)
    function test_Behavior_IDiamondFactoryPackage_areValid_facetInterfaces_goodPackage() public {
        assert(
            areValid_IDiamondFactoryPackage_facetInterfaces(
                goodPackage(), IDiamondFactoryPackage_control_facetInterfaces(), goodPackage().facetInterfaces()
            )
        );
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function test_Behavior_IDiamondFactoryPackage_areValid_facetInterfaces_badPackage() public {
        assertFalse(
            areValid_IDiamondFactoryPackage_facetInterfaces(
                badPackage(), IDiamondFactoryPackage_control_facetInterfaces(), badPackage().facetInterfaces()
            )
        );
    }

    // Test facetCuts
    /// forge-lint: disable-next-line(mixed-case-function)
    function test_Behavior_IDiamondFactoryPackage_areValid_facetCuts_goodPackage() public {
        assert(
            areValid_IDiamondLoupe_facetCuts(
                goodPackage(), IDiamondFactoryPackage_control_facetCuts(), goodPackage().facetCuts()
            )
        );
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function test_Behavior_IDiamondFactoryPackage_areValid_facetCuts_badPackage() public {
        assertFalse(
            areValid_IDiamondLoupe_facetCuts(
                badPackage(), IDiamondFactoryPackage_control_facetCuts(), badPackage().facetCuts()
            )
        );
    }

    // Test diamondConfig
    /// forge-lint: disable-next-line(mixed-case-function)
    function test_Behavior_IDiamondFactoryPackage_areValid_diamondConfig_goodPackage() public {
        assert(
            areValid_IDiamondFactoryPackage_diamondConfig(
                goodPackage(), IDiamondFactoryPackage_control_diamondConfig(), goodPackage().diamondConfig()
            )
        );
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function test_Behavior_IDiamondFactoryPackage_areValid_diamondConfig_badPackage() public {
        assertFalse(
            areValid_IDiamondFactoryPackage_diamondConfig(
                badPackage(), IDiamondFactoryPackage_control_diamondConfig(), badPackage().diamondConfig()
            )
        );
    }

    // Test calcSalt
    /// forge-lint: disable-next-line(mixed-case-function)
    function test_Behavior_IDiamondFactoryPackage_areValid_calcSalt_goodPackage() public {
        bytes memory testArgs = abi.encode("test");
        bytes32 expectedSalt = keccak256(testArgs);

        assert(
            areValid_IDiamondFactoryPackage_calcSalt(
                vm.getLabel(address(goodPackage())), expectedSalt, goodPackage().calcSalt(testArgs)
            )
        );
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function test_Behavior_IDiamondFactoryPackage_areValid_calcSalt_badPackage() public {
        bytes memory testArgs = abi.encode("test");
        bytes32 expectedSalt = keccak256(testArgs);

        assertFalse(
            areValid_IDiamondFactoryPackage_calcSalt(
                vm.getLabel(address(badPackage())), expectedSalt, badPackage().calcSalt(testArgs)
            )
        );
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function test_facetInterfaces_ValidatesSingleInterface() public {
        // Setup
        bytes4[] memory expectedInterfaces = new bytes4[](1);
        expectedInterfaces[0] = IDiamondFactoryPackage.facetInterfaces.selector;

        MockDiamondFactoryPackage subject = new MockDiamondFactoryPackage(expectedInterfaces);
        vm.label(address(subject), "MockDiamondFactoryPackage");

        // Action & Verification
        expect_IDiamondFactoryPackage_facetInterfaces(subject, expectedInterfaces);
        assertTrue(hasValid_IDiamondFactoryPackage_facetInterfaces(subject), "Should validate single interface");
    }

    // Test processArgs
    /// forge-lint: disable-next-line(mixed-case-function)
    function test_Behavior_IDiamondFactoryPackage_areValid_processArgs_goodPackage() public {
        bytes memory testArgs = abi.encode("test");

        assert(
            areValid_IDiamondFactoryPackage_processArgs(goodPackage(), testArgs, goodPackage().processArgs(testArgs))
        );
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function test_Behavior_IDiamondFactoryPackage_areValid_processArgs_badPackage() public {
        bytes memory testArgs = abi.encode("test");

        assertFalse(
            areValid_IDiamondFactoryPackage_processArgs(badPackage(), testArgs, badPackage().processArgs(testArgs))
        );
    }

    // Test expectation-based validation
    // functest_Behavior_IDiamondFactoryPackage_hasValid_diamondConfig_goodPackage

    /// forge-lint: disable-next-line(mixed-case-function)
    function test_Behavior_IDiamondFactoryPackage_hasValid_diamondConfig_badPackage() public {
        IDiamondFactoryPackage.DiamondConfig memory expectedConfig;
        expectedConfig.facetCuts = IDiamondFactoryPackage_control_facetCuts();
        expectedConfig.facetCuts[0].facetAddress = address(badPackage());
        expectedConfig.interfaces = IDiamondFactoryPackage_control_facetInterfaces();

        // Set expectations
        expect_IDiamondFactoryPackage_facetInterfaces(badPackage(), expectedConfig.interfaces);

        assertFalse(hasValid_IDiamondFactoryPackage_diamondConfig(badPackage()));
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function test_facetInterfaces_ValidatesMultipleInterfaces() public {
        // Setup
        bytes4[] memory expectedInterfaces = new bytes4[](3);
        expectedInterfaces[0] = IDiamondFactoryPackage.facetInterfaces.selector;
        expectedInterfaces[1] = IDiamondFactoryPackage.facetCuts.selector;
        expectedInterfaces[2] = IDiamondFactoryPackage.diamondConfig.selector;

        MockDiamondFactoryPackage subject = new MockDiamondFactoryPackage(expectedInterfaces);
        vm.label(address(subject), "MockDiamondFactoryPackage");

        // Action & Verification
        expect_IDiamondFactoryPackage_facetInterfaces(subject, expectedInterfaces);
        assertTrue(hasValid_IDiamondFactoryPackage_facetInterfaces(subject), "Should validate multiple interfaces");
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function test_facetInterfaces_DetectsMismatch() public {
        // Setup
        bytes4[] memory actualInterfaces = new bytes4[](2);
        actualInterfaces[0] = IDiamondFactoryPackage.facetInterfaces.selector;
        actualInterfaces[1] = IDiamondFactoryPackage.facetCuts.selector;

        bytes4[] memory expectedInterfaces = new bytes4[](2);
        expectedInterfaces[0] = IDiamondFactoryPackage.facetInterfaces.selector;
        expectedInterfaces[1] = IDiamondFactoryPackage.diamondConfig.selector;

        MockDiamondFactoryPackage subject = new MockDiamondFactoryPackage(actualInterfaces);
        vm.label(address(subject), "MockDiamondFactoryPackage");

        // Action & Verification
        expect_IDiamondFactoryPackage_facetInterfaces(subject, expectedInterfaces);
        assertFalse(hasValid_IDiamondFactoryPackage_facetInterfaces(subject), "Should detect interface mismatch");
    }

    // function test_facetCuts_ValidatesSingleFacet() public {
    //     // Setup
    //     bytes4[] memory selectors = new bytes4[](2);
    //     selectors[0] = IDiamondFactoryPackage.facetInterfaces.selector;
    //     selectors[1] = IDiamondFactoryPackage.facetCuts.selector;

    //     IDiamond.FacetCut[] memory expectedCuts = new IDiamond.FacetCut[](1);
    //     expectedCuts[0] = IDiamond.FacetCut({
    //         facetAddress: address(this),
    //         action: IDiamond.FacetCutAction.Add,
    //         functionSelectors: selectors
    //     });

    //     MockDiamondFactoryPackageWithCuts subject = new MockDiamondFactoryPackageWithCuts(expectedCuts);
    //     vm.label(address(subject), "MockDiamondFactoryPackage");

    //     // Action & Verification
    //     assertTrue(
    //        areValid_IDiamondLoupe_facetCuts(subject, expectedCuts, subject.facetCuts()),
    //         "Should validate single facet cut"
    //     );
    // }

    // function test_facetCuts_DetectsMismatch() public {
    //     // Setup - Create expected cuts
    //     bytes4[] memory expectedSelectors = new bytes4[](2);
    //     expectedSelectors[0] = IDiamondFactoryPackage.facetInterfaces.selector;
    //     expectedSelectors[1] = IDiamondFactoryPackage.facetCuts.selector;

    //     IDiamond.FacetCut[] memory expectedCuts = new IDiamond.FacetCut[](1);
    //     expectedCuts[0] = IDiamond.FacetCut({
    //         facetAddress: address(this),
    //         action: IDiamond.FacetCutAction.Add,
    //         functionSelectors: expectedSelectors
    //     });

    //     // Setup - Create actual cuts with different selectors
    //     bytes4[] memory actualSelectors = new bytes4[](2);
    //     actualSelectors[0] = IDiamondFactoryPackage.facetInterfaces.selector;
    //     actualSelectors[1] = IDiamondFactoryPackage.diamondConfig.selector;

    //     IDiamond.FacetCut[] memory actualCuts = new IDiamond.FacetCut[](1);
    //     actualCuts[0] = IDiamond.FacetCut({
    //         facetAddress: address(this),
    //         action: IDiamond.FacetCutAction.Add,
    //         functionSelectors: actualSelectors
    //     });

    //     MockDiamondFactoryPackageWithCuts subject = new MockDiamondFactoryPackageWithCuts(actualCuts);
    //     vm.label(address(subject), "MockDiamondFactoryPackage");

    //     // Action & Verification
    //     assertFalse(
    //        areValid_IDiamondLoupe_facetCuts(subject, expectedCuts, subject.facetCuts()),
    //         "Should detect facet cut mismatch"
    //     );
    // }

    // function test_diamondConfig_ValidatesValidConfig() public {
    //     // Setup - Create facet cuts
    //     bytes4[] memory selectors = new bytes4[](2);
    //     selectors[0] = IDiamondFactoryPackage.facetInterfaces.selector;
    //     selectors[1] = IDiamondFactoryPackage.facetCuts.selector;

    //     IDiamond.FacetCut[] memory expectedCuts = new IDiamond.FacetCut[](1);
    //     expectedCuts[0] = IDiamond.FacetCut({
    //         facetAddress: address(this),
    //         action: IDiamond.FacetCutAction.Add,
    //         functionSelectors: selectors
    //     });

    //     // Setup - Create interfaces
    //     bytes4[] memory expectedInterfaces = new bytes4[](2);
    //     expectedInterfaces[0] = IDiamondFactoryPackage.facetInterfaces.selector;
    //     expectedInterfaces[1] = IDiamondFactoryPackage.facetCuts.selector;

    //     // Setup - Create expected config
    //     IDiamondFactoryPackage.DiamondConfig memory expectedConfig = IDiamondFactoryPackage.DiamondConfig({
    //         facetCuts: expectedCuts,
    //         interfaces: expectedInterfaces
    //     });

    //     MockDiamondFactoryPackageWithConfig subject = new MockDiamondFactoryPackageWithConfig(expectedConfig);
    //     vm.label(address(subject), "MockDiamondFactoryPackage");

    //     // Action & Verification
    //    expect_IDiamondFactoryPackage_diamondConfig(subject, expectedConfig);
    //     assertTrue(
    //        hasValid_IDiamondFactoryPackage_diamondConfig(subject),
    //         "Should validate valid diamond config"
    //     );
    // }

    // function test_diamondConfig_DetectsMismatch() public {
    //     // Setup - Create expected config
    //     bytes4[] memory expectedSelectors = new bytes4[](2);
    //     expectedSelectors[0] = IDiamondFactoryPackage.facetInterfaces.selector;
    //     expectedSelectors[1] = IDiamondFactoryPackage.facetCuts.selector;

    //     IDiamond.FacetCut[] memory expectedCuts = new IDiamond.FacetCut[](1);
    //     expectedCuts[0] = IDiamond.FacetCut({
    //         facetAddress: address(this),
    //         action: IDiamond.FacetCutAction.Add,
    //         functionSelectors: expectedSelectors
    //     });

    //     bytes4[] memory expectedInterfaces = new bytes4[](2);
    //     expectedInterfaces[0] = IDiamondFactoryPackage.facetInterfaces.selector;
    //     expectedInterfaces[1] = IDiamondFactoryPackage.facetCuts.selector;

    //     IDiamondFactoryPackage.DiamondConfig memory expectedConfig = IDiamondFactoryPackage.DiamondConfig({
    //         facetCuts: expectedCuts,
    //         interfaces: expectedInterfaces
    //     });

    //     // Setup - Create actual config with different selectors
    //     bytes4[] memory actualSelectors = new bytes4[](2);
    //     actualSelectors[0] = IDiamondFactoryPackage.facetInterfaces.selector;
    //     actualSelectors[1] = IDiamondFactoryPackage.diamondConfig.selector;

    //     IDiamond.FacetCut[] memory actualCuts = new IDiamond.FacetCut[](1);
    //     actualCuts[0] = IDiamond.FacetCut({
    //         facetAddress: address(this),
    //         action: IDiamond.FacetCutAction.Add,
    //         functionSelectors: actualSelectors
    //     });

    //     IDiamondFactoryPackage.DiamondConfig memory actualConfig = IDiamondFactoryPackage.DiamondConfig({
    //         facetCuts: actualCuts,
    //         interfaces: actualSelectors
    //     });

    //     MockDiamondFactoryPackageWithConfig subject = new MockDiamondFactoryPackageWithConfig(actualConfig);
    //     vm.label(address(subject), "MockDiamondFactoryPackage");

    //     // Action & Verification
    //    expect_IDiamondFactoryPackage_diamondConfig(subject, expectedConfig);
    //     assertFalse(
    //        hasValid_IDiamondFactoryPackage_diamondConfig(subject),
    //         "Should detect diamond config mismatch"
    //     );
    // }
}

// contract MockDiamondFactoryPackageWithCuts is IDiamondFactoryPackage {
//     bytes4[] private _interfaces;
//     IDiamond.FacetCut[] private _cuts;

//     constructor(IDiamond.FacetCut[] memory cuts_) {
//         _cuts = cuts_;
//     }

//     function facetInterfaces() external view returns (bytes4[] memory) {
//         return _interfaces;
//     }

//     function facetCuts() external view returns (IDiamond.FacetCut[] memory) {
//         return _cuts;
//     }

//     function diamondConfig() external view returns (DiamondConfig memory) {
//         return DiamondConfig({
//             facetCuts: _cuts,
//             interfaces: _interfaces
//         });
//     }

//     function calcSalt(bytes memory) external view returns (bytes32) {
//         return bytes32(0);
//     }

//     function processArgs(bytes memory args_) external returns (bytes memory) {
//         return args_;
//     }

//     function initAccount(bytes memory) external {
//     }

//     function postDeploy(address) external returns (bytes memory) {
//         return "";
//     }
// }

// contract MockDiamondFactoryPackageWithConfig is IDiamondFactoryPackage {
//     DiamondConfig private _config;

//     constructor(DiamondConfig memory config_) {
//         _config = config_;
//     }

//     function facetInterfaces() external view returns (bytes4[] memory) {
//         return _config.interfaces;
//     }

//     function facetCuts() external view returns (IDiamond.FacetCut[] memory) {
//         return _config.facetCuts;
//     }

//     function diamondConfig() external view returns (DiamondConfig memory) {
//         return _config;
//     }

//     function calcSalt(bytes memory) external pure returns (bytes32) {
//         return bytes32(0);
//     }

//     function processArgs(bytes memory args_) external pure returns (bytes memory) {
//         return args_;
//     }

//     function initAccount(bytes memory) external pure {
//     }

//     function postDeploy(address) external pure returns (bytes memory) {
//         return "";
//     }
// }
