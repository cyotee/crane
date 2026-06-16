// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IRateProvider} from "@crane/contracts/interfaces/protocols/dexes/balancer/v3/IRateProvider.sol";
import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IBasePoolFactory} from "@crane/contracts/interfaces/protocols/dexes/balancer/v3/IBasePoolFactory.sol";
import {TokenType, TokenConfig} from "@crane/contracts/interfaces/protocols/dexes/balancer/v3/VaultTypes.sol";
import {AddressSet, AddressSetRepo} from "@crane/contracts/utils/collections/sets/AddressSetRepo.sol";

// tag::BalancerV3BasePoolFactoryRepo[]
/**
 * @title BalancerV3BasePoolFactoryRepo - Storage library for Balancer V3 base pool factory common state (pause windows, manager, pools tracking, per-pool token configs/hooks).
 * @author cyotee doge <not_cyotee@proton.me>
 * @dev Storage library (Repo) for common factory config and deployed pool tracking used across Balancer V3 pool DFPkgs/factories.
 * @dev Pools tracked via AddressSetRepo. Token configs (type, rateProvider, paysYieldFees) and hooks per pool stored in mappings.
 * @dev Provides dual (parameterized + default) overloads for _initialize and all storage accessors/mutators.
 * @dev Follows the gold standard from BalancerV3PoolRepo, BalancerV3WeightedPoolRepo, BalancerV3StablePoolRepo, BalancerV3VaultAwareRepo, CamelotV2FactoryAwareRepo, OperableRepo, FacetRegistryRepo
 *      (rich NatSpec, exact // tag:: / end:: include tags, @dev "The Storage struct to operate on.", ERC1967-compliant STORAGE_SLOT, layoutStruct param).
 * @dev Used by BalancerV3BasePoolFactory and *DFPkg for Diamond storage binding.
 */
library BalancerV3BasePoolFactoryRepo {
    using AddressSetRepo for AddressSet;

    // tag::PoolPauseWindowDurationOverflow[]
    /// @notice The factory deployer gave a duration that would overflow the Unix timestamp.
    error PoolPauseWindowDurationOverflow();
    // end::PoolPauseWindowDurationOverflow[]

    // tag::STORAGE_SLOT[]
    /**
     * @dev ERC1967-compliant storage slot.
     *      Computed as bytes32(uint256(keccak256(abi.encode("protocols.dexes.balancer.v3.base.pool.factory.common"))) - 1).
     *      This follows the canonical pattern used by BalancerV3*PoolRepo, BalancerV3VaultAwareRepo, OperableRepo, FacetRegistryRepo,
     *      Camelot*AwareRepo and other gold-standard Repos for collision-resistant deterministic storage binding.
     */
    bytes32 internal constant STORAGE_SLOT = bytes32(uint256(keccak256(abi.encode("protocols.dexes.balancer.v3.base.pool.factory.common"))) - 1);
    // end::STORAGE_SLOT[]

    // The pause window end time is stored in 32 bits.
    uint32 private constant _MAX_TIMESTAMP = type(uint32).max;

    // tag::Storage[]
    /**
     * @dev Standardized storage layout for balancer v3 base pool factory common.
     *      isDisabled: once true, no new pools.
     *      pauseWindowDuration / EndTime: for IFactoryWidePauseWindow.
     *      poolManager: the governance/manager address.
     *      pools: AddressSet of deployed pool addresses (via AddressSetRepo).
     *      tokensOfPool / typeOf... / rateProvider... / paysYield... : per-pool token config details (note TokenConfig computed on fly from these).
     *      hooksContractOfPool: per-pool hooks.
     * The Storage struct to operate on.
     */
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
    // end::Storage[]

    // tag::_layoutStruct(bytes32)[]
    /**
     * @dev Argumented version of _layoutStruct to allow for custom storage slot usage.
     * @param slot_ The storage slot to bind.
     * @return layoutStruct The Storage struct bound to the provided slot.
     */
    function _layoutStruct(bytes32 slot_) internal pure returns (Storage storage layoutStruct) {
        assembly {
            layoutStruct.slot := slot_
        }
    }
    // end::_layoutStruct(bytes32)[]

    // tag::_layoutStruct()[]
    /**
     * @dev Default _layoutStruct binding to the canonical ERC1967 STORAGE_SLOT.
     * @return layoutStruct The Storage struct bound to STORAGE_SLOT.
     */
    function _layoutStruct() internal pure returns (Storage storage layoutStruct) {
        return _layoutStruct(STORAGE_SLOT);
    }
    // end::_layoutStruct()[]

    // tag::_initialize(Storage-uint32-address)[]
    /**
     * @dev Argumented version of _initialize to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @param pauseWindowDuration The duration for the pause window (for new pools).
     * @param poolManager The pool manager / fee manager address.
     */
    function _initialize(Storage storage layoutStruct, uint32 pauseWindowDuration, address poolManager) internal {
        uint32 pauseWindowEndTime = uint32(block.timestamp) + pauseWindowDuration;
        if (pauseWindowEndTime > _MAX_TIMESTAMP) {
            revert PoolPauseWindowDurationOverflow();
        }
        layoutStruct.pauseWindowEndTime = pauseWindowEndTime;
        layoutStruct.pauseWindowDuration = pauseWindowDuration;
        layoutStruct.poolManager = poolManager;
    }
    // end::_initialize(Storage-uint32-address)[]

    // tag::_initialize(uint32-address)[]
    /**
     * @dev Default version of _initialize binding to the standard STORAGE_SLOT.
     * @param pauseWindowDuration The duration for the pause window (for new pools).
     * @param poolFeeManager The pool manager / fee manager address.
     */
    function _initialize(uint32 pauseWindowDuration, address poolFeeManager) internal {
        _initialize(_layoutStruct(), pauseWindowDuration, poolFeeManager);
    }
    // end::_initialize(uint32-address)[]

    // tag::_isDisabled(Storage)[]
    /**
     * @dev Argumented version of _isDisabled to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @return success True if the factory has been disabled.
     */
    function _isDisabled(Storage storage layoutStruct) internal view returns (bool) {
        return layoutStruct.isDisabled;
    }
    // end::_isDisabled(Storage)[]

    // tag::_isDisabled()[]
    /**
     * @dev Default version of _isDisabled binding to the standard STORAGE_SLOT.
     * @return success True if the factory has been disabled.
     */
    function _isDisabled() internal view returns (bool) {
        return _isDisabled(_layoutStruct());
    }
    // end::_isDisabled()[]

    // tag::_disable(Storage)[]
    /**
     * @dev Argumented version of _disable to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     */
    function _disable(Storage storage layoutStruct) internal {
        layoutStruct.isDisabled = true;
    }
    // end::_disable(Storage)[]

    // tag::_disable()[]
    /**
     * @dev Default version of _disable binding to the standard STORAGE_SLOT.
     */
    function _disable() internal {
        _disable(_layoutStruct());
    }
    // end::_disable()[]

    // tag::_ensureEnabled()[]
    /**
     * @dev Guard that reverts if the factory is disabled. Called before pool creation.
     * @custom:throws IBasePoolFactory.Disabled
     */
    function _ensureEnabled() internal view {
        if (_isDisabled()) {
            revert IBasePoolFactory.Disabled();
        }
    }
    // end::_ensureEnabled()[]

    // tag::_pauseWindowDuration(Storage)[]
    /**
     * @dev Argumented version of _pauseWindowDuration to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @return duration The configured pause window duration.
     */
    function _pauseWindowDuration(Storage storage layoutStruct) internal view returns (uint32) {
        return layoutStruct.pauseWindowDuration;
    }
    // end::_pauseWindowDuration(Storage)[]

    // tag::_pauseWindowDuration()[]
    /**
     * @dev Default version of _pauseWindowDuration binding to the standard STORAGE_SLOT.
     * @return duration The configured pause window duration.
     */
    function _pauseWindowDuration() internal view returns (uint32) {
        return _pauseWindowDuration(_layoutStruct());
    }
    // end::_pauseWindowDuration()[]

    // tag::_pauseWindowEndTime(Storage)[]
    /**
     * @dev Argumented version of _pauseWindowEndTime to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @return endTime The original pause window end time (unix timestamp).
     */
    function _pauseWindowEndTime(Storage storage layoutStruct) internal view returns (uint32) {
        return layoutStruct.pauseWindowEndTime;
    }
    // end::_pauseWindowEndTime(Storage)[]

    // tag::_pauseWindowEndTime()[]
    /**
     * @dev Default version of _pauseWindowEndTime binding to the standard STORAGE_SLOT.
     * @return endTime The original pause window end time (unix timestamp).
     */
    function _pauseWindowEndTime() internal view returns (uint32) {
        return _pauseWindowEndTime(_layoutStruct());
    }
    // end::_pauseWindowEndTime()[]

    // tag::_getPoolManager(Storage)[]
    /**
     * @dev Argumented version of _getPoolManager to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @return manager The pool manager address.
     */
    function _getPoolManager(Storage storage layoutStruct) internal view returns (address) {
        return layoutStruct.poolManager;
    }
    // end::_getPoolManager(Storage)[]

    // tag::_getPoolManager()[]
    /**
     * @dev Default version of _getPoolManager binding to the standard STORAGE_SLOT.
     * @return manager The pool manager address.
     */
    function _getPoolManager() internal view returns (address) {
        return _getPoolManager(_layoutStruct());
    }
    // end::_getPoolManager()[]

    // tag::_addPool(Storage-address)[]
    /**
     * @dev Argumented version of _addPool to allow direct Storage access. Uses AddressSetRepo.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @param pool The address of the newly deployed pool to track.
     */
    function _addPool(Storage storage layoutStruct, address pool) internal {
        layoutStruct.pools._add(pool);
    }
    // end::_addPool(Storage-address)[]

    // tag::_addPool(address)[]
    /**
     * @dev Default version of _addPool binding to the standard STORAGE_SLOT. Uses AddressSetRepo.
     * @param pool The address of the newly deployed pool to track.
     */
    function _addPool(address pool) internal {
        _addPool(_layoutStruct(), pool);
    }
    // end::_addPool(address)[]

    // tag::_isPoolFromFactory(Storage-address)[]
    /**
     * @dev Argumented version of _isPoolFromFactory to allow direct Storage access. Uses AddressSetRepo.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @param pool The pool address to check.
     * @return success True if `pool` was created by this factory.
     */
    function _isPoolFromFactory(Storage storage layoutStruct, address pool) internal view returns (bool) {
        return layoutStruct.pools._contains(pool);
    }
    // end::_isPoolFromFactory(Storage-address)[]

    // tag::_isPoolFromFactory(address)[]
    /**
     * @dev Default version of _isPoolFromFactory binding to the standard STORAGE_SLOT. Uses AddressSetRepo.
     * @param pool The pool address to check.
     * @return success True if `pool` was created by this factory.
     */
    function _isPoolFromFactory(address pool) internal view returns (bool) {
        return _isPoolFromFactory(_layoutStruct(), pool);
    }
    // end::_isPoolFromFactory(address)[]

    // tag::_getPoolCount(Storage)[]
    /**
     * @dev Argumented version of _getPoolCount to allow direct Storage access. Uses AddressSetRepo.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @return poolCount The number of pools deployed by this factory.
     */
    function _getPoolCount(Storage storage layoutStruct) internal view returns (uint256) {
        return layoutStruct.pools._length();
    }
    // end::_getPoolCount(Storage)[]

    // tag::_getPoolCount()[]
    /**
     * @dev Default version of _getPoolCount binding to the standard STORAGE_SLOT. Uses AddressSetRepo.
     * @return poolCount The number of pools deployed by this factory.
     */
    function _getPoolCount() internal view returns (uint256) {
        return _getPoolCount(_layoutStruct());
    }
    // end::_getPoolCount()[]

    // tag::_getPoolsInRange(Storage-uint256-uint256)[]
    /**
     * @dev Argumented version of _getPoolsInRange to allow direct Storage access. Uses AddressSetRepo.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @param start The index of the first pool to return.
     * @param count The maximum number of pools to return.
     * @return pools The list of pools deployed by this factory, starting at `start` and returning up to `count` pools.
     */
    function _getPoolsInRange(Storage storage layoutStruct, uint256 start, uint256 count)
        internal
        view
        returns (address[] memory)
    {
        return layoutStruct.pools._range(start, count);
    }
    // end::_getPoolsInRange(Storage-uint256-uint256)[]

    // tag::_getPoolsInRange(uint256-uint256)[]
    /**
     * @dev Default version of _getPoolsInRange binding to the standard STORAGE_SLOT. Uses AddressSetRepo.
     * @param start The index of the first pool to return.
     * @param count The maximum number of pools to return.
     * @return pools The list of pools deployed by this factory, starting at `start` and returning up to `count` pools.
     */
    function _getPoolsInRange(uint256 start, uint256 count) internal view returns (address[] memory) {
        return _getPoolsInRange(_layoutStruct(), start, count);
    }
    // end::_getPoolsInRange(uint256-uint256)[]

    // tag::_getPools(Storage)[]
    /**
     * @dev Argumented version of _getPools to allow direct Storage access. Uses AddressSetRepo.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @return pools The complete list of pools deployed by this factory.
     */
    function _getPools(Storage storage layoutStruct) internal view returns (address[] memory) {
        return layoutStruct.pools._values();
    }
    // end::_getPools(Storage)[]

    // tag::_getPools()[]
    /**
     * @dev Default version of _getPools binding to the standard STORAGE_SLOT. Uses AddressSetRepo.
     * @return pools The complete list of pools deployed by this factory.
     */
    function _getPools() internal view returns (address[] memory) {
        return _getPools(_layoutStruct());
    }
    // end::_getPools()[]

    // tag::_setTokenConfigs(address-TokenConfig[]-memory)[]
    /**
     * @dev Default (thin) version of _setTokenConfigs binding to the standard STORAGE_SLOT.
     *      Delegates to the Storage version. (Internal helper used during pool init in DFPkgs.)
     * @param pool_ The pool address.
     * @param tokenConfig_ The token configs to store (populates tokensOfPool + rate/type/pays mappings).
     */
    function _setTokenConfigs(address pool_, TokenConfig[] memory tokenConfig_) internal {
        _setTokenConfigs(_layoutStruct(), pool_, tokenConfig_);
    }
    // end::_setTokenConfigs(address-TokenConfig[]-memory)[]

    // tag::_getTokenConfigs(Storage-address)[]
    /**
     * @dev Argumented version of _getTokenConfigs to allow direct Storage access.
     *      Reconstructs TokenConfig[] from the per-pool mappings (tokensOfPool, typeOfTokenOfPool, rateProviderOfTokenOfPool, paysYieldFeesOfPool).
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @param pool_ The pool address.
     * @return tokenConfigs The token configs for the pool.
     */
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
    // end::_getTokenConfigs(Storage-address)[]

    // tag::_getTokenConfigs(address)[]
    /**
     * @dev Default version of _getTokenConfigs binding to the standard STORAGE_SLOT.
     * @param pool_ The pool address.
     * @return tokenConfigs The token configs for the pool.
     */
    function _getTokenConfigs(address pool_) internal view returns (TokenConfig[] memory tokenConfigs) {
        return _getTokenConfigs(_layoutStruct(), pool_);
    }
    // end::_getTokenConfigs(address)[]

    // tag::_setTokenConfigs(Storage-address-TokenConfig[]-memory)[]
    /**
     * @dev Argumented version of _setTokenConfigs to allow direct Storage access.
     *      Populates tokensOfPool (via AddressSetRepo), typeOfTokenOfPool, rateProviderOfTokenOfPool, paysYieldFeesOfPool.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @param pool_ The pool address.
     * @param tokenConfig_ The token configs (from pool creation args).
     */
    function _setTokenConfigs(Storage storage layoutStruct, address pool_, TokenConfig[] memory tokenConfig_) internal {
        for (uint256 cursor = 0; cursor < tokenConfig_.length; cursor++) {
            layoutStruct.tokensOfPool[pool_]._add(address(tokenConfig_[cursor].token));
            layoutStruct.rateProviderOfTokenOfPool[pool_][address(tokenConfig_[cursor].token)] =
                address(tokenConfig_[cursor].rateProvider);
            layoutStruct.typeOfTokenOfPool[pool_][address(tokenConfig_[cursor].token)] = tokenConfig_[cursor].tokenType;
            layoutStruct.paysYieldFeesOfPool[pool_][address(tokenConfig_[cursor].token)] =
            tokenConfig_[cursor].paysYieldFees;
        }
    }
    // end::_setTokenConfigs(Storage-address-TokenConfig[]-memory)[]

    // tag::_getNewPoolPauseWindowEndTime(Storage)[]
    /**
     * @dev Argumented version of _getNewPoolPauseWindowEndTime to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @return endTime The effective pause window end time for a new pool (0 after original window).
     */
    function _getNewPoolPauseWindowEndTime(Storage storage layoutStruct) internal view returns (uint32) {
        // We know _poolsPauseWindowEndTime <= _MAX_TIMESTAMP (checked above).
        // Do not truncate timestamp; it should still return 0 after _MAX_TIMESTAMP.
        uint32 pauseWindowEndTime = _pauseWindowEndTime(layoutStruct);
        return (block.timestamp < pauseWindowEndTime) ? pauseWindowEndTime : 0;
    }
    // end::_getNewPoolPauseWindowEndTime(Storage)[]

    // tag::_setHooksContract(Storage-address-address)[]
    /**
     * @dev Argumented version of _setHooksContract to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @param pool_ The pool address.
     * @param hooksContract_ The hooks contract address for the pool (or zero).
     */
    function _setHooksContract(Storage storage layoutStruct, address pool_, address hooksContract_) internal {
        layoutStruct.hooksContractOfPool[pool_] = hooksContract_;
    }
    // end::_setHooksContract(Storage-address-address)[]

    // tag::_setHooksContract(address-address)[]
    /**
     * @dev Default version of _setHooksContract binding to the standard STORAGE_SLOT.
     * @param pool_ The pool address.
     * @param hooksContract_ The hooks contract address for the pool (or zero).
     */
    function _setHooksContract(address pool_, address hooksContract_) internal {
        _setHooksContract(_layoutStruct(), pool_, hooksContract_);
    }
    // end::_setHooksContract(address-address)[]

    // tag::_getNewPoolPauseWindowEndTime()[]
    /**
     * @dev Default version of _getNewPoolPauseWindowEndTime binding to the standard STORAGE_SLOT.
     * @return endTime The effective pause window end time for a new pool (0 after original window).
     */
    function _getNewPoolPauseWindowEndTime() internal view returns (uint32) {
        return _getNewPoolPauseWindowEndTime(_layoutStruct());
    }
    // end::_getNewPoolPauseWindowEndTime()[]

    // tag::_getHooksContract(Storage-address)[]
    /**
     * @dev Argumented version of _getHooksContract to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @param pool_ The pool address.
     * @return hooksContract The hooks contract registered for the pool.
     */
    function _getHooksContract(Storage storage layoutStruct, address pool_) internal view returns (address) {
        return layoutStruct.hooksContractOfPool[pool_];
    }
    // end::_getHooksContract(Storage-address)[]

    // tag::_getHooksContract(address)[]
    /**
     * @dev Default version of _getHooksContract binding to the standard STORAGE_SLOT.
     * @param pool_ The pool address.
     * @return hooksContract The hooks contract registered for the pool.
     */
    function _getHooksContract(address pool_) internal view returns (address) {
        return _getHooksContract(_layoutStruct(), pool_);
    }
    // end::_getHooksContract(address)[]

// end::BalancerV3BasePoolFactoryRepo[]
}
