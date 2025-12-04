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
     */
    function test_IFacet_FacetInterfaces() public {
        assertTrue(
            Behavior_IFacet.areValid_IFacet_facetInterfaces(
                testFacet, controlFacetInterfaces(), testFacet.facetInterfaces()
            ),
            "Facet should return valid interface IDs"
        );
    }

    /**
     * @notice Tests that the facet returns the correct function selectors
     * @dev Uses Behavior_IFacet's areValid_IFacet_facetFuncs function
     */
    function test_IFacet_FacetFunctions() public {
        assertTrue(
            Behavior_IFacet.areValid_IFacet_facetFuncs(testFacet, controlFacetFuncs(), testFacet.facetFuncs()),
            "Facet should return valid function selectors"
        );
    }
}
