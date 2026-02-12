// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {ERC20Repo} from "@crane/contracts/tokens/ERC20/ERC20Repo.sol";
import {ERC20PermitStub} from "@crane/contracts/tokens/ERC20/ERC20PermitStub.sol";

contract ERC20PermitMintableStub is ERC20PermitStub {
    constructor(string memory name_, string memory symbol_, uint8 decimals_, address recipient, uint256 initialAmount)
        ERC20PermitStub(name_, symbol_, decimals_, recipient, initialAmount)
    {}

    function mint(address account, uint256 amount) external returns (bool) {
        ERC20Repo._mint(account, amount);
        return true;
    }

    function burn(address account, uint256 amount) external returns (bool) {
        ERC20Repo._burn(account, amount);
        return true;
    }
}
