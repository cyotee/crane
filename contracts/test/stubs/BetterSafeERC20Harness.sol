// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IERC20Metadata} from "@crane/contracts/interfaces/IERC20Metadata.sol";
import {BetterIERC20} from "@crane/contracts/interfaces/BetterIERC20.sol";
import {BetterSafeERC20} from "@crane/contracts/tokens/ERC20/utils/BetterSafeERC20.sol";

// tag::BetterSafeERC20Harness[]
/**
 * @title BetterSafeERC20Harness
 * @author cyotee doge <not_cyotee@proton.me>
 * @notice Test harness that exposes BetterSafeERC20 internal functions for testing.
 * @dev Not intended for production use. A minimal low-complexity test subject (like GreeterTarget, Counter).
 *      Uses `using BetterSafeERC20 for ...` to surface the library extensions as external callables in tests.
 */
contract BetterSafeERC20Harness {
    using BetterSafeERC20 for IERC20;
    using BetterSafeERC20 for IERC20Metadata;

    /* -------------------------------------------------------------------------- */
    /*                              Wrapper Functions                             */
    /* -------------------------------------------------------------------------- */

    // tag::safeTransfer(IERC20-address-uint256)[]
    /**
     * @notice Wrapper exposing BetterSafeERC20.safeTransfer.
     * @dev Delegates to the token's using extension.
     * @param token The IERC20 to operate on.
     * @param to The recipient address.
     * @param value The amount to transfer.
     * @return success True on success.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) external returns (bool) {
        return token.safeTransfer(to, value);
    }
    // end::safeTransfer(IERC20-address-uint256)[]

    // tag::safeTransferFrom(IERC20-address-address-uint256)[]
    /**
     * @notice Wrapper exposing BetterSafeERC20.safeTransferFrom.
     * @dev Delegates to the token's using extension.
     * @param token The IERC20 to operate on.
     * @param from The sender address.
     * @param to The recipient address.
     * @param value The amount to transfer.
     * @return success True on success.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) external returns (bool) {
        return token.safeTransferFrom(from, to, value);
    }
    // end::safeTransferFrom(IERC20-address-address-uint256)[]

    // tag::trySafeTransfer(IERC20-address-uint256)[]
    /**
     * @notice Wrapper exposing BetterSafeERC20.trySafeTransfer (non-reverting variant).
     * @dev Delegates to the token's using extension.
     * @param token The IERC20 to operate on.
     * @param to The recipient address.
     * @param value The amount to transfer.
     * @return success True if transfer succeeded without revert.
     */
    function trySafeTransfer(IERC20 token, address to, uint256 value) external returns (bool) {
        return token.trySafeTransfer(to, value);
    }
    // end::trySafeTransfer(IERC20-address-uint256)[]

    // tag::trySafeTransferFrom(IERC20-address-address-uint256)[]
    /**
     * @notice Wrapper exposing BetterSafeERC20.trySafeTransferFrom (non-reverting variant).
     * @dev Delegates to the token's using extension.
     * @param token The IERC20 to operate on.
     * @param from The sender address.
     * @param to The recipient address.
     * @param value The amount to transfer.
     * @return success True if transfer succeeded without revert.
     */
    function trySafeTransferFrom(IERC20 token, address from, address to, uint256 value) external returns (bool) {
        return token.trySafeTransferFrom(from, to, value);
    }
    // end::trySafeTransferFrom(IERC20-address-address-uint256)[]

    // tag::safeIncreaseAllowance(IERC20-address-uint256)[]
    /**
     * @notice Wrapper exposing BetterSafeERC20.safeIncreaseAllowance.
     * @dev Delegates to the token's using extension. Reverts on failure.
     * @param token The IERC20 to operate on.
     * @param spender The spender address.
     * @param value The allowance delta to add.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) external {
        token.safeIncreaseAllowance(spender, value);
    }
    // end::safeIncreaseAllowance(IERC20-address-uint256)[]

    // tag::safeDecreaseAllowance(IERC20-address-uint256)[]
    /**
     * @notice Wrapper exposing BetterSafeERC20.safeDecreaseAllowance.
     * @dev Delegates to the token's using extension. Reverts on failure.
     * @param token The IERC20 to operate on.
     * @param spender The spender address.
     * @param value The allowance delta to subtract.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) external {
        token.safeDecreaseAllowance(spender, value);
    }
    // end::safeDecreaseAllowance(IERC20-address-uint256)[]

    // tag::forceApprove(IERC20-address-uint256)[]
    /**
     * @notice Wrapper exposing BetterSafeERC20.forceApprove.
     * @dev Delegates to the token's using extension. Reverts on failure.
     * @param token The IERC20 to operate on.
     * @param spender The spender address.
     * @param value The allowance value to force-set.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) external {
        token.forceApprove(spender, value);
    }
    // end::forceApprove(IERC20-address-uint256)[]

    // tag::safeApprove(IERC20-address-uint256)[]
    /**
     * @notice Wrapper exposing BetterSafeERC20.safeApprove.
     * @dev Delegates to the token's using extension. Reverts on failure.
     * @param token The IERC20 to operate on.
     * @param spender The spender address.
     * @param value The allowance value to set.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) external {
        token.safeApprove(spender, value);
    }
    // end::safeApprove(IERC20-address-uint256)[]

    /* -------------------------------------------------------------------------- */
    /*                            Safe Metadata Functions                         */
    /* -------------------------------------------------------------------------- */

    // tag::safeName(IERC20Metadata)[]
    /**
     * @notice Wrapper exposing BetterSafeERC20.safeName.
     * @dev Delegates to the metadata asset's using extension.
     * @param asset The IERC20Metadata asset.
     * @return The safe-decoded name string.
     */
    function safeName(IERC20Metadata asset) external view returns (string memory) {
        return asset.safeName();
    }
    // end::safeName(IERC20Metadata)[]

    // tag::safeSymbol(IERC20Metadata)[]
    /**
     * @notice Wrapper exposing BetterSafeERC20.safeSymbol.
     * @dev Delegates to the metadata asset's using extension.
     * @param asset The IERC20Metadata asset.
     * @return The safe-decoded symbol string.
     */
    function safeSymbol(IERC20Metadata asset) external view returns (string memory) {
        return asset.safeSymbol();
    }
    // end::safeSymbol(IERC20Metadata)[]

    // tag::safeDecimals(IERC20Metadata)[]
    /**
     * @notice Wrapper exposing BetterSafeERC20.safeDecimals.
     * @dev Delegates to the metadata asset's using extension.
     * @param asset The IERC20Metadata asset.
     * @return The safe-decoded decimals.
     */
    function safeDecimals(IERC20Metadata asset) external view returns (uint8) {
        return asset.safeDecimals();
    }
    // end::safeDecimals(IERC20Metadata)[]

    /* -------------------------------------------------------------------------- */
    /*                              Utility Functions                             */
    /* -------------------------------------------------------------------------- */

    // tag::cast(IERC20[]-memory)[]
    /**
     * @notice Wrapper exposing BetterSafeERC20.cast (IERC20[] -> BetterIERC20[]).
     * @dev Delegates to the library cast utility.
     * @param tokens The array of IERC20 tokens to cast.
     * @return The cast array of BetterIERC20.
     */
    function cast(IERC20[] memory tokens) external pure returns (BetterIERC20[] memory) {
        return BetterSafeERC20.cast(tokens);
    }
    // end::cast(IERC20[]-memory)[]
}
// end::BetterSafeERC20Harness[]
