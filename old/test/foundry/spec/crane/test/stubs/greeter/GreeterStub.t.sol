// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {Test_Crane} from "contracts/crane/test/Test_Crane.sol";
import {IGreeter} from "contracts/crane/test/stubs/greeter/IGreeter.sol";
import {GreeterStub} from "contracts/crane/test/stubs/greeter/GreeterStub.sol";
// import { GreeterFacetDiamondFactoryPackage } from "contracts/crane/test/stubs/greeter/GreeterFacetDiamondFactoryPackage.sol";
import {IDiamondLoupe} from "contracts/crane/interfaces/IDiamondLoupe.sol";

// import { IDiamond } from "contracts/crane/interfaces/IDiamond.sol";

/**
 * @title GreeterStubTest
 * @dev Test that demonstrates proper Diamond proxy deployment using Package
 * This shows the correct pattern: Package provides configuration, DiamondFactory creates proxy
 */
contract GreeterStubTest is Test_Crane {
    // Test constants
    string constant INITIAL_MESSAGE = "Hello World!";
    string constant UPDATED_MESSAGE = "Hello Diamond!";

    // Test contracts
    GreeterStub public greeterStub;
    address public greeterProxy;

    function setUp() public override {
        super.setUp();

        // Deploy the simple stub contract for comparison
        greeterStub = new GreeterStub(INITIAL_MESSAGE);
        vm.label(address(greeterStub), "GreeterStub");

        // Deploy a Diamond proxy using the GreeterFacetDiamondFactoryPackage
        // This is the CORRECT way to deploy a proxy with a Package
        greeterProxy = diamondFactory()
            .deploy(
                greeterFacetDFPkg(), // Package provides configuration
                abi.encode(INITIAL_MESSAGE) // Initialization arguments
            );
        vm.label(greeterProxy, "GreeterDiamondProxy");
    }

    /**
     * @dev Test that GreeterStub works as expected (baseline)
     */
    function test_greeterStub_basicFunctionality() public {
        // Test initial message
        assertEq(greeterStub.getMessage(), INITIAL_MESSAGE, "GreeterStub should return initial message");

        // Test message update
        greeterStub.setMessage(UPDATED_MESSAGE);
        assertEq(greeterStub.getMessage(), UPDATED_MESSAGE, "GreeterStub should return updated message");
    }

    /**
     * @dev Test that Diamond proxy is created successfully
     */
    function test_diamondProxy_deployment() public {
        // Verify proxy was created
        assertTrue(address(greeterProxy) != address(0), "Diamond proxy should be deployed");

        // Verify proxy is different from package
        assertTrue(greeterProxy != address(greeterFacetDFPkg()), "Proxy should be different address from Package");

        // Verify proxy has Diamond functionality
        IDiamondLoupe loupe = IDiamondLoupe(greeterProxy);
        IDiamondLoupe.Facet[] memory facets = loupe.facets();
        assertTrue(facets.length > 0, "Proxy should have facets configured");
    }

    /**
     * @dev Test that Diamond proxy implements IGreeter interface correctly
     */
    function test_diamondProxy_greeterFunctionality() public {
        // Cast proxy to IGreeter interface
        IGreeter greeterInterface = IGreeter(greeterProxy);

        // Test initial message
        assertEq(greeterInterface.getMessage(), INITIAL_MESSAGE, "Diamond proxy should return initial message");

        // Test message update
        greeterInterface.setMessage(UPDATED_MESSAGE);
        assertEq(greeterInterface.getMessage(), UPDATED_MESSAGE, "Diamond proxy should return updated message");
    }

    /**
     * @dev Test that Diamond proxy has correct facet configuration
     */
    function test_diamondProxy_facetConfiguration() public view {
        IDiamondLoupe loupe = IDiamondLoupe(greeterProxy);

        // Get expected function selectors from IGreeter
        bytes4[] memory expectedSelectors = new bytes4[](2);
        expectedSelectors[0] = IGreeter.getMessage.selector;
        expectedSelectors[1] = IGreeter.setMessage.selector;

        // Verify that the proxy has the expected function selectors
        for (uint256 i = 0; i < expectedSelectors.length; i++) {
            address facetAddress = loupe.facetAddress(expectedSelectors[i]);
            assertTrue(
                facetAddress != address(0),
                string.concat("Selector should be mapped to a facet: ", vm.toString(expectedSelectors[i]))
            );
        }

        // Verify proxy supports IGreeter interface
        bytes4[] memory supportedInterfaces =
            loupe.facetFunctionSelectors(loupe.facetAddress(IGreeter.getMessage.selector));
        assertTrue(supportedInterfaces.length >= 2, "Greeter facet should support at least 2 functions");
    }

    /**
     * @dev Test comparison between stub and Diamond proxy behavior
     */
    function test_stubVsProxy_behaviorEquivalence() public {
        IGreeter proxy = IGreeter(greeterProxy);

        // Both should start with same message
        assertEq(greeterStub.getMessage(), proxy.getMessage(), "Stub and proxy should have same initial message");

        // Update both with same message
        string memory newMessage = "Consistency Test";
        greeterStub.setMessage(newMessage);
        proxy.setMessage(newMessage);

        // Both should return same result
        assertEq(greeterStub.getMessage(), proxy.getMessage(), "Stub and proxy should behave identically");
    }

    /**
     * @dev Test that demonstrates the key difference: proxy uses Diamond pattern
     */
    function test_proxyAdvantages_diamondPattern() public view {
        IDiamondLoupe loupe = IDiamondLoupe(greeterProxy);

        // Diamond proxy has advanced introspection capabilities
        IDiamondLoupe.Facet[] memory facets = loupe.facets();
        assertTrue(facets.length > 0, "Diamond proxy should have introspectable facets");

        // Diamond proxy can be upgraded (though not demonstrated here)
        // Diamond proxy supports multiple interfaces through facets
        // Diamond proxy provides standardized introspection via IDiamondLoupe

        // These capabilities are NOT available in the simple stub:
        // The stub cannot be easily upgraded
        // The stub doesn't support standardized introspection
        // The stub cannot easily compose multiple interfaces
    }
}
