// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

import {IAero} from "../interfaces/IAero.sol";
import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {ERC20} from "@crane/contracts/tokens/ERC20/ERC20.sol";

/// @title Aero
/// @author velodrome.finance, Solidly
/// @notice The native token in the Protocol ecosystem
/// @dev Emitted by the Minter. Uses Solady's ERC20 which includes EIP-2612 permit functionality.
contract Aero is IAero, ERC20 {
    address public minter;
    address private owner;

    constructor() ERC20("Aerodrome", "AERO") {
        minter = msg.sender;
        owner = msg.sender;
    }

    /// @dev No checks as its meant to be once off to set minting rights to BaseV1 Minter
    function setMinter(address _minter) external {
        if (msg.sender != minter) revert NotMinter();
        minter = _minter;
    }

    function mint(address account, uint256 amount) external returns (bool) {
        if (msg.sender != minter) revert NotMinter();
        _mint(account, amount);
        return true;
    }

    // Explicit overrides to resolve diamond inheritance between IAero (IERC20) and ERC20
    function totalSupply() public view override(IERC20, ERC20) returns (uint256) {
        return ERC20.totalSupply();
    }

    function balanceOf(address account) public view override(IERC20, ERC20) returns (uint256) {
        return ERC20.balanceOf(account);
    }

    function transfer(address to, uint256 value) public override(IERC20, ERC20) returns (bool) {
        return ERC20.transfer(to, value);
    }

    function allowance(address owner_, address spender) public view override(IERC20, ERC20) returns (uint256) {
        return ERC20.allowance(owner_, spender);
    }

    function approve(address spender, uint256 value) public override(IERC20, ERC20) returns (bool) {
        return ERC20.approve(spender, value);
    }

    function transferFrom(address from, address to, uint256 value) public override(IERC20, ERC20) returns (bool) {
        return ERC20.transferFrom(from, to, value);
    }
}
