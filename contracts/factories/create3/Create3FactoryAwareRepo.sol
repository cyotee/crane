// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {ICreate3FactoryProxy} from "@crane/contracts/interfaces/proxies/ICreate3FactoryProxy.sol";

library Create3FactoryAwareRepo {
    bytes32 internal constant STORAGE_SLOT = keccak256("crane.create3.factory.aware");

    struct Storage {
        ICreate3FactoryProxy factory;
    }

    function _layoutStruct(bytes32 slot) internal pure returns (Storage storage layoutStruct) {
        assembly {
            layoutStruct.slot := slot
        }
    }

    function _layoutStruct() internal pure returns (Storage storage layoutStruct) {
        return _layoutStruct(STORAGE_SLOT);
    }

    function _initialize(Storage storage layoutStruct, ICreate3FactoryProxy factory_) internal {
        layoutStruct.factory = factory_;
    }

    function _initialize(ICreate3FactoryProxy factory_) internal {
        _initialize(_layoutStruct(), factory_);
    }

    function _create3Factory(Storage storage layoutStruct) internal view returns (ICreate3FactoryProxy factory_) {
        return layoutStruct.factory;
    }

    function _create3Factory() internal view returns (ICreate3FactoryProxy factory_) {
        return _create3Factory(_layoutStruct());
    }
}
