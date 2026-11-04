// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IPoolManager} from "@crane/contracts/protocols/dexes/uniswap/v4/interfaces/IPoolManager.sol";
import {PoolKey} from "@crane/contracts/protocols/dexes/uniswap/v4/types/PoolKey.sol";
import {StateLibrary} from "@crane/contracts/protocols/dexes/uniswap/v4/libraries/StateLibrary.sol";
import {IUniswapV4SinglePositionAware} from "@crane/contracts/interfaces/IUniswapV4SinglePositionAware.sol";
import {UniswapV4ProtocolAwareRepo} from "./UniswapV4ProtocolAwareRepo.sol";
import {UniswapV4SinglePositionAwareRepo} from "./UniswapV4SinglePositionAwareRepo.sol";

contract UniswapV4SinglePositionAwareTarget is IUniswapV4SinglePositionAware {
    function poolKey() external view returns (PoolKey memory) {
        return UniswapV4SinglePositionAwareRepo._poolKey();
    }

    function tickLower() external view returns (int24) {
        return UniswapV4SinglePositionAwareRepo._tickLower();
    }

    function tickUpper() external view returns (int24) {
        return UniswapV4SinglePositionAwareRepo._tickUpper();
    }

    function positionSalt() external view returns (bytes32) {
        return UniswapV4SinglePositionAwareRepo._salt();
    }

    /// @dev Liquidity of this diamond's stored position. Not a token amount and not pool liquidity.
    function positionLiquidity() external view returns (uint128 liquidity) {
        UniswapV4SinglePositionAwareRepo.Storage storage position_ = UniswapV4SinglePositionAwareRepo._layoutStruct();
        IPoolManager manager_ = UniswapV4ProtocolAwareRepo._poolManager();
        (liquidity,,) = StateLibrary.getPositionInfo(
            manager_, position_.poolKey.toId(), address(this), position_.tickLower, position_.tickUpper, position_.salt
        );
    }
}
