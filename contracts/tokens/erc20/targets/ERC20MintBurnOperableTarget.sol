// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {
    OwnableModifiers
} from "../../../access/ownable/modifiers/OwnableModifiers.sol";
import {
    OperableModifiers
} from "../../../access/operable/modifiers/OperableModifiers.sol";
import {
    ERC20MintBurnOperableStorage
} from "../../../tokens/erc20/storage/ERC20MintBurnOperableStorage.sol";
import {
    ERC20PermitTarget
} from "../../../tokens/erc20/targets/ERC20PermitTarget.sol";
import {
    IERC20MintBurn
} from "../../../tokens/erc20/interfaces/IERC20MintBurn.sol";
contract ERC20MintBurnOperableTarget
is
ERC20PermitTarget,
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
