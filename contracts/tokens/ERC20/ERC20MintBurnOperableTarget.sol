// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {MultiStepOwnableModifiers} from "contracts/access/ERC8023/MultiStepOwnableModifiers.sol";
import {OperableModifiers} from "contracts/access/operable/OperableModifiers.sol";
// import {ERC20MintBurnOperableStorage} from "contracts/crane/token/ERC20/utils/ERC20MintBurnOperableStorage.sol";
import {ERC20PermitTarget} from "contracts/tokens/ERC20/ERC20PermitTarget.sol";
import {IERC20MintBurn} from "contracts/interfaces/IERC20MintBurn.sol";
import {ERC20Repo} from "contracts/tokens/ERC20/ERC20Repo.sol";

contract ERC20MintBurnOperableTarget is
    ERC20PermitTarget,
    MultiStepOwnableModifiers,
    OperableModifiers,
    IERC20MintBurn
{
    function mint(address account, uint256 amount) external virtual onlyOwnerOrOperator returns (bool) {
        ERC20Repo._mint(account, amount);
        return true;
    }

    function burn(address account, uint256 amount) external virtual onlyOwnerOrOperator returns (bool) {
        ERC20Repo._burn(account, amount);
        return true;
    }
}
