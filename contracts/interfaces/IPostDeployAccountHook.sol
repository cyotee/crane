// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

interface IPostDeployAccountHook {
    /**
     * @custom:selector 0xba5b83ec
     */
    function postDeploy() external returns (bool);
}
