// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {ICamelotFactory} from "contracts/crane/interfaces/protocols/dexes/camelot/v2/ICamelotFactory.sol";
import {ICamelotPair} from "contracts/crane/interfaces/protocols/dexes/camelot/v2/ICamelotPair.sol";
import {ICamelotV2Router} from "contracts/crane/interfaces/protocols/dexes/camelot/v2/ICamelotV2Router.sol";
import {BetterIERC20 as IERC20} from "contracts/crane/interfaces/BetterIERC20.sol";

struct CamelotPairAwareLayout {
    ICamelotFactory camelotFactory;
    ICamelotV2Router camV2Router;
    ICamelotPair camV2Pair;
    IERC20 token0;
    IERC20 token1;
    mapping(IERC20 token => IERC20 opToken) opTokenOfToken;
}

library CamelotPairAwareRepo {
    // tag::_layout[]
    /**
     * @dev "Binds" this struct to a storage slot.
     * @param slot_ The first slot to use in the range of slots used by the struct.
     * @return layout_ A struct from a Layout library bound to the provided slot.
     */
    function layout(bytes32 slot_) internal pure returns (CamelotPairAwareLayout storage layout_) {
        assembly {
            layout_.slot := slot_
        }
    }
    // end::_layout[]
}
