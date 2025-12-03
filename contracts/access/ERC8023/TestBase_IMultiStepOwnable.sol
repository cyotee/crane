// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                   Foundry                                  */
/* -------------------------------------------------------------------------- */

import "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {IMultiStepOwnable} from "contracts/interfaces/IMultiStepOwnable.sol";

contract MultiStepOwnableHandler is Test {
    IMultiStepOwnable public immutable ownable;

    // Actor system – 2025 gold standard
    address[] public actors;
    address public currentActor;

    modifier useActor(uint256 actorIndexSeed) {
        currentActor = actors[bound(actorIndexSeed, 0, actors.length - 1)];
        vm.startPrank(currentActor);
        _;
        vm.stopPrank();
    }

    // Ghost variables
    address public ghostCurrentOwner;
    uint256 public immutable ghostBuffer;

    constructor(IMultiStepOwnable _ownable) {
        ownable = _ownable;
        ghostCurrentOwner = _ownable.owner();
        ghostBuffer = _ownable.getOwnershipTransferBuffer();

        // Diverse actors that have found real bugs in 2024–2025
        actors.push(address(0));
        actors.push(address(0x1));
        actors.push(address(0x4));
        actors.push(address(this));
        actors.push(address(_ownable));
        actors.push(makeAddr("alice"));
        actors.push(makeAddr("bob"));
        actors.push(makeAddr("eve"));
        actors.push(makeAddr("mallory"));
        actors.push(address(0xDEAD));
        actors.push(address(0xBEEF));
        actors.push(address(0xFFFF));
        actors.push(ghostCurrentOwner); // filtered out in negative tests
    }

    // ======================= POSITIVE PATHS =======================

    function initiateOwnershipTransfer(address newOwner) public {
        vm.assume(newOwner != address(0));
        vm.assume(newOwner != address(this));
        vm.prank(ghostCurrentOwner);
        try ownable.initiateOwnershipTransfer(newOwner) {} catch {}
    }

    function confirmOwnershipTransfer(address newOwner) public {
        vm.prank(ghostCurrentOwner);
        try ownable.confirmOwnershipTransfer(newOwner) {} catch {}
    }

    function acceptOwnershipTransfer() public {
        address pending = ownable.pendingOwner();
        if (pending == address(0)) return;

        vm.prank(pending);
        try ownable.acceptOwnershipTransfer() {
            ghostCurrentOwner = pending; // update ghost on success
        } catch {}
    }

    function cancelPendingOwnershipTransfer() public {
        vm.prank(ghostCurrentOwner);
        try ownable.cancelPendingOwnershipTransfer() {} catch {}
    }

    // ======================= NEGATIVE PATHS (must revert) =======================

    function attacker_initiateOwnershipTransfer(uint256 actorSeed, address newOwner) public useActor(actorSeed) {
        vm.assume(newOwner != address(0));
        vm.assume(currentActor != ghostCurrentOwner);

        vm.expectRevert(IMultiStepOwnable.NotOwner.selector);
        ownable.initiateOwnershipTransfer(newOwner);
    }

    function attacker_confirmOwnershipTransfer(uint256 actorSeed, address newOwner) public useActor(actorSeed) {
        vm.assume(currentActor != ghostCurrentOwner);

        vm.expectRevert(IMultiStepOwnable.NotOwner.selector);
        ownable.confirmOwnershipTransfer(newOwner);
    }

    function attacker_cancelPendingOwnershipTransfer(uint256 actorSeed) public useActor(actorSeed) {
        vm.assume(currentActor != ghostCurrentOwner);

        vm.expectRevert(IMultiStepOwnable.NotOwner.selector);
        ownable.cancelPendingOwnershipTransfer();
    }

    function attacker_acceptOwnershipTransfer(uint256 actorSeed) public useActor(actorSeed) {
        address pending = ownable.pendingOwner();
        vm.assume(currentActor != pending);

        vm.expectRevert(IMultiStepOwnable.NotPending.selector);
        ownable.acceptOwnershipTransfer();
    }

    function wrongGuy_acceptOwnershipTransfer(uint256 actorSeed) public useActor(actorSeed) {
        address pending = ownable.pendingOwner();
        vm.assume(pending != address(0));
        vm.assume(currentActor != pending);

        vm.expectRevert(IMultiStepOwnable.NotPending.selector);
        ownable.acceptOwnershipTransfer();
    }
}

abstract contract TestBase_IMultiStepOwnable is StdInvariant, Test {
    IMultiStepOwnable public ownable;
    MultiStepOwnableHandler public handler;

    function _deployOwnable() internal virtual returns (IMultiStepOwnable);

    // ←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←
    // You MUST override setUp() in your child contract and assign `ownable`
    // ←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←

    function setUp() public virtual {
        // require(address(ownable) != address(0), "ownable not set in child test");
        ownable = _deployOwnable();

        handler = new MultiStepOwnableHandler(ownable);

        targetContract(address(handler));

        bytes4[] memory selectors = new bytes4[](9);
        selectors[0] = handler.initiateOwnershipTransfer.selector;
        selectors[1] = handler.confirmOwnershipTransfer.selector;
        selectors[2] = handler.acceptOwnershipTransfer.selector;
        selectors[3] = handler.cancelPendingOwnershipTransfer.selector;

        // Access-control proofs (must always revert)
        selectors[4] = handler.attacker_initiateOwnershipTransfer.selector;
        selectors[5] = handler.attacker_confirmOwnershipTransfer.selector;
        selectors[6] = handler.attacker_cancelPendingOwnershipTransfer.selector;
        selectors[7] = handler.attacker_acceptOwnershipTransfer.selector;
        selectors[8] = handler.wrongGuy_acceptOwnershipTransfer.selector;

        FuzzSelector({addr: address(handler), selectors: selectors});
        excludeContract(address(ownable));
    }

    // ====================================================================
    //                             INVARIANTS
    // ====================================================================

    function invariant_owner_never_zero() public view {
        assertTrue(ownable.owner() != address(0));
    }

    function invariant_buffer_is_constant() public view {
        assertEq(ownable.getOwnershipTransferBuffer(), handler.ghostBuffer());
    }

    function invariant_only_owner_has_power() public view {
        address o = ownable.owner();
        assertTrue(ownable.pendingOwner() != o);
        assertTrue(ownable.preConfirmedOwner() != o);
    }

    function invariant_owner_only_changes_after_full_transfer() public view {
        if (ownable.owner() != handler.ghostCurrentOwner()) {
            assertEq(ownable.pendingOwner(), address(0));
            assertEq(ownable.preConfirmedOwner(), address(0));
        }
    }

    function invariant_pending_and_preconfirmed_exclusive() public view {
        address pending = ownable.pendingOwner();
        address pre = ownable.preConfirmedOwner();
        if (pending != address(0) && pre != address(0)) {
            assertEq(pending, pre);
        }
    }
}
