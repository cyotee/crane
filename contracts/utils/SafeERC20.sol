// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SafeTransferLib} from "@crane/contracts/tokens/ERC20/utils/SafeTransferLib.sol";
import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IERC20Permit} from "@crane/contracts/interfaces/IERC20Permit.sol";

/**
 * @dev OpenZeppelin-compatible SafeERC20 wrapper using Solady's SafeTransferLib.
 * @notice Native Crane implementation - delegates to Solady
 *
 * This provides OpenZeppelin API compatibility while leveraging Solady's
 * gas-optimized implementations.
 */
library SafeERC20 {
    /**
     * @dev An operation with an ERC-20 token failed.
     */
    error SafeERC20FailedOperation(address token);

    /**
     * @dev Indicates a failed `decreaseAllowance` request.
     */
    error SafeERC20FailedDecreaseAllowance(address spender, uint256 currentAllowance, uint256 requestedDecrease);

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        SafeTransferLib.safeTransfer(address(token), to, value);
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        SafeTransferLib.safeTransferFrom(address(token), from, to, value);
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     *
     * IMPORTANT: If the token implements ERC-7674 (ERC-20 with temporary allowance), and if the "client"
     * smart contract uses ERC-7674 to set temporary allowances, then the "client" smart contract should avoid using
     * this function. Performing a {safeIncreaseAllowance} or {safeDecreaseAllowance} operation on a token contract
     * that has a non-zero temporary allowance (for that particular owner-spender) will result in unexpected behavior.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        forceApprove(token, spender, oldAllowance + value);
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `requestedDecrease`. If `token` returns no
     * value, non-reverting calls are assumed to be successful.
     *
     * IMPORTANT: If the token implements ERC-7674 (ERC-20 with temporary allowance), and if the "client"
     * smart contract uses ERC-7674 to set temporary allowances, then the "client" smart contract should avoid using
     * this function. Performing a {safeIncreaseAllowance} or {safeDecreaseAllowance} operation on a token contract
     * that has a non-zero temporary allowance (for that particular owner-spender) will result in unexpected behavior.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 requestedDecrease) internal {
        unchecked {
            uint256 currentAllowance = token.allowance(address(this), spender);
            if (currentAllowance < requestedDecrease) {
                revert SafeERC20FailedDecreaseAllowance(spender, currentAllowance, requestedDecrease);
            }
            forceApprove(token, spender, currentAllowance - requestedDecrease);
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     *
     * NOTE: If the token implements ERC-7674, this function will not modify any temporary allowance. This function
     * only sets the "standard" allowance. Any temporary allowance will remain active, in addition to the value being
     * set here.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        SafeTransferLib.safeApproveWithRetry(address(token), spender, value);
    }

    /**
     * @dev Variant of {forceApprove} that accepts a boolean `approve` parameter.
     * - If `approve` is true, sets allowance to `type(uint256).max`.
     * - If `approve` is false, sets allowance to 0.
     */
    function forceApprove(IERC20 token, address spender, bool approve) internal {
        forceApprove(token, spender, approve ? type(uint256).max : 0);
    }

    /**
     * @dev Try to transfer `value` amount of `token` from the calling contract to `to`.
     * Returns true if successful, false otherwise.
     */
    function trySafeTransfer(IERC20 token, address to, uint256 value) internal returns (bool) {
        // Solady doesn't have trySafeTransfer for ERC20 (only for ETH), so we implement it
        // by catching the revert from safeTransfer
        try IERC20(token).transfer(to, value) returns (bool success) {
            // Check for non-standard tokens that don't return a value
            return success || _hasNoCode(address(token));
        } catch {
            return false;
        }
    }

    /**
     * @dev Try to transfer `value` amount of `token` from `from` to `to`.
     * Returns true if successful, false otherwise.
     */
    function trySafeTransferFrom(IERC20 token, address from, address to, uint256 value) internal returns (bool) {
        return SafeTransferLib.trySafeTransferFrom(address(token), from, to, value);
    }

    /**
     * @dev Helper to check if an address has no code (used for non-standard token handling).
     */
    function _hasNoCode(address account) private view returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := iszero(extcodesize(account))
        }
    }
}
