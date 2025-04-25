// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {

    IDegenFactory

} from "../interfaces/IDegenFactory.sol";

import {OperableModifiers} from "../../../../access/operable/modifiers/OperableModifiers.sol";
import {OperableTarget} from "../../../../access/operable/targets/OperableTarget.sol";
import {OwnableTarget} from "../../../../access/ownable/targets/OwnableTarget.sol";

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