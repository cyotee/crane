// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.20;

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {BetterIERC20 as IERC20} from "contracts/crane/interfaces/BetterIERC20.sol";

/// forge-lint: disable-next-line(pascal-case-struct)
struct ERC4626Layout {
    IERC20 asset;
    uint8 assetDecimals;
    uint8 decimalsOffset;
}

library ERC4626Repo {
    // tag::layout[]
    /**
     * @dev "Binds" this struct to a storage slot.
     * @param slot_ The first slot to use in the range of slots used by the struct.
     * @return layout_ A struct from a Layout library bound to the provided slot.
     */
    function layout(bytes32 slot_) internal pure returns (ERC4626Layout storage layout_) {
        assembly {
            layout_.slot := slot_
        }
    }
    // end::layout[]
}
