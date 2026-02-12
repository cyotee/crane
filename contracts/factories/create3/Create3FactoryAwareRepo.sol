// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {ICreate3Factory} from "@crane/contracts/interfaces/ICreate3Factory.sol";

library Create3FactoryAwareRepo {
    bytes32 internal constant STORAGE_SLOT = keccak256("crane.create3.factory.aware");

    struct Storage {
        ICreate3Factory factory;
    }

    function _layout(bytes32 slot) internal pure returns (Storage storage layout) {
        assembly {
            layout.slot := slot
        }
    }

    function _layout() internal pure returns (Storage storage layout) {
        return _layout(STORAGE_SLOT);
    }

    function _initialize(Storage storage layout, ICreate3Factory factory_) internal {
        layout.factory = factory_;
    }

    function _initialize(ICreate3Factory factory_) internal {
        _initialize(_layout(), factory_);
    }

    function _create3Factory(Storage storage layout) internal view returns (ICreate3Factory factory_) {
        return layout.factory;
    }

    function _create3Factory() internal view returns (ICreate3Factory factory_) {
        return _create3Factory(_layout());
    }

}