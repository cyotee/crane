// SPDX-FileCopyrightText: 2021 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
// Vendored from lidofinance/core contracts/0.6.12/WstETH.sol (see WstETH.upstream.sol.txt).
// Adapted: pragma 0.6.12 → ^0.8.0; OZ ERC20Permit remapped to Crane external OZ.
// Wrap/unwrap/share math logic preserved.

pragma solidity ^0.8.0;

import {ERC20} from "@crane/contracts/external/openzeppelin-contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@crane/contracts/external/openzeppelin-contracts/token/ERC20/extensions/ERC20Permit.sol";
import {IStETH} from "@crane/contracts/external/lido/IStETH.sol";

/**
 * @title StETH token wrapper with static balances (Lido WstETH domain).
 * @dev Faithful mint/wrap domain vendor of Lido WstETH for Crane.
 */
contract WstETH is ERC20Permit {
    IStETH public stETH;

    /**
     * @param _stETH address of the StETH token to wrap
     */
    constructor(IStETH _stETH) ERC20("Wrapped liquid staked Ether 2.0", "wstETH") ERC20Permit("Wrapped liquid staked Ether 2.0") {
        stETH = _stETH;
    }

    /**
     * @notice Exchanges stETH to wstETH
     * @param _stETHAmount amount of stETH to wrap in exchange for wstETH
     * @return Amount of wstETH user receives after wrap
     */
    function wrap(uint256 _stETHAmount) external returns (uint256) {
        require(_stETHAmount > 0, "wstETH: can't wrap zero stETH");
        uint256 wstETHAmount = stETH.getSharesByPooledEth(_stETHAmount);
        _mint(msg.sender, wstETHAmount);
        require(stETH.transferFrom(msg.sender, address(this), _stETHAmount), "wstETH: transferFrom failed");
        return wstETHAmount;
    }

    /**
     * @notice Exchanges wstETH to stETH
     * @param _wstETHAmount amount of wstETH to unwrap in exchange for stETH
     * @return Amount of stETH user receives after unwrap
     */
    function unwrap(uint256 _wstETHAmount) external returns (uint256) {
        require(_wstETHAmount > 0, "wstETH: zero amount unwrap not allowed");
        uint256 stETHAmount = stETH.getPooledEthByShares(_wstETHAmount);
        _burn(msg.sender, _wstETHAmount);
        require(stETH.transfer(msg.sender, stETHAmount), "wstETH: transfer failed");
        return stETHAmount;
    }

    /**
     * @notice Shortcut to stake ETH and auto-wrap returned stETH
     */
    receive() external payable {
        uint256 shares = stETH.submit{value: msg.value}(address(0));
        _mint(msg.sender, shares);
    }

    /**
     * @notice Get amount of wstETH for a given amount of stETH
     */
    function getWstETHByStETH(uint256 _stETHAmount) external view returns (uint256) {
        return stETH.getSharesByPooledEth(_stETHAmount);
    }

    /**
     * @notice Get amount of stETH for a given amount of wstETH
     */
    function getStETHByWstETH(uint256 _wstETHAmount) external view returns (uint256) {
        return stETH.getPooledEthByShares(_wstETHAmount);
    }

    /**
     * @notice Get amount of stETH for a one wstETH
     */
    function stEthPerToken() external view returns (uint256) {
        return stETH.getPooledEthByShares(1 ether);
    }

    /**
     * @notice Get amount of wstETH for a one stETH
     */
    function tokensPerStEth() external view returns (uint256) {
        return stETH.getSharesByPooledEth(1 ether);
    }
}
