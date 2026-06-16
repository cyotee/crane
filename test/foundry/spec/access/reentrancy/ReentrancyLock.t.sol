// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                   Foundry                                  */
/* -------------------------------------------------------------------------- */

import "forge-std/Test.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {ReentrancyLockRepo} from "@crane/contracts/access/reentrancy/ReentrancyLockRepo.sol";
import {ReentrancyLockModifiers} from "@crane/contracts/access/reentrancy/ReentrancyLockModifiers.sol";
import {ReentrancyLockFacet} from "@crane/contracts/access/reentrancy/ReentrancyLockFacet.sol";
import {ReentrancyLockTarget} from "@crane/contracts/access/reentrancy/ReentrancyLockTarget.sol";
import {IReentrancyLock} from "@crane/contracts/interfaces/IReentrancyLock.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {CraneTest} from "@crane/contracts/test/CraneTest.sol";
import {Behavior_IFacet} from "@crane/contracts/factories/diamondPkg/Behavior_IFacet.sol";
import {AccessFacetFactoryService} from "@crane/contracts/access/AccessFacetFactoryService.sol";

/**
 * @title ReentrancyLockRepoHarness
 * @notice Test harness that exposes ReentrancyLockRepo internal library functions
 */
// tag::ReentrancyLockRepoHarness[]
contract ReentrancyLockRepoHarness {
    function lock() external {
        ReentrancyLockRepo._lock();
    }

    function unlock() external {
        ReentrancyLockRepo._unlock();
    }

    function isLocked() external view returns (bool) {
        return ReentrancyLockRepo._isLocked();
    }

    function onlyUnlocked() external view {
        ReentrancyLockRepo._onlyUnlocked();
    }
}
// end::ReentrancyLockRepoHarness[]

/**
 * @title ReentrancyLockModifiersHarness
 * @notice Test harness for testing the nonReentrant modifier
 */
// tag::ReentrancyLockModifiersHarness[]
contract ReentrancyLockModifiersHarness is ReentrancyLockModifiers {
    uint256 public counter;
    bool public callbackEnabled;
    address public callbackTarget;

    function protectedFunction() external nonReentrant {
        counter++;
        if (callbackEnabled && callbackTarget != address(0)) {
            // Attempt to call back into the protected function
            ReentrancyLockModifiersHarness(callbackTarget).protectedFunction();
        }
    }

    function setCallback(address target) external {
        callbackEnabled = true;
        callbackTarget = target;
    }

    function disableCallback() external {
        callbackEnabled = false;
    }

    function isLockedView() external view returns (bool) {
        return ReentrancyLockRepo._isLocked();
    }
}
// end::ReentrancyLockModifiersHarness[]

/**
 * @title ReentrancyAttacker
 * @notice Contract that attempts reentrancy attacks
 */
// tag::ReentrancyAttacker[]
contract ReentrancyAttacker {
    ReentrancyLockModifiersHarness public target;
    uint256 public attackCount;

    constructor(address _target) {
        target = ReentrancyLockModifiersHarness(_target);
    }

    function attack() external {
        target.protectedFunction();
    }

    // Fallback that attempts reentry
    fallback() external {
        if (attackCount < 3) {
            attackCount++;
            target.protectedFunction();
        }
    }
}
// end::ReentrancyAttacker[]

/**
 * @title ReentrancyLockRepo_Test
 * @notice Tests for ReentrancyLockRepo library (direct harness for _lock/_unlock/_isLocked/_onlyUnlocked).
 * @dev LR-7: full init with labels (no address(0) subjects); all asserts converted to exact assertEq/assertTrue.
 *      Reentrancy lock behavior proven (per PRD LR-7 #11). Uses expectRevert for error path (handler pattern).
 *      LR-1: NatSpec + // tag:: on contract + setUp + key tests. No facet here (see ReentrancyLockFacet_Test).
 */
// tag::ReentrancyLockRepo_Test[]
contract ReentrancyLockRepo_Test is Test {
    ReentrancyLockRepoHarness internal harness;

    function setUp() public {
        // LR-7 full realistic init (non-0 harness subject + label; no lazy 0). Direct Test ok for repo harness (modeled on access tests per AGENTS).
        harness = new ReentrancyLockRepoHarness();
        vm.label(address(harness), "ReentrancyLockRepoHarness");
    }

    // tag::test_isLocked_initiallyFalse()[]
    function test_isLocked_initiallyFalse() public view {
        assertEq(harness.isLocked(), false, "isLocked must be exact false initially");
    }
    // end::test_isLocked_initiallyFalse()[]

    // tag::test_lock_setsLockedTrue()[]
    function test_lock_setsLockedTrue() public {
        harness.lock();
        assertEq(harness.isLocked(), true, "isLocked must be exact true after _lock()");
    }
    // end::test_lock_setsLockedTrue()[]

    function test_unlock_setsLockedFalse() public {
        harness.lock();
        assertEq(harness.isLocked(), true, "exact true while locked");

        harness.unlock();
        assertEq(harness.isLocked(), false, "isLocked must be exact false after _unlock()");
    }

    function test_onlyUnlocked_whenUnlocked_succeeds() public view {
        // Should not revert (exact success path)
        harness.onlyUnlocked();
    }

    function test_onlyUnlocked_whenLocked_reverts() public {
        harness.lock();

        // LR-7: use vm.expectRevert on selector for error (handler style)
        vm.expectRevert(IReentrancyLock.IsLocked.selector);
        harness.onlyUnlocked();
    }

    function test_lockUnlock_multipleToggle() public {
        // Toggle multiple times; exact values
        for (uint256 i = 0; i < 5; i++) {
            assertEq(harness.isLocked(), false, "must be exact false before lock");
            harness.lock();
            assertEq(harness.isLocked(), true, "must be exact true after lock");
            harness.unlock();
        }
        assertEq(harness.isLocked(), false, "must be exact false at end");
    }
}
// end::ReentrancyLockRepo_Test[]

/**
 * @title ReentrancyLockModifiers_Test
 * @notice Tests for ReentrancyLockModifiers (nonReentrant modifier prevents reentry, unlocks on success/revert).
 * @dev LR-7: full init (harness + labels), exact asserts, reentrancy proof via attacker setup + expectRevert.
 *      Per PRD LR-7 item 11 for ReentrancyLockRepo usage.
 */
// tag::ReentrancyLockModifiers_Test[]
contract ReentrancyLockModifiers_Test is Test {
    ReentrancyLockModifiersHarness internal harness;

    function setUp() public {
        // LR-7: full non-0 init + label before asserts
        harness = new ReentrancyLockModifiersHarness();
        vm.label(address(harness), "ReentrancyLockModifiersHarness");
    }

    function test_lock_modifier_preventsReentrancy() public {
        // Set up the harness to call back into itself
        harness.setCallback(address(harness));

        // Reentrancy protection: expect exact selector (handler style)
        vm.expectRevert(IReentrancyLock.IsLocked.selector);
        harness.protectedFunction();
    }

    function test_lock_modifier_normalExecution_succeeds() public {
        harness.disableCallback();

        harness.protectedFunction();
        assertEq(harness.counter(), 1, "counter must be exact 1 after first protected call");

        harness.protectedFunction();
        assertEq(harness.counter(), 2, "counter must be exact 2 after second protected call");
    }

    function test_lock_modifier_unlocksAfterExecution() public {
        harness.disableCallback();

        assertEq(harness.isLockedView(), false, "isLockedView must be exact false before call");

        harness.protectedFunction();

        assertEq(harness.isLockedView(), false, "isLockedView must be exact false after call (unlocked)");
    }

    function test_lock_modifier_unlocksEvenOnRevert() public {
        // Create a new harness that will revert
        RevertingHarness revertingHarness = new RevertingHarness();
        vm.label(address(revertingHarness), "RevertingHarness");

        assertEq(revertingHarness.isLockedView(), false, "isLockedView exact false before");

        vm.expectRevert("Intentional revert");
        revertingHarness.revertingProtectedFunction();

        // After revert, lock should be reset (transient storage is reset on revert) - exact
        assertEq(revertingHarness.isLockedView(), false, "isLockedView must be exact false after revert");
    }
}
// end::ReentrancyLockModifiers_Test[]

/**
 * @title RevertingHarness
 * @notice Harness that reverts inside a locked function (used to prove unlock-on-revert for transient lock).
 */
// tag::RevertingHarness[]
contract RevertingHarness is ReentrancyLockModifiers {
    function revertingProtectedFunction() external nonReentrant {
        revert("Intentional revert");
    }

    function isLockedView() external view returns (bool) {
        return ReentrancyLockRepo._isLocked();
    }
}
// end::RevertingHarness[]

/**
 * @title ReentrancyLockFacet_Test
 * @notice Tests for ReentrancyLockFacet IFacet compliance + LR-7 declaration.
 * @dev LR-7: inherits CraneTest for full init bootstrap, deploys real ReentrancyLockFacet via AccessFacetFactoryService + create3Factory (non-0, labeled).
 *      Exact assertEq everywhere. Expanded mandatory Behavior_IFacet usage + dedicated declaration test (per AGENTS crane-testing + PRD LR-7).
 *      Uses ONLY central IFacet values (0x5b6f4d01 etc) from CENTRALLY_COMPUTED_NATSPEC_VALUES.md for comments/customs.
 *      LR-1: full NatSpec + // tag:: / end:: on contract + setUp + key tests + LR7 decl test.
 */
// tag::ReentrancyLockFacet_Test[]
contract ReentrancyLockFacet_Test is CraneTest {
    ReentrancyLockFacet internal facet;

    function setUp() public override {
        // LR-7: full realistic non-0 init via CraneTest.setUp (InitDevService factories) + real facet deployment via Access service factory pattern.
        // Never address(0); labels applied inside deploy. Subject ready for assertions.
        super.setUp();
        facet = ReentrancyLockFacet(address(AccessFacetFactoryService.deployReentrancyLockFacet(create3Factory)));
    }

    // tag::test_facetName_returnsCorrectName()[]
    function test_facetName_returnsCorrectName() public view {
        assertEq(facet.facetName(), "ReentrancyLockFacet", "facetName must be exact 'ReentrancyLockFacet'");
    }
    // end::test_facetName_returnsCorrectName()[]

    function test_facetInterfaces_returnsIsLockedSelector() public view {
        bytes4[] memory interfaces = facet.facetInterfaces();
        assertEq(interfaces.length, 1, "interfaces length must be exact 1");
        assertEq(interfaces[0], IReentrancyLock.isLocked.selector, "interfaces[0] must be exact IReentrancyLock.isLocked.selector");
    }

    function test_facetFuncs_returnsIsLockedSelector() public view {
        bytes4[] memory funcs = facet.facetFuncs();
        assertEq(funcs.length, 1, "funcs length must be exact 1");
        assertEq(funcs[0], ReentrancyLockTarget.isLocked.selector, "funcs[0] must be exact ReentrancyLockTarget.isLocked.selector");
    }

    function test_facetMetadata_returnsAllData() public view {
        (string memory name, bytes4[] memory interfaces, bytes4[] memory functions) = facet.facetMetadata();

        assertEq(name, "ReentrancyLockFacet", "metadata name exact");
        assertEq(interfaces.length, 1, "metadata interfaces length exact 1");
        assertEq(interfaces[0], IReentrancyLock.isLocked.selector, "metadata interfaces[0] exact selector");
        assertEq(functions.length, 1, "metadata functions length exact 1");
        assertEq(functions[0], ReentrancyLockTarget.isLocked.selector, "metadata functions[0] exact selector");
    }

    function test_isLocked_initiallyFalse() public view {
        assertEq(facet.isLocked(), false, "isLocked must be exact false initially on fresh facet (transient)");
    }

    /* -------------------------------------------------------------------------- */
    /*                 LR-7: Facet Declaration Tests via Behavior                 */
    /* -------------------------------------------------------------------------- */

    // tag::test_LR7_ReentrancyLockFacet_declaration_viaBehavior()[]
    /**
     * @notice LR-7 mandatory: ReentrancyLockFacet must declare correct IFacet metadata via Behavior_IFacet.
     *         Full init via CraneTest + factory service (real non-0 facet). Exact via Behavior + lengths.
     *         References central IFacet values (0x5b6f4d01 facetName, 0x2ea80826 interfaces, 0x574a4cff funcs, 0xf10d7a75 metadata) ONLY from CENTRALLY_COMPUTED_NATSPEC_VALUES.md.
     *         Also validates the single IReentrancyLock surface.
     * @custom:signature test_LR7_ReentrancyLockFacet_declaration_viaBehavior()
     */
    function test_LR7_ReentrancyLockFacet_declaration_viaBehavior() public {
        // LR-7: already full init in setUp (real deployed facet via Crane+service); re-label for clarity if needed
        IFacet facetAsIFacet = IFacet(address(facet));
        vm.label(address(facetAsIFacet), type(ReentrancyLockFacet).name);

        // Expected for this facet (IFacet from central 0x5b6f4d01 etc; 1 iface = IReentrancyLock.isLocked; 1 func)
        bytes4[] memory expectedIfaces = new bytes4[](1);
        expectedIfaces[0] = IReentrancyLock.isLocked.selector;

        bytes4[] memory expectedFuncs = new bytes4[](1);
        expectedFuncs[0] = ReentrancyLockTarget.isLocked.selector;

        // Mandatory Behavior_IFacet per LR-7 + AGENTS (expect then hasValid + consistency)
        Behavior_IFacet.expect_IFacet_facetName(facetAsIFacet, type(ReentrancyLockFacet).name);
        Behavior_IFacet.expect_IFacet_facetInterfaces(facetAsIFacet, expectedIfaces);
        Behavior_IFacet.expect_IFacet_facetFuncs(facetAsIFacet, expectedFuncs);

        assertTrue(Behavior_IFacet.hasValid_IFacet_facetName(facetAsIFacet), "facetName exact via Behavior_IFacet");
        assertTrue(Behavior_IFacet.hasValid_IFacet_facetInterfaces(facetAsIFacet), "facetInterfaces exact via Behavior_IFacet");
        assertTrue(Behavior_IFacet.hasValid_IFacet_facetFuncs(facetAsIFacet), "facetFuncs exact via Behavior_IFacet");
        assertTrue(
            Behavior_IFacet.isValid_IFacet_facetMetadata_consistency(facetAsIFacet),
            "facetMetadata consistency exact via Behavior_IFacet"
        );
    }
    // end::test_LR7_ReentrancyLockFacet_declaration_viaBehavior()[]
}
// end::ReentrancyLockFacet_Test[]

/**
 * @title ReentrancyLockTarget_Test
 * @notice Tests for ReentrancyLockTarget (thin impl delegating to Repo).
 * @dev LR-7: full init + labels + exact assert.
 */
// tag::ReentrancyLockTarget_Test[]
contract ReentrancyLockTarget_Test is Test {
    ReentrancyLockTarget internal target;
    ReentrancyLockRepoHarness internal harness;

    function setUp() public {
        // LR-7 full init (real targets/harnesses, labeled, no 0 subjects)
        target = new ReentrancyLockTarget();
        vm.label(address(target), "ReentrancyLockTarget");
        harness = new ReentrancyLockRepoHarness();
        vm.label(address(harness), "ReentrancyLockRepoHarness_forTarget");
    }

    function test_isLocked_initiallyFalse() public view {
        assertEq(target.isLocked(), false, "isLocked on Target must be exact false initially");
    }
}
// end::ReentrancyLockTarget_Test[]
