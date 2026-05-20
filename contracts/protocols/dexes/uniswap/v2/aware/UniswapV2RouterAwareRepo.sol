// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IUniswapV2Router} from "@crane/contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Router.sol";

library UniswapV2RouterAwareRepo {
    bytes32 internal constant STORAGE_SLOT = keccak256("crane.uniswap.v2.router.aware");

    struct Storage {
        IUniswapV2Router router;
    }

    function _layoutStruct(bytes32 slot) internal pure returns (Storage storage layoutStruct) {
        assembly {
            layoutStruct.slot := slot
        }
    }

    function _layoutStruct() internal pure returns (Storage storage layoutStruct) {
        return _layoutStruct(STORAGE_SLOT);
    }

    function _initialize(Storage storage layoutStruct, IUniswapV2Router router_) internal {
        layoutStruct.router = router_;
    }

    function _initialize(IUniswapV2Router router_) internal {
        _initialize(_layoutStruct(), router_);
    }

    function _uniswapV2Router(Storage storage layoutStruct) internal view returns (IUniswapV2Router router_) {
        return layoutStruct.router;
    }

    function _uniswapV2Router() internal view returns (IUniswapV2Router router_) {
        return _uniswapV2Router(_layoutStruct());
    }
}
