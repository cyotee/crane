// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.20;

/* -------------------------------------------------------------------------- */
/*                                Open Zppelin                                */
/* -------------------------------------------------------------------------- */

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC1363} from "@openzeppelin/contracts/interfaces/IERC1363.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {BetterAddress} from "contracts/utils/BetterAddress.sol";
import {BetterIERC20} from "contracts/interfaces/BetterIERC20.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
// TODO Write NatSpec comments.
// TODO Complete unit testing for all functions.
library BetterSafeERC20 {
    using BetterAddress for address;
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC1363;

    /* ---------------------------------------------------------------------- */
    /*               Wrapper Functions for Drop-In Compatibility              */
    /* ---------------------------------------------------------------------- */

    function safeTransfer(IERC20 token, address to, uint256 value) internal returns (bool) {
        token.safeTransfer(to, value);
        return true;
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal returns (bool) {
        token.safeTransferFrom(from, to, value);
        return true;
    }

    function trySafeTransfer(IERC20 token, address to, uint256 value) internal returns (bool) {
        return token.trySafeTransfer(to, value);
    }

    function trySafeTransferFrom(IERC20 token, address from, address to, uint256 value) internal returns (bool) {
        return token.trySafeTransferFrom(from, to, value);
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        token.safeIncreaseAllowance(spender, value);
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        token.safeDecreaseAllowance(spender, value);
    }

    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        token.forceApprove(spender, value);
    }

    function transferAndCallRelaxed(IERC1363 token, address to, uint256 value, bytes memory data) internal {
        token.transferAndCallRelaxed(to, value, data);
    }

    function transferFromAndCallRelaxed(IERC1363 token, address from, address to, uint256 value, bytes memory data)
        internal
    {
        token.transferFromAndCallRelaxed(from, to, value, data);
    }

    function approveAndCallRelaxed(IERC1363 token, address to, uint256 value, bytes memory data) internal {
        token.approveAndCallRelaxed(to, value, data);
    }

    /* ---------------------------------------------------------------------- */
    /*                                New Logic                               */
    /* ---------------------------------------------------------------------- */

    /**
     * @dev Attempts to fetch the asset decimals. A return value of false indicates that the attempt failed in some way.
     */
    function safeDecimals(IERC20Metadata asset_) internal view returns (uint8) {
        (bool success, bytes memory encodedDecimals) =
            address(asset_).staticcall(abi.encodeCall(IERC20Metadata.decimals, ()));
        if (success && encodedDecimals.length >= 32) {
            uint256 returnedDecimals = abi.decode(encodedDecimals, (uint256));
            if (returnedDecimals <= type(uint8).max) {
                return (uint8(returnedDecimals));
            }
        }
        return (18);
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial or zero allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        uint256 returnSize;
        uint256 returnValue;
        assembly ("memory-safe") {
            let success := call(gas(), token, 0, add(data, 0x20), mload(data), 0, 0x20)
            // bubble errors
            if iszero(success) {
                let ptr := mload(0x40)
                returndatacopy(ptr, 0, returndatasize())
                revert(ptr, returndatasize())
            }
            returnSize := returndatasize()
            returnValue := mload(0)
        }

        if (returnSize == 0 ? address(token).code.length == 0 : returnValue != 1) {
            revert SafeERC20.SafeERC20FailedOperation(address(token));
        }
    }

    function cast(IERC20[] memory tokens) internal pure returns (BetterIERC20[] memory betterTokens) {
        betterTokens = new BetterIERC20[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            betterTokens[i] = BetterIERC20(address(tokens[i]));
        }
    }
}
