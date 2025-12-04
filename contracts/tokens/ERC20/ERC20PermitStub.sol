// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                Open Zeppelin                               */
/* -------------------------------------------------------------------------- */

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import {IERC5267} from "@openzeppelin/contracts/interfaces/IERC5267.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {ERC5267Target} from "@crane/contracts/utils/cryptography/ERC5267/ERC5267Target.sol";
import {ERC2612Target} from "@crane/contracts/tokens/ERC2612/ERC2612Target.sol";
import {BetterIERC20Permit} from "@crane/contracts/interfaces/BetterIERC20Permit.sol";
import {ERC20Target} from "@crane/contracts/tokens/ERC20/ERC20Target.sol";
import {ERC20PermitTarget} from "@crane/contracts/tokens/ERC20/ERC20PermitTarget.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
// import {Create3AwareContract} from "@crane/contracts/factories/create2/aware/Create3AwareContract.sol";
// import {ICreate3Aware} from "@crane/contracts/interfaces/ICreate3Aware.sol";
import {ERC20Repo} from "@crane/contracts/tokens/ERC20/ERC20Repo.sol";

contract ERC20PermitStub is ERC20PermitTarget {
    constructor(string memory name_, string memory symbol_, uint8 decimals_, address recipient, uint256 initialAmount) {
        ERC20Repo.Storage storage erc20 = ERC20Repo._layout();
        ERC20Repo._initialize(erc20, name_, symbol_, decimals_);
        ERC20Repo._mint(erc20, recipient, initialAmount);
    }
}
