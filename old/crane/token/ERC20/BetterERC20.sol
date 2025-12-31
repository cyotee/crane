// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.20;

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {ERC20Storage} from "contracts/crane/token/ERC20/utils/ERC20Storage.sol";

import {BetterIERC20} from "contracts/crane/interfaces/BetterIERC20.sol";

/**
 * @title ERC20Target - Proxy Logic target exposing ERC20 standard.
 * @author cyotee doge <doge.cyotee>
 * @dev Expects to be initialized.
 */
contract BetterERC20 is ERC20Storage, BetterIERC20 {
    // tag::name[]
    /**
     * @inheritdoc IERC20Metadata
     */
    function name() public view virtual returns (string memory) {
        // return _erc20().name;
        return _name();
    }

    // end::name[]

    // tag::symbol[]
    /**
     * @inheritdoc IERC20Metadata
     */
    function symbol() public view virtual returns (string memory tokenSymbol) {
        // return _erc20().symbol;
        return _symbol();
    }

    // end::symbol[]

    // tag::decimals[]
    /**
     * @inheritdoc IERC20Metadata
     */
    function decimals() public view virtual returns (uint8) {
        // return _erc20().decimals;
        return _decimals();
    }

    // end::decimals[]

    // tag::totalSupply[]
    /**
     * @inheritdoc IERC20
     */
    function totalSupply() public view virtual returns (uint256 supply) {
        // return _erc20().totalSupply;
        return _totalSupply();
    }

    // end::totalSupply[]

    // tag::balanceOf[]
    /**
     * @inheritdoc IERC20
     */
    function balanceOf(address account) public view virtual returns (uint256 balance) {
        // return _erc20().balanceOf[account];
        return _balanceOf(account);
    }

    // end::balanceOf[]

    // tag::allowance[]
    /**
     * @inheritdoc IERC20
     */
    function allowance(address owner, address spender) public view virtual returns (uint256) {
        // return _erc20().allowances[owner][spender];
        return _allowance(owner, spender);
    }

    // end::allowance[]

    // tag::approve[]
    /**
     * @inheritdoc IERC20
     */
    function approve(address spender, uint256 amount) public virtual returns (bool result) {
        _approve(msg.sender, spender, amount);
        // Emit the required event.
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    // end::approve[]

    // tag::transfer[]
    /**
     * @inheritdoc IERC20
     */
    function transfer(address recipient, uint256 amount) public virtual returns (bool result) {
        _transfer(msg.sender, recipient, amount);
        // Emit the required event.
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    // end::transfer[]

    // tag::transferFrom[]
    /**
     * @inheritdoc IERC20
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual returns (bool result) {
        _transferFrom(msg.sender, sender, recipient, amount);
        // Emit the required event.
        emit Transfer(sender, recipient, amount);
        result = true;
    }

    // end::transferFrom[]

    /* ---------------------------------------------------------------------- */
    /*                               EXTENSIONS                               */
    /* ---------------------------------------------------------------------- */

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _increaseAllowance(msg.sender, spender, addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _decreaseAllowance(msg.sender, spender, subtractedValue);
        return true;
    }
}
