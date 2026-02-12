// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                Open Zeppelin                               */
/* -------------------------------------------------------------------------- */

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IERC20Events} from "@crane/contracts/interfaces/IERC20Events.sol";
import {IERC20Errors} from "@crane/contracts/interfaces/IERC20Errors.sol";

// tag::ERC20Repo[]
/**
 * @title ERC20Repo Library to usage the related Struct as a storage layout.
 * @author cyotee doge <cyotee@syscoin.org>
 * @notice Simplifies Assembly operations upon the related Struct.
 */
library ERC20Repo {
    bytes32 internal constant DEFAULT_SLOT = keccak256(abi.encode("eip.erc.20"));

    // tag::Storage[]
    /// forge-lint: disable-next-line(pascal-case-struct)
    struct Storage {
        string name;
        string symbol;
        uint8 decimals;
        uint256 totalSupply;
        mapping(address account => uint256 balance) balanceOf;
        mapping(address account => mapping(address spender => uint256 approval)) allowances;
    }
    // end::Storage[]

    // tag::_layout(bytes32)[]
    /**
     * @dev "Binds" this struct to a storage slot.
     * @param slot_ The first slot to use in the range of slots used by the struct.
     * @return layout_ A struct from a Layout library bound to the provided slot.
     */
    function _layout(bytes32 slot_) internal pure returns (Storage storage layout_) {
        assembly {
            layout_.slot := slot_
        }
    }
    // end::_layout(bytes32)[]

    function _layout() internal pure returns (Storage storage layout) {
        return _layout(DEFAULT_SLOT);
    }

    function _initialize(Storage storage layout, string memory name_, string memory symbol_, uint8 decimals_)
        internal
    {
        layout.name = name_;
        layout.symbol = symbol_;
        layout.decimals = decimals_;
    }

    function _initialize(string memory name_, string memory symbol_, uint8 decimals_) internal {
        _initialize(_layout(), name_, symbol_, decimals_);
    }

    function _approve(Storage storage layout, address owner, address spender, uint256 amount) internal {
        if (spender == address(0)) {
            // Revert if address(0).
            revert IERC20Errors.ERC20InvalidSpender(spender);
        }
        layout.allowances[owner][spender] = amount;
        emit IERC20Events.Approval(owner, spender, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        _approve(_layout(), owner, spender, amount);
    }

    function _spendAllowance(Storage storage layout, address owner, address spender, uint256 amount) internal {
        if (spender == address(0)) {
            // Revert if address(0).
            revert IERC20Errors.ERC20InvalidSpender(spender);
        }
        uint256 currentAllowance = _allowance(layout, owner, spender);
        if (currentAllowance < amount) {
            revert IERC20Errors.ERC20InsufficientAllowance(spender, currentAllowance, amount);
        }
        _approve(layout, owner, spender, currentAllowance - amount);
    }

    function _increaseBalanceOf(Storage storage layout, address account, uint256 amount) internal {
        if (account == address(0)) {
            // Revert if address(0).
            revert IERC20Errors.ERC20InvalidReceiver(account);
        }
        layout.balanceOf[account] += amount;
    }

    function _increaseBalanceOf(address account, uint256 amount) internal {
        _increaseBalanceOf(_layout(), account, amount);
    }

    function _decreaseBalanceOf(Storage storage layout, address account, uint256 amount) internal {
        if (account == address(0)) {
            // Revert if address(0).
            revert IERC20Errors.ERC20InvalidSender(account);
        }
        uint256 currentBalance = layout.balanceOf[account];
        if (currentBalance < amount) {
            revert IERC20Errors.ERC20InsufficientBalance(account, currentBalance, amount);
        }
        layout.balanceOf[account] = currentBalance - amount;
    }

    function _decreaseBalanceOf(address account, uint256 amount) internal {
        _decreaseBalanceOf(_layout(), account, amount);
    }

    function _transfer(Storage storage layout, address owner, address recipient, uint256 amount) internal {
        // address(0) MAY NEVER spend it's balance.
        if (msg.sender == address(0)) {
            // Revert if address(0).
            revert IERC20Errors.ERC20InvalidSpender(msg.sender);
        }
        // Decrease the balance of `sender` by `amount`.
        _decreaseBalanceOf(layout, owner, amount);
        // Increase the balance of `recipient` by `amount`.
        _increaseBalanceOf(layout, recipient, amount);
        emit IERC20Events.Transfer(owner, recipient, amount);
    }

    function _transfer(address owner, address recipient, uint256 amount) internal {
        _transfer(_layout(), owner, recipient, amount);
    }

    function _transferFrom(Storage storage layout, address owner, address recipient, uint256 amount) internal {
        // Spend the allowance of `msg.sender` for `owner` by `amount`.
        _spendAllowance(layout, owner, msg.sender, amount);
        // Transfer the tokens.
        _transfer(layout, owner, recipient, amount);
    }

    function _transferFrom(address owner, address recipient, uint256 amount) internal {
        _transferFrom(_layout(), owner, recipient, amount);
    }

    function _mint(Storage storage layout, address recipient, uint256 amount) internal {
        // _increaseBalanceOf(layout, recipient, amount);
        layout.balanceOf[recipient] += amount;
        layout.totalSupply += amount;
        emit IERC20Events.Transfer(address(0), recipient, amount);
    }

    function _mint(address recipient, uint256 amount) internal {
        _mint(_layout(), recipient, amount);
    }

    function _burn(Storage storage layout, address account, uint256 amount) internal {
        // _decreaseBalanceOf(layout, account, amount);
        layout.balanceOf[account] -= amount;
        layout.totalSupply -= amount;
        emit IERC20Events.Transfer(account, address(0), amount);
    }

    function _burn(address account, uint256 amount) internal {
        _burn(_layout(), account, amount);
    }

    function _name(Storage storage layout) internal view returns (string memory) {
        return layout.name;
    }

    function _name() internal view returns (string memory) {
        return _name(_layout());
    }

    function _symbol(Storage storage layout) internal view returns (string memory) {
        return layout.symbol;
    }

    function _symbol() internal view returns (string memory) {
        return _symbol(_layout());
    }

    function _decimals(Storage storage layout) internal view returns (uint8) {
        return layout.decimals;
    }

    function _decimals() internal view returns (uint8) {
        return _decimals(_layout());
    }

    function _totalSupply(Storage storage layout) internal view returns (uint256) {
        return layout.totalSupply;
    }

    function _totalSupply() internal view returns (uint256) {
        return _totalSupply(_layout());
    }

    function _balanceOf(Storage storage layout, address account) internal view returns (uint256) {
        return layout.balanceOf[account];
    }

    function _balanceOf(address account) internal view returns (uint256) {
        return _balanceOf(_layout(), account);
    }

    function _allowance(Storage storage layout, address owner, address spender) internal view returns (uint256) {
        return layout.allowances[owner][spender];
    }

    function _allowance(address owner, address spender) internal view returns (uint256) {
        return _allowance(_layout(), owner, spender);
    }
}
