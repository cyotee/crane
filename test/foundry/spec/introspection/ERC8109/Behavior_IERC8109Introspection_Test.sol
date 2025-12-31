// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                   Foundry                                  */
/* -------------------------------------------------------------------------- */

import {Test} from "forge-std/Test.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {IERC8109Introspection} from "@crane/contracts/introspection/ERC8109/IERC8109Introspection.sol";
import {Behavior_IERC8109Introspection} from "@crane/contracts/introspection/ERC8109/Behavior_IERC8109Introspection.sol";

/* -------------------------------------------------------------------------- */
/*                                 Stub Facets                                */
/* -------------------------------------------------------------------------- */

contract Stub_FacetA {
    function funcA1() external pure returns (uint256) {
        return 1;
    }

    function funcA2() external pure returns (uint256) {
        return 2;
    }
}

contract Stub_FacetB {
    function funcB1() external pure returns (uint256) {
        return 3;
    }
}

/* -------------------------------------------------------------------------- */
/*                              Stub Implementations                          */
/* -------------------------------------------------------------------------- */

/// @notice Basic implementation with correct mappings
contract Stub_ERC8109_Valid is IERC8109Introspection {
    address internal immutable FACET_A;
    address internal immutable FACET_B;

    constructor(address facetA_, address facetB_) {
        FACET_A = facetA_;
        FACET_B = facetB_;
    }

    function facetAddress(bytes4 selector) external view override returns (address) {
        if (selector == Stub_FacetA.funcA1.selector) return FACET_A;
        if (selector == Stub_FacetA.funcA2.selector) return FACET_A;
        if (selector == Stub_FacetB.funcB1.selector) return FACET_B;
        return address(0);
    }

    function functionFacetPairs() external view override returns (FunctionFacetPair[] memory pairs) {
        pairs = new FunctionFacetPair[](3);
        pairs[0] = FunctionFacetPair({selector: Stub_FacetA.funcA1.selector, facet: FACET_A});
        pairs[1] = FunctionFacetPair({selector: Stub_FacetA.funcA2.selector, facet: FACET_A});
        pairs[2] = FunctionFacetPair({selector: Stub_FacetB.funcB1.selector, facet: FACET_B});
    }
}

/// @notice Implementation with missing selector in functionFacetPairs
contract Stub_ERC8109_MissingPair is IERC8109Introspection {
    address internal immutable FACET_A;
    address internal immutable FACET_B;

    constructor(address facetA_, address facetB_) {
        FACET_A = facetA_;
        FACET_B = facetB_;
    }

    function facetAddress(bytes4 selector) external view override returns (address) {
        if (selector == Stub_FacetA.funcA1.selector) return FACET_A;
        if (selector == Stub_FacetA.funcA2.selector) return FACET_A;
        if (selector == Stub_FacetB.funcB1.selector) return FACET_B;
        return address(0);
    }

    function functionFacetPairs() external view override returns (FunctionFacetPair[] memory pairs) {
        // Missing funcA2
        pairs = new FunctionFacetPair[](2);
        pairs[0] = FunctionFacetPair({selector: Stub_FacetA.funcA1.selector, facet: FACET_A});
        pairs[1] = FunctionFacetPair({selector: Stub_FacetB.funcB1.selector, facet: FACET_B});
    }
}

/// @notice Implementation with wrong facet address for a selector
contract Stub_ERC8109_WrongFacet is IERC8109Introspection {
    address internal immutable FACET_A;
    address internal immutable FACET_B;

    constructor(address facetA_, address facetB_) {
        FACET_A = facetA_;
        FACET_B = facetB_;
    }

    function facetAddress(bytes4 selector) external view override returns (address) {
        if (selector == Stub_FacetA.funcA1.selector) return FACET_B; // Wrong facet!
        if (selector == Stub_FacetA.funcA2.selector) return FACET_A;
        if (selector == Stub_FacetB.funcB1.selector) return FACET_B;
        return address(0);
    }

    function functionFacetPairs() external view override returns (FunctionFacetPair[] memory pairs) {
        pairs = new FunctionFacetPair[](3);
        pairs[0] = FunctionFacetPair({selector: Stub_FacetA.funcA1.selector, facet: FACET_B}); // Wrong!
        pairs[1] = FunctionFacetPair({selector: Stub_FacetA.funcA2.selector, facet: FACET_A});
        pairs[2] = FunctionFacetPair({selector: Stub_FacetB.funcB1.selector, facet: FACET_B});
    }
}

/// @notice Implementation with extra pair in functionFacetPairs
contract Stub_ERC8109_ExtraPair is IERC8109Introspection {
    address internal immutable FACET_A;
    address internal immutable FACET_B;

    constructor(address facetA_, address facetB_) {
        FACET_A = facetA_;
        FACET_B = facetB_;
    }

    function facetAddress(bytes4 selector) external view override returns (address) {
        if (selector == Stub_FacetA.funcA1.selector) return FACET_A;
        if (selector == Stub_FacetA.funcA2.selector) return FACET_A;
        if (selector == Stub_FacetB.funcB1.selector) return FACET_B;
        if (selector == bytes4(0xcafebabe)) return FACET_A;
        return address(0);
    }

    function functionFacetPairs() external view override returns (FunctionFacetPair[] memory pairs) {
        pairs = new FunctionFacetPair[](4);
        pairs[0] = FunctionFacetPair({selector: Stub_FacetA.funcA1.selector, facet: FACET_A});
        pairs[1] = FunctionFacetPair({selector: Stub_FacetA.funcA2.selector, facet: FACET_A});
        pairs[2] = FunctionFacetPair({selector: Stub_FacetB.funcB1.selector, facet: FACET_B});
        pairs[3] = FunctionFacetPair({selector: bytes4(0xcafebabe), facet: FACET_A}); // Extra
    }
}

/// @notice Implementation with inconsistency between facetAddress and functionFacetPairs
contract Stub_ERC8109_Inconsistent is IERC8109Introspection {
    address internal immutable FACET_A;
    address internal immutable FACET_B;

    constructor(address facetA_, address facetB_) {
        FACET_A = facetA_;
        FACET_B = facetB_;
    }

    function facetAddress(bytes4 selector) external view override returns (address) {
        if (selector == Stub_FacetA.funcA1.selector) return FACET_A;
        if (selector == Stub_FacetA.funcA2.selector) return FACET_A;
        if (selector == Stub_FacetB.funcB1.selector) return FACET_B;
        return address(0);
    }

    function functionFacetPairs() external view override returns (FunctionFacetPair[] memory pairs) {
        pairs = new FunctionFacetPair[](3);
        pairs[0] = FunctionFacetPair({selector: Stub_FacetA.funcA1.selector, facet: FACET_A});
        // funcA2 points to wrong facet in pairs but correct in facetAddress
        pairs[1] = FunctionFacetPair({selector: Stub_FacetA.funcA2.selector, facet: FACET_B});
        pairs[2] = FunctionFacetPair({selector: Stub_FacetB.funcB1.selector, facet: FACET_B});
    }
}

/// @notice Empty implementation (no pairs)
contract Stub_ERC8109_Empty is IERC8109Introspection {
    function facetAddress(bytes4) external pure override returns (address) {
        return address(0);
    }

    function functionFacetPairs() external pure override returns (FunctionFacetPair[] memory pairs) {
        pairs = new FunctionFacetPair[](0);
    }
}

/* -------------------------------------------------------------------------- */
/*                                   Tests                                    */
/* -------------------------------------------------------------------------- */

contract Behavior_IERC8109Introspection_Test is Test {
    Stub_FacetA internal facetA;
    Stub_FacetB internal facetB;

    function setUp() public {
        facetA = new Stub_FacetA();
        facetB = new Stub_FacetB();
        vm.label(address(facetA), "FacetA");
        vm.label(address(facetB), "FacetB");
    }

    function _expectedPairs() internal view returns (IERC8109Introspection.FunctionFacetPair[] memory pairs) {
        pairs = new IERC8109Introspection.FunctionFacetPair[](3);
        pairs[0] = IERC8109Introspection.FunctionFacetPair({
            selector: Stub_FacetA.funcA1.selector,
            facet: address(facetA)
        });
        pairs[1] = IERC8109Introspection.FunctionFacetPair({
            selector: Stub_FacetA.funcA2.selector,
            facet: address(facetA)
        });
        pairs[2] = IERC8109Introspection.FunctionFacetPair({
            selector: Stub_FacetB.funcB1.selector,
            facet: address(facetB)
        });
    }

    /* -------------------------------------------------------------------------- */
    /*                            Positive Test Cases                             */
    /* -------------------------------------------------------------------------- */

    function test_Behavior_IERC8109Introspection_valid_facetAddress() public {
        Stub_ERC8109_Valid subject = new Stub_ERC8109_Valid(address(facetA), address(facetB));
        vm.label(address(subject), "ValidSubject");

        Behavior_IERC8109Introspection.expect_IERC8109Introspection(
            IERC8109Introspection(address(subject)),
            _expectedPairs()
        );

        bool isValid = Behavior_IERC8109Introspection.hasValid_IERC8109Introspection_facetAddress(
            IERC8109Introspection(address(subject))
        );

        assertTrue(isValid, "Valid implementation should pass facetAddress validation");
    }

    function test_Behavior_IERC8109Introspection_valid_functionFacetPairs() public {
        Stub_ERC8109_Valid subject = new Stub_ERC8109_Valid(address(facetA), address(facetB));
        vm.label(address(subject), "ValidSubject");

        Behavior_IERC8109Introspection.expect_IERC8109Introspection(
            IERC8109Introspection(address(subject)),
            _expectedPairs()
        );

        bool isValid = Behavior_IERC8109Introspection.hasValid_IERC8109Introspection_functionFacetPairs(
            IERC8109Introspection(address(subject))
        );

        assertTrue(isValid, "Valid implementation should pass functionFacetPairs validation");
    }

    function test_Behavior_IERC8109Introspection_valid_full() public {
        Stub_ERC8109_Valid subject = new Stub_ERC8109_Valid(address(facetA), address(facetB));
        vm.label(address(subject), "ValidSubject");

        Behavior_IERC8109Introspection.expect_IERC8109Introspection(
            IERC8109Introspection(address(subject)),
            _expectedPairs()
        );

        bool isValid = Behavior_IERC8109Introspection.hasValid_IERC8109Introspection(
            IERC8109Introspection(address(subject))
        );

        assertTrue(isValid, "Valid implementation should pass full validation");
    }

    function test_Behavior_IERC8109Introspection_areValid_facetAddress() public {
        Stub_ERC8109_Valid subject = new Stub_ERC8109_Valid(address(facetA), address(facetB));
        vm.label(address(subject), "ValidSubject");

        bool isValid = Behavior_IERC8109Introspection.areValid_IERC8109Introspection_facetAddress(
            IERC8109Introspection(address(subject)),
            Stub_FacetA.funcA1.selector,
            address(facetA),
            subject.facetAddress(Stub_FacetA.funcA1.selector)
        );

        assertTrue(isValid, "areValid should return true for matching facetAddress");
    }

    function test_Behavior_IERC8109Introspection_areValid_functionFacetPairs() public {
        Stub_ERC8109_Valid subject = new Stub_ERC8109_Valid(address(facetA), address(facetB));
        vm.label(address(subject), "ValidSubject");

        bool isValid = Behavior_IERC8109Introspection.areValid_IERC8109Introspection_functionFacetPairs(
            IERC8109Introspection(address(subject)),
            _expectedPairs(),
            subject.functionFacetPairs()
        );

        assertTrue(isValid, "areValid should return true for matching functionFacetPairs");
    }

    /* -------------------------------------------------------------------------- */
    /*                            Negative Test Cases                             */
    /* -------------------------------------------------------------------------- */

    function test_Behavior_IERC8109Introspection_invalid_missingPair() public {
        Stub_ERC8109_MissingPair subject = new Stub_ERC8109_MissingPair(address(facetA), address(facetB));
        vm.label(address(subject), "MissingPairSubject");

        Behavior_IERC8109Introspection.expect_IERC8109Introspection(
            IERC8109Introspection(address(subject)),
            _expectedPairs()
        );

        bool isValid = Behavior_IERC8109Introspection.hasValid_IERC8109Introspection_functionFacetPairs(
            IERC8109Introspection(address(subject))
        );

        assertFalse(isValid, "Implementation missing a pair should fail validation");
    }

    function test_Behavior_IERC8109Introspection_invalid_wrongFacet() public {
        Stub_ERC8109_WrongFacet subject = new Stub_ERC8109_WrongFacet(address(facetA), address(facetB));
        vm.label(address(subject), "WrongFacetSubject");

        Behavior_IERC8109Introspection.expect_IERC8109Introspection(
            IERC8109Introspection(address(subject)),
            _expectedPairs()
        );

        bool isValid = Behavior_IERC8109Introspection.hasValid_IERC8109Introspection_facetAddress(
            IERC8109Introspection(address(subject))
        );

        assertFalse(isValid, "Implementation with wrong facet should fail validation");
    }

    function test_Behavior_IERC8109Introspection_invalid_extraPair() public {
        Stub_ERC8109_ExtraPair subject = new Stub_ERC8109_ExtraPair(address(facetA), address(facetB));
        vm.label(address(subject), "ExtraPairSubject");

        Behavior_IERC8109Introspection.expect_IERC8109Introspection(
            IERC8109Introspection(address(subject)),
            _expectedPairs()
        );

        bool isValid = Behavior_IERC8109Introspection.hasValid_IERC8109Introspection_functionFacetPairs(
            IERC8109Introspection(address(subject))
        );

        assertFalse(isValid, "Implementation with extra pair should fail validation (count mismatch)");
    }

    function test_Behavior_IERC8109Introspection_invalid_inconsistent() public {
        Stub_ERC8109_Inconsistent subject = new Stub_ERC8109_Inconsistent(address(facetA), address(facetB));
        vm.label(address(subject), "InconsistentSubject");

        Behavior_IERC8109Introspection.expect_IERC8109Introspection(
            IERC8109Introspection(address(subject)),
            _expectedPairs()
        );

        // facetAddress should pass (it returns correct values)
        bool facetAddressValid = Behavior_IERC8109Introspection.hasValid_IERC8109Introspection_facetAddress(
            IERC8109Introspection(address(subject))
        );
        assertTrue(facetAddressValid, "facetAddress returns correct values");

        // functionFacetPairs should fail (it returns wrong facet for funcA2)
        bool pairsValid = Behavior_IERC8109Introspection.hasValid_IERC8109Introspection_functionFacetPairs(
            IERC8109Introspection(address(subject))
        );
        assertFalse(pairsValid, "functionFacetPairs returns inconsistent values");
    }

    function test_Behavior_IERC8109Introspection_areValid_mismatch() public {
        Stub_ERC8109_Valid subject = new Stub_ERC8109_Valid(address(facetA), address(facetB));
        vm.label(address(subject), "ValidSubject");

        // Expect facetA but actual is facetB
        bool isValid = Behavior_IERC8109Introspection.areValid_IERC8109Introspection_facetAddress(
            IERC8109Introspection(address(subject)),
            Stub_FacetA.funcA1.selector,
            address(facetB), // Wrong expectation
            subject.facetAddress(Stub_FacetA.funcA1.selector)
        );

        assertFalse(isValid, "areValid should return false for mismatched facetAddress");
    }

    /* -------------------------------------------------------------------------- */
    /*                              Edge Cases                                    */
    /* -------------------------------------------------------------------------- */

    function test_Behavior_IERC8109Introspection_empty() public {
        Stub_ERC8109_Empty subject = new Stub_ERC8109_Empty();
        vm.label(address(subject), "EmptySubject");

        IERC8109Introspection.FunctionFacetPair[] memory emptyPairs =
            new IERC8109Introspection.FunctionFacetPair[](0);

        Behavior_IERC8109Introspection.expect_IERC8109Introspection(
            IERC8109Introspection(address(subject)),
            emptyPairs
        );

        bool isValid = Behavior_IERC8109Introspection.hasValid_IERC8109Introspection(
            IERC8109Introspection(address(subject))
        );

        assertTrue(isValid, "Empty implementation should pass with empty expectations");
    }

    function test_Behavior_IERC8109Introspection_unknownSelector() public {
        Stub_ERC8109_Valid subject = new Stub_ERC8109_Valid(address(facetA), address(facetB));
        vm.label(address(subject), "ValidSubject");

        bytes4 unknownSelector = bytes4(0xdeadbeef);
        address result = subject.facetAddress(unknownSelector);

        assertEq(result, address(0), "Unknown selector should return address(0)");
    }

    function test_Behavior_IERC8109Introspection_singlePair() public {
        // Test with just one function-facet pair
        IERC8109Introspection.FunctionFacetPair[] memory singlePair =
            new IERC8109Introspection.FunctionFacetPair[](1);
        singlePair[0] = IERC8109Introspection.FunctionFacetPair({
            selector: Stub_FacetA.funcA1.selector,
            facet: address(facetA)
        });

        Stub_ERC8109_Valid subject = new Stub_ERC8109_Valid(address(facetA), address(facetB));
        vm.label(address(subject), "ValidSubject");

        // This should fail because we expect only 1 pair but actual has 3
        Behavior_IERC8109Introspection.expect_IERC8109Introspection(
            IERC8109Introspection(address(subject)),
            singlePair
        );

        bool isValid = Behavior_IERC8109Introspection.hasValid_IERC8109Introspection_functionFacetPairs(
            IERC8109Introspection(address(subject))
        );

        assertFalse(isValid, "Expecting 1 pair but having 3 should fail");
    }
}
