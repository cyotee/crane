// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import { IPermit2 } from "permit2/src/interfaces/IPermit2.sol";
import { IPermit2Aware } from "contracts/interfaces/IPermit2Aware.sol";

struct Permit2AwareLayout {
    IPermit2 permit2;
}

library Permit2AwareRepo {

    function _layout(
        bytes32 storageRange
    ) internal pure returns(Permit2AwareLayout storage layout_) {
        assembly{layout_.slot := storageRange}
    }

}

contract Permit2AwareStorage {

    /* ------------------------------ LIBRARIES ----------------------------- */

    using Permit2AwareRepo for bytes32;

    /* ---------------------------------------------------------------------- */
    /*                                 STORAGE                                */
    /* ---------------------------------------------------------------------- */

    /* -------------------------- STORAGE CONSTANTS ------------------------- */

    bytes32 private constant LAYOUT_ID
        = keccak256(abi.encode(type(Permit2AwareRepo).name));
    bytes32 private constant STORAGE_RANGE_OFFSET
        = bytes32(uint256(keccak256(abi.encode(LAYOUT_ID))) - 1);
    bytes32 private constant STORAGE_RANGE
        = type(IPermit2Aware).interfaceId;
    bytes32 private constant STORAGE_SLOT
        = keccak256(abi.encode(STORAGE_RANGE, STORAGE_RANGE_OFFSET));

    function _permit2Aware() internal pure returns (Permit2AwareLayout storage) {
        return STORAGE_SLOT._layout();
    }

    function _initPermit2Aware(
        IPermit2 permit2
    ) internal {
        _permit2Aware().permit2 = permit2;
    }

    function _permit2() internal view returns (IPermit2) {
        return _permit2Aware().permit2;
    }
    
}