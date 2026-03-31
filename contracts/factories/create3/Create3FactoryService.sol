// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {Creation} from "@crane/contracts/utils/Creation.sol";
import {BetterAddress as Address} from "@crane/contracts/utils/BetterAddress.sol";

library Create3FactoryService {
    using Address for address;

    function _create3(bytes memory initCode, bytes32 salt) internal returns (address proxy) {
        address predictedTarget = Creation._create3AddressOf(salt);
        if (predictedTarget.isContract()) {
            return predictedTarget;
        }
        return Creation.create3(initCode, salt);
    }

    function _create3WithArgs(bytes memory initCode, bytes memory initData_, bytes32 salt)
        internal
        returns (address proxy)
    {
        return Creation.create3WithArgs(initCode, initData_, salt);
    }
}
