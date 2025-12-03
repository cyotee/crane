// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                Open Zeppelin                               */
/* -------------------------------------------------------------------------- */

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {ERC20Layout, ERC20Repo} from "contracts/tokens/ERC20/ERC20Repo.sol";
import {BetterIERC20} from "contracts/interfaces/BetterIERC20.sol";
import {IFacet} from "contracts/interfaces/IFacet.sol";

contract ERC20Facet is BetterIERC20, IFacet {
    /* -------------------------------------------------------------------------- */
    /*                              IFacet Functions                              */
    /* -------------------------------------------------------------------------- */

    function facetInterfaces() external pure returns (bytes4[] memory facetInterfaces_) {
        facetInterfaces_ = new bytes4[](3);
        facetInterfaces_[0] = type(IERC20Metadata).interfaceId;
        facetInterfaces_[1] = type(IERC20).interfaceId;
        facetInterfaces_[2] = type(IERC20).interfaceId ^ type(IERC20Metadata).interfaceId;
    }

    function facetFuncs() external pure returns (bytes4[] memory facetFuncs_) {
        facetFuncs_ = new bytes4[](9);
        facetFuncs_[0] = IERC20Metadata.name.selector;
        facetFuncs_[1] = IERC20Metadata.symbol.selector;
        facetFuncs_[2] = IERC20Metadata.decimals.selector;
        facetFuncs_[3] = IERC20.totalSupply.selector;
        facetFuncs_[4] = IERC20.balanceOf.selector;
        facetFuncs_[5] = IERC20.allowance.selector;
        facetFuncs_[6] = IERC20.approve.selector;
        facetFuncs_[7] = IERC20.transfer.selector;
        facetFuncs_[8] = IERC20.transferFrom.selector;
    }

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
        ERC20Repo._transfer(owner, recipient, amount);
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
