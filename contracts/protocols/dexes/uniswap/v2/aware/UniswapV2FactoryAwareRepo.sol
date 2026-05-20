// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IUniswapV2Factory} from "@crane/contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Factory.sol";

library UniswapV2FactoryAwareRepo {
    bytes32 internal constant STORAGE_SLOT = keccak256("crane.uniswap.v2.factory.aware");

    struct Storage {
        IUniswapV2Factory factory;
    }

    function _layoutStruct(bytes32 slot) internal pure returns (Storage storage layoutStruct) {
        assembly {
            layoutStruct.slot := slot
        }
    }

    function _layoutStruct() internal pure returns (Storage storage layoutStruct) {
        return _layoutStruct(STORAGE_SLOT);
    }

    function _initialize(Storage storage layoutStruct, IUniswapV2Factory factory_) internal {
        layoutStruct.factory = factory_;
    }

    function _initialize(IUniswapV2Factory factory_) internal {
        _initialize(_layoutStruct(), factory_);
    }

    function _uniswapV2Factory(Storage storage layoutStruct) internal view returns (IUniswapV2Factory factory_) {
        return layoutStruct.factory;
    }

    function _uniswapV2Factory() internal view returns (IUniswapV2Factory factory_) {
        return _uniswapV2Factory(_layoutStruct());
    }
}
