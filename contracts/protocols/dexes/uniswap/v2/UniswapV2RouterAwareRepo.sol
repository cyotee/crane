// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IUniswapV2Router} from "contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Router.sol";

library UniswapV2RouterAwareRepo {
    bytes32 internal constant STORAGE_SLOT = keccak256("crane.uniswap.v2.router.aware");

    struct Storage {
        IUniswapV2Router router;
    }

    function _layout(bytes32 slot) internal pure returns (Storage storage layout) {
        assembly {
            layout.slot := slot
        }
    }

    function _layout() internal pure returns (Storage storage layout) {
        return _layout(STORAGE_SLOT);
    }

    function _initialize(Storage storage layout, IUniswapV2Router router_) internal {
        layout.router = router_;
    }

    function _initialize(IUniswapV2Router router_) internal {
        _initialize(_layout(), router_);
    }

    function _uniswapV2Router(Storage storage layout) internal view returns (IUniswapV2Router router_) {
        return layout.router;
    }

    function _uniswapV2Router() internal view returns (IUniswapV2Router router_) {
        return _uniswapV2Router(_layout());
    }
}