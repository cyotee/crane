// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IOwnableStorage, OwnableStorage} from "contracts/crane/access/ownable/utils/OwnableStorage.sol";
import {IOperableStorage, OperableStorage} from "contracts/crane/access/operable/OperableStorage.sol";
import {ERC20Storage} from "contracts/crane/token/ERC20/utils/ERC20Storage.sol";

interface IERC20MintBurnOperableStorage {
    struct MintBurnOperableAccountInit {
        IOwnableStorage.OwnableAccountInit ownableAccountInit;
        IOperableStorage.OperableAccountInit operableAccountInit;
        string name;
        string symbol;
        uint8 decimals;
    }
}

// TODO Make an ERC20Permit version of Mint/Burn token.
contract ERC20MintBurnOperableStorage is OwnableStorage, OperableStorage, ERC20Storage, IERC20MintBurnOperableStorage {
    /// forge-lint: disable-next-line(mixed-case-function)
    function _initERC20MB(
        address owner,
        address[] memory globalOperators,
        string memory name,
        string memory symbol,
        uint8 decimals
    ) internal {
        _initOwner(owner);
        _isOperator(owner, true);
        _initERC20(name, symbol, decimals);
        // Buying memory for the cursor is cheaper then branching on a length check.
        for (uint256 cursor = 0; cursor < globalOperators.length; cursor++) {
            _isOperator(globalOperators[cursor], true);
        }
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function _initERC20(IERC20MintBurnOperableStorage.MintBurnOperableAccountInit memory mintBurnOperableAccountInit)
        internal
    {
        // _initOwnable(mintBurnOperableAccountInit.ownableAccountInit);
        _initOwnable(mintBurnOperableAccountInit.ownableAccountInit.owner);
        if (mintBurnOperableAccountInit.operableAccountInit.operatorConfigs.length == 0) {
            _isOperator(mintBurnOperableAccountInit.ownableAccountInit.owner, true);
        }
        _initOperable(mintBurnOperableAccountInit.operableAccountInit);
        _initERC20(
            mintBurnOperableAccountInit.name, mintBurnOperableAccountInit.symbol, mintBurnOperableAccountInit.decimals
        );
    }
}
