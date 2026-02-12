// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20 as SoladyERC20} from "@crane/contracts/solady/tokens/ERC20.sol";
import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";

/**
 * @title ERC20
 * @author Crane
 * @dev Implementation of ERC20 token using Solady's gas-optimized implementation
 *      with OpenZeppelin-compatible API.
 * @notice This contract wraps Solady's ERC20 to provide a familiar OZ-like API while benefiting
 *         from Solady's gas optimizations. Includes EIP-2612 permit functionality.
 */
abstract contract ERC20 is SoladyERC20, IERC20 {
    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * Defaults to 18. Override to change.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override(SoladyERC20, IERC20) returns (uint256) {
        return SoladyERC20.totalSupply();
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override(SoladyERC20, IERC20) returns (uint256) {
        return SoladyERC20.balanceOf(account);
    }

    /**
     * @dev See {IERC20-transfer}.
     */
    function transfer(address to, uint256 value) public virtual override(SoladyERC20, IERC20) returns (bool) {
        return SoladyERC20.transfer(to, value);
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override(SoladyERC20, IERC20) returns (uint256) {
        return SoladyERC20.allowance(owner, spender);
    }

    /**
     * @dev See {IERC20-approve}.
     */
    function approve(address spender, uint256 value) public virtual override(SoladyERC20, IERC20) returns (bool) {
        return SoladyERC20.approve(spender, value);
    }

    /**
     * @dev See {IERC20-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 value) public virtual override(SoladyERC20, IERC20) returns (bool) {
        return SoladyERC20.transferFrom(from, to, value);
    }

    /**
     * @dev Creates a `value` amount of tokens and assigns them to `account`, by transferring it from address(0).
     * Relies on the `_update` mechanism.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     */
    function _mint(address account, uint256 value) internal virtual override {
        SoladyERC20._mint(account, value);
    }

    /**
     * @dev Destroys a `value` amount of tokens from `account`, lowering the total supply.
     * Relies on the `_update` mechanism.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     */
    function _burn(address account, uint256 value) internal virtual override {
        SoladyERC20._burn(account, value);
    }
}
