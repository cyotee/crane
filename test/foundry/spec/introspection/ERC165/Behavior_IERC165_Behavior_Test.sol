// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                   Foundry                                  */
/* -------------------------------------------------------------------------- */

import "forge-std/Test.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {IERC165} from "@crane/contracts/interfaces/IERC165.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {Behavior_IERC165} from "@crane/contracts/introspection/ERC165/Behavior_IERC165.sol";
import {Behavior_IFacet} from "@crane/contracts/factories/diamondPkg/Behavior_IFacet.sol";

// tag::Behavior_GoodIERC165Stub[]
/**
 * @title Behavior_GoodIERC165Stub
 * @notice Good stub implementing IERC165 (correct support) + IFacet (for mandatory LR-7 Behavior_IFacet declaration tests).
 * @dev Declares exactly as ERC165Facet does for its surface (IERC165 iface + supportsInterface func). Used for both Behavior_IERC165 + Behavior_IFacet paths.
 *      LR-7: non-0 when new'ed + labeled in setUp.
 */
contract Behavior_GoodIERC165Stub is IERC165, IFacet {
    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }

    function facetName() public pure returns (string memory name) {
        return type(Behavior_GoodIERC165Stub).name;
    }

    function facetInterfaces() public pure returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](1);
        interfaces[0] = type(IERC165).interfaceId;
    }

    function facetFuncs() public pure returns (bytes4[] memory funcs) {
        funcs = new bytes4[](1);
        funcs[0] = IERC165.supportsInterface.selector;
    }

    function facetMetadata()
        external
        pure
        returns (string memory name, bytes4[] memory interfaces, bytes4[] memory functions)
    {
        name = facetName();
        interfaces = facetInterfaces();
        functions = facetFuncs();
    }
}
// end::Behavior_GoodIERC165Stub[]

// tag::Behavior_BadIERC165Stub[]
/**
 * @notice Bad stub for negative testing (reports no interfaces supported).
 */
contract Behavior_BadIERC165Stub is IERC165 {
    function supportsInterface(bytes4 /*interfaceId*/) external pure override returns (bool) {
        return false;
    }
}
// end::Behavior_BadIERC165Stub[]

// tag::Behavior_IERC165_Behavior_Test[]
/**
 * @title Behavior_IERC165_Behavior_Test
 * @notice Dedicated behavior tests for Behavior_IERC165 (full/missing paths) + LR-7 mandatory Behavior_IFacet declaration using central values.
 * @dev LR-7 (full): explicit non-0 init of stubs in setUp (new + vm.label, no lazy/0, no init inside test fns); exact assertEq/assertTrue (no loose/side-effect only); use of Behavior_IERC165 (expect + hasValid + isValid) + mandatory Behavior_IFacet (expect/hasValid/isValid_consistency + lengths); dedicated LR-7 facet declaration test.
 *      LR-1: rich NatSpec + exact gold // tag::Name()[] / end:: (hyphenated for tests) + @custom:signature and @custom:selector tags on contract + setUp + all public fns/tests. Uses ONLY central IFacet values (0x5b6f4d01/0x2ea80826/0x574a4cff/0xf10d7a75) + supportsInterface 0x01ffc9a7 from CENTRALLY_COMPUTED_NATSPEC_VALUES.md.
 *      Handler style where applicable (exact expects). Modeled on gold: Behavior_IFacet_Test.sol, ReentrancyLock.t.sol (Facet_Test), Operable.t.sol, DevEnvSmokeTest.t.sol, ERC20DFPkg_IERC20.t.sol per AGENTS crane-testing + PRD LR-1+LR-7 + source.
 *      References the ERC165Facet control surface (no 0 inits).
 * @custom:signature Behavior_IERC165_Behavior_Test
 */
contract Behavior_IERC165_Behavior_Test is Test {
    Behavior_GoodIERC165Stub internal _goodStub;
    Behavior_BadIERC165Stub internal _badStub;

    // tag::setUp()
    /**
     * @notice LR-7 full non-0 initialization: create real stubs + vm.label before any asserts or behavior calls. No lazy address(0).
     * @dev Called by Foundry before each test. Explicit and complete per crane-testing gold examples.
     * @custom:signature setUp()
     */
    function setUp() public {
        // LR-7: explicit full init (non-0 subjects labeled; modeled on Behavior_IFacet_Test + Operable setUp)
        _goodStub = new Behavior_GoodIERC165Stub();
        vm.label(address(_goodStub), type(Behavior_GoodIERC165Stub).name);

        _badStub = new Behavior_BadIERC165Stub();
        vm.label(address(_badStub), type(Behavior_BadIERC165Stub).name);
    }
    // end::setUp()

    // tag::goodStub()[]
    /**
     * @notice Returns the fully initialized good stub (supports IERC165 correctly).
     * @return good The IERC165 subject for Behavior_IERC165 tests.
     * @custom:signature goodStub()
     * @custom:selector 0x301e4daa
     */
    function goodStub() public view returns (IERC165 good) {
        good = IERC165(address(_goodStub));
    }
    // end::goodStub()[]

    // tag::badStub()[]
    /**
     * @notice Returns the fully initialized bad stub (supports no interfaces).
     * @return bad The IERC165 subject for negative Behavior_IERC165 tests.
     * @custom:signature badStub()
     * @custom:selector 0x6ec3753d
     */
    function badStub() public view returns (IERC165 bad) {
        bad = IERC165(address(_badStub));
    }
    // end::badStub()[]

    // tag::goodAsFacet()[]
    /**
     * @notice Returns the good stub as IFacet for Behavior_IFacet declaration tests (LR-7).
     * @return f The IFacet view.
     * @custom:signature goodAsFacet()
     * @custom:selector 0x1c0e6c45
     */
    function goodAsFacet() public view returns (IFacet f) {
        f = IFacet(address(_goodStub));
    }
    // end::goodAsFacet()[]

    // tag::test_IERC165_supportsInterface_full()[]
    /**
     * @notice LR-7: full path via Behavior_IERC165 (expect stored, hasValid + isValid exact).
     *         Init from setUp; exact bool assert.
     * @custom:signature test_IERC165_supportsInterface_full()
     * @custom:selector 0x5fc90f5e
     */
    function test_IERC165_supportsInterface_full() public {
        bytes4[] memory expected = new bytes4[](1);
        expected[0] = type(IERC165).interfaceId;

        Behavior_IERC165.expect_IERC165_supportsInterface(goodStub(), expected);

        bool ok = Behavior_IERC165.hasValid_IERC165_supportsInterface(goodStub());
        assertEq(ok, true, "hasValid must be exact true when all expected interfaces supported");

        // direct isValid_ exact + also 0xffffffff negative built-in in behavior
        assertEq(
            Behavior_IERC165.isValid_IERC165_supportsInterfaces(goodStub(), true, goodStub().supportsInterface(type(IERC165).interfaceId)),
            true,
            "isValid must be exact true for supported"
        );
    }
    // end::test_IERC165_supportsInterface_full()[]

    // tag::test_IERC165_supportsInterface_missing()[]
    /**
     * @notice LR-7: missing interface path (hasValid exact false).
     *         Uses Behavior expect + exact assertEq.
     * @custom:signature test_IERC165_supportsInterface_missing()
     * @custom:selector 0x0e3e0f2e
     */
    function test_IERC165_supportsInterface_missing() public {
        bytes4[] memory expected = new bytes4[](2);
        expected[0] = type(IERC165).interfaceId;
        expected[1] = 0xdeadbeef;

        Behavior_IERC165.expect_IERC165_supportsInterface(badStub(), expected);

        bool ok = Behavior_IERC165.hasValid_IERC165_supportsInterface(badStub());
        assertEq(ok, false, "hasValid must be exact false when expected interface missing");

        assertEq(
            Behavior_IERC165.isValid_IERC165_supportsInterfaces(badStub(), true, badStub().supportsInterface(type(IERC165).interfaceId)),
            false,
            "isValid must be exact false"
        );
    }
    // end::test_IERC165_supportsInterface_missing()[]

    /* -------------------------------------------------------------------------- */
    /*                 LR-7: Mandatory Behavior_IFacet + declaration            */
    /* -------------------------------------------------------------------------- */

    // tag::test_LR7_IERC165Stub_declaration_viaBehavior_IFacet()[]
    /**
     * @notice LR-7 mandatory: good stub (ERC165-like) must declare correct IFacet metadata via Behavior_IFacet.
     *         Full init via setUp (non-0 labeled stub). Exact via Behavior + lengths.
     *         Uses ONLY central IFacet values (0x5b6f4d01 facetName, 0x2ea80826 interfaces, 0x574a4cff funcs, 0xf10d7a75 metadata) + 0x01ffc9a7 from CENTRALLY_COMPUTED_NATSPEC_VALUES.md.
     *         Also validates length exact + cross-ref to Behavior_IERC165 surface.
     * @custom:signature test_LR7_IERC165Stub_declaration_viaBehavior_IFacet()
     * @custom:selector 0x27b5830d
     */
    function test_LR7_IERC165Stub_declaration_viaBehavior_IFacet() public {
        IFacet f = goodAsFacet();

        bytes4[] memory expectedIfaces = new bytes4[](1);
        expectedIfaces[0] = type(IERC165).interfaceId;

        bytes4[] memory expectedFuncs = new bytes4[](1);
        expectedFuncs[0] = IERC165.supportsInterface.selector;

        // Mandatory Behavior_IFacet per LR-7/AGENTS (expect then hasValid + consistency)
        Behavior_IFacet.expect_IFacet_facetName(f, type(Behavior_GoodIERC165Stub).name);
        Behavior_IFacet.expect_IFacet_facetInterfaces(f, expectedIfaces);
        Behavior_IFacet.expect_IFacet_facetFuncs(f, expectedFuncs);

        assertTrue(Behavior_IFacet.hasValid_IFacet_facetName(f), "facetName exact via Behavior_IFacet");
        assertTrue(Behavior_IFacet.hasValid_IFacet_facetInterfaces(f), "facetInterfaces exact via Behavior_IFacet");
        assertTrue(Behavior_IFacet.hasValid_IFacet_facetFuncs(f), "facetFuncs exact via Behavior_IFacet");
        assertTrue(
            Behavior_IFacet.isValid_IFacet_facetMetadata_consistency(f),
            "facetMetadata consistency exact via Behavior_IFacet"
        );

        // LR-7 exact length asserts
        assertEq(f.facetInterfaces().length, 1, "interfaces length must be exact 1");
        assertEq(f.facetFuncs().length, 1, "funcs length must be exact 1");
    }
    // end::test_LR7_IERC165Stub_declaration_viaBehavior_IFacet()[]

    // tag::test_IFacet_IERC165_selectors_match_central()[]
    /**
     * @notice LR-7 + LR-1: verify IFacet and IERC165 selectors match central values used in NatSpec/tags.
     * @custom:signature test_IFacet_IERC165_selectors_match_central()
     * @custom:selector 0x2e8e0e4a
     */
    function test_IFacet_IERC165_selectors_match_central() public pure {
        assertEq(IFacet.facetName.selector, bytes4(0x5b6f4d01));
        assertEq(IFacet.facetInterfaces.selector, bytes4(0x2ea80826));
        assertEq(IFacet.facetFuncs.selector, bytes4(0x574a4cff));
        assertEq(IFacet.facetMetadata.selector, bytes4(0xf10d7a75));
        assertEq(IERC165.supportsInterface.selector, bytes4(0x01ffc9a7));
    }
    // end::test_IFacet_IERC165_selectors_match_central()[]
}
// end::Behavior_IERC165_Behavior_Test[]
