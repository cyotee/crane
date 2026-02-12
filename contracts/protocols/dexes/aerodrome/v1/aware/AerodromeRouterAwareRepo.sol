// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IRouter} from "@crane/contracts/interfaces/protocols/dexes/aerodrome/IRouter.sol";

library AerodromeRouterAwareRepo {
    bytes32 internal constant STORAGE_SLOT = keccak256("crane.aerodrome.router.aware");

    struct Storage {
        IRouter router;
    }

    function _layout(bytes32 slot) internal pure returns (Storage storage layout) {
        assembly {
            layout.slot := slot
        }
    }

    function _layout() internal pure returns (Storage storage layout) {
        return _layout(STORAGE_SLOT);
    }

    function _initialize(Storage storage layout, IRouter router_) internal {
        layout.router = router_;
    }

    function _initialize(IRouter router_) internal {
        _initialize(_layout(), router_);
    }

    function _aerodromeRouter(Storage storage layout) internal view returns (IRouter router_) {
        return layout.router;
    }

    function _aerodromeRouter() internal view returns (IRouter router_) {
        return _aerodromeRouter(_layout());
    }
}