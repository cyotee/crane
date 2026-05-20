// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {ICamelotFactory} from "@crane/contracts/interfaces/protocols/dexes/camelot/v2/ICamelotFactory.sol";

library CamelotV2FactoryAwareRepo {
    bytes32 internal constant STORAGE_SLOT = keccak256("crane.camelot.v2.factory.aware");

    struct Storage {
        ICamelotFactory factory;
    }

    function _layoutStruct(bytes32 slot) internal pure returns (Storage storage layoutStruct) {
        assembly {
            layoutStruct.slot := slot
        }
    }

    function _layoutStruct() internal pure returns (Storage storage layoutStruct) {
        return _layoutStruct(STORAGE_SLOT);
    }

    function _initialize(Storage storage layoutStruct, ICamelotFactory factory_) internal {
        layoutStruct.factory = factory_;
    }

    function _initialize(ICamelotFactory factory_) internal {
        _initialize(_layoutStruct(), factory_);
    }

    function _camelotV2Factory(Storage storage layoutStruct) internal view returns (ICamelotFactory factory_) {
        return layoutStruct.factory;
    }

    function _camelotV2Factory() internal view returns (ICamelotFactory factory_) {
        return _camelotV2Factory(_layoutStruct());
    }
}
