// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";

import {IProtocolFeeController} from "@balancer-labs/v3-interfaces/contracts/vault/IProtocolFeeController.sol";
import {IAuthorizer} from "@balancer-labs/v3-interfaces/contracts/vault/IAuthorizer.sol";
import {IHooks} from "@balancer-labs/v3-interfaces/contracts/vault/IHooks.sol";
import "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";

import {VaultStateBits} from "@balancer-labs/v3-vault/contracts/lib/VaultStateLib.sol";
import {PoolConfigBits} from "@balancer-labs/v3-vault/contracts/lib/PoolConfigLib.sol";

/* -------------------------------------------------------------------------- */
/*                          BalancerV3VaultStorageRepo                        */
/* -------------------------------------------------------------------------- */

/**
 * @title BalancerV3VaultStorageRepo
 * @notice Diamond-compatible storage layout for Balancer V3 Vault.
 * @dev This library implements the Facet-Target-Repo pattern for the Balancer V3 Vault.
 *
 * Key differences from original VaultStorage.sol:
 * 1. Uses Diamond storage pattern with slot-based layout
 * 2. Replaces immutables with storage variables (initialized once)
 * 3. Maintains exact storage layout compatibility for all state variables
 *
 * The original VaultStorage uses immutables for:
 * - _MINIMUM_TRADE_AMOUNT, _MINIMUM_WRAP_AMOUNT (config)
 * - _vaultPauseWindowEndTime, _vaultBufferPeriodEndTime, _vaultBufferPeriodDuration (timing)
 * - Transient storage slot addresses (computed at deploy time)
 *
 * In Diamond pattern, we:
 * - Store config values in regular storage (initialized once via _initialize)
 * - Use constant transient slot computations (evaluated at compile time)
 */
library BalancerV3VaultStorageRepo {
    /* ------ Storage Slot ------ */

    bytes32 internal constant STORAGE_SLOT = keccak256("protocols.dexes.balancer.v3.vault.diamond");

    /* ------ Constants (from VaultStorage) ------ */

    /// @dev Pools can have between two and eight tokens.
    uint256 internal constant MIN_TOKENS = 2;

    /// @dev Maximum token count, implicitly hard-coded in PoolConfigLib through tokenDecimalDiffs packing.
    uint256 internal constant MAX_TOKENS = 8;

    /// @dev Maximum decimals supported. Tokens must implement IERC20Metadata.decimals.
    uint8 internal constant MAX_TOKEN_DECIMALS = 18;

    /// @dev Maximum pause window duration.
    uint256 internal constant MAX_PAUSE_WINDOW_DURATION = 365 days * 4;

    /// @dev Maximum buffer period duration.
    uint256 internal constant MAX_BUFFER_PERIOD_DURATION = 180 days;

    /// @dev Minimum BPT amount minted upon pool initialization.
    uint256 internal constant POOL_MINIMUM_TOTAL_SUPPLY = 1e6;

    /// @dev Minimum BPT amount minted upon buffer initialization.
    uint256 internal constant BUFFER_MINIMUM_TOTAL_SUPPLY = 1e4;

    /* ------ Transient Storage Slots (precomputed constants) ------ */

    /**
     * @dev Transient storage slots computed using Balancer's TransientStorageHelpers.calculateSlot formula:
     * keccak256(abi.encode(uint256(keccak256(abi.encodePacked("balancer-labs.v3.storage.", domain, ".", varName))) - 1))
     * & ~bytes32(uint256(0xff))
     *
     * Domain: "VaultStorage"
     */

    /// @dev Transient slot for unlock state. Domain: VaultStorage, Key: isUnlocked
    bytes32 internal constant IS_UNLOCKED_SLOT =
        0x1369d017453f080f2416efe5ae39c8a4b4655ea0634227aaab0afdb9a9f93f00;

    /// @dev Transient slot for non-zero delta count. Domain: VaultStorage, Key: nonZeroDeltaCount
    bytes32 internal constant NON_ZERO_DELTA_COUNT_SLOT =
        0xbcbf50c510014a975eac30806436734486f167c41af035c1645353d475d57100;

    /// @dev Transient slot for token deltas mapping. Domain: VaultStorage, Key: tokenDeltas
    bytes32 internal constant TOKEN_DELTAS_SLOT =
        0xf74f46243717369ff9f20877dfc1ba8491e6be48bfe7acc5b65f5ac68f585c00;

    /// @dev Transient slot for add liquidity called flag. Domain: VaultStorage, Key: addLiquidityCalled
    bytes32 internal constant ADD_LIQUIDITY_CALLED_SLOT =
        0x3db93ac236d7287d4b8c711cce6b3cca52815a3bd1fc0fcef99ab26afea5d200;

    /// @dev Transient slot for session ID. Domain: VaultStorage, Key: sessionId
    bytes32 internal constant SESSION_ID_SLOT =
        0xa33ab5ae38c334f99ce8d4a88c1634397ed0415a9df15c29dfd3914852f29900;

    /* ------ Storage Struct ------ */

    /**
     * @notice Main storage struct for Balancer V3 Vault Diamond.
     * @dev Layout matches VaultStorage.sol for compatibility.
     */
    struct Storage {
        /* ------ Configuration (replaces immutables) ------ */

        /// @dev Minimum swap amount (scaled18), replaces immutable _MINIMUM_TRADE_AMOUNT.
        uint256 minimumTradeAmount;
        /// @dev Minimum wrap/unwrap amount (native decimals), replaces immutable _MINIMUM_WRAP_AMOUNT.
        uint256 minimumWrapAmount;
        /// @dev Vault pause window end timestamp, replaces immutable _vaultPauseWindowEndTime.
        uint32 vaultPauseWindowEndTime;
        /// @dev Vault buffer period end timestamp, replaces immutable _vaultBufferPeriodEndTime.
        uint32 vaultBufferPeriodEndTime;
        /// @dev Vault buffer period duration, replaces immutable _vaultBufferPeriodDuration.
        uint32 vaultBufferPeriodDuration;
        /// @dev Flag indicating storage has been initialized.
        bool initialized;

        /* ------ Pool State ------ */

        /// @dev Pool-specific configuration data (fees, pause window, config flags).
        mapping(address pool => PoolConfigBits poolConfig) poolConfigBits;
        /// @dev Accounts assigned to specific roles (pauseManager, swapManager).
        mapping(address pool => PoolRoleAccounts roleAccounts) poolRoleAccounts;
        /// @dev Hooks contracts associated with each pool.
        mapping(address pool => IHooks hooksContract) hooksContracts;
        /// @dev Set of tokens associated with each pool.
        mapping(address pool => IERC20[] poolTokens) poolTokens;
        /// @dev Token configuration for each pool's tokens.
        mapping(address pool => mapping(IERC20 token => TokenInfo tokenInfo)) poolTokenInfo;
        /// @dev Packed raw and live balances per token index.
        mapping(address pool => mapping(uint256 tokenIndex => bytes32 packedBalance)) poolTokenBalances;
        /// @dev Aggregate protocol fees (swap=raw, yield=derived).
        mapping(address pool => mapping(IERC20 token => bytes32 packedFees)) aggregateFeeAmounts;

        /* ------ Vault State ------ */

        /// @dev Vault state bits (pause flags).
        VaultStateBits vaultStateBits;
        /// @dev Total reserve of each ERC20 token.
        mapping(IERC20 token => uint256 balance) reservesOf;
        /// @dev Flag that prevents re-enabling queries.
        bool queriesDisabledPermanently;

        /* ------ Contract References ------ */

        /// @dev Upgradeable authorizer contract.
        IAuthorizer authorizer;
        /// @dev Protocol fee controller contract.
        IProtocolFeeController protocolFeeController;

        /* ------ ERC4626 Buffers ------ */

        /// @dev Buffer token balances (underlying=raw, wrapped=derived).
        mapping(IERC4626 wrappedToken => bytes32 packedBalance) bufferTokenBalances;
        /// @dev Buffer LP shares per user.
        mapping(IERC4626 wrappedToken => mapping(address user => uint256 shares)) bufferLpShares;
        /// @dev Total buffer LP shares.
        mapping(IERC4626 wrappedToken => uint256 totalShares) bufferTotalShares;
        /// @dev Registered underlying asset for each buffer.
        mapping(IERC4626 wrappedToken => address underlyingToken) bufferAssets;
    }

    /* ------ Layout Functions ------ */

    /**
     * @dev Returns storage layout at the specified slot.
     * @param slot_ Custom storage slot.
     * @return layout Storage pointer.
     */
    function _layout(bytes32 slot_) internal pure returns (Storage storage layout) {
        assembly {
            layout.slot := slot_
        }
    }

    /**
     * @dev Returns storage layout at the default slot.
     * @return Storage pointer.
     */
    function _layout() internal pure returns (Storage storage) {
        return _layout(STORAGE_SLOT);
    }

    /* ------ Initialization ------ */

    /**
     * @notice Initialize vault storage with configuration.
     * @dev Can only be called once. Sets values that were immutables in original.
     * @param layout Storage layout to initialize.
     * @param minimumTradeAmount_ Minimum trade amount in scaled18.
     * @param minimumWrapAmount_ Minimum wrap amount in native decimals.
     * @param pauseWindowDuration Duration of pause window from deployment.
     * @param bufferPeriodDuration Duration of buffer period after pause window.
     * @param authorizer_ Initial authorizer contract.
     * @param protocolFeeController_ Protocol fee controller contract.
     */
    function _initialize(
        Storage storage layout,
        uint256 minimumTradeAmount_,
        uint256 minimumWrapAmount_,
        uint32 pauseWindowDuration,
        uint32 bufferPeriodDuration,
        IAuthorizer authorizer_,
        IProtocolFeeController protocolFeeController_
    ) internal {
        require(!layout.initialized, "BalancerV3VaultStorageRepo: already initialized");
        require(pauseWindowDuration <= MAX_PAUSE_WINDOW_DURATION, "BalancerV3VaultStorageRepo: pause window too long");
        require(bufferPeriodDuration <= MAX_BUFFER_PERIOD_DURATION, "BalancerV3VaultStorageRepo: buffer period too long");

        layout.minimumTradeAmount = minimumTradeAmount_;
        layout.minimumWrapAmount = minimumWrapAmount_;

        // Calculate timestamps based on block.timestamp
        uint32 pauseWindowEndTime = uint32(block.timestamp) + pauseWindowDuration;
        layout.vaultPauseWindowEndTime = pauseWindowEndTime;
        layout.vaultBufferPeriodDuration = bufferPeriodDuration;
        layout.vaultBufferPeriodEndTime = pauseWindowEndTime + bufferPeriodDuration;

        layout.authorizer = authorizer_;
        layout.protocolFeeController = protocolFeeController_;
        layout.initialized = true;
    }

    /**
     * @notice Initialize using default storage slot.
     */
    function _initialize(
        uint256 minimumTradeAmount_,
        uint256 minimumWrapAmount_,
        uint32 pauseWindowDuration,
        uint32 bufferPeriodDuration,
        IAuthorizer authorizer_,
        IProtocolFeeController protocolFeeController_
    ) internal {
        _initialize(
            _layout(),
            minimumTradeAmount_,
            minimumWrapAmount_,
            pauseWindowDuration,
            bufferPeriodDuration,
            authorizer_,
            protocolFeeController_
        );
    }

    /* ------ Configuration Accessors ------ */

    function _minimumTradeAmount(Storage storage layout) internal view returns (uint256) {
        return layout.minimumTradeAmount;
    }

    function _minimumTradeAmount() internal view returns (uint256) {
        return _minimumTradeAmount(_layout());
    }

    function _minimumWrapAmount(Storage storage layout) internal view returns (uint256) {
        return layout.minimumWrapAmount;
    }

    function _minimumWrapAmount() internal view returns (uint256) {
        return _minimumWrapAmount(_layout());
    }

    function _vaultPauseWindowEndTime(Storage storage layout) internal view returns (uint32) {
        return layout.vaultPauseWindowEndTime;
    }

    function _vaultPauseWindowEndTime() internal view returns (uint32) {
        return _vaultPauseWindowEndTime(_layout());
    }

    function _vaultBufferPeriodEndTime(Storage storage layout) internal view returns (uint32) {
        return layout.vaultBufferPeriodEndTime;
    }

    function _vaultBufferPeriodEndTime() internal view returns (uint32) {
        return _vaultBufferPeriodEndTime(_layout());
    }

    function _vaultBufferPeriodDuration(Storage storage layout) internal view returns (uint32) {
        return layout.vaultBufferPeriodDuration;
    }

    function _vaultBufferPeriodDuration() internal view returns (uint32) {
        return _vaultBufferPeriodDuration(_layout());
    }

    /* ------ Contract References ------ */

    function _authorizer(Storage storage layout) internal view returns (IAuthorizer) {
        return layout.authorizer;
    }

    function _authorizer() internal view returns (IAuthorizer) {
        return _authorizer(_layout());
    }

    function _setAuthorizer(Storage storage layout, IAuthorizer newAuthorizer) internal {
        layout.authorizer = newAuthorizer;
    }

    function _setAuthorizer(IAuthorizer newAuthorizer) internal {
        _setAuthorizer(_layout(), newAuthorizer);
    }

    function _protocolFeeController(Storage storage layout) internal view returns (IProtocolFeeController) {
        return layout.protocolFeeController;
    }

    function _protocolFeeController() internal view returns (IProtocolFeeController) {
        return _protocolFeeController(_layout());
    }

    function _setProtocolFeeController(Storage storage layout, IProtocolFeeController newController) internal {
        layout.protocolFeeController = newController;
    }

    function _setProtocolFeeController(IProtocolFeeController newController) internal {
        _setProtocolFeeController(_layout(), newController);
    }

    /* ------ Vault State ------ */

    function _vaultStateBits(Storage storage layout) internal view returns (VaultStateBits) {
        return layout.vaultStateBits;
    }

    function _vaultStateBits() internal view returns (VaultStateBits) {
        return _vaultStateBits(_layout());
    }

    function _setVaultStateBits(Storage storage layout, VaultStateBits bits) internal {
        layout.vaultStateBits = bits;
    }

    function _setVaultStateBits(VaultStateBits bits) internal {
        _setVaultStateBits(_layout(), bits);
    }

    function _queriesDisabledPermanently(Storage storage layout) internal view returns (bool) {
        return layout.queriesDisabledPermanently;
    }

    function _queriesDisabledPermanently() internal view returns (bool) {
        return _queriesDisabledPermanently(_layout());
    }

    function _setQueriesDisabledPermanently(Storage storage layout, bool disabled) internal {
        layout.queriesDisabledPermanently = disabled;
    }

    function _setQueriesDisabledPermanently(bool disabled) internal {
        _setQueriesDisabledPermanently(_layout(), disabled);
    }

    /* ------ Reserves ------ */

    function _reservesOf(Storage storage layout, IERC20 token) internal view returns (uint256) {
        return layout.reservesOf[token];
    }

    function _reservesOf(IERC20 token) internal view returns (uint256) {
        return _reservesOf(_layout(), token);
    }

    function _setReservesOf(Storage storage layout, IERC20 token, uint256 amount) internal {
        layout.reservesOf[token] = amount;
    }

    function _setReservesOf(IERC20 token, uint256 amount) internal {
        _setReservesOf(_layout(), token, amount);
    }

    /* ------ Pool Config ------ */

    function _poolConfigBits(Storage storage layout, address pool) internal view returns (PoolConfigBits) {
        return layout.poolConfigBits[pool];
    }

    function _poolConfigBits(address pool) internal view returns (PoolConfigBits) {
        return _poolConfigBits(_layout(), pool);
    }

    function _setPoolConfigBits(Storage storage layout, address pool, PoolConfigBits config) internal {
        layout.poolConfigBits[pool] = config;
    }

    function _setPoolConfigBits(address pool, PoolConfigBits config) internal {
        _setPoolConfigBits(_layout(), pool, config);
    }

    /* ------ Pool Role Accounts ------ */

    function _poolRoleAccounts(Storage storage layout, address pool) internal view returns (PoolRoleAccounts storage) {
        return layout.poolRoleAccounts[pool];
    }

    function _poolRoleAccounts(address pool) internal view returns (PoolRoleAccounts storage) {
        return _poolRoleAccounts(_layout(), pool);
    }

    function _setPoolRoleAccounts(Storage storage layout, address pool, PoolRoleAccounts memory accounts) internal {
        layout.poolRoleAccounts[pool] = accounts;
    }

    function _setPoolRoleAccounts(address pool, PoolRoleAccounts memory accounts) internal {
        _setPoolRoleAccounts(_layout(), pool, accounts);
    }

    /* ------ Pool Hooks ------ */

    function _hooksContract(Storage storage layout, address pool) internal view returns (IHooks) {
        return layout.hooksContracts[pool];
    }

    function _hooksContract(address pool) internal view returns (IHooks) {
        return _hooksContract(_layout(), pool);
    }

    function _setHooksContract(Storage storage layout, address pool, IHooks hooks) internal {
        layout.hooksContracts[pool] = hooks;
    }

    function _setHooksContract(address pool, IHooks hooks) internal {
        _setHooksContract(_layout(), pool, hooks);
    }

    /* ------ Pool Tokens ------ */

    function _poolTokens(Storage storage layout, address pool) internal view returns (IERC20[] storage) {
        return layout.poolTokens[pool];
    }

    function _poolTokens(address pool) internal view returns (IERC20[] storage) {
        return _poolTokens(_layout(), pool);
    }

    /* ------ Pool Token Info ------ */

    function _poolTokenInfo(Storage storage layout, address pool, IERC20 token) internal view returns (TokenInfo storage) {
        return layout.poolTokenInfo[pool][token];
    }

    function _poolTokenInfo(address pool, IERC20 token) internal view returns (TokenInfo storage) {
        return _poolTokenInfo(_layout(), pool, token);
    }

    /* ------ Pool Token Balances ------ */

    function _poolTokenBalances(Storage storage layout, address pool) internal view returns (mapping(uint256 => bytes32) storage) {
        return layout.poolTokenBalances[pool];
    }

    function _poolTokenBalances(address pool) internal view returns (mapping(uint256 => bytes32) storage) {
        return _poolTokenBalances(_layout(), pool);
    }

    /* ------ Aggregate Fee Amounts ------ */

    function _aggregateFeeAmounts(Storage storage layout, address pool) internal view returns (mapping(IERC20 => bytes32) storage) {
        return layout.aggregateFeeAmounts[pool];
    }

    function _aggregateFeeAmounts(address pool) internal view returns (mapping(IERC20 => bytes32) storage) {
        return _aggregateFeeAmounts(_layout(), pool);
    }

    function _getAggregateFeeAmount(Storage storage layout, address pool, IERC20 token) internal view returns (bytes32) {
        return layout.aggregateFeeAmounts[pool][token];
    }

    function _getAggregateFeeAmount(address pool, IERC20 token) internal view returns (bytes32) {
        return _getAggregateFeeAmount(_layout(), pool, token);
    }

    function _setAggregateFeeAmount(Storage storage layout, address pool, IERC20 token, bytes32 amount) internal {
        layout.aggregateFeeAmounts[pool][token] = amount;
    }

    function _setAggregateFeeAmount(address pool, IERC20 token, bytes32 amount) internal {
        _setAggregateFeeAmount(_layout(), pool, token, amount);
    }

    /* ------ Buffer Token Balances ------ */

    function _bufferTokenBalance(Storage storage layout, IERC4626 wrappedToken) internal view returns (bytes32) {
        return layout.bufferTokenBalances[wrappedToken];
    }

    function _bufferTokenBalance(IERC4626 wrappedToken) internal view returns (bytes32) {
        return _bufferTokenBalance(_layout(), wrappedToken);
    }

    function _setBufferTokenBalance(Storage storage layout, IERC4626 wrappedToken, bytes32 balance) internal {
        layout.bufferTokenBalances[wrappedToken] = balance;
    }

    function _setBufferTokenBalance(IERC4626 wrappedToken, bytes32 balance) internal {
        _setBufferTokenBalance(_layout(), wrappedToken, balance);
    }

    /* ------ Buffer LP Shares ------ */

    function _bufferLpShares(Storage storage layout, IERC4626 wrappedToken, address user) internal view returns (uint256) {
        return layout.bufferLpShares[wrappedToken][user];
    }

    function _bufferLpShares(IERC4626 wrappedToken, address user) internal view returns (uint256) {
        return _bufferLpShares(_layout(), wrappedToken, user);
    }

    function _setBufferLpShares(Storage storage layout, IERC4626 wrappedToken, address user, uint256 shares) internal {
        layout.bufferLpShares[wrappedToken][user] = shares;
    }

    function _setBufferLpShares(IERC4626 wrappedToken, address user, uint256 shares) internal {
        _setBufferLpShares(_layout(), wrappedToken, user, shares);
    }

    /* ------ Buffer Total Shares ------ */

    function _bufferTotalShares(Storage storage layout, IERC4626 wrappedToken) internal view returns (uint256) {
        return layout.bufferTotalShares[wrappedToken];
    }

    function _bufferTotalShares(IERC4626 wrappedToken) internal view returns (uint256) {
        return _bufferTotalShares(_layout(), wrappedToken);
    }

    function _setBufferTotalShares(Storage storage layout, IERC4626 wrappedToken, uint256 shares) internal {
        layout.bufferTotalShares[wrappedToken] = shares;
    }

    function _setBufferTotalShares(IERC4626 wrappedToken, uint256 shares) internal {
        _setBufferTotalShares(_layout(), wrappedToken, shares);
    }

    /* ------ Buffer Assets ------ */

    function _bufferAsset(Storage storage layout, IERC4626 wrappedToken) internal view returns (address) {
        return layout.bufferAssets[wrappedToken];
    }

    function _bufferAsset(IERC4626 wrappedToken) internal view returns (address) {
        return _bufferAsset(_layout(), wrappedToken);
    }

    function _setBufferAsset(Storage storage layout, IERC4626 wrappedToken, address underlyingToken) internal {
        layout.bufferAssets[wrappedToken] = underlyingToken;
    }

    function _setBufferAsset(IERC4626 wrappedToken, address underlyingToken) internal {
        _setBufferAsset(_layout(), wrappedToken, underlyingToken);
    }

}
