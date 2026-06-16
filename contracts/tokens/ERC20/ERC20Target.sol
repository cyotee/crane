// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                Open Zeppelin                               */
/* -------------------------------------------------------------------------- */

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IERC20Metadata} from "@crane/contracts/interfaces/IERC20Metadata.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {ERC20Repo} from "@crane/contracts/tokens/ERC20/ERC20Repo.sol";
import {BetterIERC20} from "@crane/contracts/interfaces/BetterIERC20.sol";
// import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";

// tag::ERC20Target[]
/**
 * @title ERC20Target - Target contract implementing the ERC-20 standard (IERC20 + IERC20Metadata via BetterIERC20) per Facet-Target-Repo pattern.
 * @author cyotee doge <not_cyotee@proton.me>
 * @dev Delegates storage operations to ERC20Repo. Inherited by ERC20Facet (and permit extensions). Does not implement IFacet (see ERC20Facet).
 */
contract ERC20Target is BetterIERC20 {
    /* -------------------------------------------------------------------------- */
    /*                              IERC20 Functions                              */
    /* -------------------------------------------------------------------------- */

    // tag::approve(address,uint256)[]
    /**
     * @inheritdoc IERC20
     * @custom:selector 0x095ea7b3
     * @custom:signature approve(address,uint256)
     * @custom:emits Approval(address,address,uint256)
     */
    function approve(address spender, uint256 amount) external returns (bool) {
        ERC20Repo._approve(msg.sender, spender, amount);
        return true;
    }
    // end::approve(address,uint256)[]

    // tag::transfer(address,uint256)[]
    /**
     * @inheritdoc IERC20
     * @custom:selector 0xa9059cbb
     * @custom:signature transfer(address,uint256)
     * @custom:emits Transfer(address,address,uint256)
     */
    function transfer(address recipient, uint256 amount) external returns (bool) {
        ERC20Repo._transfer(msg.sender, recipient, amount);
        return true;
    }
    // end::transfer(address,uint256)[]

    // tag::transferFrom(address,address,uint256)[]
    /**
     * @inheritdoc IERC20
     * @custom:selector 0x23b872dd
     * @custom:signature transferFrom(address,address,uint256)
     * @custom:emits Transfer(address,address,uint256)
     */
    function transferFrom(address owner, address recipient, uint256 amount) external returns (bool) {
        ERC20Repo._transferFrom(owner, recipient, amount);
        return true;
    }
    // end::transferFrom(address,address,uint256)[]

    // tag::totalSupply()[]
    /**
     * @inheritdoc IERC20
     * @custom:selector 0x18160ddd
     * @custom:signature totalSupply()
     */
    function totalSupply() external view returns (uint256) {
        return ERC20Repo._totalSupply();
    }
    // end::totalSupply()[]

    // tag::balanceOf(address)[]
    /**
     * @inheritdoc IERC20
     * @custom:selector 0x70a08231
     * @custom:signature balanceOf(address)
     */
    function balanceOf(address account) external view returns (uint256) {
        return ERC20Repo._balanceOf(account);
    }
    // end::balanceOf(address)[]

    // tag::allowance(address,address)[]
    /**
     * @inheritdoc IERC20
     * @custom:selector 0xdd62ed3e
     * @custom:signature allowance(address,address)
     */
    function allowance(address owner, address spender) external view returns (uint256) {
        return ERC20Repo._allowance(owner, spender);
    }
    // end::allowance(address,address)[]

    /* -------------------------------------------------------------------------- */
    /*                          IERC20Metadata Functions                          */
    /* -------------------------------------------------------------------------- */

    // tag::name()[]
    /**
     * @inheritdoc IERC20Metadata
     * @custom:selector 0x06fdde03
     * @custom:signature name()
     */
    function name() external view returns (string memory) {
        return ERC20Repo._name();
    }
    // end::name()[]

    // tag::symbol()[]
    /**
     * @inheritdoc IERC20Metadata
     * @custom:selector 0x95d89b41
     * @custom:signature symbol()
     */
    function symbol() external view returns (string memory) {
        return ERC20Repo._symbol();
    }
    // end::symbol()[]

    // tag::decimals()[]
    /**
     * @inheritdoc IERC20Metadata
     * @custom:selector 0x313ce567
     * @custom:signature decimals()
     */
    function decimals() external view returns (uint8) {
        return ERC20Repo._decimals();
    }
    // end::decimals()[]
}
// end::ERC20Target[]
