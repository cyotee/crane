// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IPostDeployAccountHook {

    function postDeploy() external returns(bool);

}