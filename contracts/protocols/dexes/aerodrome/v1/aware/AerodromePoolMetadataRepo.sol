// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IPoolFactory} from "@crane/contracts/interfaces/protocols/dexes/aerodrome/IPoolFactory.sol";

library AerodromePoolMetadataRepo {
    bytes32 internal constant STORAGE_SLOT = keccak256("crane.aerodrome.pool.metadata.repo");

    struct Storage {
        IPoolFactory factory;
        bool isStable;
    }

    function _layout(bytes32 slot) internal pure returns (Storage storage layout) {
        assembly {
            layout.slot := slot
        }
    }

    function _layout() internal pure returns (Storage storage layout) {
        return _layout(STORAGE_SLOT);
    }

    function _initialize(Storage storage layout, IPoolFactory factory_, bool isStable_) internal {
        layout.factory = factory_;
        layout.isStable = isStable_;
    }

    function _initialize(IPoolFactory factory_, bool isStable_) internal {
        _initialize(_layout(), factory_, isStable_);
    }

    function _factory(Storage storage layout) internal view returns (IPoolFactory factory_) {
        return layout.factory;
    }

    function _factory() internal view returns (IPoolFactory factory_) {
        return _factory(_layout());
    }

    function _isStable(Storage storage layout) internal view returns (bool isStable_) {
        return layout.isStable;
    }

    function _isStable() internal view returns (bool isStable_) {
        return _isStable(_layout());
    }
}