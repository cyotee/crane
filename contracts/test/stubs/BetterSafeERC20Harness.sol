// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IERC20Metadata} from "@crane/contracts/interfaces/IERC20Metadata.sol";
import {BetterIERC20} from "@crane/contracts/interfaces/BetterIERC20.sol";
import {BetterSafeERC20} from "@crane/contracts/tokens/ERC20/utils/BetterSafeERC20.sol";

/**
 * @title BetterSafeERC20Harness
 * @notice Test harness that exposes BetterSafeERC20 internal functions for testing.
 */
contract BetterSafeERC20Harness {
    using BetterSafeERC20 for IERC20;
    using BetterSafeERC20 for IERC20Metadata;

    /* -------------------------------------------------------------------------- */
    /*                              Wrapper Functions                             */
    /* -------------------------------------------------------------------------- */

    function safeTransfer(IERC20 token, address to, uint256 value) external returns (bool) {
        return token.safeTransfer(to, value);
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) external returns (bool) {
        return token.safeTransferFrom(from, to, value);
    }

    function trySafeTransfer(IERC20 token, address to, uint256 value) external returns (bool) {
        return token.trySafeTransfer(to, value);
    }

    function trySafeTransferFrom(IERC20 token, address from, address to, uint256 value) external returns (bool) {
        return token.trySafeTransferFrom(from, to, value);
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) external {
        token.safeIncreaseAllowance(spender, value);
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) external {
        token.safeDecreaseAllowance(spender, value);
    }

    function forceApprove(IERC20 token, address spender, uint256 value) external {
        token.forceApprove(spender, value);
    }

    function safeApprove(IERC20 token, address spender, uint256 value) external {
        token.safeApprove(spender, value);
    }

    /* -------------------------------------------------------------------------- */
    /*                            Safe Metadata Functions                         */
    /* -------------------------------------------------------------------------- */

    function safeName(IERC20Metadata asset) external view returns (string memory) {
        return asset.safeName();
    }

    function safeSymbol(IERC20Metadata asset) external view returns (string memory) {
        return asset.safeSymbol();
    }

    function safeDecimals(IERC20Metadata asset) external view returns (uint8) {
        return asset.safeDecimals();
    }

    /* -------------------------------------------------------------------------- */
    /*                              Utility Functions                             */
    /* -------------------------------------------------------------------------- */

    function cast(IERC20[] memory tokens) external pure returns (BetterIERC20[] memory) {
        return BetterSafeERC20.cast(tokens);
    }
}
