// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IPoolFactory} from "@crane/contracts/interfaces/protocols/dexes/aerodrome/IPoolFactory.sol";

library AerodromePoolMetadataRepo {
    bytes32 internal constant STORAGE_SLOT = keccak256("crane.aerodrome.pool.metadata.repo");

    struct Storage {
        IPoolFactory factory;
        bool isStable;
    }

    function _layoutStruct(bytes32 slot) internal pure returns (Storage storage layoutStruct) {
        assembly {
            layoutStruct.slot := slot
        }
    }

    function _layoutStruct() internal pure returns (Storage storage layoutStruct) {
        return _layoutStruct(STORAGE_SLOT);
    }

    function _initialize(Storage storage layoutStruct, IPoolFactory factory_, bool isStable_) internal {
        layoutStruct.factory = factory_;
        layoutStruct.isStable = isStable_;
    }

    function _initialize(IPoolFactory factory_, bool isStable_) internal {
        _initialize(_layoutStruct(), factory_, isStable_);
    }

    function _factory(Storage storage layoutStruct) internal view returns (IPoolFactory factory_) {
        return layoutStruct.factory;
    }

    function _factory() internal view returns (IPoolFactory factory_) {
        return _factory(_layoutStruct());
    }

    function _isStable(Storage storage layoutStruct) internal view returns (bool isStable_) {
        return layoutStruct.isStable;
    }

    function _isStable() internal view returns (bool isStable_) {
        return _isStable(_layoutStruct());
    }
}
