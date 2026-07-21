// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@crane/contracts/external/openzeppelin-contracts-v4/governance/TimelockController.sol";

contract EtherFiTimelock is TimelockController {

    constructor(
        uint256 minDelay,
        address[] memory proposers,
        address[] memory executors,
        address admin
    ) TimelockController(minDelay, proposers, executors, admin) {}

}
