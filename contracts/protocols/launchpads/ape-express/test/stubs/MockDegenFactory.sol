// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {
    IDegenFactory
} from "contracts/interfaces/protocols/launchpads/ape-express/IDegenFactory.sol";
import {OperableModifiers} from "contracts/access/operable/OperableModifiers.sol";
import {OperableTarget} from "contracts/access/operable/OperableTarget.sol";
import {OwnableTarget} from "contracts/access/ownable/OwnableTarget.sol";

contract MockDegenFactory
is
OwnableTarget,
OperableModifiers,
OperableTarget,
IDegenFactory
{

    constructor(
        address owner_
    ) {
        _initOwner(owner_);
    }

    mapping(address token => address creator) public creatorByToken;

     function addCreator(
        address token,
        address creator
    ) public virtual
    onlyOwnerOrOperator()
    returns (bool) {
        creatorByToken[token] = creator;
        return true;
    }
}