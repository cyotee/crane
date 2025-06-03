// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {
    ICreate2Aware
} from "./ICreate2Aware.sol";

interface ICreate3Aware is ICreate2Aware {

    struct CREATE3InitData {
        bytes32 salt;
        bytes initData;
    }

    function initData() external view returns (bytes memory);

}
