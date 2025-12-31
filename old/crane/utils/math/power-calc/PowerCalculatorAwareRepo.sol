// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IPower} from "contracts/crane/interfaces/IPower.sol";

struct PowerCalculatorAwareLayout {
    IPower powerCalculator;
}

library PowerCalculatorAwareRepo {
    // tag::_layout[]
    /**
     * @dev "Binds" this struct to a storage slot.
     * @param slot_ The first slot to use in the range of slots used by the struct.
     * @return layout_ A struct from a Layout library bound to the provided slot.
     */
    function _layout(bytes32 slot_) internal pure returns (PowerCalculatorAwareLayout storage layout_) {
        assembly {
            layout_.slot := slot_
        }
    }
}
