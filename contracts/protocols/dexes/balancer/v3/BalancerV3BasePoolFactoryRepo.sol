// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IRateProvider} from "@crane/contracts/interfaces/protocols/dexes/balancer/v3/IRateProvider.sol";
import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IBasePoolFactory} from "@crane/contracts/interfaces/protocols/dexes/balancer/v3/IBasePoolFactory.sol";
import {
    TokenType,
    TokenConfig
} from "@crane/contracts/interfaces/protocols/dexes/balancer/v3/VaultTypes.sol";
import {AddressSet, AddressSetRepo} from "@crane/contracts/utils/collections/sets/AddressSetRepo.sol";

library BalancerV3BasePoolFactoryRepo {

    using AddressSetRepo for AddressSet;

    bytes32 internal constant STORAGE_SLOT =
        keccak256("protocols.dexes.balancer.v3.base.pool.factory.common");

    struct Storage {
        bool isDisabled;
        uint32 pauseWindowDuration;
        uint32 pauseWindowEndTime;
        AddressSet pools;
        // mapping(address pool => TokenConfig[] tokenConfigs) tokenConfigsOfPool;
        mapping(address pool => AddressSet tokens) tokensOfPool;
        mapping(address pool => mapping(address token => TokenType tokenType)) typeOfTokenOfPool;
        mapping(address pool => mapping(address token => address rateProvider)) rateProviderOfTokenOfPool;
        mapping(address pool => mapping(address token => bool paysYieldFees)) paysYieldFeesOfPool;
        mapping(address pool => address hooksContract) hooksContractOfPool;
    }

    // tag::_layout[]
    /**
     * @dev "Binds" this struct to a storage slot.
     * @param slot_ The first slot to use in the range of slots used by the struct.
     * @return layout_ A struct from a Layout library bound to the provided slot.
     */
    function _layout(bytes32 slot_) internal pure returns (Storage storage layout_) {
        assembly {
            layout_.slot := slot_
        }
    }
    // end::_layout[]

    function _layout() internal pure returns (Storage storage) {
        return _layout(STORAGE_SLOT);
    }

    function _addPool(Storage storage layout, address pool) internal {
        layout.pools._add(pool);
    }

    function _addPool(address pool) internal {
        _addPool(_layout(), pool);
    }

    function _isPoolFromFactory(Storage storage layout, address pool)
        internal
        view
        returns (bool)
    {
        return layout.pools._contains(pool);
    }

    function _isPoolFromFactory(address pool) internal view returns (bool) {
        return _isPoolFromFactory(_layout(), pool);
    }

    function _getPoolCount(Storage storage layout)
        internal
        view
        returns (uint256)
    {
        return layout.pools._length();
    }

    function _getPoolCount() internal view returns (uint256) {
        return _getPoolCount(_layout());
    }

    function _getPoolsInRange(
        Storage storage layout,
        uint256 start,
        uint256 count
    ) internal view returns (address[] memory) {
        return layout.pools._range(start, count);
    }

    function _getPoolsInRange(uint256 start, uint256 count) internal view returns (address[] memory) {
        return _getPoolsInRange(_layout(), start, count);
    }

    function _getPools(Storage storage layout) internal view returns (address[] memory) {
        return layout.pools._values();
    }

    function _getPools() internal view returns (address[] memory) {
        return _getPools(_layout());
    }

    function _ensureEnabled() internal view {
        if (_isDisabled()) {
            revert IBasePoolFactory.Disabled();
        }
    }

    function _isDisabled(Storage storage layout) internal view returns (bool) {
        return layout.isDisabled;
    }

    function _isDisabled() internal view returns (bool) {
        return _isDisabled(_layout());
    }

    function _disable(Storage storage layout) internal {
        layout.isDisabled = true;
    }

    function _disable() internal {
        _disable(_layout());
    }

    function _pauseWindowDuration(Storage storage layout) internal view returns (uint32) {
        return layout.pauseWindowDuration;
    }

    function _pauseWindowDuration() internal view returns (uint32) {
        return _pauseWindowDuration(_layout());
    }

    function _pauseWindowEndTime(Storage storage layout) internal view returns (uint32) {
        return layout.pauseWindowEndTime;
    }

    function _pauseWindowEndTime() internal view returns (uint32) {
        return _pauseWindowEndTime(_layout());
    }

    function _getNewPoolPauseWindowEndTime(Storage storage layout) internal view returns (uint32) {
        // We know _poolsPauseWindowEndTime <= _MAX_TIMESTAMP (checked above).
        // Do not truncate timestamp; it should still return 0 after _MAX_TIMESTAMP.
        uint32 pauseWindowEndTime = _pauseWindowEndTime(layout);
        return (block.timestamp < pauseWindowEndTime) ? pauseWindowEndTime : 0;
    }

    function _getNewPoolPauseWindowEndTime() internal view returns (uint32) {
        return _getNewPoolPauseWindowEndTime(_layout());
    }

    function _getTokenConfigs(Storage storage layout, address pool_) internal view returns (TokenConfig[] memory tokenConfigs) {
        uint256 length = layout.tokensOfPool[pool_]._length();
        tokenConfigs = new TokenConfig[](length);
        for (uint256 cursor = 0; cursor < length; cursor++) {
            address token_ = layout.tokensOfPool[pool_]._index(cursor);
            tokenConfigs[cursor] = TokenConfig({
                token: IERC20(token_),
                rateProvider: IRateProvider(layout.rateProviderOfTokenOfPool[pool_][token_]),
                tokenType: layout.typeOfTokenOfPool[pool_][token_],
                paysYieldFees: layout.paysYieldFeesOfPool[pool_][token_]
            });
        }
    }

    function _getTokenConfigs(address pool_) internal view returns (TokenConfig[] memory tokenConfigs) {
        return _getTokenConfigs(_layout(), pool_);
    }

    function _setTokenConfigs(Storage storage layout, address pool_, TokenConfig[] memory tokenConfig_) internal {
        for (uint256 cursor = 0; cursor < tokenConfig_.length; cursor++) {
            layout.tokensOfPool[pool_]._add(address(tokenConfig_[cursor].token));
            layout.rateProviderOfTokenOfPool[pool_][address(tokenConfig_[cursor].token)] =
                address(tokenConfig_[cursor].rateProvider);
            layout.typeOfTokenOfPool[pool_][address(tokenConfig_[cursor].token)] =
            tokenConfig_[cursor].tokenType;
            layout.paysYieldFeesOfPool[pool_][address(tokenConfig_[cursor].token)] =
            tokenConfig_[cursor].paysYieldFees;
        }
    }

    function _setTokenConfigs(address pool_, TokenConfig[] memory tokenConfig_) internal {
        _setTokenConfigs(_layout(), pool_, tokenConfig_);
    }

}