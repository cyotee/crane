// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.24;

import {IVersion} from "@balancer-labs/v3-interfaces/contracts/solidity-utils/helpers/IVersion.sol";

struct VersionLayout {
    string version;
}

library VersionRepo {
    /**
     * @dev "Binds" a struct to a storage slot.
     * @param storageRange The first slot to use in the range of slots used by the struct.
     * @return layout_ A struct from a Layout library bound to the provided slot.
     */
    function _layout(bytes32 storageRange) internal pure returns (VersionLayout storage layout_) {
        assembly {
            layout_.slot := storageRange
        }
    }
}

contract VersionStorage {
    /* ------------------------------ LIBRARIES ----------------------------- */

    using VersionRepo for bytes32;

    /* ---------------------------------------------------------------------- */
    /*                                 STORAGE                                */
    /* ---------------------------------------------------------------------- */

    /* -------------------------- STORAGE CONSTANTS ------------------------- */

    bytes32 private constant LAYOUT_ID = keccak256(abi.encode(type(VersionRepo).name));
    bytes32 private constant STORAGE_RANGE_OFFSET = bytes32(uint256(LAYOUT_ID) - 1);
    bytes32 private constant STORAGE_RANGE = type(IVersion).interfaceId;
    bytes32 private constant STORAGE_SLOT = (STORAGE_RANGE ^ STORAGE_RANGE_OFFSET);

    // tag::_versionStorage()[]
    function _versionStorage() internal pure virtual returns (VersionLayout storage) {
        return STORAGE_SLOT._layout();
    }
    // end::_versionStorage()[]

    function _initVersionStorage(string memory version) internal {
        _versionStorage().version = version;
    }

    function _version() internal view virtual returns (string memory) {
        return _versionStorage().version;
    }

    /// @dev Internal setter that allows this contract to be used in proxies.
    function _setVersion(string memory newVersion) internal {
        _versionStorage().version = newVersion;
    }
}
