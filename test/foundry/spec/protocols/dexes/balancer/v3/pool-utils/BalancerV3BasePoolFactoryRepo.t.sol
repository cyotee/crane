// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IRateProvider} from "@crane/contracts/interfaces/protocols/dexes/balancer/v3/IRateProvider.sol";
import {TokenConfig, TokenType} from "@crane/contracts/interfaces/protocols/dexes/balancer/v3/VaultTypes.sol";
import {IBasePoolFactory} from "@crane/contracts/interfaces/protocols/dexes/balancer/v3/IBasePoolFactory.sol";
import {BalancerV3BasePoolFactoryRepo} from "@crane/contracts/protocols/dexes/balancer/v3/pool-utils/BalancerV3BasePoolFactoryRepo.sol";

/**
 * @title BalancerV3BasePoolFactoryRepoHarness
 * @notice Exposes BalancerV3BasePoolFactoryRepo library functions for testing.
 */
contract BalancerV3BasePoolFactoryRepoHarness {
    function initialize(uint32 pauseWindowDuration_, address poolFeeManager_) external {
        BalancerV3BasePoolFactoryRepo._initialize(pauseWindowDuration_, poolFeeManager_);
    }

    function isDisabled() external view returns (bool) {
        return BalancerV3BasePoolFactoryRepo._isDisabled();
    }

    function disable() external {
        BalancerV3BasePoolFactoryRepo._disable();
    }

    function ensureEnabled() external view {
        BalancerV3BasePoolFactoryRepo._ensureEnabled();
    }

    function pauseWindowDuration() external view returns (uint32) {
        return BalancerV3BasePoolFactoryRepo._pauseWindowDuration();
    }

    function pauseWindowEndTime() external view returns (uint32) {
        return BalancerV3BasePoolFactoryRepo._pauseWindowEndTime();
    }

    function getPoolManager() external view returns (address) {
        return BalancerV3BasePoolFactoryRepo._getPoolManager();
    }

    function addPool(address pool) external {
        BalancerV3BasePoolFactoryRepo._addPool(pool);
    }

    function isPoolFromFactory(address pool) external view returns (bool) {
        return BalancerV3BasePoolFactoryRepo._isPoolFromFactory(pool);
    }

    function getPoolCount() external view returns (uint256) {
        return BalancerV3BasePoolFactoryRepo._getPoolCount();
    }

    function getPools() external view returns (address[] memory) {
        return BalancerV3BasePoolFactoryRepo._getPools();
    }

    function getPoolsInRange(uint256 start, uint256 count) external view returns (address[] memory) {
        return BalancerV3BasePoolFactoryRepo._getPoolsInRange(start, count);
    }

    function setTokenConfigs(address pool, TokenConfig[] memory tokenConfigs) external {
        BalancerV3BasePoolFactoryRepo._setTokenConfigs(pool, tokenConfigs);
    }

    function getTokenConfigs(address pool) external view returns (TokenConfig[] memory) {
        return BalancerV3BasePoolFactoryRepo._getTokenConfigs(pool);
    }

    function setHooksContract(address pool, address hooksContract) external {
        BalancerV3BasePoolFactoryRepo._setHooksContract(pool, hooksContract);
    }

    function getHooksContract(address pool) external view returns (address) {
        return BalancerV3BasePoolFactoryRepo._getHooksContract(pool);
    }

    function getNewPoolPauseWindowEndTime() external view returns (uint32) {
        return BalancerV3BasePoolFactoryRepo._getNewPoolPauseWindowEndTime();
    }

    function storageSlot() external pure returns (bytes32) {
        return BalancerV3BasePoolFactoryRepo.STORAGE_SLOT;
    }
}

/**
 * @title BalancerV3BasePoolFactoryRepo_Test
 * @notice Tests for BalancerV3BasePoolFactoryRepo library.
 */
contract BalancerV3BasePoolFactoryRepo_Test is Test {
    BalancerV3BasePoolFactoryRepoHarness internal harness;

    address internal poolManager;
    address internal mockPool1;
    address internal mockPool2;
    address internal mockToken1;
    address internal mockToken2;

    function setUp() public {
        harness = new BalancerV3BasePoolFactoryRepoHarness();
        poolManager = makeAddr("poolManager");
        mockPool1 = makeAddr("pool1");
        mockPool2 = makeAddr("pool2");
        mockToken1 = makeAddr("token1");
        mockToken2 = makeAddr("token2");
    }

    /* ---------------------------------------------------------------------- */
    /*                            Storage Slot Tests                           */
    /* ---------------------------------------------------------------------- */

    function test_storageSlot_isCorrectHash() public view {
        bytes32 expected = keccak256("protocols.dexes.balancer.v3.base.pool.factory.common");
        assertEq(harness.storageSlot(), expected, "Storage slot should match expected hash");
    }

    /* ---------------------------------------------------------------------- */
    /*                          Initialization Tests                           */
    /* ---------------------------------------------------------------------- */

    function test_initialize_storesPauseWindowDuration() public {
        uint32 duration = 365 days;
        harness.initialize(duration, poolManager);

        assertEq(harness.pauseWindowDuration(), duration, "Pause window duration should be stored");
    }

    function test_initialize_storesPoolManager() public {
        harness.initialize(365 days, poolManager);

        assertEq(harness.getPoolManager(), poolManager, "Pool manager should be stored");
    }

    function test_initialize_setsPauseWindowEndTime() public {
        uint32 duration = 365 days;
        uint256 expectedEndTime = block.timestamp + duration;

        harness.initialize(duration, poolManager);

        assertEq(harness.pauseWindowEndTime(), uint32(expectedEndTime), "Pause window end time should be set");
    }

    function test_initialize_revertsOnOverflow() public {
        // Set block.timestamp to near max and try to add a duration that overflows
        // In Solidity 0.8+, the arithmetic overflow panic (0x11) happens before the custom check
        vm.warp(type(uint32).max - 100);

        vm.expectRevert(); // Expect any revert (panic or custom error)
        harness.initialize(200, poolManager);
    }

    /* ---------------------------------------------------------------------- */
    /*                         Disable/Enable Tests                            */
    /* ---------------------------------------------------------------------- */

    function test_isDisabled_returnsFalseByDefault() public {
        harness.initialize(365 days, poolManager);

        assertFalse(harness.isDisabled(), "Should not be disabled by default");
    }

    function test_disable_setsDisabledTrue() public {
        harness.initialize(365 days, poolManager);
        harness.disable();

        assertTrue(harness.isDisabled(), "Should be disabled after disable()");
    }

    function test_ensureEnabled_revertsWhenDisabled() public {
        harness.initialize(365 days, poolManager);
        harness.disable();

        vm.expectRevert(IBasePoolFactory.Disabled.selector);
        harness.ensureEnabled();
    }

    function test_ensureEnabled_succeedsWhenEnabled() public view {
        // Should not revert since factory is not initialized (not disabled)
        harness.ensureEnabled();
    }

    /* ---------------------------------------------------------------------- */
    /*                          Pool Registry Tests                            */
    /* ---------------------------------------------------------------------- */

    function test_addPool_addsPoolToRegistry() public {
        harness.initialize(365 days, poolManager);
        harness.addPool(mockPool1);

        assertTrue(harness.isPoolFromFactory(mockPool1), "Pool should be in registry");
    }

    function test_isPoolFromFactory_returnsFalseForUnregistered() public view {
        assertFalse(harness.isPoolFromFactory(mockPool1), "Unregistered pool should return false");
    }

    function test_getPoolCount_returnsCorrectCount() public {
        harness.initialize(365 days, poolManager);

        assertEq(harness.getPoolCount(), 0, "Initial count should be 0");

        harness.addPool(mockPool1);
        assertEq(harness.getPoolCount(), 1, "Count should be 1 after adding pool");

        harness.addPool(mockPool2);
        assertEq(harness.getPoolCount(), 2, "Count should be 2 after adding second pool");
    }

    function test_getPools_returnsAllPools() public {
        harness.initialize(365 days, poolManager);
        harness.addPool(mockPool1);
        harness.addPool(mockPool2);

        address[] memory pools = harness.getPools();

        assertEq(pools.length, 2, "Should return 2 pools");
        assertTrue(pools[0] == mockPool1 || pools[1] == mockPool1, "Pool1 should be in list");
        assertTrue(pools[0] == mockPool2 || pools[1] == mockPool2, "Pool2 should be in list");
    }

    function test_getPoolsInRange_returnsCorrectSubset() public {
        harness.initialize(365 days, poolManager);

        // Add 5 pools
        for (uint256 i = 0; i < 5; i++) {
            harness.addPool(address(uint160(100 + i)));
        }

        address[] memory subset = harness.getPoolsInRange(1, 2);

        assertEq(subset.length, 2, "Should return 2 pools");
    }

    /* ---------------------------------------------------------------------- */
    /*                        Token Configs Tests                              */
    /* ---------------------------------------------------------------------- */

    function test_setTokenConfigs_storesConfigs() public {
        harness.initialize(365 days, poolManager);

        TokenConfig[] memory configs = new TokenConfig[](2);
        configs[0] = TokenConfig({
            token: IERC20(mockToken1),
            rateProvider: IRateProvider(address(0)),
            tokenType: TokenType.STANDARD,
            paysYieldFees: false
        });
        configs[1] = TokenConfig({
            token: IERC20(mockToken2),
            rateProvider: IRateProvider(address(0x123)),
            tokenType: TokenType.WITH_RATE,
            paysYieldFees: true
        });

        harness.setTokenConfigs(mockPool1, configs);

        TokenConfig[] memory retrieved = harness.getTokenConfigs(mockPool1);

        assertEq(retrieved.length, 2, "Should have 2 token configs");
    }

    function test_getTokenConfigs_returnsEmptyForUnknownPool() public view {
        TokenConfig[] memory configs = harness.getTokenConfigs(mockPool1);

        assertEq(configs.length, 0, "Should return empty array for unknown pool");
    }

    function test_setTokenConfigs_preservesTokenType() public {
        harness.initialize(365 days, poolManager);

        TokenConfig[] memory configs = new TokenConfig[](1);
        configs[0] = TokenConfig({
            token: IERC20(mockToken1),
            rateProvider: IRateProvider(address(0)),
            tokenType: TokenType.WITH_RATE,
            paysYieldFees: true
        });

        harness.setTokenConfigs(mockPool1, configs);

        TokenConfig[] memory retrieved = harness.getTokenConfigs(mockPool1);

        assertEq(uint8(retrieved[0].tokenType), uint8(TokenType.WITH_RATE), "Token type should be preserved");
        assertTrue(retrieved[0].paysYieldFees, "paysYieldFees should be preserved");
    }

    /* ---------------------------------------------------------------------- */
    /*                        Hooks Contract Tests                             */
    /* ---------------------------------------------------------------------- */

    function test_setHooksContract_storesContract() public {
        address hooksContract = makeAddr("hooks");
        harness.initialize(365 days, poolManager);

        harness.setHooksContract(mockPool1, hooksContract);

        assertEq(harness.getHooksContract(mockPool1), hooksContract, "Hooks contract should be stored");
    }

    function test_getHooksContract_returnsZeroForUnknownPool() public view {
        assertEq(harness.getHooksContract(mockPool1), address(0), "Should return zero for unknown pool");
    }

    /* ---------------------------------------------------------------------- */
    /*                      Pause Window End Time Tests                        */
    /* ---------------------------------------------------------------------- */

    function test_getNewPoolPauseWindowEndTime_returnsEndTimeBeforeExpiry() public {
        uint32 duration = 365 days;
        harness.initialize(duration, poolManager);

        uint32 endTime = harness.getNewPoolPauseWindowEndTime();

        assertEq(endTime, uint32(block.timestamp) + duration, "Should return pause window end time");
    }

    function test_getNewPoolPauseWindowEndTime_returnsZeroAfterExpiry() public {
        uint32 duration = 1 days;
        harness.initialize(duration, poolManager);

        // Warp past the pause window
        vm.warp(block.timestamp + duration + 1);

        uint32 endTime = harness.getNewPoolPauseWindowEndTime();

        assertEq(endTime, 0, "Should return 0 after pause window expires");
    }

    /* ---------------------------------------------------------------------- */
    /*                             Fuzz Tests                                  */
    /* ---------------------------------------------------------------------- */

    function testFuzz_addPool_anyAddress(address pool) public {
        vm.assume(pool != address(0));
        harness.initialize(365 days, poolManager);

        harness.addPool(pool);

        assertTrue(harness.isPoolFromFactory(pool), "Any pool address should be addable");
    }

    function testFuzz_initialize_anyDuration(uint32 duration) public {
        // Avoid overflow
        vm.assume(duration < type(uint32).max - uint32(block.timestamp));

        harness.initialize(duration, poolManager);

        assertEq(harness.pauseWindowDuration(), duration, "Any duration should be storable");
    }

    function testFuzz_initialize_anyManager(address manager) public {
        harness.initialize(365 days, manager);

        assertEq(harness.getPoolManager(), manager, "Any manager address should be storable");
    }
}
