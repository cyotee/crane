// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IRouter} from "@crane/contracts/interfaces/protocols/dexes/aerodrome/IRouter.sol";

library AerodromeRouterAwareRepo {
    bytes32 internal constant STORAGE_SLOT = keccak256("crane.aerodrome.router.aware");

    struct Storage {
        IRouter router;
    }

    function _layoutStruct(bytes32 slot) internal pure returns (Storage storage layoutStruct) {
        assembly {
            layoutStruct.slot := slot
        }
    }

    function _layoutStruct() internal pure returns (Storage storage layoutStruct) {
        return _layoutStruct(STORAGE_SLOT);
    }

    function _initialize(Storage storage layoutStruct, IRouter router_) internal {
        layoutStruct.router = router_;
    }

    function _initialize(IRouter router_) internal {
        _initialize(_layoutStruct(), router_);
    }

    function _aerodromeRouter(Storage storage layoutStruct) internal view returns (IRouter router_) {
        return layoutStruct.router;
    }

    function _aerodromeRouter() internal view returns (IRouter router_) {
        return _aerodromeRouter(_layoutStruct());
    }
}
