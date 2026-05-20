// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IRateProvider} from "@crane/contracts/interfaces/protocols/dexes/balancer/v3/IRateProvider.sol";
import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IBasePoolFactory} from "@crane/contracts/interfaces/protocols/dexes/balancer/v3/IBasePoolFactory.sol";
import {TokenType, TokenConfig} from "@crane/contracts/interfaces/protocols/dexes/balancer/v3/VaultTypes.sol";
import {AddressSet, AddressSetRepo} from "@crane/contracts/utils/collections/sets/AddressSetRepo.sol";

library BalancerV3BasePoolFactoryRepo {
    using AddressSetRepo for AddressSet;

    /// @notice The factory deployer gave a duration that would overflow the Unix timestamp.
    error PoolPauseWindowDurationOverflow();

    bytes32 internal constant STORAGE_SLOT = keccak256("protocols.dexes.balancer.v3.base.pool.factory.common");

    // The pause window end time is stored in 32 bits.
    uint32 private constant _MAX_TIMESTAMP = type(uint32).max;

    struct Storage {
        bool isDisabled;
        uint32 pauseWindowDuration;
        uint32 pauseWindowEndTime;
        address poolManager;
        AddressSet pools;
        // mapping(address pool => TokenConfig[] tokenConfigs) tokenConfigsOfPool;
        mapping(address pool => AddressSet tokens) tokensOfPool;
        mapping(address pool => mapping(address token => TokenType tokenType)) typeOfTokenOfPool;
        mapping(address pool => mapping(address token => address rateProvider)) rateProviderOfTokenOfPool;
        mapping(address pool => mapping(address token => bool paysYieldFees)) paysYieldFeesOfPool;
        mapping(address pool => address hooksContract) hooksContractOfPool;
    }

    // tag::_layoutStruct[]
    /**
     * @dev "Binds" this struct to a storage slot.
     * @param slot_ The first slot to use in the range of slots used by the struct.
     * @return layoutStruct_ A struct from a Layout library bound to the provided slot.
     */
    function _layoutStruct(bytes32 slot_) internal pure returns (Storage storage layoutStruct_) {
        assembly {
            layoutStruct_.slot := slot_
        }
    }
    // end::_layoutStruct[]

    function _layoutStruct() internal pure returns (Storage storage) {
        return _layoutStruct(STORAGE_SLOT);
    }

    function _initialize(Storage storage layoutStruct, uint32 pauseWindowDuration, address poolManager) internal {
        uint32 pauseWindowEndTime = uint32(block.timestamp) + pauseWindowDuration;
        if (pauseWindowEndTime > _MAX_TIMESTAMP) {
            revert PoolPauseWindowDurationOverflow();
        }
        layoutStruct.pauseWindowEndTime = pauseWindowEndTime;
        layoutStruct.pauseWindowDuration = pauseWindowDuration;
        layoutStruct.poolManager = poolManager;
    }

    function _initialize(uint32 pauseWindowDuration, address poolFeeManager) internal {
        _initialize(_layoutStruct(), pauseWindowDuration, poolFeeManager);
    }

    function _isDisabled(Storage storage layoutStruct) internal view returns (bool) {
        return layoutStruct.isDisabled;
    }

    function _isDisabled() internal view returns (bool) {
        return _isDisabled(_layoutStruct());
    }

    function _disable(Storage storage layoutStruct) internal {
        layoutStruct.isDisabled = true;
    }

    function _disable() internal {
        _disable(_layoutStruct());
    }

    function _ensureEnabled() internal view {
        if (_isDisabled()) {
            revert IBasePoolFactory.Disabled();
        }
    }

    function _pauseWindowDuration(Storage storage layoutStruct) internal view returns (uint32) {
        return layoutStruct.pauseWindowDuration;
    }

    function _pauseWindowDuration() internal view returns (uint32) {
        return _pauseWindowDuration(_layoutStruct());
    }

    function _pauseWindowEndTime(Storage storage layoutStruct) internal view returns (uint32) {
        return layoutStruct.pauseWindowEndTime;
    }

    function _pauseWindowEndTime() internal view returns (uint32) {
        return _pauseWindowEndTime(_layoutStruct());
    }

    function _getPoolManager(Storage storage layoutStruct) internal view returns (address) {
        return layoutStruct.poolManager;
    }

    function _getPoolManager() internal view returns (address) {
        return _getPoolManager(_layoutStruct());
    }

    function _addPool(Storage storage layoutStruct, address pool) internal {
        layoutStruct.pools._add(pool);
    }

    function _addPool(address pool) internal {
        _addPool(_layoutStruct(), pool);
    }

    function _isPoolFromFactory(Storage storage layoutStruct, address pool) internal view returns (bool) {
        return layoutStruct.pools._contains(pool);
    }

    function _isPoolFromFactory(address pool) internal view returns (bool) {
        return _isPoolFromFactory(_layoutStruct(), pool);
    }

    function _getPoolCount(Storage storage layoutStruct) internal view returns (uint256) {
        return layoutStruct.pools._length();
    }

    function _getPoolCount() internal view returns (uint256) {
        return _getPoolCount(_layoutStruct());
    }

    function _getPoolsInRange(Storage storage layoutStruct, uint256 start, uint256 count)
        internal
        view
        returns (address[] memory)
    {
        return layoutStruct.pools._range(start, count);
    }

    function _getPoolsInRange(uint256 start, uint256 count) internal view returns (address[] memory) {
        return _getPoolsInRange(_layoutStruct(), start, count);
    }

    function _getPools(Storage storage layoutStruct) internal view returns (address[] memory) {
        return layoutStruct.pools._values();
    }

    function _getPools() internal view returns (address[] memory) {
        return _getPools(_layoutStruct());
    }

    function _setTokenConfigs(address pool_, TokenConfig[] memory tokenConfig_) internal {
        _setTokenConfigs(_layoutStruct(), pool_, tokenConfig_);
    }

    function _getTokenConfigs(Storage storage layoutStruct, address pool_)
        internal
        view
        returns (TokenConfig[] memory tokenConfigs)
    {
        uint256 length = layoutStruct.tokensOfPool[pool_]._length();
        tokenConfigs = new TokenConfig[](length);
        for (uint256 cursor = 0; cursor < length; cursor++) {
            address token_ = layoutStruct.tokensOfPool[pool_]._index(cursor);
            tokenConfigs[cursor] = TokenConfig({
                token: IERC20(token_),
                rateProvider: IRateProvider(layoutStruct.rateProviderOfTokenOfPool[pool_][token_]),
                tokenType: layoutStruct.typeOfTokenOfPool[pool_][token_],
                paysYieldFees: layoutStruct.paysYieldFeesOfPool[pool_][token_]
            });
        }
    }

    function _getTokenConfigs(address pool_) internal view returns (TokenConfig[] memory tokenConfigs) {
        return _getTokenConfigs(_layoutStruct(), pool_);
    }

    function _setTokenConfigs(Storage storage layoutStruct, address pool_, TokenConfig[] memory tokenConfig_) internal {
        for (uint256 cursor = 0; cursor < tokenConfig_.length; cursor++) {
            layoutStruct.tokensOfPool[pool_]._add(address(tokenConfig_[cursor].token));
            layoutStruct.rateProviderOfTokenOfPool[pool_][address(tokenConfig_[cursor].token)] =
                address(tokenConfig_[cursor].rateProvider);
            layoutStruct.typeOfTokenOfPool[pool_][address(tokenConfig_[cursor].token)] = tokenConfig_[cursor].tokenType;
            layoutStruct.paysYieldFeesOfPool[pool_][address(tokenConfig_[cursor].token)] = tokenConfig_[cursor].paysYieldFees;
        }
    }

    function _getNewPoolPauseWindowEndTime(Storage storage layoutStruct) internal view returns (uint32) {
        // We know _poolsPauseWindowEndTime <= _MAX_TIMESTAMP (checked above).
        // Do not truncate timestamp; it should still return 0 after _MAX_TIMESTAMP.
        uint32 pauseWindowEndTime = _pauseWindowEndTime(layoutStruct);
        return (block.timestamp < pauseWindowEndTime) ? pauseWindowEndTime : 0;
    }

    function _setHooksContract(Storage storage layoutStruct, address pool_, address hooksContract_) internal {
        layoutStruct.hooksContractOfPool[pool_] = hooksContract_;
    }

    function _setHooksContract(address pool_, address hooksContract_) internal {
        _setHooksContract(_layoutStruct(), pool_, hooksContract_);
    }

    function _getNewPoolPauseWindowEndTime() internal view returns (uint32) {
        return _getNewPoolPauseWindowEndTime(_layoutStruct());
    }

    function _getHooksContract(Storage storage layoutStruct, address pool_) internal view returns (address) {
        return layoutStruct.hooksContractOfPool[pool_];
    }

    function _getHooksContract(address pool_) internal view returns (address) {
        return _getHooksContract(_layoutStruct(), pool_);
    }
}
