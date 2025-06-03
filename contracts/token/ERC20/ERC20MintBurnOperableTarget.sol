// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {
    OwnableModifiers
} from "../../access/ownable/OwnableModifiers.sol";
import {
    OperableModifiers
} from "../../access/operable/OperableModifiers.sol";
import {
    ERC20MintBurnOperableStorage
} from "./utils/ERC20MintBurnOperableStorage.sol";
import {
    BetterERC20Permit
} from "./extensions/BetterERC20Permit.sol";
import {
    IERC20MintBurn
} from "../../interfaces/IERC20MintBurn.sol";

contract ERC20MintBurnOperableTarget
is
BetterERC20Permit,
OwnableModifiers,
OperableModifiers,
ERC20MintBurnOperableStorage,
IERC20MintBurn
{

    function mint(
        address account,
        uint256 amount
    ) external virtual onlyOwnerOrOperator() returns(bool) {
        _mint(account, amount);
        return true;
    }

    function burn(
        address account,
        uint256 amount
    ) external virtual onlyOwnerOrOperator() returns(bool) {
        _burn(account, amount);
        return true;
    }

}
