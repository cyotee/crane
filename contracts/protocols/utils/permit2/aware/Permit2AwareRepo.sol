// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                   Permit2                                  */
/* -------------------------------------------------------------------------- */

// import {IPermit2} from "permit2/src/interfaces/IPermit2.sol";

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

    function _layout(bytes32 storageRange) internal pure returns (Permit2AwareLayout storage layout_) {
        assembly {
            layout_.slot := storageRange
        }
    }

    function _layout() internal pure returns (Permit2AwareLayout storage) {
        return STORAGE_SLOT._layout();
    }

    function _initialize(Permit2AwareLayout storage layout, IPermit2 permit2) internal {
        layout.permit2 = permit2;
    }

    function _initialize(IPermit2 permit2) internal {
        _initialize(_layout(), permit2);
    }

    function _permit2(Permit2AwareLayout storage layout) internal view returns (IPermit2) {
        return layout.permit2;
    }

    function _permit2() internal view returns (IPermit2) {
        return _permit2(_layout());
    }
}
// end::repo[]
