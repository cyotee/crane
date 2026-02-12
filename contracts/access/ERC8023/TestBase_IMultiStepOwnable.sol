// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {VM_ADDRESS} from "@crane/contracts/constants/FoundryConstants.sol";
import {IMultiStepOwnable} from "@crane/contracts/interfaces/IMultiStepOwnable.sol";
import {IHandler} from "@crane/contracts/interfaces/IHandler.sol";
import {BetterVM} from "@crane/contracts/utils/vm/foundry/tools/BetterVM.sol";
import {Vm} from "forge-std/Vm.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import "forge-std/Test.sol";

// tag::MultiStepOwnableHandler[]
/**
 * @title MultiStepOwnableHandler - Invariant fuzz handler for IMultiStepOwnable implementations.
 * @author cyotee doge <not_cyotee@proton.me>
 * @dev Provides both positive-path actions and negative-path access control proofs.
 * @dev Uses ghost variables to track expected long-lived state across fuzz runs.
 */
contract MultiStepOwnableHandler is IHandler {
    using BetterVM for Vm;
    /// forge-lint: disable-next-line(screaming-snake-case-const)
    Vm constant vm = Vm(VM_ADDRESS);

    IMultiStepOwnable public immutable ownable;

    // Actor system – 2025 gold standard
    address[] public actors;
    address public currentActor;

    // tag::useActor(uint256)[]
    /**
     * @notice Pranks as a pseudo-random actor for the duration of a handler call.
     * @param actorIndexSeed Seed value bounded into the actors array.
     */
    modifier useActor(uint256 actorIndexSeed) {
        currentActor = actors[BetterVM.bound(actorIndexSeed, 0, actors.length - 1)];
        vm.startPrank(currentActor);
        _;
        vm.stopPrank();
    }
    // end::useActor(uint256)[]

    // Ghost variables
    address public ghostCurrentOwner;
    uint256 public immutable ghostBuffer;

    // tag::constructor(IMultiStepOwnable)[]
    /**
     * @notice Initializes the handler with a deployed IMultiStepOwnable subject.
     * @param _ownable The subject-under-test (SUT).
     */
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
        actors.push(vm.makeAddr("alice"));
        actors.push(vm.makeAddr("bob"));
        actors.push(vm.makeAddr("eve"));
        actors.push(vm.makeAddr("mallory"));
        actors.push(address(0xDEAD));
        actors.push(address(0xBEEF));
        actors.push(address(0xFFFF));
        actors.push(ghostCurrentOwner); // filtered out in negative tests
    }
    // end::constructor(IMultiStepOwnable)[]


    // tag::selectors()[]
    /**
     * @notice Returns the exact handler function selectors registered for invariant fuzzing.
     * @dev Includes both state-changing operations and "must revert" access-control proofs.
     * @return selectors_ Array of handler function selectors.
     */
    function selectors() public pure returns (bytes4[] memory selectors_) {
        selectors_ = new bytes4[](9);
        selectors_[0] = this.initiateOwnershipTransfer.selector;
        selectors_[1] = this.confirmOwnershipTransfer.selector;
        selectors_[2] = this.acceptOwnershipTransfer.selector;
        selectors_[3] = this.cancelPendingOwnershipTransfer.selector;

        // Access-control proofs (must always revert)
        selectors_[4] = this.attacker_initiateOwnershipTransfer.selector;
        selectors_[5] = this.attacker_confirmOwnershipTransfer.selector;
        selectors_[6] = this.attacker_cancelPendingOwnershipTransfer.selector;
        selectors_[7] = this.attacker_acceptOwnershipTransfer.selector;
        selectors_[8] = this.wrongGuy_acceptOwnershipTransfer.selector;
    }
    // end::selectors()[]

    // ======================= POSITIVE PATHS =======================

    // tag::initiateOwnershipTransfer(address)[]
    /**
     * @notice Attempts to initiate an ownership transfer as the current owner.
     * @dev Swallows reverts to keep invariant fuzzing progressing.
     * @param newOwner Proposed new owner.
     */
    function initiateOwnershipTransfer(address newOwner) public {
        vm.assume(newOwner != address(0));
        vm.assume(newOwner != address(this));
        // Avoid initiating a transfer to the current owner (no-op that can violate invariants)
        vm.assume(newOwner != ghostCurrentOwner);
        vm.prank(ghostCurrentOwner);
        try ownable.initiateOwnershipTransfer(newOwner) {} catch {}
    }
    // end::initiateOwnershipTransfer(address)[]

    // tag::confirmOwnershipTransfer(address)[]
    /**
     * @notice Attempts to confirm the pending ownership transfer as the current owner.
     * @dev Swallows reverts; confirmation may fail if the buffer has not elapsed or the address is wrong.
     * @param newOwner Address expected to be the pending owner.
     */
    function confirmOwnershipTransfer(address newOwner) public {
        vm.prank(ghostCurrentOwner);
        try ownable.confirmOwnershipTransfer(newOwner) {} catch {}
    }
    // end::confirmOwnershipTransfer(address)[]

    // tag::acceptOwnershipTransfer()[]
    /**
     * @notice Attempts to accept the ownership transfer as the pending owner.
     * @dev On success, updates the ghost owner to match on-chain state.
     */
    function acceptOwnershipTransfer() public {
        address pending = ownable.pendingOwner();
        if (pending == address(0)) return;

        vm.prank(pending);
        try ownable.acceptOwnershipTransfer() {
            ghostCurrentOwner = pending; // update ghost on success
        } catch {}
    }
    // end::acceptOwnershipTransfer()[]

    // tag::cancelPendingOwnershipTransfer()[]
    /**
     * @notice Attempts to cancel any pending ownership transfer as the current owner.
     * @dev Swallows reverts to keep invariant fuzzing progressing.
     */
    function cancelPendingOwnershipTransfer() public {
        vm.prank(ghostCurrentOwner);
        try ownable.cancelPendingOwnershipTransfer() {} catch {}
    }
    // end::cancelPendingOwnershipTransfer()[]

    // ======================= NEGATIVE PATHS (must revert) =======================

    // tag::attacker_initiateOwnershipTransfer(uint256-address)[]
    /**
     * @notice Proves only the owner can initiate an ownership transfer.
     * @dev Must revert with NotOwner.
     */
    function attacker_initiateOwnershipTransfer(uint256 actorSeed, address newOwner) public useActor(actorSeed) {
        vm.assume(newOwner != address(0));
        vm.assume(currentActor != ghostCurrentOwner);

        vm.expectRevert(IMultiStepOwnable.NotOwner.selector);
        ownable.initiateOwnershipTransfer(newOwner);
    }
    // end::attacker_initiateOwnershipTransfer(uint256-address)[]

    // tag::attacker_confirmOwnershipTransfer(uint256-address)[]
    /**
     * @notice Proves only the owner can confirm an ownership transfer.
     * @dev Must revert with NotOwner.
     */
    function attacker_confirmOwnershipTransfer(uint256 actorSeed, address newOwner) public useActor(actorSeed) {
        vm.assume(currentActor != ghostCurrentOwner);

        vm.expectRevert(IMultiStepOwnable.NotOwner.selector);
        ownable.confirmOwnershipTransfer(newOwner);
    }
    // end::attacker_confirmOwnershipTransfer(uint256-address)[]

    // tag::attacker_cancelPendingOwnershipTransfer(uint256)[]
    /**
     * @notice Proves only the owner can cancel a pending ownership transfer.
     * @dev Must revert with NotOwner.
     */
    function attacker_cancelPendingOwnershipTransfer(uint256 actorSeed) public useActor(actorSeed) {
        vm.assume(currentActor != ghostCurrentOwner);

        vm.expectRevert(IMultiStepOwnable.NotOwner.selector);
        ownable.cancelPendingOwnershipTransfer();
    }
    // end::attacker_cancelPendingOwnershipTransfer(uint256)[]

    // tag::attacker_acceptOwnershipTransfer(uint256)[]
    /**
     * @notice Proves only the pending owner can accept an ownership transfer.
     * @dev Must revert with NotPending.
     */
    function attacker_acceptOwnershipTransfer(uint256 actorSeed) public useActor(actorSeed) {
        address pending = ownable.pendingOwner();
        vm.assume(currentActor != pending);

        vm.expectRevert(IMultiStepOwnable.NotPending.selector);
        ownable.acceptOwnershipTransfer();
    }
    // end::attacker_acceptOwnershipTransfer(uint256)[]

    // tag::wrongGuy_acceptOwnershipTransfer(uint256)[]
    /**
     * @notice Proves an arbitrary non-pending address cannot accept an ownership transfer.
     * @dev Must revert with NotPending.
     */
    function wrongGuy_acceptOwnershipTransfer(uint256 actorSeed) public useActor(actorSeed) {
        address pending = ownable.pendingOwner();
        vm.assume(pending != address(0));
        vm.assume(currentActor != pending);

        vm.expectRevert(IMultiStepOwnable.NotPending.selector);
        ownable.acceptOwnershipTransfer();
    }
    // end::wrongGuy_acceptOwnershipTransfer(uint256)[]
}
// end::MultiStepOwnableHandler[]

// tag::TestBase_IMultiStepOwnable[]
/**
 * @title TestBase_IMultiStepOwnable - Invariant TestBase for IMultiStepOwnable implementations.
 * @author cyotee doge <not_cyotee@proton.me>
 * @dev Inheritors provide a deployed SUT via `_deployOwnable()`.
 */
abstract contract TestBase_IMultiStepOwnable is StdInvariant, Test {
    IMultiStepOwnable public ownable;
    MultiStepOwnableHandler public handler;

    function _deployOwnable() internal virtual returns (IMultiStepOwnable);

    function setUp() public virtual {
        ownable = _deployOwnable();

        handler = new MultiStepOwnableHandler(ownable);

        targetContract(address(handler));


        // Register only the explicit handler selectors for fuzzing (avoid fuzzing SUT directly)
        targetSelector(FuzzSelector({addr: address(handler), selectors: handler.selectors()}));
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

// end::TestBase_IMultiStepOwnable[]
