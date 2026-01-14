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

contract ERC20Target is BetterIERC20 {
    /* -------------------------------------------------------------------------- */
    /*                              IERC20 Functions                              */
    /* -------------------------------------------------------------------------- */

    function approve(address spender, uint256 amount) external returns (bool) {
        ERC20Repo._approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @inheritdoc IERC20
     */
    function transfer(address recipient, uint256 amount) external returns (bool) {
        ERC20Repo._transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(address owner, address recipient, uint256 amount) external returns (bool) {
        ERC20Repo._transferFrom(owner, recipient, amount);
        return true;
    }

    /**
     * @inheritdoc IERC20
     */
    function totalSupply() external view returns (uint256) {
        return ERC20Repo._totalSupply();
    }

    /**
     * @inheritdoc IERC20
     */
    function balanceOf(address account) external view returns (uint256) {
        return ERC20Repo._balanceOf(account);
    }

    /**
     * @inheritdoc IERC20
     */
    function allowance(address owner, address spender) external view returns (uint256) {
        return ERC20Repo._allowance(owner, spender);
    }

    /* -------------------------------------------------------------------------- */
    /*                          IERC20Metadata Functions                          */
    /* -------------------------------------------------------------------------- */

    /**
     * @inheritdoc IERC20Metadata
     */
    function name() external view returns (string memory) {
        return ERC20Repo._name();
    }

    /**
     * @inheritdoc IERC20Metadata
     */
    function symbol() external view returns (string memory) {
        return ERC20Repo._symbol();
    }

    /**
     * @inheritdoc IERC20Metadata
     */
    function decimals() external view returns (uint8) {
        return ERC20Repo._decimals();
    }
}
