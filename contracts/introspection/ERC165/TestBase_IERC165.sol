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

import {IERC165} from "@crane/contracts/interfaces/IERC165.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

// import {Test_Crane} from "@crane/contracts/crane/test/Test_Crane.sol";
// import { IFacet } from "@crane/contracts/crane/interfaces/IFacet.sol";
import {Behavior_IERC165} from "@crane/contracts/introspection/ERC165/Behavior_IERC165.sol";

// tag::TestBase_IERC165[]
/**
 * @title TestBase_IERC165
 * @author cyotee doge <not_cyotee@proton.me>
 * @notice Abstract Behavior TestBase for declaration and invariant style tests of IERC165 subjects.
 * @dev LR-7 compliant: requires full realistic non-zero subject initialization (via CraneTest/TestBase inheritance chains + InitDevService + real DFPkg/deploy, never address(0)); uses exact assertTrue with meaningful messages; mandates Behavior_IERC165.expect_* + hasValid_* ; includes declaration checks.
 *      LR-1: rich NatSpec + exact // tag:: / end:: include-tags on contract and all public surface (TestBase_IERC165[], setUp[], erc165_subject()[], expected_IERC165_interfaces()[], test_IERC165_supportsInterface[] etc). Modeled on gold examples: CraneTest.sol, TestBase_IFacet.sol, Behavior_IERC165_Behavior_Test.sol, ERC20DFPkg_IERC165.t.sol usage, AGENTS.md TestBase/Behavior sections, PRD LR-1 (NatSpec+tags on all incl TestBases) + LR-7.
 *      Inheritors must perform complete init (see ERC20DFPkg_IERC165_Test) then rely on or call this setUp.
 *      ERC165 ID 0x01ffc9a7 referenced from CENTRALLY_COMPUTED_NATSPEC_VALUES.md only.
 */
abstract contract TestBase_IERC165 is Test {
    // tag::ERC165_INTERFACE_ID[]
    /// @notice ERC165 interface ID (0x01ffc9a7) per CENTRALLY_COMPUTED_NATSPEC_VALUES.md and ERC-165 spec. Required self-support declaration.
    bytes4 internal constant ERC165_INTERFACE_ID = type(IERC165).interfaceId;
    // end::ERC165_INTERFACE_ID[]

    /// @notice The IERC165 subject under test. Populated via virtual after full non-0 init by caller.
    IERC165 erc165TestSubject;

    // tag::setUp[]
    /**
     * @notice Virtual setUp that obtains real subject and primes Behavior_IERC165 expectations.
     * @dev LR-7: asserts non-zero subject (enforces full init via CraneTest/TestBase chaining + InitDev etc before call); registers via expect_ so hasValid_ can validate declaration.
     *      Supports proper TestBase usage in chains (callers do full init then TestBase_IERC165.setUp() or override+call as in gold ERC20DFPkg_IERC165.t.sol / TestBase_IFacet pattern). Preserves original logic.
     */
    function setUp() public virtual {
        erc165TestSubject = erc165_subject();
        // LR-7: full realistic non-0 init required (no address(0) subjects; use CraneTest + InitDevService + DFPkg deploy like ERC20DFPkg_IERC165.t.sol / DevEnvSmokeTest)
        assertTrue(
            address(erc165TestSubject) != address(0),
            "LR-7: erc165TestSubject must be real non-zero subject (CraneTest/TestBase chaining + InitDev + deploy)"
        );
        Behavior_IERC165.expect_IERC165_supportsInterface(erc165TestSubject, expected_IERC165_interfaces());
    }
    // end::setUp[]

    // tag::erc165_subject()[]
    /// @notice Virtual hook returning the test subject (IERC165). Must yield non-zero after full init.
    /// @return subject_ The initialized subject.
    /// forge-lint: disable-next-line(mixed-case-function)
    function erc165_subject() public virtual returns (IERC165 subject_);
    // end::erc165_subject()[]

    // tag::expected_IERC165_interfaces()[]
    /// @notice Virtual hook for expected supported interface IDs (declaration test data).
    /// @return expectedInterfaces_ Array of bytes4 IDs the subject must report support for.
    /// forge-lint: disable-next-line(mixed-case-function)
    function expected_IERC165_interfaces() public virtual returns (bytes4[] memory expectedInterfaces_);

    // end::expected_IERC165_interfaces()[]

    // tag::test_IERC165_supportsInterface()[]
    /**
     * @notice Core declaration test asserting ERC165 self-support + all expected interfaces.
     * @dev Uses Behavior_IERC165.hasValid_ (which exercises expect_ state + negative 0xffffffff case). Exact assertTrue with descriptive messages per LR-7.
     */
    function test_IERC165_supportsInterface() public virtual {
        // Verify ERC165 self-support (0x01ffc9a7) - required by ERC165 spec. Value from CENTRALLY_COMPUTED_NATSPEC_VALUES.md
        assertTrue(
            erc165TestSubject.supportsInterface(ERC165_INTERFACE_ID),
            "Contract must support ERC165 interface (0x01ffc9a7)"
        );

        // Validate all expected interfaces using Behavior library (mandatory per LR-7)
        assertTrue(
            Behavior_IERC165.hasValid_IERC165_supportsInterface(erc165TestSubject),
            "ERC165 interface support validation failed via Behavior_IERC165.hasValid_IERC165_supportsInterface"
        );
    }
    // end::test_IERC165_supportsInterface()[]
}
// end::TestBase_IERC165[]
