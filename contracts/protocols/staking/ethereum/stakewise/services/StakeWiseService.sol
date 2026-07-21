// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IEthVault} from "@crane/contracts/protocols/staking/ethereum/stakewise/interfaces/IEthVault.sol";
import {IOsTokenVaultController} from
    "@crane/contracts/protocols/staking/ethereum/stakewise/interfaces/IOsTokenVaultController.sol";

/**
 * @title StakeWiseService
 * @notice EthVault deposit/redeem and osETH rate views via OsTokenVaultController.
 */
library StakeWiseService {
    error ZeroAddress();
    error ZeroAmount();

    function _deposit(IEthVault vault, address receiver, address referrer)
        internal
        returns (uint256 shares)
    {
        if (address(vault) == address(0) || receiver == address(0)) revert ZeroAddress();
        if (msg.value == 0) revert ZeroAmount();
        shares = vault.deposit{value: msg.value}(receiver, referrer);
    }

    function _redeem(IEthVault vault, uint256 shares, address receiver) internal returns (uint256 assets) {
        if (address(vault) == address(0) || receiver == address(0)) revert ZeroAddress();
        if (shares == 0) revert ZeroAmount();
        assets = vault.redeem(shares, receiver);
    }

    function _previewDeposit(IEthVault vault, uint256 assets) internal view returns (uint256) {
        return vault.convertToShares(assets);
    }

    function _previewRedeem(IEthVault vault, uint256 shares) internal view returns (uint256) {
        return vault.convertToAssets(shares);
    }

    function _osEthRate(IOsTokenVaultController controller) internal view returns (uint256) {
        return controller.convertToAssets(1e18);
    }

    function _vaultShareBalance(IEthVault vault, address account) internal view returns (uint256) {
        return IERC20(address(vault)).balanceOf(account);
    }
}
