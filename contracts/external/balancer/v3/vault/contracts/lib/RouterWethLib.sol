// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.24;

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "@crane/contracts/utils/SafeERC20.sol";
import {Address} from "@crane/contracts/utils/Address.sol";

import { IWETH } from "@crane/contracts/external/balancer/v3/interfaces/contracts/solidity-utils/misc/IWETH.sol";
import { IVault } from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IVault.sol";

library RouterWethLib {
    using Address for address payable;
    using SafeERC20 for IERC20;

    /// @notice The amount of ETH paid is insufficient to complete this operation.
    error InsufficientEth();

    function wrapEthAndSettle(IWETH weth, IVault vault, uint256 amountToSettle) internal {
        if (address(this).balance < amountToSettle) {
            revert InsufficientEth();
        }

        // wrap amountIn to WETH.
        weth.deposit{ value: amountToSettle }();
        // send WETH to Vault.
        IERC20(address(weth)).safeTransfer(address(vault), amountToSettle);
        // update Vault accounting.
        vault.settle(IERC20(address(weth)), amountToSettle);
    }

    function unwrapWethAndTransferToSender(IWETH weth, IVault vault, address sender, uint256 amountToSend)
        internal
    {
        // Receive the WETH amountOut.
        vault.sendTo(IERC20(address(weth)), address(this), amountToSend);
        // Withdraw WETH to ETH.
        weth.withdraw(amountToSend);
        // Send ETH to sender.
        payable(sender).sendValue(amountToSend);
    }
}
