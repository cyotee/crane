// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {IPermit2} from "@crane/contracts/interfaces/protocols/utils/permit2/IPermit2.sol";
import {IPermit2Aware} from "@crane/contracts/interfaces/IPermit2Aware.sol";

// tag::struct[]
struct Permit2AwareLayout {
    IPermit2 permit2;
}

// end::struct[]

// tag::repo[]
library Permit2AwareRepo {
    /* ------------------------------ LIBRARIES ----------------------------- */

    using Permit2AwareRepo for bytes32;

    /* ---------------------------------------------------------------------- */
    /*                                 STORAGE                                */
    /* ---------------------------------------------------------------------- */

    /* -------------------------- STORAGE CONSTANTS ------------------------- */

    bytes32 private constant STORAGE_SLOT = keccak256(abi.encode("protocols.utils.permit2.aware"));

    function _layoutStruct(bytes32 storageRange) internal pure returns (Permit2AwareLayout storage layoutStruct_) {
        assembly {
            layoutStruct_.slot := storageRange
        }
    }

    function _layoutStruct() internal pure returns (Permit2AwareLayout storage) {
        return STORAGE_SLOT._layoutStruct();
    }

    function _initialize(Permit2AwareLayout storage layoutStruct, IPermit2 permit2) internal {
        layoutStruct.permit2 = permit2;
    }

    function _initialize(IPermit2 permit2) internal {
        _initialize(_layoutStruct(), permit2);
    }

    function _permit2(Permit2AwareLayout storage layoutStruct) internal view returns (IPermit2) {
        return layoutStruct.permit2;
    }

    function _permit2() internal view returns (IPermit2) {
        return _permit2(_layoutStruct());
    }
}
// end::repo[]
