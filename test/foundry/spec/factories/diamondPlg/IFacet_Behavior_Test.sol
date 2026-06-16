// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import "forge-std/Test.sol";
// import {Test_Crane} from "contracts/crane/test/Test_Crane.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {Behavior_IFacet} from "@crane/contracts/factories/diamondPkg/Behavior_IFacet.sol";

interface Behavior_IFacet_Good {
    function func0() external;

    function func1() external;

    function func2() external;
}

interface Behavior_IFacet_Bad {
    function funcBad() external;
}

contract Behavior_Stub_IFacet_Good is Behavior_IFacet_Good, IFacet {
    function func0() external {}

    function func1() external {}

    function func2() external {}

    function facetName() public pure virtual returns (string memory name) {
        return type(Behavior_Stub_IFacet_Good).name;
    }

    function facetInterfaces() public pure virtual returns (bytes4[] memory facetInterfaces_) {
        facetInterfaces_ = new bytes4[](1);
        facetInterfaces_[0] = type(Behavior_IFacet_Good).interfaceId;
    }

    function facetFuncs() public pure virtual returns (bytes4[] memory facetFuncs_) {
        facetFuncs_ = new bytes4[](3);
        facetFuncs_[0] = Behavior_IFacet_Good.func0.selector;
        facetFuncs_[1] = Behavior_IFacet_Good.func1.selector;
        facetFuncs_[2] = Behavior_IFacet_Good.func2.selector;
    }

    function facetMetadata()
        public
        pure
        virtual
        returns (string memory name_, bytes4[] memory interfaces, bytes4[] memory functions)
    {
        name_ = facetName();
        interfaces = facetInterfaces();
        functions = facetFuncs();
    }
}

contract Behavior_Stub_IFacet_Bad is Behavior_IFacet_Bad, IFacet {
    function funcBad() external {}

    function facetName() public pure virtual returns (string memory name) {
        return type(Behavior_Stub_IFacet_Bad).name;
    }

    function facetInterfaces() public pure virtual returns (bytes4[] memory facetInterfaces_) {
        facetInterfaces_ = new bytes4[](1);
        facetInterfaces_[0] = type(Behavior_IFacet_Bad).interfaceId;
    }

    function facetFuncs() public pure virtual returns (bytes4[] memory facetFuncs_) {
        facetFuncs_ = new bytes4[](1);
        facetFuncs_[0] = Behavior_IFacet_Bad.funcBad.selector;
    }

    function facetMetadata()
        public
        pure
        virtual
        returns (string memory name_, bytes4[] memory interfaces, bytes4[] memory functions)
    {
        name_ = facetName();
        interfaces = facetInterfaces();
        functions = facetFuncs();
    }
}

contract Behavior_Stub_IFacet_Bad_Complex is Behavior_Stub_IFacet_Good, Behavior_Stub_IFacet_Bad {
    function facetName()
        public
        pure
        virtual
        override(Behavior_Stub_IFacet_Good, Behavior_Stub_IFacet_Bad)
        returns (string memory name)
    {
        return type(Behavior_Stub_IFacet_Bad_Complex).name;
    }

    function facetInterfaces()
        public
        pure
        virtual
        override(Behavior_Stub_IFacet_Good, Behavior_Stub_IFacet_Bad)
        returns (bytes4[] memory facetInterfaces_)
    {
        facetInterfaces_ = new bytes4[](2);
        facetInterfaces_[0] = type(Behavior_IFacet_Good).interfaceId;
        facetInterfaces_[1] = type(Behavior_IFacet_Bad).interfaceId;
    }

    function facetFuncs()
        public
        pure
        override(Behavior_Stub_IFacet_Good, Behavior_Stub_IFacet_Bad)
        returns (bytes4[] memory facetFuncs_)
    {
        facetFuncs_ = new bytes4[](3);
        facetFuncs_[0] = Behavior_IFacet_Good.func0.selector;
        facetFuncs_[1] = Behavior_IFacet_Good.func1.selector;
        facetFuncs_[2] = Behavior_IFacet_Bad.funcBad.selector;
    }

    function facetMetadata()
        public
        pure
        virtual
        override(Behavior_Stub_IFacet_Good, Behavior_Stub_IFacet_Bad)
        returns (string memory name_, bytes4[] memory interfaces, bytes4[] memory functions)
    {
        name_ = facetName();
        interfaces = facetInterfaces();
        functions = facetFuncs();
    }
}

// tag::Behavior_IFacet_Test[]
/**
 * @title Behavior_IFacet_Test
 * @notice Dedicated behavior tests for Behavior_IFacet library.
 * @dev Validates areValid_*, hasValid_*, expect_*, isValid_*_consistency using good/bad/complex IFacet stubs.
 *      Full LR-7: explicit setUp full init (no address(0)), exact value asserts (assertTrue/assertEq/assertFalse), mandatory Behavior_IFacet usage, facet declaration tests (interfaces/funcs/name/metadata + parity to central selectors).
 *      LR-1: NatSpec + // tag::Symbol()[] / // end:: + custom selector/signature tags on contract + all public API.
 *      References ONLY values from CENTRALLY_COMPUTED_NATSPEC_VALUES.md for IFacet (0x5b6f4d01 etc).
 *      Does not inherit CraneTest/TestBase_IFacet (by design: this IS the Behavior test itself, like Behavior_IERC165_Behavior_Test).
 * @custom:signature Behavior_IFacet_Test
 */
contract Behavior_IFacet_Test is Test {
    Behavior_Stub_IFacet_Good internal _goodFacet;
    Behavior_Stub_IFacet_Bad internal _badFacet;
    Behavior_Stub_IFacet_Bad_Complex internal _badComplexFacet;

    function setUp() public {
        // LR-7: full explicit initialization (no address(0) subjects, no lazy deployment inside test methods)
        _goodFacet = new Behavior_Stub_IFacet_Good();
        _badFacet = new Behavior_Stub_IFacet_Bad();
        _badComplexFacet = new Behavior_Stub_IFacet_Bad_Complex();
    }

    // tag::goodFacet()[]
    /**
     * @notice Returns the pre-initialized good stub facet (positive path subject).
     * @return goodFacet_ The IFacet stub that correctly declares its metadata.
     * @custom:signature goodFacet()
     * @custom:selector 0xea23f10c
     */
    function goodFacet() public view returns (IFacet goodFacet_) {
        goodFacet_ = _goodFacet;
    }

    // end::goodFacet()[]

    // tag::badFacet()[]
    /**
     * @notice Returns the pre-initialized bad stub facet (negative path subject).
     * @return badFacet_ The IFacet stub whose declarations intentionally mismatch controls.
     * @custom:signature badFacet()
     * @custom:selector 0x17dbbcbc
     */
    function badFacet() public view returns (IFacet badFacet_) {
        badFacet_ = _badFacet;
    }

    // end::badFacet()[]

    // tag::badComplexFacet()[]
    /**
     * @notice Returns the pre-initialized complex (mixed good+bad) stub facet.
     * @return badComplexFacet_ The IFacet stub declaring multiple interfaces with mismatch to simple controls.
     * @custom:signature badComplexFacet()
     * @custom:selector 0x9a57d928
     */
    function badComplexFacet() public view returns (IFacet badComplexFacet_) {
        badComplexFacet_ = _badComplexFacet;
    }

    // end::badComplexFacet()[]

    // tag::IFacet_control_facetName()[]
    /// forge-lint: disable-next-line(mixed-case-function)
    /**
     * @notice Control (expected) facetName for the good stub. Used for declaration testing (LR-7).
     * @dev Mirrors pattern of other controls; references central IFacet facetName selector 0x5b6f4d01 from CENTRALLY_COMPUTED_NATSPEC_VALUES.md .
     * @return facetName_ The expected name string.
     * @custom:signature IFacet_control_facetName()
     * @custom:selector 0x1dcf4ce9
     */
    function IFacet_control_facetName() public pure virtual returns (string memory facetName_) {
        facetName_ = type(Behavior_Stub_IFacet_Good).name;
    }

    // end::IFacet_control_facetName()[]

    // tag::IFacet_control_facetInterfaces()[]
    /// forge-lint: disable-next-line(mixed-case-function)
    /**
     * @notice Control (expected) facetInterfaces for the good stub. Used for declaration testing.
     * @dev Uses central IFacet values (see CENTRALLY_COMPUTED_NATSPEC_VALUES.md):
     *      facetInterfaces selector 0x2ea80826, facetFuncs 0x574a4cff, facetName 0x5b6f4d01, facetMetadata 0xf10d7a75
     * @return facetInterfaces_ Array containing the expected interface ID.
     * @custom:signature IFacet_control_facetInterfaces()
     * @custom:selector 0x39228e3c
     */
    function IFacet_control_facetInterfaces() public pure virtual returns (bytes4[] memory facetInterfaces_) {
        facetInterfaces_ = new bytes4[](1);
        facetInterfaces_[0] = type(Behavior_IFacet_Good).interfaceId;
    }

    // end::IFacet_control_facetInterfaces()[]

    // tag::IFacet_control_facetFuncs()[]
    /// forge-lint: disable-next-line(mixed-case-function)
    /**
     * @notice Control (expected) facetFuncs for the good stub. Used for declaration testing.
     * @return facetFuncs_ Array of the three expected selectors.
     * @custom:signature IFacet_control_facetFuncs()
     * @custom:selector 0xd4a1fbd8
     */
    function IFacet_control_facetFuncs() public pure virtual returns (bytes4[] memory facetFuncs_) {
        facetFuncs_ = new bytes4[](3);
        facetFuncs_[0] = Behavior_IFacet_Good.func0.selector;
        facetFuncs_[1] = Behavior_IFacet_Good.func1.selector;
        facetFuncs_[2] = Behavior_IFacet_Good.func2.selector;
    }

    // end::IFacet_control_facetFuncs()[]

    // tag::test_IFacet_selectors_match_central()[]
    /// forge-lint: disable-next-line(mixed-case-function)
    /**
     * @notice LR-7/LR-1 helper using ONLY central NatSpec values from CENTRALLY_COMPUTED_NATSPEC_VALUES.md for IFacet selectors.
     * @dev Verifies the IFacet function selectors against authoritative central values (no ad-hoc computation).
     *      This supports declaration test correctness for facets (LR-7) and NatSpec accuracy (LR-1).
     * @custom:signature test_IFacet_selectors_match_central()
     * @custom:selector 0xfa200fe7
     */
    function test_IFacet_selectors_match_central() public pure {
        // Values taken ONLY from docs/reports/gap/CENTRALLY_COMPUTED_NATSPEC_VALUES.md for IFacet
        assertEq(IFacet.facetName.selector, bytes4(0x5b6f4d01));
        assertEq(IFacet.facetInterfaces.selector, bytes4(0x2ea80826));
        assertEq(IFacet.facetFuncs.selector, bytes4(0x574a4cff));
        assertEq(IFacet.facetMetadata.selector, bytes4(0xf10d7a75));
    }

    // end::test_IFacet_selectors_match_central()[]

    // tag::test_Behavior_IFacet_areValid_IFacet_facetInterfaces_name_goodFacet()[]
    /// forge-lint: disable-next-line(mixed-case-function)
    /**
     * @notice LR-7: uses Behavior.areValid with subjectName string + exact control/actual order.
     * @dev Full subject from setUp; control from IFacet_control_* ; asserts exact match via Behavior.
     *      Supports facet declaration testing.
     * @custom:signature test_Behavior_IFacet_areValid_IFacet_facetInterfaces_name_goodFacet()
     * @custom:selector 0x34ce511d
     */
    function test_Behavior_IFacet_areValid_IFacet_facetInterfaces_name_goodFacet() public {
        // LR-7: correct order expected=control, actual=from subject; use assertTrue for explicit
        assertTrue(
            Behavior_IFacet.areValid_IFacet_facetInterfaces(
                type(Behavior_Stub_IFacet_Good).name, IFacet_control_facetInterfaces(), goodFacet().facetInterfaces()
            )
        );
    }

    // end::test_Behavior_IFacet_areValid_IFacet_facetInterfaces_name_goodFacet()[]

    // tag::test_Behavior_IFacet_areValid_IFacet_facetFuncs_name_goodFacet()[]
    /// forge-lint: disable-next-line(mixed-case-function)
    /**
     * @notice LR-7 facet declaration coverage: areValid facetFuncs name-overload path.
     * @dev Exact values from controls (derived from central IFacet); assertTrue.
     * @custom:signature test_Behavior_IFacet_areValid_IFacet_facetFuncs_name_goodFacet()
     * @custom:selector 0x4daa3008
     */
    function test_Behavior_IFacet_areValid_IFacet_facetFuncs_name_goodFacet() public {
        assertTrue(
            Behavior_IFacet.areValid_IFacet_facetFuncs(
                type(Behavior_Stub_IFacet_Good).name, IFacet_control_facetFuncs(), goodFacet().facetFuncs()
            )
        );
    }

    // end::test_Behavior_IFacet_areValid_IFacet_facetFuncs_name_goodFacet()[]

    /// forge-lint: disable-next-line(mixed-case-function)
    function test_Behavior_IFacet_areValid_IFacet_facetInterfaces_name_badFacet() public {
        assertFalse(
            Behavior_IFacet.areValid_IFacet_facetInterfaces(
                type(Behavior_Stub_IFacet_Bad).name, IFacet_control_facetInterfaces(), badFacet().facetInterfaces()
            )
        );
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function test_Behavior_IFacet_areValid_IFacet_facetFuncs_name_badFacet() public {
        assertFalse(
            Behavior_IFacet.areValid_IFacet_facetFuncs(
                type(Behavior_Stub_IFacet_Bad).name, IFacet_control_facetFuncs(), badFacet().facetFuncs()
            )
        );
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function test_Behavior_IFacet_areValid_IFacet_facetInterfaces_name_badFacetComplex() public {
        assertFalse(
            Behavior_IFacet.areValid_IFacet_facetInterfaces(
                type(Behavior_Stub_IFacet_Bad_Complex).name,
                IFacet_control_facetInterfaces(),
                badComplexFacet().facetInterfaces()
            )
        );
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function test_Behavior_IFacet_areValid_IFacet_facetFuncs_name_badFacetComplex() public {
        assertFalse(
            Behavior_IFacet.areValid_IFacet_facetFuncs(
                type(Behavior_Stub_IFacet_Bad_Complex).name, IFacet_control_facetFuncs(), badComplexFacet().facetFuncs()
            )
        );
    }

    // tag::test_Behavior_IFacet_areValid_IFacet_facetInterfaces_subject_goodFacet()[]
    /// forge-lint: disable-next-line(mixed-case-function)
    /**
     * @notice LR-7 declaration test: validates areValid using IFacet subject + exact control values (full init subject).
     * @dev Uses Behavior_IFacet.areValid... with correct (subject, expected, actual) ; exact assertTrue.
     *      References central IFacet selectors indirectly via controls.
     * @custom:signature test_Behavior_IFacet_areValid_IFacet_facetInterfaces_subject_goodFacet()
     * @custom:selector 0x4e700c80
     */
    function test_Behavior_IFacet_areValid_IFacet_facetInterfaces_subject_goodFacet() public {
        // LR-7: full exact value assertions (length + contents) before/within Behavior validation
        bytes4[] memory expected = IFacet_control_facetInterfaces();
        bytes4[] memory actual = goodFacet().facetInterfaces();
        assertEq(actual.length, expected.length, "exact interface count must match control");
        // LR-7: use exact expected first (control), actual second; assertTrue
        assertTrue(Behavior_IFacet.areValid_IFacet_facetInterfaces(goodFacet(), expected, actual));
    }

    // end::test_Behavior_IFacet_areValid_IFacet_facetInterfaces_subject_goodFacet()[]

    /// forge-lint: disable-next-line(mixed-case-function)
    function test_Behavior_IFacet_areValid_IFacet_facetFuncs_subject_goodFacet() public {
        // LR-7: exact value assertion on length for funcs + Behavior
        bytes4[] memory expected = IFacet_control_facetFuncs();
        bytes4[] memory actual = goodFacet().facetFuncs();
        assertEq(actual.length, expected.length, "exact function selector count must match control");
        assertTrue(Behavior_IFacet.areValid_IFacet_facetFuncs(goodFacet(), expected, actual));
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function test_Behavior_IFacet_areValid_IFacet_facetInterfaces_subject_badFacet() public {
        assertFalse(
            Behavior_IFacet.areValid_IFacet_facetInterfaces(
                badFacet(), IFacet_control_facetInterfaces(), badFacet().facetInterfaces()
            )
        );
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function test_Behavior_IFacet_areValid_IFacet_facetFuncs_subject_badFacet() public {
        assertFalse(
            Behavior_IFacet.areValid_IFacet_facetFuncs(badFacet(), IFacet_control_facetFuncs(), badFacet().facetFuncs())
        );
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function test_Behavior_IFacet_areValid_IFacet_facetInterfaces_subject_badFacetComplex() public {
        assertFalse(
            Behavior_IFacet.areValid_IFacet_facetInterfaces(
                badComplexFacet(), IFacet_control_facetInterfaces(), badComplexFacet().facetInterfaces()
            )
        );
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function test_Behavior_IFacet_areValid_IFacet_facetFuncs_subject_badFacetComplex() public {
        assertFalse(
            Behavior_IFacet.areValid_IFacet_facetFuncs(
                badComplexFacet(), IFacet_control_facetFuncs(), badComplexFacet().facetFuncs()
            )
        );
    }

    // tag::test_Behavior_IFacet_hasValid_IFacet_facetInterfaces_subject_goodFacet()[]
    /// forge-lint: disable-next-line(mixed-case-function)
    /**
     * @notice LR-7: expect + hasValid pattern for facetInterfaces on fully initialized good subject.
     * @dev Validates Behavior usage for declaration tests; uses central IFacet selector 0x2ea80826 via control.
     * @custom:signature test_Behavior_IFacet_hasValid_IFacet_facetInterfaces_subject_goodFacet()
     * @custom:selector 0xefe285a0
     */
    function test_Behavior_IFacet_hasValid_IFacet_facetInterfaces_subject_goodFacet() public {
        Behavior_IFacet.expect_IFacet_facetInterfaces(goodFacet(), IFacet_control_facetInterfaces());
        assertTrue(Behavior_IFacet.hasValid_IFacet_facetInterfaces(goodFacet()));
    }

    // end::test_Behavior_IFacet_hasValid_IFacet_facetInterfaces_subject_goodFacet()[]

    // tag::test_Behavior_IFacet_hasValid_IFacet_facetFuncs_subject_goodFacet()[]
    /// forge-lint: disable-next-line(mixed-case-function)
    /**
     * @notice LR-7: expect + hasValid pattern for facetFuncs on fully initialized good subject.
     * @dev Exact Behavior lib usage + control values for facet declaration validation.
     * @custom:signature test_Behavior_IFacet_hasValid_IFacet_facetFuncs_subject_goodFacet()
     * @custom:selector 0x787a2503
     */
    function test_Behavior_IFacet_hasValid_IFacet_facetFuncs_subject_goodFacet() public {
        Behavior_IFacet.expect_IFacet_facetFuncs(goodFacet(), IFacet_control_facetFuncs());
        assertTrue(Behavior_IFacet.hasValid_IFacet_facetFuncs(goodFacet()));
    }

    // end::test_Behavior_IFacet_hasValid_IFacet_facetFuncs_subject_goodFacet()[]

    /// forge-lint: disable-next-line(mixed-case-function)
    function test_Behavior_IFacet_hasValid_IFacet_facetInterfaces_subject_badFacet() public {
        Behavior_IFacet.expect_IFacet_facetInterfaces(badFacet(), IFacet_control_facetInterfaces());
        assertFalse(Behavior_IFacet.hasValid_IFacet_facetInterfaces(badFacet()));
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function test_Behavior_IFacet_hasValid_IFacet_facetFuncs_subject_badFacet() public {
        Behavior_IFacet.expect_IFacet_facetFuncs(badFacet(), IFacet_control_facetFuncs());
        assertFalse(Behavior_IFacet.hasValid_IFacet_facetFuncs(badFacet()));
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function test_Behavior_IFacet_hasValid_IFacet_facetInterfaces_subject_badFacetComplex() public {
        Behavior_IFacet.expect_IFacet_facetInterfaces(badComplexFacet(), IFacet_control_facetInterfaces());
        assertFalse(Behavior_IFacet.hasValid_IFacet_facetInterfaces(badComplexFacet()));
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function test_Behavior_IFacet_hasValid_IFacet_facetFuncs_subject_badFacetComplex() public {
        Behavior_IFacet.expect_IFacet_facetFuncs(badComplexFacet(), IFacet_control_facetFuncs());
        assertFalse(Behavior_IFacet.hasValid_IFacet_facetFuncs(badComplexFacet()));
    }

    // tag::test_Behavior_IFacet_areValid_IFacet_facetName_good()[]
    /// forge-lint: disable-next-line(mixed-case-function)
    /**
     * @notice LR-7: declaration test coverage for facetName using Behavior.areValid (string overload + control).
     * @dev Full init subject via setUp; uses IFacet_control_facetName() for exact expected value; assertTrue exact.
     *      References central IFacet facetName() selector 0x5b6f4d01 .
     * @custom:signature test_Behavior_IFacet_areValid_IFacet_facetName_good()
     * @custom:selector 0x6c3000a9
     */
    function test_Behavior_IFacet_areValid_IFacet_facetName_good() public {
        // LR-7: use control for exact value, not inline literal
        string memory expectedName = IFacet_control_facetName();
        assertTrue(Behavior_IFacet.areValid_IFacet_facetName(expectedName, expectedName, goodFacet().facetName()));
    }

    // end::test_Behavior_IFacet_areValid_IFacet_facetName_good()[]

    // tag::test_Behavior_IFacet_hasValid_IFacet_facetName_good()[]
    /// forge-lint: disable-next-line(mixed-case-function)
    /**
     * @notice LR-7: hasValid for facetName after expect, using control for exact expected (full init).
     * @dev Demonstrates expect_* + hasValid_* pattern from Behavior library for declaration tests.
     *      Uses central referenced facetName selector 0x5b6f4d01 indirectly.
     * @custom:signature test_Behavior_IFacet_hasValid_IFacet_facetName_good()
     * @custom:selector 0x40c9e6a8
     */
    function test_Behavior_IFacet_hasValid_IFacet_facetName_good() public {
        string memory expectedName = IFacet_control_facetName();
        Behavior_IFacet.expect_IFacet_facetName(goodFacet(), expectedName);
        assertTrue(Behavior_IFacet.hasValid_IFacet_facetName(goodFacet()));
    }

    // end::test_Behavior_IFacet_hasValid_IFacet_facetName_good()[]

    // tag::test_Behavior_IFacet_isValid_IFacet_facetMetadata_consistency_good()[]
    /// forge-lint: disable-next-line(mixed-case-function)
    /**
     * @notice LR-7: tests internal declaration consistency using Behavior (preview parity analogue for metadata).
     * @dev Exercises isValid_IFacet_facetMetadata_consistency which is required by TestBase_IFacet.
     *      Uses full init subject. Exact via Behavior.
     * @custom:signature test_Behavior_IFacet_isValid_IFacet_facetMetadata_consistency_good()
     */
    function test_Behavior_IFacet_isValid_IFacet_facetMetadata_consistency_good() public {
        // LR-7: exact internal consistency assertion (name/interfaces/funcs parity via Behavior)
        assertTrue(Behavior_IFacet.isValid_IFacet_facetMetadata_consistency(goodFacet()));
    }

    // end::test_Behavior_IFacet_isValid_IFacet_facetMetadata_consistency_good()[]

    // tag::test_Behavior_IFacet_isValid_IFacet_facetMetadata_consistency_bad()[]
    /// forge-lint: disable-next-line(mixed-case-function)
    /**
     * @notice LR-7: metadata consistency must hold internally even for "bad" (mismatched) stubs.
     * @dev The isValid checks internal parity of facetMetadata() vs its component getters (not vs external control).
     * @custom:signature test_Behavior_IFacet_isValid_IFacet_facetMetadata_consistency_bad()
     * @custom:selector 0x6986ecf0
     */
    function test_Behavior_IFacet_isValid_IFacet_facetMetadata_consistency_bad() public {
        // internally consistent even if "bad" vs external control
        assertTrue(Behavior_IFacet.isValid_IFacet_facetMetadata_consistency(badFacet()));
    }

    // end::test_Behavior_IFacet_isValid_IFacet_facetMetadata_consistency_bad()[]

    // tag::test_Behavior_IFacet_isValid_IFacet_facetMetadata_consistency_complex()[]
    /// forge-lint: disable-next-line(mixed-case-function)
    /**
     * @notice LR-7: metadata consistency for complex (multi-interface) stub.
     * @dev Uses Behavior to enforce that aggregate and individuals always agree (required for TestBase_IFacet users).
     * @custom:signature test_Behavior_IFacet_isValid_IFacet_facetMetadata_consistency_complex()
     * @custom:selector 0x2935eb00
     */
    function test_Behavior_IFacet_isValid_IFacet_facetMetadata_consistency_complex() public {
        assertTrue(Behavior_IFacet.isValid_IFacet_facetMetadata_consistency(badComplexFacet()));
    }

    // end::test_Behavior_IFacet_isValid_IFacet_facetMetadata_consistency_complex()[]

    // tag::test_Behavior_IFacet_expect_IFacet_full_good()[]
    /// forge-lint: disable-next-line(mixed-case-function)
    /**
     * @notice LR-7: full expect_IFacet + follow up hasValid (declaration test coverage for facets/packages).
     * @dev Uses Behavior library's expect_IFacet (which covers name+interfaces+funcs), then hasValid_* .
     *      Subjects are from setUp full init (no address(0)).
     * @custom:signature test_Behavior_IFacet_expect_IFacet_full_good()
     * @custom:selector 0x69621f49
     */
    function test_Behavior_IFacet_expect_IFacet_full_good() public {
        Behavior_IFacet.expect_IFacet(
            goodFacet(),
            type(Behavior_Stub_IFacet_Good).name,
            IFacet_control_facetInterfaces(),
            IFacet_control_facetFuncs()
        );
        assertTrue(Behavior_IFacet.hasValid_IFacet_facetName(goodFacet()));
        assertTrue(Behavior_IFacet.hasValid_IFacet_facetInterfaces(goodFacet()));
        assertTrue(Behavior_IFacet.hasValid_IFacet_facetFuncs(goodFacet()));
    }
    // end::test_Behavior_IFacet_expect_IFacet_full_good()[]
}
// end::Behavior_IFacet_Test[]
