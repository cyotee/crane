// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.24;

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {BetterSafeERC20 as SafeERC20} from "@crane/contracts/tokens/ERC20/utils/BetterSafeERC20.sol";
import {IfrxETHMinter} from "@crane/contracts/protocols/tokens/stable/frax/FraxETH/IfrxETHMinter.sol";
import {IsfrxETH} from "@crane/contracts/protocols/tokens/stable/frax/FraxETH/IsfrxETH.sol";
import {EthereumStakingLib} from "@crane/contracts/protocols/staking/ethereum/common/EthereumStakingLib.sol";

/**
 * @title FraxETHService
 * @notice Thin Service for frxETH minter submit and sfrxETH ERC-4626 deposit/redeem.
 * @dev Bulk Frax monorepo remains under tokens/stable/frax; this is the staking integration surface only.
 */
library FraxETHService {
    using SafeERC20 for IERC20;

    error ZeroAddress();
    error ZeroAmount();

    function _submit(IfrxETHMinter minter) internal returns (uint256 frxEthOut) {
        if (address(minter) == address(0)) revert ZeroAddress();
        if (msg.value == 0) revert ZeroAmount();
        address frx = minter.frxETHToken();
        uint256 beforeBal = IERC20(frx).balanceOf(address(this));
        minter.submit{value: msg.value}();
        frxEthOut = IERC20(frx).balanceOf(address(this)) - beforeBal;
    }

    function _submitAndDeposit(IfrxETHMinter minter, address recipient)
        internal
        returns (uint256 shares)
    {
        if (address(minter) == address(0) || recipient == address(0)) revert ZeroAddress();
        if (msg.value == 0) revert ZeroAmount();
        shares = minter.submitAndDeposit{value: msg.value}(recipient);
    }

    function _depositSfrxETH(IsfrxETH sfrx, uint256 assets, address receiver)
        internal
        returns (uint256 shares)
    {
        if (address(sfrx) == address(0) || receiver == address(0)) revert ZeroAddress();
        if (assets == 0) revert ZeroAmount();
        address asset = sfrx.asset();
        EthereumStakingLib._forceApprove(IERC20(asset), address(sfrx), assets);
        shares = sfrx.deposit(assets, receiver);
    }

    function _redeemSfrxETH(IsfrxETH sfrx, uint256 shares, address receiver, address owner)
        internal
        returns (uint256 assets)
    {
        if (address(sfrx) == address(0) || receiver == address(0) || owner == address(0)) revert ZeroAddress();
        if (shares == 0) revert ZeroAmount();
        assets = sfrx.redeem(shares, receiver, owner);
    }

    function _previewDeposit(IsfrxETH sfrx, uint256 assets) internal view returns (uint256) {
        return sfrx.previewDeposit(assets);
    }

    function _previewRedeem(IsfrxETH sfrx, uint256 shares) internal view returns (uint256) {
        return sfrx.previewRedeem(shares);
    }

    function _convertToAssets(IsfrxETH sfrx, uint256 shares) internal view returns (uint256) {
        return sfrx.convertToAssets(shares);
    }
}
