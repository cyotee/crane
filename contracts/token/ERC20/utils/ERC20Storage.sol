// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                    Forge                                   */
/* -------------------------------------------------------------------------- */

// import "forge-std/console.sol";
// import "forge-std/console2.sol";

/* -------------------------------------------------------------------------- */
/*                                Open Zeppelin                               */
/* -------------------------------------------------------------------------- */

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {
    ERC20Layout,
    ERC20Repo
} from "./ERC20Repo.sol";

interface IERC20Storage {

    struct ERC20StorageInit {
        string name;
        string symbol;
        uint8 decimals;
        uint256 totalSupply;
        address recipient;
    }

}

// end::ERC20Repo[]

/**
 * @title ERC20Storage Diamond Storage ERC20 logic.
 * @author cyotee doge <doge.cyotee>
 * @notice Implements ERC20 compliant logic following Diamond Storage.
 * @notice May be inherited into other contracts to simplify proxy safe implementations.
 */
contract ERC20Storage
is
IERC20Errors,
IERC20Storage
{

    /* ------------------------------ LIBRARIES ----------------------------- */

    using ERC20Repo for bytes32;

    /* ---------------------------------------------------------------------- */
    /*                                 STORAGE                                */
    /* ---------------------------------------------------------------------- */

    /* -------------------------- STORAGE CONSTANTS ------------------------- */
  
    bytes32 private constant LAYOUT_ID
        = keccak256(abi.encode(type(ERC20Repo).name));
    bytes32 private constant STORAGE_RANGE_OFFSET
        = bytes32(uint256(keccak256(abi.encode(LAYOUT_ID))) - 1);
    bytes32 private constant STORAGE_RANGE
        // We XOR the two interfaces because the current ERC20 standard no longer states the metadata is optional.
        // https://eips.ethereum.org/EIPS/eip-20
        = type(IERC20).interfaceId ^ type(IERC20Metadata).interfaceId;
    bytes32 private constant STORAGE_SLOT
        = keccak256(abi.encode(STORAGE_RANGE, STORAGE_RANGE_OFFSET));

    // tag::_erc20()[]
    /**
     * @dev internal hook for the default storage range used by this library.
     * @dev Other services will use their default storage range to ensure consistent storage usage.
     * @return The default storage range used with repos.
     */
    function _erc20()
    internal pure virtual returns(ERC20Layout storage) {
        return STORAGE_SLOT._layout();
    }
    // end::_erc20()[]

    /* ---------------------------------------------------------------------- */
    /*                             INITIALIZATION                             */
    /* ---------------------------------------------------------------------- */

    // tag::_initERC20(string,string,uint8)[]
    /**
     * @dev Set minimal values REQUIRED per ERC20.
     * @dev Allows for 0 supply tokens that expose external supply management.
     * @param name The value to set as the token name.
     * @param symbol The value to set as the token symbol.
     * @param decimals The value to set as the token precision.
     */
    function _initERC20(
        string memory name,
        string memory symbol,
        uint8 decimals
    ) internal {
        _erc20().name = name;
        _erc20().symbol = symbol;
        _erc20().decimals = decimals;
    }
    // end::_initERC20(string,string,uint8)[]

    function _initERC20(
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint256 totalSupply,
        address recipient
    ) internal {
        _initERC20(
            name,
            symbol,
            decimals
        );
        // Branching is cheaper then a needless SSTORE, even of a 0 value.
        // Warming the slot to validate for DELETE discount is more then branching.
        if(totalSupply > 0) {
            _mint(
                // address account,
                recipient,
                // uint256 amount,
                totalSupply,
                // uint256 currentSupply
                0
            );
        }
    }

    function _initERC20(
        IERC20Storage.ERC20StorageInit memory erc20Init
    ) internal {
        _initERC20(
            // string memory name,
            erc20Init.name,
            // string memory symbol,
            erc20Init.symbol,
            // uint8 decimals,
            erc20Init.decimals,
            // uint256 totalSupply,
            erc20Init.totalSupply,
            // address recipient
            erc20Init.recipient
        );
    }

    /* ---------------------------------------------------------------------- */
    /*                                Modifiers                               */
    /* ---------------------------------------------------------------------- */

    modifier spendAllowance(
        address account,
        uint256 amount
    ) {
        // if(account != msg.sender) {
        //     // Load the current spending limit of `spender` for `sender`.
        //     uint256 currentAllowance = _erc20().allowances[account][msg.sender];
        //     // Do not allow transfers by `spender` that exceed their spending limit.
        //     if(currentAllowance < amount) {
        //         // Revert if `spender` lacks sufficient spending limit.
        //         revert ERC20InsufficientAllowance(account, currentAllowance, amount);
        //     }
        //     // Decrease the spending limit of `spender` for `sender`.
        //     ERC20Storage._decreaseAllowance(account, msg.sender,  amount);
        // }
        _spendAllowance(
            account,
            amount
        );
        _;
    }

    // function _spendAllowance(
    //     address account,
    //     uint256 amount
    // ) internal virtual {
    //     if(account != msg.sender) {
    //         // Load the current spending limit of `spender` for `sender`.
    //         uint256 currentAllowance = _erc20().allowances[account][msg.sender];
    //         // Do not allow transfers by `spender` that exceed their spending limit.
    //         if(currentAllowance < amount) {
    //             // Revert if `spender` lacks sufficient spending limit.
    //             revert ERC20InsufficientAllowance(account, currentAllowance, amount);
    //         }
    //         // Decrease the spending limit of `spender` for `sender`.
    //         ERC20Storage._decreaseAllowance(account, msg.sender,  amount);
    //     }
    // }
    function _spendAllowance(address account, uint256 amount) internal virtual {
        if (account != msg.sender) {
            uint256 currentAllowance = _allowance(account, msg.sender); // Use ERC20Storage slot
            // console.log("In _spendAllowance: owner=", account);
            // console.log("spender = ", msg.sender);
            // console.log("allowance = ", currentAllowance);
            // console.log("amount = ", amount);
            if (currentAllowance < amount) {
                revert IERC20Errors.ERC20InsufficientAllowance(account, currentAllowance, amount);
            }
            _decreaseAllowance(account, msg.sender, amount); // Use ERC20Storage’s _decreaseAllowance
        }
    }

    /* ---------------------------------------------------------------------- */
    /*                               Properties                               */
    /* ---------------------------------------------------------------------- */

    // tag::_name()[]
    /**
     * @dev Provides the value of the related Sruct member.
     * @return The token name member value from the related Struct.
     */
    function _name()
    internal view virtual returns (string memory) {
        return _erc20().name;
    }
    // end:_name()[]

    // tag::_symbol()[]
    /**
     * @dev Provides the value of the related Sruct member.
     * @return The token symbol member value from the related Struct.
     */
    function _symbol()
    internal view virtual returns (string memory) {
        return _erc20().symbol;
    }
    // end::_symbol()[]

    // tag::_decimals[]
    /**
     * @return precision Stated precision for determining a single unit of account.
     */
    function _decimals()
    internal view virtual returns (uint8 precision) {
        return _erc20().decimals;
    }
    // end::_decimals[]

    // tag::_totalSupply[]
    /**
     * @notice query the total minted token supply
     * @return supply token supply.
     */
    function _totalSupply()
    internal view virtual returns (uint256 supply) {
        return _erc20().totalSupply;
    }
    // end::_totalSupply[]


    function _totalSupply(uint256 newSupply)
    internal  {
        _erc20().totalSupply = newSupply;
    }

    function _mint(
        address account,
        uint256 amount,
        uint256 currentSupply
    ) internal virtual {
        _mint(
            amount,
            account,
            currentSupply
        );
    }

    function _mint(
        uint256 amount,
        address account,
        uint256 currentSupply
    ) internal virtual {
        // ERC20Storage._totalSupply(currentSupply + amount);
        _erc20().totalSupply = (currentSupply + amount);
        ERC20Storage._increaseBalanceOf(account, amount);
        emit IERC20.Transfer(
            address(0),
            account,
            amount
        );
    }

    // tag::_mint(uint256,address)
    /**
     * @dev Normalizes argument order to ERC4626.
     * @dev Allows for minting to address(0) to support tokens such as UniswapV2Pair.
     * @param amount Amount by which to increase total supply and credit `account`.
     * @param account The account to be credited with the `amount`.
     */
    function _mint(
        uint256 amount,
        address account
    ) internal virtual {
        // ERC20Storage._totalSupply(ERC20Storage._totalSupply() + amount);
        // ERC20Storage._increaseBalanceOf(account, amount);
        _mint(
            amount,
            account,
            _erc20().totalSupply
        );
    }
    // end::_mint(uint256,address)

    // tag::_mint(uint256,address)
    /**
     * @dev Normalizes argument order to ERC4626.
     * @dev Allows for minting to address(0) to support tokens such as UniswapV2Pair.
     * @param amount Amount by which to increase total supply and credit `account`.
     * @param account The account to be credited with the `amount`.
     */
    function _mint(
        address account,
        uint256 amount
    ) internal virtual {
        // ERC20Storage._totalSupply(ERC20Storage._totalSupply() + amount);
        // ERC20Storage._increaseBalanceOf(account, amount);
        _mint(
            amount,
            account,
            _erc20().totalSupply
        );
    }
    // end::_mint(uint256,address)

    // tag::_burn(uint256,address)
    /**
     * @dev Normalizes argument order to ERC4626.
     * @param amount Amount by which to decrease the total supply and debit `account`.
     * @param account Account to be debited by the `amount`.
     */
    function _burn(
        uint256 amount,
        address account,
        uint256 currentSupply
    ) internal virtual {
        // Decrease the total supply by `amount`.
        // Should naturally revert for underflow.
        // ERC20Storage._totalSupply( ERC20Storage._totalSupply() - amount);
        _erc20().totalSupply = currentSupply - amount;
        // Decrease the balance of the `account` by `amount`.
        ERC20Storage._decreaseBalanceOf(account, amount);
        emit IERC20.Transfer(
            account,
            address(0),
            amount
        );
    }
    // end::_burn(uint256,address)

    function _burn(
        address account,
        uint256 amount,
        uint256 currentSupply
    ) internal virtual {
        _burn(
            amount,
            account,
            currentSupply
        );
    }

    function _burn(
        address account,
        uint256 amount
    ) internal virtual {
        _burn(
            amount,
            account,
            _erc20().totalSupply
        );
    }

    function _burn(
        uint256 amount,
        address account
    ) internal virtual {
        _burn(
            amount,
            account,
            _erc20().totalSupply
        );
    }

    // tag::_balanceOf(address)[]
    /**
     * @notice query the token balance of given account
     * @param account address to query for `balance`.
     * @return balance `account` balance.
     */
    function _balanceOf(
        address account
    ) internal view virtual returns (uint256 balance) {
        // Returns the balance of `account`.
        return _erc20().balanceOf[account];
    }
    // end::_balanceOf(address)[]

    // tag::_increaseBalanceOf(address,uint256)[]
    /**
     * @param account The account for which to increase it's balance by `amount`.
     * @param amount The amount by which to increase the balance of `account`.
     */
    function _increaseBalanceOf(
        address account,
        uint256 amount
    ) internal {
        // Increase the balance of `account` by `amount`.
        // ERC20Storage._balanceOf(
        //     account,
        //     // Load the current balance of `account` and add the `amount`.
        //     // Should naturally revert for overflow.
        //     ERC20Storage._balanceOf(account) + amount
        // );
        _erc20().balanceOf[account] += amount;
    }
    // end::_increaseBalanceOf(address,uint256)[]

    // tag::_decreaseBalanceOf(address,uint256)[]
    /**
     * @param account The account for which to decease it's balance by `amount`.
     * @param amount The amount by which to decrease the balance of `account`.
     */
    function _decreaseBalanceOf(
        address account,
        uint256 amount
    ) internal {
        // Load the current balance of `account`.
        uint256 senderBalance = _erc20().balanceOf[account];
        if(senderBalance < amount) {
            // Revert if `account` balance is insufficient.
            revert ERC20InsufficientBalance(account, senderBalance, amount);
        }
        // Decrease the balance of `account` of `amount`.
        // ERC20Storage._balanceOf(
        //     account,
        //     // Load the current balance of `account` and subtract the `amount`.
        //     senderBalance - amount
        // );
        _erc20().balanceOf[account] = senderBalance - amount;
    }
    // end::_decreaseBalanceOf(address,uint256)[]

    // tag::_approve(address,address,uint256)[]
    /**
     * @dev DOES NOT emit event as that is for exposing implementation.
     * @param owner The account issuing the spending limit approval.
     * @param spender The account being approved with a spending a limit.
     * @param amount The spending limit.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        // address(0) MAY NEVER issue a spending limit approval.
        if(owner == address(0)) {
            // Revert for address(0).
            revert ERC20InvalidReceiver(owner);
        }
        // address(0) MAY NEVER recieve a spending limit approval.
        if(spender == address(0)) {
            // Revert for address(0).
            revert ERC20InvalidReceiver(spender);
        }
        // Set the spending limit of `spender` for `owner`.
        _erc20().allowances[owner][spender] = amount;
    }
    // end::_approve(address,address,uint256)[]

    // tag::_allowance(address,address)[]
    /**
     * @param owner The account of which to query spending limits.
     * @param spender The account of which to query it's spending limit.
     * @return The spending limit of `spender` for `owner`.
     */
    function _allowance(
        address owner,
        address spender
    ) internal view virtual returns (uint256) {
        // Return the spending limit of `spender` for `owner`.
        return _erc20().allowances[owner][spender];
    }
    // end::_allowance(address,address)[]

    // tag::_increaseAllowance(address,address,uint256)[]
    /**
     * @dev DOES NOT emit event as that is for exposing implementation.
     * @param owner Account for which to increase the spending limit for `spender`.
     * @param spender Account for which to increase the spending limit of `owner`.
     * @param amount The amount by which to increase the spending limit of `spender` for `owner`.
     */
    function _increaseAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        // Set the increased spending limit of `spender` for `owner`.
        ERC20Storage._approve(
            owner,
            spender,
            // Load the current spending limit and add the `amount`.
            // Should naturally revert for overflow.
           _erc20().allowances[owner][spender] + amount
        );
    }
    // end::_increaseAllowance(address,address,uint256)[]

    // tag::_decreaseAllowance(address,address,uint256)[]
    /**
     * @dev DOES NOT emit event as that is for exposing implementation.
     * @param owner The account for which to decrease the spending limit for `spender`.
     * @param spender The account for which to decrease the spending limit of `owner`.
     * @param amount The amount by which decrease the spending limit of `spender` for `owner`.
     */
    function _decreaseAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        // Set the increased spending limit of `spender` for `owner`.
        ERC20Storage._approve(
            owner,
            spender,
            // Load the current spending limit and subtract the `amount`.
            _erc20().allowances[owner][spender] - amount
        );
    }
    // end::_decreaseAllowance(address,address,uint256)[]

    // tag::_transfer(address,address,uint256)[]
    /**
     * @dev DOES NOT emit event as that is for exposing implementation.
     * @param owner The account to transfer `amount` to `recipient`.
     * @param recipient The account to be transferred `amount` from `sender`.
     * @param amount The amount to transfer from `sender` to `recipient`.
     */
    function _transfer(
        address owner,
        address recipient,
        uint256 amount
    ) internal virtual {
        // address(0) MAY NEVER spend it's balance.
        if(msg.sender == address(0)) {
            // Revert if address(0).
            revert ERC20InvalidSpender(msg.sender);
        }
        // Decrease the balance of `sender` by `amount`.
        ERC20Storage._decreaseBalanceOf(owner, amount);
        // Increase the balance of `recipient` by `amount`.
        ERC20Storage._increaseBalanceOf(recipient, amount);
    }
    // end::_transfer(address,address,uint256)[]

    // tag::_transferFrom(address,address,uint256)[]
    /**
     * @dev DOES NOT emit event as that is for exposing implementation.
     * param spender The account transferring `amount` to `recipient` from `sender`.
     * @param owner The account sending `amount` to `recipient`.
     * @param recipient The account receiving `amount` from `sender`.
     * @param amount The amount to transfer from `sender` to `recipient`.
     */
    function _transferFrom(
        address , // spender,
        address owner,
        address recipient,
        uint256 amount
    ) internal virtual spendAllowance(owner, amount) {
        // // Load the current spending limit of `spender` for `sender`.
        // uint256 currentAllowance = _erc20().allowances[sender][spender];
        // // Do not allow transfers by `spender` that exceed their spending limit.
        // if(currentAllowance < amount) {
        //     // Revert if `spender` lacks sufficient spending limit.
        //     revert ERC20InsufficientAllowance(sender, currentAllowance, amount);
        // }
        // // Decrease the spending limit of `spender` for `sender`.
        // ERC20Storage._decreaseAllowance(sender, spender,  amount);
        // Transfer `amount` from `sender` to `recipient`.
        ERC20Storage._transfer(owner, recipient, amount);
    }
    // end::_transferFrom(address,address,uint256)[]

}
