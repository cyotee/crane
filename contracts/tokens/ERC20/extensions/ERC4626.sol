// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC4626 as SoladyERC4626} from "@crane/contracts/solady/tokens/ERC4626.sol";
import {ERC20 as SoladyERC20} from "@crane/contracts/solady/tokens/ERC20.sol";
import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IERC20Metadata} from "@crane/contracts/interfaces/IERC20Metadata.sol";
import {IERC4626} from "@crane/contracts/interfaces/IERC4626.sol";

/**
 * @title ERC4626
 * @author Crane
 * @dev Implementation of the ERC-4626 "Tokenized Vault Standard" using Solady's gas-optimized implementation.
 * @notice This contract provides a standardized way to create yield-bearing vaults.
 */
abstract contract ERC4626 is SoladyERC4626, IERC4626 {
    string private _name;
    string private _symbol;
    address private immutable _asset;

    /**
     * @dev Sets the underlying asset and vault token metadata.
     */
    constructor(IERC20 asset_, string memory name_, string memory symbol_) {
        _asset = address(asset_);
        _name = name_;
        _symbol = symbol_;
    }

    // ============ IERC20Metadata overrides ============

    /**
     * @dev Returns the name of the vault token.
     */
    function name() public view virtual override(SoladyERC20, IERC20Metadata) returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the vault token.
     */
    function symbol() public view virtual override(SoladyERC20, IERC20Metadata) returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the decimals of the vault token.
     */
    function decimals() public view virtual override(SoladyERC4626, IERC20Metadata) returns (uint8) {
        return SoladyERC4626.decimals();
    }

    // ============ IERC20 overrides ============

    function totalSupply() public view virtual override(SoladyERC20, IERC20) returns (uint256) {
        return SoladyERC20.totalSupply();
    }

    function balanceOf(address account) public view virtual override(SoladyERC20, IERC20) returns (uint256) {
        return SoladyERC20.balanceOf(account);
    }

    function transfer(address to, uint256 value) public virtual override(SoladyERC20, IERC20) returns (bool) {
        return SoladyERC20.transfer(to, value);
    }

    function allowance(address owner, address spender) public view virtual override(SoladyERC20, IERC20) returns (uint256) {
        return SoladyERC20.allowance(owner, spender);
    }

    function approve(address spender, uint256 value) public virtual override(SoladyERC20, IERC20) returns (bool) {
        return SoladyERC20.approve(spender, value);
    }

    function transferFrom(address from, address to, uint256 value) public virtual override(SoladyERC20, IERC20) returns (bool) {
        return SoladyERC20.transferFrom(from, to, value);
    }

    // ============ IERC4626 overrides ============

    /**
     * @dev Returns the address of the underlying asset.
     */
    function asset() public view virtual override(SoladyERC4626, IERC4626) returns (address) {
        return _asset;
    }

    function totalAssets() public view virtual override(SoladyERC4626, IERC4626) returns (uint256) {
        return SoladyERC4626.totalAssets();
    }

    function convertToShares(uint256 assets) public view virtual override(SoladyERC4626, IERC4626) returns (uint256) {
        return SoladyERC4626.convertToShares(assets);
    }

    function convertToAssets(uint256 shares) public view virtual override(SoladyERC4626, IERC4626) returns (uint256) {
        return SoladyERC4626.convertToAssets(shares);
    }

    function maxDeposit(address receiver) public view virtual override(SoladyERC4626, IERC4626) returns (uint256) {
        return SoladyERC4626.maxDeposit(receiver);
    }

    function previewDeposit(uint256 assets) public view virtual override(SoladyERC4626, IERC4626) returns (uint256) {
        return SoladyERC4626.previewDeposit(assets);
    }

    function deposit(uint256 assets, address receiver) public virtual override(SoladyERC4626, IERC4626) returns (uint256) {
        return SoladyERC4626.deposit(assets, receiver);
    }

    function maxMint(address receiver) public view virtual override(SoladyERC4626, IERC4626) returns (uint256) {
        return SoladyERC4626.maxMint(receiver);
    }

    function previewMint(uint256 shares) public view virtual override(SoladyERC4626, IERC4626) returns (uint256) {
        return SoladyERC4626.previewMint(shares);
    }

    function mint(uint256 shares, address receiver) public virtual override(SoladyERC4626, IERC4626) returns (uint256) {
        return SoladyERC4626.mint(shares, receiver);
    }

    function maxWithdraw(address owner) public view virtual override(SoladyERC4626, IERC4626) returns (uint256) {
        return SoladyERC4626.maxWithdraw(owner);
    }

    function previewWithdraw(uint256 assets) public view virtual override(SoladyERC4626, IERC4626) returns (uint256) {
        return SoladyERC4626.previewWithdraw(assets);
    }

    function withdraw(uint256 assets, address receiver, address owner) public virtual override(SoladyERC4626, IERC4626) returns (uint256) {
        return SoladyERC4626.withdraw(assets, receiver, owner);
    }

    function maxRedeem(address owner) public view virtual override(SoladyERC4626, IERC4626) returns (uint256) {
        return SoladyERC4626.maxRedeem(owner);
    }

    function previewRedeem(uint256 shares) public view virtual override(SoladyERC4626, IERC4626) returns (uint256) {
        return SoladyERC4626.previewRedeem(shares);
    }

    function redeem(uint256 shares, address receiver, address owner) public virtual override(SoladyERC4626, IERC4626) returns (uint256) {
        return SoladyERC4626.redeem(shares, receiver, owner);
    }
}
