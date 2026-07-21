// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IWETH} from "@crane/contracts/interfaces/protocols/tokens/wrappers/weth/v9/IWETH.sol";
import {BetterSafeERC20 as SafeERC20} from "@crane/contracts/tokens/ERC20/utils/BetterSafeERC20.sol";

/**
 * @title EthereumStakingLib
 * @notice Shared ETH↔WETH helpers and safe approve patterns for staking Services.
 */
library EthereumStakingLib {
    using SafeERC20 for IERC20;

    error ZeroAddress();
    error ZeroAmount();
    error InsufficientETH(uint256 have, uint256 need);

    function _wrapETH(IWETH weth, uint256 amount) internal {
        if (address(weth) == address(0)) revert ZeroAddress();
        if (amount == 0) revert ZeroAmount();
        if (address(this).balance < amount) revert InsufficientETH(address(this).balance, amount);
        weth.deposit{value: amount}();
    }

    function _unwrapWETH(IWETH weth, uint256 amount) internal {
        if (address(weth) == address(0)) revert ZeroAddress();
        if (amount == 0) revert ZeroAmount();
        weth.withdraw(amount);
    }

    /// @dev Reset-to-zero then set allowance (handles non-standard ERC20s).
    function _forceApprove(IERC20 token, address spender, uint256 amount) internal {
        if (address(token) == address(0) || spender == address(0)) revert ZeroAddress();
        uint256 current = token.allowance(address(this), spender);
        if (current != 0) {
            token.forceApprove(spender, 0);
        }
        if (amount != 0) {
            token.forceApprove(spender, amount);
        }
    }
}
