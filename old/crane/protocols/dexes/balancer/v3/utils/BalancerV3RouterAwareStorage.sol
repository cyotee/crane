// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                 Balancer V3                                */
/* -------------------------------------------------------------------------- */

import {IRouter} from "@balancer-labs/v3-interfaces/contracts/vault/IRouter.sol";

/* -------------------------------------------------------------------------- */
/*                                  Indexedex                                 */
/* -------------------------------------------------------------------------- */

import {IBalancerV3RouterAware} from "contracts/crane/interfaces/IBalancerV3RouterAware.sol";

struct BalancerV3RouterAwareLayout {
    IRouter balancerV3Router;
}

library BalancerV3RouterAwareRepo {
    function _layout(bytes32 slot_) internal pure returns (BalancerV3RouterAwareLayout storage layout) {
        assembly {
            layout.slot := slot_
        }
    }
}

abstract contract BalancerV3RouterAwareStorage {
    using BalancerV3RouterAwareRepo for bytes32;

    bytes32 private constant LAYOUT_ID = keccak256(abi.encode(type(BalancerV3RouterAwareRepo).name));
    bytes32 private constant STORAGE_RANGE_OFFSET = bytes32(uint256(LAYOUT_ID) - 1);
    bytes32 private constant STORAGE_RANGE = type(IBalancerV3RouterAware).interfaceId;
    bytes32 private constant STORAGE_SLOT = (STORAGE_RANGE ^ STORAGE_RANGE_OFFSET);

    function _layout() private pure returns (BalancerV3RouterAwareLayout storage layout) {
        return BalancerV3RouterAwareRepo._layout(STORAGE_SLOT);
    }

    function _balancerV3Router() internal view returns (IRouter) {
        return _layout().balancerV3Router;
    }
}
