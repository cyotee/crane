// SPDX-License-Identifier: GPL-3.0
// Domain: lidofinance/core contracts/0.6.12/WstETH.sol (wrap/unwrap math)
// Pin: 372b02e197df61fdf1a443de18acb514804b828d
// Adapted: pragma 0.6.12 → ^0.8.0; OZ ERC20Permit via Crane OZ 4.9.
// Full multi-version Lido tree remains under contracts/external/lido/{0.4.24,0.6.12,0.8.*}/
pragma solidity ^0.8.0;

import {ERC20Permit} from "@crane/contracts/external/openzeppelin-contracts/token/ERC20/extensions/ERC20Permit.sol";
import {ERC20} from "@crane/contracts/external/openzeppelin-contracts/token/ERC20/ERC20.sol";
import {IStETH} from "./IStETH.sol";

/// @title wstETH — non-rebasing wrapper over stETH (upstream wrap/unwrap formulas)
contract WstETH is ERC20Permit {
    IStETH public stETH;

    constructor(IStETH _stETH) ERC20("Wrapped liquid staked Ether 2.0", "wstETH") ERC20Permit("Wrapped liquid staked Ether 2.0") {
        stETH = _stETH;
    }

    function wrap(uint256 _stETHAmount) external returns (uint256) {
        require(_stETHAmount > 0, "wstETH: zero amount wrap");
        uint256 shares = stETH.getSharesByPooledEth(_stETHAmount);
        require(shares > 0, "wstETH: zero shares wrap");
        _mint(msg.sender, shares);
        require(stETH.transferFrom(msg.sender, address(this), _stETHAmount), "wstETH: transfer failed");
        return shares;
    }

    function unwrap(uint256 _wstETHAmount) external returns (uint256) {
        require(_wstETHAmount > 0, "wstETH: zero amount unwrap");
        uint256 stETHAmount = stETH.getPooledEthByShares(_wstETHAmount);
        _burn(msg.sender, _wstETHAmount);
        require(stETH.transfer(msg.sender, stETHAmount), "wstETH: transfer failed");
        return stETHAmount;
    }

    function getWstETHByStETH(uint256 _stETHAmount) external view returns (uint256) {
        return stETH.getSharesByPooledEth(_stETHAmount);
    }

    function getStETHByWstETH(uint256 _wstETHAmount) external view returns (uint256) {
        return stETH.getPooledEthByShares(_wstETHAmount);
    }

    function stEthPerToken() external view returns (uint256) {
        return stETH.getPooledEthByShares(1 ether);
    }

    function tokensPerStEth() external view returns (uint256) {
        return stETH.getSharesByPooledEth(1 ether);
    }

    receive() external payable {
        uint256 shares = stETH.submit{value: msg.value}(address(0));
        _mint(msg.sender, shares);
    }
}
