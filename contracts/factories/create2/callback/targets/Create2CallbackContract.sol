// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {
    Create2AwareTarget
} from "../../aware/targets/Create2AwareTarget.sol";
import {
    ICreate2CallbackFactory
} from "../interfaces/ICreate2CallbackFactory.sol";
import {
    ICreate2CallbackContract
} from "../interfaces/ICreate2CallbackContract.sol";

/**
 * @title Create2CallbackContract
 * @author cyotee doge <doge.cyotee>
 * @notice A contract that implements the ICreate2CallbackContract interface.
 * @notice Pulls and stores the initialization data of the contract.
 */
contract Create2CallbackContract
is
Create2AwareTarget,
ICreate2CallbackContract
{

    /**
     * @notice The initialization data of the contract.
     */
    bytes public initData;

    /**
     * @notice Constructor that pulls and stores the initialization data of the contract.
     */
    constructor() {
        // Set the origin and the deployer of the contract.
        ORIGIN = msg.sender;
        (INITCODE_HASH, SALT, initData) = ICreate2CallbackFactory(msg.sender).initData();
    }

}
