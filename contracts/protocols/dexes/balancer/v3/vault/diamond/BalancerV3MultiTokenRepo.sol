// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.24;

import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

import {IERC20MultiTokenErrors} from "@balancer-labs/v3-interfaces/contracts/vault/IERC20MultiTokenErrors.sol";
import {EVMCallModeHelpers} from "@balancer-labs/v3-solidity-utils/contracts/helpers/EVMCallModeHelpers.sol";

import {BalancerPoolToken} from "@balancer-labs/v3-vault/contracts/BalancerPoolToken.sol";

/* -------------------------------------------------------------------------- */
/*                          BalancerV3MultiTokenRepo                          */
/* -------------------------------------------------------------------------- */

/**
 * @title BalancerV3MultiTokenRepo
 * @notice Diamond-compatible storage repo for ERC20 multi-token (BPT) accounting.
 * @dev Mirrors the private storage from ERC20MultiToken.sol for use across Diamond facets.
 *
 * The original ERC20MultiToken uses `private` mappings which cannot be shared across
 * delegatecall-based Diamond facets. This repo provides identical storage using the
 * Crane Facet-Target-Repo pattern with a deterministic storage slot.
 *
 * Storage includes:
 * - Token balances per pool per account
 * - Token allowances per pool per owner per spender
 * - Total supply per pool
 */
library BalancerV3MultiTokenRepo {

    /* ------ Storage Slot ------ */

    bytes32 internal constant STORAGE_SLOT = keccak256("protocols.dexes.balancer.v3.vault.multitoken");

    /* ------ Constants ------ */

    /// @dev Minimum total supply amount to prevent dust attacks.
    uint256 internal constant POOL_MINIMUM_TOTAL_SUPPLY = 1e6;

    /* ------ Events ------ */

    event Transfer(address indexed pool, address indexed from, address indexed to, uint256 value);
    event Approval(address indexed pool, address indexed owner, address indexed spender, uint256 value);

    /* ------ Storage Struct ------ */

    struct Storage {
        /// @dev Users' pool token (BPT) balances.
        mapping(address token => mapping(address owner => uint256 balance)) balances;
        /// @dev Users' pool token (BPT) allowances.
        mapping(address token => mapping(address owner => mapping(address spender => uint256 allowance))) allowances;
        /// @dev Total supply of all pool tokens (BPT).
        mapping(address token => uint256 totalSupply) totalSupplyOf;
    }

    /* ------ Layout Functions ------ */

    function _layout(bytes32 slot_) internal pure returns (Storage storage layout) {
        assembly {
            layout.slot := slot_
        }
    }

    function _layout() internal pure returns (Storage storage) {
        return _layout(STORAGE_SLOT);
    }

    /* ------ View Functions ------ */

    function _totalSupply(Storage storage layout, address pool) internal view returns (uint256) {
        return layout.totalSupplyOf[pool];
    }

    function _totalSupply(address pool) internal view returns (uint256) {
        return _totalSupply(_layout(), pool);
    }

    function _balanceOf(Storage storage layout, address pool, address account) internal view returns (uint256) {
        return layout.balances[pool][account];
    }

    function _balanceOf(address pool, address account) internal view returns (uint256) {
        return _balanceOf(_layout(), pool, account);
    }

    function _allowance(Storage storage layout, address pool, address owner, address spender) internal view returns (uint256) {
        if (owner == spender) {
            return type(uint256).max;
        }
        return layout.allowances[pool][owner][spender];
    }

    function _allowance(address pool, address owner, address spender) internal view returns (uint256) {
        return _allowance(_layout(), pool, owner, spender);
    }

    /* ------ State-Modifying Functions ------ */

    function _mint(Storage storage layout, address pool, address to, uint256 amount) internal {
        if (to == address(0)) {
            revert IERC20Errors.ERC20InvalidReceiver(to);
        }

        uint256 newTotalSupply = layout.totalSupplyOf[pool] + amount;
        unchecked {
            layout.balances[pool][to] += amount;
        }

        _ensurePoolMinimumTotalSupply(newTotalSupply);
        layout.totalSupplyOf[pool] = newTotalSupply;

        emit Transfer(pool, address(0), to, amount);
        BalancerPoolToken(pool).emitTransfer(address(0), to, amount);
    }

    function _mint(address pool, address to, uint256 amount) internal {
        _mint(_layout(), pool, to, amount);
    }

    function _mintMinimumSupplyReserve(Storage storage layout, address pool) internal {
        layout.totalSupplyOf[pool] += POOL_MINIMUM_TOTAL_SUPPLY;
        unchecked {
            layout.balances[pool][address(0)] += POOL_MINIMUM_TOTAL_SUPPLY;
        }
        emit Transfer(pool, address(0), address(0), POOL_MINIMUM_TOTAL_SUPPLY);
        BalancerPoolToken(pool).emitTransfer(address(0), address(0), POOL_MINIMUM_TOTAL_SUPPLY);
    }

    function _mintMinimumSupplyReserve(address pool) internal {
        _mintMinimumSupplyReserve(_layout(), pool);
    }

    function _burn(Storage storage layout, address pool, address from, uint256 amount) internal {
        if (from == address(0)) {
            revert IERC20Errors.ERC20InvalidSender(from);
        }

        uint256 accountBalance = layout.balances[pool][from];
        if (amount > accountBalance) {
            revert IERC20Errors.ERC20InsufficientBalance(from, accountBalance, amount);
        }

        unchecked {
            layout.balances[pool][from] = accountBalance - amount;
        }
        uint256 newTotalSupply = layout.totalSupplyOf[pool] - amount;

        _ensurePoolMinimumTotalSupply(newTotalSupply);
        layout.totalSupplyOf[pool] = newTotalSupply;

        // Try/catch for recovery mode resilience
        try BalancerPoolToken(pool).emitTransfer(from, address(0), amount) {} catch {}

        emit Transfer(pool, from, address(0), amount);
    }

    function _burn(address pool, address from, uint256 amount) internal {
        _burn(_layout(), pool, from, amount);
    }

    function _transfer(Storage storage layout, address pool, address from, address to, uint256 amount) internal {
        if (from == address(0)) {
            revert IERC20Errors.ERC20InvalidSender(from);
        }
        if (to == address(0)) {
            revert IERC20Errors.ERC20InvalidReceiver(to);
        }

        uint256 fromBalance = layout.balances[pool][from];
        if (amount > fromBalance) {
            revert IERC20Errors.ERC20InsufficientBalance(from, fromBalance, amount);
        }

        unchecked {
            layout.balances[pool][from] = fromBalance - amount;
            layout.balances[pool][to] += amount;
        }

        emit Transfer(pool, from, to, amount);
        BalancerPoolToken(pool).emitTransfer(from, to, amount);
    }

    function _transfer(address pool, address from, address to, uint256 amount) internal {
        _transfer(_layout(), pool, from, to, amount);
    }

    function _approve(Storage storage layout, address pool, address owner, address spender, uint256 amount) internal {
        if (owner == address(0)) {
            revert IERC20Errors.ERC20InvalidApprover(owner);
        }
        if (spender == address(0)) {
            revert IERC20Errors.ERC20InvalidSpender(spender);
        }

        layout.allowances[pool][owner][spender] = amount;

        // Try/catch for recovery mode resilience
        try BalancerPoolToken(pool).emitApproval(owner, spender, amount) {} catch {}

        emit Approval(pool, owner, spender, amount);
    }

    function _approve(address pool, address owner, address spender, uint256 amount) internal {
        _approve(_layout(), pool, owner, spender, amount);
    }

    function _spendAllowance(Storage storage layout, address pool, address owner, address spender, uint256 amount) internal {
        uint256 currentAllowance = _allowance(layout, pool, owner, spender);
        if (currentAllowance != type(uint256).max) {
            if (amount > currentAllowance) {
                revert IERC20Errors.ERC20InsufficientAllowance(spender, currentAllowance, amount);
            }
            unchecked {
                _approve(layout, pool, owner, spender, currentAllowance - amount);
            }
        }
    }

    function _spendAllowance(address pool, address owner, address spender, uint256 amount) internal {
        _spendAllowance(_layout(), pool, owner, spender, amount);
    }

    /**
     * @dev Only callable in static call (query) context. Temporarily increases balance
     * to allow burn to succeed during removeLiquidity queries.
     */
    function _queryModeBalanceIncrease(Storage storage layout, address pool, address to, uint256 amount) internal {
        if (EVMCallModeHelpers.isStaticCall() == false) {
            revert EVMCallModeHelpers.NotStaticCall();
        }
        layout.balances[address(pool)][to] += amount;
    }

    function _queryModeBalanceIncrease(address pool, address to, uint256 amount) internal {
        _queryModeBalanceIncrease(_layout(), pool, to, amount);
    }

    /* ------ Private Helpers ------ */

    function _ensurePoolMinimumTotalSupply(uint256 newTotalSupply) private pure {
        if (newTotalSupply < POOL_MINIMUM_TOTAL_SUPPLY) {
            revert IERC20MultiTokenErrors.PoolTotalSupplyTooLow(newTotalSupply);
        }
    }
}
