// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {ICLFactory} from "@crane/contracts/protocols/dexes/aerodrome/slipstream/interfaces/ICLFactory.sol";
import {ICLPool} from "@crane/contracts/protocols/dexes/aerodrome/slipstream/interfaces/ICLPool.sol";
import {IFeeModule} from "@crane/contracts/protocols/dexes/aerodrome/slipstream/interfaces/fees/IFeeModule.sol";
import {IVoter} from "@crane/contracts/protocols/dexes/aerodrome/v1/interfaces/IVoter.sol";
import {IFactoryRegistry} from "@crane/contracts/protocols/dexes/aerodrome/v1/interfaces/factories/IFactoryRegistry.sol";
import {Clones} from "@crane/contracts/proxy/Clones.sol";
import {CLPool} from "./CLPool.sol";

/// @title CLFactory
/// @notice Canonical Slipstream CL Factory - deploys CL pools and manages protocol fees
/// @dev Ported from Slipstream (Solidity 0.7.6) to Solidity 0.8.x
/// @dev Key features:
///      - Uses EIP-1167 minimal proxies (Clones) for pool deployment
///      - Supports dynamic swap fees via fee modules
///      - Supports unstaked fees for non-staked liquidity
///      - Maintains compatibility with legacy CLFactory
contract CLFactory is ICLFactory {
    /* -------------------------------------------------------------------------- */
    /*                                  Immutables                                */
    /* -------------------------------------------------------------------------- */

    /// @inheritdoc ICLFactory
    IVoter public immutable override voter;
    /// @inheritdoc ICLFactory
    address public immutable override poolImplementation;
    /// @inheritdoc ICLFactory
    IFactoryRegistry public immutable override factoryRegistry;
    /// @inheritdoc ICLFactory
    ICLFactory public immutable override legacyCLFactory;

    /* -------------------------------------------------------------------------- */
    /*                                    State                                   */
    /* -------------------------------------------------------------------------- */

    /// @inheritdoc ICLFactory
    address public override owner;
    /// @inheritdoc ICLFactory
    address public override swapFeeManager;
    /// @inheritdoc ICLFactory
    address public override swapFeeModule;
    /// @inheritdoc ICLFactory
    address public override unstakedFeeManager;
    /// @inheritdoc ICLFactory
    address public override unstakedFeeModule;
    /// @inheritdoc ICLFactory
    uint24 public override defaultUnstakedFee;

    /// @inheritdoc ICLFactory
    mapping(int24 => uint24) public override tickSpacingToFee;

    /// @dev Pool address mapping: token0 => token1 => tickSpacing => pool
    mapping(address => mapping(address => mapping(int24 => address))) public override getPool;

    /// @dev Used in VotingEscrow to determine if a contract is a valid pool
    mapping(address => bool) private _isPool;

    /// @inheritdoc ICLFactory
    address[] public override allPools;

    int24[] private _tickSpacings;

    /* -------------------------------------------------------------------------- */
    /*                                 Constructor                                */
    /* -------------------------------------------------------------------------- */

    /// @param _voter The voter contract address
    /// @param _legacyCLFactory The legacy CLFactory address (can be address(0) if none)
    /// @param _poolImplementation The pool implementation for cloning
    constructor(address _voter, address _legacyCLFactory, address _poolImplementation) {
        owner = msg.sender;
        swapFeeManager = msg.sender;
        unstakedFeeManager = msg.sender;
        voter = IVoter(_voter);
        factoryRegistry = IFactoryRegistry(IVoter(_voter).factoryRegistry());
        legacyCLFactory = ICLFactory(_legacyCLFactory);
        poolImplementation = _poolImplementation;
        defaultUnstakedFee = 100_000; // 10%

        emit OwnerChanged(address(0), msg.sender);
        emit SwapFeeManagerChanged(address(0), msg.sender);
        emit UnstakedFeeManagerChanged(address(0), msg.sender);
        emit DefaultUnstakedFeeChanged(0, 100_000);

        // Enable default tick spacings
        _enableTickSpacing(1, 100);      // 0.01% fee
        _enableTickSpacing(50, 500);     // 0.05% fee
        _enableTickSpacing(100, 500);    // 0.05% fee
        _enableTickSpacing(200, 3_000);  // 0.30% fee
        _enableTickSpacing(2_000, 10_000); // 1.00% fee
    }

    /* -------------------------------------------------------------------------- */
    /*                               Pool Creation                                */
    /* -------------------------------------------------------------------------- */

    /// @inheritdoc ICLFactory
    function createPool(address tokenA, address tokenB, int24 tickSpacing, uint160 sqrtPriceX96)
        external
        override
        returns (address pool)
    {
        require(tokenA != tokenB, "Same token");
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "Zero address");
        require(tickSpacingToFee[tickSpacing] != 0, "Invalid tick spacing");
        require(getPool[token0][token1][tickSpacing] == address(0), "Pool exists");

        // Check if pool exists in legacy factory - only owner can create duplicates
        if (address(legacyCLFactory) != address(0)) {
            if (legacyCLFactory.getPool({tokenA: token0, tokenB: token1, tickSpacing: tickSpacing}) != address(0)) {
                require(msg.sender == owner, "Only owner");
            }
        }

        // Deploy pool as EIP-1167 minimal proxy
        pool = Clones.cloneDeterministic({
            implementation: poolImplementation,
            salt: keccak256(abi.encode(token0, token1, tickSpacing))
        });

        // Initialize pool
        CLPool(pool).initialize({
            _factory: address(this),
            _token0: token0,
            _token1: token1,
            _tickSpacing: tickSpacing,
            _factoryRegistry: address(factoryRegistry),
            _sqrtPriceX96: sqrtPriceX96
        });

        allPools.push(pool);
        _isPool[pool] = true;
        getPool[token0][token1][tickSpacing] = pool;
        // Populate mapping in reverse direction
        getPool[token1][token0][tickSpacing] = pool;

        emit PoolCreated(token0, token1, tickSpacing, pool);
    }

    /* -------------------------------------------------------------------------- */
    /*                              Fee Computation                               */
    /* -------------------------------------------------------------------------- */

    /// @inheritdoc ICLFactory
    function getSwapFee(address pool) external view override returns (uint24) {
        if (swapFeeModule != address(0)) {
            // Use gas-limited static call to fee module
            try IFeeModule(swapFeeModule).getFee{gas: 200_000}(pool) returns (uint24 fee) {
                if (fee <= 100_000) { // Max 10%
                    return fee;
                }
            } catch {
                // Fall through to default
            }
        }
        return tickSpacingToFee[ICLPool(pool).tickSpacing()];
    }

    /// @inheritdoc ICLFactory
    function getUnstakedFee(address pool) external view override returns (uint24) {
        address gauge = voter.gauges(pool);
        if (!voter.isAlive(gauge) || gauge == address(0)) {
            return 0;
        }
        if (unstakedFeeModule != address(0)) {
            // Use gas-limited static call to fee module
            try IFeeModule(unstakedFeeModule).getFee{gas: 200_000}(pool) returns (uint24 fee) {
                if (fee <= 1_000_000) { // Max 100%
                    return fee;
                }
            } catch {
                // Fall through to default
            }
        }
        return defaultUnstakedFee;
    }

    /* -------------------------------------------------------------------------- */
    /*                              Owner Functions                               */
    /* -------------------------------------------------------------------------- */

    /// @inheritdoc ICLFactory
    function setOwner(address _owner) external override {
        address cachedOwner = owner;
        require(msg.sender == cachedOwner, "Not owner");
        require(_owner != address(0), "Zero address");
        emit OwnerChanged(cachedOwner, _owner);
        owner = _owner;
    }

    /// @inheritdoc ICLFactory
    function enableTickSpacing(int24 tickSpacing, uint24 fee) public override {
        require(msg.sender == owner, "Not owner");
        _enableTickSpacing(tickSpacing, fee);
    }

    function _enableTickSpacing(int24 tickSpacing, uint24 fee) private {
        require(fee > 0 && fee <= 100_000, "Invalid fee");
        // Tick spacing is capped at 16384 to prevent overflow in TickBitmap
        require(tickSpacing > 0 && tickSpacing < 16384, "Invalid tick spacing");
        require(tickSpacingToFee[tickSpacing] == 0, "Already enabled");

        tickSpacingToFee[tickSpacing] = fee;
        _tickSpacings.push(tickSpacing);
        emit TickSpacingEnabled(tickSpacing, fee);
    }

    /* -------------------------------------------------------------------------- */
    /*                           Swap Fee Manager Functions                       */
    /* -------------------------------------------------------------------------- */

    /// @inheritdoc ICLFactory
    function setSwapFeeManager(address _swapFeeManager) external override {
        address cachedSwapFeeManager = swapFeeManager;
        require(msg.sender == cachedSwapFeeManager, "Not fee manager");
        require(_swapFeeManager != address(0), "Zero address");
        swapFeeManager = _swapFeeManager;
        emit SwapFeeManagerChanged(cachedSwapFeeManager, _swapFeeManager);
    }

    /// @inheritdoc ICLFactory
    function setSwapFeeModule(address _swapFeeModule) external override {
        require(msg.sender == swapFeeManager, "Not fee manager");
        require(_swapFeeModule != address(0), "Zero address");
        address oldFeeModule = swapFeeModule;
        swapFeeModule = _swapFeeModule;
        emit SwapFeeModuleChanged(oldFeeModule, _swapFeeModule);
    }

    /* -------------------------------------------------------------------------- */
    /*                         Unstaked Fee Manager Functions                     */
    /* -------------------------------------------------------------------------- */

    /// @inheritdoc ICLFactory
    function setUnstakedFeeManager(address _unstakedFeeManager) external override {
        address cachedUnstakedFeeManager = unstakedFeeManager;
        require(msg.sender == cachedUnstakedFeeManager, "Not fee manager");
        require(_unstakedFeeManager != address(0), "Zero address");
        unstakedFeeManager = _unstakedFeeManager;
        emit UnstakedFeeManagerChanged(cachedUnstakedFeeManager, _unstakedFeeManager);
    }

    /// @inheritdoc ICLFactory
    function setUnstakedFeeModule(address _unstakedFeeModule) external override {
        require(msg.sender == unstakedFeeManager, "Not fee manager");
        require(_unstakedFeeModule != address(0), "Zero address");
        address oldFeeModule = unstakedFeeModule;
        unstakedFeeModule = _unstakedFeeModule;
        emit UnstakedFeeModuleChanged(oldFeeModule, _unstakedFeeModule);
    }

    /// @inheritdoc ICLFactory
    function setDefaultUnstakedFee(uint24 _defaultUnstakedFee) external override {
        require(msg.sender == unstakedFeeManager, "Not fee manager");
        require(_defaultUnstakedFee <= 500_000, "Fee too high"); // Max 50%
        uint24 oldUnstakedFee = defaultUnstakedFee;
        defaultUnstakedFee = _defaultUnstakedFee;
        emit DefaultUnstakedFeeChanged(oldUnstakedFee, _defaultUnstakedFee);
    }

    /* -------------------------------------------------------------------------- */
    /*                              View Functions                                */
    /* -------------------------------------------------------------------------- */

    /// @inheritdoc ICLFactory
    function tickSpacings() external view override returns (int24[] memory) {
        return _tickSpacings;
    }

    /// @inheritdoc ICLFactory
    function allPoolsLength() external view override returns (uint256) {
        return allPools.length;
    }

    /// @inheritdoc ICLFactory
    function isPool(address pool) external view override returns (bool) {
        return _isPool[pool];
    }
}
