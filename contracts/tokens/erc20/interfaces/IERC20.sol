// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {
    IERC20Errors
} from "./IERC20Errors.sol";

// tag::IERC20[]
/**
 * @title ERC20 interface
 * @author who?
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 is IERC20Errors {

    /* ------------------------------- EVENTS ------------------------------- */

    // tag::Transfer[]
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     * @param from Account debited in transfer.
     * @param to Account credited in transfer.
     * @param value Amount transferred.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );
    // end::Transfer[]

    // tag::Approval[]
    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     * @param owner Account issueing approval.
     * @param spender Account approved to spend on behalf of `owner`.
     * @param value `spender` spending limit.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    // end::Approval[]

    /* ---------------------------------------------------------------------- */
    /*                                FUNCTIONS                               */
    /* ---------------------------------------------------------------------- */

    // tag::name[]
    /**
     * @notice return token name
     * @return tokenName token name
     * @custom:sig name()
     * @custom:selector 0x06fdde03
     */
    function name()
    external view returns (string memory tokenName);
    // end::name[]

    // tag::symbol[]
    /**
     * @notice return token symbol
     * @return tokenSymbol token symbol
     * @custom:sig symbol()
     * @custom:selector 0x95d89b41
     */
    function symbol()
    external view returns (string memory tokenSymbol);
    // end::symbol[]
 
    // tag::decimals[]
    /**
     * @return precision Stated precision for determining a single unit of account.
     * @custom:sig decimals()
     * @custom:selector 0x313ce567
     */
    function decimals()
    external view returns (uint8 precision);
    // end::decimals[]

    // tag::totalSupply[]
    /**
     * @notice query the total minted token supply
     * @return supply token supply.
     * @custom:sig totalSupply()
     * @custom:selector 0x18160ddd
     */
    function totalSupply()
    external view returns (uint256 supply);
    // end::totalSupply[]

    // tag::balanceOf[]
    /**
     * @notice query the token balance of given account
     * @param account address to query
     * @return balance token balance
     * @custom:sig balanceOf(address)
     * @custom:selector 0x70a08231
     */
    function balanceOf(address account)
    external view returns (uint256 balance);
    // end::balanceOf[]

    // tag::allowance[]
    /**
     * @notice query the allowance granted from given holder to given spender
     * @param holder approver of allowance
     * @param spender recipient of allowance
     * @return limit token allowance
     * @custom:sig allowance(address,address)
     * @custom:selector 0xdd62ed3e
     */
    function allowance(address holder, address spender)
    external view returns (uint256 limit);
    // end::allowance[]

    // tag::approve[]
    /**
     * @notice grant approval to spender to spend tokens
     * @dev prefer ERC20Extended functions to avoid transaction-ordering vulnerability
     * @dev (see https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729)
     * @param spender recipient of allowance
     * @param amount quantity of tokens approved for spending
     * @return success status (always true; otherwise function should revert)
     * @custom:sig allowance(address,uint256)
     * @custom:selector 0x095ea7b3
     * @custom:emits IERC20.Approval
     */
    function approve(address spender, uint256 amount)
    external returns (bool success);
    // end::approve[]

    // tag::transfer[]
    /**
     * @notice transfer tokens to given recipient
     * @param recipient beneficiary of token transfer
     * @param amount quantity of tokens to transfer
     * @return success status (always true; otherwise function should revert)
     * @custom:sig transfer(address,uint256)
     * @custom:selector 0xa9059cbb
     * @custom:emits IERC20.Transfer
     */
    function transfer(address recipient, uint256 amount)
    external returns (bool);
    // end::transfer[]

    // tag::transferFrom[]
    /**
     * @notice transfer tokens to given recipient on behalf of given holder
     * @param holder holder of tokens prior to transfer
     * @param recipient beneficiary of token transfer
     * @param amount quantity of tokens to transfer
     * @return success status (always true; otherwise function should revert)
     * @custom:sig transferFrom(address,address,uint256)
     * @custom:selector 0x23b872dd
     * @custom:emits IERC20.Transfer
     */
    function transferFrom(address holder, address recipient, uint256 amount)
    external returns (bool success);
    // end::transferFrom[]
  
}
// end::IERC20[]
