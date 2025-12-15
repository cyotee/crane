// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {IWETH} from "@crane/contracts/interfaces/protocols/tokens/wrappers/weth/v9/IWETH.sol";
import {IWETHAware} from "@crane/contracts/interfaces/IWETHAware.sol";

struct WETHAwareLayout {
    IWETH weth;
}

library WETHAwareRepo {
    bytes32 internal constant STORAGE_RANGE = keccak256(abi.encode("protocols.tokens.wrappers.weth.v9"));

    function _layout(bytes32 storageRange) internal pure returns (WETHAwareLayout storage layout_) {
        assembly {
            layout_.slot := storageRange
        }
    }

    function _layout() internal pure returns (WETHAwareLayout storage) {
        return _layout(STORAGE_RANGE);
    }

    function _initialize(WETHAwareLayout storage layout, IWETH weth) internal {
        _setWeth(layout, weth);
    }

    function _initialize(IWETH weth) internal {
        _initialize(_layout(), weth);
    }

    function _setWeth(WETHAwareLayout storage layout, IWETH weth) internal {
        layout.weth = weth;
    }

    function _weth(WETHAwareLayout storage layout) internal view returns (IWETH) {
        return layout.weth;
    }

    function _weth() internal view returns (IWETH) {
        return _weth(_layout());
    }
}
