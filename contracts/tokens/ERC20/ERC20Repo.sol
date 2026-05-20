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
 * @title ERC20Repo Library to usage the related Struct as a storage layoutStruct.
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

    // tag::_layoutStruct(bytes32)[]
    /**
     * @dev "Binds" this struct to a storage slot.
     * @param slot_ The first slot to use in the range of slots used by the struct.
     * @return layoutStruct_ A struct from a Layout library bound to the provided slot.
     */
    function _layoutStruct(bytes32 slot_) internal pure returns (Storage storage layoutStruct_) {
        assembly {
            layoutStruct_.slot := slot_
        }
    }
    // end::_layoutStruct(bytes32)[]

    function _layoutStruct() internal pure returns (Storage storage layoutStruct) {
        return _layoutStruct(DEFAULT_SLOT);
    }

    function _initialize(Storage storage layoutStruct, string memory name_, string memory symbol_, uint8 decimals_) internal {
        layoutStruct.name = name_;
        layoutStruct.symbol = symbol_;
        layoutStruct.decimals = decimals_;
    }

    function _initialize(string memory name_, string memory symbol_, uint8 decimals_) internal {
        _initialize(_layoutStruct(), name_, symbol_, decimals_);
    }

    function _approve(Storage storage layoutStruct, address owner, address spender, uint256 amount) internal {
        if (spender == address(0)) {
            // Revert if address(0).
            revert IERC20Errors.ERC20InvalidSpender(spender);
        }
        layoutStruct.allowances[owner][spender] = amount;
        emit IERC20Events.Approval(owner, spender, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        _approve(_layoutStruct(), owner, spender, amount);
    }

    function _spendAllowance(Storage storage layoutStruct, address owner, address spender, uint256 amount) internal {
        if (spender == address(0)) {
            // Revert if address(0).
            revert IERC20Errors.ERC20InvalidSpender(spender);
        }
        uint256 currentAllowance = _allowance(layoutStruct, owner, spender);
        if (currentAllowance < amount) {
            revert IERC20Errors.ERC20InsufficientAllowance(spender, currentAllowance, amount);
        }
        _approve(layoutStruct, owner, spender, currentAllowance - amount);
    }

    function _increaseBalanceOf(Storage storage layoutStruct, address account, uint256 amount) internal {
        if (account == address(0)) {
            // Revert if address(0).
            revert IERC20Errors.ERC20InvalidReceiver(account);
        }
        layoutStruct.balanceOf[account] += amount;
    }

    function _increaseBalanceOf(address account, uint256 amount) internal {
        _increaseBalanceOf(_layoutStruct(), account, amount);
    }

    function _decreaseBalanceOf(Storage storage layoutStruct, address account, uint256 amount) internal {
        if (account == address(0)) {
            // Revert if address(0).
            revert IERC20Errors.ERC20InvalidSender(account);
        }
        uint256 currentBalance = layoutStruct.balanceOf[account];
        if (currentBalance < amount) {
            revert IERC20Errors.ERC20InsufficientBalance(account, currentBalance, amount);
        }
        layoutStruct.balanceOf[account] = currentBalance - amount;
    }

    function _decreaseBalanceOf(address account, uint256 amount) internal {
        _decreaseBalanceOf(_layoutStruct(), account, amount);
    }

    function _transfer(Storage storage layoutStruct, address owner, address recipient, uint256 amount) internal {
        // address(0) MAY NEVER spend it's balance.
        if (msg.sender == address(0)) {
            // Revert if address(0).
            revert IERC20Errors.ERC20InvalidSpender(msg.sender);
        }
        // Decrease the balance of `sender` by `amount`.
        _decreaseBalanceOf(layoutStruct, owner, amount);
        // Increase the balance of `recipient` by `amount`.
        _increaseBalanceOf(layoutStruct, recipient, amount);
        emit IERC20Events.Transfer(owner, recipient, amount);
    }

    function _transfer(address owner, address recipient, uint256 amount) internal {
        _transfer(_layoutStruct(), owner, recipient, amount);
    }

    function _transferFrom(Storage storage layoutStruct, address owner, address recipient, uint256 amount) internal {
        // Spend the allowance of `msg.sender` for `owner` by `amount`.
        _spendAllowance(layoutStruct, owner, msg.sender, amount);
        // Transfer the tokens.
        _transfer(layoutStruct, owner, recipient, amount);
    }

    function _transferFrom(address owner, address recipient, uint256 amount) internal {
        _transferFrom(_layoutStruct(), owner, recipient, amount);
    }

    function _mint(Storage storage layoutStruct, address recipient, uint256 amount) internal {
        // _increaseBalanceOf(layoutStruct, recipient, amount);
        layoutStruct.balanceOf[recipient] += amount;
        layoutStruct.totalSupply += amount;
        emit IERC20Events.Transfer(address(0), recipient, amount);
    }

    function _mint(address recipient, uint256 amount) internal {
        _mint(_layoutStruct(), recipient, amount);
    }

    function _burn(Storage storage layoutStruct, address account, uint256 amount) internal {
        // _decreaseBalanceOf(layoutStruct, account, amount);
        layoutStruct.balanceOf[account] -= amount;
        layoutStruct.totalSupply -= amount;
        emit IERC20Events.Transfer(account, address(0), amount);
    }

    function _burn(address account, uint256 amount) internal {
        _burn(_layoutStruct(), account, amount);
    }

    function _name(Storage storage layoutStruct) internal view returns (string memory) {
        return layoutStruct.name;
    }

    function _name() internal view returns (string memory) {
        return _name(_layoutStruct());
    }

    function _symbol(Storage storage layoutStruct) internal view returns (string memory) {
        return layoutStruct.symbol;
    }

    function _symbol() internal view returns (string memory) {
        return _symbol(_layoutStruct());
    }

    function _decimals(Storage storage layoutStruct) internal view returns (uint8) {
        return layoutStruct.decimals;
    }

    function _decimals() internal view returns (uint8) {
        return _decimals(_layoutStruct());
    }

    function _totalSupply(Storage storage layoutStruct) internal view returns (uint256) {
        return layoutStruct.totalSupply;
    }

    function _totalSupply() internal view returns (uint256) {
        return _totalSupply(_layoutStruct());
    }

    function _balanceOf(Storage storage layoutStruct, address account) internal view returns (uint256) {
        return layoutStruct.balanceOf[account];
    }

    function _balanceOf(address account) internal view returns (uint256) {
        return _balanceOf(_layoutStruct(), account);
    }

    function _allowance(Storage storage layoutStruct, address owner, address spender) internal view returns (uint256) {
        return layoutStruct.allowances[owner][spender];
    }

    function _allowance(address owner, address spender) internal view returns (uint256) {
        return _allowance(_layoutStruct(), owner, spender);
    }
}
