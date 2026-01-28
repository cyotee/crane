// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IAuthorizer} from "@balancer-labs/v3-interfaces/contracts/vault/IAuthorizer.sol";
import {IProtocolFeeController} from "@balancer-labs/v3-interfaces/contracts/vault/IProtocolFeeController.sol";
import {IVault} from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";

import {IDiamond} from "@crane/contracts/interfaces/IDiamond.sol";
import {IDiamondLoupe} from "@crane/contracts/interfaces/IDiamondLoupe.sol";

import {Proxy} from "@crane/contracts/proxies/Proxy.sol";
import {ERC2535Repo} from "@crane/contracts/introspection/ERC2535/ERC2535Repo.sol";

import {BalancerV3VaultStorageRepo} from "./BalancerV3VaultStorageRepo.sol";

/* -------------------------------------------------------------------------- */
/*                           BalancerV3VaultDiamond                           */
/* -------------------------------------------------------------------------- */

/**
 * @title BalancerV3VaultDiamond
 * @notice Diamond proxy implementing Balancer V3 Vault functionality.
 * @dev This contract serves as the entry point for all Vault operations,
 * delegating calls to appropriate facets based on function selectors.
 *
 * Architecture:
 * - Inherits Crane's Proxy base for standard Diamond delegatecall pattern
 * - Uses ERC2535Repo for facet address lookup (O(1) by selector)
 * - Uses BalancerV3VaultStorageRepo for Balancer-specific storage
 *
 * Facets (must be added via diamondCut):
 * - VaultTransientFacet: unlock(), settle(), sendTo()
 * - VaultSwapFacet: swap() with hooks and fees
 * - VaultLiquidityFacet: addLiquidity(), removeLiquidity()
 * - VaultBufferFacet: erc4626BufferWrapOrUnwrap()
 * - VaultPoolTokenFacet: BPT transfer/approve
 * - VaultQueryFacet: view functions
 * - VaultRegistrationFacet: registerPool(), initialize()
 * - VaultAdminFacet: admin functions
 * - VaultRecoveryFacet: removeLiquidityRecovery()
 *
 * Key design decisions:
 * 1. No constructor initialization - use initialize() via delegatecall
 * 2. Facets must be cut in before use
 * 3. Transient storage slots are precomputed constants (no immutables needed)
 */
contract BalancerV3VaultDiamond is Proxy {
    /* ========================================================================== */
    /*                                   ERRORS                                   */
    /* ========================================================================== */

    /// @dev Thrown when attempting to re-initialize an already initialized Diamond.
    error AlreadyInitialized();

    /// @dev Thrown when caller is not authorized for admin operations.
    error Unauthorized();

    /* ========================================================================== */
    /*                                   EVENTS                                   */
    /* ========================================================================== */

    /// @dev Emitted when the Diamond is initialized with Balancer V3 configuration.
    event BalancerV3VaultInitialized(
        uint256 minimumTradeAmount,
        uint256 minimumWrapAmount,
        uint32 pauseWindowDuration,
        uint32 bufferPeriodDuration,
        IAuthorizer authorizer,
        IProtocolFeeController protocolFeeController
    );

    /* ========================================================================== */
    /*                               INITIALIZATION                               */
    /* ========================================================================== */

    /**
     * @notice Initializes the Balancer V3 Vault Diamond.
     * @dev This function should be called via diamondCut's init callback.
     * Can only be called once due to BalancerV3VaultStorageRepo's internal check.
     *
     * @param minimumTradeAmount_ Minimum trade amount in scaled18
     * @param minimumWrapAmount_ Minimum wrap amount in native decimals
     * @param pauseWindowDuration Duration of pause window from deployment
     * @param bufferPeriodDuration Duration of buffer period after pause window
     * @param authorizer_ Initial authorizer contract
     * @param protocolFeeController_ Protocol fee controller contract
     */
    function initializeVault(
        uint256 minimumTradeAmount_,
        uint256 minimumWrapAmount_,
        uint32 pauseWindowDuration,
        uint32 bufferPeriodDuration,
        IAuthorizer authorizer_,
        IProtocolFeeController protocolFeeController_
    ) external {
        // BalancerV3VaultStorageRepo._initialize will revert if already initialized
        BalancerV3VaultStorageRepo._initialize(
            minimumTradeAmount_,
            minimumWrapAmount_,
            pauseWindowDuration,
            bufferPeriodDuration,
            authorizer_,
            protocolFeeController_
        );

        emit BalancerV3VaultInitialized(
            minimumTradeAmount_,
            minimumWrapAmount_,
            pauseWindowDuration,
            bufferPeriodDuration,
            authorizer_,
            protocolFeeController_
        );
    }

    /* ========================================================================== */
    /*                              DIAMOND FUNCTIONS                             */
    /* ========================================================================== */

    /**
     * @notice Performs a Diamond cut to add/replace/remove facets.
     * @dev Should be protected by governance/authorizer in production.
     * This is a simple implementation; consider adding access control.
     *
     * @param cuts Array of FacetCut structs specifying facet changes
     * @param initTarget Address to delegatecall for initialization (or address(0))
     * @param initCalldata Calldata for initialization delegatecall
     */
    function diamondCut(
        IDiamond.FacetCut[] memory cuts,
        address initTarget,
        bytes memory initCalldata
    ) external {
        // In production, add access control here
        // For now, allow during setup phase
        _ensureAuthorizedForDiamondCut();

        ERC2535Repo._diamondCut(cuts, initTarget, initCalldata);
    }

    /**
     * @notice Returns the vault address (self-reference for IVault compatibility).
     * @return vault The vault address (this contract)
     */
    function vault() external view returns (IVault) {
        return IVault(address(this));
    }

    /* ========================================================================== */
    /*                            INTERNAL FUNCTIONS                              */
    /* ========================================================================== */

    /**
     * @notice Returns the facet address for the current function selector.
     * @dev Implements Proxy's abstract _getTarget function.
     * @return target_ The facet address that handles msg.sig
     */
    function _getTarget() internal view override returns (address target_) {
        return ERC2535Repo._facetAddress(msg.sig);
    }

    /**
     * @notice Checks if caller is authorized for diamondCut operations.
     * @dev Can be customized to use IAuthorizer for governance control.
     * Current implementation allows cuts only when vault is not initialized
     * OR when caller is authorized by the authorizer.
     */
    function _ensureAuthorizedForDiamondCut() internal view {
        BalancerV3VaultStorageRepo.Storage storage layout = BalancerV3VaultStorageRepo._layout();

        // Allow cuts before initialization (setup phase)
        if (!layout.initialized) {
            return;
        }

        // After initialization, require authorizer approval
        IAuthorizer authorizer = layout.authorizer;
        if (address(authorizer) != address(0)) {
            // Use a specific action ID for diamondCut
            bytes32 actionId = keccak256(abi.encodePacked(bytes32(uint256(uint160(address(this)))), msg.sig));
            if (!authorizer.canPerform(actionId, msg.sender, address(this))) {
                revert Unauthorized();
            }
        } else {
            // No authorizer set after initialization - deny all cuts
            revert Unauthorized();
        }
    }
}
