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
 * @title ERC20Repo - Storage library for standard ERC-20 token state (name, symbol, decimals, supply, balances, allowances).
 * @author cyotee doge <cyotee@syscoin.org>
 * @dev Storage library (Repo) for ERC-20 core state per IERC20/IERC20Metadata.
 * @dev Provides dual (parameterized + default) overloads for _initialize and all storage accessors/mutators.
 * @dev Follows the gold standard from ERC4626Repo, OperableRepo, EIP712Repo, ERC2535Repo, DeployedAddressesRepo
 *      (rich NatSpec, exact // tag:: / end:: include tags, @dev "The Storage struct to operate on.", ERC1967-compliant STORAGE_SLOT).
 * @dev Used by ERC20Target, ERC20Facet, ERC20*DFPkgs and Minter facades for Diamond storage binding of ERC20 fields.
 */
library ERC20Repo {
    // tag::STORAGE_SLOT[]
    /**
     * @dev ERC1967-compliant storage slot.
     *      Computed as bytes32(uint256(keccak256(abi.encode("eip.erc.20"))) - 1).
     *      This follows the canonical pattern used by ERC2535Repo (eip.erc.2535), ERC4626Repo (eip.erc.4626), OperableRepo,
     *      MultiStepOwnableRepo, DeployedAddressesRepo, and other gold-standard Repos for collision-resistant deterministic storage binding.
     */
    bytes32 internal constant STORAGE_SLOT = bytes32(uint256(keccak256(abi.encode("eip.erc.20"))) - 1);

    // end::STORAGE_SLOT[]

    // tag::Storage[]
    /**
     * @dev Standardized storage layout for ERC-20 token.
     *      name: Token name string.
     *      symbol: Token symbol string.
     *      decimals: Token decimals.
     *      totalSupply: Total token supply.
     *      balanceOf: Balances by account.
     *      allowances: Approvals by owner->spender.
     */
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
     * @dev Argumented version of _layoutStruct to allow for custom storage slot usage.
     * @param slot_ The storage slot to bind.
     * @return layoutStruct The Storage struct bound to the provided slot.
     */
    function _layoutStruct(bytes32 slot_) internal pure returns (Storage storage layoutStruct) {
        assembly {
            layoutStruct.slot := slot_
        }
    }

    // end::_layoutStruct(bytes32)[]

    // tag::_layoutStruct()[]
    /**
     * @dev Default _layoutStruct binding to the canonical ERC1967 STORAGE_SLOT.
     * @return layoutStruct The Storage struct bound to STORAGE_SLOT.
     */
    function _layoutStruct() internal pure returns (Storage storage layoutStruct) {
        return _layoutStruct(STORAGE_SLOT);
    }

    // end::_layoutStruct()[]

    // tag::_initialize(Storage-string-memory-string-memory-uint8)[]
    /**
     * @dev Argumented version of _initialize to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @param name_ Token name.
     * @param symbol_ Token symbol.
     * @param decimals_ Token decimals.
     */
    function _initialize(Storage storage layoutStruct, string memory name_, string memory symbol_, uint8 decimals_)
        internal
    {
        layoutStruct.name = name_;
        layoutStruct.symbol = symbol_;
        layoutStruct.decimals = decimals_;
    }

    // end::_initialize(Storage-string-memory-string-memory-uint8)[]

    // tag::_initialize(string-memory-string-memory-uint8)[]
    /**
     * @dev Default version of _initialize binding to the standard STORAGE_SLOT.
     * @param name_ Token name.
     * @param symbol_ Token symbol.
     * @param decimals_ Token decimals.
     */
    function _initialize(string memory name_, string memory symbol_, uint8 decimals_) internal {
        _initialize(_layoutStruct(), name_, symbol_, decimals_);
    }

    // end::_initialize(string-memory-string-memory-uint8)[]

    // tag::_approve(Storage-address-address-uint256)[]
    /**
     * @dev Argumented version of _approve to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @param owner The token owner.
     * @param spender The spender address.
     * @param amount The approval amount.
     * @custom:emits IERC20Events.Approval
     */
    function _approve(Storage storage layoutStruct, address owner, address spender, uint256 amount) internal {
        if (spender == address(0)) {
            // Revert if address(0).
            revert IERC20Errors.ERC20InvalidSpender(spender);
        }
        layoutStruct.allowances[owner][spender] = amount;
        emit IERC20Events.Approval(owner, spender, amount);
    }

    // end::_approve(Storage-address-address-uint256)[]

    // tag::_approve(address-address-uint256)[]
    /**
     * @dev Default version of _approve binding to the standard STORAGE_SLOT.
     * @param owner The token owner.
     * @param spender The spender address.
     * @param amount The approval amount.
     * @custom:emits IERC20Events.Approval
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        _approve(_layoutStruct(), owner, spender, amount);
    }

    // end::_approve(address-address-uint256)[]

    // tag::_spendAllowance(Storage-address-address-uint256)[]
    /**
     * @dev Argumented version of _spendAllowance to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @param owner The token owner.
     * @param spender The spender address.
     * @param amount The amount to spend from allowance.
     */
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

    // end::_spendAllowance(Storage-address-address-uint256)[]

    // tag::_spendAllowance(address-address-uint256)[]
    /**
     * @dev Default version of _spendAllowance binding to the standard STORAGE_SLOT.
     * @param owner The token owner.
     * @param spender The spender address.
     * @param amount The amount to spend from allowance.
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal {
        _spendAllowance(_layoutStruct(), owner, spender, amount);
    }

    // end::_spendAllowance(address-address-uint256)[]

    // tag::_increaseBalanceOf(Storage-address-uint256)[]
    /**
     * @dev Argumented version of _increaseBalanceOf to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @param account The account to increase balance for.
     * @param amount The amount to add.
     */
    function _increaseBalanceOf(Storage storage layoutStruct, address account, uint256 amount) internal {
        if (account == address(0)) {
            // Revert if address(0).
            revert IERC20Errors.ERC20InvalidReceiver(account);
        }
        layoutStruct.balanceOf[account] += amount;
    }

    // end::_increaseBalanceOf(Storage-address-uint256)[]

    // tag::_increaseBalanceOf(address-uint256)[]
    /**
     * @dev Default version of _increaseBalanceOf binding to the standard STORAGE_SLOT.
     * @param account The account to increase balance for.
     * @param amount The amount to add.
     */
    function _increaseBalanceOf(address account, uint256 amount) internal {
        _increaseBalanceOf(_layoutStruct(), account, amount);
    }

    // end::_increaseBalanceOf(address-uint256)[]

    // tag::_decreaseBalanceOf(Storage-address-uint256)[]
    /**
     * @dev Argumented version of _decreaseBalanceOf to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @param account The account to decrease balance for.
     * @param amount The amount to subtract.
     */
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

    // end::_decreaseBalanceOf(Storage-address-uint256)[]

    // tag::_decreaseBalanceOf(address-uint256)[]
    /**
     * @dev Default version of _decreaseBalanceOf binding to the standard STORAGE_SLOT.
     * @param account The account to decrease balance for.
     * @param amount The amount to subtract.
     */
    function _decreaseBalanceOf(address account, uint256 amount) internal {
        _decreaseBalanceOf(_layoutStruct(), account, amount);
    }

    // end::_decreaseBalanceOf(address-uint256)[]

    // tag::_transfer(Storage-address-address-uint256)[]
    /**
     * @dev Argumented version of _transfer to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @param owner The sender/owner.
     * @param recipient The recipient.
     * @param amount The transfer amount.
     * @custom:emits IERC20Events.Transfer
     */
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

    // end::_transfer(Storage-address-address-uint256)[]

    // tag::_transfer(address-address-uint256)[]
    /**
     * @dev Default version of _transfer binding to the standard STORAGE_SLOT.
     * @param owner The sender/owner.
     * @param recipient The recipient.
     * @param amount The transfer amount.
     * @custom:emits IERC20Events.Transfer
     */
    function _transfer(address owner, address recipient, uint256 amount) internal {
        _transfer(_layoutStruct(), owner, recipient, amount);
    }

    // end::_transfer(address-address-uint256)[]

    // tag::_transferFrom(Storage-address-address-uint256)[]
    /**
     * @dev Argumented version of _transferFrom to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @param owner The token owner (from).
     * @param recipient The recipient.
     * @param amount The transfer amount.
     * @custom:emits IERC20Events.Transfer (via _transfer)
     */
    function _transferFrom(Storage storage layoutStruct, address owner, address recipient, uint256 amount) internal {
        // Spend the allowance of `msg.sender` for `owner` by `amount`.
        _spendAllowance(layoutStruct, owner, msg.sender, amount);
        // Transfer the tokens.
        _transfer(layoutStruct, owner, recipient, amount);
    }

    // end::_transferFrom(Storage-address-address-uint256)[]

    // tag::_transferFrom(address-address-uint256)[]
    /**
     * @dev Default version of _transferFrom binding to the standard STORAGE_SLOT.
     * @param owner The token owner (from).
     * @param recipient The recipient.
     * @param amount The transfer amount.
     * @custom:emits IERC20Events.Transfer (via _transfer)
     */
    function _transferFrom(address owner, address recipient, uint256 amount) internal {
        _transferFrom(_layoutStruct(), owner, recipient, amount);
    }

    // end::_transferFrom(address-address-uint256)[]

    // tag::_mint(Storage-address-uint256)[]
    /**
     * @dev Argumented version of _mint to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @param recipient The recipient of minted tokens.
     * @param amount The mint amount.
     * @custom:emits IERC20Events.Transfer (from zero)
     */
    function _mint(Storage storage layoutStruct, address recipient, uint256 amount) internal {
        // _increaseBalanceOf(layoutStruct, recipient, amount);
        layoutStruct.balanceOf[recipient] += amount;
        layoutStruct.totalSupply += amount;
        emit IERC20Events.Transfer(address(0), recipient, amount);
    }

    // end::_mint(Storage-address-uint256)[]

    // tag::_mint(address-uint256)[]
    /**
     * @dev Default version of _mint binding to the standard STORAGE_SLOT.
     * @param recipient The recipient of minted tokens.
     * @param amount The mint amount.
     * @custom:emits IERC20Events.Transfer (from zero)
     */
    function _mint(address recipient, uint256 amount) internal {
        _mint(_layoutStruct(), recipient, amount);
    }

    // end::_mint(address-uint256)[]

    // tag::_burn(Storage-address-uint256)[]
    /**
     * @dev Argumented version of _burn to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @param account The account to burn from.
     * @param amount The burn amount.
     * @custom:emits IERC20Events.Transfer (to zero)
     */
    function _burn(Storage storage layoutStruct, address account, uint256 amount) internal {
        // _decreaseBalanceOf(layoutStruct, account, amount);
        layoutStruct.balanceOf[account] -= amount;
        layoutStruct.totalSupply -= amount;
        emit IERC20Events.Transfer(account, address(0), amount);
    }

    // end::_burn(Storage-address-uint256)[]

    // tag::_burn(address-uint256)[]
    /**
     * @dev Default version of _burn binding to the standard STORAGE_SLOT.
     * @param account The account to burn from.
     * @param amount The burn amount.
     * @custom:emits IERC20Events.Transfer (to zero)
     */
    function _burn(address account, uint256 amount) internal {
        _burn(_layoutStruct(), account, amount);
    }

    // end::_burn(address-uint256)[]

    // tag::_name(Storage)[]
    /**
     * @dev Argumented version of _name to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @return The token name.
     */
    function _name(Storage storage layoutStruct) internal view returns (string memory) {
        return layoutStruct.name;
    }

    // end::_name(Storage)[]

    // tag::_name()[]
    /**
     * @dev Default version of _name binding to the standard STORAGE_SLOT.
     * @return The token name.
     */
    function _name() internal view returns (string memory) {
        return _name(_layoutStruct());
    }

    // end::_name()[]

    // tag::_symbol(Storage)[]
    /**
     * @dev Argumented version of _symbol to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @return The token symbol.
     */
    function _symbol(Storage storage layoutStruct) internal view returns (string memory) {
        return layoutStruct.symbol;
    }

    // end::_symbol(Storage)[]

    // tag::_symbol()[]
    /**
     * @dev Default version of _symbol binding to the standard STORAGE_SLOT.
     * @return The token symbol.
     */
    function _symbol() internal view returns (string memory) {
        return _symbol(_layoutStruct());
    }

    // end::_symbol()[]

    // tag::_decimals(Storage)[]
    /**
     * @dev Argumented version of _decimals to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @return The token decimals.
     */
    function _decimals(Storage storage layoutStruct) internal view returns (uint8) {
        return layoutStruct.decimals;
    }

    // end::_decimals(Storage)[]

    // tag::_decimals()[]
    /**
     * @dev Default version of _decimals binding to the standard STORAGE_SLOT.
     * @return The token decimals.
     */
    function _decimals() internal view returns (uint8) {
        return _decimals(_layoutStruct());
    }

    // end::_decimals()[]

    // tag::_totalSupply(Storage)[]
    /**
     * @dev Argumented version of _totalSupply to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @return The total supply.
     */
    function _totalSupply(Storage storage layoutStruct) internal view returns (uint256) {
        return layoutStruct.totalSupply;
    }

    // end::_totalSupply(Storage)[]

    // tag::_totalSupply()[]
    /**
     * @dev Default version of _totalSupply binding to the standard STORAGE_SLOT.
     * @return The total supply.
     */
    function _totalSupply() internal view returns (uint256) {
        return _totalSupply(_layoutStruct());
    }

    // end::_totalSupply()[]

    // tag::_balanceOf(Storage-address)[]
    /**
     * @dev Argumented version of _balanceOf to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @param account The account to query.
     * @return The balance.
     */
    function _balanceOf(Storage storage layoutStruct, address account) internal view returns (uint256) {
        return layoutStruct.balanceOf[account];
    }

    // end::_balanceOf(Storage-address)[]

    // tag::_balanceOf(address)[]
    /**
     * @dev Default version of _balanceOf binding to the standard STORAGE_SLOT.
     * @param account The account to query.
     * @return The balance.
     */
    function _balanceOf(address account) internal view returns (uint256) {
        return _balanceOf(_layoutStruct(), account);
    }

    // end::_balanceOf(address)[]

    // tag::_allowance(Storage-address-address)[]
    /**
     * @dev Argumented version of _allowance to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @param owner The token owner.
     * @param spender The spender.
     * @return The allowance.
     */
    function _allowance(Storage storage layoutStruct, address owner, address spender) internal view returns (uint256) {
        return layoutStruct.allowances[owner][spender];
    }

    // end::_allowance(Storage-address-address)[]

    // tag::_allowance(address-address)[]
    /**
     * @dev Default version of _allowance binding to the standard STORAGE_SLOT.
     * @param owner The token owner.
     * @param spender The spender.
     * @return The allowance.
     */
    function _allowance(address owner, address spender) internal view returns (uint256) {
        return _allowance(_layoutStruct(), owner, spender);
    }
    // end::_allowance(address-address)[]
}
// end::ERC20Repo[]
