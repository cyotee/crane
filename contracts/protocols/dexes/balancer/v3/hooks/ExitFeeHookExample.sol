// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.30;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {IVault} from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import {
    AddLiquidityKind,
    AddLiquidityParams,
    LiquidityManagement,
    RemoveLiquidityKind,
    TokenConfig,
    HookFlags
} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";

import {FixedPoint} from "@balancer-labs/v3-solidity-utils/contracts/math/FixedPoint.sol";

import {BaseHooksTarget} from "./BaseHooksTarget.sol";

/* -------------------------------------------------------------------------- */
/*                            ExitFeeHookExample                              */
/* -------------------------------------------------------------------------- */

/**
 * @title ExitFeeHookExample
 * @notice Imposes an "exit fee" on pool withdrawals, returning the fee to LPs via donation.
 * @dev This hook extracts a fee on all proportional withdrawals, then donates it back to the
 * pool (effectively increasing the value of BPT shares for all remaining LPs).
 *
 * Design constraints:
 * - Only supports proportional remove liquidity (EXACT_OUT would require BPT fees)
 * - Pool must have `enableHookAdjustedAmounts` set to true
 * - Pool must support donation for fee redistribution
 *
 * @custom:security-contact security@example.com
 */
contract ExitFeeHookExample is BaseHooksTarget, Ownable {
    using FixedPoint for uint256;

    /* ========================================================================== */
    /*                                  CONSTANTS                                 */
    /* ========================================================================== */

    /// @notice Maximum exit fee percentage (10% in 18-decimal fixed point).
    uint64 public constant MAX_EXIT_FEE_PERCENTAGE = 10e16;

    /* ========================================================================== */
    /*                                   STORAGE                                  */
    /* ========================================================================== */

    /// @notice Current exit fee percentage (18-decimal fixed point).
    /// @dev 60 bits are sufficient since max value is FixedPoint.ONE (100%).
    uint64 public exitFeePercentage;

    /* ========================================================================== */
    /*                                   EVENTS                                   */
    /* ========================================================================== */

    /**
     * @notice Emitted when this hook is successfully registered for a pool.
     * @param hooksContract This contract's address.
     * @param pool The pool address where the hook was registered.
     */
    event ExitFeeHookExampleRegistered(address indexed hooksContract, address indexed pool);

    /**
     * @notice Emitted when an exit fee is charged on a withdrawal.
     * @param pool The pool that was charged.
     * @param token The fee token address.
     * @param feeAmount The fee amount in native token decimals.
     */
    event ExitFeeCharged(address indexed pool, IERC20 indexed token, uint256 feeAmount);

    /**
     * @notice Emitted when the exit fee percentage is changed.
     * @param hookContract This contract's address.
     * @param exitFeePercentage The new exit fee percentage.
     */
    event ExitFeePercentageChanged(address indexed hookContract, uint256 exitFeePercentage);

    /* ========================================================================== */
    /*                                   ERRORS                                   */
    /* ========================================================================== */

    /**
     * @notice Thrown when the exit fee exceeds the maximum allowed.
     * @param feePercentage The attempted fee percentage.
     * @param limit The maximum allowed percentage.
     */
    error ExitFeeAboveLimit(uint256 feePercentage, uint256 limit);

    /**
     * @notice Thrown when a pool doesn't support donation (required for fee redistribution).
     */
    error PoolDoesNotSupportDonation();

    /* ========================================================================== */
    /*                                 CONSTRUCTOR                                */
    /* ========================================================================== */

    /**
     * @notice Creates a new ExitFeeHookExample.
     * @param vault_ The Balancer V3 Vault address.
     */
    constructor(IVault vault_) BaseHooksTarget(vault_) Ownable(msg.sender) {
        // Exit fee starts at 0; owner can set it later
    }

    /* ========================================================================== */
    /*                               HOOK CALLBACKS                               */
    /* ========================================================================== */

    /// @inheritdoc BaseHooksTarget
    function onRegister(
        address,
        address pool,
        TokenConfig[] memory,
        LiquidityManagement calldata liquidityManagement
    ) public override onlyVault returns (bool) {
        // NOTE: In production hooks, verify the factory and pool origin.
        // This example allows any pool that supports donation.

        if (liquidityManagement.enableDonation == false) {
            revert PoolDoesNotSupportDonation();
        }

        emit ExitFeeHookExampleRegistered(address(this), pool);

        return true;
    }

    /// @inheritdoc BaseHooksTarget
    function getHookFlags() public pure override returns (HookFlags memory hookFlags) {
        // enableHookAdjustedAmounts must be true for hooks that modify amountCalculated
        hookFlags.enableHookAdjustedAmounts = true;
        hookFlags.shouldCallAfterRemoveLiquidity = true;
    }

    /// @inheritdoc BaseHooksTarget
    function onAfterRemoveLiquidity(
        address,
        address pool,
        RemoveLiquidityKind kind,
        uint256,
        uint256[] memory,
        uint256[] memory amountsOutRaw,
        uint256[] memory,
        bytes memory
    ) public override onlyVault returns (bool, uint256[] memory hookAdjustedAmountsOutRaw) {
        // Only support proportional removes (non-proportional would require BPT fees)
        if (kind != RemoveLiquidityKind.PROPORTIONAL) {
            return (false, amountsOutRaw);
        }

        IERC20[] memory tokens = _vault.getPoolTokens(pool);
        uint256[] memory accruedFees = new uint256[](tokens.length);
        hookAdjustedAmountsOutRaw = amountsOutRaw;

        if (exitFeePercentage > 0) {
            // Charge fees proportional to each token's amountOut
            for (uint256 i = 0; i < amountsOutRaw.length; i++) {
                uint256 exitFee = amountsOutRaw[i].mulDown(exitFeePercentage);
                accruedFees[i] = exitFee;
                hookAdjustedAmountsOutRaw[i] -= exitFee;

                emit ExitFeeCharged(pool, tokens[i], exitFee);
            }

            // Donate fees back to LPs (increases remaining BPT value)
            _vault.addLiquidity(
                AddLiquidityParams({
                    pool: pool,
                    to: msg.sender, // Router; donation mints no BPT
                    maxAmountsIn: accruedFees,
                    minBptAmountOut: 0, // Donation returns 0 BPT
                    kind: AddLiquidityKind.DONATION,
                    userData: bytes("")
                })
            );
        }

        return (true, hookAdjustedAmountsOutRaw);
    }

    /* ========================================================================== */
    /*                              ADMIN FUNCTIONS                               */
    /* ========================================================================== */

    /**
     * @notice Sets the exit fee percentage charged on proportional withdrawals.
     * @dev Only callable by the owner. Fee is capped at MAX_EXIT_FEE_PERCENTAGE.
     * @param newExitFeePercentage The new fee percentage (18-decimal fixed point).
     */
    function setExitFeePercentage(uint64 newExitFeePercentage) external onlyOwner {
        if (newExitFeePercentage > MAX_EXIT_FEE_PERCENTAGE) {
            revert ExitFeeAboveLimit(newExitFeePercentage, MAX_EXIT_FEE_PERCENTAGE);
        }
        exitFeePercentage = newExitFeePercentage;

        emit ExitFeePercentageChanged(address(this), newExitFeePercentage);
    }
}
