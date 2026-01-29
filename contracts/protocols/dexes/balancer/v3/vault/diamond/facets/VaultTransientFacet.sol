// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.30;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

import {IVaultMain} from "@balancer-labs/v3-interfaces/contracts/vault/IVaultMain.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";

import {StorageSlotExtension} from "@balancer-labs/v3-solidity-utils/contracts/openzeppelin/StorageSlotExtension.sol";
import {TransientStorageHelpers} from "@balancer-labs/v3-solidity-utils/contracts/helpers/TransientStorageHelpers.sol";

import {BalancerV3VaultStorageRepo} from "../BalancerV3VaultStorageRepo.sol";
import {BalancerV3VaultModifiers} from "../BalancerV3VaultModifiers.sol";

/* -------------------------------------------------------------------------- */
/*                            VaultTransientFacet                             */
/* -------------------------------------------------------------------------- */

/**
 * @title VaultTransientFacet
 * @notice Handles transient accounting operations: unlock, settle, sendTo.
 * @dev This facet implements the core transient accounting mechanism from IVaultMain.
 *
 * Key functions:
 * - unlock(): Opens a transient context for batched operations
 * - settle(): Records token credits from deposits
 * - sendTo(): Records token debits and transfers tokens out
 *
 * The transient accounting system uses EIP-1153 transient storage to track
 * token deltas (debits and credits) within a single transaction. All deltas
 * must settle to zero before the unlock context closes.
 */
contract VaultTransientFacet is BalancerV3VaultModifiers, IFacet {
    using SafeERC20 for IERC20;
    using Address for address;
    using TransientStorageHelpers for *;
    using StorageSlotExtension for *;

    /* ========================================================================== */
    /*                                  MODIFIERS                                 */
    /* ========================================================================== */

    /**
     * @dev Modifier for functions that temporarily modify token deltas.
     * Ensures all balances are settled by the time execution completes.
     *
     * On first unlock:
     * - Sets isUnlocked to true
     * - Executes the function body
     * - Verifies all deltas are zero
     * - Sets isUnlocked to false
     * - Increments session ID
     *
     * If already unlocked (nested), just executes the body.
     */
    modifier transient() {
        bool isUnlockedBefore = _isUnlocked().tload();

        if (isUnlockedBefore == false) {
            _isUnlocked().tstore(true);
        }

        // The caller does everything here and has to settle all outstanding balances.
        _;

        if (isUnlockedBefore == false) {
            if (_nonZeroDeltaCount().tload() != 0) {
                revert BalanceNotSettled();
            }

            _isUnlocked().tstore(false);

            // Round-trip fee prevention: increment session counter after locking.
            // This prevents fee charging when add/remove liquidity happen in
            // separate unlock calls within the same transaction.
            _sessionIdSlot().tIncrement();
        }
    }

    /* ========================================================================== */
    /*                                  IFacet                                    */
    /* ========================================================================== */

    /// @inheritdoc IFacet
    function facetName() public pure returns (string memory name) {
        return type(VaultTransientFacet).name;
    }

    /// @inheritdoc IFacet
    function facetInterfaces() public pure returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](1);
        interfaces[0] = type(IVaultMain).interfaceId;
    }

    /// @inheritdoc IFacet
    function facetFuncs() public pure returns (bytes4[] memory funcs) {
        funcs = new bytes4[](8);
        funcs[0] = this.unlock.selector;
        funcs[1] = this.settle.selector;
        funcs[2] = this.sendTo.selector;
        funcs[3] = this.isUnlocked.selector;
        funcs[4] = this.reentrancyGuardEntered.selector;
        // IVaultExtension transient accounting reads
        funcs[5] = this.getNonzeroDeltaCount.selector;
        funcs[6] = this.getTokenDelta.selector;
        funcs[7] = this.getAddLiquidityCalledFlag.selector;
    }

    /// @inheritdoc IFacet
    function facetMetadata()
        external
        pure
        returns (string memory name_, bytes4[] memory interfaces, bytes4[] memory functions)
    {
        name_ = facetName();
        interfaces = facetInterfaces();
        functions = facetFuncs();
    }

    /* ========================================================================== */
    /*                              EXTERNAL FUNCTIONS                            */
    /* ========================================================================== */

    /**
     * @notice Opens a transient context and executes arbitrary operations.
     * @dev The caller must ensure all token deltas are settled before returning.
     *
     * This function:
     * 1. Opens a transient unlock context
     * 2. Calls back to msg.sender with the provided data
     * 3. Verifies all deltas are zero on return
     * 4. Closes the context and increments session
     *
     * @param data ABI-encoded function call to execute on msg.sender
     * @return result The return data from the callback
     */
    function unlock(bytes calldata data) external transient returns (bytes memory result) {
        return (msg.sender).functionCall(data);
    }

    /**
     * @notice Records credit for tokens deposited to the vault.
     * @dev Called after transferring tokens to the vault to record the credit.
     *
     * The actual credit is computed as the difference between current balance
     * and stored reserves. If more tokens were sent than the hint suggests,
     * the excess is ignored (left in vault as a donation).
     *
     * @param token The token that was deposited
     * @param amountHint The expected amount deposited (used to cap credit)
     * @return credit The actual credit amount recorded
     */
    function settle(
        IERC20 token,
        uint256 amountHint
    ) external nonReentrant onlyWhenUnlocked returns (uint256 credit) {
        BalancerV3VaultStorageRepo.Storage storage layout = BalancerV3VaultStorageRepo._layout();

        uint256 reservesBefore = layout.reservesOf[token];
        uint256 currentReserves = token.balanceOf(address(this));
        layout.reservesOf[token] = currentReserves;
        credit = currentReserves - reservesBefore;

        // Cap the credit at the hint amount to handle leftover tokens
        if (credit > amountHint) {
            credit = amountHint;
        }

        _supplyCredit(token, credit);
    }

    /**
     * @notice Records debt and transfers tokens out of the vault.
     * @dev Records the debit first, then transfers. If the debit isn't
     * settled before the unlock context closes, the transaction reverts.
     *
     * @param token The token to send
     * @param to The recipient address
     * @param amount The amount to send
     */
    function sendTo(
        IERC20 token,
        address to,
        uint256 amount
    ) external nonReentrant onlyWhenUnlocked {
        BalancerV3VaultStorageRepo.Storage storage layout = BalancerV3VaultStorageRepo._layout();

        _takeDebt(token, amount);
        layout.reservesOf[token] -= amount;

        token.safeTransfer(to, amount);
    }

    /* ========================================================================== */
    /*                               VIEW FUNCTIONS                               */
    /* ========================================================================== */

    /**
     * @notice Returns whether the vault is currently in an unlocked state.
     * @return True if unlocked, false otherwise
     */
    function isUnlocked() external view returns (bool) {
        return _isUnlocked().tload();
    }

    /**
     * @notice Returns the current reentrancy guard state.
     * @return True if a nonReentrant function is currently executing
     */
    function reentrancyGuardEntered() external view returns (bool) {
        return _reentrancyGuardEntered();
    }

    /**
     * @notice Returns the count of non-zero token deltas.
     * @dev Part of IVaultExtension. Used to check if all balances are settled.
     * @return nonzeroDeltaCount The number of tokens with non-zero deltas
     */
    function getNonzeroDeltaCount() external view returns (uint256) {
        return _nonZeroDeltaCount().tload();
    }

    /**
     * @notice Retrieves the token delta for a specific token.
     * @dev Part of IVaultExtension. Returns the current credit/debit for a token.
     * @param token The token to query
     * @return tokenDelta The current delta (positive = credit, negative = debit)
     */
    function getTokenDelta(IERC20 token) external view returns (int256) {
        return _tokenDeltas().tGet(token);
    }

    /**
     * @notice Returns whether addLiquidity was called for a pool in the current session.
     * @dev Part of IVaultExtension. Used for round-trip fee protection.
     * @param pool The pool address
     * @return liquidityAdded True if liquidity was added in this session
     */
    function getAddLiquidityCalledFlag(address pool) external view returns (bool) {
        uint256 sessionId = _sessionIdSlot().tload();
        return _addLiquidityCalled().tGet(sessionId, pool);
    }
}
