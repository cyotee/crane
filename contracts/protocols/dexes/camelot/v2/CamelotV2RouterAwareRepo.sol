// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {ICamelotV2Router} from "@crane/contracts/interfaces/protocols/dexes/camelot/v2/ICamelotV2Router.sol";

library CamelotV2RouterAwareRepo {
    bytes32 internal constant STORAGE_SLOT = keccak256("crane.camelot.v2.router.aware");

    struct Storage {
        ICamelotV2Router router;
    }

    function _layout(bytes32 slot) internal pure returns (Storage storage layout) {
        assembly {
            layout.slot := slot
        }
    }

    function _layout() internal pure returns (Storage storage layout) {
        return _layout(STORAGE_SLOT);
    }

    function _initialize(Storage storage layout, ICamelotV2Router router_) internal {
        layout.router = router_;
    }

    function _initialize(ICamelotV2Router router_) internal {
        _initialize(_layout(), router_);
    }

    function _camelotV2Router(Storage storage layout) internal view returns (ICamelotV2Router router_) {
        return layout.router;
    }

    function _camelotV2Router() internal view returns (ICamelotV2Router router_) {
        return _camelotV2Router(_layout());
    }
}