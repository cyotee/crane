// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

// tag::IHandler[]
/**
 * @title IHandler
 * @author cyotee doge <not_cyotee@proton.me>
 * @notice Minimal interface for handler contracts used in declarative invariant/fuzz testing.
 * @dev Handlers implement `selectors()` to declare which of their public functions should be
 *      exercised by Foundry's StdInvariant (via `targetSelector(FuzzSelector{...})`).
 *      Positive paths and "must-revert" negative proofs are both registered.
 *      See AGENTS.md "Declarative Invariant Testing Pattern", usage in TestBase_IMultiStepOwnable,
 *      and docs/development/testing.md. Per PRD LR-1 (NatSpec on all test files incl. handlers)
 *      and LR-7 (handler expectEmit / exact state tracking).
 * @custom:interfaceid 0x6e25b978
 */
interface IHandler {
    // tag::selectors()[]
    /**
     * @notice Returns the exact handler function selectors to register for invariant fuzzing.
     * @dev Implementations typically return both mutative actions and access-control "attacker" proofs.
     * @return selectors_ Array of 4-byte selectors (from `this.foo.selector` etc).
     * @custom:signature selectors()
     * @custom:selector 0x6e25b978
     */
    function selectors() external view returns (bytes4[] memory selectors_);
    // end::selectors()[]
}
// end::IHandler[]
