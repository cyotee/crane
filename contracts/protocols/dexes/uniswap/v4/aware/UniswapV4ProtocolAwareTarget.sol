// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IPoolManager} from "@crane/contracts/protocols/dexes/uniswap/v4/interfaces/IPoolManager.sol";
import {IUniswapV4ProtocolAware} from "@crane/contracts/interfaces/IUniswapV4ProtocolAware.sol";
import {UniswapV4ProtocolAwareRepo} from "./UniswapV4ProtocolAwareRepo.sol";

contract UniswapV4ProtocolAwareTarget is IUniswapV4ProtocolAware {
    function poolManager() external view returns (IPoolManager) {
        return UniswapV4ProtocolAwareRepo._poolManager();
    }

    function positionDescriptor() external view returns (address) {
        return UniswapV4ProtocolAwareRepo._positionDescriptor();
    }

    function positionManager() external view returns (address) {
        return UniswapV4ProtocolAwareRepo._positionManager();
    }

    function quoter() external view returns (address) {
        return UniswapV4ProtocolAwareRepo._quoter();
    }

    function stateView() external view returns (address) {
        return UniswapV4ProtocolAwareRepo._stateView();
    }

    function reservesLens() external view returns (address) {
        return UniswapV4ProtocolAwareRepo._reservesLens();
    }

    function universalRouter() external view returns (address) {
        return UniswapV4ProtocolAwareRepo._universalRouter();
    }
}
