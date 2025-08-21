// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import { IUniswapV2Factory } from "contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Factory.sol";
import { IUniswapV2Router } from    "contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Router.sol";

struct UniswapV2AwareLayout {
    IUniswapV2Factory factory;
    IUniswapV2Router router;
}

library UniswapV2AwareRepo {
    
    // tag::_layout[]
    /**
     * @dev "Binds" this struct to a storage slot.
     * @param slot_ The first slot to use in the range of slots used by the struct.
     * @return layout_ A struct from a Layout library bound to the provided slot.
     */
    function _layout(
        bytes32 slot_
    ) internal pure returns (UniswapV2AwareLayout storage layout_) {
        assembly {
            layout_.slot := slot_
        }
    }
    // end::_layout[]
    
}
