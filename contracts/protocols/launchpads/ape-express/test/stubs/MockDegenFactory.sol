// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {IDegenFactory} from "@crane/contracts/interfaces/protocols/launchpads/ape-express/IDegenFactory.sol";
import {OperableModifiers} from "@crane/contracts/access/operable/OperableModifiers.sol";
import {OperableTarget} from "@crane/contracts/access/operable/OperableTarget.sol";
import {MultiStepOwnableTarget} from "@crane/contracts/access/ERC8023/MultiStepOwnableTarget.sol";
import {MultiStepOwnableRepo} from "@crane/contracts/access/ERC8023/MultiStepOwnableRepo.sol";

contract MockDegenFactory is MultiStepOwnableTarget, OperableModifiers, OperableTarget, IDegenFactory {
    constructor(address owner_) {
        MultiStepOwnableRepo._initialize(owner_, 1 seconds);
    }

    mapping(address token => address creator) public creatorByToken;

    function addCreator(address token, address creator) public virtual onlyOwnerOrOperator returns (bool) {
        creatorByToken[token] = creator;
        return true;
    }
}
