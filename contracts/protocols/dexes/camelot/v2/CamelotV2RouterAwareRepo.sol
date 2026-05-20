// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {ICamelotV2Router} from "@crane/contracts/interfaces/protocols/dexes/camelot/v2/ICamelotV2Router.sol";

library CamelotV2RouterAwareRepo {
    bytes32 internal constant STORAGE_SLOT = keccak256("crane.camelot.v2.router.aware");

    struct Storage {
        ICamelotV2Router router;
    }

    function _layoutStruct(bytes32 slot) internal pure returns (Storage storage layoutStruct) {
        assembly {
            layoutStruct.slot := slot
        }
    }

    function _layoutStruct() internal pure returns (Storage storage layoutStruct) {
        return _layoutStruct(STORAGE_SLOT);
    }

    function _initialize(Storage storage layoutStruct, ICamelotV2Router router_) internal {
        layoutStruct.router = router_;
    }

    function _initialize(ICamelotV2Router router_) internal {
        _initialize(_layoutStruct(), router_);
    }

    function _camelotV2Router(Storage storage layoutStruct) internal view returns (ICamelotV2Router router_) {
        return layoutStruct.router;
    }

    function _camelotV2Router() internal view returns (ICamelotV2Router router_) {
        return _camelotV2Router(_layoutStruct());
    }
}
