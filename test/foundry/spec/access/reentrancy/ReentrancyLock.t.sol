// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {ReentrancyLockRepo} from "@crane/contracts/access/reentrancy/ReentrancyLockRepo.sol";
import {ReentrancyLockModifiers} from "@crane/contracts/access/reentrancy/ReentrancyLockModifiers.sol";
import {ReentrancyLockFacet} from "@crane/contracts/access/reentrancy/ReentrancyLockFacet.sol";
import {ReentrancyLockTarget} from "@crane/contracts/access/reentrancy/ReentrancyLockTarget.sol";
import {IReentrancyLock} from "@crane/contracts/interfaces/IReentrancyLock.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";

/**
 * @title ReentrancyLockRepoHarness
 * @notice Test harness that exposes ReentrancyLockRepo internal library functions
 */
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

/**
 * @title ReentrancyLockModifiersHarness
 * @notice Test harness for testing the lock modifier
 */
contract ReentrancyLockModifiersHarness is ReentrancyLockModifiers {
    uint256 public counter;
    bool public callbackEnabled;
    address public callbackTarget;

    function protectedFunction() external lock {
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

/**
 * @title ReentrancyAttacker
 * @notice Contract that attempts reentrancy attacks
 */
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

/**
 * @title ReentrancyLockRepo_Test
 * @notice Tests for ReentrancyLockRepo library
 */
contract ReentrancyLockRepo_Test is Test {
    ReentrancyLockRepoHarness internal harness;

    function setUp() public {
        harness = new ReentrancyLockRepoHarness();
    }

    function test_isLocked_initiallyFalse() public view {
        assertFalse(harness.isLocked(), "Should be unlocked initially");
    }

    function test_lock_setsLockedTrue() public {
        harness.lock();
        assertTrue(harness.isLocked(), "Should be locked after _lock()");
    }

    function test_unlock_setsLockedFalse() public {
        harness.lock();
        assertTrue(harness.isLocked());

        harness.unlock();
        assertFalse(harness.isLocked(), "Should be unlocked after _unlock()");
    }

    function test_onlyUnlocked_whenUnlocked_succeeds() public view {
        // Should not revert
        harness.onlyUnlocked();
    }

    function test_onlyUnlocked_whenLocked_reverts() public {
        harness.lock();

        vm.expectRevert(IReentrancyLock.IsLocked.selector);
        harness.onlyUnlocked();
    }

    function test_lockUnlock_multipleToggle() public {
        // Toggle multiple times
        for (uint256 i = 0; i < 5; i++) {
            assertFalse(harness.isLocked());
            harness.lock();
            assertTrue(harness.isLocked());
            harness.unlock();
        }
        assertFalse(harness.isLocked());
    }
}

/**
 * @title ReentrancyLockModifiers_Test
 * @notice Tests for ReentrancyLockModifiers
 */
contract ReentrancyLockModifiers_Test is Test {
    ReentrancyLockModifiersHarness internal harness;

    function setUp() public {
        harness = new ReentrancyLockModifiersHarness();
    }

    function test_lock_modifier_preventsReentrancy() public {
        // Set up the harness to call back into itself
        harness.setCallback(address(harness));

        // This should revert due to reentrancy protection
        vm.expectRevert(IReentrancyLock.IsLocked.selector);
        harness.protectedFunction();
    }

    function test_lock_modifier_normalExecution_succeeds() public {
        harness.disableCallback();

        harness.protectedFunction();
        assertEq(harness.counter(), 1);

        harness.protectedFunction();
        assertEq(harness.counter(), 2);
    }

    function test_lock_modifier_unlocksAfterExecution() public {
        harness.disableCallback();

        assertFalse(harness.isLockedView(), "Should be unlocked before call");

        harness.protectedFunction();

        assertFalse(harness.isLockedView(), "Should be unlocked after call");
    }

    function test_lock_modifier_unlocksEvenOnRevert() public {
        // Create a new harness that will revert
        RevertingHarness revertingHarness = new RevertingHarness();

        assertFalse(revertingHarness.isLockedView(), "Should be unlocked before");

        vm.expectRevert("Intentional revert");
        revertingHarness.revertingProtectedFunction();

        // After revert, lock should be reset (transient storage is reset on revert)
        assertFalse(revertingHarness.isLockedView(), "Should be unlocked after revert");
    }
}

/**
 * @title RevertingHarness
 * @notice Harness that reverts inside a locked function
 */
contract RevertingHarness is ReentrancyLockModifiers {
    function revertingProtectedFunction() external lock {
        revert("Intentional revert");
    }

    function isLockedView() external view returns (bool) {
        return ReentrancyLockRepo._isLocked();
    }
}

/**
 * @title ReentrancyLockFacet_Test
 * @notice Tests for ReentrancyLockFacet IFacet compliance
 */
contract ReentrancyLockFacet_Test is Test {
    ReentrancyLockFacet internal facet;

    function setUp() public {
        facet = new ReentrancyLockFacet();
    }

    function test_facetName_returnsCorrectName() public view {
        assertEq(facet.facetName(), "ReentrancyLockFacet");
    }

    function test_facetInterfaces_returnsIsLockedSelector() public view {
        bytes4[] memory interfaces = facet.facetInterfaces();
        assertEq(interfaces.length, 1);
        assertEq(interfaces[0], IReentrancyLock.isLocked.selector);
    }

    function test_facetFuncs_returnsIsLockedSelector() public view {
        bytes4[] memory funcs = facet.facetFuncs();
        assertEq(funcs.length, 1);
        assertEq(funcs[0], ReentrancyLockTarget.isLocked.selector);
    }

    function test_facetMetadata_returnsAllData() public view {
        (string memory name, bytes4[] memory interfaces, bytes4[] memory functions) = facet.facetMetadata();

        assertEq(name, "ReentrancyLockFacet");
        assertEq(interfaces.length, 1);
        assertEq(interfaces[0], IReentrancyLock.isLocked.selector);
        assertEq(functions.length, 1);
        assertEq(functions[0], ReentrancyLockTarget.isLocked.selector);
    }

    function test_isLocked_initiallyFalse() public view {
        assertFalse(facet.isLocked());
    }
}

/**
 * @title ReentrancyLockTarget_Test
 * @notice Tests for ReentrancyLockTarget
 */
contract ReentrancyLockTarget_Test is Test {
    ReentrancyLockTarget internal target;
    ReentrancyLockRepoHarness internal harness;

    function setUp() public {
        target = new ReentrancyLockTarget();
        harness = new ReentrancyLockRepoHarness();
    }

    function test_isLocked_initiallyFalse() public view {
        assertFalse(target.isLocked());
    }
}
