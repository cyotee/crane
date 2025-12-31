// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {IUniswapV2Factory} from "contracts/crane/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Factory.sol";
import {IUniswapV2Router} from "contracts/crane/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Router.sol";

struct UniswapV2AwareLayout {
    IUniswapV2Factory factory;
    IUniswapV2Router router;
}

library UniswapV2AwareRepo {

    bytes32 internal constant STORAGE_RANGE = keccak256(abi.encode("protocols.dexes.uniswap.v2"));

    // tag::_layout[]
    /**
     * @dev "Binds" this struct to a storage slot.
     * @param slot_ The first slot to use in the range of slots used by the struct.
     * @return layout_ A struct from a Layout library bound to the provided slot.
     */
    function _layout(bytes32 slot_) internal pure returns (UniswapV2AwareLayout storage layout_) {
        assembly {
            layout_.slot := slot_
        }
    }

    function _layout() internal pure returns (UniswapV2AwareLayout storage) {
        return _layout(STORAGE_RANGE);
    }

    function _initialize(
        UniswapV2AwareLayout storage layout,
        IUniswapV2Factory factory,
        IUniswapV2Router router
    ) internal {
        _setFactory(layout, factory);
        _setRouter(layout, router);
    }

    function _initialize(IUniswapV2Factory factory, IUniswapV2Router router) internal {
        _initialize(_layout(), factory, router);
    }

    function _setFactory(UniswapV2AwareLayout storage layout, IUniswapV2Factory factory) internal {
        layout.factory = factory;
    }

    function _setRouter(UniswapV2AwareLayout storage layout, IUniswapV2Router router) internal {
        layout.router = router;
    }

    function _factory(UniswapV2AwareLayout storage layout) internal view returns (IUniswapV2Factory) {
        return layout.factory;
    }

    function _factory() internal view returns (IUniswapV2Factory) {
        return _factory(_layout());
    }

    function _router(UniswapV2AwareLayout storage layout) internal view returns (IUniswapV2Router) {
        return layout.router;
    }

    function _router() internal view returns (IUniswapV2Router) {
        return _router(_layout());
    }
}
