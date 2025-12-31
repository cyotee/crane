// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {AddressSet} from 
// AddressSetRepo
"@crane/src/utils/collections/sets/AddressSetRepo.sol";

/// forge-lint: disable-next-line(pascal-case-struct)
struct ERC5115Layout {
    address yieldToken;
    AddressSet tokensIn;
    AddressSet tokensOut;
}

library ERC5115Repo {
    // tag::_layout[]
    /**
     * @dev "Binds" this struct to a storage slot.
     * @param slot_ The first slot to use in the range of slots used by the struct.
     * @return layout_ A struct from a Layout library bound to the provided slot.
     */
    function _layout(bytes32 slot_) internal pure returns (ERC5115Layout storage layout_) {
        assembly {
            layout_.slot := slot_
        }
    }
    // end::_layout[]
}
