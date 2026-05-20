// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {betterconsole as console} from "@crane/contracts/utils/vm/foundry/tools/betterconsole.sol";
import {CraneTest} from "@crane/contracts/test/CraneTest.sol";

import {IOperable} from '@crane/contracts/access/operable/IOperable.sol';

contract Interfaces is CraneTest {

    function test() public pure {
        console.log("IOperable interface ID: ", type(IOperable).interfaceId);
        console.logBytes4(type(IOperable).interfaceId);
        console.log("IOperable NewGlobalOperatorStatus topic hash: ", keccak256("NewGlobalOperatorStatus(address,bool)"));
        console.log("IOperable NewFunctionOperatorStatus topic hash: ", keccak256("NewFunctionOperatorStatus(address,bytes4,bool)"));
        console.log("IOperable NotOperator selector: ", IOperable.NotOperator.selector);
        console.logBytes4(IOperable.NotOperator.selector);
        console.log("IOperable isOperator selector: ", IOperable.isOperator.selector);
        console.logBytes4(IOperable.isOperator.selector);
        console.log("IOperable isOperatorFor selector: ", IOperable.isOperatorFor.selector);
        console.logBytes4(IOperable.isOperatorFor.selector);
        console.log("IOperable setOperator selector: ", IOperable.setOperator.selector);
        console.logBytes4(IOperable.setOperator.selector);
        console.log("IOperable setOperatorFor selector:", IOperable.setOperatorFor.selector);
        console.logBytes4(IOperable.setOperatorFor.selector);
    }

}