// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                              Balancer V3 Interfaces                        */
/* -------------------------------------------------------------------------- */

import {ICowPool} from "@balancer-labs/v3-interfaces/contracts/pool-cow/ICowPool.sol";

/**
 * @title CowPoolRepo
 * @notice Storage library for Balancer V3 CoW Pool trusted router and factory references.
 * @dev Implements the standard Crane Repo pattern with dual overloads (parameterized and default).
 * CoW Pools restrict swaps to a trusted router for MEV protection.
 *
 * @custom:storage-slot protocols.dexes.balancer.v3.pool.cow
 */
library CowPoolRepo {
    bytes32 internal constant STORAGE_SLOT = keccak256("protocols.dexes.balancer.v3.pool.cow");

    /* ------ Errors ------ */

    /// @notice Thrown when attempting to set an invalid (zero) trusted router address.
    error InvalidTrustedCowRouter();

    /// @notice Thrown when attempting to set an invalid (zero) factory address.
    error InvalidCowPoolFactory();

    /* ------ Storage ------ */

    /**
     * @notice Storage layout for CoW Pool.
     * @param trustedCowRouter The address of the trusted CoW Router for MEV-protected swaps.
     * @param cowPoolFactory The address of the factory that created this pool.
     */
    struct Storage {
        address trustedCowRouter;
        address cowPoolFactory;
    }

    /* ------ Layout Functions ------ */

    /**
     * @notice Returns a storage pointer for a given slot.
     * @param slot The storage slot to use.
     * @return layout Storage pointer.
     */
    function _layout(bytes32 slot) internal pure returns (Storage storage layout) {
        assembly {
            layout.slot := slot
        }
    }

    /**
     * @notice Returns a storage pointer using the default slot.
     * @return layout Storage pointer.
     */
    function _layout() internal pure returns (Storage storage layout) {
        return _layout(STORAGE_SLOT);
    }

    /* ------ Initialization ------ */

    /**
     * @notice Initialize the CoW Pool with factory and trusted router addresses.
     * @param layout Storage pointer.
     * @param cowPoolFactory_ The address of the factory creating this pool.
     * @param trustedCowRouter_ The address of the trusted CoW Router.
     */
    function _initialize(
        Storage storage layout,
        address cowPoolFactory_,
        address trustedCowRouter_
    ) internal {
        if (cowPoolFactory_ == address(0)) revert InvalidCowPoolFactory();
        if (trustedCowRouter_ == address(0)) revert InvalidTrustedCowRouter();

        layout.cowPoolFactory = cowPoolFactory_;
        layout.trustedCowRouter = trustedCowRouter_;

        emit ICowPool.CowTrustedRouterChanged(trustedCowRouter_);
    }

    /**
     * @notice Initialize the CoW Pool with factory and trusted router addresses (default slot).
     * @param cowPoolFactory_ The address of the factory creating this pool.
     * @param trustedCowRouter_ The address of the trusted CoW Router.
     */
    function _initialize(address cowPoolFactory_, address trustedCowRouter_) internal {
        _initialize(_layout(), cowPoolFactory_, trustedCowRouter_);
    }

    /* ------ Getters ------ */

    /**
     * @notice Get the trusted CoW Router address.
     * @param layout Storage pointer.
     * @return trustedCowRouter The trusted router address.
     */
    function _getTrustedCowRouter(Storage storage layout) internal view returns (address trustedCowRouter) {
        return layout.trustedCowRouter;
    }

    /**
     * @notice Get the trusted CoW Router address (default slot).
     * @return trustedCowRouter The trusted router address.
     */
    function _getTrustedCowRouter() internal view returns (address trustedCowRouter) {
        return _getTrustedCowRouter(_layout());
    }

    /**
     * @notice Get the factory address that created this pool.
     * @param layout Storage pointer.
     * @return cowPoolFactory The factory address.
     */
    function _getCowPoolFactory(Storage storage layout) internal view returns (address cowPoolFactory) {
        return layout.cowPoolFactory;
    }

    /**
     * @notice Get the factory address that created this pool (default slot).
     * @return cowPoolFactory The factory address.
     */
    function _getCowPoolFactory() internal view returns (address cowPoolFactory) {
        return _getCowPoolFactory(_layout());
    }

    /* ------ Setters ------ */

    /**
     * @notice Update the trusted CoW Router address.
     * @dev Emits CowTrustedRouterChanged event.
     * @param layout Storage pointer.
     * @param trustedCowRouter_ The new trusted router address.
     */
    function _setTrustedCowRouter(Storage storage layout, address trustedCowRouter_) internal {
        if (trustedCowRouter_ == address(0)) revert InvalidTrustedCowRouter();

        layout.trustedCowRouter = trustedCowRouter_;

        emit ICowPool.CowTrustedRouterChanged(trustedCowRouter_);
    }

    /**
     * @notice Update the trusted CoW Router address (default slot).
     * @param trustedCowRouter_ The new trusted router address.
     */
    function _setTrustedCowRouter(address trustedCowRouter_) internal {
        _setTrustedCowRouter(_layout(), trustedCowRouter_);
    }
}
