// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {PoolKey} from "@crane/contracts/protocols/dexes/uniswap/v4/types/PoolKey.sol";

// tag::UniswapV4SinglePositionAwareRepo[]
/// @title UniswapV4SinglePositionAwareRepo
/// @notice Instance storage for one PoolKey, its ticks, and its salt.
/// @dev Slot is `protocols.dexes.uniswap.v4.singlePosition.aware`.
library UniswapV4SinglePositionAwareRepo {
    // tag::STORAGE_SLOT[]
    bytes32 internal constant STORAGE_SLOT =
        bytes32(uint256(keccak256(abi.encode("protocols.dexes.uniswap.v4.singlePosition.aware"))) - 1);
    // end::STORAGE_SLOT[]

    // tag::Storage[]
    struct Storage {
        PoolKey poolKey;
        int24 tickLower;
        int24 tickUpper;
        bytes32 salt;
    }
    // end::Storage[]

    function _layoutStruct(bytes32 slot_) internal pure returns (Storage storage layoutStruct) {
        assembly {
            layoutStruct.slot := slot_
        }
    }

    function _layoutStruct() internal pure returns (Storage storage layoutStruct) {
        return _layoutStruct(STORAGE_SLOT);
    }

    function _initialize(
        Storage storage layoutStruct,
        PoolKey memory poolKey_,
        int24 tickLower_,
        int24 tickUpper_,
        bytes32 salt_
    ) internal {
        layoutStruct.poolKey = poolKey_;
        layoutStruct.tickLower = tickLower_;
        layoutStruct.tickUpper = tickUpper_;
        layoutStruct.salt = salt_;
    }

    function _initialize(PoolKey memory poolKey_, int24 tickLower_, int24 tickUpper_, bytes32 salt_) internal {
        _initialize(_layoutStruct(), poolKey_, tickLower_, tickUpper_, salt_);
    }

    function _poolKey(Storage storage layoutStruct) internal view returns (PoolKey memory) {
        return layoutStruct.poolKey;
    }

    function _poolKey() internal view returns (PoolKey memory) {
        return _poolKey(_layoutStruct());
    }

    function _tickLower(Storage storage layoutStruct) internal view returns (int24) {
        return layoutStruct.tickLower;
    }

    function _tickLower() internal view returns (int24) {
        return _tickLower(_layoutStruct());
    }

    function _tickUpper(Storage storage layoutStruct) internal view returns (int24) {
        return layoutStruct.tickUpper;
    }

    function _tickUpper() internal view returns (int24) {
        return _tickUpper(_layoutStruct());
    }

    function _salt(Storage storage layoutStruct) internal view returns (bytes32) {
        return layoutStruct.salt;
    }

    function _salt() internal view returns (bytes32) {
        return _salt(_layoutStruct());
    }
}
// end::UniswapV4SinglePositionAwareRepo[]
