// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.24;

/// @title Wired — one-time deploy-phase wiring
/// @notice Some contracts reference each other cyclically and cannot take
///         every address as a constructor argument. Those contracts expose a
///         single `wire`-style function guarded by this base: callable only
///         by the deployer, exactly once, during the deploy transaction
///         batch. After wiring there is NO mutable address surface — the
///         invariant suite asserts re-wiring reverts (specs/mechanism.md §6
///         item 7).
abstract contract Wired {
    error NotDeployer();
    error AlreadyWired();
    error NotWired();
    error ZeroAddress();

    address internal immutable _deployer;
    bool public wired;

    constructor() {
        _deployer = msg.sender;
    }

    modifier wiring() {
        if (msg.sender != _deployer) revert NotDeployer();
        if (wired) revert AlreadyWired();
        wired = true;
        _;
    }

    function _checkWired() internal view {
        if (!wired) revert NotWired();
    }

    function _nonZero(address a) internal pure returns (address) {
        if (a == address(0)) revert ZeroAddress();
        return a;
    }
}
