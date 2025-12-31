// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                Open Zeppelin                               */
/* -------------------------------------------------------------------------- */

import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {BetterIERC20 as IERC20} from "contracts/crane/interfaces/BetterIERC20.sol";
import {IERC4626Aware} from "contracts/crane/interfaces/IERC4626Aware.sol";

/// forge-lint: disable-next-line(pascal-case-struct)
struct ERC4626AwareLayout {
    IERC4626 wrapper;
    IERC20 underlying;
}

library ERC4626AwareRepo {
    function _layout(bytes32 slot_) internal pure returns (ERC4626AwareLayout storage layout_) {
        assembly {
            layout_.slot := slot_
        }
    }
}

contract ERC4626AwareStorage {
    using ERC4626AwareRepo for bytes32;

    /* ---------------------------------------------------------------------- */
    /*                                 STORAGE                                */
    /* ---------------------------------------------------------------------- */

    /* -------------------------- STORAGE CONSTANTS ------------------------- */

    bytes32 private constant LAYOUT_ID = keccak256(abi.encode(type(ERC4626AwareRepo).name));
    bytes32 private constant STORAGE_RANGE_OFFSET = bytes32(uint256(LAYOUT_ID) - 1);
    bytes32 private constant STORAGE_RANGE =
    // We XOR the two interfaces because the current ERC20 standard no longer states the metadata is optional.
    // https://eips.ethereum.org/EIPS/eip-20
    type(IERC4626Aware).interfaceId;
    bytes32 private constant STORAGE_SLOT = (STORAGE_RANGE ^ STORAGE_RANGE_OFFSET);

    // tag::_balV3VaultAware()[]
    /**
     * @dev internal hook for the default storage range used by this contract.
     * @return The default storage range used with repos.
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function _ERC4626Aware() internal pure virtual returns (ERC4626AwareLayout storage) {
        return STORAGE_SLOT._layout();
    }

    // end::_balV3VaultAware()[]

    /* ---------------------------------------------------------------------- */
    /*                             Initialization                             */
    /* ---------------------------------------------------------------------- */

    /// forge-lint: disable-next-line(mixed-case-function)
    function _initERC4626Aware(IERC4626 wrapper_, IERC20 underlying_) internal {
        _ERC4626Aware().wrapper = wrapper_;
        _ERC4626Aware().underlying = underlying_;
    }

    /* ---------------------------------------------------------------------- */
    /*                                  Logic                                 */
    /* ---------------------------------------------------------------------- */

    function _wrapper() internal view returns (IERC4626) {
        return _ERC4626Aware().wrapper;
    }

    function _underlying() internal view returns (IERC20) {
        return _ERC4626Aware().underlying;
    }
}
