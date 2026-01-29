// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.30;

import {IVaultMain} from "@balancer-labs/v3-interfaces/contracts/vault/IVaultMain.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";

import {BalancerV3VaultModifiers} from "../BalancerV3VaultModifiers.sol";
import {BalancerV3MultiTokenRepo} from "../BalancerV3MultiTokenRepo.sol";

/* -------------------------------------------------------------------------- */
/*                            VaultPoolTokenFacet                             */
/* -------------------------------------------------------------------------- */

/**
 * @title VaultPoolTokenFacet
 * @notice Handles BPT (Balancer Pool Token) transfers and approvals.
 * @dev Implements the ERC20-like BPT functions from IVaultMain:
 * - transfer(): Transfer BPT between accounts
 * - transferFrom(): Transfer BPT with allowance check
 *
 * BPT tokens are managed by the Vault on behalf of pools. Each pool address
 * acts as a "token address" in the multi-token accounting system.
 */
contract VaultPoolTokenFacet is BalancerV3VaultModifiers, IFacet {

    /* ========================================================================== */
    /*                                  IFacet                                    */
    /* ========================================================================== */

    /// @inheritdoc IFacet
    function facetName() public pure returns (string memory name) {
        return type(VaultPoolTokenFacet).name;
    }

    /// @inheritdoc IFacet
    function facetInterfaces() public pure returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](1);
        interfaces[0] = type(IVaultMain).interfaceId;
    }

    /// @inheritdoc IFacet
    function facetFuncs() public pure returns (bytes4[] memory funcs) {
        // Only transfer and transferFrom are in IVaultMain
        // totalSupply, balanceOf, allowance, approve are in IVaultExtension (handled by VaultQueryFacet)
        funcs = new bytes4[](2);
        funcs[0] = this.transfer.selector;
        funcs[1] = this.transferFrom.selector;
    }

    /// @inheritdoc IFacet
    function facetMetadata()
        external
        pure
        returns (string memory name_, bytes4[] memory interfaces, bytes4[] memory functions)
    {
        name_ = facetName();
        interfaces = facetInterfaces();
        functions = facetFuncs();
    }

    /* ========================================================================== */
    /*                              EXTERNAL FUNCTIONS                            */
    /* ========================================================================== */

    /**
     * @notice Transfers BPT from one account to another.
     * @dev msg.sender must be the pool contract. The pool calls this to transfer
     * its tokens on behalf of the owner.
     *
     * @param owner The account whose tokens are being transferred
     * @param to The recipient account
     * @param amount The amount of BPT to transfer
     * @return success Always returns true on success, reverts on failure
     */
    function transfer(address owner, address to, uint256 amount) external returns (bool) {
        BalancerV3MultiTokenRepo._transfer(msg.sender, owner, to, amount);
        return true;
    }

    /**
     * @notice Transfers BPT with allowance check.
     * @dev msg.sender must be the pool contract. The spender must have
     * sufficient allowance from the `from` address.
     *
     * @param spender The account executing the transfer (must have allowance)
     * @param from The account whose tokens are being transferred
     * @param to The recipient account
     * @param amount The amount of BPT to transfer
     * @return success Always returns true on success, reverts on failure
     */
    function transferFrom(address spender, address from, address to, uint256 amount) external returns (bool) {
        BalancerV3MultiTokenRepo._spendAllowance(msg.sender, from, spender, amount);
        BalancerV3MultiTokenRepo._transfer(msg.sender, from, to, amount);
        return true;
    }

    /* ========================================================================== */
    /*                               VIEW FUNCTIONS                               */
    /* ========================================================================== */

    /**
     * @notice Returns the total supply of a pool's BPT.
     * @param pool The pool address
     * @return Total BPT supply
     */
    function totalSupply(address pool) external view returns (uint256) {
        return BalancerV3MultiTokenRepo._totalSupply(pool);
    }

    /**
     * @notice Returns an account's BPT balance for a pool.
     * @param pool The pool address
     * @param account The account to query
     * @return BPT balance
     */
    function balanceOf(address pool, address account) external view returns (uint256) {
        return BalancerV3MultiTokenRepo._balanceOf(pool, account);
    }

    /**
     * @notice Returns the BPT allowance for a spender.
     * @param pool The pool address
     * @param owner The token owner
     * @param spender The approved spender
     * @return Allowance amount (type(uint256).max if owner == spender)
     */
    function allowance(address pool, address owner, address spender) external view returns (uint256) {
        return BalancerV3MultiTokenRepo._allowance(pool, owner, spender);
    }

    /**
     * @notice Approves a spender to transfer BPT.
     * @dev msg.sender must be the pool contract.
     *
     * @param owner The token owner
     * @param spender The account being approved
     * @param amount The approval amount
     * @return success Always returns true on success
     */
    function approve(address owner, address spender, uint256 amount) external returns (bool) {
        BalancerV3MultiTokenRepo._approve(msg.sender, owner, spender, amount);
        return true;
    }
}
