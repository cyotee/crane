// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {Create2AwareTarget} from "contracts/factories/create2/aware/Create2AwareTarget.sol";
import {ICreate2CallbackFactory} from "contracts/interfaces/ICreate2CallbackFactory.sol";
import {ICreate2CallbackContract} from "contracts/interfaces/ICreate2CallbackContract.sol";

/**
 * @title Create2CallbackContract
 * @author cyotee doge <doge.cyotee>
 * @notice A contract that implements the ICreate2CallbackContract interface.
 * @notice Pulls and stores the initialization data of the contract.
 */
contract Create2CallbackContract is Create2AwareTarget, ICreate2CallbackContract {
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
