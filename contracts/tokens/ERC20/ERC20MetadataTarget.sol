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
import {IERC20Metadata} from "@crane/contracts/interfaces/IERC20Metadata.sol";

abstract contract ERC20MetadataTarget is IERC20Metadata {
    /* -------------------------------------------------------------------------- */
    /*                          IERC20Metadata Functions                          */
    /* -------------------------------------------------------------------------- */

    function name() external view returns (string memory) {
        return ERC20Repo._name();
    }

    function symbol() external view returns (string memory) {
        return ERC20Repo._symbol();
    }

    function decimals() external view returns (uint8) {
        return ERC20Repo._decimals();
    }
}
