// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.30;

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";

import {IBasePoolFactory} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IBasePoolFactory.sol";
import {ISenderGuard} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/ISenderGuard.sol";
import {IVault} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IVault.sol";
import {
    LiquidityManagement,
    TokenConfig,
    PoolSwapParams,
    HookFlags
} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/VaultTypes.sol";

import {BaseHooksTarget} from "./BaseHooksTarget.sol";

/* -------------------------------------------------------------------------- */
/*                       VeBALFeeDiscountHookExample                          */
/* -------------------------------------------------------------------------- */

/**
 * @title VeBALFeeDiscountHookExample
 * @notice Provides a 50% swap fee discount to veBAL token holders.
 * @dev Uses the dynamic fee mechanism to reward veBAL holders with reduced fees.
 *
 * Security considerations:
 * - Only works with trusted routers that correctly implement `getSender()`
 * - Untrusted routers could spoof the sender address
 * - Restricts to pools from a specific factory
 *
 * @custom:security-contact security@example.com
 */
contract VeBALFeeDiscountHookExample is BaseHooksTarget {
    /* ========================================================================== */
    /*                                   STORAGE                                  */
    /* ========================================================================== */

    /// @notice The only factory whose pools can use this hook.
    address private immutable _allowedFactory;

    /// @notice The only router trusted to provide accurate sender information.
    address private immutable _trustedRouter;

    /// @notice The veBAL token used to check for discount eligibility.
    IERC20 private immutable _veBAL;

    /* ========================================================================== */
    /*                                   EVENTS                                   */
    /* ========================================================================== */

    /**
     * @notice Emitted when this hook is successfully registered.
     * @param hooksContract This contract's address.
     * @param factory The factory that created the pool.
     * @param pool The pool address.
     */
    event VeBALFeeDiscountHookExampleRegistered(
        address indexed hooksContract,
        address indexed factory,
        address indexed pool
    );

    /* ========================================================================== */
    /*                                 CONSTRUCTOR                                */
    /* ========================================================================== */

    /**
     * @notice Creates a new VeBALFeeDiscountHookExample.
     * @param vault_ The Balancer V3 Vault address.
     * @param allowedFactory_ The factory whose pools can register this hook.
     * @param veBAL_ The veBAL token address for eligibility checks.
     * @param trustedRouter_ The router trusted to provide accurate sender info.
     */
    constructor(
        IVault vault_,
        address allowedFactory_,
        address veBAL_,
        address trustedRouter_
    ) BaseHooksTarget(vault_) {
        _allowedFactory = allowedFactory_;
        _trustedRouter = trustedRouter_;
        _veBAL = IERC20(veBAL_);
    }

    /* ========================================================================== */
    /*                               HOOK CALLBACKS                               */
    /* ========================================================================== */

    /// @inheritdoc BaseHooksTarget
    function getHookFlags() public pure override returns (HookFlags memory hookFlags) {
        hookFlags.shouldCallComputeDynamicSwapFee = true;
    }

    /// @inheritdoc BaseHooksTarget
    function onRegister(
        address factory,
        address pool,
        TokenConfig[] memory,
        LiquidityManagement calldata
    ) public override onlyVault returns (bool) {
        emit VeBALFeeDiscountHookExampleRegistered(address(this), factory, pool);

        // Restrictive: only pools from the allowed factory
        return factory == _allowedFactory &&
            IBasePoolFactory(factory).isPoolFromFactory(pool);
    }

    /// @inheritdoc BaseHooksTarget
    function onComputeDynamicSwapFeePercentage(
        PoolSwapParams calldata params,
        address,
        uint256 staticSwapFeePercentage
    ) public view override onlyVault returns (bool, uint256) {
        // Security: Only apply discount via trusted router
        // Untrusted routers could manipulate getSender()
        if (params.router != _trustedRouter) {
            return (true, staticSwapFeePercentage);
        }

        // Get the actual user initiating the swap
        address user = ISenderGuard(params.router).getSender();

        // 50% discount for veBAL holders
        if (_veBAL.balanceOf(user) > 0) {
            return (true, staticSwapFeePercentage / 2);
        }

        return (true, staticSwapFeePercentage);
    }
}
