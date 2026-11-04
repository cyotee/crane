// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IPoolManager} from "@crane/contracts/protocols/dexes/uniswap/v4/interfaces/IPoolManager.sol";

// tag::UniswapV4ProtocolAwareRepo[]
/// @title UniswapV4ProtocolAwareRepo
/// @notice Storage for the Uniswap V4 architecture addresses.
/// @dev Slot is `protocols.dexes.uniswap.v4.protocol.aware`. The seven addresses are one pair.
library UniswapV4ProtocolAwareRepo {
    // tag::STORAGE_SLOT[]
    bytes32 internal constant STORAGE_SLOT =
        bytes32(uint256(keccak256(abi.encode("protocols.dexes.uniswap.v4.protocol.aware"))) - 1);
    // end::STORAGE_SLOT[]

    // tag::Storage[]
    struct Storage {
        IPoolManager poolManager;
        address positionDescriptor;
        address positionManager;
        address quoter;
        address stateView;
        address reservesLens;
        address universalRouter;
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
        IPoolManager poolManager_,
        address positionDescriptor_,
        address positionManager_,
        address quoter_,
        address stateView_,
        address reservesLens_,
        address universalRouter_
    ) internal {
        layoutStruct.poolManager = poolManager_;
        layoutStruct.positionDescriptor = positionDescriptor_;
        layoutStruct.positionManager = positionManager_;
        layoutStruct.quoter = quoter_;
        layoutStruct.stateView = stateView_;
        layoutStruct.reservesLens = reservesLens_;
        layoutStruct.universalRouter = universalRouter_;
    }

    function _initialize(
        IPoolManager poolManager_,
        address positionDescriptor_,
        address positionManager_,
        address quoter_,
        address stateView_,
        address reservesLens_,
        address universalRouter_
    ) internal {
        _initialize(
            _layoutStruct(),
            poolManager_,
            positionDescriptor_,
            positionManager_,
            quoter_,
            stateView_,
            reservesLens_,
            universalRouter_
        );
    }

    function _poolManager(Storage storage layoutStruct) internal view returns (IPoolManager) {
        return layoutStruct.poolManager;
    }

    function _poolManager() internal view returns (IPoolManager) {
        return _poolManager(_layoutStruct());
    }

    function _positionDescriptor(Storage storage layoutStruct) internal view returns (address) {
        return layoutStruct.positionDescriptor;
    }

    function _positionDescriptor() internal view returns (address) {
        return _positionDescriptor(_layoutStruct());
    }

    function _positionManager(Storage storage layoutStruct) internal view returns (address) {
        return layoutStruct.positionManager;
    }

    function _positionManager() internal view returns (address) {
        return _positionManager(_layoutStruct());
    }

    function _quoter(Storage storage layoutStruct) internal view returns (address) {
        return layoutStruct.quoter;
    }

    function _quoter() internal view returns (address) {
        return _quoter(_layoutStruct());
    }

    function _stateView(Storage storage layoutStruct) internal view returns (address) {
        return layoutStruct.stateView;
    }

    function _stateView() internal view returns (address) {
        return _stateView(_layoutStruct());
    }

    function _reservesLens(Storage storage layoutStruct) internal view returns (address) {
        return layoutStruct.reservesLens;
    }

    function _reservesLens() internal view returns (address) {
        return _reservesLens(_layoutStruct());
    }

    function _universalRouter(Storage storage layoutStruct) internal view returns (address) {
        return layoutStruct.universalRouter;
    }

    function _universalRouter() internal view returns (address) {
        return _universalRouter(_layoutStruct());
    }
}
// end::UniswapV4ProtocolAwareRepo[]
