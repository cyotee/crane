// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {Bytes4Set} from 
// Bytes4SetRepo
"@crane/src/utils/collections/sets/Bytes4SetRepo.sol";

/// forge-lint: disable-next-line(pascal-case-struct)
struct ERC5115ExtensionLayout {
    Bytes4Set yieldTokenTypes;
}

library ERC5115ExtensionRepo {
    // tag::_layout[]
    /**
     * @dev "Binds" this struct to a storage slot.
     * @param slot_ The first slot to use in the range of slots used by the struct.
     * @return layout_ A struct from a Layout library bound to the provided slot.
     */
    function _layout(bytes32 slot_) internal pure returns (ERC5115ExtensionLayout storage layout_) {
        assembly {
            layout_.slot := slot_
        }
    }
    // end::_layout[]
}
