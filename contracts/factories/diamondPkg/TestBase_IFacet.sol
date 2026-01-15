// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

/* -------------------------------------------------------------------------- */
/*                                   Foundry                                  */
/* -------------------------------------------------------------------------- */

/// forge-lint: disable-next-line(unaliased-plain-import)
import "forge-std/Test.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */
// import {Test_Crane} from "@crane/contracts/crane/test/Test_Crane.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {Behavior_IFacet} from "@crane/contracts/factories/diamondPkg/Behavior_IFacet.sol";

// import {Behavior_IFacet} from "@crane/contracts/crane/test/behaviors/Behavior_IFacet.sol";

/**
 * @title TestBase_IFacet
 * @notice Abstract base contract for testing IFacet implementations
 * @dev Provides a standardized framework for testing facets by:
 *      1. Declaring expected interface IDs and function selectors via virtual functions
 *      2. Using Behavior_IFacet to validate actual vs expected values
 *      3. Requiring minimal implementation from inheriting test contracts
 *
 * @dev Usage:
 *      1. Inherit from this contract
 *      2. Implement the virtual functions to return expected values
 *      3. Set the `testFacet` variable in your setUp() function
 *      4. All test functions will automatically validate your facet
 */
abstract contract TestBase_IFacet is Test {
    IFacet internal testFacet;

    function setUp() public virtual {
        testFacet = facetTestInstance();
    }

    /* ========================================================================== */
    /*                           INTERFACE ID HELPERS                            */
    /* ========================================================================== */

    /**
     * @notice Computes an ERC165 interface ID from an array of function selectors
     * @dev Interface IDs are computed as the XOR of all function selectors in the interface.
     *      This follows the ERC165 specification for interface ID computation.
     * @param selectors The array of function selectors that comprise the interface
     * @return interfaceId The computed interface ID (XOR of all selectors)
     */
    function computeInterfaceId(bytes4[] memory selectors) public pure returns (bytes4 interfaceId) {
        for (uint256 i = 0; i < selectors.length; i++) {
            interfaceId ^= selectors[i];
        }
    }

    /**
     * @notice Verifies that an expected interface ID matches the XOR of its constituent selectors
     * @dev Use this helper to verify interface IDs are correctly declared.
     *      Pass in the selectors that should comprise the interface and the expected ID.
     * @param selectors The function selectors that comprise the interface
     * @param expectedInterfaceId The declared/expected interface ID to verify
     * @return valid True if the computed ID matches the expected ID
     */
    function verifyInterfaceId(bytes4[] memory selectors, bytes4 expectedInterfaceId) public pure returns (bool valid) {
        return computeInterfaceId(selectors) == expectedInterfaceId;
    }

    /* ========================================================================== */
    /*                              VIRTUAL FUNCTIONS                            */
    /* ========================================================================== */

    function facetTestInstance() public virtual returns (IFacet);

    function controlFacetName() public view virtual returns (string memory facetName);

    /**
     * @notice Returns the expected interface IDs that the facet should support
     * @dev Must be implemented by inheriting contracts
     * @return controlInterfaces Array of interface IDs (bytes4) the facet should expose
     */
    function controlFacetInterfaces() public view virtual returns (bytes4[] memory controlInterfaces);

    /**
     * @notice Returns the expected function selectors that the facet should expose
     * @dev Must be implemented by inheriting contracts
     * @return controlFuncs Array of function selectors (bytes4) the facet should expose
     */
    function controlFacetFuncs() public view virtual returns (bytes4[] memory controlFuncs);

    /* ========================================================================== */
    /*                              TEST FUNCTIONS                               */
    /* ========================================================================== */

    function test_IFacet_facetName() public view {
        assertTrue(Behavior_IFacet.areValid_IFacet_facetName(testFacet, controlFacetName(), testFacet.facetName()));
    }

    /**
     * @notice Tests that the facet returns the correct interface IDs
     * @dev Uses Behavior_IFacet's areValid_IFacet_facetInterfaces function
     *      First asserts length equality for clearer error messages
     */
    function test_IFacet_FacetInterfaces() public {
        bytes4[] memory expected = controlFacetInterfaces();
        bytes4[] memory actual = testFacet.facetInterfaces();

        assertEq(
            actual.length,
            expected.length,
            "Facet interfaces count mismatch - extra or missing declarations"
        );

        assertTrue(
            Behavior_IFacet.areValid_IFacet_facetInterfaces(testFacet, expected, actual),
            "Facet should return valid interface IDs"
        );
    }

    /**
     * @notice Tests that the facet returns the correct function selectors
     * @dev Uses Behavior_IFacet's areValid_IFacet_facetFuncs function
     *      First asserts length equality for clearer error messages
     */
    function test_IFacet_FacetFunctions() public {
        bytes4[] memory expected = controlFacetFuncs();
        bytes4[] memory actual = testFacet.facetFuncs();

        assertEq(
            actual.length,
            expected.length,
            "Facet function selectors count mismatch - extra or missing declarations"
        );

        assertTrue(
            Behavior_IFacet.areValid_IFacet_facetFuncs(testFacet, expected, actual),
            "Facet should return valid function selectors"
        );
    }

    /**
     * @notice Tests that facetMetadata() returns values consistent with individual getters
     * @dev Verifies that the aggregate function matches facetName(), facetInterfaces(), and facetFuncs()
     *      This ensures implementations don't have inconsistent return values between methods
     */
    function test_IFacet_FacetMetadata_Consistency() public {
        assertTrue(
            Behavior_IFacet.isValid_IFacet_facetMetadata_consistency(testFacet),
            "facetMetadata() must return values matching individual getter functions"
        );
    }

    /**
     * @notice Tests that the IFacet interface ID is correctly computed via XOR of selectors
     * @dev Verifies interface ID computation follows ERC165 specification.
     *      IFacet interface ID = keccak256("facetName()")[0:4] XOR
     *                            keccak256("facetInterfaces()")[0:4] XOR
     *                            keccak256("facetFuncs()")[0:4] XOR
     *                            keccak256("facetMetadata()")[0:4]
     */
    function test_IFacet_InterfaceId_Computation() public pure {
        // Build array of IFacet function selectors
        bytes4[] memory ifacetSelectors = new bytes4[](4);
        ifacetSelectors[0] = IFacet.facetName.selector;       // 0x5b6f4d01
        ifacetSelectors[1] = IFacet.facetInterfaces.selector; // 0x2ea80826
        ifacetSelectors[2] = IFacet.facetFuncs.selector;      // 0x574a4cff
        ifacetSelectors[3] = IFacet.facetMetadata.selector;   // 0xf10d7a75

        // Compute expected interface ID via XOR
        bytes4 computedId = computeInterfaceId(ifacetSelectors);

        // Verify against Solidity's built-in interface ID computation
        bytes4 expectedId = type(IFacet).interfaceId;

        assertEq(
            computedId,
            expectedId,
            "Computed IFacet interface ID must match type(IFacet).interfaceId"
        );
    }
}
