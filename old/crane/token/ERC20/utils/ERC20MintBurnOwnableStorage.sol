// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IOwnableStorage, OwnableStorage} from "contracts/crane/access/ownable/utils/OwnableStorage.sol";
import {IOperableStorage, OperableStorage} from "contracts/crane/access/operable/OperableStorage.sol";
import {ERC20PermitStorage} from "contracts/crane/token/ERC20/extensions/utils/ERC20PermitStorage.sol";

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
contract ERC20MintBurnOwnableStorage is OwnableStorage, ERC20PermitStorage, IERC20MintBurnOperableStorage {
    /// forge-lint: disable-next-line(mixed-case-function)
    function _initERC20MB(
        address owner,
        string memory name,
        string memory symbol,
        uint8 decimals,
        string memory version
    ) internal {
        _initOwner(owner);
        _initERC20Permit(name, symbol, decimals, version);
    }
}
