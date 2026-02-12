// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {ERC20Repo} from "@crane/contracts/tokens/ERC20/ERC20Repo.sol";
import {ERC20Target} from "@crane/contracts/tokens/ERC20/ERC20Target.sol";

contract ERC20TargetStub is ERC20Target {
    constructor(address recipient, uint256 initialAmount) {
        ERC20Repo._mint(recipient, initialAmount);
    }
}
