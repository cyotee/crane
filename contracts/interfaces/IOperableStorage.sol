// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/**
 * @title IOperableStorage - Inheritable structs for 
 */
interface IOperableStorage
{

    struct OperatorConfig {
        address operator;
        bytes4[] funcs;
    }

    struct OperableAccountInit {
        address[] globalOperators;
        OperatorConfig[] operatorConfigs;
    }

}
