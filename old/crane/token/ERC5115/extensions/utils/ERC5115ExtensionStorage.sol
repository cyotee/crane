// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {Bytes4Set, Bytes4SetRepo} from "@crane/src/utils/collections/sets/Bytes4SetRepo.sol";
import {ERC5115ExtensionLayout, ERC5115ExtensionRepo} from "./ERC5115ExtensionRepo.sol";
import {IERC5115Extension} from "contracts/crane/interfaces/IERC5115Extension.sol";

contract ERC5115ExtensionStorage {
    /* ------------------------------ LIBRARIES ----------------------------- */

    using Bytes4SetRepo for Bytes4Set;
    using ERC5115ExtensionRepo for bytes32;

    /* ---------------------------------------------------------------------- */
    /*                                 STORAGE                                */
    /* ---------------------------------------------------------------------- */

    /* -------------------------- STORAGE CONSTANTS ------------------------- */

    bytes32 private constant LAYOUT_ID = keccak256(abi.encode(type(ERC5115ExtensionRepo).name));
    bytes32 private constant STORAGE_RANGE_OFFSET = bytes32(uint256(LAYOUT_ID) - 1);
    bytes32 private constant STORAGE_RANGE = type(IERC5115Extension).interfaceId;
    bytes32 private constant STORAGE_SLOT = (STORAGE_RANGE ^ STORAGE_RANGE_OFFSET);

    // tag::_erc5115Extension()[]
    /**
     * @dev internal hook for the default storage range used by this library.
     * @dev Other services will use their default storage range to ensure consistent storage usage.
     * @return The default storage range used with repos.
     */
    function _erc5115Extension() internal pure virtual returns (ERC5115ExtensionLayout storage) {
        return STORAGE_SLOT._layout();
    }

    // end::_erc5115Extension()[]

    /// forge-lint: disable-next-line(mixed-case-function)
    function _initERC5115Extension(bytes4[] memory yieldTokenTypes) internal {
        _erc5115Extension().yieldTokenTypes._add(yieldTokenTypes);
    }

    function _yieldTokenTypes() internal view returns (Bytes4Set storage) {
        return _erc5115Extension().yieldTokenTypes;
    }
}
